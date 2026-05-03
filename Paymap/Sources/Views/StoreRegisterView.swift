import SwiftUI
import CoreLocation
import GoogleMobileAds

struct StoreRegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var lm: LanguageManager
    @StateObject private var viewModel = StoreRegisterViewModel()
    @State private var showingSuccess = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(lm.s.storeInfoSection)) {
                    TextField(lm.s.storeNamePlaceholder, text: $viewModel.storeName)
                    TextField(lm.s.storeNameEnPlaceholder, text: $viewModel.storeNameEn)
                    Picker(lm.s.categoryLabel, selection: $viewModel.selectedCategory) {
                        ForEach(StoreCategory.allCases, id: \.self) { category in
                            Label(category.localizedName(lm.s), systemImage: category.iconName)
                                .tag(category)
                        }
                    }
                    TextField(lm.s.addressPlaceholder, text: $viewModel.address)
                }

                ForEach(PaymentCatalog.grouped, id: \.group) { section in
                    Section(header: Text(section.group.localizedName(lm.s))) {
                        ForEach(section.entries) { entry in
                            Button(action: { viewModel.toggle(entry.id) }) {
                                HStack {
                                    Image(systemName: entry.iconName)
                                        .foregroundColor(Color.premiumNavy)
                                        .frame(width: 24)
                                    Text(PaymentCatalog.displayName(for: entry.id, l10n: lm.s))
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
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text(lm.s.registerButton).frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.storeName.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isSubmitting)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle(lm.s.registerStoreTitle)
            .alert(lm.s.registrationCompleteTitle, isPresented: $showingSuccess) {
                Button(lm.s.okButton) { viewModel.reset() }
            } message: {
                Text(lm.s.registrationCompleteBody(viewModel.storeName))
            }
            .alert(lm.s.errorTitle, isPresented: .constant(viewModel.errorMessage != nil)) {
                Button(lm.s.okButton) { viewModel.errorMessage = nil }
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
    @Published var storeNameEn = ""
    @Published var address = ""
    @Published var selectedCategory: StoreCategory = .convenienceStore
    @Published var selectedPayments: Set<String> = []
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    private let storeService = StoreService()
    private let geocodingService = GeocodingService()
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

        // 住所が入力されていれば英語に自動翻訳
        let addressEnValue = address.isEmpty ? nil : await geocodingService.translateAddressToEnglish(address)

        let trimmedNameEn = storeNameEn.trimmingCharacters(in: .whitespaces)
        let newStore = Store(
            id: UUID().uuidString,
            name: storeName.trimmingCharacters(in: .whitespaces),
            nameEn: trimmedNameEn.isEmpty ? nil : trimmedNameEn,
            location: Store.Coordinate(latitude: 35.6812, longitude: 139.7671),
            category: selectedCategory,
            supportedPaymentMethods: Array(selectedPayments),
            address: address.isEmpty ? nil : address,
            addressEn: addressEnValue,
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
        storeNameEn = ""
        address = ""
        selectedCategory = .convenienceStore
        selectedPayments = []
    }
}
