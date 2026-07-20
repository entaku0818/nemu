//
//  HealthKitService.swift
//  nemu
//
//  セッション終了時に睡眠データを HealthKit（睡眠分析）へ書き込む。
//  睡眠ステージは検出していないため asleepUnspecified の単一サンプルとして保存する。
//

import Foundation
import HealthKit
import Observation

enum HealthKitPermissionState {
    case notDetermined
    case authorized
    case denied
    case unavailable
}

@Observable
@MainActor
final class HealthKitService {
    static let shared = HealthKitService()

    private let store = HKHealthStore()
    private let sleepType = HKCategoryType(.sleepAnalysis)

    private(set) var authorizationStatus: HKAuthorizationStatus = .notDetermined

    private init() {
        refreshStatus()
    }

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    var permissionState: HealthKitPermissionState {
        guard isAvailable else { return .unavailable }
        switch authorizationStatus {
        case .sharingAuthorized: return .authorized
        case .sharingDenied: return .denied
        default: return .notDetermined
        }
    }

    func refreshStatus() {
        guard isAvailable else { return }
        authorizationStatus = store.authorizationStatus(for: sleepType)
    }

    func requestAuthorization() async {
        guard isAvailable else { return }
        try? await store.requestAuthorization(toShare: [sleepType], read: [])
        refreshStatus()
    }

    /// 就寝〜起床の全体を asleepUnspecified の単一サンプルとして保存する
    func saveSleepSession(bedTime: Date, wakeTime: Date) async {
        guard isAvailable, authorizationStatus == .sharingAuthorized else { return }
        let sample = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            start: bedTime,
            end: wakeTime
        )
        try? await store.save(sample)
    }
}
