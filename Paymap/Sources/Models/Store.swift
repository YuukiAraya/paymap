import Foundation
import CoreLocation
import SwiftUI

struct Store: Identifiable, Codable {
    let id: String
    let name: String
    let location: Coordinate
    let category: StoreCategory
    var supportedPaymentMethods: [String] // Array of PaymentMethod IDs
    
    struct Coordinate: Codable {
        let latitude: Double
        let longitude: Double
    }
    
    var clLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
    }
}

enum StoreCategory: String, Codable, CaseIterable {
    case convenienceStore = "コンビニ"
    case cafe = "カフェ"
    case vendingMachine = "自動販売機"
    case drugStore = "ドラッグストア"
    case restaurant = "レストラン"
    case other = "その他"
    
    var displayName: String {
        self.rawValue
    }
    
    var iconName: String {
        switch self {
        case .convenienceStore: return "cart.fill"
        case .cafe: return "cup.and.saucer.fill"
        case .vendingMachine: return "takeoutbag.and.cup.and.straw.fill"
        case .drugStore: return "cross.case.fill"
        case .restaurant: return "fork.knife"
        case .other: return "mappin"
        }
    }
    
    var color: Color {
        switch self {
        case .convenienceStore: return .orange
        case .cafe: return .brown
        case .vendingMachine: return .cyan
        case .drugStore: return .pink
        case .restaurant: return .red
        case .other: return Color.premiumNavy
        }
    }
    
    // For UIKit/Google Maps compatibility
    var uiColor: UIColor {
        UIColor(color)
    }
}
