//
//  ShieldActionExtension.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import ManagedSettings
import Foundation

// Kilit ekranındaki buton aksiyonlarını yöneten ve kolay bypass'ı engelleyen extension.
public class ShieldActionExtension: ShieldActionDelegate {
    
    public override func handle(action: ShieldAction, for application: Application, completionHandler: @escaping (ShieldActionOutcome) -> Void) {
        handleShieldAction(action, completionHandler: completionHandler)
    }
    
    public override func handle(action: ShieldAction, for category: ActivityCategory, completionHandler: @escaping (ShieldActionOutcome) -> Void) {
        handleShieldAction(action, completionHandler: completionHandler)
    }
    
    public override func handle(action: ShieldAction, for webDomain: WebDomain, completionHandler: @escaping (ShieldActionOutcome) -> Void) {
        handleShieldAction(action, completionHandler: completionHandler)
    }
    
    private func handleShieldAction(_ action: ShieldAction, completionHandler: @escaping (ShieldActionOutcome) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // "Ana Uygulamaya Dön" butonuna basıldığında shield KALDIRILMAZ,
            // sadece eylem ertelenir veya tamamlanır. Kolay bypass olmaması için completionHandler'a (.defer) dönüyoruz.
            // Bu sayede sistem engellemeye devam eder ve kullanıcı bypass edemez.
            LocalDataStore.shared.addLog(
                title: "Kilit Ekranı Eylemi",
                detail: "Kullanıcı kilit ekranındaki ana butona bastı. Erişim engeli korunuyor.",
                type: .info
            )
            completionHandler(.none) // Kilit ekranı kapanmaz, bypass engellenir.
            
        case .secondaryButtonPressed:
            completionHandler(.none)
            
        @unknown default:
            completionHandler(.none)
        }
    }
}
