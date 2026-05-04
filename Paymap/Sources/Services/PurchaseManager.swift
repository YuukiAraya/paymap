import StoreKit
import Foundation

@MainActor
class PurchaseManager: ObservableObject {
    static let premiumProductID = "com.csn.Paymap.premium"

    @Published var isPremium = false
    @Published var product: Product?
    @Published var isPurchasing = false
    @Published var errorMessage: String?

    private var transactionListenerTask: Task<Void, Never>?

    init() {
        transactionListenerTask = listenForTransactions()
        Task {
            await loadProduct()
            await refreshPremiumStatus()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.premiumProductID])
            product = products.first
        } catch {
            print("PurchaseManager: failed to load products - \(error)")
        }
    }

    func refreshPremiumStatus() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, tx.productID == Self.premiumProductID {
                active = true
                break
            }
        }
        isPremium = active
    }

    func purchase() async {
        guard let product else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let tx) = verification {
                    await tx.finish()
                    await refreshPremiumStatus()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshPremiumStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let tx) = result {
                    await tx.finish()
                    await self?.refreshPremiumStatus()
                }
            }
        }
    }
}
