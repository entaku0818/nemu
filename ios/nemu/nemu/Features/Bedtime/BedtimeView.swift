//
//  BedtimeView.swift
//  nemu
//

import SwiftUI
import SwiftData
import Combine

struct BedtimeView: View {
    let alarmTime: Date
    @State private var viewModel = BedtimeViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isDimmed = false
    @State private var showMemo = false
    @State private var showWakeConfirm = false
    @State private var showQuitConfirm = false
    @State private var showPaywall = false
    @State private var bedStartTime = Date()
    @State private var elapsedTime: TimeInterval = 0
    private let elapsedTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var elapsedTimeText: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {

                // ヘッダー
                HStack {
                    Button {
                        showQuitConfirm = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    Spacer()

                    Text("就寝モード")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))

                    Spacer()

                    Button {
                        showMemo.toggle()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                Spacer()

                // 月アイコン
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.indigo.opacity(0.6))

                Text("おやすみなさい")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.5))

                if elapsedTime >= 60 {
                    Text(elapsedTimeText)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.25))
                        .monospacedDigit()
                }

                Spacer()

                // 自然音セレクター
                VStack(spacing: 12) {
                    Text("自然音")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                        .tracking(2)

                    HStack(spacing: 12) {
                        ForEach(BedtimeViewModel.SoundType.allCases) { sound in
                            SoundButton(
                                sound: sound,
                                isSelected: viewModel.selectedSound == sound,
                                isPremium: sound.isPremium,
                                isUnlocked: viewModel.isUnlocked,
                                onTap: { viewModel.selectSound(sound) },
                                onPaywallTap: { showPaywall = true }
                            )
                        }
                    }
                }

                Spacer()

                VStack(spacing: 16) {
                    Button {
                        showWakeConfirm = true
                    } label: {
                        Label("起きた！", systemImage: "sun.max.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.indigo.gradient)
                            )
                    }

                    Button {
                        isDimmed.toggle()
                        if isDimmed {
                            viewModel.dimScreen()
                        } else {
                            viewModel.restoreScreen()
                        }
                    } label: {
                        Label(isDimmed ? "画面を戻す" : "画面を暗くする",
                              systemImage: isDimmed ? "sun.max.fill" : "moon.fill")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showMemo) {
            MemoView(memo: $viewModel.memo)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .interactiveDismissDisabled(true)
        .alert("保存エラー", isPresented: Binding(
            get: { viewModel.dbError != nil },
            set: { if !$0 { viewModel.dbError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.dbError ?? "")
        }
        .alert("本当に起きた？", isPresented: $showWakeConfirm) {
            Button("起きた！") {
                viewModel.finish()
                dismiss()
            }
            Button("まだ寝る", role: .cancel) {}
        }
        .alert("セッションを終了しますか？", isPresented: $showQuitConfirm) {
            Button("終了する", role: .destructive) {
                viewModel.cancelSession()
                dismiss()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("記録は保存されません。")
        }
        .onReceive(elapsedTimer) { _ in
            elapsedTime = Date().timeIntervalSince(bedStartTime)
        }
        .onAppear {
            bedStartTime = Date()
            viewModel.startSession(modelContext: modelContext, wakeTime: alarmTime)
        }
        .onDisappear {
            viewModel.finish()
        }
    }
}

// MARK: - 起床後スコア表示

// MARK: - 自然音ボタン（プレミアムロック対応）

/// デザイン仕様:
/// - 無料音（なし・雨）: そのまま選択可
/// - プレミアム音（波・森）: ロックアイコンをオーバーレイ表示、タップでペイウォールへ
private struct SoundButton: View {
    let sound: BedtimeViewModel.SoundType
    let isSelected: Bool
    let isPremium: Bool
    let isUnlocked: Bool
    let onTap: () -> Void
    let onPaywallTap: () -> Void

    private var isLocked: Bool { isPremium && !isUnlocked }

    var body: some View {
        Button {
            if isLocked {
                onPaywallTap()
            } else {
                onTap()
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 4) {
                    Image(systemName: sound.systemImage)
                        .font(.title3)
                    Text(sound.rawValue)
                        .font(.caption2)
                }
                .frame(width: 64, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected && !isLocked
                              ? Color.indigo
                              : Color.white.opacity(0.08))
                )
                .foregroundStyle(isLocked ? .white.opacity(0.35) : .white)

                // ロックバッジ
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(
                            Circle()
                                .fill(Color.indigo.opacity(0.85))
                        )
                        .offset(x: 4, y: -4)
                }
            }
        }
    }
}

// MARK: - メモシート

struct MemoView: View {
    @Binding var memo: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.12).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("今日のメモ")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button("完了") { dismiss() }
                        .foregroundStyle(.indigo)
                }
                .padding()

                Text("ストレス・感謝・気になること、なんでも")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.horizontal)

                TextEditor(text: $memo)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .foregroundStyle(.white)
                    .padding(.horizontal)
                    .frame(maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    BedtimeView(alarmTime: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date())
}
