import SwiftUI
import CoreLocation
import GoogleMobileAds

struct StoreRegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = StoreRegisterViewModel()
    @State private var showingSuccess = false

    var body: some View {
        NavigationView {
            Form {
                // 店舗基本情報
                Section(header: Text("店舗情報")) {
                    TextField("店舗名（例：セブンイレブン 渋谷店）", text: $viewModel.storeName)
                    Picker("カテゴリ", selection: $viewModel.selectedCategory) {
                        ForEach(StoreCategory.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: category.iconName)
                                .tag(category)
                        }
                    }
                    TextField("住所（任意）", text: $viewModel.address)
                }

                // 決済手段
                ForEach(PaymentCatalog.grouped, id: \.group) { section in
                    Section(header: Text(section.group.rawValue)) {
                        ForEach(section.entries) { entry in
                            Button(action: { viewModel.toggle(entry.id) }) {
                                HStack {
                                    Image(systemName: entry.iconName)
                                        .foregroundColor(Color.premiumNavy)
                                        .frame(width: 24)
                                    Text(entry.displayName)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: viewModel.selectedPayments.contains(entry.id)
                                          ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(viewModel.selectedPayments.contains(entry.id)
                                                         ? Color.premiumEmerald : .gray)
                                        .imageScale(.large)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button(action: submit) {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("店舗を登録する")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.storeName.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isSubmitting)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("店舗を登録")
            .alert("登録完了", isPresented: $showingSuccess) {
                Button("OK") { viewModel.reset() }
            } message: {
                Text("「\(viewModel.storeName)」を登録しました。情報の提供ありがとうございます！")
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private func submit() {
        let uid = authViewModel.userProfile?.uid
        Task {
            let success = await viewModel.submit(registeredByUid: uid)
            if success {
                // 登録完了後にインタースティシャル広告を表示
                await viewModel.showInterstitialAd()
                showingSuccess = true
            }
        }
    }
}

// MARK: - ViewModel
@MainActor
class StoreRegisterViewModel: ObservableObject {
    @Published var storeName = ""
    @Published var address = ""
    @Published var selectedCategory: StoreCategory = .convenienceStore
    @Published var selectedPayments: Set<String> = []
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    private let storeService = StoreService()
    private var interstitial: InterstitialAd?
    private let interstitialUnitID = "ca-app-pub-4490113823639458/8255863769"

    init() {
        loadInterstitial()
    }

    private func loadInterstitial() {
        Task {
            do {
                interstitial = try await InterstitialAd.load(
                    with: interstitialUnitID,
                    request: Request()
                )
            } catch {
                print("Interstitial ad failed to load: \(error)")
            }
        }
    }

    func showInterstitialAd() async {
        guard let ad = interstitial,
              let root = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows.first?.rootViewController
        else { return }
        ad.present(from: root)
        interstitial = nil
        loadInterstitial()
    }

    func toggle(_ id: String) {
        if selectedPayments.contains(id) { selectedPayments.remove(id) }
        else { selectedPayments.insert(id) }
    }

    func submit(registeredByUid: String?) async -> Bool {
        isSubmitting = true
        defer { isSubmitting = false }

        let newStore = Store(
            id: UUID().uuidString,
            name: storeName.trimmingCharacters(in: .whitespaces),
            location: Store.Coordinate(latitude: 35.6812, longitude: 139.7671), // 現在地取得は今後実装
            category: selectedCategory,
            supportedPaymentMethods: Array(selectedPayments),
            address: address.isEmpty ? nil : address,
            registeredByUid: registeredByUid
        )

        do {
            try await storeService.upsertStore(newStore)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func reset() {
        storeName = ""
        address = ""
        selectedCategory = .convenienceStore
        selectedPayments = []
    }
}
