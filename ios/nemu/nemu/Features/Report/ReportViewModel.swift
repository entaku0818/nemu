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
        let repo = SleepSessionRepository(context: context)
        allSessions = repo.fetchValid()
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

    var totalSleepHours: Int {
        guard let context = modelContext else { return 0 }
        return SleepSessionRepository(context: context).totalSleepHours()
    }

    // MARK: - 週間グラフ用データ

    var weeklyScores: [(date: Date, score: Int)] {
        guard let context = modelContext else { return [] }
        return SleepSessionRepository(context: context).weeklyScores()
    }
}
