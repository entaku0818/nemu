//
//  SettingsView.swift
//  nemu
//

import SwiftUI
import UserNotifications
import CoreLocation
import AVFoundation

struct SettingsView: View {
    @State private var notificationGranted = false
    @State private var locationGranted = false
    @State private var microphoneGranted = false
    @State private var showPaywall = false
    @State private var purchaseService = PurchaseService.shared

    // 就寝リマインダー
    @AppStorage("bedtimeReminderEnabled") private var reminderEnabled = false
    @AppStorage("bedtimeReminderHour") private var reminderHour = 22
    @AppStorage("bedtimeReminderMinute") private var reminderMinute = 30
    @State private var showReminderTimePicker = false

    private var reminderTime: Date {
        Calendar.current.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: Date()) ?? Date()
    }

    private var reminderTimeText: String {
        String(format: "%02d:%02d", reminderHour, reminderMinute)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー
                    HStack {
                        Text("設定")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // プレミアム
                    SettingsSection(title: "プレミアム") {
                        if purchaseService.isPremium {
                            SettingsRow(
                                icon: "crown.fill",
                                iconColor: Color.assetGold,
                                title: "プレミアム会員"
                            ) {
                                Text("有効")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.assetGold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.assetGold.opacity(0.15)))
                            }
                        } else {
                            Button {
                                showPaywall = true
                            } label: {
                                SettingsRow(
                                    icon: "crown.fill",
                                    iconColor: Color.assetGold,
                                    title: "プレミアムにアップグレード"
                                ) {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                            }
                        }
                    }

                    // 就寝リマインダー
                    SettingsSection(title: "就寝リマインダー") {
                        SettingsRow(icon: "bell.fill", iconColor: .indigo, title: "リマインダー") {
                            Toggle("", isOn: $reminderEnabled)
                                .tint(.indigo)
                                .onChange(of: reminderEnabled) { scheduleReminder() }
                        }

                        if reminderEnabled {
                            Divider().background(Color.white.opacity(0.08)).padding(.leading, 56)
                            Button {
                                showReminderTimePicker = true
                            } label: {
                                SettingsRow(icon: "clock.fill", iconColor: .indigo.opacity(0.6), title: "通知時刻") {
                                    Text(reminderTimeText)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                            }
                        }
                    }

                    // 権限
                    SettingsSection(title: "権限") {
                        PermissionSettingsRow(
                            icon: "bell.badge.fill",
                            title: "通知",
                            granted: notificationGranted
                        )
                        Divider().background(Color.white.opacity(0.08)).padding(.leading, 56)
                        PermissionSettingsRow(
                            icon: "location.fill",
                            title: "位置情報",
                            granted: locationGranted
                        )
                        Divider().background(Color.white.opacity(0.08)).padding(.leading, 56)
                        PermissionSettingsRow(
                            icon: "mic.fill",
                            title: "マイク",
                            granted: microphoneGranted
                        )
                    }

                    // アプリ情報
                    SettingsSection(title: "アプリ情報") {
                        SettingsRow(
                            icon: "info.circle.fill",
                            iconColor: .indigo,
                            title: "バージョン"
                        ) {
                            Text(appVersion)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.4))
                        }

                        #if DEBUG
                        Divider().background(Color.white.opacity(0.08)).padding(.leading, 56)
                        Button {
                            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                        } label: {
                            SettingsRow(
                                icon: "arrow.counterclockwise",
                                iconColor: .orange,
                                title: "オンボーディングをリセット"
                            ) {
                                EmptyView()
                            }
                        }
                        #endif
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .onAppear { checkPermissions() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkPermissions()
        }
        .sheet(isPresented: $showReminderTimePicker) {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("完了") {
                        showReminderTimePicker = false
                        scheduleReminder()
                    }
                    .foregroundStyle(.indigo)
                    .font(.headline)
                    .padding()
                }
                DatePicker("", selection: Binding(
                    get: { reminderTime },
                    set: { date in
                        let c = Calendar.current
                        reminderHour = c.component(.hour, from: date)
                        reminderMinute = c.component(.minute, from: date)
                    }
                ), displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                Spacer()
            }
            .background(Color.appBackground)
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private func scheduleReminder() {
        Task {
            await BedtimeReminderService.shared.schedule(at: reminderTime, enabled: reminderEnabled)
        }
    }

    private func checkPermissions() {
        // 通知
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                notificationGranted = settings.authorizationStatus == .authorized
            }
        }
        // 位置情報
        let locStatus = CLLocationManager().authorizationStatus
        locationGranted = locStatus == .authorizedWhenInUse || locStatus == .authorizedAlways
        // マイク
        microphoneGranted = AVAudioSession.sharedInstance().recordPermission == .granted
    }
}

// MARK: - セクション

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
                .tracking(1.5)
                .padding(.horizontal)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.07))
            )
            .padding(.horizontal)
        }
    }
}

// MARK: - 汎用行

private struct SettingsRow<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(iconColor)
                .frame(width: 28)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white)

            Spacer()

            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - 権限行（設定アプリへ遷移）

private struct PermissionSettingsRow: View {
    let icon: String
    let title: String
    let granted: Bool

    var body: some View {
        Button {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            SettingsRow(icon: icon, iconColor: granted ? .indigo : .white.opacity(0.3), title: title) {
                HStack(spacing: 6) {
                    Text(granted ? "許可済み" : "未許可")
                        .font(.caption)
                        .foregroundStyle(granted ? .white.opacity(0.5) : .orange.opacity(0.8))
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
