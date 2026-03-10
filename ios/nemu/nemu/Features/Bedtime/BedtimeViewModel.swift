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
        audioPlayer?.stop()
        restoreScreen()
        endSession()
    }
}
