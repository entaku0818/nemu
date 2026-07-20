//
//  BedtimeViewModel.swift
//  nemu
//

import Foundation
import Observation
import AVFoundation
import UIKit
import SwiftData
import CoreMotion

@Observable
@MainActor
final class BedtimeViewModel {

    // MARK: - DBエラー
    var dbError: String?

    // MARK: - 自然音
    enum SoundType: String, CaseIterable, Identifiable {
        case rain = "雨"
        case wave = "波"
        case forest = "森"
        case none = "なし"

        var id: String { rawValue }

        /// 雨は無料体験用、波・森はプレミアム限定
        var isPremium: Bool {
            switch self {
            case .none, .rain: return false
            case .wave, .forest: return true
            }
        }

        var systemImage: String {
            switch self {
            case .rain:   return "cloud.rain.fill"
            case .wave:   return "water.waves"
            case .forest: return "tree.fill"
            case .none:   return "speaker.slash.fill"
            }
        }
    }

    var selectedSound: SoundType = .none

    // MARK: - AVAudioEngine（プログラム生成音）

    private var audioEngine: AVAudioEngine?

    func selectSound(_ sound: SoundType) {
        selectedSound = sound
        stopAudio()
        analytics.logSoundSelected(sound.rawValue)
        playGeneratedSound(sound)
    }

    private func playGeneratedSound(_ type: SoundType) {
        let engine = AVAudioEngine()
        let sampleRate = 44100.0
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }

        // AVAudioSourceNode でリアルタイム生成
        var brownPrev: Float = 0
        var lfoPhase: Double = 0

        let srcNode = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let channelData = ablPointer.first?.mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }
            for i in 0..<Int(frameCount) {
                let white = Float.random(in: -1...1)
                var sample: Float = 0

                switch type {
                case .rain:
                    // ホワイトノイズをソフトに（雨音近似）
                    sample = white * 0.25

                case .wave:
                    // ブラウンノイズ + 低周波LFOで波のうねり
                    brownPrev = (brownPrev + white * 0.02).clamped(to: -1...1)
                    lfoPhase += 0.08 / sampleRate
                    let lfo = Float(sin(2 * .pi * lfoPhase)) * 0.5 + 0.5
                    sample = brownPrev * lfo * 0.5

                case .forest:
                    // ブラウンノイズ（低周波強め、穏やかな自然音）
                    brownPrev = (brownPrev + white * 0.01).clamped(to: -1...1)
                    sample = brownPrev * 0.4

                case .none:
                    sample = 0
                }
                channelData[i] = sample
            }
            return noErr
        }

        engine.attach(srcNode)
        engine.connect(srcNode, to: engine.mainMixerNode, format: format)

        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            audioEngine = engine
        } catch {
            audioEngine = nil
        }
    }

    private func stopAudio() {
        audioEngine?.stop()
        audioEngine = nil
    }

    private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - 画面減光
    private var originalBrightness: CGFloat = 0.5

    func dimScreen() {
        let screen = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first?.screen
        originalBrightness = screen?.brightness ?? 0.5
        screen?.brightness = 0.02
    }

    func restoreScreen() {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first?.screen.brightness = originalBrightness
    }

    // MARK: - SleepSession記録

    private var modelContext: ModelContext?
    private var currentSession: SleepSession?
    private var isFinished = false
    private var sessionBedTime: Date?

    /// finish()後に参照できる直近セッション結果
    private(set) var lastScore: Int = 0
    private(set) var lastDuration: TimeInterval = 0

    func startSession(modelContext: ModelContext, wakeTime: Date? = nil) {
        self.modelContext = modelContext
        let now = Date()
        sessionBedTime = now
        let session = SleepSession(bedTime: now, scheduledWakeTime: wakeTime)
        modelContext.insert(session)
        do {
            try modelContext.save()
        } catch {
            dbError = "セッションの開始に失敗しました。もう一度お試しください。"
            return
        }
        self.currentSession = session
        SleepSessionFinalizer.markActive(bedTime: now)
        SleepMonitorService.shared.startMonitoring(bedTime: now)
        Task { await BedtimeReminderService.shared.scheduleWakeCheck(after: wakeTime) }
        // audio バックグラウンドモードを有効化するため、常にエンジンを起動する
        // .none 選択時は無音（振幅0）で audio セッションを維持し、iOS にアプリを生かし続けてもらう
        playGeneratedSound(selectedSound)
    }

    func endSession() {
        guard let session = currentSession, let context = modelContext else { return }
        currentSession = nil
        stopAudio()
        deactivateAudioSession()

        let bedTime = sessionBedTime ?? session.bedTime
        let wakeTime = Date()

        #if DEBUG
        if DebugSettings.shared.timeAcceleration {
            let actualDuration = wakeTime.timeIntervalSince(bedTime)
            let fakeBedTime = wakeTime.addingTimeInterval(-actualDuration * 60)
            session.bedTime = fakeBedTime
            session.motionTimestamps = session.motionTimestamps.map { ts in
                fakeBedTime.addingTimeInterval(ts.timeIntervalSince(bedTime) * 60)
            }
            session.snoreTimestamps = session.snoreTimestamps.map { ts in
                fakeBedTime.addingTimeInterval(ts.timeIntervalSince(bedTime) * 60)
            }
        }
        #endif

        let snoreTimestamps = SleepMonitorService.shared.snoreTimestamps
        SleepMonitorService.shared.stopMonitoring()

        Task {
            let result = await SleepSessionFinalizer.finalize(
                session,
                wakeTime: wakeTime,
                snoreTimestamps: snoreTimestamps,
                context: context
            )
            switch result {
            case .saved(let score, let duration):
                lastScore = score
                lastDuration = duration
                analytics.logWakeUp(Int(duration / 60), score, session.snoreTimestamps.count, session.motionEventCount)
                await HealthKitService.shared.saveSleepSession(bedTime: session.bedTime, wakeTime: wakeTime)
                // 破棄されたセッション（30分未満）では通知しない。記録もされていないのに
                // 「記録されました」バナーやスコア画面が出てしまう不整合を防ぐため。
                NotificationCenter.default.post(
                    name: .didWakeUp,
                    object: nil,
                    userInfo: ["score": lastScore, "duration": lastDuration]
                )
            case .discarded:
                break
            }
        }
    }

    // MARK: - Analytics
    var analytics: NemuAnalyticsClient = .live

    // MARK: - プレミアム状態
    var isUnlocked: Bool { PurchaseService.shared.isPremium }

    // MARK: - 終了

    func finish() {
        guard !isFinished else { return }
        isFinished = true
        restoreScreen()
        BedtimeReminderService.shared.cancelWakeCheck()
        endSession()
        Task {
            await cancelAllAlarms()
        }
    }

    private func cancelAllAlarms() async {
        guard let context = modelContext else {
            await AlarmService.shared.cancelAlarm()
            return
        }
        let alarms = (try? context.fetch(FetchDescriptor<AlarmSetting>())) ?? []
        for alarm in alarms {
            if let idStr = alarm.scheduledAlarmIDString, let id = UUID(uuidString: idStr) {
                await AlarmService.shared.cancelAlarm(id: id)
            }
        }
        await AlarmService.shared.cancelAlarm()
    }

    /// 記録を保存せずにセッションを破棄する（緊急終了用）
    func cancelSession() {
        guard !isFinished else { return }
        isFinished = true
        stopAudio()
        deactivateAudioSession()
        restoreScreen()
        BedtimeReminderService.shared.cancelWakeCheck()
        if let session = currentSession, let context = modelContext {
            let durationMinutes = Int(Date().timeIntervalSince(session.bedTime) / 60)
            analytics.logBedtimeCancelled(durationMinutes)
            currentSession = nil
            SleepSessionFinalizer.discard(session, context: context)
        } else {
            SleepSessionFinalizer.clearActive()
        }
        SleepMonitorService.shared.stopMonitoring()
    }
}

// MARK: - Comparable helper for clamping
private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
