//
//  Goal.swift
//  PedometerSample
//
//  Created by cmStudent on 2025/07/08.
//

import Foundation
import SwiftData

@Model
final class Goal {
    var id: UUID
    var targetType: TargetType // 目標タイプ（歩数、距離、カロリー）
    var targetValue: Double // 目標値
    var periodType: PeriodType // 期間タイプ（日、週、月）
    var createdAt: Date // 作成日
    var isActive: Bool // アクティブかどうか
    
    init(targetType: TargetType, targetValue: Double, periodType: PeriodType) {
        self.id = UUID()
        self.targetType = targetType
        self.targetValue = targetValue
        self.periodType = periodType
        self.createdAt = Date()
        self.isActive = true
    }
}

enum TargetType: String, Codable {
    case steps = "steps" // 歩数
    case distance = "distance" // 距離
    case calories = "calories" // カロリー
    
    var displayName: String {
        switch self {
        case .steps:
            return "歩数"
        case .distance:
            return "距離 (km)"
        case .calories:
            return "カロリー (kcal)"
        }
    }
}

enum PeriodType: String, Codable {
    case daily = "daily" // 日単位
    case weekly = "weekly" // 週単位
    case monthly = "monthly" // 月単位
    
    var displayName: String {
        switch self {
        case .daily:
            return "毎日"
        case .weekly:
            return "毎週"
        case .monthly:
            return "毎月"
        }
    }
}