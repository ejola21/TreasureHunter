// Services/StoreService.swift
import StoreKit
import Observation

@Observable
final class StoreService {
    static let shared = StoreService()

    // 기존 상품 ID (MyInfo.m)
    static let timeAdd10 = "time_add_10"
    static let solutionAdd10 = "solution_add_10"

    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []

    init() {
        Task { await listenForTransactions() }
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: [
                Self.timeAdd10,
                Self.solutionAdd10
            ])
        } catch {}
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)

            // 기존 resultbuy 로직 — NSUserDefaults에 수량 추가
            switch transaction.productID {
            case Self.timeAdd10:
                AppState.shared.timeAddCount += 10
            case Self.solutionAdd10:
                AppState.shared.solutionCount += 10
            default:
                break
            }

            await transaction.finish()

        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if let transaction = try? checkVerified(result) {
                await transaction.finish()
            }
        }
    }

    enum StoreError: Error {
        case verificationFailed
    }
}
