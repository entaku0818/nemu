//
//  ContentView.swift (MainTabView)
//  nemu
//
//  Created by 遠藤拓弥 on 2026/03/08.
//

import SwiftUI

struct MainTabView: View {
    @State private var showAssetBanner = false
    @State private var selectedTab = 0
    @State private var showWakeResult = false
    @State private var wakeScore = 0
    @State private var wakeDuration: TimeInterval = 0

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("ホーム", systemImage: "moon.stars.fill")
                    }
                    .tag(0)

                ReportView()
                    .tabItem {
                        Label("レポート", systemImage: "chart.bar.fill")
                    }
                    .tag(1)
            }
            .tint(.indigo)
            .preferredColorScheme(.dark)

            if showAssetBanner {
                SleepAssetBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                    .zIndex(1)
            }
        }
        .fullScreenCover(isPresented: $showWakeResult) {
            WakeResultView(
                score: wakeScore,
                duration: wakeDuration,
                onShowReport: {
                    showWakeResult = false
                    selectedTab = 1
                },
                onDismiss: {
                    showWakeResult = false
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .didWakeUp)) { notification in
            wakeScore = notification.userInfo?["score"] as? Int ?? 0
            wakeDuration = notification.userInfo?["duration"] as? TimeInterval ?? 0
            // 30分未満のセッションはスコア画面を出さずそのままReportへ
            if wakeDuration >= 1800 {
                showWakeResult = true
            } else {
                selectedTab = 1
            }
            showBanner()
        }
    }

    private func showBanner() {
        withAnimation(.spring(duration: 0.4)) {
            showAssetBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeOut(duration: 0.4)) {
                showAssetBanner = false
            }
        }
    }
}

// MARK: - 起床後スコア表示

struct WakeResultView: View {
    let score: Int
    let duration: TimeInterval
    let onShowReport: () -> Void
    let onDismiss: () -> Void

    private var grade: String {
        switch score {
        case 80...: return "とても良い"
        case 60..<80: return "良い"
        case 40..<60: return "普通"
        default: return "改善できそう"
        }
    }

    private var comment: String {
        switch score {
        case 80...: return "よく眠れました！"
        case 60..<80: return "いい睡眠でした"
        case 40..<60: return "お疲れさまでした"
        default: return "明日はもっとよく眠れます"
        }
    }

    private var gradeColor: Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .indigo
        case 40..<60: return Color.assetGold
        default: return .orange
        }
    }

    private var durationFormatted: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)時間\(minutes)分"
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "sun.max.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.yellow.opacity(0.8))

                Text(comment)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))

                VStack(spacing: 8) {
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(score)")
                            .font(.system(size: 96, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("/ 100")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.35))
                            .padding(.bottom, 12)
                    }
                    Text(grade)
                        .font(.headline)
                        .foregroundStyle(gradeColor)
                }

                HStack(spacing: 8) {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(.indigo)
                    Text(durationFormatted)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.white.opacity(0.07)))

                Spacer()

                VStack(spacing: 12) {
                    Button(action: onShowReport) {
                        Label("レポートを見る", systemImage: "chart.bar.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.indigo.gradient)
                            )
                    }

                    Button(action: onDismiss) {
                        Text("閉じる")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.4))
                            .underline()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - 睡眠資産バナー

private struct SleepAssetBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.subheadline.bold())
                .foregroundStyle(Color.assetGold)

            Text("+1日分の睡眠資産が記録されました")
                .font(.subheadline.bold())
                .foregroundStyle(.white)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.assetGold.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
        )
        .padding(.horizontal)
    }
}

#Preview {
    MainTabView()
}
