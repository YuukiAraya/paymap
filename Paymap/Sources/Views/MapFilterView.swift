import SwiftUI

struct MapFilterView: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Binding var filter: StoreFilter
    @Environment(\.dismiss) private var dismiss

    @State private var draftFilter = StoreFilter()

    var body: some View {
        NavigationView {
            Form {
                // MARK: カテゴリフィルター
                Section(header: Text(lm.s.filterByCategory)) {
                    Button(action: { draftFilter.category = nil }) {
                        HStack {
                            Text(lm.s.filterAllCategories)
                                .foregroundColor(.primary)
                            Spacer()
                            if draftFilter.category == nil {
                                Image(systemName: "checkmark").foregroundColor(Color.premiumEmerald)
                            }
                        }
                    }
                    ForEach(StoreCategory.allCases, id: \.self) { cat in
                        Button(action: { draftFilter.category = cat }) {
                            HStack {
                                Label(cat.localizedName(lm.s), systemImage: cat.iconName)
                                    .foregroundColor(cat.color)
                                Spacer()
                                if draftFilter.category == cat {
                                    Image(systemName: "checkmark").foregroundColor(Color.premiumEmerald)
                                }
                            }
                        }
                    }
                }

                // MARK: 設備フィルター
                Section(header: Text(lm.s.filterByFacility)) {
                    Toggle(isOn: $draftFilter.requireWifi) {
                        Label(lm.s.filterWifi, systemImage: "wifi")
                    }
                    .tint(Color.premiumEmerald)

                    Toggle(isOn: $draftFilter.requirePower) {
                        Label(lm.s.filterPower, systemImage: "powerplug.fill")
                    }
                    .tint(Color.premiumEmerald)
                }

                // MARK: 決済手段フィルター（プレミアム以外は1つのみ）
                Section(header: HStack {
                    Text(lm.s.filterByPayment)
                    if !purchaseManager.isPremium {
                        Spacer()
                        Text("Premium").font(.caption).foregroundColor(.purple)
                    }
                }) {
                    if !purchaseManager.isPremium && draftFilter.paymentIds.count == 0 {
                        Text(lm.s.advancedFilterPremium)
                            .font(.caption).foregroundColor(.secondary)
                    }

                    ForEach(PaymentCatalog.grouped, id: \.group) { section in
                        Section(header: Text(section.group.localizedName(lm.s)).font(.caption).bold()) {
                            ForEach(section.entries) { entry in
                                Button(action: {
                                    if draftFilter.paymentIds.contains(entry.id) {
                                        draftFilter.paymentIds.remove(entry.id)
                                    } else {
                                        if !purchaseManager.isPremium {
                                            draftFilter.paymentIds = [entry.id]
                                        } else {
                                            draftFilter.paymentIds.insert(entry.id)
                                        }
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: entry.iconName)
                                            .foregroundColor(Color.premiumNavy).frame(width: 24)
                                        Text(PaymentCatalog.displayName(for: entry.id, l10n: lm.s))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: draftFilter.paymentIds.contains(entry.id)
                                              ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(draftFilter.paymentIds.contains(entry.id)
                                                             ? Color.premiumEmerald : .gray)
                                    }
                                }
                            }
                        }
                    }
                }

                // MARK: クリアボタン
                if draftFilter.isActive {
                    Section {
                        Button(role: .destructive, action: { draftFilter.clear() }) {
                            Text(lm.s.clearFilters).frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle(lm.s.filterTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(lm.s.cancelButton) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(lm.s.applyFilters) {
                        filter = draftFilter
                        dismiss()
                    }
                    .bold()
                    .foregroundColor(Color.premiumEmerald)
                }
            }
            .onAppear { draftFilter = filter }
        }
    }
}
