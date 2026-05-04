import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class StoreService {
    private lazy var db = Firestore.firestore()

    // MARK: - Fetch stores near a location (bounding box GeoQuery)
    func fetchStores(near latitude: Double, longitude: Double, radiusKm: Double = 20.0) async throws -> [Store] {
        guard FirebaseApp.app() != nil else { return [] }

        let latDelta = radiusKm / 111.0
        let lngDelta = radiusKm / (111.0 * cos(latitude * .pi / 180))

        let snapshot = try await db.collection("stores")
            .whereField("latitude", isGreaterThan: latitude - latDelta)
            .whereField("latitude", isLessThan: latitude + latDelta)
            .limit(to: 100)
            .getDocuments()

        let minLng = longitude - lngDelta
        let maxLng = longitude + lngDelta

        return snapshot.documents.compactMap { doc -> Store? in
            guard let store = (try? doc.data(as: StoreDTO.self))?.toStore(id: doc.documentID) else { return nil }
            guard store.location.longitude >= minLng, store.location.longitude <= maxLng else { return nil }
            return store
        }
    }

    // MARK: - Add or update store
    func upsertStore(_ store: Store) async throws {
        let dto = StoreDTO(from: store)
        try db.collection("stores").document(store.id).setData(from: dto, merge: true)
    }

    // MARK: - Submit 80% consensus report
    func submitPaymentReport(storeId: String, methodId: String, isSupported: Bool) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw PaymapError.notAuthenticated
        }

        let reportRef = db.collection("stores").document(storeId)
            .collection("payment_reports").document(methodId)

        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            let reportDoc: DocumentSnapshot
            do { reportDoc = try transaction.getDocument(reportRef) }
            catch let e as NSError { errorPointer?.pointee = e; return nil }

            let data = reportDoc.data() ?? [:]
            var reporters = data["reporters"] as? [String: Bool] ?? [:]
            let previous = reporters[uid]
            reporters[uid] = isSupported

            var supported = data["supportedCount"] as? Int ?? 0
            var unsupported = data["unsupportedCount"] as? Int ?? 0

            if let prev = previous {
                if prev != isSupported {
                    if isSupported { supported += 1; unsupported -= 1 }
                    else { supported -= 1; unsupported += 1 }
                }
            } else {
                if isSupported { supported += 1 } else { unsupported += 1 }
            }

            let total = supported + unsupported
            let rate = total > 0 ? Double(supported) / Double(total) : 0.0
            let isActive = rate >= 0.8

            transaction.setData([
                "methodId": methodId, "supportedCount": supported,
                "unsupportedCount": unsupported, "totalReports": total,
                "approvalRate": rate, "isActive": isActive, "reporters": reporters
            ], forDocument: reportRef, merge: false)

            let storeRef = self.db.collection("stores").document(storeId)
            if isActive {
                transaction.updateData(["confirmedPaymentMethods": FieldValue.arrayUnion([methodId])], forDocument: storeRef)
            } else {
                transaction.updateData(["confirmedPaymentMethods": FieldValue.arrayRemove([methodId])], forDocument: storeRef)
            }
            return nil
        }
    }

    // MARK: - Fetch stores by user
    func fetchStoresByUser(uid: String) async throws -> [Store] {
        guard FirebaseApp.app() != nil else { return [] }
        let snapshot = try await db.collection("stores")
            .whereField("registeredByUid", isEqualTo: uid)
            .getDocuments()
        return snapshot.documents.compactMap { (try? $0.data(as: StoreDTO.self))?.toStore(id: $0.documentID) }
    }

    // MARK: - User profile (Firestore)
    func fetchOrCreateUser(uid: String, displayName: String, email: String) async throws -> UserData {
        guard FirebaseApp.app() != nil else {
            return UserData(totalContributions: 0, badges: [], isPremium: false, photoURL: nil)
        }
        let ref = db.collection("users").document(uid)
        let doc = try await ref.getDocument()

        if let data = doc.data() {
            return UserData(
                totalContributions: data["totalContributions"] as? Int ?? 0,
                badges: data["badges"] as? [String] ?? [],
                isPremium: data["isPremium"] as? Bool ?? false,
                photoURL: data["photoURL"] as? String
            )
        } else {
            let newData: [String: Any] = [
                "displayName": displayName, "email": email,
                "totalContributions": 0, "badges": [],
                "isPremium": false, "createdAt": Date()
            ]
            try await ref.setData(newData)
            return UserData(totalContributions: 0, badges: [], isPremium: false, photoURL: nil)
        }
    }

    // MARK: - Add contribution points + evaluate badges
    // Returns (newTotal, newlyEarnedBadgeIDs)
    func addPoints(to uid: String, points: Int) async throws -> (total: Int, newBadges: [String]) {
        guard FirebaseApp.app() != nil else { return (0, []) }
        let ref = db.collection("users").document(uid)

        let doc = try await ref.getDocument()
        let current = doc.data()?["totalContributions"] as? Int ?? 0
        var badges = doc.data()?["badges"] as? [String] ?? []
        let total = current + points

        var newBadges: [String] = []
        if total >= 1,   !badges.contains("firstPost") { newBadges.append("firstPost") }
        if total >= 10,  !badges.contains("br10")      { newBadges.append("br10") }
        if total >= 50,  !badges.contains("br50")      { newBadges.append("br50") }
        if total >= 200, !badges.contains("brMaster")  { newBadges.append("brMaster") }

        badges.append(contentsOf: newBadges)
        try await ref.updateData(["totalContributions": total, "badges": badges])
        return (total, newBadges)
    }

    func awardExplorerBadge(to uid: String) async throws {
        guard FirebaseApp.app() != nil else { return }
        let ref = db.collection("users").document(uid)
        let doc = try await ref.getDocument()
        var badges = doc.data()?["badges"] as? [String] ?? []
        if !badges.contains("brExplorer") {
            badges.append("brExplorer")
            try await ref.updateData(["badges": badges])
        }
    }

    // MARK: - Seed sample stores (Shinjuku, fixed IDs to prevent duplicates)
    func seedShinjukuStores() async throws {
        guard FirebaseApp.app() != nil else { return }
        let stores: [Store] = [
            Store(id: "seed_shinjuku_01",
                  name: "セブンイレブン 新宿南口店", nameEn: "7-Eleven Shinjuku South Exit",
                  location: .init(latitude: 35.6882, longitude: 139.7018),
                  category: .convenienceStore,
                  supportedPaymentMethods: ["paypay","suica","pasmo","nanaco","waon",
                                            "visa","mastercard","jcb","quicpay","id_payment"],
                  address: "東京都新宿区新宿3丁目", addressEn: "3 Chome Shinjuku, Shinjuku-ku, Tokyo",
                  photoURL: nil, registeredByUid: nil),

            Store(id: "seed_shinjuku_02",
                  name: "ローソン 新宿三丁目店", nameEn: "Lawson Shinjuku 3-chome",
                  location: .init(latitude: 35.6921, longitude: 139.7058),
                  category: .convenienceStore,
                  supportedPaymentMethods: ["paypay","suica","pasmo","waon",
                                            "visa","mastercard","id_payment"],
                  address: "東京都新宿区新宿3-15", addressEn: "3-15 Shinjuku, Shinjuku-ku, Tokyo",
                  photoURL: nil, registeredByUid: nil),

            Store(id: "seed_shinjuku_03",
                  name: "ファミリーマート 新宿駅東口店", nameEn: "FamilyMart Shinjuku East Exit",
                  location: .init(latitude: 35.6907, longitude: 139.7031),
                  category: .convenienceStore,
                  supportedPaymentMethods: ["paypay","linepay","suica","pasmo","nanaco","waon",
                                            "visa","mastercard","jcb","quicpay"],
                  address: "東京都新宿区新宿3-37", addressEn: "3-37 Shinjuku, Shinjuku-ku, Tokyo",
                  photoURL: nil, registeredByUid: nil),

            Store(id: "seed_shinjuku_04",
                  name: "スターバックス 新宿サザンテラス店",
                  nameEn: "Starbucks Shinjuku Southern Terrace",
                  location: .init(latitude: 35.6884, longitude: 139.7013),
                  category: .cafe,
                  supportedPaymentMethods: ["visa","mastercard","jcb","amex",
                                            "suica","pasmo","paypay"],
                  address: "東京都渋谷区代々木2-2-1", addressEn: "2-2-1 Yoyogi, Shibuya-ku, Tokyo",
                  photoURL: nil, registeredByUid: nil),

            Store(id: "seed_shinjuku_05",
                  name: "ドトールコーヒー 新宿西口店", nameEn: "Doutor Coffee Shinjuku West",
                  location: .init(latitude: 35.6929, longitude: 139.6982),
                  category: .cafe,
                  supportedPaymentMethods: ["paypay","visa","mastercard","suica","pasmo"],
                  address: "東京都新宿区西新宿1-1", addressEn: "1-1 Nishi-Shinjuku, Shinjuku-ku, Tokyo",
                  photoURL: nil, registeredByUid: nil),

            Store(id: "seed_shinjuku_06",
                  name: "マクドナルド 新宿東南口店", nameEn: "McDonald's Shinjuku Southeast Exit",
                  location: .init(latitude: 35.6901, longitude: 139.7022),
                  category: .fastFood,
                  supportedPaymentMethods: ["paypay","suica","pasmo","visa","mastercard",
                                            "jcb","quicpay","id_payment"],
                  address: "東京都新宿区新宿3-22", addressEn: "3-22 Shinjuku, Shinjuku-ku, Tokyo",
                  photoURL: nil, registeredByUid: nil),

            Store(id: "seed_shinjuku_07",
                  name: "吉野家 新宿西口店", nameEn: "Yoshinoya Shinjuku West",
                  location: .init(latitude: 35.6933, longitude: 139.6984),
                  category: .restaurant,
                  supportedPaymentMethods: ["paypay","suica","pasmo","visa","mastercard"],
                  address: "東京都新宿区西新宿1-2", addressEn: "1-2 Nishi-Shinjuku, Shinjuku-ku, Tokyo",
                  photoURL: nil, registeredByUid: nil),

            Store(id: "seed_shinjuku_08",
                  name: "松屋 新宿東口店", nameEn: "Matsuya Shinjuku East",
                  location: .init(latitude: 35.6935, longitude: 139.7026),
                  category: .restaurant,
                  supportedPaymentMethods: ["cash_only"],
                  address: "東京都新宿区新宿3-26", addressEn: "3-26 Shinjuku, Shinjuku-ku, Tokyo",
                  photoURL: nil, registeredByUid: nil),

            Store(id: "seed_shinjuku_09",
                  name: "ビックカメラ 新宿西口店", nameEn: "BicCamera Shinjuku West",
                  location: .init(latitude: 35.6928, longitude: 139.6988),
                  category: .other,
                  supportedPaymentMethods: ["visa","mastercard","jcb","amex",
                                            "paypay","suica","pasmo","waon","quicpay","id_payment"],
                  address: "東京都新宿区西新宿1-5-1", addressEn: "1-5-1 Nishi-Shinjuku, Shinjuku-ku, Tokyo",
                  photoURL: nil, registeredByUid: nil),

            Store(id: "seed_shinjuku_10",
                  name: "伊勢丹 新宿本店", nameEn: "Isetan Shinjuku Main Store",
                  location: .init(latitude: 35.6937, longitude: 139.7047),
                  category: .other,
                  supportedPaymentMethods: ["visa","mastercard","jcb","amex","diners","unionpay",
                                            "paypay","suica","pasmo","quicpay"],
                  address: "東京都新宿区新宿3-14-1", addressEn: "3-14-1 Shinjuku, Shinjuku-ku, Tokyo",
                  photoURL: nil, registeredByUid: nil),
        ]
        for store in stores {
            try await upsertStore(store)
        }
    }

    // MARK: - Payment reports
    func fetchPaymentReports(for storeId: String) async throws -> [PaymentReport] {
        let snapshot = try await db.collection("stores").document(storeId)
            .collection("payment_reports").getDocuments()
        return snapshot.documents.compactMap { doc -> PaymentReport? in
            let data = doc.data()
            return PaymentReport(
                methodId: doc.documentID,
                supportedCount: data["supportedCount"] as? Int ?? 0,
                unsupportedCount: data["unsupportedCount"] as? Int ?? 0,
                totalReports: data["totalReports"] as? Int ?? 0,
                approvalRate: data["approvalRate"] as? Double ?? 0.0,
                isActive: data["isActive"] as? Bool ?? false
            )
        }
    }
}

// MARK: - Supporting Types

struct UserData {
    let totalContributions: Int
    let badges: [String]
    let isPremium: Bool
    let photoURL: String?
}

struct PaymentReport {
    let methodId: String
    let supportedCount: Int
    let unsupportedCount: Int
    let totalReports: Int
    let approvalRate: Double
    let isActive: Bool
    var approvalPercentage: Int { Int(approvalRate * 100) }
}

struct StoreDTO: Codable {
    let name: String
    let nameEn: String?
    let category: String
    let latitude: Double
    let longitude: Double
    let confirmedPaymentMethods: [String]
    let lastUpdated: Date
    let address: String?
    let addressEn: String?
    let photoURL: String?
    let registeredByUid: String?

    init(from store: Store) {
        self.name = store.name
        self.nameEn = store.nameEn
        self.category = store.category.rawValue
        self.latitude = store.location.latitude
        self.longitude = store.location.longitude
        self.confirmedPaymentMethods = store.supportedPaymentMethods
        self.lastUpdated = Date()
        self.address = store.address
        self.addressEn = store.addressEn
        self.photoURL = store.photoURL
        self.registeredByUid = store.registeredByUid
    }

    func toStore(id: String) -> Store? {
        guard let category = StoreCategory(rawValue: category) else { return nil }
        return Store(
            id: id, name: name, nameEn: nameEn,
            location: Store.Coordinate(latitude: latitude, longitude: longitude),
            category: category,
            supportedPaymentMethods: confirmedPaymentMethods,
            address: address, addressEn: addressEn,
            photoURL: photoURL,
            registeredByUid: registeredByUid
        )
    }
}

enum PaymapError: LocalizedError {
    case notAuthenticated
    case firestoreError(String)

    private static var isEnglish: Bool {
        UserDefaults.standard.string(forKey: "appLanguage") == "en"
    }

    var errorDescription: String? {
        let en = PaymapError.isEnglish
        switch self {
        case .notAuthenticated:
            return en ? "Please sign in to continue." : "ログインが必要です"
        case .firestoreError(let msg):
            return en ? "Database error: \(msg)" : "データベースエラー: \(msg)"
        }
    }
}
