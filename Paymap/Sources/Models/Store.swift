import Foundation
import CoreLocation
import SwiftUI

struct Store: Identifiable, Codable {
    let id: String
    let name: String
    var nameEn: String?
    let location: Coordinate
    let category: StoreCategory
    var supportedPaymentMethods: [String]
    var address: String?
    var addressEn: String?
    var registeredByUid: String?

    struct Coordinate: Codable {
        let latitude: Double
        let longitude: Double
    }

    func displayName(isEnglish: Bool) -> String {
        isEnglish ? (nameEn?.isEmpty == false ? nameEn! : name) : name
    }

    func displayAddress(isEnglish: Bool) -> String? {
        isEnglish ? (addressEn ?? address) : address
    }

    var clLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
    }

    var googleMapsURL: URL? {
        let q = "\(location.latitude),\(location.longitude)"
        guard let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: "https://www.google.com/maps/search/?api=1&query=\(encoded)")
    }
}

enum StoreCategory: String, Codable, CaseIterable {
    case convenienceStore = "コンビニ"
    case cafe             = "カフェ"
    case restaurant       = "レストラン"
    case izakaya          = "居酒屋"
    case fastFood         = "ファストフード"
    case supermarket      = "スーパー"
    case drugStore        = "ドラッグストア"
    case hotel            = "ホテル"
    case vendingMachine   = "自動販売機"
    case other            = "その他"

    var displayName: String { rawValue }

    func localizedName(_ l10n: L10n) -> String {
        switch self {
        case .convenienceStore: return l10n.catConvenience
        case .cafe:             return l10n.catCafe
        case .restaurant:       return l10n.catRestaurant
        case .izakaya:          return l10n.catIzakaya
        case .fastFood:         return l10n.catFastFood
        case .supermarket:      return l10n.catSupermarket
        case .drugStore:        return l10n.catDrugStore
        case .hotel:            return l10n.catHotel
        case .vendingMachine:   return l10n.catVending
        case .other:            return l10n.catOther
        }
    }

    var iconName: String {
        switch self {
        case .convenienceStore: return "cart.fill"
        case .cafe:             return "cup.and.saucer.fill"
        case .restaurant:       return "fork.knife"
        case .izakaya:          return "wineglass.fill"
        case .fastFood:         return "bag.fill"
        case .supermarket:      return "basket.fill"
        case .drugStore:        return "cross.case.fill"
        case .hotel:            return "bed.double.fill"
        case .vendingMachine:   return "takeoutbag.and.cup.and.straw.fill"
        case .other:            return "mappin"
        }
    }

    var color: Color {
        switch self {
        case .convenienceStore: return .orange
        case .cafe:             return .brown
        case .restaurant:       return .red
        case .izakaya:          return .purple
        case .fastFood:         return Color(red: 0.85, green: 0.65, blue: 0.0)
        case .supermarket:      return .green
        case .drugStore:        return .pink
        case .hotel:            return .indigo
        case .vendingMachine:   return .cyan
        case .other:            return Color.premiumNavy
        }
    }

    var uiColor: UIColor { UIColor(color) }
}
