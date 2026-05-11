//
//  ScreenshotRenderTests.swift
//  nemuTests
//
// ImageRenderer で App Store 用スクリーンショットを生成する。
// 出力先: /tmp/nemu_screenshots/{lang}_{n}_{screen}.png
// 実行: xcodebuild test -only-testing:nemuTests/ScreenshotRenderTests
//

import XCTest
import SwiftUI
@testable import nemu

@MainActor
final class ScreenshotRenderTests: XCTestCase {

    // iPhone 15 Plus / 16 Pro Max: 430x932pt @3x = 1290x2796px
    private let width: CGFloat = 430
    private let height: CGFloat = 932
    private let scale: CGFloat = 3.0

    private let outputDir = URL(fileURLWithPath: "/tmp/nemu_screenshots")

    override func setUp() {
        super.setUp()
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
    }

    func testGenerateScreenshots() throws {
        let languages: [(NemuLanguage, String)] = [
            (.japanese, "ja"),
            (.english,  "en")
        ]

        let screens: [(NemuScreenshotScreen, String)] = [
            (.home,      "00_home"),
            (.bedtime,   "01_bedtime"),
            (.wakeScore, "02_score"),
            (.report,    "03_report"),
            (.paywall,   "04_paywall")
        ]

        for (language, langCode) in languages {
            for (screen, screenName) in screens {
                let view = makeView(screen: screen, language: language)
                let filename = "\(langCode)_\(screenName).png"
                try render(view: view, filename: filename)
            }
        }
    }

    // MARK: -

    @ViewBuilder
    private func makeView(screen: NemuScreenshotScreen, language: NemuLanguage) -> some View {
        AppStoreScreenshotView(
            title: screen.title(language: language),
            subtitle: screen.subtitle(language: language),
            background: screen.background
        ) {
            switch screen {
            case .home:      MockNemuHomeView(language: language)
            case .bedtime:   MockBedtimeView(language: language)
            case .wakeScore: MockWakeScoreView(language: language)
            case .report:    MockNemuReportView(language: language)
            case .paywall:   MockNemuPaywallView(language: language)
            }
        }
    }

    private func render<V: View>(view: V, filename: String) throws {
        let renderer = ImageRenderer(
            content: view.frame(width: width, height: height)
        )
        renderer.proposedSize = ProposedViewSize(width: width, height: height)
        renderer.scale = scale

        guard let uiImage = renderer.uiImage,
              let pngData = uiImage.pngData() else {
            XCTFail("描画失敗: \(filename)"); return
        }

        let fileURL = outputDir.appendingPathComponent(filename)
        try pngData.write(to: fileURL)
        let w = Int(uiImage.size.width * scale)
        let h = Int(uiImage.size.height * scale)
        print("✓ \(filename): \(w)x\(h)px")
    }
}
