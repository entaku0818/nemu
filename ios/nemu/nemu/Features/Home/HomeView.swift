//
//  HomeView.swift
//  nemu
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var showAlarmList = false
    #if DEBUG
    @State private var showDebugMenu = false
    #endif

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {

                // ヘッダー
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.stars.fill")
                            .font(.title3)
                            .foregroundStyle(.indigo)
                            #if DEBUG
                            .onLongPressGesture {
                                showDebugMenu = true
                            }
                            #endif
                        Text("Slumber")
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

                // 昨夜のスコアカード
                if let session = viewModel.latestSession, session.score > 0 {
                    CompactScoreCard(
                        session: session,
                        grade: viewModel.lastNightGrade,
                        streak: viewModel.streakDays
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }

                // 次のアラーム（タップで一覧へ）
                Button {
                    showAlarmList = true
                } label: {
                    HStack {
                        Image(systemName: "alarm.fill")
                            .foregroundStyle(.indigo)
                        Text(viewModel.nextAlarmDescription)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.07))
                    )
                    .padding(.horizontal)
                }
                .padding(.top, 16)

                Spacer()

                // 就寝ボタン
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
            SleepMonitorService.shared.prepareForSleep()
        }
        .sheet(isPresented: $showAlarmList, onDismiss: {
            viewModel.reload()
        }) {
            AlarmListView()
        }
        #if DEBUG
        .sheet(isPresented: $showDebugMenu) {
            DebugMenuView()
        }
        #endif
        .fullScreenCover(isPresented: $viewModel.isBedtimeMode) {
            BedtimeView(alarmTime: viewModel.nextAlarmSetting?.wakeTime ?? Date())
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

// MARK: - 昨夜スコアカード

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
            HStack(alignment: .bottom, spacing: 3) {
                Text("\(session.score)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("/ 100")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.bottom, 4)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(grade)
                    .font(.caption.bold())
                    .foregroundStyle(gradeColor)
                Text("\(session.dateLabel) · \(session.durationFormatted)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.35))
            }

            Spacer()

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
