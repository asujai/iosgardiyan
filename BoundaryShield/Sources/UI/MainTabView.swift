//
//  MainTabView.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    
    init() {
        // Tab bar görünümünü özelleştirme
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(UITheme.backgroundDark)
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Ana Sayfa", systemImage: "house.fill")
                }
                .tag(0)
            
            ProtectionView()
                .tabItem {
                    Label("Koruma", systemImage: "shield.fill")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.fill")
                }
                .tag(2)
        }
        .tint(UITheme.copperAccent)
        .background(UITheme.backgroundDark.ignoresSafeArea())
    }
}

#Preview {
    MainTabView()
}
