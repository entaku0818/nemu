//
//  DesignTokens.swift
//  nemu
//
//  アプリ全体で共有するデザイントークン
//  「睡眠が資産になる」コンセプトの視覚言語を一元管理
//

import SwiftUI

// MARK: - カラー

extension Color {
    /// 資産・ゴールドアクセント
    /// 使用箇所：PaywallView・ReportView の資産関連UI
    static let assetGold = Color(red: 1.0, green: 0.78, blue: 0.28)

    /// アプリ背景色（全画面共通）
    static let appBackground = Color(red: 0.06, green: 0.06, blue: 0.12)
}
