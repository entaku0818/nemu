//
//  AlarmSetting.swift
//  nemu
//

import Foundation
import SwiftData

@Model
final class AlarmSetting {
    var wakeTime: Date
    var isEnabled: Bool
    var repeatDays: [Int]  // 0=Sun, 1=Mon, ..., 6=Sat
    var scheduledAlarmIDString: String?  // AlarmKit の Alarm.ID を永続化

    init(wakeTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date(),
         isEnabled: Bool = true,
         repeatDays: [Int] = [1, 2, 3, 4, 5]) {
        self.wakeTime = wakeTime
        self.isEnabled = isEnabled
        self.repeatDays = repeatDays
    }
}
