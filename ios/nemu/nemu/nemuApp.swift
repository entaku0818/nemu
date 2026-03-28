//
//  nemuApp.swift
//  nemu
//
//  Created by 遠藤拓弥 on 2026/03/08.
//

import SwiftUI
import SwiftData
import GoogleMobileAds

@main
struct nemuApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        // TODO: RevenueCat SPM追加後、ダッシュボードで取得した API キーを設定する
        // PurchaseService.shared.configure(apiKey: "YOUR_REVENUECAT_API_KEY")
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .modelContainer(for: [AlarmSetting.self, SleepSession.self])
    }
}
