//
//  GoalViewModel.swift
//  PedometerSample
//
//  Created by cmStudent on 2025/07/08.
//

import Foundation
import SwiftData
import SwiftUI

class GoalViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var selectedTargetType: TargetType = .steps
    @Published var targetValue: String = ""
    @Published var selectedPeriodType: PeriodType = .daily
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    
    // 目標を取得する
    func fetchGoals(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Goal>(sortBy: [SortDescriptor(\Goal.createdAt, order: .reverse)])
        do {
            goals = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching goals: \(error)")
        }
    }
    
    // アクティブな目標を取得する
    func getActiveGoal(for targetType: TargetType) -> Goal? {
        return goals.first(where: { $0.targetType == targetType && $0.isActive })
    }
    
    // 新しい目標を追加する
    func addGoal(modelContext: ModelContext) {
        guard let value = Double(targetValue), value > 0 else {
            alertMessage = "有効な目標値を入力してください"
            showAlert = true
            return
        }
        
        // 同じタイプのアクティブな目標が既に存在する場合は非アクティブにする
        if let existingGoal = getActiveGoal(for: selectedTargetType) {
            existingGoal.isActive = false
            // 既存の目標を非アクティブにする場合は、明示的なsave()呼び出しは不要
        // SwiftDataは自動的に変更を追跡します
        }
        
        // 新しい目標を作成
        let newGoal = Goal(targetType: selectedTargetType, targetValue: value, periodType: selectedPeriodType)
        
        // SwiftDataに保存
        modelContext.insert(newGoal)
        
        // 入力フィールドをリセット
        targetValue = ""
        // 目標リストを更新
        fetchGoals(modelContext: modelContext)
    }
    
    // 目標の進捗状況を計算する
    func calculateProgress(goal: Goal, historyItems: [HistoryItem]) -> Double {
        // 期間に基づいて関連する履歴アイテムをフィルタリング
        let relevantItems = filterHistoryItemsByPeriod(historyItems, for: goal.periodType)
        
        // 目標タイプに基づいて合計値を計算
        var totalValue: Double = 0
        
        switch goal.targetType {
        case .steps:
            totalValue = Double(relevantItems.reduce(0) { $0 + $1.steps })
        case .distance:
            totalValue = relevantItems.reduce(0) { $0 + $1.distance }
        case .calories:
            totalValue = relevantItems.reduce(0) { $0 + $1.kcal }
        }
        
        // 進捗率を計算（0.0〜1.0）
        let progress = min(totalValue / goal.targetValue, 1.0)
        return progress
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