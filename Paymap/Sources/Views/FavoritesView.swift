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
            if let uid = authViewModel.userProfile?.uid {
                Task { await vm.fetch(uid: uid) }
            }
        }
        .onChange(of: authViewModel.userProfile?.uid) { uid in
            guard let uid else { return }
            Task { await vm.fetch(uid: uid) }
        }
    }

    private var content: some View {
        List {
            if vm.isLoading {
                HStack {
                    Spacer()
                    ProgressView(lm.s.loadingLabel)
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else if vm.stores.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 48)).foregroundColor(.secondary)
                        Text(lm.s.favoritesEmpty).foregroundColor(.secondary)
                    }
                    .padding(.top, 80)
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            } else {
                ForEach(vm.stores) { store in
                    Button(action: {
                        NotificationCenter.default.post(
                            name: .navigateToStore,
                            object: nil,
                            userInfo: ["store": store]
                        )
                    }) {
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
                        .foregroundColor(.primary)
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
        .refreshable {
            if let uid = authViewModel.userProfile?.uid {
                await vm.fetch(uid: uid)
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

    func fetch(uid: String) async {
        isLoading = true
        do {
            stores = try await storeService.fetchFavoriteStores(uid: uid)
        } catch {
            // エラー時は既存データを保持（空にしない）
        }
        isLoading = false
    }

    func removeFavorite(store: Store, uid: String) {
        stores.removeAll { $0.id == store.id }
        Task {
            try? await storeService.toggleFavorite(storeId: store.id, uid: uid, isFavoriting: false)
        }
    }
}
