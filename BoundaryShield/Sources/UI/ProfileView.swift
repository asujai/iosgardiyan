//
//  ProfileView.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import SwiftUI

struct ProfileView: View {
    @AppStorage("boundaryshield_app_theme") private var savedTheme: String = "system"
    @AppStorage("boundaryshield_app_language") private var savedLanguage: String = "tr"
    
    @State private var disciplineState = DisciplineState()
    @State private var rulesCount: Int = 0
    @State private var logs: [AppLog] = []
    @State private var settings = AppSettings()
    
    @State private var isQuotesPresented = false
    @State private var isPrivacyPresented = false
    @State private var isClearDataAlertPresented = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                UITheme.backgroundDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profil kartı (Seviye ve Kırmızı Rozet)
                        profileHeaderCard
                        
                        // İstatistikler Grid'i
                        statsGrid
                        
                        // Ayarlar Bölümü
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AYARLAR")
                                .font(.caption)
                                .foregroundColor(UITheme.textSecondary)
                                .tracking(1.5)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                // Tema Seçimi
                                themeRow
                                
                                Divider().background(Color.white.opacity(0.05))
                                
                                // Dil Seçimi
                                languageRow
                                
                                Divider().background(Color.white.opacity(0.05))
                                
                                // Motivasyon Sözleri
                                NavigationLink(destination: QuotesManagementView()) {
                                    settingNavigationRow(icon: "quote.bubble.fill", title: "Motivasyon Sözlerim")
                                }
                                
                                Divider().background(Color.white.opacity(0.05))
                                
                                // Gizlilik & Veri Kullanımı
                                Button(action: { isPrivacyPresented = true }) {
                                    settingNavigationRow(icon: "lock.doc.fill", title: "Veri Kullanımı ve Gizlilik")
                                }
                            }
                            .background(UITheme.cardDark)
                            .cornerRadius(14)
                            .padding(.horizontal)
                        }
                        
                        // Aktivite Günlüğü (Log / Timeline)
                        activityTimeline
                        
                        // Kritik Eylemler (Sıfırlama)
                        VStack(spacing: 12) {
                            Button(action: {
                                isClearDataAlertPresented = true
                            }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("Tüm Verileri Temizle")
                                }
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(UITheme.errorRed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(UITheme.errorRed.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(UITheme.errorRed.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal)
                            
                            Text("Boundary Shield v1.0.0 — Native iOS")
                                .font(.caption2)
                                .foregroundColor(UITheme.textSecondary)
                                .padding(.top, 10)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isPrivacyPresented) {
                privacySheet
            }
            .alert("Tüm Verileri Temizle", isPresented: $isClearDataAlertPresented) {
                Button("İptal", role: .cancel) {}
                Button("Temizle", role: .destructive) {
                    clearAllDataAndShields()
                }
            } message: {
                Text("Bu işlem tüm kurallarınızı, log geçmişinizi, başarı serinizi ve özel sözlerinizi silecektir. Bu işlem geri alınamaz.")
            }
            .onAppear {
                loadProfileData()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var profileHeaderCard: some View {
        VStack(spacing: 16) {
            // Seviye Crown
            ZStack {
                Circle()
                    .fill(disciplineState.hasRedBadge ? UITheme.errorRed.opacity(0.15) : UITheme.copperAccent.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: disciplineState.hasRedBadge ? "exclamationmark.shield.fill" : "crown.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(disciplineState.hasRedBadge ? UITheme.errorRed : UITheme.copperAccent)
            }
            
            VStack(spacing: 6) {
                Text(disciplineState.hasRedBadge ? "Telafi Süreci" : DisciplineEngine.shared.getLevelName(for: disciplineState.level))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(UITheme.textPrimary)
                
                if disciplineState.hasRedBadge {
                    Text("Kırmızı Rozeti kaldırmak için kalan başarı günü: \(disciplineState.activeRedemptionDaysLeft)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(UITheme.errorRed)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(UITheme.errorRed.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    Text("Mevcut Seviye")
                        .font(.system(size: 13))
                        .foregroundColor(UITheme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .premiumCard()
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            statGridItem(title: "Başarı Serisi", value: "\(disciplineState.consecutiveSuccessDays) Gün", icon: "flame.fill", color: .orange)
            statGridItem(title: "Toplam Başarı", value: "\(disciplineState.totalSuccessDays) Gün", icon: "checkmark.seal.fill", color: UITheme.successGreen)
            statGridItem(title: "Aktif Sınır", value: "\(rulesCount) Sınır", icon: "hourglass", color: UITheme.copperAccent)
            statGridItem(title: "Başarı Oranı", value: formatSuccessRate(), icon: "chart.bar.fill", color: .blue)
        }
        .padding(.horizontal)
    }
    
    private func statGridItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(UITheme.textPrimary)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(UITheme.textSecondary)
            }
        }
        .padding()
        .background(UITheme.cardDark)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private var themeRow: some View {
        HStack {
            Image(systemName: "paintpalette.fill")
                .foregroundColor(UITheme.copperAccent)
                .frame(width: 24)
            Text("Tema")
                .foregroundColor(UITheme.textPrimary)
            Spacer()
            Picker("Tema", selection: $savedTheme) {
                Text("Sistem").tag("system")
                Text("Açık").tag("light")
                Text("Koyu").tag("dark")
                Text("Premium").tag("premiumDark")
            }
            .tint(UITheme.copperAccent)
        }
        .padding()
    }
    
    private var languageRow: some View {
        HStack {
            Image(systemName: "globe")
                .foregroundColor(UITheme.copperAccent)
                .frame(width: 24)
            Text("Dil")
                .foregroundColor(UITheme.textPrimary)
            Spacer()
            Picker("Dil", selection: $savedLanguage) {
                Text("Türkçe").tag("tr")
                Text("English").tag("en")
            }
            .tint(UITheme.copperAccent)
        }
        .padding()
    }
    
    private func settingNavigationRow(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(UITheme.copperAccent)
                .frame(width: 24)
            Text(title)
                .foregroundColor(UITheme.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(UITheme.textSecondary)
        }
        .padding()
    }
    
    private var activityTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AKTİVİTE GÜNLÜĞÜ")
                .font(.caption)
                .foregroundColor(UITheme.textSecondary)
                .tracking(1.5)
                .padding(.horizontal)
            
            if logs.isEmpty {
                Text("Henüz bir olay günlüğü kaydedilmedi.")
                    .font(.system(size: 14))
                    .foregroundColor(UITheme.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(UITheme.cardDark)
                    .cornerRadius(14)
                    .padding(.horizontal)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(logs.prefix(5)) { log in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(logColor(for: log.type))
                                .frame(width: 8, height: 8)
                                .padding(.top, 6)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(log.title)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(UITheme.textPrimary)
                                Text(log.detail)
                                    .font(.system(size: 12))
                                    .foregroundColor(UITheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(formatLogDate(log.timestamp))
                                    .font(.system(size: 10))
                                    .foregroundColor(UITheme.textSecondary.opacity(0.7))
                            }
                        }
                    }
                }
                .padding()
                .background(UITheme.cardDark)
                .cornerRadius(14)
                .padding(.horizontal)
            }
        }
    }
    
    private var privacySheet: some View {
        NavigationStack {
            ZStack {
                UITheme.backgroundDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Veri Kullanımı ve Gizlilik Bildirgesi")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(UITheme.textPrimary)
                            .padding(.top)
                        
                        Text("Boundary Shield, tamamen çevrimdışı (offline) çalışacak şekilde tasarlanmıştır. Gizliliğiniz bizim için en yüksek önceliktir.")
                            .font(.system(size: 14))
                            .foregroundColor(UITheme.textSecondary)
                            .lineSpacing(4)
                        
                        privacyPoint(title: "1. İnternet Erişimi Yoktur", desc: "Uygulamamız hiçbir şekilde internet bağlantısı kurmaz. Bilgileriniz herhangi bir sunucuya veya üçüncü tarafa gönderilmez.")
                        
                        privacyPoint(title: "2. Veriler Cihazınızda Kalır", desc: "Kısıtladığınız uygulamalar, disiplin seriniz ve günlük loglarınız, Apple'ın güvenli App Group UserDefaults sistemiyle şifrelenmiş olarak cihazınızda yerel olarak saklanır.")
                        
                        privacyPoint(title: "3. Apple Screen Time Entegrasyonu", desc: "Uygulama kısıtlamaları Apple'ın resmi FamilyControls ve ManagedSettings çerçeveleri üzerinden yürütülür. Bu çerçevelerin topladığı kişisel uygulama verilerine geliştirici dahil hiç kimse erişemez.")
                    }
                    .padding()
                }
            }
            .navigationTitle("Gizlilik")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kapat") { isPrivacyPresented = false }
                        .foregroundColor(UITheme.copperAccent)
                }
            }
        }
    }
    
    private func privacyPoint(title: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(UITheme.textPrimary)
            Text(desc)
                .font(.system(size: 13))
                .foregroundColor(UITheme.textSecondary)
                .lineSpacing(3)
        }
    }
    
    // MARK: - Helpers & Data Loading
    
    private func loadProfileData() {
        disciplineState = DisciplineEngine.shared.loadState()
        rulesCount = LocalDataStore.shared.loadRules().count
        logs = LocalDataStore.shared.loadLogs()
        settings = LocalDataStore.shared.loadSettings()
    }
    
    private func logColor(for type: LogType) -> Color {
        switch type {
        case .success: return UITheme.successGreen
        case .error: return UITheme.errorRed
        case .warning: return UITheme.copperAccent
        case .info: return .blue
        }
    }
    
    private func formatLogDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatSuccessRate() -> String {
        let history = disciplineState.dailyHistory
        guard !history.isEmpty else { return "%0" }
        
        let successes = history.values.filter { $0 == "success" }.count
        let total = history.count
        
        let rate = (Double(successes) / Double(total)) * 100.0
        return String(format: "%%%.0f", rate)
    }
    
    private func clearAllDataAndShields() {
        // Shield'leri temizle ve izlemeyi durdur
        ProtectionEngine.shared.clearAllShields()
        
        // Yerel verileri sıfırla
        LocalDataStore.shared.clearAllData()
        
        // Yeniden yükle
        loadProfileData()
        
        // Onboarding'e geri dönmek için yetki durumunu sıfırla
        // (Gerçek hayatta bu tetiklendiğinde uygulama izin ekranına yönlenir)
        // Burada UserDefaults yetki durumunu simüle edebiliriz.
        // Yetki durumunu tetiklemek için Notification atabiliriz.
        // Ana akış yetkisizliğe düşünce OnboardingView açılacaktır.
        // Biz simülasyon amacıyla yetki durumunu çekeceğiz.
        // Kullanıcı tüm verileri sıfırladıktan sonra uygulamadan çıkabilir veya yeniden izin alabilir.
        
        // Bildirim gönderme
        NotificationCenter.default.post(name: NSNotification.Name("AuthorizationCenterDidChange"), object: nil)
    }
}

#Preview {
    ProfileView()
}
