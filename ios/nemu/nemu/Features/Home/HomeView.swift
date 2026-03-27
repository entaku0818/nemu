//
//  HomeView.swift
//  nemu
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var showTimePicker = false
    #if DEBUG
    @State private var showScreenshotPreview = false
    #endif

    private let dayLabels = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {

                // ヘッダー: ブランド + 累計資産バッジ
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.stars.fill")
                            .font(.title3)
                            .foregroundStyle(.indigo)
                            #if DEBUG
                            .onLongPressGesture {
                                showScreenshotPreview = true
                            }
                            #endif
                        Text("ねむ")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    if viewModel.totalSleepHours > 0 {
                        TotalAssetBadge(totalHours: viewModel.totalSleepHours)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 20)

                // 昨夜のスコアカード（記録がある場合のみ）
                if let session = viewModel.latestSession, session.score > 0 {
                    CompactScoreCard(
                        session: session,
                        grade: viewModel.lastNightGrade,
                        streak: viewModel.streakDays
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }

                // 起床時刻 + 曜日
                VStack(spacing: 16) {
                    Text("起床時刻")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                        .textCase(.uppercase)
                        .tracking(2)

                    // 大活字タイポグラフィ（タップで編集シートを開く）
                    Button {
                        showTimePicker = true
                    } label: {
                        Text(viewModel.wakeTimeFormatted)
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                    }

                    // 繰り返し曜日
                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { day in
                            Button {
                                viewModel.toggleRepeatDay(day)
                            } label: {
                                Text(dayLabels[day])
                                    .font(.caption.bold())
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(viewModel.repeatDays.contains(day)
                                                  ? Color.indigo
                                                  : Color.white.opacity(0.1))
                                    )
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.07))
                )
                .padding(.horizontal)

                // アラームON/OFF
                VStack(spacing: 8) {
                    Toggle(isOn: $viewModel.isAlarmEnabled) {
                        Text("アラーム")
                            .foregroundStyle(.white)
                    }
                    .tint(.indigo)
                    .padding(.horizontal, 24)
                    .onChange(of: viewModel.isAlarmEnabled) {
                        viewModel.saveAlarmSetting()
                    }

                    Text(viewModel.nextAlarmDescription)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.top, 20)

                Spacer()

                // 就寝ボタン + マイクロコピー
                VStack(spacing: 8) {
                    Button {
                        viewModel.startBedtime()
                    } label: {
                        Label("就寝する", systemImage: "bed.double.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.indigo.gradient)
                            )
                    }

                    // 連続記録 or 資産マイクロコピー
                    if viewModel.streakDays >= 2 {
                        Text("\(viewModel.streakDays)日連続記録中 ✦")
                            .font(.caption2)
                            .foregroundStyle(Color.assetGold.opacity(0.7))
                    } else {
                        Text("今夜も睡眠資産を積み上げよう ✦")
                            .font(.caption2)
                            .foregroundStyle(Color.assetGold.opacity(0.5))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            viewModel.setup(modelContext: modelContext)
            // 就寝前に位置情報を先行取得。フォアグラウンド中に完了させることで
            // WhenInUse権限のまま日の出計算を確実に行う。
            SleepMonitorService.shared.prepareForSleep()
        }
        // 起床時刻編集シート
        .sheet(isPresented: $showTimePicker) {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("完了") { showTimePicker = false }
                        .foregroundStyle(.indigo)
                        .font(.headline)
                        .padding()
                }
                DatePicker("", selection: $viewModel.wakeTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .onChange(of: viewModel.wakeTime) {
                        viewModel.saveAlarmSetting()
                    }
                Spacer()
            }
            .background(Color.appBackground)
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
        #if DEBUG
        .sheet(isPresented: $showScreenshotPreview) {
            ScreenshotPreviewView()
        }
        #endif
        .fullScreenCover(isPresented: $viewModel.isBedtimeMode) {
            BedtimeView(alarmTime: viewModel.wakeTime)
        }
        .alert("保存エラー", isPresented: Binding(
            get: { viewModel.dbError != nil },
            set: { if !$0 { viewModel.dbError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.dbError ?? "")
        }
    }
}

// MARK: - 昨夜スコアカード（コンパクト版）

private struct CompactScoreCard: View {
    let session: SleepSession
    let grade: String
    let streak: Int

    private var gradeColor: Color {
        switch session.score {
        case 80...: return .green
        case 60..<80: return .indigo
        case 40..<60: return Color.assetGold
        default: return .orange
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // スコア数字
            HStack(alignment: .bottom, spacing: 3) {
                Text("\(session.score)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("/ 100")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.bottom, 4)
            }

            // グレード + 睡眠時間
            VStack(alignment: .leading, spacing: 3) {
                Text(grade)
                    .font(.caption.bold())
                    .foregroundStyle(gradeColor)
                Text("昨夜 · \(session.durationFormatted)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.35))
            }

            Spacer()

            // 連続記録バッジ（2日以上で表示）
            if streak >= 2 {
                VStack(spacing: 2) {
                    Text("🔥")
                        .font(.caption)
                    Text("\(streak)日")
                        .font(.caption2.bold())
                        .foregroundStyle(Color.assetGold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.assetGold.opacity(0.12))
                        .overlay(Capsule().strokeBorder(Color.assetGold.opacity(0.25), lineWidth: 1))
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.07))
        )
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [AlarmSetting.self, SleepSession.self], inMemory: true)
}
