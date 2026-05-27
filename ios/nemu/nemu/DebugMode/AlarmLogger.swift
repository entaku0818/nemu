//
//  AlarmLogger.swift
//  nemu
//

#if DEBUG

import Foundation
import Observation

@Observable
final class AlarmLogger {
    static let shared = AlarmLogger()

    struct Entry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let level: Level
        let message: String

        enum Level { case info, success, error }
    }

    private(set) var entries: [Entry] = []

    private init() {}

    func log(_ message: String, level: Entry.Level = .info) {
        entries.insert(Entry(timestamp: Date(), level: level, message: message), at: 0)
    }

    func clear() { entries.removeAll() }
}

#endif
