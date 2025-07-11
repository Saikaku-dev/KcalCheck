//
//  ContentViewModel.swift
//  PedometerSample
//
//  Created by cmStudent on 2025/07/07.
//

import Foundation
import CoreMotion
import UIKit

final class ContentViewModel: ObservableObject {
    @Published var data: CMPedometerData?
    @Published var message: String = ""
    
    private let pedometer: CMPedometer
    
    init() {
        if CMPedometer.isStepCountingAvailable() {}
        
        if CMPedometer.isDistanceAvailable() {}
        
        if CMPedometer.isFloorCountingAvailable() {}
        
        if CMPedometer.isPaceAvailable() {}
        
        if CMPedometer.isCadenceAvailable() {}
        
        if CMPedometer.isPedometerEventTrackingAvailable() {}
        
        switch CMPedometer.authorizationStatus() {
        case .notDetermined:
            break
        case .restricted:
            break
        case .denied:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        case .authorized:
            break
            
        @unknown default:
            break
        }
        pedometer = CMPedometer()
    }
    
    func start() {
        pedometer.startUpdates(from: .now) { data, error in
            DispatchQueue.main.async {
                self.data = data
            }
        }
        
        pedometer.startEventUpdates { event, error in
            if let event = event {
                switch event.type {
                case .pause:
                    DispatchQueue.main.async {
                        self.message = "停止中"
                    }
                case .resume:
                    DispatchQueue.main.async {
                        self.message = "実行中"
                    }
                @unknown default:
                    break
                }
            }
        }
        
    }
    
    func stop() {
        pedometer.stopUpdates()
        pedometer.stopEventUpdates()
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
