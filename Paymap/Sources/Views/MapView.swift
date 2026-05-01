import SwiftUI
import CoreLocation

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    
    @State private var region = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Google Maps View Wrapper
            GoogleMapView(
                stores: $viewModel.stores,
                selectedStore: $viewModel.selectedStore,
                region: $region
            )
            .ignoresSafeArea()
            
            if let selected = viewModel.selectedStore {
                StoreDetailSheet(store: selected, viewModel: viewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .onAppear {
            viewModel.fetchStores(in: region)
        }
    }
}

struct StorePinView: View {
    let store: Store
    let isSelected: Bool
    
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
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            
            if isSelected {
                Text(store.name)
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.premiumNavy)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

struct StoreDetailSheet: View {
    let store: Store
    @ObservedObject var viewModel: MapViewModel
    @State private var showingReportSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(store.category.color.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: store.category.iconName)
                        .foregroundColor(store.category.color)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.name)
                        .font(.title2)
                        .bold()
                        .foregroundColor(Color.premiumNavy)
                    
                    Text(store.category.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {
                    withAnimation {
                        viewModel.selectedStore = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .imageScale(.large)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("現在有効な決済手段")
                    .font(.headline)
                    .foregroundColor(Color.premiumNavy)
                
                if store.supportedPaymentMethods.isEmpty {
                    Text("まだ情報がありません。最初の報告者になりましょう！")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(store.supportedPaymentMethods, id: \.self) { methodId in
                                HStack {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(Color.premiumEmerald)
                                    Text(methodId)
                                        .bold()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.premiumEmerald.opacity(0.15))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
            }
            
            Button(action: {
                showingReportSheet = true
            }) {
                HStack {
                    Image(systemName: "exclamationmark.bubble")
                    Text("情報が間違っている・追加する")
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .glassCard()
        .padding(.horizontal)
        .padding(.bottom, 20)
        .sheet(isPresented: $showingReportSheet) {
            ReportPaymentMethodView(store: store, viewModel: viewModel)
        }
    }
}

// MARK: - New Consensus Reporting UI
struct ReportPaymentMethodView: View {
    let store: Store
    @ObservedObject var viewModel: MapViewModel
    @Environment(\.presentationMode) var presentationMode
    
    let allPossibleMethods = ["PayPay", "Suica", "Credit Card", "LINE Pay", "QUICPay", "iD", "現金のみ", "Coke ON Pay"]
    
    @State private var reportedMethods: Set<String> = []
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("この店舗で使える決済手段を選択してください"), footer: Text("※全体の80%以上のユーザーが「使える」と報告した手段のみがマップ上で有効化されます。")) {
                    ForEach(allPossibleMethods, id: \.self) { method in
                        Button(action: {
                            if reportedMethods.contains(method) {
                                reportedMethods.remove(method)
                            } else {
                                reportedMethods.insert(method)
                            }
                        }) {
                            HStack {
                                Text(method)
                                    .foregroundColor(.primary)
                                Spacer()
                                if reportedMethods.contains(method) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color.premiumEmerald)
                                        .imageScale(.large)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                        .imageScale(.large)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        submitReport()
                    }) {
                        Text("報告を送信する")
                            .frame(maxWidth: .infinity)
                            .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("情報の申請")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                reportedMethods = Set(store.supportedPaymentMethods)
            }
            .alert("報告ありがとうございます", isPresented: $showingAlert) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("承認ステータスが更新されました。")
            }
        }
    }
    
    private func submitReport() {
        viewModel.submitConsensusReport(for: store, methods: Array(reportedMethods))
        showingAlert = true
    }
}
