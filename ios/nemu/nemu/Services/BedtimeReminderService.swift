//
//  BedtimeReminderService.swift
//  nemu
//
// 就寝リマインダー通知を管理する。指定時刻に毎日 UNUserNotification を送る。
//

import Foundation
import UserNotifications

final class BedtimeReminderService {
    static let shared = BedtimeReminderService()
    private let notificationID = "com.entaku.nemu.bedtimeReminder"
    private let wakeCheckID    = "com.entaku.nemu.wakeCheck"
    private init() {}

    // MARK: - 就寝リマインダー（毎日）

    func schedule(at time: Date, enabled: Bool) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])
        guard enabled else { return }

        let status = await center.notificationSettings()
        guard status.authorizationStatus == .authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "そろそろ寝る時間です"
        content.body = "今夜も睡眠資産を積み上げましょう"
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)

        try? await center.add(request)
    }

    func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationID])
    }

    // MARK: - 起床確認通知（アラーム時刻 + 30分後に1回）

    /// wakeTime に nil を渡した場合は即時（30分後）にスケジュール
    func scheduleWakeCheck(after wakeTime: Date?) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [wakeCheckID])

        let status = await center.notificationSettings()
        guard status.authorizationStatus == .authorized else { return }

        let fireAt = (wakeTime ?? Date()).addingTimeInterval(30 * 60)
        guard fireAt > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "起きましたか？"
        content.body = "睡眠記録を保存するにはアプリを開いてください"
        content.sound = .default

        let interval = fireAt.timeIntervalSinceNow
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: wakeCheckID, content: content, trigger: trigger)

        try? await center.add(request)
    }

    func cancelWakeCheck() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [wakeCheckID])
    }
}
