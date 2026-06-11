//
//  ProtectionView.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import SwiftUI

struct ProtectionView: View {
    @State private var rules: [ShieldRule] = []
    @State private var filterSelection: String = "active" // active, shieldActive, all
    @State private var selectedRule: ShieldRule? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                UITheme.backgroundDark.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Filtre Seçenekleri
                    filterBar
                    
                    if filteredRules.isEmpty {
                        emptyState
                    } else {
                        ruleList
                    }
                }
                .navigationTitle("Koruma Sınırları")
                .navigationBarTitleDisplayMode(.inline)
                .sheet(item: $selectedRule) { rule in
                    RuleManagementSheet(rule: rule) {
                        loadRules()
                    }
                }
                .onAppear {
                    loadRules()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var filterBar: some View {
        HStack(spacing: 12) {
            filterButton(title: "Aktif", key: "active")
            filterButton(title: "Limiti Dolan", key: "shieldActive")
            filterButton(title: "Tümü", key: "all")
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private func filterButton(title: String, key: String) -> some View {
        let isSelected = filterSelection == key
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                filterSelection = key
            }
        }) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? UITheme.copperAccent : UITheme.cardDark)
                .foregroundColor(isSelected ? .black : UITheme.textPrimary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(isSelected ? 0 : 0.05), lineWidth: 1)
                )
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "shield.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(UITheme.textSecondary.opacity(0.5))
            
            Text("Eşleşen Kural Bulunamadı")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(UITheme.textPrimary)
            
            Text("Henüz belirlediğiniz bir sınır kuralı bulunmuyor veya seçilen filtreyle eşleşmiyor.")
                .font(.system(size: 14))
                .foregroundColor(UITheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    private var ruleList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredRules) { rule in
                    ruleCard(for: rule)
                        .onTapGesture {
                            selectedRule = rule
                        }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    private func ruleCard(for rule: ShieldRule) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(rule.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(UITheme.textPrimary)
                
                Spacer()
                
                // Durum Etiketleri
                if rule.isShieldActiveToday {
                    HStack(spacing: 4) {
                        Circle().fill(UITheme.errorRed).frame(width: 8, height: 8)
                        Text("Limit Doldu")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(UITheme.errorRed)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(UITheme.errorRed.opacity(0.15))
                    .cornerRadius(8)
                } else if rule.isActive {
                    HStack(spacing: 4) {
                        Circle().fill(UITheme.successGreen).frame(width: 8, height: 8)
                        Text("İzleniyor")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(UITheme.successGreen)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(UITheme.successGreen.opacity(0.15))
                    .cornerRadius(8)
                } else {
                    Text("Devre Dışı")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(UITheme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Günlük Limit")
                        .font(.caption)
                        .foregroundColor(UITheme.textSecondary)
                    Text(formatSeconds(rule.dailyLimitInSeconds))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(UITheme.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Aktif Günler")
                        .font(.caption)
                        .foregroundColor(UITheme.textSecondary)
                    Text(formatActiveDays(rule.activeDays))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(UITheme.textPrimary)
                }
            }
            
            // Eğer planlanmış değişiklik varsa
            if rule.pendingNewLimitInSeconds != nil || rule.pendingActiveDays != nil {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.2.circlepath")
                        .font(.caption)
                    Text("Değişiklikler yarın reset sonrası geçerli olacaktır.")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(UITheme.copperAccent)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(UITheme.cardDark)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(rule.isShieldActiveToday ? UITheme.errorRed.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    // MARK: - Helpers & Data Filtering
    
    private func loadRules() {
        rules = LocalDataStore.shared.loadRules()
    }
    
    private var filteredRules: [ShieldRule] {
        switch filterSelection {
        case "active":
            return rules.filter { $0.isActive }
        case "shieldActive":
            return rules.filter { $0.isShieldActiveToday }
        default:
            return rules
        }
    }
    
    private func formatSeconds(_ seconds: TimeInterval) -> String {
        let hr = Int(seconds) / 3600
        let min = (Int(seconds) % 3600) / 60
        if hr > 0 {
            return "\(hr) saat \(min) dk"
        }
        return "\(min) dk"
    }
    
    private func formatActiveDays(_ days: Set<Int>) -> String {
        if days.count == 7 { return "Her Gün" }
        if days == Set([2, 3, 4, 5, 6]) { return "Hafta İçi" }
        if days == Set([1, 7]) { return "Hafta Sonu" }
        
        let weekdayNames = [2: "Pzt", 3: "Sal", 4: "Çar", 5: "Per", 6: "Cum", 7: "Cmt", 1: "Paz"]
        let sortedDays = days.sorted { d1, d2 in
            let order = [2, 3, 4, 5, 6, 7, 1]
            return (order.firstIndex(of: d1) ?? 0) < (order.firstIndex(of: d2) ?? 0)
        }
        return sortedDays.compactMap { weekdayNames[$0] }.joined(separator: ", ")
    }
}

#Preview {
    ProtectionView()
}
