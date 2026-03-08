//
//  ContentView.swift (MainTabView)
//  nemu
//
//  Created by 遠藤拓弥 on 2026/03/08.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "moon.stars.fill")
                }

            ReportView()
                .tabItem {
                    Label("レポート", systemImage: "chart.bar.fill")
                }
        }
        .tint(.indigo)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
}
