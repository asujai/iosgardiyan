//
//  SafeDailyResetManager.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import Foundation

/// Bypass girişimlerini engellemek için tasarlanmış güvenli günlük reset yöneticisi.
public final class SafeDailyResetManager {
    public static let shared = SafeDailyResetManager()
    
    private let defaults: UserDefaults
    
    private struct ResetMetadata: Codable {
        var lastResetDate: Date = Date.distantPast
        var lastResetWallClockTime: TimeInterval = 0
        var lastResetSystemUptime: TimeInterval = 0
        var lastKnownWallClockTime: TimeInterval = 0
        var lastKnownTimeZoneIdentifier: String = TimeZone.current.identifier
    }
    
    private let metadataKey = "boundaryshield_reset_metadata"
    
    private init() {
        self.defaults = UserDefaults(suiteName: AppConfig.appGroupId) ?? UserDefaults.standard
    }
    
    private func loadMetadata() -> ResetMetadata {
        guard let data = defaults.data(forKey: metadataKey),
              let metadata = try? JSONDecoder().decode(ResetMetadata.self, from: data) else {
            return ResetMetadata()
        }
        return metadata
    }
    
    private func saveMetadata(_ metadata: ResetMetadata) {
        if let encoded = try? JSONEncoder().encode(metadata) {
            defaults.set(encoded, forKey: metadataKey)
            defaults.synchronize()
        }
    }
    
    /// Günlük saatin değiştirilmesini veya geriye alınmasını kontrol eder.
    /// Günlük reset yapılması gerekiyorsa reset işlemlerini tetikler ve true döner.
    public func checkAndPerformReset() -> Bool {
        let now = Date()
        let currentWallClock = now.timeIntervalSince1970
        let currentUptime = ProcessInfo.processInfo.systemUptime
        let currentTimeZone = TimeZone.current
        
        var metadata = loadMetadata()
        
        // 1. Saat Geriye Alınma Kontrolü (Bypass Engelleme)
        if currentWallClock < metadata.lastKnownWallClockTime {
            LocalDataStore.shared.addLog(
                title: "Zaman Bypass Girişimi!",
                detail: "Cihaz saatinin geriye alındığı tespit edildi. Reset engellendi.",
                type: .warning
            )
            // Son bilinen zamanı yine de en yüksek değere sabitleyelim
            return false
        }
        
        // Son bilinen wall clock zamanını güncelle
        metadata.lastKnownWallClockTime = currentWallClock
        saveMetadata(metadata)
        
        // İlk çalıştırma kontrolü
        if metadata.lastResetDate == Date.distantPast {
            performResetActions(&metadata, now: now, currentWallClock: currentWallClock, currentUptime: currentUptime, currentTimeZone: currentTimeZone)
            return true
        }
        
        // 2. Takvim Günü Değişim Kontrolü
        let calendar = Calendar.current
        let isDifferentDay = !calendar.isDate(now, inSameDayAs: metadata.lastResetDate)
        
        // 3. 22 Saat Kuralı Kontrolü
        let timeSinceLastReset = now.timeIntervalSince(metadata.lastResetDate)
        let hasEnoughTimePassed = timeSinceLastReset >= (22 * 3600) // En az 22 saat geçmiş olmalı
        
        // Uptime farkı ve reboot kontrolü
        let isRebooted = currentUptime < metadata.lastResetSystemUptime
        
        if isDifferentDay && hasEnoughTimePassed {
            // Güvenli günlük reset koşulları sağlandı
            performResetActions(&metadata, now: now, currentWallClock: currentWallClock, currentUptime: currentUptime, currentTimeZone: currentTimeZone)
            return true
        } else if isDifferentDay && !hasEnoughTimePassed {
            // Gün değişmiş fakat 22 saat geçmemişse (Muhtemelen timezone veya manuel ileri alma)
            if isRebooted {
                // Reboot edilmiş olsa dahi 22 saat geçmediyse izin vermiyoruz.
                LocalDataStore.shared.addLog(
                    title: "Erken Gün Değişimi",
                    detail: "Gün değişti ancak son resetten bu yana 22 saat geçmedi. Reset ertelendi.",
                    type: .info
                )
            } else {
                LocalDataStore.shared.addLog(
                    title: "Hızlı Gün Değişimi Engellendi",
                    detail: "Saat ileri alınarak bypass yapılmaya çalışılmış olabilir. 22 saat kuralı devrede.",
                    type: .warning
                )
            }
        }
        
        return false
    }
    
    private func performResetActions(_ metadata: inout ResetMetadata, now: Date, currentWallClock: TimeInterval, currentUptime: TimeInterval, currentTimeZone: TimeZone) {
        LocalDataStore.shared.addLog(
            title: "Güvenli Günlük Reset",
            detail: "Yeni güne geçildi. Sınırlar sıfırlanıyor ve yarına planlanan kurallar uygulanıyor.",
            type: .success
        )
        
        // Kuralları yükle ve yeni gün için resetle
        var rules = LocalDataStore.shared.loadRules()
        var successToday = true
        var wasAnyRuleMonitoredToday = false
        
        // Bugün aktif olan kuralları tespit edelim (Calendar haftalık gün indexi: 1-7, Pazar=1)
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: now)
        
        for i in 0..<rules.count {
            // Eğer dün (veya son aktif olunan gün) kural limitini aştıysa disiplin puanı düşecek
            if rules[i].isActive && rules[i].activeDays.contains(todayWeekday) {
                wasAnyRuleMonitoredToday = true
                if rules[i].isShieldActiveToday {
                    // Shield aktifleştiyse demek ki o kuralda limite ulaşıldı (başarı veya ihlal durumuna göre karar verilebilir)
                    // Ürün fikrine göre: süre limiti dolunca erişim engellenir, bu bir başarıdır (kullanıcı sınıra uymuş veya sınırlandırılmış).
                    // Ancak bypass yapmaya çalıştıysa veya aşmaya zorladıysa ihlal sayılır.
                    // Senaryo: Kural limitinin dolması normal bir başarı kabul edilir (çünkü kural çalışmıştır ve kullanıcı sınırı aşamamıştır).
                }
            }
            
            // Shield'ı sıfırla
            rules[i].isShieldActiveToday = false
            
            // Yarın uygulanacak planları şimdi uygula
            if let pendingLimit = rules[i].pendingNewLimitInSeconds {
                rules[i].dailyLimitInSeconds = pendingLimit
                rules[i].pendingNewLimitInSeconds = nil
                LocalDataStore.shared.addLog(
                    title: "Kural Güncellendi",
                    detail: "'\(rules[i].name)' kuralının yeni süresi yürürlüğe girdi.",
                    type: .info
                )
            }
            
            if let pendingDays = rules[i].pendingActiveDays {
                rules[i].activeDays = pendingDays
                rules[i].pendingActiveDays = nil
                LocalDataStore.shared.addLog(
                    title: "Kural Güncellendi",
                    detail: "'\(rules[i].name)' kuralının aktif gün değişiklikleri yürürlüğe girdi.",
                    type: .info
                )
            }
        }
        
        LocalDataStore.shared.saveRules(rules)
        
        // Disiplin değerlendirmesi (Örn: Eğer izlenen aktif sınırlar varsa ve bypass/ihlal yapılmadıysa başarıdır)
        if wasAnyRuleMonitoredToday {
            DisciplineEngine.shared.recordSuccess(for: now)
        }
        
        // Metadata güncelleme
        metadata.lastResetDate = now
        metadata.lastResetWallClockTime = currentWallClock
        metadata.lastResetSystemUptime = currentUptime
        metadata.lastKnownWallClockTime = currentWallClock
        metadata.lastKnownTimeZoneIdentifier = currentTimeZone.identifier
        
        saveMetadata(metadata)
    }
}
