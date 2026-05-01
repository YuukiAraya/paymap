import SwiftUI
import FirebaseAuth
import FirebaseCore

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingEditProfile = false
    @State private var showingRegisteredStores = false

    var body: some View {
        NavigationView {
            List {
                // プロフィールヘッダー
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
                            Text(authViewModel.userProfile?.displayName ?? "ゲスト")
                                .font(.headline)
                            Text(authViewModel.userProfile?.email ?? "")
                                .font(.subheadline).foregroundColor(.secondary)
                            Button("プロフィールを編集") { showingEditProfile = true }
                                .font(.caption).foregroundColor(Color.premiumEmerald)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // 実績・インセンティブ
                Section(header: Text("実績・インセンティブ")) {
                    HStack {
                        Text("貢献ポイント")
                        Spacer()
                        Text("\(authViewModel.userProfile?.totalContributions ?? 0) pt")
                            .bold().foregroundColor(Color.premiumEmerald)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("獲得バッジ").font(.subheadline)
                        HStack(spacing: 16) {
                            BadgeView(icon: "star.fill",  title: "初投稿",    color: .yellow)
                            BadgeView(icon: "flame.fill", title: "10件達成",  color: .orange)
                            BadgeView(icon: "crown.fill", title: "決済マスター", color: .gray).opacity(0.4)
                        }
                    }
                    .padding(.vertical, 8)

                    NavigationLink(destination: ContributionRulesView()) {
                        Label("貢献ポイントの獲得ルールを見る", systemImage: "questionmark.circle")
                            .foregroundColor(Color.premiumNavy)
                    }
                }

                // 自分が登録した店舗
                Section(header: Text("登録した店舗")) {
                    NavigationLink(destination: MyRegisteredStoresView()) {
                        Label("登録した店舗一覧", systemImage: "mappin.and.ellipse")
                            .foregroundColor(Color.premiumNavy)
                    }
                }

                // プレミアムプラン
                Section(header: Text("プレミアムプラン")) {
                    NavigationLink(destination: PremiumFeatureView()) {
                        HStack {
                            Image(systemName: "sparkles").foregroundColor(.purple)
                            Text("プレミアム機能の詳細を見る")
                                .foregroundColor(.purple).bold()
                        }
                    }
                }

                // ログアウト
                Section {
                    Button(action: { authViewModel.signOut() }) {
                        Text("ログアウト").foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("マイページ")
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

// MARK: - プロフィール編集
struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var nickname = ""
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("アイコン")) {
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: "person.circle.fill")
                                .resizable().frame(width: 80, height: 80)
                                .foregroundColor(Color.premiumNavy)
                            Button("写真を変更（準備中）") {}
                                .font(.caption).foregroundColor(.secondary)
                                .disabled(true)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                Section(header: Text("ニックネーム")) {
                    TextField("ニックネームを入力", text: $nickname)
                }
            }
            .navigationTitle("プロフィール編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { save() }
                        .bold()
                        .disabled(isSaving || nickname.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { nickname = authViewModel.userProfile?.displayName ?? "" }
            .alert("エラー", isPresented: $showingError) {
                Button("OK") {}
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

// MARK: - 登録した店舗一覧
struct MyRegisteredStoresView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var vm = MyStoresViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView("読み込み中…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.stores.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "mappin.slash")
                        .font(.system(size: 48)).foregroundColor(.secondary)
                    Text("まだ登録した店舗がありません")
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
                            Text(store.name).font(.subheadline).bold()
                            Text(store.category.displayName)
                                .font(.caption).foregroundColor(.secondary)
                            if let address = store.address {
                                Text(address).font(.caption2).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("登録した店舗")
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
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "crown.fill").resizable()
                    .frame(width: 80, height: 80).foregroundColor(.yellow).padding(.top, 40)
                Text("PayMap Premium").font(.largeTitle).bold()
                VStack(alignment: .leading, spacing: 20) {
                    PremiumFeatureRow(icon: "eye.slash",      title: "広告非表示",
                                      description: "マップや店舗詳細画面の広告がすべて非表示になります。")
                    PremiumFeatureRow(icon: "line.3.horizontal.decrease.circle", title: "高度な絞り込み検索",
                                      description: "「PayPayが使える × 深夜営業」など条件を組み合わせた検索が可能に。")
                    PremiumFeatureRow(icon: "map.fill",       title: "オフラインマップ",
                                      description: "電波の届かない地下の店舗でも決済手段を確認できます。")
                    PremiumFeatureRow(icon: "mappin.circle",  title: "オリジナルマップピン",
                                      description: "あなたのマップピンを特別なデザインにカスタマイズできます。")
                }
                .padding()
                Button(action: { print("Upgrade tapped") }) {
                    Text("月額 300円でアップグレード")
                        .font(.headline).frame(maxWidth: .infinity).padding()
                        .background(Color.yellow).foregroundColor(.black).cornerRadius(12)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("プレミアムプラン")
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
