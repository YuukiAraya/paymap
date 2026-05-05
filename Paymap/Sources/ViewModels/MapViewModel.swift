import Foundation
import Combine
import CoreLocation
import FirebaseCore
import FirebaseAuth

// MARK: - Filter Model
struct StoreFilter {
    var paymentIds: Set<String> = []
    var category: StoreCategory? = nil
    var requireWifi: Bool = false
    var requirePower: Bool = false

    var isActive: Bool {
        !paymentIds.isEmpty || category != nil || requireWifi || requirePower
    }

    mutating func clear() {
        paymentIds = []
        category = nil
        requireWifi = false
        requirePower = false
    }
}

// MARK: - MapViewModel
class MapViewModel: ObservableObject {
    @Published var stores: [Store] = []
    @Published var selectedStore: Store?
    @Published var errorMessage: String?
    @Published var activeFilter = StoreFilter()
    @Published var isOffline: Bool = false
    @Published var favoriteStoreIds: Set<String> = []

    private let storeService = StoreService()
    private let placesService: PlacesServiceProtocol

    init(placesService: PlacesServiceProtocol = PlacesService()) {
        self.placesService = placesService
    }

    // MARK: - Filtered stores (client-side)
    var filteredStores: [Store] {
        guard activeFilter.isActive else { return stores }
        return stores.filter { store in
            if let cat = activeFilter.category, store.category != cat { return false }
            if activeFilter.requireWifi, store.hasWifi != true { return false }
            if activeFilter.requirePower, store.hasPower != true { return false }
            if !activeFilter.paymentIds.isEmpty {
                let supported = Set(store.supportedPaymentMethods)
                if !activeFilter.paymentIds.isSubset(of: supported) { return false }
            }
            return true
        }
    }

    // MARK: - Fetch stores (Firestore GeoQuery → mock fallback → offline cache)
    @MainActor
    func fetchStores(in region: CLLocationCoordinate2D) {
        Task {
            do {
                if FirebaseApp.app() != nil, Auth.auth().currentUser != nil {
                    if !UserDefaults.standard.bool(forKey: "shinjukuSeeded") {
                        do {
                            try await storeService.seedShinjukuStores()
                            UserDefaults.standard.set(true, forKey: "shinjukuSeeded")
                        } catch {}
                    }
                    let result = try await storeService.fetchStores(
                        near: region.latitude, longitude: region.longitude, radiusKm: 20.0)
                    if !result.isEmpty {
                        self.stores = applyFavoriteFlags(result)
                        storeService.cacheStores(result)
                        self.isOffline = false
                        return
                    }
                }
                let places = try await placesService.fetchNearbyPlaces(coordinate: region, radius: 1000)
                self.stores = applyFavoriteFlags(places)
                self.isOffline = false
            } catch {
                self.errorMessage = error.localizedDescription
                let cached = storeService.loadCachedStores()
                if !cached.isEmpty {
                    self.stores = applyFavoriteFlags(cached)
                    self.isOffline = true
                } else {
                    self.stores = applyFavoriteFlags((try? await placesService.fetchNearbyPlaces(coordinate: region, radius: 1000)) ?? [])
                }
            }
        }
    }

    // MARK: - Submit 80% consensus report
    func submitConsensusReport(for store: Store, methods: [String], uid: String? = nil) {
        Task {
            do {
                if FirebaseApp.app() != nil, Auth.auth().currentUser != nil {
                    let allIds = PaymentCatalog.all.map { $0.id }
                    for id in allIds {
                        try await storeService.submitPaymentReport(
                            storeId: store.id,
                            methodId: id,
                            isSupported: methods.contains(id)
                        )
                    }
                }
                await MainActor.run { self.updateLocalStore(store.id, methods: methods) }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.updateLocalStore(store.id, methods: methods)
                }
            }
        }
    }

    // MARK: - Favorites
    func loadFavorites(uid: String) {
        Task {
            do {
                let ids = try await storeService.fetchFavoriteStoreIds(uid: uid)
                await MainActor.run {
                    self.favoriteStoreIds = Set(ids)
                    self.stores = self.stores.map { s in
                        var copy = s
                        copy.isFavorited = ids.contains(s.id)
                        return copy
                    }
                }
            } catch {}
        }
    }

    func toggleFavorite(store: Store, uid: String) {
        let wasFavorited = favoriteStoreIds.contains(store.id)
        let newState = !wasFavorited
        if newState {
            favoriteStoreIds.insert(store.id)
        } else {
            favoriteStoreIds.remove(store.id)
        }
        updateFavoriteFlag(storeId: store.id, isFav: newState)
        Task {
            do {
                try await storeService.toggleFavorite(storeId: store.id, uid: uid, isFavoriting: newState)
            } catch {
                await MainActor.run {
                    if newState { self.favoriteStoreIds.remove(store.id) }
                    else { self.favoriteStoreIds.insert(store.id) }
                    self.updateFavoriteFlag(storeId: store.id, isFav: !newState)
                }
            }
        }
    }

    // MARK: - Private helpers
    private func updateLocalStore(_ storeId: String, methods: [String]) {
        if let idx = stores.firstIndex(where: { $0.id == storeId }) {
            stores[idx].supportedPaymentMethods = methods
            if selectedStore?.id == storeId { selectedStore = stores[idx] }
        }
    }

    private func updateFavoriteFlag(storeId: String, isFav: Bool) {
        if let idx = stores.firstIndex(where: { $0.id == storeId }) {
            stores[idx].isFavorited = isFav
            if selectedStore?.id == storeId { selectedStore = stores[idx] }
        }
    }

    private func applyFavoriteFlags(_ list: [Store]) -> [Store] {
        list.map { s in
            var copy = s
            copy.isFavorited = favoriteStoreIds.contains(s.id)
            return copy
        }
    }
}
