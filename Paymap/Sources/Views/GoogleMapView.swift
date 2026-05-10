import SwiftUI
import GoogleMaps

struct GoogleMapView: UIViewRepresentable {
    @Binding var stores: [Store]
    @Binding var selectedStore: Store?
    @Binding var region: CLLocationCoordinate2D
    @Binding var longPressCoordinate: CLLocationCoordinate2D?
    @EnvironmentObject var lm: LanguageManager

    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapView

        init(_ parent: GoogleMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            if let storeId = marker.userData as? String,
               let store = parent.stores.first(where: { $0.id == storeId }) {
                withAnimation(.spring()) {
                    parent.selectedStore = store
                    parent.region = store.clLocationCoordinate
                }
            }
            return true
        }

        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            withAnimation(.spring()) { parent.selectedStore = nil }
        }

        func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
            withAnimation(.spring()) {
                parent.selectedStore = nil
                parent.longPressCoordinate = coordinate
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(
            withLatitude: region.latitude, longitude: region.longitude, zoom: 15.0)
        let options = GMSMapViewOptions()
        options.camera = camera
        options.frame = .zero
        let mapView = GMSMapView(options: options)
        mapView.delegate = context.coordinator
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: 66, right: 0)
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        let currentPos = mapView.camera.target
        let distance = CLLocation(latitude: currentPos.latitude, longitude: currentPos.longitude)
            .distance(from: CLLocation(latitude: region.latitude, longitude: region.longitude))

        if distance > 100 {
            let camera = GMSCameraPosition.camera(
                withLatitude: region.latitude, longitude: region.longitude, zoom: 15.0)
            mapView.animate(to: camera)
        }

        mapView.clear()

        for store in stores {
            let marker = GMSMarker()
            marker.position = store.clLocationCoordinate
            marker.userData = store.id
            let isSelected = selectedStore?.id == store.id
            let renderer = ImageRenderer(content: StorePinView(
                store: store, isSelected: isSelected,
                displayName: store.displayName(isEnglish: lm.isEnglish)
            ))
            renderer.scale = 3.0
            marker.icon = renderer.uiImage
            marker.groundAnchor = CGPoint(x: 0.5, y: 1.0)
            marker.map = mapView
        }

        if let lp = longPressCoordinate {
            let marker = GMSMarker()
            marker.position = lp
            marker.icon = GMSMarker.markerImage(with: UIColor(Color.premiumEmerald))
            marker.title = "登録場所"
            marker.map = mapView
        }
    }
}
