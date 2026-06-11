//
//  LocalDataStore.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import Foundation
import FamilyControls

/// Log tipleri.
public enum LogType: String, Codable {
    case info
    case warning
    case error
    case success
}

/// Uygulama içi olay günlükleri (Timeline için).
public struct AppLog: Codable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let title: String
    public let detail: String
    public let type: LogType
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), title: String, detail: String, type: LogType) {
        self.id = id
        self.timestamp = timestamp
        self.title = title
        self.detail = detail
        self.type = type
    }
}

/// Günlük limit kurallarını tanımlayan model.
public struct ShieldRule: Codable, Identifiable, Equatable {
    public let id: UUID
    public var name: String
    /// Seçilen uygulamalar, kategoriler ve web siteleri (FamilyControls)
    public var selection: FamilyActivitySelection
    /// Günlük süre limiti (saniye cinsinden)
    public var dailyLimitInSeconds: TimeInterval
    /// Haftalık aktif günler (1: Pazar, 2: Pazartesi, ..., 7: Cumartesi)
    public var activeDays: Set<Int>
    /// Kuralın aktif olup olmadığı
    public var isActive: Bool
    /// Limit bugün doldu mu?
    public var isShieldActiveToday: Bool
    /// Yarın uygulanmak üzere planlanan yeni limit (saniye cinsinden)
    public var pendingNewLimitInSeconds: TimeInterval?
    /// Yarın uygulanmak üzere planlanan aktif gün değişikliği
    public var pendingActiveDays: Set<Int>?
    
    public init(id: UUID = UUID(),
                name: String,
                selection: FamilyActivitySelection = FamilyActivitySelection(),
                dailyLimitInSeconds: TimeInterval,
                activeDays: Set<Int> = Set(1...7),
                isActive: Bool = true,
                isShieldActiveToday: Bool = false,
                pendingNewLimitInSeconds: TimeInterval? = nil,
                pendingActiveDays: Set<Int>? = nil) {
        self.id = id
        self.name = name
        self.selection = selection
        self.dailyLimitInSeconds = dailyLimitInSeconds
        self.activeDays = activeDays
        self.isActive = isActive
        self.isShieldActiveToday = isShieldActiveToday
        self.pendingNewLimitInSeconds = pendingNewLimitInSeconds
        self.pendingActiveDays = pendingActiveDays
    }
    
    public static func == (lhs: ShieldRule, rhs: ShieldRule) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Uygulama ayarlarını tanımlayan model.
public struct AppSettings: Codable {
    public var theme: String = "system" // system, light, dark, premiumDark
    public var language: String = "tr"  // tr, en
    public var onlyMyQuotes: Bool = false
}

/// App Group üzerinden ortak veri okuma ve yazma işlemlerini yürüten veri deposu.
public final class LocalDataStore {
    public static let shared = LocalDataStore()
    
    private let sharedUserDefaults: UserDefaults?
    
    private init() {
        self.sharedUserDefaults = UserDefaults(suiteName: AppConfig.appGroupId)
        if self.sharedUserDefaults == nil {
            print("WARNING: App Group UserDefaults could not be initialized. Falling back to standard.")
        }
    }
    
    private var defaults: UserDefaults {
        return sharedUserDefaults ?? UserDefaults.standard
    }
    
    // MARK: - Rules
    
    public func saveRules(_ rules: [ShieldRule]) {
        if let encoded = try? JSONEncoder().encode(rules) {
            defaults.set(encoded, forKey: AppConfig.Keys.rules)
            defaults.synchronize()
        }
    }
    
    public func loadRules() -> [ShieldRule] {
        guard let data = defaults.data(forKey: AppConfig.Keys.rules),
              let rules = try? JSONDecoder().decode([ShieldRule].self, from: data) else {
            return []
        }
        return rules
    }
    
    // MARK: - Settings
    
    public func saveSettings(_ settings: AppSettings) {
        if let encoded = try? JSONEncoder().encode(settings) {
            defaults.set(encoded, forKey: AppConfig.Keys.appSettings)
            defaults.synchronize()
        }
    }
    
    public func loadSettings() -> AppSettings {
        guard let data = defaults.data(forKey: AppConfig.Keys.appSettings),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }
    
    // MARK: - Logs
    
    public func saveLogs(_ logs: [AppLog]) {
        // En fazla 500 log tutarak şişmeyi önleyelim.
        let trimmedLogs = Array(logs.prefix(500))
        if let encoded = try? JSONEncoder().encode(trimmedLogs) {
            defaults.set(encoded, forKey: AppConfig.Keys.logs)
            defaults.synchronize()
        }
    }
    
    public func loadLogs() -> [AppLog] {
        guard let data = defaults.data(forKey: AppConfig.Keys.logs),
              let logs = try? JSONDecoder().decode([AppLog].self, from: data) else {
            return []
        }
        return logs
    }
    
    public func addLog(title: String, detail: String, type: LogType) {
        var currentLogs = loadLogs()
        let newLog = AppLog(title: title, detail: detail, type: type)
        currentLogs.insert(newLog, at: 0)
        saveLogs(currentLogs)
    }
    
    // MARK: - Clear All Data
    
    public func clearAllData() {
        defaults.removeObject(forKey: AppConfig.Keys.rules)
        defaults.removeObject(forKey: AppConfig.Keys.disciplineState)
        defaults.removeObject(forKey: AppConfig.Keys.quotes)
        defaults.removeObject(forKey: AppConfig.Keys.logs)
        defaults.removeObject(forKey: AppConfig.Keys.appSettings)
        defaults.synchronize()
        addLog(title: "Veri Sıfırlama", detail: "Tüm yerel veriler kullanıcı tarafından temizlendi.", type: .warning)
    }
}
