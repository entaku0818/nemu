//
//  AlarmService.swift
//  nemu
//

import Foundation
import AlarmKit
import SwiftUI
import Observation

// MARK: - AlarmMetadata

struct NemuAlarmMetadata: AlarmMetadata {}

// MARK: - AlarmService

@Observable
@MainActor
final class AlarmService {
    static let shared = AlarmService()

    var isAuthorized: Bool = false
    var scheduledAlarmID: Alarm.ID?
    var errorMessage: String?

    private init() {}

    // MARK: - 認可

    func requestAuthorization() async {
        do {
            let status = try await AlarmManager.shared.requestAuthorization()
            isAuthorized = status == .authorized
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - アラームをスケジュール

    func scheduleAlarm(at date: Date, repeatDays: Set<Int>) async {
        if !isAuthorized {
            await requestAuthorization()
            guard isAuthorized else { return }
        }

        await cancelAlarm()

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)

        let schedule: Alarm.Schedule
        if repeatDays.isEmpty {
            schedule = .fixed(date)
        } else {
            let weekdays: [Locale.Weekday] = repeatDays.compactMap {
                switch $0 {
                case 0: return .sunday
                case 1: return .monday
                case 2: return .tuesday
                case 3: return .wednesday
                case 4: return .thursday
                case 5: return .friday
                case 6: return .saturday
                default: return nil
                }
            }
            let time = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
            schedule = .relative(.init(time: time, repeats: .weekly(weekdays)))
        }

        let alertPresentation = AlarmPresentation.Alert(
            title: "おはようございます",
            stopButton: AlarmButton(text: "起きた！", textColor: .white, systemImageName: "sun.max.fill"),
            secondaryButton: AlarmButton(text: "あと5分…", textColor: .white, systemImageName: "zzz"),
            secondaryButtonBehavior: .custom
        )
        let presentation = AlarmPresentation(alert: alertPresentation)

        let attributes = AlarmAttributes<NemuAlarmMetadata>(
            presentation: presentation,
            metadata: NemuAlarmMetadata(),
            tintColor: Color.indigo
        )

        let configuration = AlarmManager.AlarmConfiguration<NemuAlarmMetadata>.alarm(
            schedule: schedule,
            attributes: attributes,
            stopIntent: WakeUpIntent(),
            secondaryIntent: SnoozeIntent()
        )

        do {
            let id = UUID()
            let _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
            scheduledAlarmID = id
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - キャンセル

    func cancelAlarm() async {
        guard let id = scheduledAlarmID else { return }
        do {
            try await AlarmManager.shared.cancel(id: id)
            scheduledAlarmID = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - 次のアラーム日時を計算

    func nextAlarmDate(wakeTime: Date, repeatDays: Set<Int>) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: wakeTime)
        let minute = calendar.component(.minute, from: wakeTime)

        for dayOffset in 0..<8 {
            guard let candidate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let weekday = calendar.component(.weekday, from: candidate) - 1  // 0=Sun

            if repeatDays.isEmpty || repeatDays.contains(weekday) {
                if let alarmDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: candidate),
                   alarmDate > now {
                    return alarmDate
                }
            }
        }
        return nil
    }
}
