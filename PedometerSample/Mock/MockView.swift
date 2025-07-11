//
//  MockView.swift
//  PedometerSample
//
//  Created by cmStudent on 2025/07/07.
//

import SwiftUI

struct PedometerDisplayData {
    let message: String
    let startDate: Date
    let endDate: Date
    let steps: Int
    let distance: Double
    let kcal: Double?
    let floorsAscended: Int
    let floorsDescended: Int
}

struct MockData {
    static let pedometer: PedometerDisplayData = PedometerDisplayData(
        message: "Mockデータです",
        startDate: Date().addingTimeInterval(-3600),
        endDate: Date(),
        steps: 117,
        distance: 123.0,
        kcal: 5.2,
        floorsAscended: 2,
        floorsDescended: 3
    )
}

struct MockView: View {
    let data: PedometerDisplayData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 状态消息
            Text(data.message)
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.headline)
                .fontWeight(.bold)
                .padding(.vertical, 8)
            
            // 时间信息
            Section(header: Text("計測時間").font(.subheadline).foregroundColor(.secondary)) {
                HStack {
                    Text("開始:")
                        .foregroundColor(.secondary)
                    Text(dateString(data.startDate))
                        .fontWeight(.medium)
                }
                HStack {
                    Text("終了:")
                        .foregroundColor(.secondary)
                    Text(dateString(data.endDate))
                        .fontWeight(.medium)
                }
            }
            Divider()
            
            // 歩数・距離・カロリー
            Section(header: Text("運動データ").font(.subheadline).foregroundColor(.secondary)) {
                HStack {
                    Text("歩数")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(data.steps)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                HStack {
                    Text("距離")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.2f m", data.distance))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                HStack {
                    Text("消費カロリー")
                        .foregroundColor(.secondary)
                    Spacer()
                    if let kcal = data.kcal {
                        Text(String(format: "%.2f kcal", kcal))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    } else {
                        Text("0.00 kcal")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                    }
                }
            }
            Divider()
            
            // 階段データ
            Section(header: Text("階段データ").font(.subheadline).foregroundColor(.secondary)) {
                HStack {
                    Text("登った階数")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(data.floorsAscended)")
                        .fontWeight(.medium)
                }
                HStack {
                    Text("下った階数")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(data.floorsDescended)")
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .gray.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .padding()
    }
    
    func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    MockView(data: MockData.pedometer)
}
