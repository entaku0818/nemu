//
//  SleepSessionRepository.swift
//  nemu
//

import Foundation
import SwiftData

/// SleepSession の取得・集計ロジックを一元管理するリポジトリ
final class SleepSessionRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - 取得

    /// 全セッションを bedTime 降順で返す
    func fetchAll() -> [SleepSession] {
        let descriptor = FetchDescriptor<SleepSession>(
            sortBy: [SortDescriptor(\.bedTime, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// score > 0 かつ 30分以上のセッションのみ返す
    func fetchValid() -> [SleepSession] {
        fetchAll().filter { isValid($0) }
    }

    // MARK: - 集計

    /// 有効セッションの累計睡眠時間（時間・切り捨て）
    func totalSleepHours() -> Int {
        let seconds = fetchValid().compactMap { session -> TimeInterval? in
            guard let wake = session.wakeTime else { return nil }
            let d = wake.timeIntervalSince(session.bedTime)
            return d > 0 && d <= 86400 ? d : nil
        }.reduce(0, +)
        return Int(seconds / 3600)
    }

    /// 有効セッションの最新1件
    func latestValidSession() -> SleepSession? {
        fetchValid().first
    }

    /// 直近 N 日の (date, score) ペア（score がない日は 0）
    func weeklyScores(days: Int = 7) -> [(date: Date, score: Int)] {
        let valid = fetchValid()
        let calendar = Calendar.current
        return (0..<days).compactMap { offset -> (Date, Int)? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            let session = valid.first { $0.bedTime >= dayStart && $0.bedTime < dayEnd }
            return (dayStart, session?.score ?? 0)
        }.reversed()
    }

    /// 連続睡眠日数
    func streak() -> Int {
        let valid = fetchValid()
        guard !valid.isEmpty else { return 0 }
        let calendar = Calendar.current
        var count = 1
        var prevDay = calendar.startOfDay(for: valid[0].bedTime)
        for session in valid.dropFirst() {
            let day = calendar.startOfDay(for: session.bedTime)
            let diff = calendar.dateComponents([.day], from: day, to: prevDay).day ?? 0
            if diff == 1 { count += 1; prevDay = day } else { break }
        }
        return count
    }

    // MARK: - Private

    private func isValid(_ session: SleepSession) -> Bool {
        guard session.score > 0 else { return false }
        guard let wake = session.wakeTime else { return false }
        let d = wake.timeIntervalSince(session.bedTime)
        return d >= 1800 && d <= 86400
    }
}
