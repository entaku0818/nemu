//
//  OnboardingViewModel.swift
//  nemu
//

import Foundation
import Observation
import UserNotifications
import CoreLocation

@Observable
@MainActor
final class OnboardingViewModel: NSObject {

    var currentPage: Int = 0
    var wakeTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()

    var notificationStatus: UNAuthorizationStatus = .notDetermined
    var locationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
    }

    var isLastPage: Bool { currentPage == 2 }

    func nextPage() {
        guard currentPage < 2 else { return }
        currentPage += 1
    }

    // MARK: - 通知権限
    func requestNotification() async {
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        notificationStatus = granted ? .authorized : .denied
    }

    // MARK: - 位置情報権限
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
    }
}

extension OnboardingViewModel: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.locationStatus = manager.authorizationStatus
        }
    }
}
