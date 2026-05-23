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
        case .japanese: return "Slumber"
        case .english: return "Slumber"
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

    var alarmLabel: String {
        switch self {
        case .japanese: return "アラーム"
        case .english: return "Alarm"
        }
    }

    var tomorrowAlarm: String {
        switch self {
        case .japanese: return "明日 7:00"
        case .english: return "Tomorrow 7:00"
        }
    }

    var sleepDurationFormatted: String {
        switch self {
        case .japanese: return "7時間23分"
        case .english: return "7h 23m"
        }
    }

    var motionLabel: String {
        switch self {
        case .japanese: return "モーション"
        case .english: return "Motion"
        }
    }

    var motionLevel: String {
        switch self {
        case .japanese: return "少ない"
        case .english: return "Low"
        }
    }

    var viewReportButton: String {
        switch self {
        case .japanese: return "レポートを見る"
        case .english: return "View Report"
        }
    }

    var wakeUpButton: String {
        switch self {
        case .japanese: return "起床する"
        case .english: return "Wake Up"
        }
    }

    var alarmAtTime: String {
        switch self {
        case .japanese: return "目覚まし 7:00"
        case .english: return "Alarm 7:00"
        }
    }

    var sleepElapsedFormatted: String {
        switch self {
        case .japanese: return "3時間12分"
        case .english: return "3h 12m"
        }
    }

    var totalLabel: String {
        switch self {
        case .japanese: return "累計"
        case .english: return "Total"
        }
    }

    var totalHours: String {
        switch self {
        case .japanese: return "52時間"
        case .english: return "52h"
        }
    }

    var scoreUnit: String {
        switch self {
        case .japanese: return "82点"
        case .english: return "82pts"
        }
    }

    var startTrialButton: String {
        switch self {
        case .japanese: return "14日間無料トライアルを始める"
        case .english: return "Start 14-Day Free Trial"
        }
    }

    var dayLabels: [String] {
        switch self {
        case .japanese: return ["日", "月", "火", "水", "木", "金", "土"]
        case .english:  return ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
        }
    }

    var weekDayLabels: [String] {
        switch self {
        case .japanese: return ["月", "火", "水", "木", "金", "土", "日"]
        case .english:  return ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
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
                            Text(language.dayLabels[day])
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
                        Text(language.alarmLabel)
                            .foregroundStyle(.white)
                        Spacer()
                        // ImageRenderer非対応のToggleをカスタム実装
                        Capsule()
                            .fill(Color.indigo)
                            .frame(width: 51, height: 31)
                            .overlay(
                                Circle()
                                    .fill(.white)
                                    .frame(width: 27, height: 27)
                                    .offset(x: 10)
                            )
                    }
                    .padding(.horizontal, 24)
                    Text(language.tomorrowAlarm)
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
                        Text(language.sleepDurationFormatted)
                            .foregroundStyle(.white)
                            .bold()
                    }
                    Divider().background(.white.opacity(0.1))
                    HStack {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundStyle(.green)
                        Text(language.motionLabel)
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Text(language.motionLevel)
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
                    Text(language.viewReportButton)
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

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: 24) {
                reportHeader
                scoreCard
                weeklyChartCard
                Spacer()
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
                Text(language.totalLabel)
                    .font(.caption2)
                    .foregroundStyle(Color.assetGold.opacity(0.7))
                Text(language.totalHours)
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
                Text(language.scoreUnit)
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
                    Text(language.sleepDurationFormatted)
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

    // Chart非対応のためカスタム棒グラフ
    private var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language.weeklyTrend)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
            GeometryReader { geo in
                let maxScore = mockScores.max() ?? 100
                let barWidth = (geo.size.width - CGFloat(mockScores.count - 1) * 8) / CGFloat(mockScores.count)
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(zip(language.weekDayLabels, mockScores)), id: \.0) { day, score in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(score >= 80 ? Color.assetGold : Color.indigo)
                                .frame(width: barWidth, height: geo.size.height * 0.82 * score / maxScore)
                            Text(day)
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.6))
                                .frame(width: barWidth)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 120)
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

                    Text(language.sleepElapsedFormatted)
                        .font(.system(size: 48, weight: .thin, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))

                    Text(language.alarmAtTime)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Button {} label: {
                    Label(language.wakeUpButton, systemImage: "sun.max.fill")
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
                    Text(language.startTrialButton)
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

// MARK: - iPhone フレーム

struct PhoneMockupView<Content: View>: View {
    let content: Content

    // iPhone 16 Pro Max 比率に合わせた内部サイズ
    private let cornerRadius: CGFloat = 50
    private let borderWidth: CGFloat = 8
    private let dynamicIslandW: CGFloat = 120
    private let dynamicIslandH: CGFloat = 34

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // ベゼル
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(white: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color(white: 0.4), Color(white: 0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: borderWidth
                            )
                    )

                // 画面
                RoundedRectangle(cornerRadius: cornerRadius - borderWidth)
                    .fill(Color.black)
                    .padding(borderWidth)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius - borderWidth))

                // コンテンツ
                content
                    .frame(width: w - borderWidth * 2, height: h - borderWidth * 2)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius - borderWidth))
                    .offset(x: 0, y: 0)
                    .padding(borderWidth)

                // Dynamic Island
                Capsule()
                    .fill(Color.black)
                    .frame(width: dynamicIslandW, height: dynamicIslandH)
                    .frame(width: w, height: h, alignment: .top)
                    .padding(.top, borderWidth + 12)

                // ホームインジケーター
                Capsule()
                    .fill(Color(white: 0.5).opacity(0.6))
                    .frame(width: 120, height: 5)
                    .frame(width: w, height: h, alignment: .bottom)
                    .padding(.bottom, borderWidth + 8)
            }
            .frame(width: w, height: h)
        }
    }
}

// MARK: - App Store スクリーンショット（フレーム＋背景＋キャプション）

struct AppStoreScreenshotView<Content: View>: View {
    let title: String
    let subtitle: String
    let background: [Color]
    let content: Content

    init(
        title: String,
        subtitle: String,
        background: [Color],
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.background = background
        self.content = content()
    }

    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(colors: background, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // キャプション
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text(subtitle)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 52)
                .padding(.horizontal, 28)
                .padding(.bottom, 28)

                // iPhone フレーム
                PhoneMockupView {
                    content
                }
                .aspectRatio(9/19.5, contentMode: .fit)
                .padding(.horizontal, 24)

                Spacer(minLength: 24)
            }
        }
    }
}

// MARK: - キャプション定義

extension NemuScreenshotScreen {
    func title(language: NemuLanguage) -> String {
        switch (self, language) {
        case (.home, .japanese):      return "確実に起きられる\nアラーム"
        case (.home, .english):       return "Wake Up\nReliably"
        case (.bedtime, .japanese):   return "就寝中も\nしっかりサポート"
        case (.bedtime, .english):    return "Monitored\nWhile You Sleep"
        case (.wakeScore, .japanese): return "眠りを\nスコアで可視化"
        case (.wakeScore, .english):  return "Visualize\nYour Sleep"
        case (.report, .japanese):    return "睡眠資産を\n積み上げる"
        case (.report, .english):     return "Build Your\nSleep Asset"
        case (.paywall, .japanese):   return "もっと深く\n眠るために"
        case (.paywall, .english):    return "Sleep Deeper\nWith Premium"
        }
    }

    func subtitle(language: NemuLanguage) -> String {
        switch (self, language) {
        case (.home, .japanese):      return "日の出・体動・明るさ3条件で\n最適なタイミングに起こします"
        case (.home, .english):       return "Sunrise × Motion × Light\ntrigger the perfect wake-up"
        case (.bedtime, .japanese):   return "サイレントモードでも\n絶対に鳴るAlarmKit搭載"
        case (.bedtime, .english):    return "Powered by AlarmKit —\nrings even in Silent mode"
        case (.wakeScore, .japanese): return "睡眠時間・体動・いびきを分析\n毎朝スコアをお知らせ"
        case (.wakeScore, .english):  return "Duration, motion & snoring\nanalyzed every morning"
        case (.report, .japanese):    return "毎日の記録が積み重なる\n週間トレンドで傾向を把握"
        case (.report, .english):     return "Track weekly trends and\nbuild your sleep history"
        case (.paywall, .japanese):   return "詳細レポート・全自然音・\n長期グラフでさらに快眠へ"
        case (.paywall, .english):    return "Detailed reports, all sounds\nand long-term graphs"
        }
    }

    var background: [Color] {
        switch self {
        case .home:      return [Color(red: 0.08, green: 0.08, blue: 0.25), Color(red: 0.15, green: 0.10, blue: 0.35)]
        case .bedtime:   return [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.10, green: 0.08, blue: 0.22)]
        case .wakeScore: return [Color(red: 0.10, green: 0.15, blue: 0.30), Color(red: 0.20, green: 0.12, blue: 0.28)]
        case .report:    return [Color(red: 0.08, green: 0.12, blue: 0.28), Color(red: 0.18, green: 0.10, blue: 0.32)]
        case .paywall:   return [Color(red: 0.20, green: 0.14, blue: 0.10), Color(red: 0.30, green: 0.18, blue: 0.08)]
        }
    }
}

#Preview {
    ScreenshotPreviewView()
}

// フレーム付きプレビュー
#Preview("Home JA Framed") {
    AppStoreScreenshotView(
        title: NemuScreenshotScreen.home.title(language: .japanese),
        subtitle: NemuScreenshotScreen.home.subtitle(language: .japanese),
        background: NemuScreenshotScreen.home.background
    ) {
        MockNemuHomeView(language: .japanese)
    }
    .frame(width: 393, height: 852)
}
#endif
