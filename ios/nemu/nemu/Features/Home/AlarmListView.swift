//
//  AlarmListView.swift
//  nemu
//

import SwiftUI
import SwiftData

struct AlarmListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\AlarmSetting.wakeTime)]) private var alarms: [AlarmSetting]
    @State private var showAddSheet = false
    @State private var isEditing = false

    private let dayLabels = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // ヘッダー
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Spacer()

                    Text("アラーム")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Spacer()

                    HStack(spacing: 16) {
                        if alarms.count > 1 {
                            Button(isEditing ? "完了" : "編集") {
                                isEditing.toggle()
                            }
                            .foregroundStyle(.indigo)
                        }
                        Button {
                            showAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title3)
                                .foregroundStyle(.indigo)
                        }
                    }
                }
                .padding()

                if alarms.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "alarm")
                            .font(.system(size: 48))
                            .foregroundStyle(.white.opacity(0.2))
                        Text("アラームがありません")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.3))
                        Button {
                            showAddSheet = true
                        } label: {
                            Text("追加する")
                                .font(.subheadline.bold())
                                .foregroundStyle(.indigo)
                        }
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(alarms) { alarm in
                                HStack(spacing: 12) {
                                    if isEditing && alarms.count > 1 {
                                        Button {
                                            Task {
                                                if let idStr = alarm.scheduledAlarmIDString,
                                                   let id = UUID(uuidString: idStr) {
                                                    await AlarmService.shared.cancelAlarm(id: id)
                                                }
                                                modelContext.delete(alarm)
                                                try? modelContext.save()
                                            }
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundStyle(.red)
                                                .font(.title3)
                                        }
                                        .transition(.move(edge: .leading).combined(with: .opacity))
                                    }
                                    AlarmRow(alarm: alarm, dayLabels: dayLabels, canDelete: alarms.count > 1)
                                }
                                .animation(.easeInOut, value: isEditing)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddAlarmSheet()
        }
    }
}

// MARK: - 1行

private struct AlarmRow: View {
    @Bindable var alarm: AlarmSetting
    let dayLabels: [String]
    var canDelete: Bool = true

    var body: some View {
        HStack(spacing: 16) {
            // 時刻
            VStack(alignment: .leading, spacing: 4) {
                Text(timeString(from: alarm.wakeTime))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(alarm.isEnabled ? .white : .white.opacity(0.3))

                // 繰り返し曜日
                HStack(spacing: 4) {
                    if alarm.repeatDays.isEmpty {
                        Text("1回のみ")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.35))
                    } else {
                        ForEach(0..<7, id: \.self) { day in
                            Text(dayLabels[day])
                                .font(.caption2.bold())
                                .foregroundStyle(
                                    alarm.repeatDays.contains(day)
                                    ? (alarm.isEnabled ? .indigo : .white.opacity(0.3))
                                    : .white.opacity(0.15)
                                )
                        }
                    }
                }
            }

            Spacer()

            // ON/OFF
            Toggle("", isOn: $alarm.isEnabled)
                .tint(.indigo)
                .onChange(of: alarm.isEnabled) {
                    Task {
                        if alarm.isEnabled {
                            let existingID = alarm.scheduledAlarmIDString.flatMap { UUID(uuidString: $0) }
                            let newID = await AlarmService.shared.scheduleAlarm(
                                at: alarm.wakeTime,
                                repeatDays: Set(alarm.repeatDays),
                                existingID: existingID
                            )
                            alarm.scheduledAlarmIDString = newID?.uuidString
                        } else {
                            if let idStr = alarm.scheduledAlarmIDString,
                               let id = UUID(uuidString: idStr) {
                                await AlarmService.shared.cancelAlarm(id: id)
                                alarm.scheduledAlarmIDString = nil
                            }
                        }
                        try? alarm.modelContext?.save()
                    }
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.07))
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if canDelete {
                Button(role: .destructive) {
                    Task {
                        if let idStr = alarm.scheduledAlarmIDString,
                           let id = UUID(uuidString: idStr) {
                            await AlarmService.shared.cancelAlarm(id: id)
                        }
                        alarm.modelContext?.delete(alarm)
                        try? alarm.modelContext?.save()
                    }
                } label: {
                    Label("削除", systemImage: "trash")
                }
            }
        }
    }

    private func timeString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}

// MARK: - 追加シート

private struct AddAlarmSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var wakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var repeatDays: Set<Int> = [1, 2, 3, 4, 5]

    private let dayLabels = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Text("アラームを追加")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button("追加") { addAlarm() }
                        .font(.headline)
                        .foregroundStyle(.indigo)
                }
                .padding()

                DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)

                // 繰り返し曜日
                VStack(spacing: 12) {
                    Text("繰り返し")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(1.5)

                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { day in
                            Button {
                                if repeatDays.contains(day) {
                                    repeatDays.remove(day)
                                } else {
                                    repeatDays.insert(day)
                                }
                            } label: {
                                Text(dayLabels[day])
                                    .font(.caption.bold())
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(repeatDays.contains(day)
                                                  ? Color.indigo
                                                  : Color.white.opacity(0.1))
                                    )
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func addAlarm() {
        let setting = AlarmSetting(wakeTime: wakeTime, isEnabled: true, repeatDays: Array(repeatDays))
        modelContext.insert(setting)
        Task {
            let id = await AlarmService.shared.scheduleAlarm(
                at: wakeTime,
                repeatDays: repeatDays,
                existingID: nil
            )
            setting.scheduledAlarmIDString = id?.uuidString
            try? modelContext.save()
        }
        dismiss()
    }
}

#Preview {
    AlarmListView()
        .modelContainer(for: [AlarmSetting.self], inMemory: true)
}
