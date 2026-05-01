import Foundation
import CoreLocation

protocol PlacesServiceProtocol {
    func fetchNearbyPlaces(coordinate: CLLocationCoordinate2D, radius: Double) async throws -> [Store]
}

class PlacesService: PlacesServiceProtocol {
    // TODO: Inject Google Places API Key
    private let apiKey = "YOUR_GOOGLE_PLACES_API_KEY"
    
    func fetchNearbyPlaces(coordinate: CLLocationCoordinate2D, radius: Double) async throws -> [Store] {
        // MOCK IMPLEMENTATION: Returns dummy data after a short delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return [
            Store(id: "place_1", name: "セブンイレブン 渋谷駅前店", location: Store.Coordinate(latitude: coordinate.latitude + 0.001, longitude: coordinate.longitude + 0.001), category: .convenienceStore, supportedPaymentMethods: ["PayPay", "Suica"]),
            Store(id: "place_2", name: "スターバックス 渋谷モディ店", location: Store.Coordinate(latitude: coordinate.latitude - 0.001, longitude: coordinate.longitude - 0.001), category: .cafe, supportedPaymentMethods: ["Credit Card", "Suica"]),
            Store(id: "place_3", name: "マツモトキヨシ 渋谷Part1", location: Store.Coordinate(latitude: coordinate.latitude + 0.002, longitude: coordinate.longitude - 0.001), category: .drugStore, supportedPaymentMethods: []),
            Store(id: "place_4", name: "コカ・コーラ自販機 (道玄坂)", location: Store.Coordinate(latitude: coordinate.latitude - 0.002, longitude: coordinate.longitude + 0.002), category: .vendingMachine, supportedPaymentMethods: ["Coke ON Pay", "Suica", "PayPay"])
        ]
        
        // ACTUAL IMPLEMENTATION (Example)
        /*
        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(coordinate.latitude),\(coordinate.longitude)&radius=\(radius)&type=store&key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        // Parse Google Places JSON to [Store]
        */
    }
}
