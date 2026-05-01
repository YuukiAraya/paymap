import SwiftUI
import GoogleMaps

@main
struct PaymapApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        GMSServices.provideAPIKey("AIzaSyCEUXvgia4w1DzQTNL8mYcoljVcczMsR44")
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
