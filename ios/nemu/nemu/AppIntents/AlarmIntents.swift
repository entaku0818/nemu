//
//  AlarmIntents.swift
//  nemu
//

import AppIntents
import AlarmKit
import Foundation

// MARK: - 「起きた！」ボタン

struct WakeUpIntent: AppIntent, LiveActivityIntent {
    static let title: LocalizedStringResource = "起きた！"

    func perform() async throws -> some IntentResult {
        // AlarmKit経由での起床フラグを保存（アプリ未起動時の復元用）
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "alarmKitWakeTimestamp")
        await MainActor.run {
            NotificationCenter.default.post(name: .alarmKitDidFire, object: nil)
        }
        return .result()
    }
}

// MARK: - 「あと5分…」スヌーズボタン

struct SnoozeIntent: AppIntent, LiveActivityIntent {
    static let title: LocalizedStringResource = "あと5分…"

    func perform() async throws -> some IntentResult {
        let snoozeDate = Date().addingTimeInterval(5 * 60)
        await AlarmService.shared.scheduleAlarm(at: snoozeDate, repeatDays: [])
        return .result()
    }
}

// MARK: - Notification名

extension Notification.Name {
    static let didWakeUp = Notification.Name("com.entaku.nemu.didWakeUp")
    /// AlarmKit の「起きた！」ボタンが押されたとき（スコア計算前）
    static let alarmKitDidFire = Notification.Name("com.entaku.nemu.alarmKitDidFire")
}
