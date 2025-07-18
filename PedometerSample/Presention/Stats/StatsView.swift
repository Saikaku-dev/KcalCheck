//
//  StatsView.swift
//  PedometerSample
//
//  Created by cmStudent on 2025/07/08.
//

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()
    @Query(sort: \HistoryItem.date, order: .reverse) private var historyItems: [HistoryItem]
    
    @State private var showingExportSheet = false
    @State private var csvData: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 期間選択セグメント
                    Picker("期間", selection: $viewModel.selectedTimeRange) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: viewModel.selectedTimeRange) { _, _ in
                        viewModel.calculateStats(historyItems: historyItems)
                    }
                    
                    // 統計サマリーカード
                    StatsSummaryCard(viewModel: viewModel)
                    
                    // データタイプ選択セグメント
                    Picker("データタイプ", selection: $viewModel.selectedDataType) {
                        ForEach(DataType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: viewModel.selectedDataType) { _, _ in
                        viewModel.calculateStats(historyItems: historyItems)
                    }
                    
                    // チャート
                    StatsChartCard(viewModel: viewModel)
                    
                    // 詳細統計
                    StatsDetailCard(viewModel: viewModel)
                }
                .padding(.vertical)
            }
            .navigationTitle("統計")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        csvData = viewModel.generateCSVData(historyItems: historyItems)
                        showingExportSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportView(csvData: csvData)
            }
            .onAppear {
                viewModel.calculateStats(historyItems: historyItems)
            }
        }
    }
}

struct StatsSummaryCard: View {
    @ObservedObject var viewModel: StatsViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("サマリー")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                // 歩数サマリー
                SummaryItem(
                    icon: "figure.walk",
                    color: .blue,
                    title: "合計歩数",
                    value: "\(viewModel.totalSteps)",
                    unit: "歩"
                )
                
                Divider()
                    .frame(height: 40)
                
                // 距離サマリー
                SummaryItem(
                    icon: "map",
                    color: .green,
                    title: "合計距離",
                    value: String(format: "%.2f", viewModel.totalDistance),
                    unit: "km"
                )
                
                Divider()
                    .frame(height: 40)
                
                // カロリーサマリー
                SummaryItem(
                    icon: "flame.fill",
                    color: .orange,
                    title: "合計カロリー",
                    value: String(format: "%.1f", viewModel.totalCalories),
                    unit: "kcal"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct SummaryItem: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatsChartCard: View {
    @ObservedObject var viewModel: StatsViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("\(viewModel.selectedTimeRange.displayName)\(viewModel.selectedDataType.displayName)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if viewModel.chartData.isEmpty {
                Text("データがありません")
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                Chart {
                    ForEach(viewModel.chartData, id: \.date) { item in
                        BarMark(
                            x: .value("日付", item.date),
                            y: .value(viewModel.selectedDataType.displayName, item.value)
                        )
                        .foregroundStyle(viewModel.selectedDataType.color)
                    }
                    
                    // 平均値の線
                    RuleMark(
                        y: .value("平均", averageValue)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .foregroundStyle(.gray)
                    .annotation(position: .top, alignment: .trailing) {
                        Text("平均: \(formattedAverage) \(viewModel.selectedDataType.unit)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 250)
                .chartYScale(domain: 0...(maxValue * 1.2))
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
        .padding(.horizontal)
    }
    
    // チャートデータの最大値
    private var maxValue: Double {
        viewModel.chartData.map { $0.value }.max() ?? 1
    }
    
    // 平均値
    private var averageValue: Double {
        switch viewModel.selectedDataType {
        case .steps:
            return Double(viewModel.averageStepsPerDay)
        case .distance:
            return viewModel.averageDistancePerDay
        case .calories:
            return viewModel.averageCaloriesPerDay
        }
    }
    
    // フォーマットされた平均値
    private var formattedAverage: String {
        switch viewModel.selectedDataType {
        case .steps:
            return "\(viewModel.averageStepsPerDay)"
        case .distance:
            return String(format: "%.2f", viewModel.averageDistancePerDay)
        case .calories:
            return String(format: "%.1f", viewModel.averageCaloriesPerDay)
        }
    }
}

struct StatsDetailCard: View {
    @ObservedObject var viewModel: StatsViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Text("詳細統計")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                // 平均値
                DetailRow(
                    title: "1日平均歩数",
                    value: "\(viewModel.averageStepsPerDay)",
                    unit: "歩"
                )
                
                DetailRow(
                    title: "1日平均距離",
                    value: String(format: "%.2f", viewModel.averageDistancePerDay),
                    unit: "km"
                )
                
                DetailRow(
                    title: "1日平均カロリー消費",
                    value: String(format: "%.1f", viewModel.averageCaloriesPerDay),
                    unit: "kcal"
                )
                
                Divider()
                
                // 最大値
                DetailRow(
                    title: "1日最大歩数",
                    value: "\(viewModel.maxStepsInOneDay)",
                    unit: "歩"
                )
                
                DetailRow(
                    title: "1日最大距離",
                    value: String(format: "%.2f", viewModel.maxDistanceInOneDay),
                    unit: "km"
                )
                
                DetailRow(
                    title: "1日最大カロリー消費",
                    value: String(format: "%.1f", viewModel.maxCaloriesInOneDay),
                    unit: "kcal"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ExportView: View {
    let csvData: String
    @Environment(\.dismiss) private var dismiss
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("データのエクスポート")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("選択した期間のデータをCSV形式でエクスポートします。")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Divider()
                
                // プレビュー
                VStack(alignment: .leading, spacing: 8) {
                    Text("プレビュー:")
                        .font(.headline)
                    
                    ScrollView {
                        Text(csvData)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                    }
                    .frame(height: 200)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // エクスポートボタン
                Button(action: {
                    exportCSV()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("CSVファイルとして保存")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(alertMessage.contains("成功") ? "成功" : "エラー"),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // CSVファイルをエクスポートする
    private func exportCSV() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let filename = "pedometer_stats_\(timestamp).csv"
        
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            alertMessage = "ドキュメントディレクトリにアクセスできませんでした"
            showingAlert = true
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        do {
            try csvData.write(to: fileURL, atomically: true, encoding: .utf8)
            alertMessage = "ファイルを正常に保存しました: \(fileURL.path)"
            showingAlert = true
        } catch {
            alertMessage = "ファイルの保存中にエラーが発生しました: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(for: [HistoryItem.self, Goal.self])
}