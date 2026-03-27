//
//  PurchaseService.swift
//  nemu
//
//  STUB: RevenueCat未追加のため、UXテスト用スタブ実装
//  本番前に SPM で RevenueCat を追加して元の実装に戻すこと
//

import Foundation

@Observable
@MainActor
final class PurchaseService {
    static let shared = PurchaseService()

    private(set) var isPremium = false
    private(set) var isLoading = false
    var errorMessage: String?

    private init() {}

    func configure(apiKey: String) {}

    func refresh() async {}

    func purchaseMonthly() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isPremium = true
        isLoading = false
    }

    func purchaseYearly() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isPremium = true
        isLoading = false
    }

    func restore() async {
        errorMessage = "有効なサブスクリプションが見つかりませんでした"
    }
}
