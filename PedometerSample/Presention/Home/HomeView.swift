//
//  HomeView.swift
//  PedometerSample
//
//  Created by cmStudent on 2025/07/07.
//

import SwiftUI
import CoreMotion
import UIKit

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
    
    func stop() {
        pedometer.stopUpdates()
        pedometer.stopEventUpdates()
        
        //dataのデータを保存する(運動開始日と消費したカロリー)
        guard let data = data else { return }
        let startedData = data.startDate.dateString()
        let kcal = kcalCalculation()
        addHistory(date: startedData, kcal: kcal ?? 0)
        message = "停止しました"
    }
    
    func addHistory(date: String, kcal: Double) {
        let item = HistoryItem(date: date, kcal: kcal)
        histories.append(item)
    }
    
    func kcalCalculation() -> Double? {
        guard
            let data = data,
            let distance = data.distance?.doubleValue,
            let user = CurrentUser.shared.user
        else {
            return nil
        }
        // カロリーの計算公式：体重(kg) × 距離(km) × 係数(1.05)
        // 1.05 歩きのMETs値
        let weight = user.userWeight
        let distanceKm = distance / 1000.0
        let kcal = weight * distanceKm * 1.05
        return kcal
    }
}

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    var body: some View {
        VStack {
            HStack {
                if let user = CurrentUser.shared.user {
                    Text(user.nickName)
                        .font(.title)
                        .foregroundColor(.red)
                    Text("さん、こんにちは！")
                        .font(.title2)
                } else {
                    Text("Preview")
                        .font(.title)
                        .foregroundColor(.red)
                    Text("さん、こんにちは！")
                        .font(.title2)
                }
            }
            
            Spacer()
            
            // MARK: - データ
            if let data = vm.data,
               let user = CurrentUser.shared.user {
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
                    vm.stop()
                }
            }) {
                Text(vm.isStarted ? "運動終了" :"運動開始")
                    .foregroundColor(vm.isStarted ? .red : .green)
            }
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
}
