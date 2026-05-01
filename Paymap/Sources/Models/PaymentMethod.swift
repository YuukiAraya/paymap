import Foundation
import SwiftUI

struct PaymentMethod: Identifiable, Codable {
    let id: String
    let name: String
    let iconName: String
    let type: PaymentType

    enum PaymentType: String, Codable {
        case creditCard, electronicMoney, qrCode, other
    }
}

// MARK: - Payment Catalog
enum PaymentCatalog {

    struct Entry: Identifiable {
        let id: String
        let displayName: String
        let group: Group
        let iconName: String

        enum Group: String, CaseIterable {
            case creditCard = "クレジットカード"
            case qr         = "QRコード決済"
            case ic         = "電子マネー・IC"
            case other      = "その他"
        }
    }

    static let all: [Entry] = [
        // クレジットカード
        Entry(id: "visa",        displayName: "Visa",             group: .creditCard, iconName: "creditcard.fill"),
        Entry(id: "mastercard",  displayName: "Mastercard",       group: .creditCard, iconName: "creditcard.fill"),
        Entry(id: "jcb",         displayName: "JCB",              group: .creditCard, iconName: "creditcard.fill"),
        Entry(id: "amex",        displayName: "American Express", group: .creditCard, iconName: "creditcard.fill"),
        Entry(id: "diners",      displayName: "Diners Club",      group: .creditCard, iconName: "creditcard.fill"),
        Entry(id: "unionpay",    displayName: "銀聯 (UnionPay)",  group: .creditCard, iconName: "creditcard.fill"),
        // QRコード決済
        Entry(id: "paypay",      displayName: "PayPay",           group: .qr, iconName: "qrcode"),
        Entry(id: "linepay",     displayName: "LINE Pay",         group: .qr, iconName: "qrcode"),
        Entry(id: "rakuten_pay", displayName: "楽天Pay",           group: .qr, iconName: "qrcode"),
        Entry(id: "au_pay",      displayName: "au PAY",           group: .qr, iconName: "qrcode"),
        Entry(id: "merpay",      displayName: "メルペイ",           group: .qr, iconName: "qrcode"),
        // 電子マネー・IC
        Entry(id: "suica",       displayName: "Suica",            group: .ic, iconName: "wave.3.right"),
        Entry(id: "pasmo",       displayName: "PASMO",            group: .ic, iconName: "wave.3.right"),
        Entry(id: "nanaco",      displayName: "nanaco",           group: .ic, iconName: "wave.3.right"),
        Entry(id: "waon",        displayName: "WAON",             group: .ic, iconName: "wave.3.right"),
        Entry(id: "quicpay",     displayName: "QUICPay",          group: .ic, iconName: "wave.3.right"),
        Entry(id: "id_payment",  displayName: "iD",               group: .ic, iconName: "wave.3.right"),
        Entry(id: "coke_on",     displayName: "Coke ON Pay",      group: .ic, iconName: "wave.3.right"),
        // その他
        Entry(id: "cash_only",   displayName: "現金のみ",           group: .other, iconName: "yensign.circle"),
    ]

    static func displayName(for id: String) -> String {
        all.first { $0.id == id }?.displayName ?? id
    }

    static func iconName(for id: String) -> String {
        all.first { $0.id == id }?.iconName ?? "creditcard"
    }

    static var grouped: [(group: Entry.Group, entries: [Entry])] {
        Entry.Group.allCases.compactMap { group in
            let entries = all.filter { $0.group == group }
            return entries.isEmpty ? nil : (group: group, entries: entries)
        }
    }
}
