//
//  HomeView.swift
//  PedometerSample
//
//  Created by cmStudent on 2025/07/07.
//

import SwiftUI
import CoreMotion
import UIKit
import SwiftData

class HomeViewModel: ObservableObject {
    @Published var isStepCountingAvailable: Bool = false //歩数
    @Published var isDistanceAvailable: Bool = false //距離
    @Published var isFloorCountingAvailable: Bool = false //階段
    @Published var isEventTrackingAvailable: Bool = false //追跡
    
    @Published var data: CMPedometerData?
    @Published var message: String = ""
    @Published var isStarted: Bool = false
    
    private let pedometer: CMPedometer
    @Published var histories: [HistoryItem] = []
    init() {
        isStepCountingAvailable = CMPedometer.isStepCountingAvailable()
        isDistanceAvailable = CMPedometer.isDistanceAvailable()
        isFloorCountingAvailable = CMPedometer.isFloorCountingAvailable()
        isEventTrackingAvailable = CMPedometer.isPedometerEventTrackingAvailable()
        
        pedometer = CMPedometer()
        //権限検測
        if CMPedometer.authorizationStatus() == .denied {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        
    }
    
    func start() {
        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.message = "エラー: \(error.localizedDescription)"
                    return
                }
                self?.data = data
            }
        }
        
        pedometer.startEventUpdates { [weak self] event, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.message = "イベントエラー: \(error.localizedDescription)"
                    return
                }
                
                guard let event = event else { return }
                switch event.type {
                case .pause:
                    self?.message = "停止中"
                case .resume:
                    self?.message = "実行中"
                @unknown default:
                    break
                }
            }
        }
    }
    
    func stop(modelContext: ModelContext) {
        pedometer.stopUpdates()
        pedometer.stopEventUpdates()
        
        //dataのデータを保存する(運動開始日と消費したカロリー)
        guard let data = data else { 
            message = "データがありません"
            return 
        }
        
        let startedData = data.startDate.dateString()
        let kcal = kcalCalculation()
        
        // モデルコンテキストが有効かどうかを確認
        do {
            // テスト用に空のクエリを実行して、モデルコンテキストが有効かどうかを確認
            let _ = try modelContext.fetch(FetchDescriptor<HistoryItem>())
            // モデルコンテキストが有効な場合、履歴を追加
            addHistory(date: startedData, kcal: kcal ?? 0, modelContext: modelContext)
            
            // 「お疲れ様です」メッセージを表示し、3秒後に「停止しました」に戻す
            message = "お疲れ様です"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.message = "停止しました"
            }
        } catch {
            print("モデルコンテキストエラー: \(error)")
            message = "データの保存に失敗しました: \(error.localizedDescription)"
            // エラーが発生しても、アプリが閉じないようにする
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.message = "停止しました（データは保存されていません）"
            }
        }
    }
    
    func addHistory(date: String, kcal: Double, modelContext: ModelContext) {
        guard let data = data else { 
            print("データがnilのため履歴を追加できません")
            message = "データがないため保存できません"
            return 
        }
        
        // 获取用户名，如果用户数据为空则使用默认值
        let userName = CurrentUser.shared.user?.nickName ?? "未知ユーザー"
        
        // 時間のフォーマット
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let startTime = formatter.string(from: data.startDate)
        let endTime = formatter.string(from: data.endDate)
        
        do {
            // 新しいHistoryItemを作成
            let item = HistoryItem(
                date: date,
                kcal: kcal,
                userName: userName,
                steps: data.numberOfSteps.intValue,
                distance: data.distance?.doubleValue ?? 0.0,
                startTime: startTime,
                endTime: endTime
            )
            
            // ローカル配列に追加
            histories.append(item)
            
            // SwiftDataに保存
            modelContext.insert(item)
            try modelContext.save()
            print("履歴が正常に保存されました: \(date), \(kcal) kcal, \(data.numberOfSteps.intValue) 歩")
        } catch {
            print("履歴の保存中にエラーが発生しました: \(error)")
            message = "データの保存に失敗しました: \(error.localizedDescription)"
            // エラーの詳細をログに記録
            print("エラーの詳細: \(error)")
        }
    }
    
    func kcalCalculation() -> Double? {
        guard
            let data = data,
            let distance = data.distance?.doubleValue
        else {
            return nil
        }
        
        // 使用默认体重或从用户数据获取
        let weight = CurrentUser.shared.user?.userWeight ?? 60.0 // 默认体重
        
        // カロリーの計算公式：体重(kg) × 距離(km) × 係数(1.05)
        // 1.05 歩きのMETs値
        let distanceKm = distance / 1000.0
        let kcal = weight * distanceKm * 1.05
        return kcal
    }
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var vm = HomeViewModel()
    var body: some View {
        VStack {
            HStack {
                Text(CurrentUser.shared.user?.nickName ?? "ゲスト")
                    .font(.title)
                    .foregroundColor(.red)
                Text("さん、こんにちは！")
                    .font(.title2)
            }
            
            Spacer()
            
            // MARK: - データ
            if let data = vm.data {
                VStack(alignment: .leading, spacing: 16) {
                    // 状态消息
                    Text(vm.message)
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
                            Text("\(data.numberOfSteps)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        HStack {
                            Text("距離")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.2f m", data.distance?.doubleValue ?? 0))
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        HStack {
                            Text("消費カロリー")
                                .foregroundColor(.secondary)
                            Spacer()
                            if let kcal = vm.kcalCalculation() {
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
                            Text("\(data.floorsAscended ?? 0)")
                                .fontWeight(.medium)
                        }
                        HStack {
                            Text("下った階数")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(data.floorsDescended ?? 0)")
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
            } else {
//                MockView(data: MockData.pedometer)
                Text("まだデータを取得してません、運動を開始してください。")
                    .font(.caption)
            }
            
            Spacer()
            
            // MARK: - コントロラー
            //開始&中止ボタン
            Button(action: {
                vm.isStarted.toggle()
                if vm.isStarted {
                    vm.start()
                } else {
                    vm.stop(modelContext: modelContext)
                }
            }) {
                Text(vm.isStarted ? "運動終了" :"運動開始")
                    .foregroundColor(vm.isStarted ? .red : .green)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        
    }
    
    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

extension Date {
    func dateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: self)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [HistoryItem.self, Goal.self])
}
