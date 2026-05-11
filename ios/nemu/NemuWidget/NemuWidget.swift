//
//  NemuWidget.swift
//  NemuWidget
//

import WidgetKit
import SwiftUI

// MARK: - App Group 共有キー

private let appGroupID = "group.com.entaku.slumber"
private let nextAlarmKey = "nextAlarmTimeInterval"
private let nextAlarmEnabledKey = "nextAlarmEnabled"

// MARK: - Timeline Entry

struct AlarmEntry: TimelineEntry {
    let date: Date
    let nextAlarmDate: Date?
    let isEnabled: Bool
}

// MARK: - Provider

struct AlarmProvider: TimelineProvider {
    func placeholder(in context: Context) -> AlarmEntry {
        AlarmEntry(date: Date(), nextAlarmDate: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()), isEnabled: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (AlarmEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AlarmEntry>) -> Void) {
        let current = entry()
        // 次のアラーム時刻の翌分に再取得
        let reload = current.nextAlarmDate.map { Calendar.current.date(byAdding: .minute, value: 1, to: $0) ?? Date() } ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [current], policy: .after(reload)))
    }

    private func entry() -> AlarmEntry {
        let defaults = UserDefaults(suiteName: appGroupID)
        let interval = defaults?.double(forKey: nextAlarmKey) ?? 0
        let enabled = defaults?.bool(forKey: nextAlarmEnabledKey) ?? false
        let alarmDate = interval > 0 ? Date(timeIntervalSince1970: interval) : nil
        return AlarmEntry(date: Date(), nextAlarmDate: alarmDate, isEnabled: enabled)
    }
}

// MARK: - Views

struct AlarmWidgetInlineView: View {
    let entry: AlarmEntry

    var body: some View {
        if let alarm = entry.nextAlarmDate, entry.isEnabled {
            Label {
                Text(alarm, style: .time)
            } icon: {
                Image(systemName: "alarm.fill")
            }
            .widgetAccentable()
        } else {
            Text("アラームなし")
        }
    }
}

struct AlarmWidgetRectangularView: View {
    let entry: AlarmEntry

    var body: some View {
        if let alarm = entry.nextAlarmDate, entry.isEnabled {
            VStack(alignment: .leading, spacing: 2) {
                Label("次のアラーム", systemImage: "alarm.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .widgetAccentable()
                Text(alarm, style: .time)
                    .font(.title3.bold())
            }
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Label("Nemu", systemImage: "moon.stars.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("アラームなし")
                    .font(.subheadline)
            }
        }
    }
}

struct AlarmWidgetCircularView: View {
    let entry: AlarmEntry

    var body: some View {
        ZStack {
            if let alarm = entry.nextAlarmDate, entry.isEnabled {
                VStack(spacing: 0) {
                    Image(systemName: "alarm.fill")
                        .font(.caption2)
                        .widgetAccentable()
                    Text(alarm, style: .time)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.7)
                }
            } else {
                Image(systemName: "moon.stars.fill")
                    .font(.title3)
            }
        }
    }
}

// MARK: - Widget

struct NemuAlarmWidget: Widget {
    let kind = "NemuAlarmWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AlarmProvider()) { entry in
            AlarmWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("次のアラーム")
        .description("次に鳴るアラームの時刻を表示します。")
        .supportedFamilies([
            .accessoryInline,
            .accessoryRectangular,
            .accessoryCircular
        ])
    }
}

struct AlarmWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: AlarmEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            AlarmWidgetInlineView(entry: entry)
        case .accessoryCircular:
            AlarmWidgetCircularView(entry: entry)
        default:
            AlarmWidgetRectangularView(entry: entry)
        }
    }
}

// MARK: - Preview

#Preview(as: .accessoryRectangular) {
    NemuAlarmWidget()
} timeline: {
    AlarmEntry(
        date: .now,
        nextAlarmDate: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()),
        isEnabled: true
    )
}
