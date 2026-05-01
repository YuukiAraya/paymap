import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MapView()
                .tabItem { Label("マップ", systemImage: "map.fill") }

            StoreRegisterView()
                .tabItem { Label("店舗登録", systemImage: "plus.circle.fill") }

            ProfileView()
                .tabItem { Label("マイページ", systemImage: "person.fill") }
        }
        .tint(Color.premiumEmerald)
    }
}
