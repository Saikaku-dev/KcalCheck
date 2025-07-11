//
//  HistoryView.swift
//  PedometerSample
//
//  Created by cmStudent on 2025/07/08.
//

import SwiftUI
import SwiftData

@Model
final class HistoryItem {
    var id: UUID
    var date: String
    var kcal: Double

    init(date: String, kcal: Double) {
        self.id = UUID()
        self.date = date
        self.kcal = kcal
    }
}


class HistoryViewModel: ObservableObject {
    
    
}

struct HistoryView: View {
    
    var body: some View {
        
    }
}

#Preview {
    HistoryView()
}
