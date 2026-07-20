//
//  WeatherServiceTests.swift
//  nemuTests
//

import Testing
import WeatherKit
@testable import nemu

struct WeatherServiceTests {

    @Test("晴れ系は「晴れ」と表示")
    func clearConditions() {
        #expect(WeatherService.japaneseLabel(for: .clear) == "晴れ")
        #expect(WeatherService.japaneseLabel(for: .mostlyClear) == "晴れ")
    }

    @Test("雨系は「雨」と表示")
    func rainConditions() {
        #expect(WeatherService.japaneseLabel(for: .rain) == "雨")
        #expect(WeatherService.japaneseLabel(for: .heavyRain) == "雨")
    }

    @Test("雪系は「雪」と表示")
    func snowConditions() {
        #expect(WeatherService.japaneseLabel(for: .snow) == "雪")
    }

    @Test("雷雨系は「雷雨」と表示")
    func thunderstormConditions() {
        #expect(WeatherService.japaneseLabel(for: .thunderstorms) == "雷雨")
    }

    @Test("降水確率40%未満は傘不要")
    func lowPrecipitationAdvice() {
        #expect(WeatherService.precipitationAdvice(chance: 0.1) == "傘は不要です")
    }

    @Test("降水確率40%以上は傘を推奨")
    func highPrecipitationAdvice() {
        #expect(WeatherService.precipitationAdvice(chance: 0.4) == "傘があると安心です")
        #expect(WeatherService.precipitationAdvice(chance: 0.8) == "傘があると安心です")
    }
}
