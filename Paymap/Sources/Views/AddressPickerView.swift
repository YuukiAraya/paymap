import SwiftUI
import GoogleMaps
import CoreLocation

// MARK: - Address Picker (住所入力 → 地図で位置確認)
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

    private let geocodingService = GeocodingService()

    var body: some View {
        NavigationView {
            ZStack {
                AddressConfirmMapView(center: $mapCenter, onCenterChanged: { coord in
                    confirmedCoordinate = coord
                    reverseGeocodeCenter(coord)
                })
                .ignoresSafeArea(edges: .bottom)

                // Center pin (fixed)
                VStack {
                    Spacer()
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Color.premiumEmerald)
                        .shadow(radius: 4)
                        .offset(y: -22)
                    Spacer()
                }
                .allowsHitTesting(false)

                VStack {
                    Spacer()
                    // Bottom card
                    VStack(alignment: .leading, spacing: 12) {
                        Text(lm.s.dragToAdjust)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if isGeocoding {
                            HStack {
                                ProgressView()
                                Text(lm.s.geocodingInProgress)
                                    .font(.subheadline).foregroundColor(.secondary)
                            }
                        } else {
                            Label(displayAddress.isEmpty ? "—" : displayAddress,
                                  systemImage: "mappin.and.ellipse")
                                .font(.subheadline)
                                .foregroundColor(Color.premiumNavy)
                        }

                        if let err = geocodeError {
                            Text(err).font(.caption).foregroundColor(.red)
                        }

                        Button(action: confirmLocation) {
                            Text(lm.s.confirmLocationButton)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(confirmedCoordinate == nil)
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
            .onAppear { geocodeInitialAddress() }
        }
    }

    private func geocodeInitialAddress() {
        if let coord = initialCoordinate {
            mapCenter = coord
            confirmedCoordinate = coord
            if !initialAddress.isEmpty {
                // 確認済み座標＋住所あり → そのまま使う
                displayAddress = initialAddress
            } else {
                // 座標はあるが住所未入力（現在地から開いた場合など）→ 逆ジオコーディングで住所を取得
                reverseGeocodeCenter(coord)
            }
            return
        }
        guard !initialAddress.isEmpty else { return }
        // 住所文字列をジオコーディングしてマップ中心を移動
        isGeocoding = true
        geocodeError = nil
        Task {
            if let coord = await geocodingService.geocodeAddress(initialAddress) {
                await MainActor.run {
                    mapCenter = coord
                    confirmedCoordinate = coord
                    displayAddress = initialAddress
                    isGeocoding = false
                }
            } else {
                await MainActor.run {
                    geocodeError = lm.s.geocodeFailedError
                    isGeocoding = false
                }
            }
        }
    }

    private func reverseGeocodeCenter(_ coord: CLLocationCoordinate2D) {
        isGeocoding = true
        Task {
            let addr = await geocodingService.reverseGeocode(coord, language: lm.isEnglish ? "en" : "ja")
            await MainActor.run {
                displayAddress = addr ?? ""
                isGeocoding = false
            }
        }
    }

    private func confirmLocation() {
        guard let coord = confirmedCoordinate else { return }
        onConfirm(coord, displayAddress)
        dismiss()
    }
}

// MARK: - Map view with draggable center
struct AddressConfirmMapView: UIViewRepresentable {
    @Binding var center: CLLocationCoordinate2D
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
        let current = mapView.camera.target
        let dist = CLLocation(latitude: current.latitude, longitude: current.longitude)
            .distance(from: CLLocation(latitude: center.latitude, longitude: center.longitude))
        if dist > 200, !context.coordinator.isDragging {
            let cam = GMSCameraPosition.camera(
                withLatitude: center.latitude, longitude: center.longitude, zoom: 16.0)
            mapView.animate(to: cam)
        }
    }
}
