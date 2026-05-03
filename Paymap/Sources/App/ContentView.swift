import SwiftUI

struct ContentView: View {
    @EnvironmentObject var lm: LanguageManager

    var body: some View {
        TabView {
            MapView()
                .tabItem { Label(lm.s.tabMap, systemImage: "map.fill") }

            StoreRegisterView()
                .tabItem { Label(lm.s.tabRegister, systemImage: "plus.circle.fill") }

            ProfileView()
                .tabItem { Label(lm.s.tabMyPage, systemImage: "person.fill") }
        }
        .tint(Color.premiumEmerald)
    }
}
