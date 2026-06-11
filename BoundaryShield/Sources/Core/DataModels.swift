//
//  DataModels.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import Foundation
import FamilyControls

/// Tema tercihleri enum yapısı.
public enum ThemePreference: String, Codable, CaseIterable {
    case system
    case light
    case dark
    case premiumDark
}

/// Dil tercihleri enum yapısı.
public enum LanguagePreference: String, Codable, CaseIterable {
    case tr
    case en
}

/// Olay log tipi.
public enum LogSeverity: String, Codable {
    case info
    case warning
    case error
    case success
}

/// Uygulama olay günlüğü modeli.
public struct StatusLog: Codable, Identifiable, Equatable {
    public let id: UUID
    public let timestamp: Date
    public let title: String
    public let detail: String
    public let type: LogSeverity
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), title: String, detail: String, type: LogSeverity) {
        self.id = id
        self.timestamp = timestamp
        self.title = title
        self.detail = detail
        self.type = type
    }
}

/// Motivasyon sözü veri modeli.
public struct MotivationQuote: Codable, Identifiable, Equatable {
    public let id: UUID
    public var text: String
    public var author: String
    public var isActive: Bool
    public var isCustom: Bool
    
    public init(id: UUID = UUID(), text: String, author: String = "", isActive: Bool = true, isCustom: Bool = false) {
        self.id = id
        self.text = text
        self.author = author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Anonim" : author
        self.isActive = isActive
        self.isCustom = isCustom
    }
}

/// Disiplin durumunu temsil eden veri modeli.
public struct DisciplineState: Codable, Equatable {
    public var level: Int = 1
    public var consecutiveSuccessDays: Int = 0
    public var totalSuccessDays: Int = 0
    public var hasRedBadge: Bool = false
    public var activeRedemptionDaysLeft: Int = 0
    public var redemptionStreakGoal: Int = 2
    public var lastSuccessDate: Date? = nil
    public var lastViolationDate: Date? = nil
    /// 100 günlük disiplin grid kaydı (Tarih string'i -> Durum: "success", "violation")
    public var dailyHistory: [String: String] = [:]
}

/// Kullanıcının oluşturduğu kısıtlama kuralı.
public struct AppLimitRule: Codable, Identifiable, Equatable {
    public let id: UUID
    public var name: String
    /// FamilyActivityPicker aracılığıyla seçilen uygulamalar, kategoriler ve web siteleri
    public var selection: FamilyActivitySelection
    /// Günlük limit süresi (Saniye cinsinden)
    public var dailyLimit: TimeInterval
    /// Haftalık aktif günler (1: Pazar, 2: Pazartesi, ..., 7: Cumartesi)
    public var activeWeekdays: Set<Int>
    public let createdDate: Date
    /// Günlük durum (Örn: "monitoring", "shielded", "disabled")
    public var currentDayState: String
    /// Yarına ertelenen süre artış planı
    public var plannedNextDayLimit: TimeInterval?
    /// Yarına ertelenen aktif gün değişiklik planı
    public var plannedNextDayActiveDays: Set<Int>?
    public var isActive: Bool
    /// Limit bugün doldu mu veya ihlal gerçekleşti mi?
    public var isFailed: Bool
    public var lastUpdatedDate: Date
    
    public init(id: UUID = UUID(),
                name: String,
                selection: FamilyActivitySelection = FamilyActivitySelection(),
                dailyLimit: TimeInterval,
                activeWeekdays: Set<Int> = Set(1...7),
                createdDate: Date = Date(),
                currentDayState: String = "monitoring",
                plannedNextDayLimit: TimeInterval? = nil,
                plannedNextDayActiveDays: Set<Int>? = nil,
                isActive: Bool = true,
                isFailed: Bool = false,
                lastUpdatedDate: Date = Date()) {
        self.id = id
        self.name = name
        self.selection = selection
        self.dailyLimit = dailyLimit
        self.activeWeekdays = activeWeekdays
        self.createdDate = createdDate
        self.currentDayState = currentDayState
        self.plannedNextDayLimit = plannedNextDayLimit
        self.plannedNextDayActiveDays = plannedNextDayActiveDays
        self.isActive = isActive
        self.isFailed = isFailed
        self.lastUpdatedDate = lastUpdatedDate
    }
    
    public static func == (lhs: AppLimitRule, rhs: AppLimitRule) -> Bool {
        return lhs.id == rhs.id
    }
}
