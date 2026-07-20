//
//  OnboardingView.swift
//  nemu
//

import SwiftUI
import SwiftData
import CoreLocation
import UIKit

struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.modelContext) private var modelContext
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.12).ignoresSafeArea()

            VStack(spacing: 0) {
                PageIndicator(
                    current: viewModel.currentPage.rawValue,
                    total: OnboardingPage.allCases.count
                )
                .padding(.top, 60)
                .padding(.bottom, 8)

                let vm = Bindable(viewModel)
                TabView(selection: vm.currentPage) {
                    WelcomePage()
                        .tag(OnboardingPage.welcome)
                    MotionDetectionPage()
                        .tag(OnboardingPage.motionDetection)
                    SunrisePage()
                        .tag(OnboardingPage.sunrise)
                    PermissionsPage(viewModel: viewModel)
                        .tag(OnboardingPage.permissions)
                    WakeTimePage(wakeTime: vm.wakeTime)
                        .tag(OnboardingPage.wakeTime)
                    CompletePage()
                        .tag(OnboardingPage.complete)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                bottomButtons
            }
        }
        .onAppear {
            viewModel.trackPageView(.welcome)
        }
        .onChange(of: viewModel.currentPage) { _, page in
            viewModel.trackPageView(page)
        }
    }

    @ViewBuilder
    private var bottomButtons: some View {
        VStack(spacing: 12) {
            Button {
                if viewModel.isLastPage {
                    viewModel.trackCompleted()
                    saveAndComplete()
                } else {
                    viewModel.nextPage()
                }
            } label: {
                Text(viewModel.isLastPage ? "はじめる" : "次へ")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.indigo.gradient)
                    )
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 48)
        .animation(.spring(duration: 0.3), value: viewModel.currentPage)
    }

    private func saveAndComplete() {
        let setting = AlarmSetting(
            wakeTime: viewModel.wakeTime,
            isEnabled: true,
            repeatDays: [1, 2, 3, 4, 5]
        )
        modelContext.insert(setting)
        try? modelContext.save()
        onComplete()
    }
}

// MARK: - ページインジケーター

private struct PageIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Color.indigo : Color.white.opacity(0.2))
                    .frame(width: i == current ? 24 : 8, height: 8)
                    .animation(.spring(duration: 0.3), value: current)
            }
        }
    }
}

// MARK: - Page 1: ウェルカム

struct WelcomePage: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 80))
                .foregroundStyle(.indigo.gradient)
                .symbolEffect(.bounce, value: appeared)
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: 12) {
                Text("Slumber")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                Text("確実に起きられる\n気持ちいい目覚めを")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(.spring(duration: 0.5).delay(0.05), value: appeared)
            }

            VStack(spacing: 16) {
                FeatureRow(icon: "bed.double.fill",  text: "入眠をやさしくサポート",       delay: 0.1, appeared: appeared)
                FeatureRow(icon: "alarm.fill",        text: "サイレントでも確実に起こす",   delay: 0.2, appeared: appeared)
                FeatureRow(icon: "sun.horizon.fill",  text: "日の出に合わせた自然な目覚め", delay: 0.3, appeared: appeared)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(duration: 0.6)) { appeared = true }
        }
        .onDisappear { appeared = false }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String
    let delay: Double
    let appeared: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.indigo)
                .frame(width: 32)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
        }
        .padding(.horizontal, 8)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -20)
        .animation(.spring(duration: 0.5).delay(delay), value: appeared)
    }
}

// MARK: - Page 2: 体動検知

struct MotionDetectionPage: View {
    @State private var appeared = false
    @State private var waving = false

    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.indigo.opacity(0.3), lineWidth: 1.5)
                        .scaleEffect(waving ? 2.8 : 1)
                        .opacity(waving ? 0 : 0.6)
                        .animation(
                            .easeOut(duration: 1.8)
                                .delay(Double(i) * 0.6)
                                .repeatForever(autoreverses: false),
                            value: waving
                        )
                        .frame(width: 80, height: 80)
                }

                Image(systemName: "figure.sleep")
                    .font(.system(size: 52))
                    .foregroundStyle(.indigo.gradient)
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)
            }
            .frame(height: 130)

            VStack(spacing: 12) {
                Text("体動を検知して\n眠りを計測")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                Text("スマートフォンを枕元に置くだけで、\n眠りの深さをリアルタイムに検知。\n体動パターンから睡眠スコアを算出します。")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(.spring(duration: 0.5).delay(0.1), value: appeared)
            }
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(duration: 0.6)) { appeared = true }
            waving = true
        }
        .onDisappear {
            appeared = false
            waving = false
        }
    }
}

// MARK: - Page 3: 日の出

struct SunrisePage: View {
    @State private var appeared = false
    @State private var glowing = false

    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                ForEach(0..<8, id: \.self) { i in
                    Capsule()
                        .fill(Color.orange.opacity(glowing ? 0.35 : 0.05))
                        .frame(width: 4, height: 28)
                        .offset(y: -65)
                        .rotationEffect(.degrees(Double(i) * 45))
                        .animation(
                            .easeInOut(duration: 1.4)
                                .delay(Double(i) * 0.12)
                                .repeatForever(autoreverses: true),
                            value: glowing
                        )
                }

                Image(systemName: "sun.horizon.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                    )
                    .scaleEffect(appeared ? 1 : 0.4)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
            }
            .frame(height: 150)

            VStack(spacing: 12) {
                Text("日の出に合わせた\n自然な目覚め")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                Text("現在地の日の出時刻を自動計算。\n設定した起床時刻と組み合わせて、\n最も心地よいタイミングで起こします。")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(.spring(duration: 0.5).delay(0.1), value: appeared)
            }
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(duration: 0.7)) { appeared = true }
            glowing = true
        }
        .onDisappear {
            appeared = false
            glowing = false
        }
    }
}

// MARK: - Page 4: 権限

struct PermissionsPage: View {
    var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.indigo.gradient)

                Text("必要な権限")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("Slumber が正しく動くために\n以下の権限が必要です")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                PermissionRow(
                    icon: "bell.badge.fill",
                    title: "通知",
                    description: "就寝リマインダーとアラームに使います",
                    state: viewModel.notificationState
                ) {
                    Task { await viewModel.requestNotification() }
                }

                PermissionRow(
                    icon: "location.fill",
                    title: "位置情報",
                    description: "日の出時刻の取得に使います",
                    state: viewModel.locationState
                ) {
                    viewModel.requestLocation()
                }

                PermissionRow(
                    icon: "mic.fill",
                    title: "マイク",
                    description: "就寝中のいびきを検知するために使います",
                    state: viewModel.microphoneState
                ) {
                    Task { await viewModel.requestMicrophone() }
                }

                PermissionRow(
                    icon: "figure.walk.motion",
                    title: "体の動き",
                    description: "睡眠中の体動を検知して、起床タイミングの精度を高めます",
                    state: viewModel.motionState
                ) {
                    viewModel.requestMotion()
                }

                if viewModel.isHealthKitAvailable {
                    PermissionRow(
                        icon: "heart.fill",
                        title: "ヘルスケア",
                        description: "睡眠データをヘルスケアアプリに保存します",
                        state: viewModel.healthKitState
                    ) {
                        Task { await viewModel.requestHealthKit() }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 24)
    }
}

private struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let state: PermissionState
    let action: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.indigo)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Button(action: buttonAction) {
                Text(buttonText)
                    .font(.caption.bold())
                    .foregroundStyle(state == .authorized ? .white.opacity(0.5) : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(state == .authorized ? Color.white.opacity(0.1) : Color.indigo)
                    )
            }
            .disabled(state == .authorized)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.07))
        )
    }

    private var buttonText: String {
        switch state {
        case .notDetermined: return "続ける"
        case .authorized:    return "許可済み"
        case .denied:        return "設定を開く"
        }
    }

    /// denied の場合はシステムが再度ダイアログを出さないため、
    /// リクエストをやり直すのではなく設定アプリのアプリ設定画面へ誘導する。
    private func buttonAction() {
        guard state != .denied else {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            return
        }
        action()
    }
}

// MARK: - Page 5: 起床時刻

struct WakeTimePage: View {
    @Binding var wakeTime: Date

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "alarm.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.indigo.gradient)

                Text("起床時刻を設定")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("後からいつでも変更できます")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }

            DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Page 6: 完了

struct CompletePage: View {
    @State private var appeared = false
    @State private var sparkle = false

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundStyle(.indigo.gradient)
                .symbolEffect(.pulse, isActive: sparkle)
                .scaleEffect(appeared ? 1 : 0.3)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: 12) {
                Text("準備完了！")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                Text("今夜から睡眠資産を\n積み上げよう")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(.spring(duration: 0.5).delay(0.05), value: appeared)
            }

            VStack(spacing: 10) {
                UsageTip(icon: "moon.fill",    text: "就寝前に「就寝する」をタップ",       delay: 0.15, appeared: appeared)
                UsageTip(icon: "iphone",       text: "スマホを枕元に置いて寝るだけ",       delay: 0.25, appeared: appeared)
                UsageTip(icon: "sun.max.fill", text: "アラームが最適なタイミングで起こします", delay: 0.35, appeared: appeared)
            }
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(duration: 0.6)) { appeared = true }
            sparkle = true
        }
        .onDisappear {
            appeared = false
            sparkle = false
        }
    }
}

private struct UsageTip: View {
    let icon: String
    let text: String
    let delay: Double
    let appeared: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.indigo)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.07))
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .animation(.spring(duration: 0.5).delay(delay), value: appeared)
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .modelContainer(for: AlarmSetting.self, inMemory: true)
}
