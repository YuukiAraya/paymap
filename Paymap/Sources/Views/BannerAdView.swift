import SwiftUI
import GoogleMobileAds

// MARK: - Banner Ad View
struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    init(adUnitID: String = "ca-app-pub-4490113823639458/5672872963") {
        self.adUnitID = adUnitID
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = context.coordinator.rootViewController()
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject {
        func rootViewController() -> UIViewController? {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows.first?.rootViewController
        }
    }
}

// MARK: - Ad Banner Container（プレミアムユーザーは非表示）
struct AdBannerContainer: View {
    var isPremium: Bool = false

    var body: some View {
        if !isPremium {
            BannerAdView()
                .frame(height: 50)
                .frame(maxWidth: .infinity)
        }
    }
}
