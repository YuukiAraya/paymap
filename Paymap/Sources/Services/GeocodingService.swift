import Foundation
import CoreLocation

struct GeocodingService {
    private var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String ?? ""
    }

    // 座標 → 住所（逆ジオコーディング）
    func reverseGeocode(_ coordinate: CLLocationCoordinate2D, language: String = "ja") async -> String? {
        let lat = coordinate.latitude
        let lng = coordinate.longitude
        guard let url = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(lat),\(lng)&key=\(apiKey)&language=\(language)")
        else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(GeocodingResponse.self, from: data)
            return response.results.first?.formattedAddress
        } catch { return nil }
    }

    // 住所 → 英語表記に翻訳
    func translateAddressToEnglish(_ japaneseAddress: String) async -> String? {
        return await geocode(japaneseAddress, language: "en").flatMap { $0.formattedAddress }
    }

    // 住所 → 座標変換
    func geocodeAddress(_ address: String) async -> CLLocationCoordinate2D? {
        guard let result = await geocode(address, language: "ja") else { return nil }
        return CLLocationCoordinate2D(latitude: result.lat, longitude: result.lng)
    }

    // 住所 → 座標 + 英語住所を同時取得
    func geocodeFull(_ address: String) async -> (coordinate: CLLocationCoordinate2D, addressEn: String?)? {
        guard let ja = await geocode(address, language: "ja") else { return nil }
        let addressEn = await geocode(address, language: "en")?.formattedAddress
        return (CLLocationCoordinate2D(latitude: ja.lat, longitude: ja.lng), addressEn)
    }

    private struct GeoResult {
        let lat: Double
        let lng: Double
        let formattedAddress: String
    }

    private func geocode(_ address: String, language: String) async -> GeoResult? {
        guard !address.isEmpty,
              let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?address=\(encoded)&key=\(apiKey)&language=\(language)")
        else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(GeocodingResponse.self, from: data)
            guard let first = response.results.first else { return nil }
            return GeoResult(
                lat: first.geometry.location.lat,
                lng: first.geometry.location.lng,
                formattedAddress: first.formattedAddress
            )
        } catch {
            return nil
        }
    }
}

private struct GeocodingResponse: Decodable {
    let results: [GeocodingResult]
}

private struct GeocodingResult: Decodable {
    let formattedAddress: String
    let geometry: GeocodingGeometry
    enum CodingKeys: String, CodingKey {
        case formattedAddress = "formatted_address"
        case geometry
    }
}

private struct GeocodingGeometry: Decodable {
    let location: GeocodingLocation
}

private struct GeocodingLocation: Decodable {
    let lat: Double
    let lng: Double
}
