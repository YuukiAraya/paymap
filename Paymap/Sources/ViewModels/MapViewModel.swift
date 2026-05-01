import Foundation
import Combine
import CoreLocation
import FirebaseCore
import FirebaseAuth

class MapViewModel: ObservableObject {
    @Published var stores: [Store] = []
    @Published var selectedStore: Store?
    @Published var region: CLLocationCoordinate2D?
    @Published var errorMessage: String?
    
    private let placesService: PlacesServiceProtocol
    private let storeService = StoreService()
    
    init(placesService: PlacesServiceProtocol = PlacesService()) {
        self.placesService = placesService
    }
    
    // MARK: - Fetch stores
    @MainActor
    func fetchStores(in region: CLLocationCoordinate2D) {
        Task {
            do {
                // Try Firestore first; fall back to mock Places service
                if FirebaseApp.app() != nil, Auth.auth().currentUser != nil {
                    let firestoreStores = try await storeService.fetchStores(
                        near: region.latitude,
                        longitude: region.longitude
                    )
                    if !firestoreStores.isEmpty {
                        self.stores = firestoreStores
                        return
                    }
                }
                // Fallback: mock data from PlacesService
                let fetchedStores = try await placesService.fetchNearbyPlaces(coordinate: region, radius: 1000)
                self.stores = fetchedStores
            } catch {
                self.errorMessage = error.localizedDescription
                // Always fall back to mock data
                let fallback = try? await placesService.fetchNearbyPlaces(coordinate: region, radius: 1000)
                self.stores = fallback ?? []
            }
        }
    }
    
    // MARK: - Submit 80% consensus report (real Firestore transaction)
    func submitConsensusReport(for store: Store, methods: [String]) {
        Task {
            do {
                if FirebaseApp.app() != nil, Auth.auth().currentUser != nil {
                    // Real Firestore submission for each method
                    let allMethods = ["PayPay", "Suica", "Credit Card", "LINE Pay", "QUICPay", "iD", "現金のみ", "Coke ON Pay"]
                    for method in allMethods {
                        let isSupported = methods.contains(method)
                        try await storeService.submitPaymentReport(
                            storeId: store.id,
                            methodId: method,
                            isSupported: isSupported
                        )
                    }
                }
                
                // Optimistically update local state for immediate UI feedback
                await MainActor.run {
                    if let index = self.stores.firstIndex(where: { $0.id == store.id }) {
                        self.stores[index].supportedPaymentMethods = methods
                        if self.selectedStore?.id == store.id {
                            self.selectedStore = self.stores[index]
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    // Still update local state even if Firebase fails (mock mode)
                    if let index = self.stores.firstIndex(where: { $0.id == store.id }) {
                        self.stores[index].supportedPaymentMethods = methods
                        if self.selectedStore?.id == store.id {
                            self.selectedStore = self.stores[index]
                        }
                    }
                }
            }
        }
    }
}
