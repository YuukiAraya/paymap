import Foundation

struct PaymentMethod: Identifiable, Codable {
    let id: String
    let name: String
    let iconName: String
    let type: PaymentType
    
    enum PaymentType: String, Codable {
        case creditCard
        case electronicMoney
        case qrCode
        case other
    }
}
