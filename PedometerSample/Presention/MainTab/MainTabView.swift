//
//  MainTabView.swift
//  PedometerSample
//
//  Created by cmStudent on 2025/07/08.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            HistoryView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("History")
                }
            GoalView()
                .tabItem {
                    Image(systemName: "flag.fill")
                    Text("目標")
                }
            StatsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("統計")
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [HistoryItem.self, Goal.self])
}
