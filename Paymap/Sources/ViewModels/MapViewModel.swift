import Foundation
import Combine
import CoreLocation

class MapViewModel: ObservableObject {
    @Published var stores: [Store] = []
    @Published var selectedStore: Store?
    @Published var region: CLLocationCoordinate2D?
    
    private let placesService: PlacesServiceProtocol
    
    init(placesService: PlacesServiceProtocol = PlacesService()) {
        self.placesService = placesService
    }
    
    @MainActor
    func fetchStores(in region: CLLocationCoordinate2D) {
        Task {
            do {
                let fetchedStores = try await placesService.fetchNearbyPlaces(coordinate: region, radius: 1000)
                self.stores = fetchedStores
            } catch {
                print("Error fetching stores: \(error)")
            }
        }
    }
    
    // MOCK: Consensus reporting logic
    func submitConsensusReport(for store: Store, methods: [String]) {
        // In reality, this would send data to Firestore and Cloud Functions would calculate the 80% rule.
        // Here we mock the behavior:
        // If the user reports it, we'll assume they are the "first discoverer" for this mock and it instantly becomes 100%.
        
        if let index = stores.firstIndex(where: { $0.id == store.id }) {
            stores[index].supportedPaymentMethods = methods
            
            // Update selectedStore if it's currently showing
            if selectedStore?.id == store.id {
                selectedStore = stores[index]
            }
        }
    }
}
