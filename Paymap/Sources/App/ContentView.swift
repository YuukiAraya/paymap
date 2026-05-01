import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MapView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("マップ")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("マイページ")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
