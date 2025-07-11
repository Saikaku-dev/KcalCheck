//
//  ContentView.swift
//  PedometerSample
//
//  Created by cmStudent on 2025/07/07.
//

import SwiftUI

struct ContentView: View {
    @StateObject var vm = ContentViewModel()
    @State private var isStarted: Bool = false
    
    var body: some View {
        Button(isStarted ? "終了" : "開始") {
            isStarted.toggle()
            if isStarted {
                vm.start()
            } else {
                vm.stop()
            }
        }
        
        Divider()
        
        if let data = vm.data {
            VStack {
                Text(vm.message)
                
                Group {
                    Text("開始日時")
                    Text(data.startDate.description)
                    Text("終了日時")
                    Text(data.endDate.description)
                    Divider()
                }
                
                Group {
                    Text("歩数")
                    Text("\(data.numberOfSteps)")
                    Text("距離")
                    Text("\(data.distance ?? 0)")
                    Divider()
                    
                    // TODO: - カロリー計算
                    Text("消耗したカロリー")
                }
                
                Group {
                    Text("平均秒速")
                    Text("\(data.averageActivePace ?? 0)")
                    Text("現在秒速")
                    Text("\(data.currentPace ?? 0)")
                    Text("ケイデンス")
                    Text("\(data.currentCadence ?? 0)")
                    Divider()
                }
                
                Group {
                    Text("階段を登った階数")
                    Text("\(data.floorsAscended ?? 0)")
                    Text("階段を下った階数")
                    Text("\(data.floorsDescended ?? 0)")
                    Divider()
                }
                
            }
        } else {
            Text("データなし")
        }
    }
}

#Preview {
    ContentView()
}
