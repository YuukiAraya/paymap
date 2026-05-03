import Foundation

struct GeocodingService {
    private let apiKey = "AIzaSyC5nAa-MuY8Ef1uG0bSYhl5nKdlXMrkpqw"

    func translateAddressToEnglish(_ japaneseAddress: String) async -> String? {
        guard !japaneseAddress.isEmpty,
              let encoded = japaneseAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?address=\(encoded)&key=\(apiKey)&language=en")
        else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(GeocodingResponse.self, from: data)
            return response.results.first?.formattedAddress
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
    enum CodingKeys: String, CodingKey {
        case formattedAddress = "formatted_address"
    }
}
