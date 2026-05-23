//
//  NemuAnalytics.swift
//  nemu
//
//  Firebase Analytics イベント定義。
//  Analytics.logEvent を直接呼ばず、必ずここを経由する。
//

import FirebaseAnalytics

enum NemuAnalytics {

    // MARK: - Alarm

    /// アラームをセット（時刻・繰り返し設定を記録）
    static func logAlarmSet(hour: Int, minute: Int, hasRepeat: Bool) {
        Analytics.logEvent("alarm_set", parameters: [
            "hour":       hour,
            "minute":     minute,
            "has_repeat": hasRepeat ? "true" : "false"
        ])
    }

    // MARK: - Bedtime

    /// 就寝モード開始
    static func logBedtimeStart(scheduledWakeHour: Int) {
        Analytics.logEvent("bedtime_start", parameters: [
            "scheduled_wake_hour": scheduledWakeHour
        ])
    }

    /// 自然音選択（rain / wave / forest / none）
    static func logSoundSelected(sound: String) {
        Analytics.logEvent("bedtime_sound_selected", parameters: [
            "sound": sound
        ])
    }

    // MARK: - Wake Up

    /// 起床（セッション正常終了）
    static func logWakeUp(durationMinutes: Int, score: Int, snoreCount: Int, motionCount: Int) {
        Analytics.logEvent("wake_up", parameters: [
            "duration_minutes": durationMinutes,
            "score":            score,
            "snore_count":      snoreCount,
            "motion_count":     motionCount
        ])
    }

    /// 就寝キャンセル（記録なし終了）
    static func logBedtimeCancelled(durationMinutes: Int) {
        Analytics.logEvent("bedtime_cancelled", parameters: [
            "duration_minutes": durationMinutes
        ])
    }

    // MARK: - Paywall / Purchase

    /// ペイウォール表示（source: "home" / "bedtime" / "report" 等）
    static func logPaywallView(source: String) {
        Analytics.logEvent("paywall_view", parameters: [
            "source": source
        ])
    }

    /// 購入タップ（plan: "monthly" / "yearly"）
    static func logPurchaseStarted(plan: String) {
        Analytics.logEvent("purchase_started", parameters: [
            "plan": plan
        ])
    }

    /// 購入完了
    static func logPurchaseCompleted(plan: String) {
        Analytics.logEvent("purchase_completed", parameters: [
            "plan": plan
        ])
    }

    /// 購入失敗
    static func logPurchaseFailed(plan: String) {
        Analytics.logEvent("purchase_failed", parameters: [
            "plan": plan
        ])
    }

    /// 購入復元完了
    static func logPurchaseRestored() {
        Analytics.logEvent("purchase_restored", parameters: nil)
    }

    // MARK: - Report

    /// レポート画面を開いた
    static func logReportView() {
        Analytics.logEvent("report_view", parameters: nil)
    }
}
