//
//  SleepMonitorService.swift
//  nemu
//
// 就寝中のセンサー監視（CoreMotion + CoreLocation + UIScreen）
//

import Foundation
import CoreMotion
import CoreLocation
import UIKit
import Observation

@Observable
@MainActor
final class SleepMonitorService: NSObject {
    static let shared = SleepMonitorService()

    // MARK: - State
    var motionEventCount: Int = 0
    var currentBrightness: CGFloat = 0
    var sunriseDate: Date?
    var isMonitoring: Bool = false

    // 3条件トリガー
    var shouldWake: Bool {
        guard isMonitoring, let sunrise = sunriseDate else { return false }
        let now = Date()
        let nearSunrise = abs(now.timeIntervalSince(sunrise)) < 30 * 60
        let movingMore = motionEventCount > 3
        let brightening = currentBrightness > 0.15
        return nearSunrise && movingMore && brightening
    }

    private let motionManager = CMMotionActivityManager()
    private let locationManager = CLLocationManager()
    private var brightnessTimer: Timer?
    private var bedTime: Date?

    private override init() {
        super.init()
        locationManager.delegate = self
    }

    // MARK: - 開始

    func startMonitoring(bedTime: Date) {
        self.bedTime = bedTime
        self.motionEventCount = 0
        self.isMonitoring = true

        startMotionMonitoring()
        startBrightnessMonitoring()
        requestLocationForSunrise()
    }

    // MARK: - 停止

    func stopMonitoring() {
        isMonitoring = false
        motionManager.stopActivityUpdates()
        brightnessTimer?.invalidate()
        brightnessTimer = nil
        locationManager.stopUpdatingLocation()
    }

    // MARK: - CoreMotion

    private func startMotionMonitoring() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }

        motionManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self, let activity else { return }
            Task { @MainActor in
                // 静止→動きに変わったらカウント
                if activity.walking || activity.running || activity.unknown {
                    self.motionEventCount += 1
                }
            }
        }
    }

    // MARK: - 画面輝度監視（朝の光の代替）

    private func startBrightnessMonitoring() {
        brightnessTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.currentBrightness = UIScreen.main.brightness
            }
        }
    }

    // MARK: - CoreLocation（日の出時刻）

    private func requestLocationForSunrise() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    private func calculateSunrise(for location: CLLocation) {
        // 今日の日の出時刻を計算（Solar noon approximation）
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // 簡易計算: 緯度から日の出時刻を近似
        let latitude = location.coordinate.latitude
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 172
        let declination = 23.45 * sin(Double(dayOfYear - 81) * 360 / 365 * .pi / 180)
        let hourAngle = acos(-tan(latitude * .pi / 180) * tan(declination * .pi / 180)) * 180 / .pi
        let sunriseHour = 12.0 - hourAngle / 15.0

        if let sunrise = calendar.date(bySettingHour: Int(sunriseHour),
                                        minute: Int((sunriseHour.truncatingRemainder(dividingBy: 1)) * 60),
                                        second: 0, of: today) {
            self.sunriseDate = sunrise
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension SleepMonitorService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        Task { @MainActor in
            self.calculateSunrise(for: location)
            manager.stopUpdatingLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 位置情報が取得できない場合はデフォルト（6:00）を使用
        Task { @MainActor in
            let calendar = Calendar.current
            self.sunriseDate = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: Date())
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }
}
