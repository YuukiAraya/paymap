import SwiftUI
import GoogleMaps

struct GoogleMapView: UIViewRepresentable {
    @Binding var stores: [Store]
    @Binding var selectedStore: Store?
    @Binding var region: CLLocationCoordinate2D
    
    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapView
        
        init(_ parent: GoogleMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            if let storeId = marker.userData as? String,
               let store = parent.stores.first(where: { $0.id == storeId }) {
                // Animate selection
                withAnimation(.spring()) {
                    parent.selectedStore = store
                }
            }
            return true
        }
        
        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            withAnimation(.spring()) {
                parent.selectedStore = nil
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: region.latitude, longitude: region.longitude, zoom: 15.0)
        let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        mapView.delegate = context.coordinator
        
        // Optional: Custom map styling could be applied here
        // mapView.mapStyle = try? GMSMapStyle(jsonString: mapStyleJSON)
        
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // Only update camera if it's significantly different to avoid stuttering
        let currentPos = mapView.camera.target
        let distance = CLLocation(latitude: currentPos.latitude, longitude: currentPos.longitude)
            .distance(from: CLLocation(latitude: region.latitude, longitude: region.longitude))
        
        if distance > 100 {
            let camera = GMSCameraPosition.camera(withLatitude: region.latitude, longitude: region.longitude, zoom: 15.0)
            mapView.animate(to: camera)
        }
        
        // Efficient marker update: clear and recreate (In a real app, diffing is better)
        mapView.clear()
        
        for store in stores {
            let marker = GMSMarker()
            marker.position = store.clLocationCoordinate
            marker.userData = store.id // Store ID for retrieval on tap
            
            // Apply custom styling based on StoreCategory
            let isSelected = selectedStore?.id == store.id
            marker.iconView = createCustomMarkerView(for: store, isSelected: isSelected)
            
            marker.map = mapView
        }
    }
    
    private func createCustomMarkerView(for store: Store, isSelected: Bool) -> UIView {
        // Native SwiftUI hosting inside a UIView for custom Google Maps markers
        let controller = UIHostingController(rootView: StorePinView(store: store, isSelected: isSelected))
        controller.view.backgroundColor = .clear
        
        // Adjust size based on selection state
        let size: CGFloat = isSelected ? 60 : 40
        controller.view.frame = CGRect(x: 0, y: 0, width: size, height: size)
        
        return controller.view
    }
}
