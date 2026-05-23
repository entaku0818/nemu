//
//  NemuAnalyticsClient.swift
//  nemu
//
//  Analytics の依存性クライアント。
//  ・live  — Firebase Analytics に送信（本番）
//  ・noop  — 何もしない（テスト・Preview 用）
//
//  使い方:
//    // ViewModel やサービスに注入
//    var analytics: NemuAnalyticsClient = .live
//
//    // テストでは差し替え
//    sut.analytics = .noop
//

import FirebaseAnalytics
import SwiftUI

// MARK: - SwiftUI EnvironmentKey

private struct AnalyticsClientKey: EnvironmentKey {
    static let defaultValue: NemuAnalyticsClient = .live
}

extension EnvironmentValues {
    var analyticsClient: NemuAnalyticsClient {
        get { self[AnalyticsClientKey.self] }
        set { self[AnalyticsClientKey.self] = newValue }
    }
}

// MARK: - Client

struct NemuAnalyticsClient {

    var logAlarmSet:           (_ hour: Int, _ minute: Int, _ hasRepeat: Bool) -> Void
    var logBedtimeStart:       (_ scheduledWakeHour: Int) -> Void
    var logSoundSelected:      (_ sound: String) -> Void
    var logWakeUp:             (_ durationMinutes: Int, _ score: Int, _ snoreCount: Int, _ motionCount: Int) -> Void
    var logBedtimeCancelled:   (_ durationMinutes: Int) -> Void
    var logPaywallView:        (_ source: String) -> Void
    var logPurchaseStarted:    (_ plan: String) -> Void
    var logPurchaseCompleted:  (_ plan: String) -> Void
    var logPurchaseFailed:     (_ plan: String) -> Void
    var logPurchaseRestored:   () -> Void
    var logReportView:         () -> Void
}

// MARK: - Live (Firebase Analytics)

extension NemuAnalyticsClient {
    static let live = NemuAnalyticsClient(
        logAlarmSet: { hour, minute, hasRepeat in
            Analytics.logEvent("alarm_set", parameters: [
                "hour":       hour,
                "minute":     minute,
                "has_repeat": hasRepeat ? "true" : "false"
            ])
        },
        logBedtimeStart: { wakeHour in
            Analytics.logEvent("bedtime_start", parameters: [
                "scheduled_wake_hour": wakeHour
            ])
        },
        logSoundSelected: { sound in
            Analytics.logEvent("bedtime_sound_selected", parameters: [
                "sound": sound
            ])
        },
        logWakeUp: { durationMinutes, score, snoreCount, motionCount in
            Analytics.logEvent("wake_up", parameters: [
                "duration_minutes": durationMinutes,
                "score":            score,
                "snore_count":      snoreCount,
                "motion_count":     motionCount
            ])
        },
        logBedtimeCancelled: { durationMinutes in
            Analytics.logEvent("bedtime_cancelled", parameters: [
                "duration_minutes": durationMinutes
            ])
        },
        logPaywallView: { source in
            Analytics.logEvent("paywall_view", parameters: [
                "source": source
            ])
        },
        logPurchaseStarted: { plan in
            Analytics.logEvent("purchase_started", parameters: ["plan": plan])
        },
        logPurchaseCompleted: { plan in
            Analytics.logEvent("purchase_completed", parameters: ["plan": plan])
        },
        logPurchaseFailed: { plan in
            Analytics.logEvent("purchase_failed", parameters: ["plan": plan])
        },
        logPurchaseRestored: {
            Analytics.logEvent("purchase_restored", parameters: nil)
        },
        logReportView: {
            Analytics.logEvent("report_view", parameters: nil)
        }
    )
}

// MARK: - Noop (テスト・Preview 用)

extension NemuAnalyticsClient {
    static let noop = NemuAnalyticsClient(
        logAlarmSet:          { _, _, _ in },
        logBedtimeStart:      { _ in },
        logSoundSelected:     { _ in },
        logWakeUp:            { _, _, _, _ in },
        logBedtimeCancelled:  { _ in },
        logPaywallView:       { _ in },
        logPurchaseStarted:   { _ in },
        logPurchaseCompleted: { _ in },
        logPurchaseFailed:    { _ in },
        logPurchaseRestored:  {},
        logReportView:        {}
    )
}
