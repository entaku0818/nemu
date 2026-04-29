//
//  nemuTests.swift
//  nemuTests
//

import Testing
import Foundation
@testable import nemu

struct SleepScoreTests {

    // MARK: - ヘルパー

    private func makeBreakdown(
        sleepHours: Double,
        motionCount: Int = 0,
        motionInSecondHalf: Bool = false,
        snoreCount: Int = 0
    ) -> ScoreBreakdown {
        let bedTime = Date()
        let wakeTime = bedTime.addingTimeInterval(sleepHours * 3600)

        let motionTimestamps: [Date]
        if motionCount > 0 {
            let sessionDuration = sleepHours * 3600
            let offset: Double = motionInSecondHalf ? sessionDuration * 0.75 : sessionDuration * 0.25
            motionTimestamps = (0..<motionCount).map { i in
                bedTime.addingTimeInterval(offset + Double(i) * 10)
            }
        } else {
            motionTimestamps = []
        }

        let snoreTimestamps = (0..<snoreCount).map { i in
            bedTime.addingTimeInterval(Double(i) * 60)
        }

        return SleepSession.computeBreakdown(
            bedTime: bedTime,
            wakeTime: wakeTime,
            motionEventCount: motionCount,
            motionTimestamps: motionTimestamps,
            snoreTimestamps: snoreTimestamps
        )
    }

    // MARK: - 睡眠時間スコア

    @Test("30分未満はスコア0")
    func scoreBelowThreshold() {
        let bedTime = Date()
        let wakeTime = bedTime.addingTimeInterval(1799)
        let bd = SleepSession.computeBreakdown(
            bedTime: bedTime, wakeTime: wakeTime,
            motionEventCount: 0, motionTimestamps: [], snoreTimestamps: []
        )
        #expect(bd.total == 0)
    }

    @Test("7時間睡眠はdurationScoreが満点近い")
    func score7Hours() {
        let bd = makeBreakdown(sleepHours: 7)
        #expect(bd.durationScore >= 80)
    }

    @Test("5時間睡眠はdurationScore40点")
    func score5Hours() {
        let bd = makeBreakdown(sleepHours: 5)
        #expect(bd.durationScore == 40)
    }

    @Test("8時間睡眠はdurationScore100点")
    func score8Hours() {
        let bd = makeBreakdown(sleepHours: 8)
        #expect(bd.durationScore == 100)
    }

    @Test("9時間睡眠はdurationScoreが減点される")
    func score9Hours() {
        let bd8 = makeBreakdown(sleepHours: 8)
        let bd9 = makeBreakdown(sleepHours: 9)
        #expect(bd9.durationScore < bd8.durationScore)
    }

    // MARK: - 体動ペナルティ

    @Test("体動10回で-20点")
    func motionPenalty10() {
        let bd = makeBreakdown(sleepHours: 7, motionCount: 10)
        #expect(bd.motionPenalty == 20)
    }

    @Test("体動ペナルティは最大40点")
    func motionPenaltyCap() {
        let bd = makeBreakdown(sleepHours: 7, motionCount: 100)
        #expect(bd.motionPenalty == 40)
    }

    // MARK: - 体動分布ボーナス

    @Test("後半に体動が集中すると+10ボーナス")
    func distributionBonusSecondHalf() {
        let bd = makeBreakdown(sleepHours: 7, motionCount: 5, motionInSecondHalf: true)
        #expect(bd.distributionBonus == 10)
    }

    @Test("前半に体動が集中するとボーナスなし")
    func distributionBonusFirstHalf() {
        let bd = makeBreakdown(sleepHours: 7, motionCount: 5, motionInSecondHalf: false)
        #expect(bd.distributionBonus == 0)
    }

    @Test("タイムスタンプなしはボーナスなし")
    func distributionBonusNoTimestamps() {
        let bedTime = Date()
        let wakeTime = bedTime.addingTimeInterval(7 * 3600)
        let bd = SleepSession.computeBreakdown(
            bedTime: bedTime, wakeTime: wakeTime,
            motionEventCount: 5, motionTimestamps: [], snoreTimestamps: []
        )
        #expect(bd.distributionBonus == 0)
    }

    // MARK: - いびきペナルティ

    @Test("いびき3回で-9点")
    func snorePenalty3() {
        let bd = makeBreakdown(sleepHours: 7, snoreCount: 3)
        #expect(bd.snorePenalty == 9)
    }

    @Test("いびきペナルティは最大20点")
    func snorePenaltyCap() {
        let bd = makeBreakdown(sleepHours: 7, snoreCount: 100)
        #expect(bd.snorePenalty == 20)
    }

    // MARK: - 合計スコア

    @Test("スコアは0〜100の範囲に収まる")
    func scoreRange() {
        let extremeCases: [(Double, Int, Int)] = [
            (2, 0, 0),   // 短い睡眠
            (7, 0, 0),   // 理想的
            (7, 50, 50), // 体動・いびき多数
            (12, 0, 0),  // 長すぎ
        ]
        for (hours, motion, snore) in extremeCases {
            let bd = makeBreakdown(sleepHours: hours, motionCount: motion, snoreCount: snore)
            #expect(bd.total >= 0 && bd.total <= 100, "hours=\(hours) motion=\(motion) snore=\(snore) → \(bd.total)")
        }
    }

    @Test("体動後半集中＋いびきなし＋7時間はハイスコア")
    func highScoreConditions() {
        let bd = makeBreakdown(sleepHours: 7, motionCount: 3, motionInSecondHalf: true, snoreCount: 0)
        #expect(bd.total >= 80)
    }
}
