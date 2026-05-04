import Foundation
import Combine
import CoreLocation
import FirebaseCore
import FirebaseAuth

class MapViewModel: ObservableObject {
    @Published var stores: [Store] = []
    @Published var selectedStore: Store?
    @Published var errorMessage: String?

    private let storeService = StoreService()
    private let placesService: PlacesServiceProtocol

    init(placesService: PlacesServiceProtocol = PlacesService()) {
        self.placesService = placesService
    }

    // MARK: - Fetch stores (Firestore GeoQuery → mock fallback)
    @MainActor
    func fetchStores(in region: CLLocationCoordinate2D) {
        Task {
            do {
                if FirebaseApp.app() != nil, Auth.auth().currentUser != nil {
                    // 初回のみ新宿サンプルデータをシード（固定IDなので重複なし）
                    if !UserDefaults.standard.bool(forKey: "shinjukuSeeded") {
                        do {
                            try await storeService.seedShinjukuStores()
                            UserDefaults.standard.set(true, forKey: "shinjukuSeeded")
                        } catch {
                            // シード失敗時はフラグを立てず次回リトライ
                        }
                    }
                    let result = try await storeService.fetchStores(
                        near: region.latitude, longitude: region.longitude,
                        radiusKm: 20.0)
                    if !result.isEmpty {
                        self.stores = result
                        return
                    }
                }
                self.stores = try await placesService.fetchNearbyPlaces(coordinate: region, radius: 1000)
            } catch {
                self.errorMessage = error.localizedDescription
                self.stores = (try? await placesService.fetchNearbyPlaces(coordinate: region, radius: 1000)) ?? []
            }
        }
    }

    // MARK: - Submit 80% consensus report
    func submitConsensusReport(for store: Store, methods: [String], uid: String? = nil) {
        Task {
            do {
                if FirebaseApp.app() != nil, Auth.auth().currentUser != nil {
                    // Use all catalog IDs (not hardcoded display names)
                    let allIds = PaymentCatalog.all.map { $0.id }
                    for id in allIds {
                        try await storeService.submitPaymentReport(
                            storeId: store.id,
                            methodId: id,
                            isSupported: methods.contains(id)
                        )
                    }
                }
                await MainActor.run { self.updateLocalStore(store.id, methods: methods) }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.updateLocalStore(store.id, methods: methods)
                }
            }
        }
    }

    private func updateLocalStore(_ storeId: String, methods: [String]) {
        if let idx = stores.firstIndex(where: { $0.id == storeId }) {
            stores[idx].supportedPaymentMethods = methods
            if selectedStore?.id == storeId { selectedStore = stores[idx] }
        }
    }
}
