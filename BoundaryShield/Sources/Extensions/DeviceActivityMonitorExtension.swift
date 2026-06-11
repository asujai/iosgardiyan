//
//  DeviceActivityMonitorExtension.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import DeviceActivity
import ManagedSettings
import Foundation

// iOS arka planında limit sürelerini takip eden ve süre aşımında tetiklenen extension.
public class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    private let store = ManagedSettingsStore()
    
    // Süre limiti dolduğunda tetiklenen ana metot.
    public override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        let ruleIdString = activity.rawValue
        
        // 1. Kuralları yükle ve eşleşeni bul
        var rules = LocalDataStore.shared.loadRules()
        guard let index = rules.firstIndex(where: { $0.id.uuidString == ruleIdString }) else { return }
        
        // 2. Kural durumunu güncelle
        rules[index].isShieldActiveToday = true
        LocalDataStore.shared.saveRules(rules)
        
        // 3. Shield Uygula (Engelleme)
        applyShield(for: rules[index])
        
        // 4. Olayı logla
        LocalDataStore.shared.addLog(
            title: "Limit Aşıldı",
            detail: "'\(rules[index].name)' süresi dolduğu için uygulamalar kilitlendi.",
            type: .warning
        )
        
        // İhlal kaydını tetikleme (Ürün kuralı: Limit dolduğunda kilitlenme olması başarıdır.
        // Ancak kullanıcı izinsiz bir eylem yaparsa veya bypass etmeye çalışırsa ihlal sayılır)
    }
    
    public override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // İzleme zaman aralığı başladığında yapılacaklar (isteğe bağlı)
    }
    
    public override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        // Gün sonu veya izleme aralığı bittiğinde shield kaldırılabilir (Reset işlemleri)
        let ruleIdString = activity.rawValue
        let rules = LocalDataStore.shared.loadRules()
        if let rule = rules.first(where: { $0.id.uuidString == ruleIdString }) {
            removeShield(for: rule)
        }
    }
    
    // MARK: - Shield Helper Operations
    
    private func applyShield(for rule: ShieldRule) {
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
    }
    
    private func removeShield(for rule: ShieldRule) {
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
}
