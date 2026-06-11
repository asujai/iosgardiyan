//
//  DeviceActivityScheduleBuilder.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import Foundation
import DeviceActivity
import FamilyControls

/// DeviceActivity izleme programlarını ve olay eşiklerini inşa eden yardımcı servis.
public struct DeviceActivityScheduleBuilder {
    
    /// Belirtilen kural için günlük 24 saatlik izleme planı (schedule) oluşturur.
    public static func buildSchedule() -> DeviceActivitySchedule {
        return DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
    }
    
    /// Kuralın limit süresine ve seçimlerine göre olay eşiği (threshold event) oluşturur.
    public static func buildEvent(for rule: AppLimitRule) -> DeviceActivityEvent {
        let limitHour = Int(rule.dailyLimit) / 3600
        let limitMinute = (Int(rule.dailyLimit) % 3600) / 60
        
        let threshold = DateComponents(hour: limitHour, minute: limitMinute)
        
        return DeviceActivityEvent(
            applications: rule.selection.applicationTokens,
            categories: rule.selection.categoryTokens,
            webDomains: rule.selection.webDomainTokens,
            threshold: threshold
        )
    }
}
