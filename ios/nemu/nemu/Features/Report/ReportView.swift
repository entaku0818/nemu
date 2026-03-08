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
                    HStack {
                        Text("睡眠レポート")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // 昨夜のスコア
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
        }
        .onAppear {
            viewModel.setup(modelContext: modelContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: .didWakeUp)) { _ in
            viewModel.setup(modelContext: modelContext)
        }
    }
}

// MARK: - スコアカード

struct ScoreCard: View {
    let session: SleepSession
    let grade: String

    var body: some View {
        VStack(spacing: 16) {
            Text("昨夜の睡眠")
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
                StatItem(label: "動いた回数", value: "\(session.motionEventCount)回")
                if let wakeTime = session.wakeTime {
                    StatItem(label: "起床", value: wakeTime.formatted(date: .omitted, time: .shortened))
                }
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

// MARK: - 週間グラフ

struct WeeklyChartCard: View {
    let weeklyScores: [(date: Date, score: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("過去7日間")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .tracking(2)

            Chart(weeklyScores, id: \.date) { item in
                BarMark(
                    x: .value("日付", item.date, unit: .day),
                    y: .value("スコア", item.score)
                )
                .foregroundStyle(
                    item.score > 0
                    ? Color.indigo.gradient
                    : Color.white.opacity(0.1).gradient
                )
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 50, 100]) { value in
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.4))
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.05))
                }
            }
            .frame(height: 140)
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
            Text("履歴")
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
            Text("まだデータがありません")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.4))
            Text("「就寝する」ボタンを押して\n初めての睡眠を記録しましょう")
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
