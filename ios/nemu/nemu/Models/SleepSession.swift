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
        let seconds = wakeTime.timeIntervalSince(bedTime)
        // 30分未満は記録としてカウントしない
        guard seconds >= 1800 else {
            score = 0
            return
        }
        let hours = seconds / 3600
        // 理想: 7時間。5h未満=低、5〜8h=線形増加、8h超=100点
        let durationScore: Int
        if hours < 5 {
            durationScore = Int(hours / 5 * 40)           // 0〜40点
        } else if hours <= 8 {
            durationScore = Int(40 + (hours - 5) / 3 * 60) // 40〜100点
        } else {
            durationScore = max(0, Int(100 - (hours - 8) * 10)) // 8h超は減点
        }
        let motionPenalty = min(40, motionEventCount * 2)
        score = max(0, min(100, durationScore - motionPenalty))
    }
}
