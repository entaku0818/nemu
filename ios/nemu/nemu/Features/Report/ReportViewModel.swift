//
//  ReportViewModel.swift
//  nemu
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class ReportViewModel {
    var latestSession: SleepSession?
    var allSessions: [SleepSession] = []

    private var modelContext: ModelContext?

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSessions()
    }

    private func loadSessions() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<SleepSession>(
            sortBy: [SortDescriptor(\.bedTime, order: .reverse)]
        )
        allSessions = (try? context.fetch(descriptor)) ?? []
        latestSession = allSessions.first
    }

    // MARK: - スコア表示

    var scoreGrade: String {
        guard let score = latestSession?.score else { return "-" }
        switch score {
        case 80...: return "とても良い"
        case 60..<80: return "良い"
        case 40..<60: return "普通"
        default: return "改善できそう"
        }
    }

    var scoreColor: String {
        guard let score = latestSession?.score else { return "gray" }
        switch score {
        case 80...: return "green"
        case 60..<80: return "blue"
        case 40..<60: return "yellow"
        default: return "orange"
        }
    }

    // MARK: - 累計睡眠時間（資産総量）

    /// 全セッションの合計睡眠時間（時間単位・切り捨て）
    var totalSleepHours: Int {
        let totalSeconds = allSessions.compactMap { session -> TimeInterval? in
            guard let wake = session.wakeTime else { return nil }
            return wake.timeIntervalSince(session.bedTime)
        }.reduce(0, +)
        return Int(totalSeconds / 3600)
    }

    // MARK: - 週間グラフ用データ

    var weeklyScores: [(date: Date, score: Int)] {
        let calendar = Calendar.current
        return (0..<7).compactMap { dayOffset -> (Date, Int)? in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { return nil }
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let session = allSessions.first { $0.bedTime >= dayStart && $0.bedTime < dayEnd }
            return (dayStart, session?.score ?? 0)
        }.reversed()
    }
}
