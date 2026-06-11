//
//  RuleManagementSheet.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import SwiftUI

struct RuleManagementSheet: View {
    @Environment(\.dismiss) var dismiss
    
    let rule: ShieldRule
    var onUpdate: () -> Void
    
    @State private var ruleName: String = ""
    @State private var limitHour: Int = 0
    @State private var limitMinute: Int = 0
    @State private var selectedDays: Set<Int> = []
    
    // Silme Butonu İçin Basılı Tutma State'leri
    @State private var isPressing = false
    @State private var deleteProgress: Double = 0.0
    @State private var timer: Timer? = nil
    
    let weekdays = [
        (2, "Pzt"), (3, "Sal"), (4, "Çar"), (5, "Per"), (6, "Cum"), (7, "Cmt"), (1, "Paz")
    ]
    
    init(rule: ShieldRule, onUpdate: @escaping () -> Void) {
        self.rule = rule
        self.onUpdate = onUpdate
        
        // State'leri başlangıçta kural verileriyle dolduralım
        let totalMinutes = Int(rule.dailyLimitInSeconds) / 60
        _ruleName = State(initialValue: rule.name)
        _limitHour = State(initialValue: totalMinutes / 60)
        _limitMinute = State(initialValue: totalMinutes % 60)
        _selectedDays = State(initialValue: rule.activeDays)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                UITheme.backgroundDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Bilgilendirme Uyarısı
                        infoAlert
                        
                        // Kural Adı
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sınır Adı")
                                .font(.caption)
                                .foregroundColor(UITheme.textSecondary)
                                .textCase(.uppercase)
                            
                            TextField("Sınır Adı", text: $ruleName)
                                .padding()
                                .background(UITheme.cardDark)
                                .foregroundColor(UITheme.textPrimary)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Limit Ayarı
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Limit Süresi")
                                .font(.caption)
                                .foregroundColor(UITheme.textSecondary)
                                .textCase(.uppercase)
                            
                            HStack {
                                Picker("Saat", selection: $limitHour) {
                                    ForEach(0..<24, id: \.self) { hr in
                                        Text("\(hr) saat").tag(hr)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(maxWidth: .infinity)
                                
                                Picker("Dakika", selection: $limitMinute) {
                                    ForEach(0..<60, id: \.self) { min in
                                        Text("\(min) dk").tag(min)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(maxWidth: .infinity)
                            }
                            .padding()
                            .background(UITheme.cardDark)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Gün Seçimi
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Aktif Günler")
                                .font(.caption)
                                .foregroundColor(UITheme.textSecondary)
                                .textCase(.uppercase)
                            
                            HStack(spacing: 6) {
                                ForEach(weekdays, id: \.0) { id, name in
                                    let isSelected = selectedDays.contains(id)
                                    Button(action: {
                                        if isSelected {
                                            if selectedDays.count > 1 {
                                                selectedDays.remove(id)
                                            }
                                        } else {
                                            selectedDays.insert(id)
                                        }
                                    }) {
                                        Text(name)
                                            .font(.system(size: 13, weight: .bold))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(isSelected ? UITheme.copperAccent : UITheme.cardDark)
                                            .foregroundColor(isSelected ? .black : UITheme.textPrimary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Güncelle ve Kaydet Butonu
                        Button(action: saveChanges) {
                            Text("Değişiklikleri Kaydet")
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(UITheme.copperAccent)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding()
                        
                        // 5 Saniye Basılı Tutarak Silme Butonu
                        deleteButton
                            .padding(.horizontal)
                            .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Sınırı Yönet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(UITheme.copperAccent)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var infoAlert: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(UITheme.copperAccent)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Bypass Koruması Aktif")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(UITheme.textPrimary)
                Text("Bypassı engellemek için süre artırma ve gün azaltma talepleri yarın gece yarısı resetinden sonra geçerli olacaktır. Süre azaltma ve kural silme hemen uygulanabilir.")
                    .font(.system(size: 12))
                    .foregroundColor(UITheme.textSecondary)
                    .lineSpacing(2)
            }
        }
        .padding()
        .background(UITheme.copperAccent.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    private var deleteButton: some View {
        VStack(spacing: 8) {
            Text("Sınırı Kaldır (Sil)")
                .font(.caption)
                .foregroundColor(UITheme.textSecondary)
                .textCase(.uppercase)
            
            // Custom Long Press Delete Button
            ZStack(alignment: .leading) {
                // Arka plan ilerleme barı
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(UITheme.errorRed.opacity(0.25))
                        .frame(width: geo.size.width * deleteProgress)
                        .animation(.linear(duration: 0.1), value: deleteProgress)
                }
                
                HStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "trash.fill")
                        Text(isPressing ? "Basılı Tutun... (\(Int(5 - (deleteProgress * 5)))s)" : "5 Saniye Basılı Tutarak Sil")
                            .font(.system(size: 16, weight: .bold))
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
            }
            .background(UITheme.cardDark)
            .foregroundColor(UITheme.errorRed)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(UITheme.errorRed.opacity(0.4), lineWidth: 1)
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressing {
                            startDeleteTimer()
                        }
                    }
                    .onEnded { _ in
                        stopDeleteTimer()
                    }
            )
        }
    }
    
    // MARK: - Core Operations
    
    private func saveChanges() {
        var rules = LocalDataStore.shared.loadRules()
        guard let index = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        
        let newSeconds = TimeInterval((limitHour * 3600) + (limitMinute * 60))
        
        // 1. Süre Artış Kontrolü (Aynı gün artış engellenir, yarına planlanır)
        if newSeconds > rule.dailyLimitInSeconds {
            rules[index].pendingNewLimitInSeconds = newSeconds
            LocalDataStore.shared.addLog(
                title: "Limit Artışı Planlandı",
                detail: "'\(rule.name)' limit artış talebi bypass koruması nedeniyle yarına planlandı.",
                type: .info
            )
        } else if newSeconds < rule.dailyLimitInSeconds {
            // Süre azaltımı hemen uygulanabilir
            rules[index].dailyLimitInSeconds = newSeconds
            rules[index].pendingNewLimitInSeconds = nil
            // İzlemeyi güncelle
            ProtectionEngine.shared.startMonitoring(rule: rules[index])
            LocalDataStore.shared.addLog(
                title: "Limit Azaltıldı",
                detail: "'\(rule.name)' kural limiti hemen uygulandı.",
                type: .success
            )
        }
        
        // 2. Aktif Gün Değişikliği (Yarına planlanır)
        if selectedDays != rule.activeDays {
            rules[index].pendingActiveDays = selectedDays
            LocalDataStore.shared.addLog(
                title: "Gün Değişikliği Planlandı",
                detail: "'\(rule.name)' aktif gün değişiklikleri yarına planlandı.",
                type: .info
            )
        }
        
        rules[index].name = ruleName
        LocalDataStore.shared.saveRules(rules)
        onUpdate()
        dismiss()
    }
    
    // MARK: - Delete Timer Management
    
    private func startDeleteTimer() {
        isPressing = true
        deleteProgress = 0.0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if deleteProgress < 1.0 {
                deleteProgress += 0.02 // 0.1 saniyede %2 artış -> 5 saniyede %100 olur
            } else {
                // 5 saniye tamamlandı, silme işlemini yap
                stopDeleteTimer()
                performDelete()
            }
        }
    }
    
    private func stopDeleteTimer() {
        isPressing = false
        timer?.invalidate()
        timer = nil
        
        // Eğer tamamlanmadan bırakıldıysa sıfırla
        if deleteProgress < 1.0 {
            deleteProgress = 0.0
        }
    }
    
    private func performDelete() {
        var rules = LocalDataStore.shared.loadRules()
        rules.removeAll(where: { $0.id == rule.id })
        LocalDataStore.shared.saveRules(rules)
        
        // Monitoring sonlandır ve shield kaldır
        ProtectionEngine.shared.stopMonitoring(rule: rule)
        
        LocalDataStore.shared.addLog(
            title: "Sınır Kuralı Silindi",
            detail: "'\(rule.name)' kuralı basılı tutularak silindi ve takibi sonlandırıldı.",
            type: .warning
        )
        
        onUpdate()
        dismiss()
    }
}

#Preview {
    RuleManagementSheet(rule: ShieldRule(name: "Test Sınırı", dailyLimitInSeconds: 3600)) {}
}
