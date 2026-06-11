//
//  ShieldStoreManager.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import Foundation
import ManagedSettings
import FamilyControls

/// ManagedSettingsStore kısıtlama (shield) uygulama ve kaldırma işlemlerini yürüten modüler servis.
public final class ShieldStoreManager {
    public static let shared = ShieldStoreManager()
    
    private let store = ManagedSettingsStore()
    
    private init() {}
    
    /// Belirtilen kural için kısıtlamaları (shield) etkinleştirir.
    public func applyShield(for rule: AppLimitRule) {
        var currentApplications = store.shield.applications ?? []
        var currentCategories = store.shield.applicationCategories ?? []
        var currentWebDomains = store.shield.webDomains ?? []
        
        for token in rule.selection.applicationTokens {
            currentApplications.insert(token)
        }
        for token in rule.selection.categoryTokens {
            currentCategories.insert(token)
        }
        for token in rule.selection.webDomainTokens {
            currentWebDomains.insert(token)
        }
        
        store.shield.applications = currentApplications
        store.shield.applicationCategories = currentCategories
        store.shield.webDomains = currentWebDomains
        
        LocalDataStore.shared.addLog(
            title: "Engel Uygulandı",
            detail: "'\(rule.name)' sınırı aşıldığı için kilitler etkinleştirildi.",
            type: .warning
        )
    }
    
    /// Belirtilen kural için kısıtlamaları kaldırır.
    public func removeShield(for rule: AppLimitRule) {
        var currentApplications = store.shield.applications ?? []
        var currentCategories = store.shield.applicationCategories ?? []
        var currentWebDomains = store.shield.webDomains ?? []
        
        for token in rule.selection.applicationTokens {
            currentApplications.remove(token)
        }
        for token in rule.selection.categoryTokens {
            currentCategories.remove(token)
        }
        for token in rule.selection.webDomainTokens {
            currentWebDomains.remove(token)
        }
        
        store.shield.applications = currentApplications.isEmpty ? nil : currentApplications
        store.shield.applicationCategories = currentCategories.isEmpty ? nil : currentCategories
        store.shield.webDomains = currentWebDomains.isEmpty ? nil : currentWebDomains
    }
    
    /// Sistemdeki tüm kısıtlamaları (shield'ları) temizler.
    public func clearAllShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        
        LocalDataStore.shared.addLog(
            title: "Tüm Kilitler Temizlendi",
            detail: "Sistem sıfırlama veya kural iptalleri nedeniyle tüm kilitler kaldırıldı.",
            type: .info
        )
    }
}
