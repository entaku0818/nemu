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

    // アプリ強制終了で未完了になったセッションの復元
    var incompleteSession: SleepSession?

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

    var analytics: NemuAnalyticsClient = .live

    var incompleteSessionMessage: String {
        guard let session = incompleteSession else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d HH:mm"
        return "就寝開始: \(formatter.string(from: session.bedTime))\nアプリが終了していたため記録が保存されていません。"
    }

    private var modelContext: ModelContext?

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadNextAlarm()
        loadSleepStats()
        checkForIncompleteSession()
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
        nextAlarmSetting = alarms.first(where: { $0.isEnabled }) ?? alarms.first
        if let idString = nextAlarmSetting?.scheduledAlarmIDString,
           let uuid = UUID(uuidString: idString) {
            AlarmService.shared.scheduledAlarmID = uuid
        }
    }

    private func loadSleepStats() {
        guard let context = modelContext else { return }
        let repo = SleepSessionRepository(context: context)
        latestSession = repo.latestValidSession()
        totalSleepHours = repo.totalSleepHours()
        streakDays = repo.streak()
    }

    // MARK: - Incomplete Session Recovery

    private func checkForIncompleteSession() {
        guard let context = modelContext,
              let bedTime = SleepSessionFinalizer.activeBedTime() else {
            incompleteSession = nil
            return
        }
        let descriptor = FetchDescriptor<SleepSession>()
        let sessions = (try? context.fetch(descriptor)) ?? []
        incompleteSession = sessions.first {
            abs($0.bedTime.timeIntervalSince(bedTime)) < 1 && $0.wakeTime == nil
        }
        if incompleteSession == nil {
            SleepSessionFinalizer.clearActive()
        }
    }

    func finalizeIncompleteSession() {
        guard let session = incompleteSession, let context = modelContext else { return }
        incompleteSession = nil

        // アラームで起きた場合は「起きた！」ボタンを押した時刻を使う（より正確）
        let alarmTimestamp = UserDefaults.standard.double(forKey: "alarmKitWakeTimestamp")
        let wakeTime: Date
        if alarmTimestamp > 0 {
            wakeTime = Date(timeIntervalSince1970: alarmTimestamp)
            UserDefaults.standard.removeObject(forKey: "alarmKitWakeTimestamp")
        } else {
            wakeTime = Date()
        }

        Task {
            await SleepSessionFinalizer.finalize(session, wakeTime: wakeTime, context: context)
            loadSleepStats()
        }
    }

    func discardIncompleteSession() {
        guard let session = incompleteSession, let context = modelContext else {
            SleepSessionFinalizer.clearActive()
            incompleteSession = nil
            return
        }
        incompleteSession = nil
        SleepSessionFinalizer.discard(session, context: context)
    }

    // MARK: - Bedtime

    func startBedtime() {
        isBedtimeMode = true
        scheduleEnabledAlarms()
        let wakeHour = Calendar.current.component(.hour, from: nextAlarmSetting?.wakeTime ?? Date())
        analytics.logBedtimeStart(wakeHour)
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
