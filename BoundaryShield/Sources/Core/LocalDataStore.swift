//
//  LocalDataStore.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import Foundation
import FamilyControls

/// Uygulamanın üst seviye yerel veri erişim katmanı. AppGroupStore kullanarak veri tutarlılığını sağlar.
public final class LocalDataStore {
    public static let shared = LocalDataStore()
    
    private let store = AppGroupStore.shared
    
    private init() {}
    
    // MARK: - Rules (AppLimitRule)
    
    public func saveRules(_ rules: [AppLimitRule]) {
        store.save(rules, forKey: AppConfiguration.Keys.rules)
    }
    
    public func loadRules() -> [AppLimitRule] {
        return store.load(forKey: AppConfiguration.Keys.rules) ?? []
    }
    
    // MARK: - Logs (StatusLog)
    
    public func saveLogs(_ logs: [StatusLog]) {
        let trimmed = Array(logs.prefix(500))
        store.save(trimmed, forKey: AppConfiguration.Keys.logs)
    }
    
    public func loadLogs() -> [StatusLog] {
        return store.load(forKey: AppConfiguration.Keys.logs) ?? []
    }
    
    public func addLog(title: String, detail: String, type: LogSeverity) {
        var currentLogs = loadLogs()
        let newLog = StatusLog(title: title, detail: detail, type: type)
        currentLogs.insert(newLog, at: 0)
        saveLogs(currentLogs)
    }
    
    // MARK: - Settings (Theme & Language Preference)
    
    public func saveThemePreference(_ preference: ThemePreference) {
        store.save(preference.rawValue, forKey: AppConfiguration.Keys.theme)
    }
    
    public func loadThemePreference() -> ThemePreference {
        guard let raw: String = store.load(forKey: AppConfiguration.Keys.theme),
              let pref = ThemePreference(rawValue: raw) else {
            return .system
        }
        return pref
    }
    
    public func saveLanguagePreference(_ preference: LanguagePreference) {
        store.save(preference.rawValue, forKey: AppConfiguration.Keys.language)
    }
    
    public func loadLanguagePreference() -> LanguagePreference {
        guard let raw: String = store.load(forKey: AppConfiguration.Keys.language),
              let pref = LanguagePreference(rawValue: raw) else {
            return .tr
        }
        return pref
    }
    
    public func saveOnlyMyQuotesPreference(_ onlyMy: Bool) {
        store.save(onlyMy, forKey: AppConfiguration.Keys.onlyMyQuotes)
    }
    
    public func loadOnlyMyQuotesPreference() -> Bool {
        return store.load(forKey: AppConfiguration.Keys.onlyMyQuotes) ?? false
    }
    
    // MARK: - Reset & Clear
    
    public func clearAllData() {
        // Sıfırlama metadata'sını temizle
        SafeDailyResetManager.shared.clearMetadata()
        
        store.remove(forKey: AppConfiguration.Keys.rules)
        store.remove(forKey: AppConfiguration.Keys.disciplineState)
        store.remove(forKey: AppConfiguration.Keys.quotes)
        store.remove(forKey: AppConfiguration.Keys.logs)
        store.remove(forKey: AppConfiguration.Keys.theme)
        store.remove(forKey: AppConfiguration.Keys.language)
        store.remove(forKey: AppConfiguration.Keys.onlyMyQuotes)
        
        addLog(title: "Sistem Sıfırlandı", detail: "Tüm yerel veriler ve reset ayarları temizlendi.", type: .warning)
    }
}
