// SleepSessionFinalizer
// アプリ強制終了時もセッションを確実に復元・保存するためのサービス。
// UserDefaults にアクティブなセッションの bedTime を記録し、
// 起動時に未完了セッションが残っていれば復元できるようにする。

import Foundation
import SwiftData
import CoreMotion

enum SleepSessionFinalizer {

    private static let activeSessionKey = "nemu.activeSessionBedTime"

    // MARK: - Active Session Tracking

    static func markActive(bedTime: Date) {
        UserDefaults.standard.set(bedTime.timeIntervalSince1970, forKey: activeSessionKey)
    }

    static func clearActive() {
        UserDefaults.standard.removeObject(forKey: activeSessionKey)
    }

    static func activeBedTime() -> Date? {
        let t = UserDefaults.standard.double(forKey: activeSessionKey)
        guard t > 0 else { return nil }
        return Date(timeIntervalSince1970: t)
    }

    // MARK: - Finalization

    enum Result {
        case saved(score: Int, duration: TimeInterval)
        case discarded
    }

    /// wakeTime を設定し CoreMotion データを取得してスコアを計算・保存する。
    /// 30分未満のセッションは自動削除。
    @MainActor
    static func finalize(
        _ session: SleepSession,
        wakeTime: Date,
        snoreTimestamps: [Date] = [],
        context: ModelContext
    ) async -> Result {
        session.wakeTime = wakeTime
        if !snoreTimestamps.isEmpty {
            session.snoreTimestamps = snoreTimestamps
        }

        await fetchMotionData(for: session, to: wakeTime)

        session.calculateScore()
        clearActive()

        if session.duration < 1800 {
            context.delete(session)
            try? context.save()
            return .discarded
        } else {
            try? context.save()
            return .saved(score: session.score, duration: session.duration)
        }
    }

    static func discard(_ session: SleepSession, context: ModelContext) {
        context.delete(session)
        try? context.save()
        clearActive()
    }

    // MARK: - Private

    @MainActor
    private static func fetchMotionData(for session: SleepSession, to wakeTime: Date) async {
        guard CMMotionActivityManager.isActivityAvailable() else { return }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let mgr = CMMotionActivityManager()
            mgr.queryActivityStarting(from: session.bedTime, to: wakeTime, to: .main) { activities, _ in
                let motionActivities = activities?.filter {
                    !$0.stationary && ($0.walking || $0.running || $0.cycling || $0.automotive)
                } ?? []
                session.motionEventCount = motionActivities.count
                session.motionTimestamps = motionActivities.map { $0.startDate }
                continuation.resume()
            }
        }
    }
}
