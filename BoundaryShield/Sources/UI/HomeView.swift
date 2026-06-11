//
//  HomeView.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import SwiftUI

struct HomeView: View {
    @State private var isAddLimitPresented = false
    @State private var isDisciplineDetailPresented = false
    
    @State private var rules: [ShieldRule] = []
    @State private var disciplineState = DisciplineState()
    
    var body: some View {
        NavigationStack {
            ZStack {
                UITheme.backgroundDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Üst Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Bugünkü İrade")
                                    .font(.caption)
                                    .foregroundColor(UITheme.textSecondary)
                                    .tracking(2)
                                    .textCase(.uppercase)
                                
                                Text(disciplineState.hasRedBadge ? "Telafi Modu" : DisciplineEngine.shared.getLevelName(for: disciplineState.level))
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(disciplineState.hasRedBadge ? UITheme.errorRed : UITheme.textPrimary)
                            }
                            Spacer()
                            
                            if disciplineState.hasRedBadge {
                                Image(systemName: "exclamationmark.shield.fill")
                                    .font(.title)
                                    .foregroundColor(UITheme.errorRed)
                                    .shadow(color: UITheme.errorRed.opacity(0.4), radius: 6)
                            } else {
                                Image(systemName: "crown.fill")
                                    .font(.title)
                                    .foregroundStyle(UITheme.copperGradient)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // İstatistikler Kartı
                        statsCard
                        
                        // 21 Günlük Disiplin Grid'i
                        disciplineGrid
                        
                        // Hızlı Eylemler
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Hızlı Eylemler")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(UITheme.textSecondary)
                                .padding(.horizontal)
                            
                            Button(action: {
                                isAddLimitPresented = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                    Text("Yeni Sınır Ekle")
                                        .font(.system(size: 16, weight: .semibold))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                                .padding()
                                .background(UITheme.cardDark)
                                .foregroundColor(UITheme.copperAccent)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(UITheme.copperAccent.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        // Günün Sözü Kartı
                        quoteCard
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Boundary Shield")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isAddLimitPresented) {
                AddLimitView()
                    .onDisappear {
                        loadData()
                    }
            }
            .sheet(isPresented: $isDisciplineDetailPresented) {
                DisciplineDetailView()
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var statsCard: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Kazanılan Zaman")
                        .font(.system(size: 14))
                        .foregroundColor(UITheme.textSecondary)
                    Text(formatSavedTime())
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(UITheme.textPrimary)
                }
                Spacer()
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Aktif Sınırlar")
                        .font(.caption)
                        .foregroundColor(UITheme.textSecondary)
                    Text("\(rules.filter { $0.isActive }.count)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(UITheme.copperAccent)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Limiti Dolanlar")
                        .font(.caption)
                        .foregroundColor(UITheme.textSecondary)
                    Text("\(rules.filter { $0.isShieldActiveToday }.count)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(UITheme.errorRed)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Başarı Serisi")
                        .font(.caption)
                        .foregroundColor(UITheme.textSecondary)
                    Text("\(disciplineState.consecutiveSuccessDays) Gün")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(UITheme.successGreen)
                }
            }
        }
        .premiumCard()
        .padding(.horizontal)
    }
    
    private var disciplineGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("21 Günlük Disiplin Serisi")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(UITheme.textSecondary)
                Spacer()
                Button(action: {
                    isDisciplineDetailPresented = true
                }) {
                    Text("Detaylar")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(UITheme.copperAccent)
                }
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 10) {
                ForEach(0..<21, id: \.self) { index in
                    gridItem(for: index)
                }
            }
            .padding()
            .background(UITheme.cardDark)
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
    
    private func gridItem(for index: Int) -> some View {
        // Son 20 günü ve bugünü grid üzerine yerleştirelim.
        let targetDate = Date().addingTimeInterval(TimeInterval(-20 + index * 24 * 3600))
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
            color = Color.gray.opacity(0.2) // Veri yok
        }
        
        return VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isToday ? Color.white.opacity(0.6) : Color.clear, lineWidth: 1.5)
                )
            Text("\(Calendar.current.component(.day, from: targetDate))")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isToday ? .white : UITheme.textSecondary)
        }
        .onTapGesture {
            isDisciplineDetailPresented = true
        }
    }
    
    private var quoteCard: some View {
        let quote = QuoteManager.shared.getRandomActiveQuote(onlyCustom: LocalDataStore.shared.loadSettings().onlyMyQuotes)
        return VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.title3)
                .foregroundColor(UITheme.copperAccent)
            
            Text(quote.text)
                .font(.system(size: 15, weight: .medium, design: .serif))
                .italic()
                .foregroundColor(UITheme.textPrimary)
                .lineSpacing(4)
            
            HStack {
                Spacer()
                Text("— \(quote.author)")
                    .font(.caption)
                    .foregroundColor(UITheme.textSecondary)
                    .fontWeight(.semibold)
            }
        }
        .premiumCard()
        .padding(.horizontal)
    }
    
    // MARK: - Helpers
    
    private func loadData() {
        rules = LocalDataStore.shared.loadRules()
        disciplineState = DisciplineEngine.shared.loadState()
    }
    
    private func formatSavedTime() -> String {
        // Tahmini kazanılan zaman: Başarılı olunan gün sayısı * 1.5 saat
        let hours = Double(disciplineState.totalSuccessDays) * 1.5
        if hours == 0 {
            return "0 sa"
        }
        return String(format: "%.1f sa", hours)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

#Preview {
    HomeView()
}
