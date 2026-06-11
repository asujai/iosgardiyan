//
//  OnboardingView.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import SwiftUI
import FamilyControls
import UserNotifications

struct OnboardingView: View {
    @EnvironmentObject var protectionEngine: ProtectionEngine
    @State private var isRequesting = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            UITheme.backgroundDark.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo / Simge
                ZStack {
                    Circle()
                        .fill(UITheme.copperAccent.opacity(0.15))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "shield.star.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundStyle(UITheme.copperGradient)
                }
                .padding(.bottom, 10)
                
                // Başlıklar
                VStack(spacing: 12) {
                    Text("Boundary Shield")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(UITheme.textPrimary)
                    
                    Text("Dijital Sınırlarını Çiz, İradeni Güçlendir")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(UITheme.textSecondary)
                }
                .multilineTextAlignment(.center)
                
                Spacer()
                
                // Bilgilendirme Maddeleri
                VStack(alignment: .leading, spacing: 20) {
                    onboardingFeature(
                        icon: "hourglass.badge.plus",
                        title: "Kendi Sınırlarını Koy",
                        desc: "Dikkat dağıtan uygulamalara günlük süre limitleri belirle."
                    )
                    
                    onboardingFeature(
                        icon: "lock.shield.fill",
                        title: "Resmi iOS Koruması",
                        desc: "Süre sınırın dolunca Screen Time sistemiyle uygulamalara erişim engellenir."
                    )
                    
                    onboardingFeature(
                        icon: "hand.raised.fill",
                        title: "Tavizsiz Disiplin",
                        desc: "Kolay bypass engelleri ve 21 günlük serilerle hedefine sadık kal."
                    )
                    
                    onboardingFeature(
                        icon: "eye.slash.fill",
                        title: "%100 Yerel ve Gizli",
                        desc: "Tüm verileriniz sadece kendi cihazınızda yerel olarak saklanır."
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(UITheme.errorRed)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // İzin Verme Butonu
                Button(action: {
                    requestPermissionFlow()
                }) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.black)
                                .padding(.trailing, 8)
                        }
                        Text("Kuruluma Başla ve İzin Ver")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(UITheme.copperGradient)
                    .foregroundColor(.black)
                    .cornerRadius(14)
                    .shadow(color: UITheme.copperAccent.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isRequesting)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func onboardingFeature(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(UITheme.copperAccent)
                .frame(width: 30)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(UITheme.textPrimary)
                Text(desc)
                    .font(.system(size: 14))
                    .foregroundColor(UITheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private func requestPermissionFlow() {
        isRequesting = true
        errorMessage = nil
        
        Task {
            do {
                // 1. Ekran Süresi İzni
                try await protectionEngine.requestAuthorization()
                
                // 2. Bildirim İzni (İsteğe bağlı, hataya sebep olmamalı)
                let _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                
                DispatchQueue.main.async {
                    self.isRequesting = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isRequesting = false
                    self.errorMessage = "Screen Time izni reddedildi. Ayarlardan izin vermeniz gerekmektedir."
                }
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(ProtectionEngine.shared)
}
