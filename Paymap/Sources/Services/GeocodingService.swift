import Foundation
import CoreLocation

// CLGeocoder を使用した実装（Google Geocoding REST API の代替）
// → GCP の 100% エラーを解消し、APIキー制限の影響を受けない
struct GeocodingService {

    // MARK: - 逆ジオコーディング（座標 → 住所）
    func reverseGeocode(_ coordinate: CLLocationCoordinate2D, language: String = "ja") async -> String? {
        guard let placemark = await clReverseGeocode(coordinate, locale: language) else { return nil }
        return buildAddress(from: placemark, language: language)
    }

    // MARK: - 住所 → 座標
    func geocodeAddress(_ address: String) async -> CLLocationCoordinate2D? {
        return await clGeocode(address, locale: "ja")?.location?.coordinate
    }

    // MARK: - 住所 → 英語表記
    func translateAddressToEnglish(_ japaneseAddress: String) async -> String? {
        guard let placemark = await clGeocode(japaneseAddress, locale: "en") else { return nil }
        return buildAddress(from: placemark, language: "en")
    }

    // MARK: - 住所 → 座標 + 英語住所
    func geocodeFull(_ address: String) async -> (coordinate: CLLocationCoordinate2D, addressEn: String?)? {
        guard let placemark = await clGeocode(address, locale: "ja"),
              let coord = placemark.location?.coordinate else { return nil }
        let enPlacemark = await clGeocode(address, locale: "en")
        let addressEn = enPlacemark.map { buildAddress(from: $0, language: "en") }
        return (coord, addressEn)
    }

    // MARK: - Private helpers

    private func clGeocode(_ address: String, locale: String) async -> CLPlacemark? {
        guard !address.isEmpty else { return nil }
        let preferredLocale = Locale(identifier: locale == "en" ? "en_US" : "ja_JP")
        return await withCheckedContinuation { continuation in
            CLGeocoder().geocodeAddressString(
                address,
                in: nil,
                preferredLocale: preferredLocale
            ) { placemarks, _ in
                continuation.resume(returning: placemarks?.first)
            }
        }
    }

    private func clReverseGeocode(_ coord: CLLocationCoordinate2D, locale: String) async -> CLPlacemark? {
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        let preferredLocale = Locale(identifier: locale == "en" ? "en_US" : "ja_JP")
        return await withCheckedContinuation { continuation in
            CLGeocoder().reverseGeocodeLocation(
                location,
                preferredLocale: preferredLocale
            ) { placemarks, _ in
                continuation.resume(returning: placemarks?.first)
            }
        }
    }

    private func buildAddress(from placemark: CLPlacemark, language: String) -> String {
        if language == "en" {
            let parts = [
                placemark.subThoroughfare,
                placemark.thoroughfare,
                placemark.subLocality,
                placemark.locality,
                placemark.administrativeArea,
            ].compactMap { $0 }
            return parts.isEmpty ? (placemark.name ?? "") : parts.joined(separator: " ")
        } else {
            let parts = [
                placemark.administrativeArea,
                placemark.locality,
                placemark.subLocality,
                placemark.thoroughfare,
                placemark.subThoroughfare,
            ].compactMap { $0 }
            return parts.isEmpty ? (placemark.name ?? "") : parts.joined()
        }
    }
}
