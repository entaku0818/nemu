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
        }
    }

    func saveAlarmSetting() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<AlarmSetting>()
        if let existing = try? context.fetch(descriptor).first {
            existing.wakeTime = wakeTime
            existing.isEnabled = isAlarmEnabled
            existing.repeatDays = Array(repeatDays)
        } else {
            let setting = AlarmSetting(wakeTime: wakeTime, isEnabled: isAlarmEnabled, repeatDays: Array(repeatDays))
            context.insert(setting)
        }
        try? context.save()
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
