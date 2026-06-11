//
//  DeviceActivityMonitorExtension.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import DeviceActivity
import ManagedSettings
import Foundation

// Arka planda kısıtlanmış uygulamaların süre limitlerini takip eden ve kilit uygulayan extension.
public class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    
    // Süre limiti aşıldığında işletim sistemi tarafından tetiklenir.
    public override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        let ruleIdString = activity.rawValue
        
        // 1. Kuralları yükle ve ilgili olanı bul
        var rules = LocalDataStore.shared.loadRules()
        guard let index = rules.firstIndex(where: { $0.id.uuidString == ruleIdString }) else { return }
        
        // Aynı gün birden fazla kez ihlal kaydı oluşmasını engellemek için kontrol
        if rules[index].isFailed { return }
        
        // 2. Kural durumunu güncelle
        rules[index].isFailed = true
        rules[index].currentDayState = "shielded"
        LocalDataStore.shared.saveRules(rules)
        
        // 3. Kısıtlamayı uygula (ShieldStoreManager yardımıyla)
        ShieldStoreManager.shared.applyShield(for: rules[index])
        
        // 4. Olayı logla
        LocalDataStore.shared.addLog(
            title: "Limit Aşıldı",
            detail: "'\(rules[index].name)' süre sınırı dolduğu için erişim kısıtlandı.",
            type: .warning
        )
        
        // 5. Disiplin ihlali olarak kaydet
        DisciplineEngine.shared.recordViolation(for: Date())
        
        // 6. Kullanıcıya bildirim gönder
        NotificationManager.shared.sendLocalNotification(
            title: "Süre Sınırı Aşıldı",
            body: "'\(rules[index].name)' için belirlenen günlük süre sınırı doldu."
        )
    }
    
    public override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        let ruleIdString = activity.rawValue
        let rules = LocalDataStore.shared.loadRules()
        
        guard let rule = rules.first(where: { $0.id.uuidString == ruleIdString }) else { return }
        
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: Date())
        
        // Bugün rule aktif günlerinden biri değilse monitoring/shield uygulanmasın, gerekirse temizlensin
        if !rule.activeWeekdays.contains(todayWeekday) {
            ShieldStoreManager.shared.removeShield(for: rule)
            print("INFO: BoundaryShield day not active. Shield removed for \(rule.name).")
        }
    }
    
    public override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        let ruleIdString = activity.rawValue
        let rules = LocalDataStore.shared.loadRules()
        if let rule = rules.first(where: { $0.id.uuidString == ruleIdString }) {
            ShieldStoreManager.shared.removeShield(for: rule)
        }
    }
}
