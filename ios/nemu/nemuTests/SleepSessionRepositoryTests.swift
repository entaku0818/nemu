//
//  SleepSessionRepositoryTests.swift
//  nemuTests
//

import Testing
import SwiftData
import Foundation
@testable import nemu

@MainActor
struct SleepSessionRepositoryTests {

    private func makeContext() throws -> ModelContext {
        let schema = Schema([SleepSession.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test("allScoresは有効セッションのみを日付昇順で返す")
    func allScoresReturnsSortedValidSessions() throws {
        let context = try makeContext()
        let repo = SleepSessionRepository(context: context)

        let old = SleepSession(bedTime: Date().addingTimeInterval(-86400 * 10))
        old.wakeTime = old.bedTime.addingTimeInterval(7 * 3600)
        old.score = 70

        let recent = SleepSession(bedTime: Date().addingTimeInterval(-86400 * 2))
        recent.wakeTime = recent.bedTime.addingTimeInterval(7 * 3600)
        recent.score = 85

        let invalid = SleepSession(bedTime: Date().addingTimeInterval(-86400))
        invalid.wakeTime = invalid.bedTime.addingTimeInterval(600) // 10分 → 30分未満は無効
        invalid.score = 0

        context.insert(old)
        context.insert(recent)
        context.insert(invalid)
        try context.save()

        let scores = repo.allScores()
        #expect(scores.count == 2)
        #expect(scores[0].score == 70)
        #expect(scores[1].score == 85)
        #expect(scores[0].date < scores[1].date)
    }

    @Test("allScoresはデータがない場合は空配列")
    func allScoresEmptyWhenNoSessions() throws {
        let context = try makeContext()
        let repo = SleepSessionRepository(context: context)
        #expect(repo.allScores().isEmpty)
    }
}
