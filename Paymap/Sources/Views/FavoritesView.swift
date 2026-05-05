import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @StateObject private var vm = FavoritesViewModel()

    var body: some View {
        Group {
            if !purchaseManager.isPremium {
                PremiumGateView()
            } else {
                content
            }
        }
        .navigationTitle(lm.s.favoritesTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if purchaseManager.isPremium, let uid = authViewModel.userProfile?.uid {
                vm.fetch(uid: uid)
            }
        }
    }

    private var content: some View {
        Group {
            if vm.isLoading {
                ProgressView(lm.s.loadingLabel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.stores.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 48)).foregroundColor(.secondary)
                    Text(lm.s.favoritesEmpty).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(vm.stores) { store in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(store.category.color.opacity(0.2)).frame(width: 44, height: 44)
                            Image(systemName: store.category.iconName)
                                .foregroundColor(store.category.color)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.displayName(isEnglish: lm.isEnglish))
                                .font(.subheadline).bold()
                            Text(store.category.localizedName(lm.s))
                                .font(.caption).foregroundColor(.secondary)
                            if let address = store.displayAddress(isEnglish: lm.isEnglish) {
                                Text(address).font(.caption2).foregroundColor(.secondary)
                            }
                            FacilityBadgesRow(store: store)
                        }
                        Spacer()
                        Image(systemName: "heart.fill").foregroundColor(.red)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            if let uid = authViewModel.userProfile?.uid {
                                vm.removeFavorite(store: store, uid: uid)
                            }
                        } label: {
                            Label(lm.s.removeFavorite, systemImage: "heart.slash")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Premium Gate
private struct PremiumGateView: View {
    @EnvironmentObject var lm: LanguageManager

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 64)).foregroundColor(.pink)
            Text(lm.s.favoritesTitle).font(.title2).bold()
            Text(lm.s.favoritesRequiresPremium)
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal)
            NavigationLink(destination: PremiumFeatureView()) {
                Text(lm.s.viewPremiumDetails)
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.yellow).foregroundColor(.black).cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - ViewModel
@MainActor
class FavoritesViewModel: ObservableObject {
    @Published var stores: [Store] = []
    @Published var isLoading = false
    private let storeService = StoreService()

    func fetch(uid: String) {
        isLoading = true
        Task {
            do {
                stores = try await storeService.fetchFavoriteStores(uid: uid)
            } catch {
                stores = []
            }
            isLoading = false
        }
    }

    func removeFavorite(store: Store, uid: String) {
        stores.removeAll { $0.id == store.id }
        Task {
            try? await storeService.toggleFavorite(storeId: store.id, uid: uid, isFavoriting: false)
        }
    }
}
