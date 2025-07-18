//
//  StatsViewModel.swift
//  PedometerSample
//
//  Created by cmStudent on 2025/07/08.
//

import Foundation
import SwiftData
import SwiftUI

class StatsViewModel: ObservableObject {
    @Published var selectedTimeRange: TimeRange = .week
    @Published var selectedDataType: DataType = .steps
    
    // 統計データ
    @Published var totalSteps: Int = 0
    @Published var totalDistance: Double = 0
    @Published var totalCalories: Double = 0
    @Published var averageStepsPerDay: Int = 0
    @Published var averageDistancePerDay: Double = 0
    @Published var averageCaloriesPerDay: Double = 0
    @Published var maxStepsInOneDay: Int = 0
    @Published var maxDistanceInOneDay: Double = 0
    @Published var maxCaloriesInOneDay: Double = 0
    
    // チャートデータ
    @Published var chartData: [(date: String, value: Double)] = []
    
    // 統計データを計算する
    func calculateStats(historyItems: [HistoryItem]) {
        // 選択された期間に基づいて履歴アイテムをフィルタリング
        let filteredItems = filterHistoryItemsByTimeRange(historyItems)
        
        // 日付ごとにグループ化
        let groupedByDate = Dictionary(grouping: filteredItems) { $0.date }
        
        // 合計値を計算
        totalSteps = filteredItems.reduce(0) { $0 + $1.steps }
        totalDistance = filteredItems.reduce(0) { $0 + $1.distance }
        totalCalories = filteredItems.reduce(0) { $0 + $1.kcal }
        
        // 日数（データがある日のみ）
        let daysWithData = groupedByDate.count
        
        // 平均値を計算（データがある場合のみ）
        if daysWithData > 0 {
            averageStepsPerDay = totalSteps / daysWithData
            averageDistancePerDay = totalDistance / Double(daysWithData)
            averageCaloriesPerDay = totalCalories / Double(daysWithData)
        } else {
            averageStepsPerDay = 0
            averageDistancePerDay = 0
            averageCaloriesPerDay = 0
        }
        
        // 1日あたりの最大値を計算
        maxStepsInOneDay = groupedByDate.values.map { items in
            items.reduce(0) { $0 + $1.steps }
        }.max() ?? 0
        
        maxDistanceInOneDay = groupedByDate.values.map { items in
            items.reduce(0) { $0 + $1.distance }
        }.max() ?? 0
        
        maxCaloriesInOneDay = groupedByDate.values.map { items in
            items.reduce(0) { $0 + $1.kcal }
        }.max() ?? 0
        
        // チャートデータを生成
        generateChartData(groupedByDate: groupedByDate)
    }
    
    // チャートデータを生成する
    private func generateChartData(groupedByDate: [String: [HistoryItem]]) {
        let sortedDates = groupedByDate.keys.sorted()
        
        // 選択されたデータタイプに基づいてチャートデータを生成
        chartData = sortedDates.map { date in
            let items = groupedByDate[date] ?? []
            let value: Double
            
            switch selectedDataType {
            case .steps:
                value = Double(items.reduce(0) { $0 + $1.steps })
            case .distance:
                value = items.reduce(0) { $0 + $1.distance }
            case .calories:
                value = items.reduce(0) { $0 + $1.kcal }
            }
            
            return (date: formatDateForChart(date), value: value)
        }
    }
    
    // チャート表示用に日付をフォーマットする
    private func formatDateForChart(_ dateString: String) -> String {
        guard let date = dateFromString(dateString) else { return dateString }
        
        let formatter = DateFormatter()
        
        switch selectedTimeRange {
        case .week, .month:
            formatter.dateFormat = "MM/dd"
        case .year:
            formatter.dateFormat = "yyyy/MM"
        }
        
        return formatter.string(from: date)
    }
    
    // 選択された期間に基づいて履歴アイテムをフィルタリングする
    private func filterHistoryItemsByTimeRange(_ items: [HistoryItem]) -> [HistoryItem] {
        let calendar = Calendar.current
        let now = Date()
        
        return items.filter { item in
            // 日付文字列をDateに変換
            guard let itemDate = dateFromString(item.date) else { return false }
            
            switch selectedTimeRange {
            case .week:
                // 過去7日間のデータ
                if let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) {
                    return itemDate >= sevenDaysAgo && itemDate <= now
                }
            case .month:
                // 過去30日間のデータ
                if let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) {
                    return itemDate >= thirtyDaysAgo && itemDate <= now
                }
            case .year:
                // 過去365日間のデータ
                if let oneYearAgo = calendar.date(byAdding: .day, value: -365, to: now) {
                    return itemDate >= oneYearAgo && itemDate <= now
                }
            }
            
            return false
        }
    }
    
    // 日付文字列をDateに変換するヘルパーメソッド
    private func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    // CSVファイルとしてエクスポートするためのデータを生成
    func generateCSVData(historyItems: [HistoryItem]) -> String {
        // ヘッダー行
        var csvString = "日付,開始時間,終了時間,歩数,距離(km),カロリー(kcal),ユーザー名\n"
        
        // 選択された期間に基づいて履歴アイテムをフィルタリング
        let filteredItems = filterHistoryItemsByTimeRange(historyItems)
        
        // 日付でソート
        let sortedItems = filteredItems.sorted { $0.date > $1.date }
        
        // 各アイテムをCSV行に変換
        for item in sortedItems {
            let line = "\(item.date),\(item.startTime),\(item.endTime),\(item.steps),\(item.distance),\(item.kcal),\(item.userName)\n"
            csvString.append(line)
        }
        
        return csvString
    }
}

enum TimeRange: String, CaseIterable, Identifiable {
    case week = "week"
    case month = "month"
    case year = "year"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .week:
            return "週間"
        case .month:
            return "月間"
        case .year:
            return "年間"
        }
    }
}

enum DataType: String, CaseIterable, Identifiable {
    case steps = "steps"
    case distance = "distance"
    case calories = "calories"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .steps:
            return "歩数"
        case .distance:
            return "距離"
        case .calories:
            return "カロリー"
        }
    }
    
    var unit: String {
        switch self {
        case .steps:
            return "歩"
        case .distance:
            return "km"
        case .calories:
            return "kcal"
        }
    }
    
    var color: Color {
        switch self {
        case .steps:
            return .blue
        case .distance:
            return .green
        case .calories:
            return .orange
        }
    }
}