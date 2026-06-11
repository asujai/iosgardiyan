//
//  RuleManagementSheet.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import SwiftUI

struct RuleManagementSheet: View {
    @Environment(\.dismiss) var dismiss
    
    let rule: AppLimitRule
    var onUpdate: () -> Void
    
    @State private var ruleName: String = ""
    @State private var limitHour: Int = 0
    @State private var limitMinute: Int = 0
    @State private var selectedDays: Set<Int> = []
    @State private var errorMessage: String? = nil
    
    // Silme Butonu İçin Basılı Tutma State'leri
    @State private var isPressing = false
    @State private var deleteProgress: Double = 0.0
    @State private var timer: Timer? = nil
    
    let weekdays = [
        (2, "Pzt"), (3, "Sal"), (4, "Çar"), (5, "Per"), (6, "Cum"), (7, "Cmt"), (1, "Paz")
    ]
    
    init(rule: AppLimitRule, onUpdate: @escaping () -> Void) {
        self.rule = rule
        self.onUpdate = onUpdate
        
        let totalMinutes = Int(rule.dailyLimit) / 60
        _ruleName = State(initialValue: rule.name)
        _limitHour = State(initialValue: totalMinutes / 60)
        _limitMinute = State(initialValue: totalMinutes % 60)
        _selectedDays = State(initialValue: rule.activeWeekdays)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                UITheme.backgroundDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        infoAlert
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(UITheme.errorRed)
                                .padding(.horizontal)
                        }
                        
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
                            .onChange(of: limitHour) { _ in validateTime() }
                            .onChange(of: limitMinute) { _ in validateTime() }
                        }
                        .padding(.horizontal)
                        
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
                        
                        Button(action: saveChanges) {
                            Text("Değişiklikleri Kaydet")
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(isSaveDisabled ? Color.gray.opacity(0.3) : UITheme.copperAccent)
                                .foregroundColor(isSaveDisabled ? UITheme.textSecondary : .black)
                                .cornerRadius(12)
                        }
                        .disabled(isSaveDisabled)
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding()
                        
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
            
            ZStack(alignment: .leading) {
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
    
    // MARK: - Validation
    
    private var isSaveDisabled: Bool {
        let isTimeZero = limitHour == 0 && limitMinute == 0
        let isNameEmpty = ruleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return isTimeZero || isNameEmpty || selectedDays.isEmpty
    }
    
    private func validateTime() {
        if limitHour == 0 && limitMinute == 0 {
            errorMessage = "Süre limiti 0 olamaz. En az 1 dakika seçmelisiniz."
        } else {
            errorMessage = nil
        }
    }
    
    // MARK: - Core Operations
    
    private func saveChanges() {
        var rules = LocalDataStore.shared.loadRules()
        guard let index = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        
        let newSeconds = TimeInterval((limitHour * 3600) + (limitMinute * 60))
        
        // 0 dakika kontrolü
        if newSeconds == 0 {
            errorMessage = "Geçersiz süre."
            return
        }
        
        // 1. Süre Artış Kontrolü (Yarına planlanır)
        if newSeconds > rule.dailyLimit {
            rules[index].plannedNextDayLimit = newSeconds
            LocalDataStore.shared.addLog(
                title: "Limit Artışı Planlandı",
                detail: "'\(rule.name)' limit artış talebi yarına planlandı.",
                type: .info
            )
        } else if newSeconds < rule.dailyLimit {
            // Süre azaltımı hemen uygulanır (Güvenli monitoring yenilemesi)
            // Önce durdur
            ScreenTimeProtectionEngine.shared.stopMonitoring(rule: rules[index])
            
            // Güncelle ve kaydet
            rules[index].dailyLimit = newSeconds
            rules[index].plannedNextDayLimit = nil
            LocalDataStore.shared.saveRules(rules)
            
            // Yeniden başlat
            ScreenTimeProtectionEngine.shared.startMonitoring(rule: rules[index])
            
            LocalDataStore.shared.addLog(
                title: "Limit Azaltıldı",
                detail: "'\(rule.name)' kural limiti güvenli şekilde yenilenerek hemen uygulandı.",
                type: .success
            )
        }
        
        // 2. Aktif Gün Değişikliği (Yarına planlanır)
        if selectedDays != rule.activeWeekdays {
            rules[index].plannedNextDayActiveDays = selectedDays
            LocalDataStore.shared.addLog(
                title: "Gün Değişikliği Planlandı",
                detail: "'\(rule.name)' aktif gün değişiklikleri yarına planlandı.",
                type: .info
            )
        }
        
        rules[index].name = ruleName
        rules[index].lastUpdatedDate = Date()
        LocalDataStore.shared.saveRules(rules)
        onUpdate()
        dismiss()
    }
    
    private func startDeleteTimer() {
        isPressing = true
        deleteProgress = 0.0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if deleteProgress < 1.0 {
                deleteProgress += 0.02
            } else {
                stopDeleteTimer()
                performDelete()
            }
        }
    }
    
    private func stopDeleteTimer() {
        isPressing = false
        timer?.invalidate()
        timer = nil
        
        if deleteProgress < 1.0 {
            deleteProgress = 0.0
        }
    }
    
    private func performDelete() {
        var rules = LocalDataStore.shared.loadRules()
        rules.removeAll(where: { $0.id == rule.id })
        LocalDataStore.shared.saveRules(rules)
        
        ScreenTimeProtectionEngine.shared.stopMonitoring(rule: rule)
        
        LocalDataStore.shared.addLog(
            title: "Sınır Silindi",
            detail: "'\(rule.name)' kısıtlama kuralı kaldırıldı.",
            type: .warning
        )
        
        onUpdate()
        dismiss()
    }
}
