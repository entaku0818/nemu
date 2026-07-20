//
//  OnboardingViewModel.swift
//  nemu
//

import Foundation
import Observation
import UserNotifications
import CoreLocation
import AVFoundation
import CoreMotion
import FirebaseAnalytics

/// オンボーディングの権限行が表示すべき状態。
/// システムの許可ダイアログは一度 denied になると再表示されないため、
/// denied の場合はリクエストし直すのではなく設定アプリへ誘導する。
enum PermissionState {
    case notDetermined
    case authorized
    case denied
}

enum OnboardingPage: Int, CaseIterable {
    case welcome = 0
    case motionDetection = 1
    case sunrise = 2
    case permissions = 3
    case wakeTime = 4
    case complete = 5

    var analyticsName: String {
        switch self {
        case .welcome:         return "welcome"
        case .motionDetection: return "motion_detection"
        case .sunrise:         return "sunrise"
        case .permissions:     return "permissions"
        case .wakeTime:        return "wake_time"
        case .complete:        return "complete"
        }
    }
}

@Observable
@MainActor
final class OnboardingViewModel: NSObject {

    var currentPage: OnboardingPage = .welcome
    var wakeTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    var notificationStatus: UNAuthorizationStatus = .notDetermined
    var locationStatus: CLAuthorizationStatus = .notDetermined
    var microphoneStatus: AVAudioApplication.recordPermission = AVAudioApplication.shared.recordPermission
    var motionStatus: CMAuthorizationStatus = CMMotionActivityManager.authorizationStatus()

    private let locationManager = CLLocationManager()
    private let healthKitService = HealthKitService.shared

    // MARK: - 表示用の状態

    var notificationState: PermissionState {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: return .authorized
        case .denied: return .denied
        default: return .notDetermined
        }
    }

    var locationState: PermissionState {
        switch locationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return .authorized
        case .denied, .restricted: return .denied
        default: return .notDetermined
        }
    }

    var microphoneState: PermissionState {
        switch microphoneStatus {
        case .granted: return .authorized
        case .denied: return .denied
        default: return .notDetermined
        }
    }

    var motionState: PermissionState {
        switch motionStatus {
        case .authorized: return .authorized
        case .denied, .restricted: return .denied
        default: return .notDetermined
        }
    }

    var healthKitState: PermissionState {
        switch healthKitService.permissionState {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined, .unavailable: return .notDetermined
        }
    }

    var isHealthKitAvailable: Bool { healthKitService.isAvailable }

    override init() {
        super.init()
        locationManager.delegate = self
    }

    var isLastPage: Bool { currentPage == .complete }

    func nextPage() {
        guard let next = OnboardingPage(rawValue: currentPage.rawValue + 1) else { return }
        currentPage = next
    }

    func skipPermissions() {
        nextPage()
    }

    func trackPageView(_ page: OnboardingPage) {
        Analytics.logEvent("onboarding_page_view", parameters: ["page": page.analyticsName])
    }

    func trackCompleted() {
        Analytics.logEvent("onboarding_completed", parameters: nil)
    }

    // MARK: - 通知権限
    func requestNotification() async {
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        notificationStatus = granted ? .authorized : .denied
        Analytics.logEvent("onboarding_permission_result", parameters: [
            "type": "notification",
            "granted": granted ? "true" : "false"
        ])
    }

    // MARK: - 位置情報権限
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - マイク権限
    func requestMicrophone() async {
        let granted = await AVAudioApplication.requestRecordPermission()
        microphoneStatus = AVAudioApplication.shared.recordPermission
        Analytics.logEvent("onboarding_permission_result", parameters: [
            "type": "microphone",
            "granted": granted ? "true" : "false"
        ])
    }

    // MARK: - モーション権限
    /// CMMotionActivityManager には明示的な requestAuthorization API がなく、
    /// 初回の API 呼び出し時に暗黙的にシステムの許可ダイアログが表示される。
    /// 起床確認時まで放置すると文脈のないタイミングで突然聞かれてしまうため、
    /// オンボーディングの権限説明ページで軽量なクエリを実行して前倒しでリクエストする。
    func requestMotion() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        let manager = CMMotionActivityManager()
        let now = Date()
        manager.queryActivityStarting(from: now.addingTimeInterval(-60), to: now, to: .main) { [weak self] _, _ in
            Task { @MainActor in
                guard let self else { return }
                self.motionStatus = CMMotionActivityManager.authorizationStatus()
                Analytics.logEvent("onboarding_permission_result", parameters: [
                    "type": "motion",
                    "granted": self.motionStatus == .authorized ? "true" : "false"
                ])
            }
        }
    }

    // MARK: - HealthKit権限
    func requestHealthKit() async {
        await healthKitService.requestAuthorization()
        Analytics.logEvent("onboarding_permission_result", parameters: [
            "type": "healthkit",
            "granted": healthKitState == .authorized ? "true" : "false"
        ])
    }
}

extension OnboardingViewModel: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.locationStatus = manager.authorizationStatus
            let granted = manager.authorizationStatus == .authorizedWhenInUse
                       || manager.authorizationStatus == .authorizedAlways
            Analytics.logEvent("onboarding_permission_result", parameters: [
                "type": "location",
                "granted": granted ? "true" : "false"
            ])
        }
    }
}
