//
//  GoalView.swift
//  PedometerSample
//
//  Created by cmStudent on 2025/07/08.
//

import SwiftUI
import SwiftData

struct GoalView: View {
    @StateObject private var viewModel = GoalViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HistoryItem.date, order: .reverse) private var historyItems: [HistoryItem]
    @Query(sort: \Goal.createdAt, order: .reverse) private var goals: [Goal]
    
    @State private var showingAddGoalSheet = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if goals.isEmpty {
                    ContentUnavailableView("目標が設定されていません", systemImage: "flag.fill", description: Text("右上の+ボタンから新しい目標を設定できます"))
                } else {
                    List {
                        ForEach(goals.filter { $0.isActive }) { goal in
                            NavigationLink(destination: GoalDetailView(goal: goal, historyItems: historyItems)) {
                                GoalRowView(goal: goal, historyItems: historyItems, viewModel: viewModel)
                            }
                        }
                        
                        if !goals.filter({ !$0.isActive }).isEmpty {
                            Section("過去の目標") {
                                ForEach(goals.filter { !$0.isActive }) { goal in
                                    NavigationLink(destination: GoalDetailView(goal: goal, historyItems: historyItems)) {
                                        GoalRowView(goal: goal, historyItems: historyItems, viewModel: viewModel)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("目標")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddGoalSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGoalSheet) {
                AddGoalView(viewModel: viewModel)
            }
        }
    }
}

struct GoalRowView: View {
    let goal: Goal
    let historyItems: [HistoryItem]
    let viewModel: GoalViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: goalIcon)
                    .foregroundColor(goalColor)
                Text(goal.targetType.displayName)
                    .font(.headline)
                Spacer()
                Text(goal.isActive ? "アクティブ" : "完了")
                    .font(.caption)
                    .padding(4)
                    .background(goal.isActive ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text("目標: \(Int(goal.targetValue)) \(unitString)")
                .font(.subheadline)
            
            Text("期間: \(goal.periodType.displayName)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 進捗バー
            ProgressView(value: viewModel.calculateProgress(goal: goal, historyItems: historyItems))
                .progressViewStyle(LinearProgressViewStyle(tint: goalColor))
                .padding(.top, 4)
            
            // 進捗率
            HStack {
                let progress = viewModel.calculateProgress(goal: goal, historyItems: historyItems)
                Text("\(Int(progress * 100))% 達成")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 現在の値
                let currentValue = getCurrentValue(for: goal.targetType)
                Text("現在: \(Int(currentValue)) \(unitString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    // 目標タイプに基づいたアイコンを取得
    private var goalIcon: String {
        switch goal.targetType {
        case .steps:
            return "figure.walk"
        case .distance:
            return "map"
        case .calories:
            return "flame.fill"
        }
    }
    
    // 目標タイプに基づいた色を取得
    private var goalColor: Color {
        switch goal.targetType {
        case .steps:
            return .blue
        case .distance:
            return .green
        case .calories:
            return .orange
        }
    }
    
    // 単位文字列を取得
    private var unitString: String {
        switch goal.targetType {
        case .steps:
            return "歩"
        case .distance:
            return "km"
        case .calories:
            return "kcal"
        }
    }
    
    // 現在の値を取得
    private func getCurrentValue(for targetType: TargetType) -> Double {
        // 期間に基づいて関連する履歴アイテムをフィルタリング
        let relevantItems = filterHistoryItemsByPeriod(historyItems, for: goal.periodType)
        
        switch targetType {
        case .steps:
            return Double(relevantItems.reduce(0) { $0 + $1.steps })
        case .distance:
            return relevantItems.reduce(0) { $0 + $1.distance }
        case .calories:
            return relevantItems.reduce(0) { $0 + $1.kcal }
        }
    }
    
    // 期間に基づいて履歴アイテムをフィルタリングする
    private func filterHistoryItemsByPeriod(_ items: [HistoryItem], for periodType: PeriodType) -> [HistoryItem] {
        let calendar = Calendar.current
        let now = Date()
        
        return items.filter { item in
            // 日付文字列をDateに変換
            guard let itemDate = dateFromString(item.date) else { return false }
            
            switch periodType {
            case .daily:
                // 今日のアイテムのみ
                return calendar.isDateInToday(itemDate)
            case .weekly:
                // 今週のアイテムのみ
                return calendar.isDate(itemDate, equalTo: now, toGranularity: .weekOfYear)
            case .monthly:
                // 今月のアイテムのみ
                return calendar.isDate(itemDate, equalTo: now, toGranularity: .month)
            }
        }
    }
    
    // 日付文字列をDateに変換するヘルパーメソッド
    private func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}

struct AddGoalView: View {
    @ObservedObject var viewModel: GoalViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("目標タイプ")) {
                    Picker("目標タイプ", selection: $viewModel.selectedTargetType) {
                        Text("歩数").tag(TargetType.steps)
                        Text("距離 (km)").tag(TargetType.distance)
                        Text("カロリー (kcal)").tag(TargetType.calories)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("目標値")) {
                    TextField("目標値を入力", text: $viewModel.targetValue)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("期間")) {
                    Picker("期間", selection: $viewModel.selectedPeriodType) {
                        Text("毎日").tag(PeriodType.daily)
                        Text("毎週").tag(PeriodType.weekly)
                        Text("毎月").tag(PeriodType.monthly)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("新しい目標を設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        // 入力値の検証
                        guard let value = Double(viewModel.targetValue), value > 0 else {
                            viewModel.alertMessage = "有効な目標値を入力してください"
                            viewModel.showAlert = true
                            return
                        }
                        
                        // 同じタイプのアクティブな目標を非アクティブにする
                        for goal in viewModel.goals where goal.targetType == viewModel.selectedTargetType && goal.isActive {
                            goal.isActive = false
                        }
                        
                        // 新しい目標を作成して保存
                        let newGoal = Goal(targetType: viewModel.selectedTargetType, 
                                          targetValue: value, 
                                          periodType: viewModel.selectedPeriodType)
                        modelContext.insert(newGoal)
                        
                        // 入力フィールドをリセット
                        viewModel.targetValue = ""
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("エラー"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}

#Preview {
    GoalView()
        .modelContainer(for: [HistoryItem.self, Goal.self])
}