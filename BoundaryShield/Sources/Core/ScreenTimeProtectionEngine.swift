//
//  ScreenTimeProtectionEngine.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import Foundation
import DeviceActivity
import FamilyControls
import Combine

/// Yetkilendirme durumuna göre DeviceActivity izlemelerini başlatan ve durduran koruma motoru.
public final class ScreenTimeProtectionEngine: ObservableObject {
    public static let shared = ScreenTimeProtectionEngine()
    
    private let activityCenter = DeviceActivityCenter()
    private let authManager = ScreenTimeAuthorizationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // İzin durumunu dinle ve duruma göre izlemeleri yenile
        authManager.$authorizationStatus
            .sink { [weak self] status in
                if status == .approved {
                    self?.refreshMonitoring()
                } else {
                    self?.clearAllMonitoring()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Belirtilen kural için günlük limit izleme programını başlatır.
    public func startMonitoring(rule: AppLimitRule) {
        guard authManager.authorizationStatus == .approved else {
            print("WARNING: Screen Time permission not approved. Cannot start monitoring for \(rule.name).")
            return
        }
        
        let activityName = DeviceActivityName(rule.id.uuidString)
        let schedule = DeviceActivityScheduleBuilder.buildSchedule()
        let event = DeviceActivityScheduleBuilder.buildEvent(for: rule)
        let eventName = DeviceActivityEvent.Name(rule.id.uuidString)
        
        do {
            try activityCenter.startMonitoring(
                activityName,
                during: schedule,
                events: [eventName: event]
            )
            LocalDataStore.shared.addLog(
                title: "İzleme Başlatıldı",
                detail: "'\(rule.name)' kuralı için günlük süre limit takibi aktif.",
                type: .info
            )
        } catch {
            LocalDataStore.shared.addLog(
                title: "İzleme Başlatılamadı",
                detail: "'\(rule.name)' izlemesi başlatılırken hata oluştu: \(error.localizedDescription)",
                type: .error
            )
        }
    }
    
    /// Belirtilen kuralın takibini durdurur ve kilitlerini kaldırır.
    public func stopMonitoring(rule: AppLimitRule) {
        let activityName = DeviceActivityName(rule.id.uuidString)
        activityCenter.stopMonitoring([activityName])
        
        // Kilit varsa kaldır
        ShieldStoreManager.shared.removeShield(for: rule)
        
        LocalDataStore.shared.addLog(
            title: "İzleme Durduruldu",
            detail: "'\(rule.name)' kural takibi ve engeli sonlandırıldı.",
            type: .info
        )
    }
    
    /// Sistemdeki tüm izlemeleri sonlandırır ve tüm kilitleri temizler.
    public func clearAllMonitoring() {
        activityCenter.stopMonitoring()
        ShieldStoreManager.shared.clearAllShields()
        
        LocalDataStore.shared.addLog(
            title: "Tüm Korumalar Kapatıldı",
            detail: "Aktif tüm sınırlar ve kilitler devre dışı bırakıldı.",
            type: .warning
        )
    }
    
    /// Kayıtlı kuralları yükleyip, aktiflik durumlarına göre izlemeleri günceller.
    public func refreshMonitoring() {
        let rules = LocalDataStore.shared.loadRules()
        
        // Önce tüm izlemeyi durdur
        activityCenter.stopMonitoring()
        
        // Aktif kurallar için izlemeleri yeniden başlat
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: Date())
        
        for rule in rules {
            if rule.isActive {
                // Eğer bugün kuralın aktif günlerinden biriyse izlemeyi başlat
                if rule.activeWeekdays.contains(todayWeekday) {
                    startMonitoring(rule: rule)
                    
                    // Eğer limit bugün zaten dolmuşsa shield'ı tekrar uygula
                    if rule.isFailed {
                        ShieldStoreManager.shared.applyShield(for: rule)
                    }
                } else {
                    // Bugün aktif değilse kısıtlamalarını kaldır
                    ShieldStoreManager.shared.removeShield(for: rule)
                }
            }
        }
    }
}
