import Foundation
import FirebaseAuth

// さくらインターネット PHP API のベース URL
private let kAPIBase = "https://coussinet.sakura.ne.jp/paymap/api"

class StoreService {

    // MARK: - Networking helpers

    private func get<R: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> R {
        var comps = URLComponents(string: "\(kAPIBase)/\(path)")!
        if !query.isEmpty {
            comps.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = comps.url else { throw PaymapError.apiError("Bad URL") }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(R.self, from: data)
    }

    private func post<B: Encodable, R: Decodable>(
        _ path: String, body: B, action: String? = nil
    ) async throws -> R {
        let urlStr = action.map { "\(kAPIBase)/\(path)?action=\($0)" } ?? "\(kAPIBase)/\(path)"
        guard let url = URL(string: urlStr) else { throw PaymapError.apiError("Bad URL") }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(R.self, from: data)
    }

    // MARK: - Delete store (本人24h以内 or 他更新0件 or 管理者)

    func deleteStore(storeId: String, uid: String) async throws {
        var comps = URLComponents(string: "\(kAPIBase)/stores.php")!
        comps.queryItems = [
            URLQueryItem(name: "store_id", value: storeId),
            URLQueryItem(name: "uid", value: uid)
        ]
        guard let url = comps.url else { throw PaymapError.apiError("Bad URL") }
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode == 403 {
            let errRes = try? JSONDecoder().decode(DeleteErrorResponse.self, from: data)
            if errRes?.error == "cannot_delete" {
                throw PaymapError.cannotDelete
            }
            throw PaymapError.apiError(errRes?.error ?? "not_authorized")
        }
        let res = try JSONDecoder().decode(SuccessResponse.self, from: data)
        if !res.success { throw PaymapError.apiError("delete_failed") }
    }

    // MARK: - Report store error (誤り報告)

    func reportStoreError(storeId: String, uid: String, reason: String) async throws -> Int {
        let res: ReportErrorResponse = try await post(
            "stores.php",
            body: ReportErrorBody(storeId: storeId, uid: uid, reason: reason),
            action: "report_error"
        )
        return res.reportCount
    }

    // MARK: - Fetch stores near a location

    func fetchStores(near latitude: Double, longitude: Double, radiusKm: Double = 20.0) async throws -> [Store] {
        let res: StoreListResponse = try await get("stores.php", query: [
            "lat": "\(latitude)", "lng": "\(longitude)", "radius": "\(radiusKm)"
        ])
        return res.stores.compactMap { $0.toStore() }
    }

    // MARK: - Fetch stores by user

    func fetchStoresByUser(uid: String) async throws -> [Store] {
        let res: StoreListResponse = try await get("stores.php", query: ["uid": uid])
        return res.stores.compactMap { $0.toStore() }
    }

    // MARK: - Add or update store

    func upsertStore(_ store: Store) async throws {
        let _: SuccessResponse = try await post("stores.php", body: StoreUpsertBody(from: store))
    }

    // MARK: - Submit 80% consensus report

    func submitPaymentReport(storeId: String, methodId: String, isSupported: Bool) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw PaymapError.notAuthenticated
        }
        let body = PaymentReportBody(
            storeId: storeId, methodId: methodId, userId: uid, isSupported: isSupported)
        let _: SuccessResponse = try await post("reports.php", body: body)
    }

    // MARK: - Update store facilities (WiFi / Power)

    func updateStoreFacilities(storeId: String, hasWifi: Bool?, hasPower: Bool?) async throws {
        let body = UpdateFacilitiesBody(storeId: storeId, hasWifi: hasWifi, hasPower: hasPower)
        let _: SuccessResponse = try await post("stores.php", body: body, action: "update_facilities")
    }

    // MARK: - User profile

    func fetchOrCreateUser(uid: String, displayName: String, email: String) async throws -> UserData {
        if let res: UserProfileResponse = try? await get("users.php", query: ["uid": uid]),
           res.uid != nil {
            return UserData(
                totalContributions: res.totalContributions ?? 0,
                badges: res.badges ?? [],
                isPremium: res.isPremium ?? false,
                photoURL: res.photoURL,
                favoriteStoreIds: res.favoriteStoreIds ?? []
            )
        }
        let _: SuccessResponse = try await post(
            "users.php",
            body: UserCreateBody(uid: uid, displayName: displayName, email: email))
        return UserData(totalContributions: 0, badges: [], isPremium: false, photoURL: nil)
    }

    func updateUserProfile(uid: String, displayName: String? = nil, email: String? = nil) async throws {
        let body = UserUpdateBody(uid: uid, displayName: displayName, email: email)
        let _: SuccessResponse = try await post("users.php", body: body, action: "update_profile")
    }

    // MARK: - Add contribution points + evaluate badges

    func addPoints(to uid: String, points: Int) async throws -> (total: Int, newBadges: [String]) {
        let res: AddPointsResponse = try await post(
            "users.php",
            body: AddPointsBody(uid: uid, points: points),
            action: "add_points")
        return (res.total, res.newBadges)
    }

    func awardExplorerBadge(to uid: String) async throws {
        let body = AwardBadgeBody(uid: uid, badgeId: "brExplorer")
        let _: SuccessResponse = try await post("users.php", body: body, action: "award_badge")
    }

    // MARK: - Ranking

    func fetchTopUsers(limit: Int = 20) async throws -> [RankingEntry] {
        let res: RankingListResponse = try await get("users.php", query: [
            "action": "ranking", "limit": "\(limit)"
        ])
        return res.ranking
    }

    // MARK: - Favorites

    func fetchFavoriteStoreIds(uid: String) async throws -> [String] {
        let res: UserProfileResponse = try await get("users.php", query: ["uid": uid])
        return res.favoriteStoreIds ?? []
    }

    func toggleFavorite(storeId: String, uid: String, isFavoriting: Bool) async throws {
        let body = ToggleFavoriteBody(uid: uid, storeId: storeId, isFavorite: isFavoriting)
        let _: SuccessResponse = try await post("users.php", body: body, action: "toggle_favorite")
    }

    func fetchFavoriteStores(uid: String) async throws -> [Store] {
        let ids = try await fetchFavoriteStoreIds(uid: uid)
        guard !ids.isEmpty else { return [] }
        let res: StoreListResponse = try await get("stores.php", query: [
            "ids": ids.joined(separator: ",")
        ])
        return res.stores.compactMap { $0.toStore() }
    }

    // MARK: - Payment reports

    func fetchPaymentReports(for storeId: String) async throws -> [PaymentReport] {
        let res: PaymentReportsResponse = try await get("reports.php", query: ["store_id": storeId])
        return res.reports.map {
            PaymentReport(
                methodId: $0.methodId,
                supportedCount: $0.supportedCount,
                unsupportedCount: $0.unsupportedCount,
                totalReports: $0.totalReports,
                approvalRate: $0.approvalRate,
                isActive: $0.isActive
            )
        }
    }

    // MARK: - Photo upload (Sakura Internet uploads ディレクトリへ)

    func uploadStorePhoto(storeId: String, imageData: Data, uploadBaseURL: String) async throws -> String {
        guard let url = URL(string: "\(uploadBaseURL)/upload.php") else {
            throw PaymapError.apiError("Invalid upload URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"store_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(storeId)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw PaymapError.apiError("Photo upload failed")
        }
        let json = try JSONDecoder().decode([String: String].self, from: data)
        guard let photoURL = json["url"] else {
            throw PaymapError.apiError("No URL in upload response")
        }
        return photoURL
    }

    // MARK: - Seed sample stores (Shinjuku, fixed IDs to prevent duplicates)

    func seedShinjukuStores() async throws {
        let stores: [Store] = [
            Store(id: "seed_shinjuku_01",
                  name: "セブンイレブン 新宿南口店", nameEn: "7-Eleven Shinjuku South Exit",
                  location: .init(latitude: 35.6882, longitude: 139.7018),
                  category: .convenienceStore,
                  supportedPaymentMethods: ["paypay","suica","pasmo","nanaco","waon",
                                            "visa","mastercard","jcb","quicpay","id_payment"],
                  address: "東京都新宿区新宿3丁目", addressEn: "3 Chome Shinjuku, Shinjuku-ku, Tokyo",
                  photoURL: nil, registeredByUid: nil, hasWifi: false, hasPower: false),

            Store(id: "seed_shinjuku_02",
                  name: "ローソン 新宿三丁目店", nameEn: "Lawson Shinjuku 3-chome",
                  location: .init(latitude: 35.6921, longitude: 139.7058),
                  category: .convenienceStore,
                  supportedPaymentMethods: ["paypay","suica","pasmo","waon","visa","mastercard","id_payment"],
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
                  supportedPaymentMethods: ["visa","mastercard","jcb","amex","suica","pasmo","paypay"],
                  address: "東京都渋谷区代々木2-2-1", addressEn: "2-2-1 Yoyogi, Shibuya-ku, Tokyo",
                  photoURL: nil, registeredByUid: nil, hasWifi: true, hasPower: true),

            Store(id: "seed_shinjuku_05",
                  name: "ドトールコーヒー 新宿西口店", nameEn: "Doutor Coffee Shinjuku West",
                  location: .init(latitude: 35.6929, longitude: 139.6982),
                  category: .cafe,
                  supportedPaymentMethods: ["paypay","visa","mastercard","suica","pasmo"],
                  address: "東京都新宿区西新宿1-1", addressEn: "1-1 Nishi-Shinjuku, Shinjuku-ku, Tokyo",
                  photoURL: nil, registeredByUid: nil, hasWifi: true, hasPower: false),

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

    // MARK: - Offline cache helpers

    func cacheStores(_ stores: [Store]) {
        if let data = try? JSONEncoder().encode(stores) {
            UserDefaults.standard.set(data, forKey: "cachedStores")
            UserDefaults.standard.set(Date(), forKey: "cachedStoresDate")
        }
    }

    func loadCachedStores() -> [Store] {
        guard let data = UserDefaults.standard.data(forKey: "cachedStores"),
              let stores = try? JSONDecoder().decode([Store].self, from: data)
        else { return [] }
        return stores
    }
}

// MARK: - Supporting Types (public — used by ViewModels / Views)

struct UserData {
    let totalContributions: Int
    let badges: [String]
    let isPremium: Bool
    let photoURL: String?
    var favoriteStoreIds: [String] = []
}

struct RankingEntry: Identifiable, Codable {
    let rank: Int
    let uid: String
    let displayName: String
    let points: Int
    let badges: [String]
    var id: String { uid }

    enum CodingKeys: String, CodingKey {
        case rank, uid, displayName, points, badges
    }
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

enum PaymapError: LocalizedError {
    case notAuthenticated
    case apiError(String)
    case cannotDelete

    private static var isEnglish: Bool {
        UserDefaults.standard.string(forKey: "appLanguage") == "en"
    }

    var errorDescription: String? {
        let en = PaymapError.isEnglish
        switch self {
        case .notAuthenticated:
            return en ? "Please sign in to continue." : "ログインが必要です"
        case .apiError(let msg):
            return en ? "Server error: \(msg)" : "サーバーエラー: \(msg)"
        case .cannotDelete:
            return en ? "Cannot delete this store." : "この店舗は削除できません"
        }
    }
}

// MARK: - Private API response / request types

private struct StoreListResponse: Decodable {
    let stores: [APIStore]
}

private struct APIStore: Decodable {
    let id: String
    let name: String
    let nameEn: String?
    let category: String
    let location: APILocation
    let address: String?
    let addressEn: String?
    let photoURL: String?
    let registeredByUid: String?
    let hasWifi: Bool?
    let hasPower: Bool?
    let supportedPaymentMethods: [String]
    let createdAt: String?

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    func toStore() -> Store? {
        guard let cat = StoreCategory(rawValue: category) else { return nil }
        var store = Store(
            id: id, name: name, nameEn: nameEn,
            location: .init(latitude: location.latitude, longitude: location.longitude),
            category: cat,
            supportedPaymentMethods: supportedPaymentMethods,
            address: address, addressEn: addressEn,
            photoURL: photoURL,
            registeredByUid: registeredByUid,
            hasWifi: hasWifi,
            hasPower: hasPower
        )
        if let str = createdAt {
            store.createdAt = APIStore.dateFormatter.date(from: str)
        }
        return store
    }
}

private struct APILocation: Decodable {
    let latitude: Double
    let longitude: Double
}

private struct UserProfileResponse: Decodable {
    let uid: String?
    let displayName: String?
    let email: String?
    let totalContributions: Int?
    let isPremium: Bool?
    let photoURL: String?
    let badges: [String]?
    let favoriteStoreIds: [String]?
}

private struct AddPointsResponse: Decodable {
    let success: Bool
    let total: Int
    let newBadges: [String]
}

private struct RankingListResponse: Decodable {
    let ranking: [RankingEntry]
}

private struct PaymentReportsResponse: Decodable {
    let reports: [APIPaymentReportSummary]
}

private struct APIPaymentReportSummary: Decodable {
    let methodId: String
    let supportedCount: Int
    let unsupportedCount: Int
    let totalReports: Int
    let approvalRate: Double
    let isActive: Bool
}

private struct SuccessResponse: Decodable {
    let success: Bool
}

// --- Request body types ---

private struct StoreUpsertBody: Encodable {
    let id: String
    let name: String
    let nameEn: String?
    let category: String
    let location: EncodableLocation
    let address: String?
    let addressEn: String?
    let photoURL: String?
    let registeredByUid: String?
    let hasWifi: Bool?
    let hasPower: Bool?
    let supportedPaymentMethods: [String]

    init(from store: Store) {
        id = store.id
        name = store.name
        nameEn = store.nameEn
        category = store.category.rawValue
        location = EncodableLocation(latitude: store.location.latitude, longitude: store.location.longitude)
        address = store.address
        addressEn = store.addressEn
        photoURL = store.photoURL
        registeredByUid = store.registeredByUid
        hasWifi = store.hasWifi
        hasPower = store.hasPower
        supportedPaymentMethods = store.supportedPaymentMethods
    }
}

private struct EncodableLocation: Encodable {
    let latitude: Double
    let longitude: Double
}

private struct PaymentReportBody: Encodable {
    let storeId: String
    let methodId: String
    let userId: String
    let isSupported: Bool

    enum CodingKeys: String, CodingKey {
        case storeId     = "store_id"
        case methodId    = "method_id"
        case userId      = "user_id"
        case isSupported = "is_supported"
    }
}

private struct UpdateFacilitiesBody: Encodable {
    let storeId: String
    let hasWifi: Bool?
    let hasPower: Bool?

    enum CodingKeys: String, CodingKey {
        case storeId  = "store_id"
        case hasWifi
        case hasPower
    }
}

private struct UserCreateBody: Encodable {
    let uid: String
    let displayName: String?
    let email: String?
}

private struct UserUpdateBody: Encodable {
    let uid: String
    let displayName: String?
    let email: String?
}

private struct AddPointsBody: Encodable {
    let uid: String
    let points: Int
}

private struct AwardBadgeBody: Encodable {
    let uid: String
    let badgeId: String

    enum CodingKeys: String, CodingKey {
        case uid
        case badgeId = "badge_id"
    }
}

private struct DeleteErrorResponse: Decodable {
    let success: Bool?
    let error: String?
}

private struct ReportErrorBody: Encodable {
    let storeId: String
    let uid: String
    let reason: String

    enum CodingKeys: String, CodingKey {
        case storeId = "store_id"
        case uid, reason
    }
}

private struct ReportErrorResponse: Decodable {
    let success: Bool
    let reportCount: Int

    enum CodingKeys: String, CodingKey {
        case success
        case reportCount = "report_count"
    }
}

private struct ToggleFavoriteBody: Encodable {
    let uid: String
    let storeId: String
    let isFavorite: Bool

    enum CodingKeys: String, CodingKey {
        case uid
        case storeId    = "store_id"
        case isFavorite = "is_favorite"
    }
}
