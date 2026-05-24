//
//  nemuApp.swift
//  nemu
//
//  Created by 遠藤拓弥 on 2026/03/08.
//

import SwiftUI
import SwiftData
import GoogleMobileAds
import FirebaseCore
import FirebaseCrashlytics

@main
struct nemuApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        FirebaseApp.configure()
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        PurchaseService.shared.configure(apiKey: "appl_iVuNDjtHBbFeIYSwAtqapteaYkb")
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
