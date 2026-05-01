import SwiftUI
import Firebase
import GoogleMaps

@main
struct PaymapApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        // Google Maps SDK
        GMSServices.provideAPIKey("AIzaSyCEUXvgia4w1DzQTNL8mYcoljVcczMsR44")
        
        // Firebase - requires GoogleService-Info.plist in project root
        // If plist is not yet configured, Firebase will not initialize (app still runs in mock mode)
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
            } else {
                AuthView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
