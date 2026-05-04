import SwiftUI
import Firebase
import GoogleMaps
import GoogleSignIn
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        MobileAds.shared.start(completionHandler: nil)
        return true
    }

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct PaymapApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var purchaseManager = PurchaseManager()

    init() {
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String ?? ""
        GMSServices.provideAPIKey(apiKey)

        if let _ = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            FirebaseApp.configure()
        } else {
            print("⚠️ GoogleService-Info.plist not found. Firebase features will not work.")
        }
    }

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                ContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(languageManager)
                    .environmentObject(locationManager)
                    .environmentObject(purchaseManager)
            } else {
                AuthView()
                    .environmentObject(authViewModel)
                    .environmentObject(languageManager)
            }
        }
    }
}
