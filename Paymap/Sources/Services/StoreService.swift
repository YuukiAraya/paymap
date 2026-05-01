import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class StoreService {
    private lazy var db = Firestore.firestore()
    
    // MARK: - Fetch stores near a location (from Firestore cache)
    func fetchStores(near latitude: Double, longitude: Double) async throws -> [Store] {
        // In a full implementation, use GeoFirestore or GeoQuery for radius queries.
        // For now, fetch the most recently updated stores.
        let snapshot = try await db.collection("stores")
            .order(by: "lastUpdated", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: StoreDTO.self).toStore(id: document.documentID)
        }
    }
    
    // MARK: - Add or update store from Google Places
    func upsertStore(_ store: Store) async throws {
        let dto = StoreDTO(from: store)
        try db.collection("stores").document(store.id).setData(from: dto, merge: true)
    }
    
    // MARK: - Submit a payment method report (80% consensus)
    func submitPaymentReport(storeId: String, methodId: String, isSupported: Bool) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw PaymapError.notAuthenticated
        }
        
        let reportRef = db
            .collection("stores")
            .document(storeId)
            .collection("payment_reports")
            .document(methodId)
        
        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            let reportDoc: DocumentSnapshot
            do {
                reportDoc = try transaction.getDocument(reportRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            let data = reportDoc.data() ?? [:]
            var reporters = data["reporters"] as? [String: Bool] ?? [:]
            
            // Allow re-voting (update existing vote)
            let previousVote = reporters[uid]
            reporters[uid] = isSupported
            
            var supportedCount = data["supportedCount"] as? Int ?? 0
            var unsupportedCount = data["unsupportedCount"] as? Int ?? 0
            
            // Adjust counts based on whether this is a new vote or a change
            if let prev = previousVote {
                if prev != isSupported {
                    if isSupported { supportedCount += 1; unsupportedCount -= 1 }
                    else { supportedCount -= 1; unsupportedCount += 1 }
                }
                // Same vote again: no change
            } else {
                // New vote
                if isSupported { supportedCount += 1 }
                else { unsupportedCount += 1 }
            }
            
            let totalReports = supportedCount + unsupportedCount
            let approvalRate = totalReports > 0 ? Double(supportedCount) / Double(totalReports) : 0.0
            let isActive = approvalRate >= 0.8  // 80% rule
            
            let updatedData: [String: Any] = [
                "methodId": methodId,
                "supportedCount": supportedCount,
                "unsupportedCount": unsupportedCount,
                "totalReports": totalReports,
                "approvalRate": approvalRate,
                "isActive": isActive,
                "reporters": reporters
            ]
            
            transaction.setData(updatedData, forDocument: reportRef, merge: false)
            
            // If isActive changed, update the parent store's confirmedPaymentMethods
            let storeRef = self.db.collection("stores").document(storeId)
            if isActive {
                transaction.updateData(["confirmedPaymentMethods": FieldValue.arrayUnion([methodId])], forDocument: storeRef)
            } else {
                transaction.updateData(["confirmedPaymentMethods": FieldValue.arrayRemove([methodId])], forDocument: storeRef)
            }
            
            return nil
        }
    }
    
    // MARK: - Fetch stores registered by a specific user
    func fetchStoresByUser(uid: String) async throws -> [Store] {
        guard FirebaseApp.app() != nil else { return [] }
        let snapshot = try await db.collection("stores")
            .whereField("registeredByUid", isEqualTo: uid)
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: StoreDTO.self).toStore(id: doc.documentID)
        }
    }

    // MARK: - Fetch payment reports for a store
    func fetchPaymentReports(for storeId: String) async throws -> [PaymentReport] {
        let snapshot = try await db
            .collection("stores")
            .document(storeId)
            .collection("payment_reports")
            .getDocuments()
        
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

// MARK: - Supporting types

struct PaymentReport {
    let methodId: String
    let supportedCount: Int
    let unsupportedCount: Int
    let totalReports: Int
    let approvalRate: Double
    let isActive: Bool
    
    var approvalPercentage: Int { Int(approvalRate * 100) }
}

// Firestore DTO (Data Transfer Object) for Store
struct StoreDTO: Codable {
    let name: String
    let category: String
    let latitude: Double
    let longitude: Double
    let confirmedPaymentMethods: [String]
    let lastUpdated: Date
    let address: String?
    let registeredByUid: String?

    init(from store: Store) {
        self.name = store.name
        self.category = store.category.rawValue
        self.latitude = store.location.latitude
        self.longitude = store.location.longitude
        self.confirmedPaymentMethods = store.supportedPaymentMethods
        self.lastUpdated = Date()
        self.address = store.address
        self.registeredByUid = store.registeredByUid
    }

    func toStore(id: String) -> Store? {
        guard let category = StoreCategory(rawValue: category) else { return nil }
        return Store(
            id: id,
            name: name,
            location: Store.Coordinate(latitude: latitude, longitude: longitude),
            category: category,
            supportedPaymentMethods: confirmedPaymentMethods,
            address: address,
            registeredByUid: registeredByUid
        )
    }
}

enum PaymapError: LocalizedError {
    case notAuthenticated
    case firestoreError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "ログインが必要です"
        case .firestoreError(let msg): return "データベースエラー: \(msg)"
        }
    }
}
