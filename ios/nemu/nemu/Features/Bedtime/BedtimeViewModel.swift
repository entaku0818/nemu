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

    // MARK: - メモ
    var memo: String = ""

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
        guard sound != .none else { return }
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
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
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
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - 画面減光
    private var originalBrightness: CGFloat = UIScreen.main.brightness

    func dimScreen() {
        originalBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = 0.02
    }

    func restoreScreen() {
        UIScreen.main.brightness = originalBrightness
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
        let session = SleepSession(bedTime: now)
        modelContext.insert(session)
        do {
            try modelContext.save()
        } catch {
            dbError = "セッションの開始に失敗しました: \(error.localizedDescription)"
            return
        }
        self.currentSession = session
        SleepMonitorService.shared.startMonitoring(bedTime: now)
    }

    func endSession() {
        guard let session = currentSession, let context = modelContext else { return }
        currentSession = nil
        stopAudio()

        let bedTime = sessionBedTime ?? session.bedTime
        let wakeTime = Date()
        session.wakeTime = wakeTime

        // CoreMotion 過去データを照会してモーションイベントをカウント
        // （バックグラウンド中も蓄積されたデータを確実に取得）
        if CMMotionActivityManager.isActivityAvailable() {
            let mgr = CMMotionActivityManager()
            mgr.queryActivityStarting(from: bedTime, to: wakeTime, to: .main) { [weak self] activities, _ in
                guard let self else { return }
                // stationary 以外（明確な動き）をカウント
                let count = activities?.filter {
                    !$0.stationary && ($0.walking || $0.running || $0.cycling || $0.automotive)
                }.count ?? 0
                session.motionEventCount = count
                session.calculateScore()
                self.lastScore = session.score
                self.lastDuration = session.duration
                do {
                    try context.save()
                } catch {
                    self.dbError = "睡眠データの保存に失敗しました: \(error.localizedDescription)"
                }
                SleepMonitorService.shared.stopMonitoring()
                NotificationCenter.default.post(
                    name: .didWakeUp,
                    object: nil,
                    userInfo: ["score": self.lastScore, "duration": self.lastDuration]
                )
            }
        } else {
            // CoreMotion 非対応デバイスはフォールバック
            session.motionEventCount = SleepMonitorService.shared.motionEventCount
            session.calculateScore()
            lastScore = session.score
            lastDuration = session.duration
            try? context.save()
            SleepMonitorService.shared.stopMonitoring()
            NotificationCenter.default.post(
                name: .didWakeUp,
                object: nil,
                userInfo: ["score": lastScore, "duration": lastDuration]
            )
        }
    }

    // MARK: - プレミアム状態
    var isUnlocked: Bool { PurchaseService.shared.isPremium }

    // MARK: - 終了

    func finish() {
        guard !isFinished else { return }
        isFinished = true
        restoreScreen()
        endSession()
        // 通知は endSession() 内の非同期処理後に投稿される
    }

    /// 記録を保存せずにセッションを破棄する（緊急終了用）
    func cancelSession() {
        guard !isFinished else { return }
        isFinished = true
        stopAudio()
        restoreScreen()
        if let session = currentSession, let context = modelContext {
            currentSession = nil
            context.delete(session)
            try? context.save()
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
