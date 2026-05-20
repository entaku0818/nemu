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

    // 輝度履歴（直近30件 = 30分分）
    private(set) var brightnessHistory: [(date: Date, value: CGFloat)] = []
    private var baselineBrightness: CGFloat = 0

    // 輝度が就寝時より 0.15 以上上昇していれば「明るくなった」と判断
    var isBrightnessRising: Bool {
        guard brightnessHistory.count >= 3 else { return false }
        let recent = brightnessHistory.suffix(3).map(\.value).reduce(0, +) / 3
        return recent - baselineBrightness >= 0.15
    }

    // 3条件トリガー（日の出前後30分 AND 体動3回以上 AND 輝度上昇）
    var shouldWake: Bool {
        guard isMonitoring, let sunrise = sunriseDate else { return false }
        let now = Date()
        let nearSunrise = abs(now.timeIntervalSince(sunrise)) < 30 * 60
        let effectiveCount = motionTimestamps.isEmpty ? motionEventCount : motionTimestamps.count
        return nearSunrise && effectiveCount > 3 && isBrightnessRising
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
        self.brightnessHistory = []
        self.lastSnoreTime = nil
        self.isMonitoring = true

        let initialBrightness = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first?.screen.brightness ?? 0
        self.baselineBrightness = initialBrightness
        self.currentBrightness = initialBrightness

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
                guard let self else { return }
                let brightness = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }.first?.screen.brightness ?? 0
                self.currentBrightness = brightness
                self.brightnessHistory.append((date: Date(), value: brightness))
                // 直近30件（30分分）だけ保持
                if self.brightnessHistory.count > 30 {
                    self.brightnessHistory.removeFirst()
                }
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
        let sessionStart = bedTime ?? Date()
        let sessionHour = calendar.component(.hour, from: sessionStart)
        // 18時以降の就寝は翌朝の日の出を計算
        let baseDay = calendar.startOfDay(for: sessionStart)
        let today = sessionHour >= 18
            ? calendar.date(byAdding: .day, value: 1, to: baseDay) ?? baseDay
            : baseDay

        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 172

        let declination = 23.45 * sin(Double(dayOfYear - 81) * 360 / 365 * .pi / 180)
        let hourAngle = acos(-tan(latitude * .pi / 180) * tan(declination * .pi / 180)) * 180 / .pi

        let sunriseUTC = 12.0 - longitude / 15.0 - hourAngle / 15.0
        let timezoneOffset = Double(TimeZone.current.secondsFromGMT()) / 3600.0
        let sunriseLocal = sunriseUTC + timezoneOffset

        // 負値・24超えを正規化してから 0...23 / 0...59 にクランプ
        let rawHour = Int(sunriseLocal)
        let hour = min(max(((rawHour % 24) + 24) % 24, 0), 23)
        let minute = min(max(Int((sunriseLocal - Double(rawHour)) * 60), 0), 59)

        if let sunrise = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) {
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
        // 位置情報取得失敗時はスマートアラームを無効化（設定アラーム時刻のみで起床）
        Task { @MainActor in
            self.sunriseDate = nil
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
