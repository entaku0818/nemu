//
//  nemuUITests.swift
//  nemuUITests
//
//  Created by 遠藤拓弥 on 2026/03/08.
//

import XCTest

final class nemuUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    // MARK: - App Store Screenshots

    @MainActor
    func testCaptureScreenshots() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_SCREENSHOT_MODE"]
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "01_home"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Navigate to Report tab
        let reportTab = app.tabBars.buttons["レポート"]
        if reportTab.exists {
            reportTab.tap()
            sleep(1)
            let reportAttachment = XCTAttachment(screenshot: app.screenshot())
            reportAttachment.name = "02_report"
            reportAttachment.lifetime = .keepAlways
            add(reportAttachment)
        }

        // Go back to home and tap 就寝する
        let homeTab = app.tabBars.buttons["ホーム"]
        if homeTab.exists {
            homeTab.tap()
            sleep(1)
        }

        let sleepButton = app.buttons["就寝する"]
        if sleepButton.exists {
            // Handle system permission dialogs via interruption monitor
            addUIInterruptionMonitor(withDescription: "Permission dialog") { alert in
                let allowBtn = alert.buttons["許可"]
                if allowBtn.exists { allowBtn.tap(); return true }
                let okBtn = alert.buttons["OK"]
                if okBtn.exists { okBtn.tap(); return true }
                return false
            }
            sleepButton.tap()
            sleep(3)
            // Interact with app to trigger interruption handler
            app.tap()
            sleep(2)
            let bedtimeAttachment = XCTAttachment(screenshot: app.screenshot())
            bedtimeAttachment.name = "03_bedtime"
            bedtimeAttachment.lifetime = .keepAlways
            add(bedtimeAttachment)
        }
    }
}
