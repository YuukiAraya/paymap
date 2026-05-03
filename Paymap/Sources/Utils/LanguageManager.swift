import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable {
    case japanese = "ja"
    case english  = "en"

    var displayName: String {
        switch self {
        case .japanese: return "日本語"
        case .english:  return "English"
        }
    }
}

class LanguageManager: ObservableObject {
    @AppStorage("appLanguage") var languageRaw: String = "ja" {
        didSet { objectWillChange.send() }
    }

    var language: AppLanguage {
        get { AppLanguage(rawValue: languageRaw) ?? .japanese }
        set { languageRaw = newValue.rawValue }
    }

    var isEnglish: Bool { language == .english }

    // Convenience: access all localized strings
    var s: L10n { isEnglish ? .english : .japanese }
}
