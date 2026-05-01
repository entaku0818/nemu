//
//  SleepMonitorService.swift
//  nemu
//
// 就寝中のセンサー監視（CoreMotion + CoreLocation + UIScreen + AVAudioEngine）
//

import Foundation
import CoreMotion
import CoreLocation
import UIKit
import AVFoundation
import Observation

@Observable
@MainActor
final class SleepMonitorService: NSObject {
    static let shared = SleepMonitorService()

    // MARK: - State
    var motionEventCount: Int = 0
    var motionTimestamps: [Date] = []
    var snoreTimestamps: [Date] = []
    var currentBrightness: CGFloat = 0
    var sunriseDate: Date?
    var isMonitoring: Bool = false
    var currentRMS: Float = 0

    // 2条件トリガー（日の出前後30分 AND 体動3回以上）
    var shouldWake: Bool {
        guard isMonitoring, let sunrise = sunriseDate else { return false }
        let now = Date()
        let nearSunrise = abs(now.timeIntervalSince(sunrise)) < 30 * 60
        let effectiveCount = motionTimestamps.isEmpty ? motionEventCount : motionTimestamps.count
        return nearSunrise && effectiveCount > 3
    }

    private let motionManager = CMMotionActivityManager()
    private let locationManager = CLLocationManager()
    private var brightnessTimer: Timer?
    private var bedTime: Date?

    // いびき検知
    private var snoreEngine: AVAudioEngine?
    private var lastSnoreTime: Date?

    private override init() {
        super.init()
        locationManager.delegate = self
    }

    // MARK: - 就寝前の準備

    func prepareForSleep() {
        guard sunriseDate == nil else { return }
        requestLocationForSunrise()
    }

    // MARK: - 開始

    func startMonitoring(bedTime: Date) {
        self.bedTime = bedTime
        self.motionEventCount = 0
        self.motionTimestamps = []
        self.snoreTimestamps = []
        self.lastSnoreTime = nil
        self.isMonitoring = true

        startMotionMonitoring()
        startBrightnessMonitoring()
        startSnoreMonitoring()

        #if DEBUG
        if DebugSettings.shared.timeAcceleration {
            sunriseDate = Date().addingTimeInterval(60)
            return
        }
        #endif

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
        stopSnoreMonitoring()
    }

    // MARK: - CoreMotion

    private func startMotionMonitoring() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        motionManager.startActivityUpdates(to: .main) { [weak self] activity in
            guard let self, let activity else { return }
            Task { @MainActor in
                if activity.walking || activity.running {
                    self.motionEventCount += 1
                    self.motionTimestamps.append(Date())
                }
            }
        }
    }

    // MARK: - 画面輝度監視

    private func startBrightnessMonitoring() {
        brightnessTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.currentBrightness = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }.first?.screen.brightness ?? 0
            }
        }
    }

    // MARK: - いびき検知（AVAudioEngine 入力タップ + RMS）

    private func startSnoreMonitoring() {
        let session = AVAudioSession.sharedInstance()
        guard session.recordPermission == .granted else { return }

        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true)
        } catch { return }

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let rms = Self.calculateRMS(buffer)
            Task { @MainActor in
                self.currentRMS = rms
                // 閾値 0.04 = 室内の中程度の音（いびき目安）
                // 30秒以内の連続検知は同一イベントとしてまとめる
                guard rms > 0.04 else { return }
                let now = Date()
                if let last = self.lastSnoreTime, now.timeIntervalSince(last) < 30 { return }
                self.lastSnoreTime = now
                self.snoreTimestamps.append(now)
            }
        }

        do {
            try engine.start()
            snoreEngine = engine
        } catch {
            inputNode.removeTap(onBus: 0)
            snoreEngine = nil
        }
    }

    private func stopSnoreMonitoring() {
        snoreEngine?.inputNode.removeTap(onBus: 0)
        snoreEngine?.stop()
        snoreEngine = nil
        lastSnoreTime = nil
        currentRMS = 0
    }

    private static func calculateRMS(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let data = buffer.floatChannelData?[0] else { return 0 }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return 0 }
        let sum = (0..<count).reduce(Float(0)) { $0 + data[$1] * data[$1] }
        return sqrt(sum / Float(count))
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

        let declination = 23.45 * sin(Double(dayOfYear - 81) * 360 / 365 * .pi / 180)
        let hourAngle = acos(-tan(latitude * .pi / 180) * tan(declination * .pi / 180)) * 180 / .pi

        let sunriseUTC = 12.0 - longitude / 15.0 - hourAngle / 15.0
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
