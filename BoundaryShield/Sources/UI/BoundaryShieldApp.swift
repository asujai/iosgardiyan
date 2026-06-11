//
//  BoundaryShieldApp.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import SwiftUI

@main
struct BoundaryShieldApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var authManager = ScreenTimeAuthorizationManager.shared
    @State private var hasCheckedReset = false
    @AppStorage(AppConfiguration.Keys.theme) private var savedTheme: String = "system"
    
    init() {
        // Güvenli günlük reset doğrulaması
        _ = SafeDailyResetManager.shared.checkAndPerformReset()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.authorizationStatus == .approved {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(authManager)
            .preferredColorScheme(selectedColorScheme)
            .onAppear {
                if !hasCheckedReset {
                    _ = SafeDailyResetManager.shared.checkAndPerformReset()
                    hasCheckedReset = true
                }
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    // Uygulama ön plana geldiğinde yetki durumunu güncelle
                    authManager.refreshAuthorizationStatus()
                    // reset durumunu kontrol et
                    _ = SafeDailyResetManager.shared.checkAndPerformReset()
                }
            }
        }
    }
    
    private var selectedColorScheme: ColorScheme? {
        switch savedTheme {
        case "light": return .light
        case "dark", "premiumDark": return .dark
        default: return nil
        }
    }
}
