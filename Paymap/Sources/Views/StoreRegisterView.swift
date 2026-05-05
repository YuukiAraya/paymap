import SwiftUI
import CoreLocation
import GoogleMobileAds

extension Notification.Name {
    static let storeRegistered = Notification.Name("storeRegistered")
}

struct StoreRegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var viewModel = StoreRegisterViewModel()
    @State private var showingSuccess = false
    @State private var showingAddressPicker = false

    var initialCoordinate: CLLocationCoordinate2D? = nil

    var body: some View {
        NavigationView {
            Form {
                // MARK: 店舗情報
                Section(header: Text(lm.s.storeInfoSection)) {
                    TextField(lm.s.storeNamePlaceholder, text: $viewModel.storeName)
                    TextField(lm.s.storeNameEnPlaceholder, text: $viewModel.storeNameEn)
                    Picker(lm.s.categoryLabel, selection: $viewModel.selectedCategory) {
                        ForEach(StoreCategory.allCases, id: \.self) { category in
                            Label(category.localizedName(lm.s), systemImage: category.iconName).tag(category)
                        }
                    }
                }

                // MARK: 住所（必須）
                Section(header: Text(lm.s.addressRequired)) {
                    HStack {
                        TextField(lm.s.addressRequired, text: $viewModel.address)
                        if !viewModel.address.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.premiumEmerald)
                        }
                    }
                    if viewModel.addressError {
                        Text("住所を入力してください")
                            .font(.caption).foregroundColor(.red)
                    }

                    Button(action: { showingAddressPicker = true }) {
                        HStack {
                            Image(systemName: "map")
                                .foregroundColor(Color.premiumNavy)
                            Text(lm.s.confirmOnMapButton)
                                .foregroundColor(Color.premiumNavy)
                            Spacer()
                            if viewModel.isLocationConfirmed {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(Color.premiumEmerald)
                            }
                        }
                    }
                    .sheet(isPresented: $showingAddressPicker) {
                        AddressPickerView(
                            initialAddress: viewModel.address,
                            initialCoordinate: viewModel.confirmedCoordinate
                                ?? (viewModel.address.isEmpty ? locationManager.currentOrDefault : nil)
                        ) { coord, resolvedAddress in
                            viewModel.confirmedCoordinate = coord
                            viewModel.isLocationConfirmed = true
                            if resolvedAddress.isEmpty == false {
                                viewModel.address = resolvedAddress
                            }
                        }
                        .environmentObject(lm)
                    }
                }

                // MARK: 設備情報
                Section(header: Text(lm.s.facilitiesSection)) {
                    Toggle(isOn: Binding(
                        get: { viewModel.hasWifi == true },
                        set: { viewModel.hasWifi = $0 ? true : false }
                    )) {
                        Label(lm.s.hasWifiLabel, systemImage: "wifi")
                    }
                    .tint(Color.premiumEmerald)

                    Toggle(isOn: Binding(
                        get: { viewModel.hasPower == true },
                        set: { viewModel.hasPower = $0 ? true : false }
                    )) {
                        Label(lm.s.hasPowerLabel, systemImage: "powerplug.fill")
                    }
                    .tint(Color.premiumEmerald)
                }

                // MARK: 決済手段
                ForEach(PaymentCatalog.grouped, id: \.group) { section in
                    Section(header: Text(section.group.localizedName(lm.s))) {
                        ForEach(section.entries) { entry in
                            Button(action: { viewModel.toggle(entry.id) }) {
                                HStack {
                                    Image(systemName: entry.iconName)
                                        .foregroundColor(Color.premiumNavy).frame(width: 24)
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
                    .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
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
            .onAppear {
                if let coord = initialCoordinate {
                    viewModel.confirmedCoordinate = coord
                    viewModel.isLocationConfirmed = true
                }
            }
        }
    }

    private func submit() {
        guard viewModel.validateAddress() else { return }
        let uid = authViewModel.userProfile?.uid
        let fallbackCoord = locationManager.currentOrDefault
        Task {
            let success = await viewModel.submit(registeredByUid: uid, fallbackCoordinate: fallbackCoord)
            if success {
                await authViewModel.addContributionPoints(30)
                await authViewModel.checkExplorerBadge()
                await viewModel.showInterstitialAd()
                NotificationCenter.default.post(name: .storeRegistered, object: nil)
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
    @Published var hasWifi: Bool? = nil
    @Published var hasPower: Bool? = nil
    @Published var confirmedCoordinate: CLLocationCoordinate2D? = nil
    @Published var isLocationConfirmed: Bool = false
    @Published var addressError: Bool = false

    private let storeService = StoreService()
    private let geocodingService = GeocodingService()
    private var interstitial: InterstitialAd?
    private let interstitialUnitID = "ca-app-pub-4490113823639458/8255863769"

    var canSubmit: Bool {
        !storeName.trimmingCharacters(in: .whitespaces).isEmpty
            && !address.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init() { loadInterstitial() }

    func validateAddress() -> Bool {
        if address.trimmingCharacters(in: .whitespaces).isEmpty {
            addressError = true
            return false
        }
        addressError = false
        return true
    }

    private func loadInterstitial() {
        Task {
            do {
                interstitial = try await InterstitialAd.load(
                    with: interstitialUnitID, request: Request())
            } catch {}
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
        if selectedPayments.contains(id) {
            selectedPayments.remove(id)
        } else if id == "cash_only" {
            selectedPayments = ["cash_only"]
        } else {
            selectedPayments.remove("cash_only")
            selectedPayments.insert(id)
        }
    }

    func submit(registeredByUid: String?, fallbackCoordinate: CLLocationCoordinate2D) async -> Bool {
        isSubmitting = true
        defer { isSubmitting = false }

        var coordinate = confirmedCoordinate ?? fallbackCoordinate
        var addressEn: String? = nil

        if confirmedCoordinate == nil {
            if let result = await geocodingService.geocodeFull(address) {
                coordinate = result.coordinate
                addressEn = result.addressEn
                confirmedCoordinate = coordinate
                isLocationConfirmed = true
            } else {
                errorMessage = "住所から位置を取得できませんでした"
                return false
            }
        } else {
            addressEn = await geocodingService.translateAddressToEnglish(address)
        }

        let trimmedNameEn = storeNameEn.trimmingCharacters(in: .whitespaces)

        let newStore = Store(
            id: UUID().uuidString,
            name: storeName.trimmingCharacters(in: .whitespaces),
            nameEn: trimmedNameEn.isEmpty ? nil : trimmedNameEn,
            location: Store.Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude),
            category: selectedCategory,
            supportedPaymentMethods: Array(selectedPayments),
            address: address.isEmpty ? nil : address,
            addressEn: addressEn,
            photoURL: nil,
            registeredByUid: registeredByUid,
            hasWifi: hasWifi,
            hasPower: hasPower
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
        hasWifi = nil
        hasPower = nil
        confirmedCoordinate = nil
        isLocationConfirmed = false
        addressError = false
    }
}
