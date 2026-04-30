//
//  OnboardingViewModel.swift
//  nemu
//

import Foundation
import Observation
import UserNotifications
import CoreLocation
import AVFoundation
import FirebaseAnalytics

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
    var microphoneGranted: Bool = false

    private let locationManager = CLLocationManager()

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
        microphoneGranted = granted
        Analytics.logEvent("onboarding_permission_result", parameters: [
            "type": "microphone",
            "granted": granted ? "true" : "false"
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
