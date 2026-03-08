//
//  OnboardingView.swift
//  nemu
//

import SwiftUI
import SwiftData
import CoreLocation

struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.modelContext) private var modelContext
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.12).ignoresSafeArea()

            VStack {
                // ページインジケーター
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(i == viewModel.currentPage ? Color.indigo : Color.white.opacity(0.2))
                            .frame(width: i == viewModel.currentPage ? 24 : 8, height: 8)
                            .animation(.spring(duration: 0.3), value: viewModel.currentPage)
                    }
                }
                .padding(.top, 60)

                Spacer()

                // ページコンテンツ
                switch viewModel.currentPage {
                case 0: WelcomePage()
                case 1: PermissionsPage(viewModel: viewModel)
                case 2: WakeTimePage(wakeTime: $viewModel.wakeTime)
                default: EmptyView()
                }

                Spacer()

                // ボタン
                Button {
                    if viewModel.isLastPage {
                        saveAndComplete()
                    } else {
                        withAnimation(.spring(duration: 0.4)) {
                            viewModel.nextPage()
                        }
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
                .padding(.bottom, 48)
            }
        }
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

// MARK: - Page 1: ウェルカム

struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 80))
                .foregroundStyle(.indigo.gradient)

            VStack(spacing: 12) {
                Text("ねむ")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)

                Text("確実に起きられる\n気持ちいい目覚めを")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                FeatureRow(icon: "bed.double.fill",    text: "入眠をやさしくサポート")
                FeatureRow(icon: "alarm.fill",         text: "サイレントでも確実に起こす")
                FeatureRow(icon: "sun.horizon.fill",   text: "日の出に合わせた自然な目覚め")
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 32)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

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
    }
}

// MARK: - Page 2: 権限

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

                Text("ねむが正しく動くために\n以下の権限が必要です")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                PermissionRow(
                    icon: "bell.badge.fill",
                    title: "通知",
                    description: "就寝リマインダーとアラームに使います",
                    status: viewModel.notificationStatus == .authorized
                ) {
                    Task { await viewModel.requestNotification() }
                }

                PermissionRow(
                    icon: "location.fill",
                    title: "位置情報",
                    description: "日の出時刻の取得に使います",
                    status: viewModel.locationStatus == .authorizedWhenInUse ||
                            viewModel.locationStatus == .authorizedAlways
                ) {
                    viewModel.requestLocation()
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 24)
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let status: Bool
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

            Button(action: action) {
                Text(status ? "許可済み" : "許可する")
                    .font(.caption.bold())
                    .foregroundStyle(status ? .white.opacity(0.5) : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(status ? Color.white.opacity(0.1) : Color.indigo)
                    )
            }
            .disabled(status)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.07))
        )
    }
}

// MARK: - Page 3: 起床時刻

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

#Preview {
    OnboardingView(onComplete: {})
        .modelContainer(for: AlarmSetting.self, inMemory: true)
}
