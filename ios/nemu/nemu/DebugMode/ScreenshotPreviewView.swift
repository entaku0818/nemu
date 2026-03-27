//
//  ScreenshotPreviewView.swift
//  nemu
//
//  App Store スクリーンショット用プレビュー（DEBUGビルドのみ）
//

import SwiftUI
import Charts

#if DEBUG

// MARK: - Screenshot Preview Feature
struct ScreenshotPreviewView: View {
    @State private var selectedLanguage: NemuLanguage?

    var body: some View {
        NavigationStack {
            List {
                ForEach(NemuLanguage.allCases, id: \.self) { language in
                    Button(action: {
                        selectedLanguage = language
                    }) {
                        HStack {
                            Text(language.displayName)
                                .font(.headline)
                            Spacer()
                            Text(language.appTitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("スクリーンショットプレビュー")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(item: $selectedLanguage) { language in
                NemuFullscreenScreenshotView(language: language, onDismiss: {
                    selectedLanguage = nil
                })
            }
        }
    }
}

// MARK: - Fullscreen Screenshot View
struct NemuFullscreenScreenshotView: View {
    let language: NemuLanguage
    let onDismiss: () -> Void
    @State private var selectedTab = 0
    @State private var dragOffset: CGSize = .zero

    private var isLastTab: Bool {
        selectedTab == NemuScreenshotScreen.allCases.count - 1
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Array(NemuScreenshotScreen.allCases.enumerated()), id: \.element) { index, screen in
                screenPreview(for: screen)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea(edges: [])
        .offset(x: isLastTab ? dragOffset.width : 0, y: dragOffset.height)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = CGSize(width: 0, height: value.translation.height)
                    } else if isLastTab && value.translation.width > 0 {
                        dragOffset = CGSize(width: value.translation.width, height: 0)
                    }
                }
                .onEnded { value in
                    if value.translation.height > 150 {
                        onDismiss()
                    } else if isLastTab && value.translation.width > 150 {
                        onDismiss()
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = .zero
                        }
                    }
                }
        )
    }

    @ViewBuilder
    private func screenPreview(for screen: NemuScreenshotScreen) -> some View {
        switch screen {
        case .home:
            MockNemuHomeView(language: language)
        case .wakeScore:
            MockWakeScoreView(language: language)
        case .report:
            MockNemuReportView(language: language)
        case .bedtime:
            MockBedtimeView(language: language)
        case .paywall:
            MockNemuPaywallView(language: language)
        }
    }
}

// MARK: - Language Enum
enum NemuLanguage: String, CaseIterable, Identifiable {
    case japanese = "ja"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .japanese: return "日本語"
        case .english: return "English"
        }
    }

    var appTitle: String {
        switch self {
        case .japanese: return "ねむ"
        case .english: return "Nemu"
        }
    }

    var wakeTimeLabel: String {
        switch self {
        case .japanese: return "起床時刻"
        case .english: return "Wake Time"
        }
    }

    var sleepButton: String {
        switch self {
        case .japanese: return "就寝する"
        case .english: return "Start Sleep"
        }
    }

    var sleepAssetTitle: String {
        switch self {
        case .japanese: return "睡眠資産"
        case .english: return "Sleep Asset"
        }
    }

    var sleepAssetSubtitle: String {
        switch self {
        case .japanese: return "眠るたびに積み上がる記録"
        case .english: return "Building your sleep record"
        }
    }

    var lastNightScore: String {
        switch self {
        case .japanese: return "昨夜のスコア"
        case .english: return "Last Night Score"
        }
    }

    var weeklyTrend: String {
        switch self {
        case .japanese: return "週間トレンド"
        case .english: return "Weekly Trend"
        }
    }

    var bedtimeMode: String {
        switch self {
        case .japanese: return "就寝モード"
        case .english: return "Bedtime Mode"
        }
    }

    var wakeUpScore: String {
        switch self {
        case .japanese: return "起床スコア"
        case .english: return "Wake Up Score"
        }
    }

    var sleepDuration: String {
        switch self {
        case .japanese: return "睡眠時間"
        case .english: return "Sleep Duration"
        }
    }

    var upgradeTitle: String {
        switch self {
        case .japanese: return "眠りを、資産に。"
        case .english: return "Sleep is your asset."
        }
    }

    var trialLabel: String {
        switch self {
        case .japanese: return "14日間無料トライアル"
        case .english: return "14-Day Free Trial"
        }
    }

    var yearlyPlan: String {
        switch self {
        case .japanese: return "年額プラン ¥2,900/年"
        case .english: return "Yearly Plan ¥2,900/yr"
        }
    }

    var monthlyPlan: String {
        switch self {
        case .japanese: return "月額 ¥480"
        case .english: return "Monthly ¥480"
        }
    }

    var gradeLabel: String {
        switch self {
        case .japanese: return "良い眠り"
        case .english: return "Good Sleep"
        }
    }
}

// MARK: - Screen Enum
enum NemuScreenshotScreen: String, CaseIterable {
    case home
    case wakeScore
    case report
    case bedtime
    case paywall
}

// MARK: - Mock: Home
struct MockNemuHomeView: View {
    let language: NemuLanguage
    private let dayLabels = ["日", "月", "火", "水", "木", "金", "土"]
    @State private var wakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.indigo.gradient)
                    Text(language.appTitle)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }

                VStack(spacing: 16) {
                    Text(language.wakeTimeLabel)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(2)

                    Text("7:00")
                        .font(.system(size: 64, weight: .thin, design: .rounded))
                        .foregroundStyle(.white)

                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { day in
                            Text(dayLabels[day])
                                .font(.caption.bold())
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill([1, 3, 5].contains(day)
                                              ? Color.indigo
                                              : Color.white.opacity(0.1))
                                )
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.07))
                )
                .padding(.horizontal)

                VStack(spacing: 8) {
                    HStack {
                        Text("アラーム")
                            .foregroundStyle(.white)
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .tint(.indigo)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 24)
                    Text("明日 7:00")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Button {} label: {
                    Label(language.sleepButton, systemImage: "bed.double.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.indigo.gradient)
                        )
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Mock: Wake Score
struct MockWakeScoreView: View {
    let language: NemuLanguage

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 8) {
                    Text(language.wakeUpScore)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(2)

                    Text("82")
                        .font(.system(size: 120, weight: .thin, design: .rounded))
                        .foregroundStyle(Color.assetGold)

                    Text(language.gradeLabel)
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    HStack(spacing: 4) {
                        ForEach(0..<5) { i in
                            Image(systemName: i < 4 ? "star.fill" : "star")
                                .foregroundStyle(Color.assetGold)
                                .font(.caption)
                        }
                    }
                }

                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "moon.zzz.fill")
                            .foregroundStyle(.indigo)
                        Text(language.sleepDuration)
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Text("7時間23分")
                            .foregroundStyle(.white)
                            .bold()
                    }
                    Divider().background(.white.opacity(0.1))
                    HStack {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundStyle(.green)
                        Text("モーション")
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Text("少ない")
                            .foregroundStyle(.green)
                            .bold()
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.07))
                )
                .padding(.horizontal)

                Spacer()

                Button {} label: {
                    Text("レポートを見る")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.indigo.gradient)
                        )
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Mock: Report
struct MockNemuReportView: View {
    let language: NemuLanguage
    private let mockScores: [Double] = [72, 85, 60, 90, 78, 82, 88]
    private let dayLabels = ["月", "火", "水", "木", "金", "土", "日"]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    reportHeader
                    scoreCard
                    weeklyChartCard
                }
            }
        }
    }

    private var reportHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(language.sleepAssetTitle)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(language.sleepAssetSubtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("累計")
                    .font(.caption2)
                    .foregroundStyle(Color.assetGold.opacity(0.7))
                Text("52時間")
                    .font(.title3.bold())
                    .foregroundStyle(Color.assetGold)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private var scoreCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text(language.lastNightScore)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text("82点")
                    .font(.caption.bold())
                    .foregroundStyle(Color.assetGold)
            }
            HStack(alignment: .bottom, spacing: 16) {
                Text("82")
                    .font(.system(size: 64, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.gradeLabel)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("7時間23分")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.07)))
        .padding(.horizontal)
    }

    private var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language.weeklyTrend)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
            Chart {
                ForEach(Array(zip(dayLabels, mockScores)), id: \.0) { day, score in
                    BarMark(x: .value("Day", day), y: .value("Score", score))
                        .foregroundStyle(score >= 80 ? AnyShapeStyle(Color.assetGold) : AnyShapeStyle(Color.indigo))
                        .cornerRadius(4)
                }
            }
            .frame(height: 120)
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel().foregroundStyle(Color.white.opacity(0.6))
                }
            }
            .chartYAxis(.hidden)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.07)))
        .padding(.horizontal)
    }
}

// MARK: - Mock: Bedtime
struct MockBedtimeView: View {
    let language: NemuLanguage

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                HStack {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer()
                    Text(language.bedtimeMode)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Image(systemName: "note.text")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.indigo.opacity(0.8))

                    Text("3時間12分")
                        .font(.system(size: 48, weight: .thin, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))

                    Text("目覚まし 7:00")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Button {} label: {
                    Label("起床する", systemImage: "sun.max.fill")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.assetGold)
                        )
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Mock: Paywall
struct MockNemuPaywallView: View {
    let language: NemuLanguage
    private let mockScores: [Double] = [65, 72, 80, 85, 78, 90, 82]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.assetGold)
                    Text(language.upgradeTitle)
                        .font(.title.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                .padding(.bottom, 24)

                // Mini chart
                Chart {
                    ForEach(Array(mockScores.enumerated()), id: \.offset) { i, score in
                        LineMark(
                            x: .value("Day", i),
                            y: .value("Score", score)
                        )
                        .foregroundStyle(Color.assetGold)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                }
                .frame(height: 80)
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .padding(.horizontal)

                Text("Sample")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.bottom, 24)

                Spacer()

                // Plans
                VStack(spacing: 12) {
                    // Yearly (highlighted)
                    VStack(spacing: 4) {
                        Text(language.trialLabel)
                            .font(.caption.bold())
                            .foregroundStyle(Color.assetGold)
                        Text(language.yearlyPlan)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.indigo.opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.assetGold, lineWidth: 1.5)
                            )
                    )

                    // Monthly
                    Text(language.monthlyPlan)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.06))
                        )
                }
                .padding(.horizontal)

                Button {} label: {
                    Text(language.trialLabel + "を始める")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.assetGold)
                        )
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    ScreenshotPreviewView()
}
#endif
