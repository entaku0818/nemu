//
//  WeatherCard.swift
//  nemu
//
//  起床後レポートのプレミアム限定カード：今日の天気・気温を表示する
//

import SwiftUI

struct WeatherCard: View {
    @State private var weatherService = WeatherService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日の天気")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .tracking(2)

            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.07))
        )
        .padding(.horizontal)
        .onAppear {
            if weatherService.permissionState == .authorized {
                weatherService.requestWeather()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch weatherService.permissionState {
        case .notDetermined:
            permissionPrompt(
                message: "天気を表示するには位置情報が必要です",
                buttonTitle: "位置情報を許可",
                action: { weatherService.requestWeather() }
            )
        case .denied:
            permissionPrompt(
                message: "位置情報が許可されていません。設定から許可してください",
                buttonTitle: "設定を開く",
                action: { weatherService.openSettings() }
            )
        case .authorized:
            if weatherService.isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if let message = weatherService.errorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            } else if let conditionLabel = weatherService.conditionLabel, let temperature = weatherService.temperature {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(conditionLabel) \(temperature)℃")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        if let advice = weatherService.precipitationAdvice {
                            Text(advice)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    Spacer()
                }
            } else {
                Text("天気情報を取得中です")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    private func permissionPrompt(message: String, buttonTitle: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(message)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
            Button(action: action) {
                Text(buttonTitle)
                    .font(.caption.bold())
                    .foregroundStyle(Color.assetGold)
            }
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.06, green: 0.06, blue: 0.12).ignoresSafeArea()
        WeatherCard()
    }
}
