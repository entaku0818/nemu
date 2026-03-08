//
//  nemuApp.swift
//  nemu
//
//  Created by 遠藤拓弥 on 2026/03/08.
//

import SwiftUI
import SwiftData

@main
struct nemuApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .modelContainer(for: AlarmSetting.self)
    }
}
