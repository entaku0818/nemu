//
//  PurchaseService.swift
//  nemu
//

import Foundation
import RevenueCat

@Observable
@MainActor
final class PurchaseService {
    static let shared = PurchaseService()
    private(set) var isPremium = false
    private(set) var isLoading = false
    var errorMessage: String?
    var analytics: NemuAnalyticsClient = .live

    private init() {}

    func configure(apiKey: String) {
        Purchases.configure(withAPIKey: apiKey)
        Task { await refresh() }
    }

    func refresh() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            isPremium = info.entitlements["premium"]?.isActive == true
        } catch {
            isPremium = false
        }
    }

    func purchaseMonthly() async {
        await purchase(productId: "com.entaku.nemu.premium.monthly")
    }

    func purchaseYearly() async {
        await purchase(productId: "com.entaku.nemu.premium.yearly")
    }

    private func purchase(productId: String) async {
        let plan = productId.contains("yearly") ? "yearly" : "monthly"
        isLoading = true
        defer { isLoading = false }
        analytics.logPurchaseStarted(plan)
        do {
            let products = try await Purchases.shared.products([productId])
            guard let product = products.first else {
                errorMessage = "商品が見つかりませんでした"
                analytics.logPurchaseFailed(plan)
                return
            }
            let (_, info, _) = try await Purchases.shared.purchase(product: product)
            isPremium = info.entitlements["premium"]?.isActive == true
            if isPremium {
                analytics.logPurchaseCompleted(plan)
            }
        } catch {
            errorMessage = "購入に失敗しました"
            analytics.logPurchaseFailed(plan)
        }
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let info = try await Purchases.shared.restorePurchases()
            isPremium = info.entitlements["premium"]?.isActive == true
            if isPremium {
                analytics.logPurchaseRestored()
            } else {
                errorMessage = "有効なサブスクリプションが見つかりませんでした"
            }
        } catch {
            errorMessage = "復元に失敗しました"
        }
    }
}
