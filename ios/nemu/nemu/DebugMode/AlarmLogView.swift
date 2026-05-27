//
//  AlarmLogView.swift
//  nemu
//

#if DEBUG

import SwiftUI

struct AlarmLogView: View {
    @State private var logger = AlarmLogger.shared

    var body: some View {
        List {
            if logger.entries.isEmpty {
                ContentUnavailableView(
                    "ログなし",
                    systemImage: "bell.slash",
                    description: Text("アラームの操作が発生するとここに記録されます")
                )
            } else {
                ForEach(logger.entries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.message)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(color(for: entry.level))
                            .fixedSize(horizontal: false, vertical: true)
                        Text(entry.timestamp.formatted(.dateTime.month().day().hour().minute().second()))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .listRowInsets(.init(top: 8, leading: 12, bottom: 8, trailing: 12))
                }
            }
        }
        .navigationTitle("アラームログ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("クリア", role: .destructive) {
                    logger.clear()
                }
                .disabled(logger.entries.isEmpty)
            }
        }
    }

    private func color(for level: AlarmLogger.Entry.Level) -> Color {
        switch level {
        case .success: return .green
        case .error:   return .red
        case .info:    return .primary
        }
    }
}

#Preview {
    NavigationStack {
        AlarmLogView()
    }
}

#endif
