//
//  SleepSession.swift
//  nemu
//

import Foundation
import SwiftData

@Model
final class SleepSession {
    var bedTime: Date
    var wakeTime: Date?
    var motionEventCount: Int   // 動いた回数
    var score: Int              // 睡眠スコア 0-100

    init(bedTime: Date = Date(), motionEventCount: Int = 0) {
        self.bedTime = bedTime
        self.motionEventCount = motionEventCount
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

    func calculateScore() {
        guard let wakeTime else { return }
        let hours = wakeTime.timeIntervalSince(bedTime) / 3600
        // 理想: 7〜8時間、動き少なめ
        let durationScore = min(100, max(0, Int((hours - 5) / 3 * 60)))
        let motionPenalty = min(40, motionEventCount * 2)
        score = max(0, durationScore - motionPenalty + 40)
    }
}
