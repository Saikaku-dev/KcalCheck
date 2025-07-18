//
//  PedometerSampleApp.swift
//  PedometerSample
//
//  Created by cmStudent on 2025/07/07.
//

import SwiftUI
import SwiftData

@main
struct PedometerSampleApp: App {
    @State private var hasValidUser: Bool = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if CurrentUser.shared.user != nil {
                    MainTabView()
                } else {
                    EntryView()
                }
            }
        }
        .modelContainer(for: [HistoryItem.self, Goal.self])
    }
}
