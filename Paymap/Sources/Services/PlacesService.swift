import Foundation
import CoreLocation

protocol PlacesServiceProtocol {
    func fetchNearbyPlaces(coordinate: CLLocationCoordinate2D, radius: Double) async throws -> [Store]
}

// MARK: - Google Places API (New) v1
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
            guard let url = URL(string: "https://places.googleapis.com/v1/places:searchNearby") else {
                return MockPlacesService().mockStores(near: coordinate)
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
            request.setValue(
                "places.id,places.displayName,places.formattedAddress,places.location,places.types,places.photos",
                forHTTPHeaderField: "X-Goog-FieldMask"
            )
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = [
                "locationRestriction": [
                    "circle": [
                        "center": [
                            "latitude":  coordinate.latitude,
                            "longitude": coordinate.longitude,
                        ],
                        "radius": radius,
                    ],
                ],
                "maxResultCount": 20,
                "languageCode": "ja",
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                return MockPlacesService().mockStores(near: coordinate)
            }
            let decoded = try JSONDecoder().decode(NewPlacesResponse.self, from: data)
            let stores = decoded.places?.compactMap { Store(fromNew: $0, apiKey: apiKey) } ?? []
            return stores.isEmpty ? MockPlacesService().mockStores(near: coordinate) : stores
        } catch {
            return MockPlacesService().mockStores(near: coordinate)
        }
    }
}

// MARK: - New Places API response models

private struct NewPlacesResponse: Decodable {
    let places: [NewPlaceResult]?
}

private struct NewPlaceResult: Decodable {
    let id: String
    let displayName: DisplayName?
    let formattedAddress: String?
    let location: LatLng?
    let types: [String]?
    let photos: [PlacePhoto]?

    struct DisplayName: Decodable {
        let text: String
    }
    struct LatLng: Decodable {
        let latitude: Double
        let longitude: Double
    }
    struct PlacePhoto: Decodable {
        // e.g. "places/ChIJ.../photos/AbCd..."
        let name: String
    }
}

private extension Store {
    init?(fromNew result: NewPlaceResult, apiKey: String) {
        guard let lat = result.location?.latitude,
              let lng = result.location?.longitude
        else { return nil }

        // 写真URLは Places API (New) のメディアエンドポイントを使用
        let photoURL: String? = result.photos?.first.map { photo in
            "https://places.googleapis.com/v1/\(photo.name)/media?key=\(apiKey)&maxHeightPx=600"
        }

        self.init(
            id: result.id,
            name: result.displayName?.text ?? "",
            nameEn: nil,
            location: Store.Coordinate(latitude: lat, longitude: lng),
            category: StoreCategory(googleTypes: result.types ?? []),
            supportedPaymentMethods: [],
            address: result.formattedAddress,
            addressEn: nil,
            photoURL: photoURL,
            registeredByUid: nil
        )
    }
}

private extension StoreCategory {
    init(googleTypes: [String]) {
        let t = Set(googleTypes)
        if      t.contains("convenience_store")                               { self = .convenienceStore }
        else if t.contains("cafe")                                            { self = .cafe }
        else if t.contains("bar")                                             { self = .bar }
        else if t.contains("night_club")                                      { self = .izakaya }
        else if t.contains("meal_takeaway") || t.contains("meal_delivery")    { self = .fastFood }
        else if t.contains("supermarket")  || t.contains("grocery_or_supermarket") { self = .supermarket }
        else if t.contains("pharmacy")     || t.contains("drugstore")         { self = .drugStore }
        else if t.contains("lodging")                                         { self = .hotel }
        else if t.contains("restaurant")   || t.contains("food")              { self = .restaurant }
        else                                                                   { self = .other }
    }
}

// MARK: - Mock fallback

private struct MockPlacesService {
    func mockStores(near coordinate: CLLocationCoordinate2D) -> [Store] {
        let lat = coordinate.latitude
        let lng = coordinate.longitude
        return [
            Store(id: "mock_1", name: "セブンイレブン", nameEn: "7-Eleven",
                  location: .init(latitude: lat + 0.001, longitude: lng + 0.001),
                  category: .convenienceStore,
                  supportedPaymentMethods: ["paypay", "suica", "nanaco", "visa"],
                  address: "（サンプルデータ）", addressEn: "(sample)",
                  photoURL: nil, registeredByUid: nil),

            Store(id: "mock_2", name: "スターバックス", nameEn: "Starbucks",
                  location: .init(latitude: lat - 0.001, longitude: lng - 0.001),
                  category: .cafe,
                  supportedPaymentMethods: ["visa", "mastercard", "suica"],
                  address: "（サンプルデータ）", addressEn: "(sample)",
                  photoURL: nil, registeredByUid: nil),

            Store(id: "mock_3", name: "マツモトキヨシ", nameEn: "Matsumoto Kiyoshi",
                  location: .init(latitude: lat + 0.002, longitude: lng - 0.001),
                  category: .drugStore,
                  supportedPaymentMethods: ["cash_only"],
                  address: "（サンプルデータ）", addressEn: "(sample)",
                  photoURL: nil, registeredByUid: nil),

            Store(id: "mock_4", name: "自動販売機", nameEn: "Vending Machine",
                  location: .init(latitude: lat - 0.002, longitude: lng + 0.002),
                  category: .vendingMachine,
                  supportedPaymentMethods: ["suica", "paypay"],
                  address: "（サンプルデータ）", addressEn: "(sample)",
                  photoURL: nil, registeredByUid: nil),

            Store(id: "mock_5", name: "マクドナルド", nameEn: "McDonald's",
                  location: .init(latitude: lat - 0.0015, longitude: lng + 0.0015),
                  category: .fastFood,
                  supportedPaymentMethods: ["paypay", "suica", "visa"],
                  address: "（サンプルデータ）", addressEn: "(sample)",
                  photoURL: nil, registeredByUid: nil),
        ]
    }
}
