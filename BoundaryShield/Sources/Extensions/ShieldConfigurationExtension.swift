//
//  ShieldConfigurationExtension.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit
import Foundation

// Limit aşımında çıkan kilit ekranının (shield) görünüm konfigürasyonu.
public class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    public override func configuration(shielding application: Application) -> ShieldConfiguration {
        return makeCustomConfiguration()
    }
    
    public override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return makeCustomConfiguration()
    }
    
    public override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return makeCustomConfiguration()
    }
    
    public override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return makeCustomConfiguration()
    }
    
    private func makeCustomConfiguration() -> ShieldConfiguration {
        // App Group UserDefaults üzerinden rastgele bir motivasyon sözü seçelim
        let quote = QuoteManager.shared.getRandomActiveQuote()
        
        let displayTitle = "Bugünkü Limitin Doldu"
        let displaySubtitle = "Bu sınırı sen belirledin. Bugünlük burada dur.\n\n\"\(quote.text)\"\n— \(quote.author)"
        
        return ShieldConfiguration(
            backgroundEffect: UIBlurEffect(style: .dark),
            backgroundColor: UIColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 1.0), // Obsidyen
            title: ShieldConfiguration.Label(
                text: displayTitle,
                color: UIColor(red: 0.82, green: 0.45, blue: 0.32, alpha: 1.0) // Bakır
            ),
            subtitle: ShieldConfiguration.Label(
                text: displaySubtitle,
                color: .white
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Ana Uygulamaya Dön",
                color: .black
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.82, green: 0.45, blue: 0.32, alpha: 1.0), // Bakır
            secondaryButtonLabel: nil
        )
    }
}
