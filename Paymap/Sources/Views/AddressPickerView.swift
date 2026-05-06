import SwiftUI
import GoogleMaps
import CoreLocation

// MARK: - Address Picker（住所テキスト入力 ↔ 地図ドラッグ 両方向同期）
struct AddressPickerView: View {
    @EnvironmentObject var lm: LanguageManager
    @Environment(\.dismiss) private var dismiss

    let initialAddress: String
    var initialCoordinate: CLLocationCoordinate2D? = nil
    var onConfirm: (CLLocationCoordinate2D, String) -> Void

    @State private var confirmedCoordinate: CLLocationCoordinate2D?
    @State private var displayAddress: String = ""
    @State private var isGeocoding = false
    @State private var geocodeError: String?
    @State private var mapCenter: CLLocationCoordinate2D = LocationManager.defaultCoordinate
    // テキスト入力でジオコーディング中はマップ操作を一時無効化
    @State private var mapInteractionDisabled = false

    private let geocodingService = GeocodingService()

    var body: some View {
        NavigationView {
            ZStack {
                AddressConfirmMapView(
                    center: $mapCenter,
                    interactionDisabled: mapInteractionDisabled,
                    onCenterChanged: { coord in
                        // マップ操作無効中（テキストジオコーディング中）は無視
                        guard !mapInteractionDisabled else { return }
                        confirmedCoordinate = coord
                        reverseGeocodeCenter(coord)
                    })
                .ignoresSafeArea(edges: .bottom)

                // 中心ピン（固定表示）
                VStack {
                    Spacer()
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(mapInteractionDisabled ? .gray : Color.premiumEmerald)
                        .shadow(radius: 4)
                        .offset(y: -22)
                    Spacer()
                }
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.2), value: mapInteractionDisabled)

                VStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 12) {
                        // 操作ヒント
                        HStack(spacing: 6) {
                            Image(systemName: mapInteractionDisabled
                                  ? "keyboard.fill" : "hand.draw.fill")
                                .font(.caption).foregroundColor(.secondary)
                            Text(mapInteractionDisabled
                                 ? lm.s.geocodingInProgress
                                 : lm.s.dragToAdjust)
                                .font(.caption).foregroundColor(.secondary)
                        }

                        // 編集可能な住所フィールド
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField(lm.s.addressRequired, text: $displayAddress)
                                .font(.subheadline)
                                .foregroundColor(Color.premiumNavy)
                                .submitLabel(.search)
                                .onSubmit { geocodeFromText() }
                            if isGeocoding {
                                ProgressView().scaleEffect(0.8)
                            } else if confirmedCoordinate != nil && !displayAddress.isEmpty {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.premiumEmerald)
                            }
                        }
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                        if let err = geocodeError {
                            Text(err).font(.caption).foregroundColor(.red)
                        }

                        HStack(spacing: 8) {
                            // 住所で検索ボタン
                            Button(action: geocodeFromText) {
                                Label(lm.isEnglish ? "Search" : "住所で検索",
                                      systemImage: "magnifyingglass")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .disabled(displayAddress.isEmpty || isGeocoding)

                            // この位置で確定ボタン
                            Button(action: confirmLocation) {
                                Text(lm.s.confirmLocationButton)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(confirmedCoordinate == nil)
                        }
                    }
                    .padding(16)
                    .glassCard()
                    .padding()
                }
            }
            .navigationTitle(lm.s.addressPickerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(lm.s.cancelButton) { dismiss() }
                }
            }
            .onAppear { setupInitialState() }
        }
    }

    // MARK: - Setup

    private func setupInitialState() {
        if let coord = initialCoordinate {
            mapCenter = coord
            confirmedCoordinate = coord
            if !initialAddress.isEmpty {
                displayAddress = initialAddress
            } else {
                // 座標のみ（住所未取得）→ 逆ジオコーディングで取得
                reverseGeocodeCenter(coord)
            }
        } else if !initialAddress.isEmpty {
            // 住所のみ → テキストをジオコーディングしてマップを移動
            displayAddress = initialAddress
            geocodeFromText()
        }
    }

    // MARK: - テキスト → 地図（住所検索）

    private func geocodeFromText() {
        let trimmed = displayAddress.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isGeocoding = true
        geocodeError = nil
        mapInteractionDisabled = true  // マップ操作を一時無効化

        Task {
            if let coord = await geocodingService.geocodeAddress(trimmed) {
                await MainActor.run {
                    mapCenter = coord
                    confirmedCoordinate = coord
                    isGeocoding = false
                    mapInteractionDisabled = false
                }
            } else {
                await MainActor.run {
                    geocodeError = lm.s.geocodeFailedError
                    isGeocoding = false
                    mapInteractionDisabled = false
                }
            }
        }
    }

    // MARK: - 地図 → テキスト（逆ジオコーディング）

    private func reverseGeocodeCenter(_ coord: CLLocationCoordinate2D) {
        isGeocoding = true
        Task {
            let addr = await geocodingService.reverseGeocode(
                coord, language: lm.isEnglish ? "en" : "ja")
            await MainActor.run {
                displayAddress = addr ?? ""
                isGeocoding = false
            }
        }
    }

    // MARK: - 確定

    private func confirmLocation() {
        guard let coord = confirmedCoordinate else { return }
        onConfirm(coord, displayAddress)
        dismiss()
    }
}

// MARK: - Map view（interactionDisabled サポート付き）
struct AddressConfirmMapView: UIViewRepresentable {
    @Binding var center: CLLocationCoordinate2D
    var interactionDisabled: Bool = false
    var onCenterChanged: (CLLocationCoordinate2D) -> Void

    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: AddressConfirmMapView
        var isDragging = false

        init(_ parent: AddressConfirmMapView) { self.parent = parent }

        func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
            isDragging = gesture
        }

        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            let coord = position.target
            parent.center = coord
            parent.onCenterChanged(coord)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(
            withLatitude: center.latitude, longitude: center.longitude, zoom: 16.0)
        let options = GMSMapViewOptions()
        options.camera = camera
        options.frame = .zero
        let mapView = GMSMapView(options: options)
        mapView.delegate = context.coordinator
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // マップ操作の有効/無効切り替え
        mapView.settings.scrollGestures    = !interactionDisabled
        mapView.settings.zoomGestures      = !interactionDisabled
        mapView.settings.rotateGestures    = !interactionDisabled
        mapView.settings.tiltGestures      = !interactionDisabled

        // 中心が大きく離れた場合のみカメラを移動
        let current = mapView.camera.target
        let dist = CLLocation(latitude: current.latitude, longitude: current.longitude)
            .distance(from: CLLocation(latitude: center.latitude, longitude: center.longitude))
        if dist > 100, !context.coordinator.isDragging {
            let cam = GMSCameraPosition.camera(
                withLatitude: center.latitude, longitude: center.longitude, zoom: 16.0)
            mapView.animate(to: cam)
        }
    }
}
