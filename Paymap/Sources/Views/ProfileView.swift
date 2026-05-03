import SwiftUI
import FirebaseAuth
import FirebaseCore

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var lm: LanguageManager
    @State private var showingEditProfile = false
    @State private var showingRegisteredStores = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
            List {
                // Profile header
                Section {
                    HStack(spacing: 16) {
                        Button(action: { showingEditProfile = true }) {
                            ZStack(alignment: .bottomTrailing) {
                                Image(systemName: "person.circle.fill")
                                    .resizable().frame(width: 64, height: 64)
                                    .foregroundColor(Color.premiumNavy)
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundColor(Color.premiumEmerald)
                                    .background(Color.white.clipShape(Circle()))
                                    .offset(x: 4, y: 4)
                            }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authViewModel.userProfile?.displayName ?? lm.s.guestName)
                                .font(.headline)
                            Text(authViewModel.userProfile?.email ?? "")
                                .font(.subheadline).foregroundColor(.secondary)
                            Button(lm.s.editProfileLink) { showingEditProfile = true }
                                .font(.caption).foregroundColor(Color.premiumEmerald)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Achievements
                Section(header: Text(lm.s.achievementsSection)) {
                    HStack {
                        Text(lm.s.contributionPoints)
                        Spacer()
                        Text("\(authViewModel.userProfile?.totalContributions ?? 0) \(lm.s.pointsUnit)")
                            .bold().foregroundColor(Color.premiumEmerald)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(lm.s.badgesLabel).font(.subheadline)
                        HStack(spacing: 16) {
                            BadgeView(icon: "star.fill",  title: lm.s.brFirstPost, color: .yellow)
                            BadgeView(icon: "flame.fill", title: lm.s.br10,        color: .orange)
                            BadgeView(icon: "crown.fill", title: lm.s.brMaster,    color: .gray).opacity(0.4)
                        }
                    }
                    .padding(.vertical, 8)

                    NavigationLink(destination: ContributionRulesView()) {
                        Label(lm.s.rulesLink, systemImage: "questionmark.circle")
                            .foregroundColor(Color.premiumNavy)
                    }
                }

                // My registered stores
                Section(header: Text(lm.s.registeredStoresSection)) {
                    NavigationLink(destination: MyRegisteredStoresView()) {
                        Label(lm.s.viewRegisteredStores, systemImage: "mappin.and.ellipse")
                            .foregroundColor(Color.premiumNavy)
                    }
                }

                // Premium plan
                Section(header: Text(lm.s.premiumSection)) {
                    NavigationLink(destination: PremiumFeatureView()) {
                        HStack {
                            Image(systemName: "sparkles").foregroundColor(.purple)
                            Text(lm.s.viewPremiumDetails)
                                .foregroundColor(.purple).bold()
                        }
                    }
                }

                // Language
                Section(header: Text(lm.s.languageSection)) {
                    Picker("", selection: Binding(
                        get: { lm.language },
                        set: { lm.language = $0 }
                    )) {
                        ForEach(AppLanguage.allCases, id: \.self) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Logout
                Section {
                    Button(action: { authViewModel.signOut() }) {
                        Text(lm.s.logoutButton).foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(lm.s.myPageTitle)
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
                    .environmentObject(authViewModel)
                    .environmentObject(lm)
            }
            AdBannerContainer(isPremium: authViewModel.userProfile.map { _ in false } ?? false)
            } // VStack
        }
    }
}

// MARK: - Edit Profile
struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var lm: LanguageManager
    @Environment(\.dismiss) private var dismiss
    @State private var nickname = ""
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(lm.s.iconSection)) {
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "person.circle.fill")
                                .resizable().frame(width: 80, height: 80)
                                .foregroundColor(Color.premiumNavy)
                            Button(lm.s.changePhotoDisabled) {}
                                .font(.caption).foregroundColor(.secondary)
                                .disabled(true)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                Section(header: Text(lm.s.nicknameSection)) {
                    TextField(lm.s.nicknamePlaceholder, text: $nickname)
                }
            }
            .navigationTitle(lm.s.editProfileTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(lm.s.cancelButton) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(lm.s.saveButton) { save() }
                        .bold()
                        .disabled(isSaving || nickname.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { nickname = authViewModel.userProfile?.displayName ?? "" }
            .alert(lm.s.errorTitle, isPresented: $showingError) {
                Button(lm.s.okButton) {}
            } message: { Text(errorMessage) }
        }
    }

    private func save() {
        isSaving = true
        Task {
            do {
                try await authViewModel.updateDisplayName(nickname.trimmingCharacters(in: .whitespaces))
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
            isSaving = false
        }
    }
}

// MARK: - My Registered Stores
struct MyRegisteredStoresView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var lm: LanguageManager
    @StateObject private var vm = MyStoresViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView(lm.s.loadingLabel).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.stores.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 48)).foregroundColor(.secondary)
                    Text(lm.s.myStoresEmpty)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(vm.stores) { store in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(store.category.color.opacity(0.2)).frame(width: 40, height: 40)
                            Image(systemName: store.category.iconName)
                                .foregroundColor(store.category.color)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.displayName(isEnglish: lm.isEnglish)).font(.subheadline).bold()
                            Text(store.category.localizedName(lm.s))
                                .font(.caption).foregroundColor(.secondary)
                            if let address = store.displayAddress(isEnglish: lm.isEnglish) {
                                Text(address).font(.caption2).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(lm.s.myStoresTitle)
        .onAppear {
            if let uid = authViewModel.userProfile?.uid {
                vm.fetchMyStores(uid: uid)
            }
        }
    }
}

@MainActor
class MyStoresViewModel: ObservableObject {
    @Published var stores: [Store] = []
    @Published var isLoading = false
    private let storeService = StoreService()

    func fetchMyStores(uid: String) {
        isLoading = true
        Task {
            do {
                stores = try await storeService.fetchStoresByUser(uid: uid)
            } catch {
                stores = []
            }
            isLoading = false
        }
    }
}

// MARK: - Badge View
struct BadgeView: View {
    let icon: String; let title: String; let color: Color
    var body: some View {
        VStack {
            Image(systemName: icon).resizable().scaledToFit()
                .frame(height: 30).foregroundColor(color)
            Text(title).font(.caption2)
        }
    }
}

// MARK: - Premium Feature View
struct PremiumFeatureView: View {
    @EnvironmentObject var lm: LanguageManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "crown.fill").resizable()
                    .frame(width: 80, height: 80).foregroundColor(.yellow).padding(.top, 40)
                Text(lm.s.premiumTitle).font(.largeTitle).bold()
                VStack(alignment: .leading, spacing: 20) {
                    PremiumFeatureRow(icon: "eye.slash",
                                      title: lm.s.premiumNoAds,
                                      description: lm.s.premiumNoAdsDesc)
                    PremiumFeatureRow(icon: "line.3.horizontal.decrease.circle",
                                      title: lm.s.premiumSearch,
                                      description: lm.s.premiumSearchDesc)
                    PremiumFeatureRow(icon: "map.fill",
                                      title: lm.s.premiumOffline,
                                      description: lm.s.premiumOfflineDesc)
                    PremiumFeatureRow(icon: "mappin.circle",
                                      title: lm.s.premiumCustomPin,
                                      description: lm.s.premiumCustomPinDesc)
                }
                .padding()
                Button(action: { print("Upgrade tapped") }) {
                    Text(lm.s.premiumUpgrade)
                        .font(.headline).frame(maxWidth: .infinity).padding()
                        .background(Color.yellow).foregroundColor(.black).cornerRadius(12)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(lm.s.premiumSection)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PremiumFeatureRow: View {
    let icon: String; let title: String; let description: String
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon).resizable().scaledToFit()
                .frame(width: 30, height: 30).foregroundColor(.purple)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(description).font(.subheadline).foregroundColor(.secondary)
            }
        }
    }
}
