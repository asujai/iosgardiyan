//
//  SafeDailyResetManager.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import Foundation

/// Bypass girişimlerini önleyen ve günlük zaman aşımında kural resetlerini koordine eden güvenli günlük sıfırlama yöneticisi.
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
    
    private let metadataKey = "boundaryshield_reset_metadata_v3"
    
    private init() {
        self.defaults = UserDefaults(suiteName: AppConfiguration.appGroupId) ?? UserDefaults.standard
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
    
    /// Cihaz saatinin geriye alınmasını veya bypass girişimlerini doğrular.
    /// Yeni güne geçildiğinde ve şartlar sağlandığında sıfırlama işlemlerini tetikler ve true döner.
    public func checkAndPerformReset() -> Bool {
        let now = Date()
        let currentWallClock = now.timeIntervalSince1970
        let currentUptime = ProcessInfo.processInfo.systemUptime
        let currentTimeZone = TimeZone.current
        
        var metadata = loadMetadata()
        
        // 1. Saat Geriye Alınma Kontrolü
        if currentWallClock < metadata.lastKnownWallClockTime {
            LocalDataStore.shared.addLog(
                title: "Bypass Girişimi Engellendi",
                detail: "Cihaz saatinin geriye alındığı saptandı. Günlük reset engellendi.",
                type: .warning
            )
            return false
        }
        
        // Son bilinen zamanı güncelle
        metadata.lastKnownWallClockTime = currentWallClock
        saveMetadata(metadata)
        
        // İlk kurulum doğrulaması (Sadece metadata kaydet, log/başarı yazma)
        if metadata.lastResetDate == Date.distantPast {
            metadata.lastResetDate = now
            metadata.lastResetWallClockTime = currentWallClock
            metadata.lastResetSystemUptime = currentUptime
            metadata.lastKnownWallClockTime = currentWallClock
            metadata.lastKnownTimeZoneIdentifier = currentTimeZone.identifier
            saveMetadata(metadata)
            return true
        }
        
        // 2. Takvim Günü Fark Kontrolü
        let calendar = Calendar.current
        let isDifferentDay = !calendar.isDate(now, inSameDayAs: metadata.lastResetDate)
        
        // 3. En Az 22 Saat Geçme Kontrolü
        let timeSinceLastReset = now.timeIntervalSince(metadata.lastResetDate)
        let hasEnoughTimePassed = timeSinceLastReset >= (22 * 3600)
        
        let isRebooted = currentUptime < metadata.lastResetSystemUptime
        
        if isDifferentDay && hasEnoughTimePassed {
            performResetActions(&metadata, now: now, currentWallClock: currentWallClock, currentUptime: currentUptime, currentTimeZone: currentTimeZone)
            return true
        } else if isDifferentDay && !hasEnoughTimePassed {
            if isRebooted {
                LocalDataStore.shared.addLog(
                    title: "Erken Gün Değişimi",
                    detail: "Gün değişti fakat son resetten bu yana 22 saat geçmedi. Reset ertelendi.",
                    type: .info
                )
            } else {
                LocalDataStore.shared.addLog(
                    title: "Manuel Bypass Engellendi",
                    detail: "Saat ileri alınarak bypass yapılmaya çalışılmış olabilir. 22 saat kontrolü devrede.",
                    type: .warning
                )
            }
        }
        
        return false
    }
    
    private func performResetActions(_ metadata: inout ResetMetadata, now: Date, currentWallClock: TimeInterval, currentUptime: TimeInterval, currentTimeZone: TimeZone) {
        let evaluatedDate = metadata.lastResetDate
        let calendar = Calendar.current
        let evaluatedWeekday = calendar.component(.weekday, from: evaluatedDate)
        
        var rules = LocalDataStore.shared.loadRules()
        var wasAnyRuleMonitoredYesterday = false
        var wasAnyRuleFailedYesterday = false
        
        // 1. Önceki günün durumunu değerlendir (Bypass koruması için reset öncesi kontrol)
        for rule in rules {
            if rule.isActive && rule.activeWeekdays.contains(evaluatedWeekday) {
                wasAnyRuleMonitoredYesterday = true
                if rule.isFailed {
                    wasAnyRuleFailedYesterday = true
                }
            }
        }
        
        // 2. Disiplin değerlendirmesini önceki günün tarihiyle yaz
        if wasAnyRuleMonitoredYesterday {
            if wasAnyRuleFailedYesterday {
                // Eğer dün en az 1 kısıtlama kuralı aşıldıysa bu bir ihlaldir
                DisciplineEngine.shared.recordViolation(for: evaluatedDate)
            } else {
                // Hiçbir kural ihlal edilmeden gün tamamlandıysa başarı yaz
                DisciplineEngine.shared.recordSuccess(for: evaluatedDate)
            }
        }
        
        // 3. Günlük state'leri sıfırla ve planlanan yarın güncellemelerini uygula
        for i in 0..<rules.count {
            rules[i].isFailed = false
            rules[i].currentDayState = "monitoring"
            
            if let pendingLimit = rules[i].plannedNextDayLimit {
                rules[i].dailyLimit = pendingLimit
                rules[i].plannedNextDayLimit = nil
                rules[i].lastUpdatedDate = now
                LocalDataStore.shared.addLog(
                    title: "Süre Güncellendi",
                    detail: "'\(rules[i].name)' kural süresi yürürlüğe girdi.",
                    type: .info
                )
            }
            
            if let pendingDays = rules[i].plannedNextDayActiveDays {
                rules[i].activeWeekdays = pendingDays
                rules[i].plannedNextDayActiveDays = nil
                rules[i].lastUpdatedDate = now
                LocalDataStore.shared.addLog(
                    title: "Aktif Günler Güncellendi",
                    detail: "'\(rules[i].name)' aktif gün planı yürürlüğe girdi.",
                    type: .info
                )
            }
        }
        
        LocalDataStore.shared.saveRules(rules)
        
        LocalDataStore.shared.addLog(
            title: "Güvenli Günlük Reset",
            detail: "Yeni gün sıfırlamaları başarıyla uygulandı.",
            type: .success
        )
        
        // İzleme planlarını yenile
        ScreenTimeProtectionEngine.shared.refreshMonitoring()
        
        // Metadata güncelleme
        metadata.lastResetDate = now
        metadata.lastResetWallClockTime = currentWallClock
        metadata.lastResetSystemUptime = currentUptime
        metadata.lastKnownWallClockTime = currentWallClock
        metadata.lastKnownTimeZoneIdentifier = currentTimeZone.identifier
        
        saveMetadata(metadata)
    }
    
    /// Reset metadata verilerini tamamen temizler (İlk kurulum haline döner).
    public func clearMetadata() {
        defaults.removeObject(forKey: metadataKey)
        defaults.synchronize()
    }
}
