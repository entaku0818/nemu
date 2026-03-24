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
        .onReceive(NotificationCenter.default.publisher(for: .didWakeUp)) { _ in
            selectedTab = 1
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
