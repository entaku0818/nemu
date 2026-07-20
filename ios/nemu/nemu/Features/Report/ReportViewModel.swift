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

    // MARK: - 長期トレンドグラフ用データ（プレミアム）

    enum TrendRange: String, CaseIterable, Identifiable {
        case days30 = "30日"
        case days90 = "90日"
        case allTime = "全期間"

        var id: String { rawValue }
    }

    func trendScores(_ range: TrendRange) -> [(date: Date, score: Int)] {
        guard let context = modelContext else { return [] }
        let repo = SleepSessionRepository(context: context)
        switch range {
        case .days30: return repo.weeklyScores(days: 30)
        case .days90: return repo.weeklyScores(days: 90)
        case .allTime: return repo.allScores()
        }
    }

    // MARK: - CSVエクスポート

    var csvString: String {
        var lines = ["日付,就寝時刻,起床時刻,睡眠時間(分),スコア,体動回数,いびき回数"]
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ja_JP")
        fmt.dateFormat = "yyyy/MM/dd"
        let timeFmt = DateFormatter()
        timeFmt.locale = Locale(identifier: "ja_JP")
        timeFmt.dateFormat = "HH:mm"
        for s in allSessions {
            let date = fmt.string(from: s.bedTime)
            let bed = timeFmt.string(from: s.bedTime)
            let wake = s.wakeTime.map { timeFmt.string(from: $0) } ?? ""
            let mins = Int(s.duration / 60)
            lines.append("\(date),\(bed),\(wake),\(mins),\(s.score),\(s.motionEventCount),\(s.snoreTimestamps.count)")
        }
        return lines.joined(separator: "\n")
    }
}
