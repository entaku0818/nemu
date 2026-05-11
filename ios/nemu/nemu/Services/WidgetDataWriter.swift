//
//  WidgetDataWriter.swift
//  nemu
//
// App Group UserDefaults にアラーム情報を書き込み、ウィジェットを更新する。
//

import Foundation
import WidgetKit

enum WidgetDataWriter {
    private static let appGroupID = "group.com.entaku.slumber"
    private static let nextAlarmKey = "nextAlarmTimeInterval"
    private static let nextAlarmEnabledKey = "nextAlarmEnabled"

    static func update(nextAlarm: Date?, enabled: Bool) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        if let alarm = nextAlarm {
            defaults.set(alarm.timeIntervalSince1970, forKey: nextAlarmKey)
        } else {
            defaults.removeObject(forKey: nextAlarmKey)
        }
        defaults.set(enabled, forKey: nextAlarmEnabledKey)
        WidgetCenter.shared.reloadTimelines(ofKind: "NemuAlarmWidget")
    }
}
