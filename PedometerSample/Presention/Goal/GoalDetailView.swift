//
//  GoalDetailView.swift
//  PedometerSample
//
//  Created by cmStudent on 2025/07/08.
//

import SwiftUI
import Charts

struct GoalDetailView: View {
    let goal: Goal
    let historyItems: [HistoryItem]
    
    @StateObject private var viewModel = GoalViewModel()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 目標情報カード
                GoalInfoCard(goal: goal, historyItems: historyItems, viewModel: viewModel)
                
                // 進捗グラフ
                ProgressChartView(goal: goal, historyItems: historyItems)
                
                // 履歴リスト
                RelevantHistoryList(goal: goal, historyItems: historyItems)
            }
            .padding()
        }
        .navigationTitle("目標詳細")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GoalInfoCard: View {
    let goal: Goal
    let historyItems: [HistoryItem]
    let viewModel: GoalViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // 目標タイプアイコンとタイトル
            HStack {
                Image(systemName: goalIcon)
                    .font(.largeTitle)
                    .foregroundColor(goalColor)
                
                VStack(alignment: .leading) {
                    Text(goal.targetType.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(goal.periodType.displayName)の目標")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // アクティブステータス
                Text(goal.isActive ? "アクティブ" : "完了")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(goal.isActive ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Divider()
            
            // 目標値と現在の進捗
            HStack(spacing: 20) {
                VStack {
                    Text("目標")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(goal.targetValue))")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(unitString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack {
                    Text("現在")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(getCurrentValue()))")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(unitString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack {
                    Text("残り")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(max(0, goal.targetValue - getCurrentValue())))")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(unitString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            
            Divider()
            
            // 進捗バー
            VStack(alignment: .leading, spacing: 8) {
                let progress = viewModel.calculateProgress(goal: goal, historyItems: historyItems)
                
                HStack {
                    Text("進捗状況")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: goalColor))
                    .frame(height: 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
    private func getCurrentValue() -> Double {
        // 期間に基づいて関連する履歴アイテムをフィルタリング
        let relevantItems = filterHistoryItemsByPeriod(historyItems, for: goal.periodType)
        
        switch goal.targetType {
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

struct ProgressChartView: View {
    let goal: Goal
    let historyItems: [HistoryItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("進捗グラフ")
                .font(.headline)
            
            if chartData.isEmpty {
                Text("データがありません")
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                Chart {
                    ForEach(chartData, id: \.date) { item in
                        BarMark(
                            x: .value("日付", item.date),
                            y: .value(getValue(), item.value)
                        )
                        .foregroundStyle(goalColor)
                    }
                    
                    if goal.periodType != .daily {
                        RuleMark(
                            y: .value("目標", dailyTargetValue)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .foregroundStyle(.red)
                        .annotation(position: .top, alignment: .trailing) {
                            Text("日次目標: \(Int(dailyTargetValue)) \(unitString)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .frame(height: 250)
                .chartYScale(domain: 0...(max(dailyTargetValue * 1.2, maxValue * 1.2)))
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let dateValue = value.as(String.self) {
                                Text(dateValue)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // チャートデータを生成
    private var chartData: [(date: String, value: Double)] {
        let calendar = Calendar.current
        let now = Date()
        
        switch goal.periodType {
        case .daily:
            // 今日の時間ごとのデータ
            return getHourlyData(for: now)
        case .weekly:
            // 今週の日ごとのデータ
            return getDailyData(for: now, days: 7)
        case .monthly:
            // 今月の日ごとのデータ
            let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
            return getDailyData(for: now, days: daysInMonth)
        }
    }
    
    // 時間ごとのデータを取得
    private func getHourlyData(for date: Date) -> [(date: String, value: Double)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:00"
        
        var result: [(date: String, value: Double)] = []
        
        // 現在の時間を取得
        let currentHour = calendar.component(.hour, from: date)
        
        // 0時から現在の時間までのデータを生成
        for hour in 0...currentHour {
            let hourDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
            let hourString = formatter.string(from: hourDate)
            
            // この時間帯の履歴アイテムをフィルタリング
            let hourlyItems = historyItems.filter { item in
                guard let itemDate = dateFromString(item.date) else { return false }
                return calendar.isDate(itemDate, inSameDayAs: date) &&
                       calendar.component(.hour, from: itemDate) == hour
            }
            
            // 値を集計
            let value: Double
            switch goal.targetType {
            case .steps:
                value = Double(hourlyItems.reduce(0) { $0 + $1.steps })
            case .distance:
                value = hourlyItems.reduce(0) { $0 + $1.distance }
            case .calories:
                value = hourlyItems.reduce(0) { $0 + $1.kcal }
            }
            
            result.append((date: hourString, value: value))
        }
        
        return result
    }
    
    // 日ごとのデータを取得
    private func getDailyData(for date: Date, days: Int) -> [(date: String, value: Double)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        
        var result: [(date: String, value: Double)] = []
        
        // 指定された日数分のデータを生成
        for day in 0..<days {
            // 基準日から指定された日数前の日付を計算
            guard let dayDate = calendar.date(byAdding: .day, value: -day, to: date) else { continue }
            let dayString = formatter.string(from: dayDate)
            
            // この日の履歴アイテムをフィルタリング
            let dailyItems = historyItems.filter { item in
                guard let itemDate = dateFromString(item.date) else { return false }
                return calendar.isDate(itemDate, inSameDayAs: dayDate)
            }
            
            // 値を集計
            let value: Double
            switch goal.targetType {
            case .steps:
                value = Double(dailyItems.reduce(0) { $0 + $1.steps })
            case .distance:
                value = dailyItems.reduce(0) { $0 + $1.distance }
            case .calories:
                value = dailyItems.reduce(0) { $0 + $1.kcal }
            }
            
            result.append((date: dayString, value: value))
        }
        
        // 日付順に並べ替え
        return result.reversed()
    }
    
    // 目標タイプに基づいた値の名前を取得
    private func getValue() -> String {
        switch goal.targetType {
        case .steps:
            return "歩数"
        case .distance:
            return "距離 (km)"
        case .calories:
            return "カロリー (kcal)"
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
    
    // 日次目標値を計算
    private var dailyTargetValue: Double {
        switch goal.periodType {
        case .daily:
            return goal.targetValue
        case .weekly:
            return goal.targetValue / 7
        case .monthly:
            let calendar = Calendar.current
            let now = Date()
            let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
            return goal.targetValue / Double(daysInMonth)
        }
    }
    
    // チャートデータの最大値
    private var maxValue: Double {
        chartData.map { $0.value }.max() ?? 0
    }
    
    // 日付文字列をDateに変換するヘルパーメソッド
    private func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}

struct RelevantHistoryList: View {
    let goal: Goal
    let historyItems: [HistoryItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("関連する履歴")
                .font(.headline)
            
            if relevantItems.isEmpty {
                Text("関連する履歴がありません")
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                ForEach(relevantItems) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.date)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("\(item.startTime) - \(item.endTime)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            switch goal.targetType {
                            case .steps:
                                Text("\(item.steps) 歩")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            case .distance:
                                Text("\(String(format: "%.2f", item.distance)) km")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            case .calories:
                                Text("\(String(format: "%.1f", item.kcal)) kcal")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // 関連する履歴アイテムを取得
    private var relevantItems: [HistoryItem] {
        filterHistoryItemsByPeriod(historyItems, for: goal.periodType)
            .sorted(by: { $0.date > $1.date })
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

#Preview {
    let goal = Goal(targetType: .steps, targetValue: 10000, periodType: .daily)
    let historyItems: [HistoryItem] = []
    return GoalDetailView(goal: goal, historyItems: historyItems)
}