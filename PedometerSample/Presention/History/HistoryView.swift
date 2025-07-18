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
    var userName: String
    var steps: Int
    var distance: Double
    var startTime: String
    var endTime: String

    init(date: String, kcal: Double, userName: String, steps: Int, distance: Double, startTime: String, endTime: String) {
        self.id = UUID()
        self.date = date
        self.kcal = kcal
        self.userName = userName
        self.steps = steps
        self.distance = distance
        self.startTime = startTime
        self.endTime = endTime
    }
}

class HistoryViewModel: ObservableObject {
    @Published var historyItems: [HistoryItem] = []
    
    func fetchHistoryItems(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<HistoryItem>(sortBy: [SortDescriptor(\HistoryItem.date, order: .reverse)])
        do {
            historyItems = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching history items: \(error)")
        }
    }
}

struct HistoryDetailView: View {
    let historyItem: HistoryItem
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // ユーザー情報
                HStack {
                    Text(historyItem.userName)
                        .font(.title)
                        .foregroundColor(.red)
                    Text("さんの運動記録")
                        .font(.title2)
                }
                .padding(.bottom, 10)
                
                // 基本情報
                VStack(alignment: .leading, spacing: 12) {
                    Group {
                        HStack {
                            Text("日付:")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(historyItem.date)
                                .font(.title3)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("開始時間:")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(historyItem.startTime)
                                .font(.body)
                        }
                        
                        HStack {
                            Text("終了時間:")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(historyItem.endTime)
                                .font(.body)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                )
                
                // 運動データ
                VStack(alignment: .leading, spacing: 12) {
                    Text("運動データ")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    HStack(spacing: 15) {
                        // 歩数
                        VStack {
                            Text("\(historyItem.steps)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("歩数")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                        )
                        
                        // 距離
                        VStack {
                            Text(String(format: "%.1f m", historyItem.distance))
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("距離")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.1))
                        )
                        
                        // カロリー
                        VStack {
                            Text(String(format: "%.1f", historyItem.kcal))
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("カロリー")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                }
                
                // 効果
                VStack(alignment: .leading, spacing: 12) {
                    Text("健康効果")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("・有酸素運動として心肺機能の向上")
                            .font(.subheadline)
                        Text("・下半身の筋力強化")
                            .font(.subheadline)
                        Text("・消費カロリー: \(String(format: "%.2f kcal", historyItem.kcal))")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.yellow.opacity(0.1))
                    )
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("運動詳細")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HistoryItem.date, order: .reverse) private var historyItems: [HistoryItem]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(historyItems) { item in
                    NavigationLink(destination: HistoryDetailView(historyItem: item)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.date)
                                    .font(.headline)
                            }
                            Spacer()
                            Text(String(format: "%.1f kcal", item.kcal))
                                .foregroundColor(.orange)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("運動履歴")
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [HistoryItem.self, Goal.self])
}
