//
//  DebugMenuView.swift
//  nemu
//

#if DEBUG

import SwiftUI

@Observable
final class DebugSettings {
    static let shared = DebugSettings()

    var timeAcceleration: Bool {
        get { UserDefaults.standard.bool(forKey: "debugTimeAcceleration") }
        set { UserDefaults.standard.set(newValue, forKey: "debugTimeAcceleration") }
    }

    private init() {}
}

struct DebugMenuView: View {
    @State private var settings = DebugSettings.shared
    @State private var showScreenshotPreview = false
    @State private var monitor = SleepMonitorService.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: Bindable(settings).timeAcceleration) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("時間加速モード")
                                .font(.subheadline)
                            Text("1分 = 1時間として記録・起床トリガー発火")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.indigo)
                } header: {
                    Text("睡眠シミュレーション")
                }

                Section {
                    HStack {
                        Text("マイク入力レベル (RMS)")
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.4f", monitor.currentRMS))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(monitor.currentRMS > 0.04 ? .orange : .secondary)
                    }
                    HStack {
                        Text("いびき検知数")
                            .font(.subheadline)
                        Spacer()
                        Text("\(monitor.snoreTimestamps.count) 回")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("監視状態")
                            .font(.subheadline)
                        Spacer()
                        Text(monitor.isMonitoring ? "録音中" : "停止中")
                            .font(.caption)
                            .foregroundStyle(monitor.isMonitoring ? .green : .secondary)
                    }
                } header: {
                    Text("いびき検知モニター")
                } footer: {
                    Text("RMS > 0.04 でいびき判定。オレンジ色になれば音を拾っています。")
                        .font(.caption2)
                }

                Section {
                    Button("スクリーンショットプレビュー") {
                        showScreenshotPreview = true
                    }
                } header: {
                    Text("開発ツール")
                }
            }
            .navigationTitle("デバッグ")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showScreenshotPreview) {
            ScreenshotPreviewView()
        }
    }
}

#Preview {
    DebugMenuView()
}

#endif
