import Foundation
import CoreLocation

protocol PlacesServiceProtocol {
    func fetchNearbyPlaces(coordinate: CLLocationCoordinate2D, radius: Double) async throws -> [Store]
}

// MARK: - Google Places Nearby Search (REST)
class PlacesService: PlacesServiceProtocol {
    private let apiKey: String

    init() {
        apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String ?? ""
    }

    func fetchNearbyPlaces(coordinate: CLLocationCoordinate2D, radius: Double) async throws -> [Store] {
        guard !apiKey.isEmpty else {
            return MockPlacesService().mockStores(near: coordinate)
        }
        do {
            var components = URLComponents(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json")!
            components.queryItems = [
                URLQueryItem(name: "location", value: "\(coordinate.latitude),\(coordinate.longitude)"),
                URLQueryItem(name: "radius",   value: "\(Int(radius))"),
                URLQueryItem(name: "language", value: "ja"),
                URLQueryItem(name: "key",      value: apiKey),
            ]
            guard let url = components.url else { throw URLError(.badURL) }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            let results = try JSONDecoder().decode(PlacesResponse.self, from: data).results.compactMap { Store(from: $0) }
            // API が結果を返せない場合もモックにフォールバック
            return results.isEmpty ? MockPlacesService().mockStores(near: coordinate) : results
        } catch {
            return MockPlacesService().mockStores(near: coordinate)
        }
    }
}

// MARK: - Response Models
private struct PlacesResponse: Decodable {
    let results: [PlaceResult]
}

private struct PlaceResult: Decodable {
    let placeId: String
    let name: String
    let vicinity: String?
    let geometry: Geometry?
    let types: [String]?
    let photos: [PlacePhoto]?

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name, vicinity, geometry, types, photos
    }

    struct Geometry: Decodable {
        let location: LatLng
    }
    struct LatLng: Decodable {
        let lat: Double
        let lng: Double
    }
    struct PlacePhoto: Decodable {
        let photoReference: String
        enum CodingKeys: String, CodingKey { case photoReference = "photo_reference" }
    }
}

private extension Store {
    init?(from result: PlaceResult) {
        guard let lat = result.geometry?.location.lat,
              let lng = result.geometry?.location.lng
        else { return nil }

        self.init(
            id: result.placeId,
            name: result.name,
            nameEn: nil,
            location: Store.Coordinate(latitude: lat, longitude: lng),
            category: StoreCategory(googleTypes: result.types ?? []),
            supportedPaymentMethods: [],
            address: result.vicinity,
            addressEn: nil,
            photoURL: nil,
            registeredByUid: nil
        )
    }
}

private extension StoreCategory {
    init(googleTypes: [String]) {
        let t = Set(googleTypes)
        if t.contains("convenience_store")                          { self = .convenienceStore }
        else if t.contains("cafe")                                  { self = .cafe }
        else if t.contains("bar") || t.contains("night_club")       { self = .izakaya }
        else if t.contains("meal_takeaway") || t.contains("meal_delivery") { self = .fastFood }
        else if t.contains("supermarket") || t.contains("grocery_or_supermarket") { self = .supermarket }
        else if t.contains("pharmacy") || t.contains("drugstore")   { self = .drugStore }
        else if t.contains("lodging")                               { self = .hotel }
        else if t.contains("restaurant") || t.contains("food")      { self = .restaurant }
        else                                                         { self = .other }
    }
}

// MARK: - Mock fallback (development / no API key)
private struct MockPlacesService {
    func mockStores(near coordinate: CLLocationCoordinate2D) -> [Store] {
        let lat = coordinate.latitude
        let lng = coordinate.longitude
        return [
            Store(id: "mock_1", name: "セブンイレブン", nameEn: "7-Eleven",
                  location: .init(latitude: lat + 0.001, longitude: lng + 0.001),
                  category: .convenienceStore,
                  supportedPaymentMethods: ["paypay", "suica", "nanaco", "visa"],
                  address: "東京都渋谷区道玄坂1-1-1",
                  addressEn: "1-1-1 Dogenzaka, Shibuya, Tokyo",
                  photoURL: nil, registeredByUid: nil),

            Store(id: "mock_2", name: "スターバックス", nameEn: "Starbucks",
                  location: .init(latitude: lat - 0.001, longitude: lng - 0.001),
                  category: .cafe,
                  supportedPaymentMethods: ["visa", "mastercard", "suica"],
                  address: "東京都渋谷区神南1-21-3",
                  addressEn: "1-21-3 Jinnan, Shibuya, Tokyo",
                  photoURL: nil, registeredByUid: nil),

            Store(id: "mock_3", name: "マツモトキヨシ", nameEn: "Matsumoto Kiyoshi",
                  location: .init(latitude: lat + 0.002, longitude: lng - 0.001),
                  category: .drugStore,
                  supportedPaymentMethods: ["cash_only"],
                  address: "東京都渋谷区宇田川町21-1",
                  addressEn: "21-1 Udagawacho, Shibuya, Tokyo",
                  photoURL: nil, registeredByUid: nil),

            Store(id: "mock_4", name: "自動販売機", nameEn: "Vending Machine",
                  location: .init(latitude: lat - 0.002, longitude: lng + 0.002),
                  category: .vendingMachine,
                  supportedPaymentMethods: ["suica", "paypay"],
                  address: "東京都渋谷区道玄坂2丁目",
                  addressEn: "Dogenzaka 2-chome, Shibuya, Tokyo",
                  photoURL: nil, registeredByUid: nil),

            Store(id: "mock_5", name: "マクドナルド", nameEn: "McDonald's",
                  location: .init(latitude: lat - 0.0015, longitude: lng + 0.0015),
                  category: .fastFood,
                  supportedPaymentMethods: ["paypay", "suica", "visa"],
                  address: "東京都渋谷区宇田川町29-3",
                  addressEn: "29-3 Udagawacho, Shibuya, Tokyo",
                  photoURL: nil, registeredByUid: nil),
        ]
    }
}
