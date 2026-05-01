import Foundation
import CoreLocation

protocol PlacesServiceProtocol {
    func fetchNearbyPlaces(coordinate: CLLocationCoordinate2D, radius: Double) async throws -> [Store]
}

class PlacesService: PlacesServiceProtocol {
    func fetchNearbyPlaces(coordinate: CLLocationCoordinate2D, radius: Double) async throws -> [Store] {
        try await Task.sleep(nanoseconds: 800_000_000)

        let lat = coordinate.latitude
        let lng = coordinate.longitude

        return [
            Store(id: "place_1",
                  name: "セブンイレブン 渋谷駅前店",
                  location: Store.Coordinate(latitude: lat + 0.001, longitude: lng + 0.001),
                  category: .convenienceStore,
                  supportedPaymentMethods: ["paypay", "suica", "nanaco", "visa", "mastercard"],
                  address: "東京都渋谷区道玄坂1-1-1",
                  registeredByUid: nil),

            Store(id: "place_2",
                  name: "スターバックス 渋谷モディ店",
                  location: Store.Coordinate(latitude: lat - 0.001, longitude: lng - 0.001),
                  category: .cafe,
                  supportedPaymentMethods: ["visa", "mastercard", "jcb", "suica", "pasmo"],
                  address: "東京都渋谷区神南1-21-3",
                  registeredByUid: nil),

            Store(id: "place_3",
                  name: "マツモトキヨシ 渋谷Part1店",
                  location: Store.Coordinate(latitude: lat + 0.002, longitude: lng - 0.001),
                  category: .drugStore,
                  supportedPaymentMethods: ["cash_only"],
                  address: "東京都渋谷区宇田川町21-1",
                  registeredByUid: nil),

            Store(id: "place_4",
                  name: "コカ・コーラ自販機（道玄坂）",
                  location: Store.Coordinate(latitude: lat - 0.002, longitude: lng + 0.002),
                  category: .vendingMachine,
                  supportedPaymentMethods: ["coke_on", "suica", "paypay"],
                  address: "東京都渋谷区道玄坂2丁目",
                  registeredByUid: nil),

            Store(id: "place_5",
                  name: "焼鳥 山田屋",
                  location: Store.Coordinate(latitude: lat + 0.0015, longitude: lng - 0.002),
                  category: .izakaya,
                  supportedPaymentMethods: ["visa", "mastercard", "paypay"],
                  address: "東京都渋谷区円山町5-3",
                  registeredByUid: nil),

            Store(id: "place_6",
                  name: "マクドナルド 渋谷センター街店",
                  location: Store.Coordinate(latitude: lat - 0.0015, longitude: lng + 0.0015),
                  category: .fastFood,
                  supportedPaymentMethods: ["paypay", "linepay", "suica", "visa"],
                  address: "東京都渋谷区宇田川町29-3",
                  registeredByUid: nil),

            Store(id: "place_7",
                  name: "東急ストア 渋谷店",
                  location: Store.Coordinate(latitude: lat + 0.003, longitude: lng + 0.001),
                  category: .supermarket,
                  supportedPaymentMethods: ["suica", "pasmo", "waon", "visa", "mastercard", "jcb"],
                  address: "東京都渋谷区道玄坂2-24-1",
                  registeredByUid: nil),
        ]
    }
}
