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
    var wakeTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    var isAlarmEnabled: Bool = true
    var repeatDays: Set<Int> = [1, 2, 3, 4, 5]  // Mon–Fri
    var isBedtimeMode: Bool = false
    var dbError: String?

    private var modelContext: ModelContext?

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadAlarmSetting()
    }

    private func loadAlarmSetting() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<AlarmSetting>()
        if let setting = try? context.fetch(descriptor).first {
            wakeTime = setting.wakeTime
            isAlarmEnabled = setting.isEnabled
            repeatDays = Set(setting.repeatDays)
            // アプリ再起動後にアラームIDを復元
            if let idString = setting.scheduledAlarmIDString,
               let uuid = UUID(uuidString: idString) {
                AlarmService.shared.scheduledAlarmID = uuid
            }
        }
    }

    func saveAlarmSetting() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<AlarmSetting>()
        do {
            if let existing = try context.fetch(descriptor).first {
                existing.wakeTime = wakeTime
                existing.isEnabled = isAlarmEnabled
                existing.repeatDays = Array(repeatDays)
            } else {
                let setting = AlarmSetting(wakeTime: wakeTime, isEnabled: isAlarmEnabled, repeatDays: Array(repeatDays))
                context.insert(setting)
            }
            try context.save()
        } catch {
            dbError = "設定の保存に失敗しました: \(error.localizedDescription)"
        }
    }

    private func saveAlarmID() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<AlarmSetting>()
        guard let existing = try? context.fetch(descriptor).first else { return }
        existing.scheduledAlarmIDString = AlarmService.shared.scheduledAlarmID?.uuidString
        do {
            try context.save()
        } catch {
            dbError = "アラームIDの保存に失敗しました: \(error.localizedDescription)"
        }
    }

    func toggleRepeatDay(_ day: Int) {
        if repeatDays.contains(day) {
            repeatDays.remove(day)
        } else {
            repeatDays.insert(day)
        }
        saveAlarmSetting()
    }

    func startBedtime() {
        isBedtimeMode = true
        scheduleAlarmIfNeeded()
    }

    // MARK: - AlarmKit

    func scheduleAlarmIfNeeded() {
        guard isAlarmEnabled else { return }
        let alarmService = AlarmService.shared
        guard let nextDate = alarmService.nextAlarmDate(wakeTime: wakeTime, repeatDays: repeatDays) else { return }
        Task {
            await alarmService.scheduleAlarm(at: nextDate, repeatDays: repeatDays)
            saveAlarmID()  // スケジュール後にIDをDBへ永続化
        }
    }

    func cancelAlarm() {
        Task {
            await AlarmService.shared.cancelAlarm()
        }
    }

    var wakeTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: wakeTime)
    }

    var nextAlarmDescription: String {
        guard isAlarmEnabled else { return "アラームオフ" }
        return "\(wakeTimeFormatted) に起こします"
    }
}
