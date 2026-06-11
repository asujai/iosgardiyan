//
//  DisciplineEngine.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import Foundation

/// Disiplin, başarı, seviye ve ihlal kurallarını kontrol eden motor.
public final class DisciplineEngine {
    public static let shared = DisciplineEngine()
    
    private let store = AppGroupStore.shared
    
    private init() {}
    
    // MARK: - State Management
    
    public func loadState() -> DisciplineState {
        return store.load(forKey: AppConfiguration.Keys.disciplineState) ?? DisciplineState()
    }
    
    public func saveState(_ state: DisciplineState) {
        store.save(state, forKey: AppConfiguration.Keys.disciplineState)
    }
    
    // MARK: - Core Operations
    
    /// Günlük başarı serisini işler.
    public func recordSuccess(for date: Date = Date()) {
        var state = loadState()
        let dateKey = formatDate(date)
        
        // Zaten o gün için veri kaydedildiyse tekrar kaydetme
        if state.dailyHistory[dateKey] == "success" { return }
        
        state.dailyHistory[dateKey] = "success"
        state.totalSuccessDays += 1
        state.lastSuccessDate = date
        
        if state.hasRedBadge {
            // Telafi sürecinde ise
            state.activeRedemptionDaysLeft = max(0, state.activeRedemptionDaysLeft - 1)
            if state.activeRedemptionDaysLeft == 0 {
                state.hasRedBadge = false
                LocalDataStore.shared.addLog(
                    title: "Rozet Temizlendi",
                    detail: "2 günlük başarı telafi serisini tamamlayarak Kırmızı Rozet'i kaldırdınız!",
                    type: .success
                )
                NotificationManager.shared.sendLocalNotification(
                    title: "İrade Madalyası",
                    body: "Kırmızı Rozet başarıyla kaldırıldı! Odaklanmaya devam et."
                )
            } else {
                LocalDataStore.shared.addLog(
                    title: "Telafi Günü Başarılı",
                    detail: "Kırmızı rozetin kalkması için 1 başarılı gün daha gerekiyor.",
                    type: .info
                )
            }
        } else {
            // Normal başarı serisi
            state.consecutiveSuccessDays += 1
            let oldLevel = state.level
            state.level = calculateLevel(consecutiveSuccessDays: state.consecutiveSuccessDays)
            
            if state.level > oldLevel {
                LocalDataStore.shared.addLog(
                    title: "Yeni Seviye!",
                    detail: "Seviyeniz \(oldLevel)'den \(state.level)'e yükseldi.",
                    type: .success
                )
                NotificationManager.shared.sendLocalNotification(
                    title: "Seviye Atladınız!",
                    body: "Tebrikler, yeni rütbeniz: \(getLevelName(for: state.level))"
                )
            } else {
                LocalDataStore.shared.addLog(
                    title: "Gün Başarılı",
                    detail: "Bugünkü sınırlarınıza başarıyla uydunuz. Seri: \(state.consecutiveSuccessDays) gün.",
                    type: .success
                )
            }
        }
        
        saveState(state)
    }
    
    /// Bypass veya sınır kuralı ihlali yapıldığında tetiklenir.
    public func recordViolation(for date: Date = Date()) {
        var state = loadState()
        let dateKey = formatDate(date)
        
        // Zaten o gün için ihlal kaydedildiyse tekrar kaydetme
        if state.dailyHistory[dateKey] == "violation" { return }
        
        state.dailyHistory[dateKey] = "violation"
        state.lastViolationDate = date
        
        // İhlal Cezası
        state.consecutiveSuccessDays = 0
        state.level = 1
        state.hasRedBadge = true
        state.redemptionStreakGoal = 2
        state.activeRedemptionDaysLeft = 2
        
        LocalDataStore.shared.addLog(
            title: "Disiplin İhlal Edildi!",
            detail: "Kural bypass edildi veya ihlal oluştu. Seviyeniz 1'e düşürüldü, Kırmızı Rozet verildi.",
            type: .error
        )
        
        NotificationManager.shared.sendLocalNotification(
            title: "Disiplin İhlali!",
            body: "Sınırlarınız ihlal edildi. Seviyeniz sıfırlandı ve Kırmızı Rozet aldınız."
        )
        
        saveState(state)
    }
    
    // MARK: - Levels
    
    public func getLevelName(for level: Int) -> String {
        switch level {
        case 1: return "Başlangıç (Level 1)"
        case 2: return "Demir İrade (Level 2)"
        case 3: return "Çelik Koruyucu (Level 3)"
        case 4: return "Odak Ustası (Level 4)"
        case 5: return "Zaman Hakimi (Level 5)"
        case 6: return "Disiplin Anıtı (Level 6)"
        default: return "Bilinmeyen Rütbe"
        }
    }
    
    private func calculateLevel(consecutiveSuccessDays: Int) -> Int {
        if consecutiveSuccessDays >= 60 { return 6 }
        if consecutiveSuccessDays >= 30 { return 5 }
        if consecutiveSuccessDays >= 15 { return 4 }
        if consecutiveSuccessDays >= 7  { return 3 }
        if consecutiveSuccessDays >= 3  { return 2 }
        return 1
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
}
