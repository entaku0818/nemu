//
//  BedtimeViewModel.swift
//  nemu
//

import Foundation
import Observation
import AVFoundation
import UIKit
import SwiftData

@Observable
@MainActor
final class BedtimeViewModel {

    // MARK: - メモ
    var memo: String = ""

    // MARK: - 呼吸法（4-7-8）
    enum BreathPhase {
        case inhale, hold, exhale, idle

        var label: String {
            switch self {
            case .inhale: return "吸う"
            case .hold:   return "止める"
            case .exhale: return "吐く"
            case .idle:   return "タップで開始"
            }
        }

        var duration: Double {
            switch self {
            case .inhale: return 4
            case .hold:   return 7
            case .exhale: return 8
            case .idle:   return 0
            }
        }
    }

    var breathPhase: BreathPhase = .idle
    var breathProgress: Double = 0.0
    var breathCycleCount: Int = 0
    private var breathTask: Task<Void, Never>?

    func toggleBreathing() {
        if breathPhase == .idle {
            startBreathing()
        } else {
            stopBreathing()
        }
    }

    private func startBreathing() {
        breathTask = Task {
            while !Task.isCancelled {
                for phase in [BreathPhase.inhale, .hold, .exhale] {
                    guard !Task.isCancelled else { return }
                    breathPhase = phase
                    let steps = 60
                    for i in 0...steps {
                        guard !Task.isCancelled else { return }
                        breathProgress = Double(i) / Double(steps)
                        try? await Task.sleep(nanoseconds: UInt64(phase.duration / Double(steps) * 1_000_000_000))
                    }
                }
                breathCycleCount += 1
            }
        }
    }

    func stopBreathing() {
        breathTask?.cancel()
        breathTask = nil
        breathPhase = .idle
        breathProgress = 0
    }

    // MARK: - 自然音
    enum SoundType: String, CaseIterable, Identifiable {
        case rain = "雨"
        case wave = "波"
        case forest = "森"
        case none = "なし"

        var id: String { rawValue }

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
    private var audioPlayer: AVAudioPlayer?

    func selectSound(_ sound: SoundType) {
        selectedSound = sound
        audioPlayer?.stop()
        guard sound != .none else { return }
        // TODO: Bundle に音声ファイルを追加後に有効化
        // if let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") {
        //     audioPlayer = try? AVAudioPlayer(contentsOf: url)
        //     audioPlayer?.numberOfLoops = -1
        //     audioPlayer?.play()
        // }
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

    func startSession(modelContext: ModelContext) {
        self.modelContext = modelContext
        let session = SleepSession(bedTime: Date())
        modelContext.insert(session)
        try? modelContext.save()
        self.currentSession = session

        // センサー監視開始
        SleepMonitorService.shared.startMonitoring(bedTime: Date())
    }

    func endSession() {
        guard let session = currentSession, let context = modelContext else { return }
        session.wakeTime = Date()
        session.motionEventCount = SleepMonitorService.shared.motionEventCount
        session.calculateScore()
        try? context.save()
        SleepMonitorService.shared.stopMonitoring()
    }

    // MARK: - 終了
    func finish() {
        stopBreathing()
        audioPlayer?.stop()
        restoreScreen()
        endSession()
    }
}
