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
    private init() {}

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
}
