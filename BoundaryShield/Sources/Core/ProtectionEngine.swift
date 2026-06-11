//
//  ProtectionEngine.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import Foundation
import FamilyControls
import DeviceActivity
import ManagedSettings
import Combine

/// Screen Time API yetkilendirmelerini, kural schedule'larını ve Shield durumlarını yöneten motor.
public final class ProtectionEngine: ObservableObject {
    public static let shared = ProtectionEngine()
    
    private let center = AuthorizationCenter.shared
    private let activityCenter = DeviceActivityCenter()
    private let store = ManagedSettingsStore()
    
    @Published public var authorizationStatus: AuthorizationStatus = .notDetermined
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        self.authorizationStatus = center.authorizationStatus
        
        // İzin değişikliklerini izle
        NotificationCenter.default.publisher(for: NSNotification.Name("AuthorizationCenterDidChange"))
            .sink { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.authorizationStatus = self.center.authorizationStatus
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Authorization
    
    /// Kullanıcıdan Screen Time (FamilyControls) izni ister.
    @MainActor
    public func requestAuthorization() async throws {
        do {
            try await center.requestAuthorization(for: .individual)
            authorizationStatus = center.authorizationStatus
            LocalDataStore.shared.addLog(
                title: "Ekran Süresi İzni",
                detail: "Screen Time izni başarıyla güncellendi: \(String(describing: authorizationStatus))",
                type: .info
            )
        } catch {
            LocalDataStore.shared.addLog(
                title: "İzin Hatası",
                detail: "Screen Time izin isteği başarısız oldu: \(error.localizedDescription)",
                type: .error
            )
            throw error
        }
    }
    
    // MARK: - Schedule & Monitoring
    
    /// Belirtilen kural için DeviceActivity izlemesini başlatır.
    public func startMonitoring(rule: ShieldRule) {
        guard authorizationStatus == .approved else {
            print("WARNING: Screen Time permission not approved. Monitoring not started.")
            return
        }
        
        let activityName = DeviceActivityName(rule.id.uuidString)
        
        // Kuralın aktif günlerini ve limitini ayarla
        // Not: iOS DeviceActivitySchedule için zaman aralığı (interval) belirlenir.
        // Limit dolduğunda DeviceActivityMonitorExtension uyarılacaktır.
        let limitHour = Int(rule.dailyLimitInSeconds) / 3600
        let limitMinute = (Int(rule.dailyLimitInSeconds) % 3600) / 60
        
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let threshold = DateComponents(hour: limitHour, minute: limitMinute)
        let event = DeviceActivityEvent(
            applications: rule.selection.applicationTokens,
            categories: rule.selection.categoryTokens,
            webDomains: rule.selection.webDomainTokens,
            threshold: threshold
        )
        
        do {
            try activityCenter.startMonitoring(
                activityName,
                during: schedule,
                events: [DeviceActivityEvent.Name(rule.id.uuidString): event]
            )
            LocalDataStore.shared.addLog(
                title: "Kural İzleme Başladı",
                detail: "'\(rule.name)' kuralı için \(limitHour) sa \(limitMinute) dk limit izleniyor.",
                type: .info
            )
        } catch {
            LocalDataStore.shared.addLog(
                title: "İzleme Hatası",
                detail: "'\(rule.name)' izlemesi başlatılamadı: \(error.localizedDescription)",
                type: .error
            )
        }
    }
    
    /// Belirtilen kuralın izlemesini durdurur.
    public func stopMonitoring(rule: ShieldRule) {
        let activityName = DeviceActivityName(rule.id.uuidString)
        activityCenter.stopMonitoring([activityName])
        
        // Eğer bu kural için shield aktifse kaldır
        removeShield(for: rule)
        
        LocalDataStore.shared.addLog(
            title: "Kural İzleme Durduruldu",
            detail: "'\(rule.name)' kuralının takibi sonlandırıldı.",
            type: .info
        )
    }
    
    // MARK: - Shield Management
    
    /// Kuralın seçili uygulamalarını engeller (Shield uygular).
    public func applyShield(for rule: ShieldRule) {
        // ManagedSettingsStore kullanarak uygulamaları shield altına alıyoruz
        // Birden fazla kural varsa hepsinin tokenlarını birleştirip tek bir store'a atamak veya
        // extension tarafında dinamik yönetmek en doğrusudur.
        // Burada doğrudan ManagedSettingsStore'a ekliyoruz.
        
        var currentApplications = store.shield.applications ?? []
        var currentCategories = store.shield.applicationCategories ?? []
        var currentWebDomains = store.shield.webDomains ?? []
        
        // Kuralın seçimlerini ekle
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
            title: "Koruma Aktifleşti",
            detail: "'\(rule.name)' limiti dolduğu için engelleme uygulandı.",
            type: .warning
        )
    }
    
    /// Kuralın seçili uygulamalarının engelini kaldırır.
    public func removeShield(for rule: ShieldRule) {
        var currentApplications = store.shield.applications ?? []
        var currentCategories = store.shield.applicationCategories ?? []
        var currentWebDomains = store.shield.webDomains ?? []
        
        // Kuralın seçimlerini kaldır
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
    
    /// Tüm engelleri temizler.
    public func clearAllShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        
        // İzlemeleri durdur
        activityCenter.stopMonitoring()
        
        LocalDataStore.shared.addLog(
            title: "Tüm Engeller Kaldırıldı",
            detail: "Güvenli sıfırlama veya silme işlemi nedeniyle tüm engeller temizlendi.",
            type: .info
        )
    }
}
