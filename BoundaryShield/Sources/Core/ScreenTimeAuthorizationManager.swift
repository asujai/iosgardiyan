//
//  ScreenTimeAuthorizationManager.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import Foundation
import FamilyControls
import Combine

/// Screen Time (FamilyControls) yetkilendirme süreçlerini yöneten modüler servis.
public final class ScreenTimeAuthorizationManager: ObservableObject {
    public static let shared = ScreenTimeAuthorizationManager()
    
    private let center = AuthorizationCenter.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published public var authorizationStatus: AuthorizationStatus = .notDetermined
    
    private init() {
        self.authorizationStatus = center.authorizationStatus
        
        // Yetki durum değişikliklerini dinle
        NotificationCenter.default.publisher(for: NSNotification.Name("AuthorizationCenterDidChange"))
            .sink { [weak self] _ in
                self?.refreshAuthorizationStatus()
            }
            .store(in: &cancellables)
    }
    
    /// Yetki durumunu doğrudan Aile Denetimleri merkezinden okuyarak günceller.
    public func refreshAuthorizationStatus() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.authorizationStatus = self.center.authorizationStatus
        }
    }
    
    /// Aile denetimleri (Screen Time) izni talep eder (Swift Concurrency).
    @MainActor
    public func requestAuthorization() async throws {
        do {
            try await center.requestAuthorization(for: .individual)
            refreshAuthorizationStatus()
            LocalDataStore.shared.addLog(
                title: "İzin Talebi",
                detail: "Screen Time izni talep edildi. Durum: \(String(describing: authorizationStatus))",
                type: .info
            )
        } catch {
            LocalDataStore.shared.addLog(
                title: "İzin Hatası",
                detail: "İzin alma başarısız oldu: \(error.localizedDescription)",
                type: .error
            )
            throw error
        }
    }
}
