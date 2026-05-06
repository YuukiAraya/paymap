import SwiftUI

struct ContentView: View {
    @EnvironmentObject var lm: LanguageManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MapView()
                .tabItem { Label(lm.s.tabMap, systemImage: "map.fill") }
                .tag(0)

            StoreRegisterView()
                .tabItem { Label(lm.s.tabRegister, systemImage: "plus.circle.fill") }
                .tag(1)

            ProfileView()
                .tabItem { Label(lm.s.tabMyPage, systemImage: "person.fill") }
                .tag(2)
        }
        .tint(Color.premiumEmerald)
        // 登録店舗一覧からタップ → マップタブへ自動遷移
        .onReceive(NotificationCenter.default.publisher(for: .navigateToStore)) { _ in
            selectedTab = 0
        }
    }
}
