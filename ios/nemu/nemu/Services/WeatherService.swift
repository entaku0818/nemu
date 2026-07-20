//
//  WeatherService.swift
//  nemu
//
//  起床後レポート用の天気取得（WeatherKit + CoreLocation）
//  プレミアム限定機能のため、位置情報の許可は ReportView 表示時にオンデマンドで要求する。
//

import Foundation
import CoreLocation
import WeatherKit
import Observation
import UIKit

enum WeatherPermissionState {
    case notDetermined
    case authorized
    case denied
}

@Observable
@MainActor
final class WeatherService: NSObject {
    static let shared = WeatherService()

    private(set) var conditionLabel: String?
    private(set) var temperature: Int?
    private(set) var precipitationAdvice: String?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var locationStatus: CLAuthorizationStatus

    var permissionState: WeatherPermissionState {
        switch locationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return .authorized
        case .denied, .restricted: return .denied
        default: return .notDetermined
        }
    }

    private let locationManager = CLLocationManager()
    private let weatherKitService = WeatherKit.WeatherService.shared

    private override init() {
        locationStatus = CLLocationManager().authorizationStatus
        super.init()
        locationManager.delegate = self
    }

    /// 位置情報が未許可ならリクエスト、許可済みなら現在地の天気を取得する
    func requestWeather() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            break
        }
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func fetchWeather(for location: CLLocation) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let weather = try await weatherKitService.weather(for: location)
            let current = weather.currentWeather
            conditionLabel = Self.japaneseLabel(for: current.condition)
            temperature = Int(current.temperature.converted(to: .celsius).value.rounded())
            let chance = weather.dailyForecast.forecast.first?.precipitationChance ?? 0
            precipitationAdvice = Self.precipitationAdvice(chance: chance)
        } catch {
            errorMessage = "天気情報を取得できませんでした"
        }
    }

    // MARK: - 純粋関数（テスト対象）

    nonisolated static func japaneseLabel(for condition: WeatherCondition) -> String {
        switch condition {
        case .clear, .mostlyClear:
            return "晴れ"
        case .partlyCloudy:
            return "晴れ時々曇り"
        case .cloudy, .mostlyCloudy:
            return "曇り"
        case .foggy, .haze, .smoky:
            return "霧"
        case .drizzle, .sunShowers:
            return "小雨"
        case .rain, .heavyRain, .freezingRain, .freezingDrizzle:
            return "雨"
        case .snow, .heavySnow, .flurries, .sunFlurries, .sleet, .wintryMix, .blizzard, .blowingSnow:
            return "雪"
        case .thunderstorms, .strongStorms, .isolatedThunderstorms, .scatteredThunderstorms, .hurricane, .tropicalStorm:
            return "雷雨"
        case .hot:
            return "猛暑"
        case .frigid, .blowingDust:
            return "強風"
        case .windy, .breezy:
            return "風が強い"
        default:
            return "曇り"
        }
    }

    nonisolated static func precipitationAdvice(chance: Double) -> String {
        chance >= 0.4 ? "傘があると安心です" : "傘は不要です"
    }
}

// MARK: - CLLocationManagerDelegate

extension WeatherService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        Task { @MainActor in
            await self.fetchWeather(for: location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = "天気情報を取得できませんでした"
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.locationStatus = manager.authorizationStatus
            if self.permissionState == .authorized {
                manager.requestLocation()
            }
        }
    }
}
