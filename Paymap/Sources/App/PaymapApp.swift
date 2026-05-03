import SwiftUI
import Firebase
import GoogleMaps
import GoogleSignIn
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // AdMob 初期化
        MobileAds.shared.start(completionHandler: nil)
        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct PaymapApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var languageManager = LanguageManager()

    init() {
        // Google Maps SDK
        GMSServices.provideAPIKey("AIzaSyC5nAa-MuY8Ef1uG0bSYhl5nKdlXMrkpqw")

        // Firebase
        if let _ = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            FirebaseApp.configure()
        } else {
            print("⚠️ GoogleService-Info.plist not found. Firebase features will not work. See Docs/00_AI_Handover.md for setup instructions.")
        }
    }

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                ContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(languageManager)
            } else {
                AuthView()
                    .environmentObject(authViewModel)
                    .environmentObject(languageManager)
            }
        }
    }
}
