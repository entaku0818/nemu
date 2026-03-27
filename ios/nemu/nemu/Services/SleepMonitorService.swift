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

    // 2条件トリガー（日の出前後30分 AND 体動3回以上）
    // NOTE: brightening（画面輝度）はロック画面中に取得不可のため条件から除外。
    // currentBrightness は将来的に LightSensor API が利用可能になった際に再追加を検討。
    var shouldWake: Bool {
        guard isMonitoring, let sunrise = sunriseDate else { return false }
        let now = Date()
        let nearSunrise = abs(now.timeIntervalSince(sunrise)) < 30 * 60
        let movingMore = motionEventCount > 3
        return nearSunrise && movingMore
    }

    private let motionManager = CMMotionActivityManager()
    private let locationManager = CLLocationManager()
    private var brightnessTimer: Timer?
    private var bedTime: Date?

    private override init() {
        super.init()
        locationManager.delegate = self
    }

    // MARK: - 就寝前の準備（HomeViewのonAppearから呼ぶ）

    /// 就寝モード開始前に位置情報を先行取得する。
    /// BedtimeView表示前にフォアグラウンドで呼ぶことで、
    /// WhenInUse権限のまま確実に日の出時刻を取得できる。
    func prepareForSleep() {
        guard sunriseDate == nil else { return }
        requestLocationForSunrise()
    }

    // MARK: - 開始

    func startMonitoring(bedTime: Date) {
        self.bedTime = bedTime
        self.motionEventCount = 0
        self.isMonitoring = true

        startMotionMonitoring()
        startBrightnessMonitoring()
        // prepareForSleep()で取得済みの場合は再取得しない
        if sunriseDate == nil {
            requestLocationForSunrise()
        }
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
                // 明確な動き（walking/running）のみカウント。
                // unknown は静止中でも発生するため除外し、誤カウントを防ぐ。
                if activity.walking || activity.running {
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
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 172

        // 太陽赤緯（度）
        let declination = 23.45 * sin(Double(dayOfYear - 81) * 360 / 365 * .pi / 180)
        // 時角（度）: 地平線での太陽角度から計算
        let hourAngle = acos(-tan(latitude * .pi / 180) * tan(declination * .pi / 180)) * 180 / .pi

        // UTC基準の日の出時刻 = 正午UTC - 経度補正 - 時角
        let sunriseUTC = 12.0 - longitude / 15.0 - hourAngle / 15.0
        // デバイスのタイムゾーンオフセットを加算してローカル時刻へ変換
        let timezoneOffset = Double(TimeZone.current.secondsFromGMT()) / 3600.0
        let sunriseLocal = sunriseUTC + timezoneOffset

        let hour = Int(sunriseLocal) % 24
        let minute = Int((sunriseLocal - Double(Int(sunriseLocal))) * 60)

        if let sunrise = calendar.date(bySettingHour: max(0, hour),
                                        minute: max(0, minute),
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
