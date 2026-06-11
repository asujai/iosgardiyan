//
//  BoundaryShieldApp.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import SwiftUI

@main
struct BoundaryShieldApp: App {
    @StateObject private var protectionEngine = ProtectionEngine.shared
    @State private var hasCheckedReset = false
    @AppStorage("boundaryshield_app_theme") private var savedTheme: String = "system"
    
    init() {
        // Güvenli günlük reset kontrolü
        _ = SafeDailyResetManager.shared.checkAndPerformReset()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if protectionEngine.authorizationStatus == .approved {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(protectionEngine)
            .preferredColorScheme(selectedColorScheme)
            .onAppear {
                if !hasCheckedReset {
                    _ = SafeDailyResetManager.shared.checkAndPerformReset()
                    hasCheckedReset = true
                }
            }
        }
    }
    
    private var selectedColorScheme: ColorScheme? {
        switch savedTheme {
        case "light": return .light
        case "dark", "premiumDark": return .dark
        default: return nil // System theme
        }
    }
}
