//
//  PaywallView.swift
//  nemu
//
//  デザイン仕様：「睡眠が資産になる」コンセプト
//  - ユーザー自身の睡眠データを表示し「積み上げた記録を守る」価値訴求
//  - データなしの場合はモックを表示（"サンプル"ラベルで審査対応）
//  - 年額プラン主役（¥2,900/年）・月額¥480も選択可
//  - 14日間無料トライアルは年額のみ
//

import SwiftUI

// assetGold は Design/DesignTokens.swift の Color extension で定義（モジュール共有）

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var purchaseService = PurchaseService.shared
    @State private var selectedPlan: PlanType = .yearly

    /// 呼び出し元から渡す。空の場合はモックデータを表示。
    var sessions: [SleepSession] = []

    enum PlanType { case monthly, yearly }

    // MARK: - 実データ集計

    private var completedSessions: [SleepSession] {
        sessions.filter { $0.wakeTime != nil }
    }

    private var hasRealData: Bool { !completedSessions.isEmpty }

    private var realWeeklyScores: [CGFloat] {
        let calendar = Calendar.current
        return (0..<7).reversed().compactMap { offset -> CGFloat? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd   = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let session  = completedSessions.first { $0.bedTime >= dayStart && $0.bedTime < dayEnd }
            return CGFloat(session?.score ?? 0)
        }
    }

    private var totalDays: Int { completedSessions.count }

    private var averageScore: Int {
        guard !completedSessions.isEmpty else { return 0 }
        return completedSessions.map(\.score).reduce(0, +) / completedSessions.count
    }

    private var totalHours: Int {
        Int(completedSessions.map(\.duration).reduce(0, +) / 3600)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.12)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 閉じるボタン
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding()
                }

                ScrollView {
                    VStack(spacing: 28) {

                        // ヘッダー
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.indigo.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "moon.stars.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.indigo.gradient)
                            }
                            Text("あなたの睡眠資産を守る")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Text("眠るたびに積み上がる、あなただけの記録")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)
                        .padding(.horizontal)

                        // 睡眠資産プレビュー（実データ or モック）
                        SleepAssetPreview(
                            weeklyScores: hasRealData ? realWeeklyScores : [48, 55, 61, 59, 70, 74, 82],
                            totalDays: hasRealData ? totalDays : 21,
                            totalHours: hasRealData ? totalHours : 168,
                            averageScore: hasRealData ? averageScore : 74,
                            isMock: !hasRealData
                        )
                        .padding(.horizontal)

                        // プレミアム特典リスト
                        VStack(spacing: 12) {
                            FeatureRow(icon: "waveform",                   text: "全ての自然音が使い放題")
                            FeatureRow(icon: "chart.line.uptrend.xyaxis",  text: "30日以上の詳細な睡眠履歴")
                            FeatureRow(icon: "bell.badge.fill",            text: "スマートアラームで最適覚醒")
                        }
                        .padding(.horizontal)

                        // プランセレクター（年額主役・月額も選択可）
                        PlanSelector(selectedPlan: $selectedPlan)
                            .padding(.horizontal)

                        // CTAボタン
                        VStack(spacing: 12) {
                            Button {
                                Task {
                                    if selectedPlan == .yearly {
                                        await purchaseService.purchaseYearly()
                                    } else {
                                        await purchaseService.purchaseMonthly()
                                    }
                                    if purchaseService.isPremium { dismiss() }
                                }
                            } label: {
                                Group {
                                    if purchaseService.isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text(selectedPlan == .yearly ? "14日間 無料で始める" : "月額プランで始める")
                                    }
                                }
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.indigo.gradient)
                                )
                            }
                            .disabled(purchaseService.isLoading)

                            if selectedPlan == .yearly {
                                Text("14日後、年額 ¥2,900 が自動更新されます")
                                    .font(.caption2)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.white.opacity(0.3))
                            }

                            if let error = purchaseService.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }

                            Button {
                                Task { await purchaseService.restore() }
                            } label: {
                                Text("購入を復元する")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.4))
                                    .underline()
                            }
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 32)
                    }
                }
            }
        }
    }
}

// MARK: - 睡眠資産プレビュー

private struct SleepAssetPreview: View {
    let weeklyScores: [CGFloat]
    let totalDays: Int
    let totalHours: Int
    let averageScore: Int
    let isMock: Bool

    private let dayLabels = ["月", "火", "水", "木", "金", "土", "日"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Label("睡眠資産の推移", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.caption.bold())
                    .foregroundStyle(Color.assetGold)
                Spacer()
                if isMock {
                    Text("サンプル")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.25))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                }
            }

            AssetLineChart(scores: weeklyScores, labels: dayLabels)
                .frame(height: 100)

            HStack(spacing: 10) {
                AssetMetricCard(icon: "flame.fill",  label: "記録日数",   value: "\(totalDays)日")
                AssetMetricCard(icon: "moon.fill",   label: "累計睡眠",   value: "\(totalHours)h")
                AssetMetricCard(icon: "sparkles",    label: "平均スコア", value: "\(averageScore)")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.assetGold.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// MARK: - 資産折れ線グラフ（Charts不使用・軽量実装）

private struct AssetLineChart: View {
    let scores: [CGFloat]
    let labels: [String]

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let maxScore: CGFloat = 100
                let points = scores.enumerated().map { i, score -> CGPoint in
                    let x = scores.count > 1
                        ? CGFloat(i) / CGFloat(scores.count - 1) * w
                        : w / 2
                    let y = h - (score / maxScore) * h
                    return CGPoint(x: x, y: y)
                }

                ZStack {
                    // エリア塗り
                    Path { path in
                        guard let first = points.first else { return }
                        path.move(to: CGPoint(x: first.x, y: h))
                        path.addLine(to: first)
                        for pt in points.dropFirst() { path.addLine(to: pt) }
                        if let last = points.last {
                            path.addLine(to: CGPoint(x: last.x, y: h))
                        }
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [Color.assetGold.opacity(0.3), Color.assetGold.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // ライン
                    Path { path in
                        guard let first = points.first else { return }
                        path.move(to: first)
                        for pt in points.dropFirst() { path.addLine(to: pt) }
                    }
                    .stroke(Color.assetGold, style: StrokeStyle(lineWidth: 2, lineJoin: .round))

                    // 最終点
                    if let last = points.last {
                        Circle()
                            .fill(Color.assetGold)
                            .frame(width: 8, height: 8)
                            .position(last)
                    }
                }
            }

            HStack(spacing: 0) {
                ForEach(labels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.3))
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - 資産指標カード

private struct AssetMetricCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.assetGold)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.07))
        )
    }
}

// MARK: - プランセレクター

private struct PlanSelector: View {
    @Binding var selectedPlan: PaywallView.PlanType

    var body: some View {
        VStack(spacing: 10) {
            PlanCard(
                isSelected: selectedPlan == .yearly,
                badge: "おすすめ",
                title: "年額プラン",
                price: "¥2,900",
                period: "/ 年",
                note: "¥242 / 月 · 14日間無料トライアル"
            ) { selectedPlan = .yearly }

            PlanCard(
                isSelected: selectedPlan == .monthly,
                badge: nil,
                title: "月額プラン",
                price: "¥480",
                period: "/ 月",
                note: "トライアルなし · いつでもキャンセル可"
            ) { selectedPlan = .monthly }
        }
    }
}

private struct PlanCard: View {
    let isSelected: Bool
    let badge: String?
    let title: String
    let price: String
    let period: String
    let note: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                        if let badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .foregroundStyle(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.assetGold))
                        }
                    }
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(price)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text(period)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.indigo.opacity(0.25) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isSelected ? Color.indigo.opacity(0.8) : Color.white.opacity(0.1),
                                lineWidth: 1.5
                            )
                    )
            )
        }
    }
}

// MARK: - 特典行

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.indigo.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.footnote.bold())
                    .foregroundStyle(.indigo)
            }
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
            Spacer()
            Image(systemName: "checkmark")
                .font(.caption.bold())
                .foregroundStyle(.indigo)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    PaywallView(sessions: [])
}
