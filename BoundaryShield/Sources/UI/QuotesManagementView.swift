//
//  QuotesManagementView.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import SwiftUI

struct QuotesManagementView: View {
    @State private var quotes: [MotivationQuote] = []
    @State private var onlyMyQuotes: Bool = false
    @State private var isAddQuotePresented = false
    
    @State private var newQuoteText: String = ""
    @State private var newQuoteAuthor: String = ""
    
    var body: some View {
        ZStack {
            UITheme.backgroundDark.ignoresSafeArea()
            
            VStack(spacing: 16) {
                toggleCard
                
                if filteredQuotes.isEmpty {
                    emptyState
                } else {
                    quotesList
                }
            }
            .padding(.top)
        }
        .navigationTitle("Motivasyon Sözleri")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { isAddQuotePresented = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(UITheme.copperAccent)
                }
            }
        }
        .sheet(isPresented: $isAddQuotePresented) {
            addQuoteSheet
        }
        .onAppear {
            loadQuotesData()
        }
    }
    
    // MARK: - Subviews
    
    private var toggleCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Kişisel Filtre")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(UITheme.textPrimary)
                Text("Yalnızca kendi eklediğim sözler gösterilsin.")
                    .font(.system(size: 12))
                    .foregroundColor(UITheme.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $onlyMyQuotes)
                .tint(UITheme.copperAccent)
                .labelsHidden()
                .onChange(of: onlyMyQuotes) { newValue in
                    LocalDataStore.shared.saveOnlyMyQuotesPreference(newValue)
                }
        }
        .padding()
        .background(UITheme.cardDark)
        .cornerRadius(14)
        .padding(.horizontal)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "quote.bubble")
                .font(.system(size: 50))
                .foregroundColor(UITheme.textSecondary.opacity(0.4))
            
            Text("Söz Bulunamadı")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(UITheme.textPrimary)
            
            Text("Henüz kendi eklediğiniz bir söz bulunmuyor.")
                .font(.system(size: 13))
                .foregroundColor(UITheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("İlk Sözünü Ekle") {
                isAddQuotePresented = true
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.black)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(UITheme.copperAccent)
            .cornerRadius(20)
            
            Spacer()
        }
    }
    
    private var quotesList: some View {
        List {
            ForEach(filteredQuotes) { quote in
                quoteRow(for: quote)
                    .listRowBackground(UITheme.cardDark)
                    .listRowSeparatorTint(Color.white.opacity(0.05))
            }
            .onDelete(perform: deleteQuote)
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
    
    private func quoteRow(for quote: MotivationQuote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\"\(quote.text)\"")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .italic()
                .foregroundColor(UITheme.textPrimary)
            
            HStack {
                if quote.isCustom {
                    Text("Kendi Sözüm")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(UITheme.copperAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(UITheme.copperAccent.opacity(0.15))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Text("— \(quote.author)")
                    .font(.caption2)
                    .foregroundColor(UITheme.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var addQuoteSheet: some View {
        NavigationStack {
            ZStack {
                UITheme.backgroundDark.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Söz İçeriği")
                            .font(.caption)
                            .foregroundColor(UITheme.textSecondary)
                            .textCase(.uppercase)
                        
                        TextEditor(text: $newQuoteText)
                            .frame(height: 120)
                            .padding(8)
                            .background(UITheme.cardDark)
                            .foregroundColor(UITheme.textPrimary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Yazar (İsteğe Bağlı)")
                            .font(.caption)
                            .foregroundColor(UITheme.textSecondary)
                            .textCase(.uppercase)
                        
                        TextField("Örn: Marcus Aurelius", text: $newQuoteAuthor)
                            .padding()
                            .background(UITheme.cardDark)
                            .foregroundColor(UITheme.textPrimary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    Button(action: saveNewQuote) {
                        Text("Sözü Ekle")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(newQuoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.3) : UITheme.copperAccent)
                            .foregroundColor(newQuoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? UITheme.textSecondary : .black)
                            .cornerRadius(12)
                    }
                    .disabled(newQuoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Yeni Söz Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        isAddQuotePresented = false
                        newQuoteText = ""
                        newQuoteAuthor = ""
                    }
                    .foregroundColor(UITheme.copperAccent)
                }
            }
        }
    }
    
    // MARK: - Helpers & Data Operations
    
    private func loadQuotesData() {
        quotes = QuoteManager.shared.loadQuotes()
        onlyMyQuotes = LocalDataStore.shared.loadOnlyMyQuotesPreference()
    }
    
    private var filteredQuotes: [MotivationQuote] {
        if onlyMyQuotes {
            return quotes.filter { $0.isCustom }
        }
        return quotes
    }
    
    private func saveNewQuote() {
        QuoteManager.shared.addQuote(text: newQuoteText, author: newQuoteAuthor)
        loadQuotesData()
        isAddQuotePresented = false
        newQuoteText = ""
        newQuoteAuthor = ""
    }
    
    private func deleteQuote(at offsets: IndexSet) {
        let targetQuotes = filteredQuotes
        for index in offsets {
            let quote = targetQuotes[index]
            if quote.isCustom {
                QuoteManager.shared.deleteQuote(id: quote.id)
            } else {
                LocalDataStore.shared.addLog(
                    title: "Silme Engellendi",
                    detail: "Sistem varsayılan sözleri silinemez.",
                    type: .warning
                )
            }
        }
        loadQuotesData()
    }
}

#Preview {
    QuotesManagementView()
}
