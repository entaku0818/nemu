//
//  ReportView.swift
//  nemu
//

import SwiftUI
import SwiftData
import Charts

struct ReportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ReportViewModel()

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.12).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // ヘッダー
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("睡眠資産")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Text("眠るたびに積み上がる記録")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        Spacer()
                        // 累計睡眠時間バッジ
                        if !viewModel.allSessions.isEmpty {
                            TotalAssetBadge(totalHours: viewModel.totalSleepHours)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // スコアカード
                    if let session = viewModel.latestSession {
                        ScoreCard(session: session, grade: viewModel.scoreGrade)
                    } else {
                        EmptyReportCard()
                    }

                    // 週間グラフ
                    WeeklyChartCard(weeklyScores: viewModel.weeklyScores)

                    // 履歴リスト
                    if !viewModel.allSessions.isEmpty {
                        SessionHistoryCard(sessions: Array(viewModel.allSessions.prefix(7)))
                    }

                    Spacer(minLength: 40)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !PurchaseService.shared.isPremium {
                    BannerAdView()
                        .frame(height: 50)
                        .background(Color.appBackground)
                }
            }
        }
        .onAppear {
            viewModel.setup(modelContext: modelContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: .didWakeUp)) { _ in
            viewModel.setup(modelContext: modelContext)
        }
    }
}

// MARK: - 累計資産バッジ

/// ヘッダー右に表示：「累計○○時間の睡眠資産」で継続モチベーションを強化
struct TotalAssetBadge: View {
    let totalHours: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "moon.fill")
                .font(.system(size: 10))
                .foregroundStyle(Color.assetGold)
            Text("累計 \(totalHours)h")
                .font(.caption.bold())
                .foregroundStyle(Color.assetGold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.assetGold.opacity(0.12))
                .overlay(Capsule().strokeBorder(Color.assetGold.opacity(0.3), lineWidth: 1))
        )
    }
}

// MARK: - スコアカード

struct ScoreCard: View {
    let session: SleepSession
    let grade: String
    @State private var showBreakdown = false

    private var breakdown: ScoreBreakdown { session.scoreBreakdown }

    var body: some View {
        VStack(spacing: 16) {
            Text("\(session.dateLabel)のスコア")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .tracking(2)

            HStack(alignment: .bottom, spacing: 4) {
                Text("\(session.score)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("/ 100")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, 8)
            }

            Text(grade)
                .font(.subheadline.bold())
                .foregroundStyle(.indigo)

            HStack(spacing: 24) {
                StatItem(label: "睡眠時間", value: session.durationFormatted)
                StatItem(label: "体動", value: "\(session.motionEventCount)回")
                if session.snoreTimestamps.count > 0 {
                    StatItem(label: "いびき", value: "\(session.snoreTimestamps.count)回")
                }
                if let wakeTime = session.wakeTime {
                    StatItem(label: "起床", value: wakeTime.formatted(date: .omitted, time: .shortened))
                }
            }

            // スコア内訳（タップで展開）
            Button {
                withAnimation(.spring(duration: 0.3)) { showBreakdown.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Text("スコア内訳")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                    Image(systemName: showBreakdown ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.3))
                }
            }

            if showBreakdown {
                ScoreBreakdownView(breakdown: breakdown)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.07))
        )
        .padding(.horizontal)
    }
}

struct ScoreBreakdownView: View {
    let breakdown: ScoreBreakdown

    var body: some View {
        VStack(spacing: 8) {
            Divider().background(Color.white.opacity(0.1))
            BreakdownRow(label: "睡眠時間スコア", value: "+\(breakdown.durationScore)", color: .white.opacity(0.7))
            BreakdownRow(label: "体動ペナルティ", value: "-\(breakdown.motionPenalty)", color: .orange.opacity(0.8))
            if breakdown.distributionBonus > 0 {
                BreakdownRow(label: "自然な目覚めボーナス", value: "+\(breakdown.distributionBonus)", color: .green.opacity(0.9))
            }
            if breakdown.snorePenalty > 0 {
                BreakdownRow(label: "いびきペナルティ", value: "-\(breakdown.snorePenalty)", color: .red.opacity(0.8))
            }
            Divider().background(Color.white.opacity(0.1))
            BreakdownRow(label: "合計", value: "\(breakdown.total)点", color: .white, bold: true)
        }
    }
}

private struct BreakdownRow: View {
    let label: String
    let value: String
    let color: Color
    var bold: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(bold ? .subheadline.bold() : .caption)
                .foregroundStyle(bold ? .white : .white.opacity(0.5))
            Spacer()
            Text(value)
                .font(bold ? .subheadline.bold() : .caption.bold())
                .foregroundStyle(color)
        }
    }
}

struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
        }
    }
}

// MARK: - 週間資産グラフ

/// デザイン仕様：「資産の成長」表現
/// - タイトルを「今週の睡眠資産」に変更
/// - BarMarkからAreaMark+LineMarkへ：蓄積・右肩上がりの成長感
/// - ゴールドグラデーションで"資産色"を統一
/// - スコアありの日はゴールド、記録なしは薄いグレーで差をつける
struct WeeklyChartCard: View {
    let weeklyScores: [(date: Date, score: Int)]

    /// 今週の最高スコア（強調表示用）
    private var maxScore: Int { weeklyScores.map(\.score).max() ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Label("今週の睡眠資産", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.caption.bold())
                    .foregroundStyle(Color.assetGold)
                Spacer()
                if maxScore > 0 {
                    Text("最高 \(maxScore)pt")
                        .font(.caption2.bold())
                        .foregroundStyle(Color.assetGold.opacity(0.8))
                }
            }

            Chart(weeklyScores, id: \.date) { item in

                // エリア（資産の蓄積・面積感）
                AreaMark(
                    x: .value("日付", item.date, unit: .day),
                    y: .value("スコア", item.score)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.assetGold.opacity(0.35), Color.assetGold.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                // ライン（成長の軌跡）
                LineMark(
                    x: .value("日付", item.date, unit: .day),
                    y: .value("スコア", item.score)
                )
                .foregroundStyle(
                    item.score > 0 ? Color.assetGold : Color.white.opacity(0.1)
                )
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)

                // 各日のポイントマーカー
                PointMark(
                    x: .value("日付", item.date, unit: .day),
                    y: .value("スコア", item.score)
                )
                .foregroundStyle(item.score > 0 ? Color.assetGold : Color.white.opacity(0.15))
                .symbolSize(item.score == maxScore && maxScore > 0 ? 60 : 30)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 50, 100]) { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.3))
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.05))
                }
            }
            .chartYScale(domain: 0...100)
            .frame(height: 150)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.07))
        )
        .padding(.horizontal)
    }
}

// MARK: - 履歴リスト

struct SessionHistoryCard: View {
    let sessions: [SleepSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("蓄積ログ")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .tracking(2)

            ForEach(sessions) { session in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.bedTime.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                        Text(session.durationFormatted)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Spacer()
                    Text("\(session.score)")
                        .font(.title3.bold())
                        .foregroundStyle(.indigo)
                }
                .padding(.vertical, 4)

                if session.id != sessions.last?.id {
                    Divider()
                        .background(Color.white.opacity(0.1))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.07))
        )
        .padding(.horizontal)
    }
}

// MARK: - データなし

struct EmptyReportCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 40))
                .foregroundStyle(.indigo.opacity(0.5))
            Text("まだ睡眠資産がありません")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.4))
            Text("「就寝モードへ」ボタンを押して\n最初の資産を積み上げましょう")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.07))
        )
        .padding(.horizontal)
    }
}

#Preview {
    ReportView()
        .modelContainer(for: [SleepSession.self, AlarmSetting.self], inMemory: true)
}
