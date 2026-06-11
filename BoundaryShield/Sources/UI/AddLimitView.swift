//
//  AddLimitView.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import SwiftUI
import FamilyControls

struct AddLimitView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var ruleName: String = ""
    @State private var selection = FamilyActivitySelection()
    @State private var limitHour: Int = 1
    @State private var limitMinute: Int = 0
    @State private var activeDays: Set<Int> = Set([2, 3, 4, 5, 6]) // Varsayılan: Hafta içi
    @State private var errorMessage: String? = nil
    
    let weekdays = [
        (2, "Pzt"), (3, "Sal"), (4, "Çar"), (5, "Per"), (6, "Cum"), (7, "Cmt"), (1, "Paz")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                UITheme.backgroundDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
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
                            
                            TextField("Örn: Sosyal Medya Detoksu", text: $ruleName)
                                .padding()
                                .background(UITheme.cardDark)
                                .foregroundColor(UITheme.textPrimary)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                        .padding(.top, 10)
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Uygulama ve Kategoriler")
                                .font(.caption)
                                .foregroundColor(UITheme.textSecondary)
                                .textCase(.uppercase)
                            
                            FamilyActivityPicker(headerText: "Kısıtlanacak Uygulamaları Seçin", selection: $selection)
                                .frame(height: 250)
                                .background(UITheme.cardDark)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Günlük Limit Süresi")
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .onChange(of: limitHour) { _ in validateTime() }
                            .onChange(of: limitMinute) { _ in validateTime() }
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Aktif Günler")
                                .font(.caption)
                                .foregroundColor(UITheme.textSecondary)
                                .textCase(.uppercase)
                            
                            HStack(spacing: 8) {
                                ForEach(weekdays, id: \.0) { id, name in
                                    let isSelected = activeDays.contains(id)
                                    Button(action: {
                                        if isSelected {
                                            if activeDays.count > 1 {
                                                activeDays.remove(id)
                                            }
                                        } else {
                                            activeDays.insert(id)
                                        }
                                    }) {
                                        Text(name)
                                            .font(.system(size: 14, weight: .bold))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(isSelected ? UITheme.copperAccent : UITheme.cardDark)
                                            .foregroundColor(isSelected ? .black : UITheme.textPrimary)
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.white.opacity(isSelected ? 0 : 0.1), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Button(action: saveRule) {
                            Text("Sınırı Kaydet ve Aktifleştir")
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(isSaveDisabled ? Color.gray.opacity(0.3) : UITheme.copperAccent)
                                .foregroundColor(isSaveDisabled ? UITheme.textSecondary : .black)
                                .cornerRadius(12)
                        }
                        .disabled(isSaveDisabled)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Yeni Sınır")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(UITheme.copperAccent)
                }
            }
        }
    }
    
    // MARK: - Validation
    
    private var isSaveDisabled: Bool {
        let isSelectionEmpty = selection.applicationTokens.isEmpty &&
                              selection.categoryTokens.isEmpty &&
                              selection.webDomainTokens.isEmpty
        let isTimeZero = limitHour == 0 && limitMinute == 0
        let isNameEmpty = ruleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        return isSelectionEmpty || isTimeZero || isNameEmpty || activeDays.isEmpty
    }
    
    private func validateTime() {
        if limitHour == 0 && limitMinute == 0 {
            errorMessage = "Limit süresi 0 olamaz. Lütfen en az 1 dakika seçin."
        } else {
            errorMessage = nil
        }
    }
    
    // MARK: - Core Operations
    
    private func saveRule() {
        let totalSeconds = TimeInterval((limitHour * 3600) + (limitMinute * 60))
        
        if totalSeconds == 0 {
            errorMessage = "Geçersiz süre."
            return
        }
        
        let newRule = AppLimitRule(
            name: ruleName,
            selection: selection,
            dailyLimit: totalSeconds,
            activeWeekdays: activeDays,
            currentDayState: "monitoring",
            isActive: true,
            isFailed: false
        )
        
        var currentRules = LocalDataStore.shared.loadRules()
        currentRules.append(newRule)
        LocalDataStore.shared.saveRules(currentRules)
        
        ScreenTimeProtectionEngine.shared.startMonitoring(rule: newRule)
        
        LocalDataStore.shared.addLog(
            title: "Sınır Oluşturuldu",
            detail: "'\(ruleName)' adlı kısıtlama kuralı oluşturuldu.",
            type: .success
        )
        
        dismiss()
    }
}

#Preview {
    AddLimitView()
}
