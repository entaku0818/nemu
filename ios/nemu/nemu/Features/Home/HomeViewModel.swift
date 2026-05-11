//
//  HomeViewModel.swift
//  nemu
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class HomeViewModel {
    var isBedtimeMode: Bool = false
    var dbError: String?

    // 睡眠資産サマリー
    var latestSession: SleepSession?
    var streakDays: Int = 0
    var totalSleepHours: Int = 0

    // 次のアラーム（AlarmListViewのDBから読む）
    var nextAlarmSetting: AlarmSetting?

    var lastNightGrade: String {
        guard let score = latestSession?.score else { return "" }
        switch score {
        case 80...: return "とても良い"
        case 60..<80: return "良い"
        case 40..<60: return "普通"
        default: return "改善できそう"
        }
    }

    var nextAlarmDescription: String {
        guard let alarm = nextAlarmSetting, alarm.isEnabled else { return "アラームなし" }
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return "\(f.string(from: alarm.wakeTime)) に起こします"
    }

    private var modelContext: ModelContext?

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadNextAlarm()
        loadSleepStats()
    }

    func reload() {
        loadNextAlarm()
        loadSleepStats()
    }

    private func loadNextAlarm() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<AlarmSetting>(
            sortBy: [SortDescriptor(\.wakeTime)]
        )
        let alarms = (try? context.fetch(descriptor)) ?? []
        // 有効なアラームのうち最も近い時刻
        nextAlarmSetting = alarms.first(where: { $0.isEnabled }) ?? alarms.first
        // AlarmKit ID を復元
        if let idString = nextAlarmSetting?.scheduledAlarmIDString,
           let uuid = UUID(uuidString: idString) {
            AlarmService.shared.scheduledAlarmID = uuid
        }
    }

    private func loadSleepStats() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<SleepSession>(
            sortBy: [SortDescriptor(\.bedTime, order: .reverse)]
        )
        guard let sessions = try? context.fetch(descriptor) else { return }

        latestSession = sessions.first(where: { $0.score > 0 })

        let totalSeconds = sessions
            .filter { $0.score > 0 }
            .compactMap { session -> TimeInterval? in
                guard let wakeTime = session.wakeTime else { return nil }
                let duration = wakeTime.timeIntervalSince(session.bedTime)
                return duration > 0 && duration <= 86400 ? duration : nil
            }.reduce(0, +)
        totalSleepHours = Int(totalSeconds / 3600)

        streakDays = calculateStreak(sessions: sessions)
    }

    private func calculateStreak(sessions: [SleepSession]) -> Int {
        let validSessions = sessions.filter { $0.score > 0 }
        guard !validSessions.isEmpty else { return 0 }
        let calendar = Calendar.current
        var streak = 1
        var prevDay = calendar.startOfDay(for: validSessions[0].bedTime)
        for session in validSessions.dropFirst() {
            let sessionDay = calendar.startOfDay(for: session.bedTime)
            let diff = calendar.dateComponents([.day], from: sessionDay, to: prevDay).day ?? 0
            if diff == 1 {
                streak += 1
                prevDay = sessionDay
            } else {
                break
            }
        }
        return streak
    }

    func startBedtime() {
        isBedtimeMode = true
        scheduleEnabledAlarms()
    }

    private func scheduleEnabledAlarms() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<AlarmSetting>()
        guard let alarms = try? context.fetch(descriptor) else { return }
        for alarm in alarms where alarm.isEnabled {
            let existingID = alarm.scheduledAlarmIDString.flatMap { UUID(uuidString: $0) }
            Task {
                let newID = await AlarmService.shared.scheduleAlarm(
                    at: alarm.wakeTime,
                    repeatDays: Set(alarm.repeatDays),
                    existingID: existingID
                )
                alarm.scheduledAlarmIDString = newID?.uuidString
                try? context.save()
            }
        }
    }
}
