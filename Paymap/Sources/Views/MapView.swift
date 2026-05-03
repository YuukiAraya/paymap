import SwiftUI
import CoreLocation

// MARK: - Main Map View
struct MapView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var lm: LanguageManager
    @StateObject private var viewModel = MapViewModel()
    @State private var region = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)

    var body: some View {
        ZStack(alignment: .bottom) {
            GoogleMapView(
                stores: $viewModel.stores,
                selectedStore: $viewModel.selectedStore,
                region: $region
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                if let selected = viewModel.selectedStore {
                    StoreDetailSheet(store: selected, viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                AdBannerContainer(isPremium: authViewModel.userProfile.map { _ in false } ?? false)
            }
            .zIndex(1)
        }
        .onAppear { viewModel.fetchStores(in: region) }
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
                }
                Spacer()
                Button(action: { withAnimation { viewModel.selectedStore = nil } }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray).imageScale(.large)
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
                        VStack(spacing: 8) {
                            Image(systemName: store.category.iconName)
                                .font(.system(size: 64))
                                .foregroundColor(store.category.color.opacity(0.5))
                            Text(lm.s.photoComingSoon)
                                .font(.caption).foregroundColor(.secondary)
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

                        if let url = store.googleMapsURL {
                            Link(destination: url) {
                                Label(lm.s.openGoogleMaps, systemImage: "arrow.up.right.square")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SecondaryButtonStyle())
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
            AdBannerContainer(isPremium: authViewModel.userProfile.map { _ in false } ?? false)
            } // VStack
        }
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

// MARK: - Report / Add Payment Methods
struct ReportPaymentMethodView: View {
    let store: Store
    @ObservedObject var viewModel: MapViewModel
    @EnvironmentObject var lm: LanguageManager
    @Environment(\.presentationMode) var presentationMode

    @State private var selectedIds: Set<String> = []
    @State private var showingAlert = false

    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text(lm.s.reportSectionHeader),
                    footer: Text(lm.s.reportSectionFooter)
                ) {
                    ForEach(PaymentCatalog.grouped, id: \.group) { section in
                        Section(header: Text(section.group.localizedName(lm.s)).font(.caption).bold()) {
                            ForEach(section.entries) { entry in
                                Button(action: { toggle(entry.id) }) {
                                    HStack {
                                        Image(systemName: entry.iconName)
                                            .foregroundColor(Color.premiumNavy)
                                            .frame(width: 24)
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
                        Text(lm.s.submitReport)
                            .frame(maxWidth: .infinity)
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
            .onAppear { selectedIds = Set(store.supportedPaymentMethods) }
            .alert(lm.s.reportThanks, isPresented: $showingAlert) {
                Button(lm.s.okButton) { presentationMode.wrappedValue.dismiss() }
            } message: {
                Text(lm.s.reportThanksBody)
            }
        }
    }

    private func toggle(_ id: String) {
        if selectedIds.contains(id) { selectedIds.remove(id) }
        else { selectedIds.insert(id) }
    }

    private func submitReport() {
        viewModel.submitConsensusReport(for: store, methods: Array(selectedIds))
        showingAlert = true
    }
}
