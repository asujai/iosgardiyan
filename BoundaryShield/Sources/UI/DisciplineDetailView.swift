//
//  DisciplineDetailView.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import SwiftUI

struct DisciplineDetailView: View {
    @Environment(\.dismiss) var dismiss
    @State private var disciplineState = DisciplineState()
    
    // Grid düzeni (10 sütun)
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 10)
    
    var body: some View {
        NavigationStack {
            ZStack {
                UITheme.backgroundDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // İstatistik Özeti
                        statsSummary
                        
                        // Renk Açıklamaları (Legend)
                        legendView
                        
                        // 100 Günlük Disiplin Grid'i
                        VStack(alignment: .leading, spacing: 12) {
                            Text("100 Günlük Blok Geçmişi")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(UITheme.textSecondary)
                            
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(0..<100, id: \.self) { index in
                                    gridCell(for: index)
                                }
                            }
                            .padding()
                            .background(UITheme.cardDark)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        
                        // Motivasyon Kutusu
                        motivationCard
                        
                        Spacer(minLength: 30)
                    }
                }
            }
            .navigationTitle("Disiplin Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(UITheme.copperAccent)
                }
            }
            .onAppear {
                disciplineState = DisciplineEngine.shared.loadState()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var statsSummary: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mevcut Seri")
                    .font(.caption)
                    .foregroundColor(UITheme.textSecondary)
                Text("\(disciplineState.consecutiveSuccessDays) Gün")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(UITheme.successGreen)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .background(Color.white.opacity(0.1))
                .frame(height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Toplam Başarı")
                    .font(.caption)
                    .foregroundColor(UITheme.textSecondary)
                Text("\(disciplineState.totalSuccessDays) Gün")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(UITheme.copperAccent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .background(Color.white.opacity(0.1))
                .frame(height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Seviye")
                    .font(.caption)
                    .foregroundColor(UITheme.textSecondary)
                Text("Lvl \(disciplineState.level)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .premiumCard()
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    private var legendView: some View {
        HStack(spacing: 16) {
            legendItem(color: UITheme.successGreen, label: "Başarı")
            legendItem(color: UITheme.errorRed, label: "İhlal")
            legendItem(color: UITheme.copperAccent, label: "Bugün")
            legendItem(color: Color.gray.opacity(0.2), label: "Veri Yok")
        }
        .padding(.horizontal)
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 14, height: 14)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(UITheme.textSecondary)
        }
    }
    
    private func gridCell(for index: Int) -> some View {
        // Son 99 günü ve bugünü çizen 100 hücrelik grid.
        let targetDate = Date().addingTimeInterval(TimeInterval(-99 + index * 24 * 3600))
        let dateKey = formatDate(targetDate)
        
        let status = disciplineState.dailyHistory[dateKey]
        let isToday = Calendar.current.isDateInToday(targetDate)
        
        let color: Color
        if isToday {
            color = UITheme.copperAccent
        } else if status == "success" {
            color = UITheme.successGreen
        } else if status == "violation" {
            color = UITheme.errorRed
        } else {
            color = Color.gray.opacity(0.2)
        }
        
        return RoundedRectangle(cornerRadius: 6)
            .fill(color)
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isToday ? Color.white.opacity(0.6) : Color.clear, lineWidth: 1)
            )
    }
    
    private var motivationCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "bolt.shield.fill")
                    .foregroundColor(UITheme.copperAccent)
                    .font(.title3)
                Text("Disiplin Yolculuğu")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(UITheme.textPrimary)
                Spacer()
            }
            
            Text("Alışkanlıkların oluşması 21 gün, karakterin oluşması ise 90 gün sürer. Bu 100 günlük blok iradenizi somutlaştırmak için tasarlanmıştır. Her bir yeşil kutu, kendi hayatınızın kontrolünü elinize aldığınız bir günü temsil eder.")
                .font(.system(size: 13))
                .foregroundColor(UITheme.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .premiumCard()
        .padding(.horizontal)
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

#Preview {
    DisciplineDetailView()
}
