//
//  SleepSession.swift
//  nemu
//

import Foundation
import SwiftData

struct ScoreBreakdown {
    let durationScore: Int      // 睡眠時間スコア (0-100)
    let motionPenalty: Int      // 体動ペナルティ (0-40)
    let distributionBonus: Int  // 後半集中ボーナス (0 or 10)
    let snorePenalty: Int       // いびきペナルティ (0-20)
    let total: Int              // 合計 (0-100)
}

@Model
final class SleepSession {
    var bedTime: Date
    var wakeTime: Date?
    var motionEventCount: Int    // Legacy: CoreMotion query count
    var motionTimestamps: [Date] // タイムスタンプ付き体動ログ
    var snoreTimestamps: [Date]  // いびき検知タイムスタンプ
    var score: Int

    init(bedTime: Date = Date(), motionEventCount: Int = 0) {
        self.bedTime = bedTime
        self.motionEventCount = motionEventCount
        self.motionTimestamps = []
        self.snoreTimestamps = []
        self.score = 0
    }

    var duration: TimeInterval {
        guard let wakeTime else { return 0 }
        return wakeTime.timeIntervalSince(bedTime)
    }

    var durationFormatted: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)時間\(minutes)分"
    }

    var dateLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(bedTime) { return "今日" }
        if calendar.isDateInYesterday(bedTime) { return "昨夜" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        return formatter.string(from: bedTime)
    }

    var scoreBreakdown: ScoreBreakdown {
        guard let wakeTime else {
            return ScoreBreakdown(durationScore: 0, motionPenalty: 0, distributionBonus: 0, snorePenalty: 0, total: 0)
        }
        return SleepSession.computeBreakdown(
            bedTime: bedTime,
            wakeTime: wakeTime,
            motionEventCount: motionEventCount,
            motionTimestamps: motionTimestamps,
            snoreTimestamps: snoreTimestamps
        )
    }

    func calculateScore() {
        score = scoreBreakdown.total
    }

    // テストからも呼べるよう static に切り出す
    static func computeBreakdown(
        bedTime: Date,
        wakeTime: Date,
        motionEventCount: Int,
        motionTimestamps: [Date],
        snoreTimestamps: [Date]
    ) -> ScoreBreakdown {
        let seconds = wakeTime.timeIntervalSince(bedTime)
        guard seconds >= 1800 else {
            return ScoreBreakdown(durationScore: 0, motionPenalty: 0, distributionBonus: 0, snorePenalty: 0, total: 0)
        }

        // 睡眠時間スコア
        let hours = seconds / 3600
        let durationScore: Int
        if hours < 5 {
            durationScore = Int(hours / 5 * 40)
        } else if hours <= 8 {
            durationScore = Int(40 + (hours - 5) / 3 * 60)
        } else {
            durationScore = max(0, Int(100 - (hours - 8) * 10))
        }

        // 体動ペナルティ
        let effectiveCount = motionTimestamps.isEmpty ? motionEventCount : motionTimestamps.count
        let motionPenalty = min(40, effectiveCount * 2)

        // 後半集中ボーナス：後半に体動が多い = 自然な目覚め準備
        let distributionBonus: Int
        if !motionTimestamps.isEmpty {
            let midpoint = bedTime.addingTimeInterval(seconds / 2)
            let firstHalf = motionTimestamps.filter { $0 < midpoint }.count
            let secondHalf = motionTimestamps.filter { $0 >= midpoint }.count
            distributionBonus = secondHalf > firstHalf ? 10 : 0
        } else {
            distributionBonus = 0
        }

        // いびきペナルティ
        let snorePenalty = min(20, snoreTimestamps.count * 3)

        let total = max(0, min(100, durationScore - motionPenalty + distributionBonus - snorePenalty))
        return ScoreBreakdown(
            durationScore: durationScore,
            motionPenalty: motionPenalty,
            distributionBonus: distributionBonus,
            snorePenalty: snorePenalty,
            total: total
        )
    }
}
