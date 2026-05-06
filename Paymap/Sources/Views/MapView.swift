import SwiftUI
import CoreLocation

// MARK: - Main Map View
struct MapView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    @StateObject private var viewModel = MapViewModel()
    @State private var region = LocationManager.defaultCoordinate
    @State private var longPressCoordinate: CLLocationCoordinate2D? = nil
    @State private var showingFilter = false
    @State private var showingRegisterFromLongPress = false

    var body: some View {
        ZStack(alignment: .bottom) {
            GoogleMapView(
                stores: Binding(
                    get: { viewModel.filteredStores },
                    set: { _ in }
                ),
                selectedStore: $viewModel.selectedStore,
                region: $region,
                longPressCoordinate: $longPressCoordinate
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // オフライン表示バナー
                if viewModel.isOffline {
                    HStack {
                        Image(systemName: "wifi.slash")
                        Text(lm.s.showingCachedData)
                            .font(.caption)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.85))
                    .foregroundColor(.white)
                }

                // フィルター適用中バナー
                if viewModel.activeFilter.isActive {
                    Button(action: { showingFilter = true }) {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            Text(lm.s.filterActive)
                                .font(.caption).bold()
                            Spacer()
                            Text(lm.s.clearFilters)
                                .font(.caption)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.premiumEmerald.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        viewModel.activeFilter.clear()
                    })
                }

                Spacer()

                // 長押し登録ポップアップ
                if let coord = longPressCoordinate {
                    LongPressRegisterCard(
                        coordinate: coord,
                        onRegister: { showingRegisterFromLongPress = true },
                        onCancel: { longPressCoordinate = nil }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // 店舗詳細シート
                if let selected = viewModel.selectedStore, longPressCoordinate == nil {
                    StoreDetailSheet(store: selected, viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                AdBannerContainer()
            }
            .zIndex(1)

            // フィルターボタン（右上）
            VStack {
                HStack {
                    Spacer()
                    Button(action: { showingFilter = true }) {
                        ZStack {
                            Circle()
                                .fill(viewModel.activeFilter.isActive ? Color.premiumEmerald : Color.white)
                                .frame(width: 44, height: 44)
                                .shadow(radius: 4)
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(viewModel.activeFilter.isActive ? .white : Color.premiumNavy)
                        }
                    }
                    .padding(.top, 60)
                    .padding(.trailing, 16)
                }
                Spacer()
            }
            .zIndex(2)
        }
        .onAppear {
            let coord = locationManager.currentOrDefault
            region = coord
            viewModel.fetchStores(in: coord)
            if let uid = authViewModel.userProfile?.uid {
                viewModel.loadFavorites(uid: uid)
            }
        }
        .onChange(of: locationManager.location) { loc in
            guard let loc else { return }
            region = loc
            viewModel.fetchStores(in: loc)
        }
        .onReceive(NotificationCenter.default.publisher(for: .storeRegistered)) { _ in
            longPressCoordinate = nil
            viewModel.fetchStores(in: locationManager.currentOrDefault)
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToStore)) { notification in
            guard let store = notification.userInfo?["store"] as? Store else { return }
            let coord = CLLocationCoordinate2D(
                latitude: store.location.latitude,
                longitude: store.location.longitude)
            withAnimation {
                region = coord
                viewModel.selectedStore = store
            }
            viewModel.fetchStores(in: coord)
        }
        .sheet(isPresented: $showingFilter) {
            MapFilterView(filter: $viewModel.activeFilter)
                .environmentObject(lm)
                .environmentObject(purchaseManager)
        }
        .sheet(isPresented: $showingRegisterFromLongPress) {
            StoreRegisterView(initialCoordinate: longPressCoordinate)
                .environmentObject(authViewModel)
                .environmentObject(lm)
                .environmentObject(locationManager)
        }
        .onChange(of: showingRegisterFromLongPress) { showing in
            if !showing { longPressCoordinate = nil }
        }
    }
}

// MARK: - Long Press Register Card
private struct LongPressRegisterCard: View {
    let coordinate: CLLocationCoordinate2D
    let onRegister: () -> Void
    let onCancel: () -> Void
    @EnvironmentObject var lm: LanguageManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(Color.premiumEmerald)
                    .font(.title2)
                Text(lm.s.registerHereTitle)
                    .font(.headline).foregroundColor(Color.premiumNavy)
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray).imageScale(.large)
                }
            }
            Text(String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude))
                .font(.caption).foregroundColor(.secondary)

            HStack(spacing: 8) {
                Button(action: onCancel) {
                    Text(lm.s.cancelPinButton).frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())

                Button(action: onRegister) {
                    Label(lm.s.registerHereButton, systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .glassCard()
        .padding(.horizontal).padding(.bottom, 8)
    }
}

// MARK: - Map Pin
struct StorePinView: View {
    let store: Store
    let isSelected: Bool
    var displayName: String? = nil

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(store.category.color)
                    .frame(width: isSelected ? 44 : 32, height: isSelected ? 44 : 32)
                    .shadow(radius: isSelected ? 6 : 2)
                Image(systemName: store.category.iconName)
                    .foregroundColor(.white)
                    .font(isSelected ? .title3 : .body)
                if store.isFavorited {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 12, height: 12)
                        .offset(x: isSelected ? 16 : 12, y: isSelected ? -16 : -12)
                }
            }
            if isSelected {
                Text(displayName ?? store.name)
                    .font(.caption).bold()
                    .padding(.horizontal, 6).padding(.vertical, 4)
                    .background(Color.premiumNavy)
                    .foregroundColor(.white)
                    .cornerRadius(8).shadow(radius: 4)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// MARK: - Bottom Sheet (compact)
struct StoreDetailSheet: View {
    let store: Store
    @ObservedObject var viewModel: MapViewModel
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingDetail = false
    @State private var showingReport = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(store.category.color.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: store.category.iconName)
                        .foregroundColor(store.category.color)
                        .font(.title2)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.displayName(isEnglish: lm.isEnglish))
                        .font(.title3).bold()
                        .foregroundColor(Color.premiumNavy)
                    Text(store.category.localizedName(lm.s))
                        .font(.subheadline).foregroundColor(.secondary)
                    if let address = store.displayAddress(isEnglish: lm.isEnglish) {
                        Label(address, systemImage: "mappin.and.ellipse")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    FacilityBadgesRow(store: store)
                }
                Spacer()
                VStack(spacing: 8) {
                    Button(action: {
                        if let uid = authViewModel.userProfile?.uid {
                            withAnimation { viewModel.toggleFavorite(store: store, uid: uid) }
                        }
                    }) {
                        Image(systemName: store.isFavorited ? "heart.fill" : "heart")
                            .foregroundColor(store.isFavorited ? .red : .gray)
                            .imageScale(.large)
                    }
                    Button(action: { withAnimation { viewModel.selectedStore = nil } }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray).imageScale(.large)
                    }
                }
            }

            Divider()

            if store.supportedPaymentMethods.isEmpty {
                Text(lm.s.noPaymentInfo)
                    .font(.subheadline).foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(store.supportedPaymentMethods, id: \.self) { id in
                            HStack(spacing: 4) {
                                Image(systemName: PaymentCatalog.iconName(for: id))
                                    .foregroundColor(Color.premiumEmerald)
                                Text(PaymentCatalog.displayName(for: id, l10n: lm.s))
                                    .font(.caption).bold()
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color.premiumEmerald.opacity(0.12))
                            .cornerRadius(10)
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                Button(action: { showingDetail = true }) {
                    Label(lm.s.viewDetails, systemImage: "info.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())

                Button(action: { showingReport = true }) {
                    Label(lm.s.addInfo, systemImage: "plus.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .glassCard()
        .padding(.horizontal).padding(.bottom, 16)
        .sheet(isPresented: $showingDetail) {
            StoreDetailFullView(store: store, viewModel: viewModel)
        }
        .sheet(isPresented: $showingReport) {
            ReportPaymentMethodView(store: store, viewModel: viewModel)
        }
    }
}

// MARK: - Facility Badges Row
struct FacilityBadgesRow: View {
    let store: Store
    var body: some View {
        HStack(spacing: 4) {
            if let wifi = store.hasWifi {
                HStack(spacing: 3) {
                    Image(systemName: wifi ? "wifi" : "wifi.slash")
                    Text("WiFi")
                }
                .font(.caption2)
                .foregroundColor(wifi ? .blue : .secondary)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background((wifi ? Color.blue : Color.gray).opacity(0.1)).cornerRadius(6)
            }
            if let power = store.hasPower {
                HStack(spacing: 3) {
                    Image(systemName: power ? "powerplug.fill" : "powerplug")
                    Text("電源")
                }
                .font(.caption2)
                .foregroundColor(power ? .orange : .secondary)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background((power ? Color.orange : Color.gray).opacity(0.1)).cornerRadius(6)
            }
        }
    }
}

// MARK: - Full Detail Page
struct StoreDetailFullView: View {
    let store: Store
    @ObservedObject var viewModel: MapViewModel
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingReport = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ZStack {
                            Rectangle()
                                .fill(store.category.color.opacity(0.15))
                                .frame(height: 220)
                            if let urlStr = store.photoURL, let url = URL(string: urlStr) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let img):
                                        img.resizable().scaledToFill()
                                            .frame(height: 220).clipped()
                                    case .failure: photoPlaceholder
                                    default: ProgressView().frame(height: 220)
                                    }
                                }
                            } else {
                                photoPlaceholder
                            }
                        }

                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(store.displayName(isEnglish: lm.isEnglish))
                                    .font(.title2).bold()
                                Label(store.category.localizedName(lm.s), systemImage: store.category.iconName)
                                    .foregroundColor(store.category.color)
                                if let address = store.displayAddress(isEnglish: lm.isEnglish) {
                                    Label(address, systemImage: "mappin.and.ellipse")
                                        .font(.subheadline).foregroundColor(.secondary)
                                }
                            }

                            // 設備情報
                            if store.hasWifi != nil || store.hasPower != nil {
                                Divider()
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(lm.s.facilitiesSection)
                                        .font(.headline).foregroundColor(Color.premiumNavy)
                                    HStack(spacing: 12) {
                                        if let wifi = store.hasWifi {
                                            FacilityChip(
                                                icon: "wifi",
                                                label: wifi ? lm.s.wifiAvailable : lm.s.wifiUnavailable,
                                                available: wifi
                                            )
                                        }
                                        if let power = store.hasPower {
                                            FacilityChip(
                                                icon: "powerplug.fill",
                                                label: power ? lm.s.powerAvailable : lm.s.powerUnavailable,
                                                available: power
                                            )
                                        }
                                    }
                                }
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 10) {
                                Text(lm.s.paymentAvailable)
                                    .font(.headline).foregroundColor(Color.premiumNavy)
                                if store.supportedPaymentMethods.isEmpty {
                                    Text(lm.s.noPaymentInfo)
                                        .font(.subheadline).foregroundColor(.secondary)
                                } else {
                                    let grouped = Dictionary(grouping: store.supportedPaymentMethods) { id in
                                        PaymentCatalog.all.first { $0.id == id }?.group ?? .other
                                    }
                                    ForEach(PaymentCatalog.Entry.Group.allCases, id: \.self) { group in
                                        if let ids = grouped[group], !ids.isEmpty {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(group.localizedName(lm.s))
                                                    .font(.caption).bold().foregroundColor(.secondary)
                                                FlowLayout(ids: ids, l10n: lm.s)
                                            }
                                        }
                                    }
                                }
                            }

                            Divider()

                            HStack(spacing: 8) {
                                Button(action: {
                                    if let uid = authViewModel.userProfile?.uid {
                                        viewModel.toggleFavorite(store: store, uid: uid)
                                    }
                                }) {
                                    Label(
                                        store.isFavorited ? lm.s.removeFavorite : lm.s.addFavorite,
                                        systemImage: store.isFavorited ? "heart.fill" : "heart"
                                    ).frame(maxWidth: .infinity)
                                }
                                .buttonStyle(SecondaryButtonStyle())
                                .foregroundColor(store.isFavorited ? .red : .primary)

                                if let url = store.googleMapsURL {
                                    Link(destination: url) {
                                        Label(lm.s.openGoogleMaps, systemImage: "arrow.up.right.square")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(SecondaryButtonStyle())
                                }
                            }

                            Button(action: { showingReport = true }) {
                                Label(lm.s.addEditPayment, systemImage: "exclamationmark.bubble")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                        .padding()
                    }
                }
                AdBannerContainer()
            }
            .navigationTitle(lm.s.storeDetail)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(lm.s.closeButton) { dismiss() }
                }
            }
            .sheet(isPresented: $showingReport) {
                ReportPaymentMethodView(store: store, viewModel: viewModel)
            }
        }
    }

    private var photoPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: store.category.iconName)
                .font(.system(size: 64))
                .foregroundColor(store.category.color.opacity(0.5))
            Text(lm.s.photoComingSoon)
                .font(.caption).foregroundColor(.secondary)
        }
    }
}

// MARK: - Facility Chip
struct FacilityChip: View {
    let icon: String
    let label: String
    let available: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(label).font(.caption).bold()
        }
        .foregroundColor(available ? .green : .secondary)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background((available ? Color.green : Color.gray).opacity(0.12))
        .cornerRadius(10)
    }
}

private struct FlowLayout: View {
    let ids: [String]
    let l10n: L10n
    var body: some View {
        HStack(spacing: 6) {
            ForEach(ids, id: \.self) { id in
                HStack(spacing: 4) {
                    Image(systemName: PaymentCatalog.iconName(for: id))
                    Text(PaymentCatalog.displayName(for: id, l10n: l10n))
                        .font(.caption).bold()
                }
                .foregroundColor(Color.premiumEmerald)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.premiumEmerald.opacity(0.12))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - Facility three-state (あり / なし / 不明)
// StoreRegisterView でも共有するため internal スコープ
enum FacilityState: String, CaseIterable, Identifiable {
    case available   = "あり"
    case unavailable = "なし"
    case unknown     = "不明"

    var id: String { rawValue }
    var boolValue: Bool? {
        switch self {
        case .available:   return true
        case .unavailable: return false
        case .unknown:     return nil
        }
    }
    init(_ value: Bool?) {
        switch value {
        case true:  self = .available
        case false: self = .unavailable
        default:    self = .unknown
        }
    }
}

// MARK: - Report / Add Payment Methods
struct ReportPaymentMethodView: View {
    let store: Store
    @ObservedObject var viewModel: MapViewModel
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var selectedIds: Set<String> = []
    @State private var wifiState: FacilityState = .unknown
    @State private var powerState: FacilityState = .unknown
    @State private var showingAlert = false

    var body: some View {
        NavigationView {
            Form {
                // MARK: 設備情報
                Section(header: Text(lm.s.facilitiesSection)) {
                    HStack {
                        Label(lm.s.hasWifiLabel, systemImage: "wifi")
                            .foregroundColor(Color.premiumNavy)
                        Spacer()
                        Picker("", selection: $wifiState) {
                            ForEach(FacilityState.allCases) { state in
                                Text(state.rawValue).tag(state)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                    }
                    HStack {
                        Label(lm.s.hasPowerLabel, systemImage: "powerplug.fill")
                            .foregroundColor(Color.premiumNavy)
                        Spacer()
                        Picker("", selection: $powerState) {
                            ForEach(FacilityState.allCases) { state in
                                Text(state.rawValue).tag(state)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                    }
                }

                Section(
                    header: Text(lm.s.reportSectionHeader),
                    footer: Text(lm.s.reportSectionFooter)
                ) {
                    ForEach(PaymentCatalog.grouped, id: \.group) { section in
                        Section(header: Text(section.group.localizedName(lm.s)).font(.caption).bold()) {
                            ForEach(section.entries) { entry in
                                Button(action: { togglePayment(entry.id) }) {
                                    HStack {
                                        Image(systemName: entry.iconName)
                                            .foregroundColor(Color.premiumNavy).frame(width: 24)
                                        Text(PaymentCatalog.displayName(for: entry.id, l10n: lm.s))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: selectedIds.contains(entry.id)
                                              ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedIds.contains(entry.id)
                                                             ? Color.premiumEmerald : .gray)
                                            .imageScale(.large)
                                    }
                                }
                            }
                        }
                    }
                }
                Section {
                    Button(action: submitReport) {
                        Text(lm.s.submitReport).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle(lm.s.reportTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(lm.s.cancelButton) { presentationMode.wrappedValue.dismiss() }
                }
            }
            .onAppear {
                selectedIds = Set(store.supportedPaymentMethods)
                wifiState  = FacilityState(store.hasWifi)
                powerState = FacilityState(store.hasPower)
            }
            .alert(lm.s.reportThanks, isPresented: $showingAlert) {
                Button(lm.s.okButton) { presentationMode.wrappedValue.dismiss() }
            } message: { Text(lm.s.reportThanksBody) }
        }
    }

    private func togglePayment(_ id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else if id == "cash_only" {
            selectedIds = ["cash_only"]
        } else {
            selectedIds.remove("cash_only")
            selectedIds.insert(id)
        }
    }

    private func submitReport() {
        viewModel.submitConsensusReport(for: store, methods: Array(selectedIds),
                                        uid: authViewModel.userProfile?.uid)
        viewModel.updateStoreFacilities(storeId: store.id,
                                        hasWifi: wifiState.boolValue,
                                        hasPower: powerState.boolValue)
        Task { await authViewModel.addContributionPoints(10) }
        showingAlert = true
    }
}
