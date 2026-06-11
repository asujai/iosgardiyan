//
//  DisciplineEngine.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import Foundation

/// Disiplin durumunu temsil eden veri modeli.
public struct DisciplineState: Codable {
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

/// Disiplin, başarı, seviye ve ihlal yönetimini kontrol eden motor.
public final class DisciplineEngine {
    public static let shared = DisciplineEngine()
    
    private let defaults: UserDefaults
    
    private init() {
        self.defaults = UserDefaults(suiteName: AppConfig.appGroupId) ?? UserDefaults.standard
    }
    
    // MARK: - State Management
    
    public func loadState() -> DisciplineState {
        guard let data = defaults.data(forKey: AppConfig.Keys.disciplineState),
              let state = try? JSONDecoder().decode(DisciplineState.self, from: data) else {
            return DisciplineState()
        }
        return state
    }
    
    public func saveState(_ state: DisciplineState) {
        if let encoded = try? JSONEncoder().encode(state) {
            defaults.set(encoded, forKey: AppConfig.Keys.disciplineState)
            defaults.synchronize()
        }
    }
    
    // MARK: - Actions
    
    /// Günlük başarı durumunu işler.
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
                    title: "Kırmızı Rozet Kaldırıldı",
                    detail: "2 günlük telafi serisini başarıyla tamamladınız ve kırmızı rozetten kurtuldunuz!",
                    type: .success
                )
            } else {
                LocalDataStore.shared.addLog(
                    title: "Telafi Başarısı",
                    detail: "Kırmızı rozeti kaldırmak için 1 başarılı gün daha gerekiyor.",
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
                    title: "Seviye Atlandı!",
                    detail: "Tebrikler! Seviyeniz \(oldLevel)'den \(state.level)'e yükseldi.",
                    type: .success
                )
            } else {
                LocalDataStore.shared.addLog(
                    title: "Başarı Kaydedildi",
                    detail: "Bugünkü limitlerinize uydunuz. Mevcut seriniz: \(state.consecutiveSuccessDays) gün.",
                    type: .success
                )
            }
        }
        
        saveState(state)
    }
    
    /// İhlal durumunu işler (kural aşımı veya kuralın bypass edilmesi).
    public func recordViolation(for date: Date = Date()) {
        var state = loadState()
        let dateKey = formatDate(date)
        
        // Zaten o gün için ihlal kaydedildiyse tekrar kaydetme
        if state.dailyHistory[dateKey] == "violation" { return }
        
        state.dailyHistory[dateKey] = "violation"
        state.lastViolationDate = date
        
        // İhlal cezası
        state.consecutiveSuccessDays = 0
        state.level = 1
        state.hasRedBadge = true
        state.redemptionStreakGoal = 2
        state.activeRedemptionDaysLeft = 2
        
        LocalDataStore.shared.addLog(
            title: "Disiplin İhlali!",
            detail: "Sınırlarınız aşıldı veya kurallar ihlal edildi. Seviyeniz 1'e düşürüldü ve Kırmızı Rozet aldınız.",
            type: .error
        )
        
        saveState(state)
    }
    
    /// Seviye ismini döner.
    public func getLevelName(for level: Int) -> String {
        switch level {
        case 1: return "Başlangıç (Level 1)"
        case 2: return "Demir İrade (Level 2)"
        case 3: return "Çelik Koruyucu (Level 3)"
        case 4: return "Odak Ustası (Level 4)"
        case 5: return "Zaman Hakimi (Level 5)"
        case 6: return "Disiplin Anıtı (Level 6)"
        default: return "Bilinmeyen Seviye"
        }
    }
    
    // MARK: - Helpers
    
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
