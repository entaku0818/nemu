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

        /// Bundle 内の音声ファイル名（拡張子なし）
        /// ファイルは rain.mp3 / wave.mp3 / forest.mp3 をプロジェクトに追加する
        /// フリー素材例: https://freesound.org / https://soundbible.com
        var fileName: String {
            switch self {
            case .rain:   return "rain"
            case .wave:   return "wave"
            case .forest: return "forest"
            case .none:   return ""
            }
        }
    }

    var selectedSound: SoundType = .none
    private var audioPlayer: AVAudioPlayer?

    func selectSound(_ sound: SoundType) {
        selectedSound = sound
        audioPlayer?.stop()
        guard sound != .none else { return }

        // ロック画面でも再生できるようにオーディオセッションを設定
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: "mp3") else {
            // 音声ファイル未追加の場合は選択状態だけ保持（無音）
            return
        }
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.numberOfLoops = -1
        audioPlayer?.play()
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
        do {
            try modelContext.save()
        } catch {
            dbError = "セッションの開始に失敗しました: \(error.localizedDescription)"
            return
        }
        self.currentSession = session
        SleepMonitorService.shared.startMonitoring(bedTime: Date())
    }

    func endSession() {
        guard let session = currentSession, let context = modelContext else { return }
        currentSession = nil  // 二重呼び出し防止
        // 音声リソースを確実に解放
        audioPlayer?.stop()
        audioPlayer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        session.wakeTime = Date()
        session.motionEventCount = SleepMonitorService.shared.motionEventCount
        session.calculateScore()
        do {
            try context.save()
        } catch {
            dbError = "睡眠データの保存に失敗しました: \(error.localizedDescription)"
        }
        SleepMonitorService.shared.stopMonitoring()
    }

    // MARK: - プレミアム状態
    var isUnlocked: Bool { PurchaseService.shared.isPremium }

    // MARK: - 終了
    func finish() {
        restoreScreen()
        endSession()
        NotificationCenter.default.post(name: .didWakeUp, object: nil)
    }
}
