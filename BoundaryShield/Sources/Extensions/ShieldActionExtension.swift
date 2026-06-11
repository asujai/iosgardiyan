//
//  ShieldActionExtension.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import ManagedSettings
import Foundation

// Kilit ekranındaki buton aksiyonlarını yöneten ve bypass'ı engelleyen extension.
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
            // "Ana Uygulamaya Dön" butonuna basıldığında shield KALDIRILMAZ
            LocalDataStore.shared.addLog(
                title: "Kilit Ekranı Eylemi",
                detail: "Kullanıcı kilit ekranındaki ana butona bastı. Erişim engeli korunuyor.",
                type: .info
            )
            completionHandler(.none) // Kilit ekranı kapatılmaz, bypass engellenir.
            
        case .secondaryButtonPressed:
            completionHandler(.none)
            
        @unknown default:
            completionHandler(.none)
        }
    }
}
