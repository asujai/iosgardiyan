//
//  QuoteManager.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import Foundation

/// Motivasyon sözlerini yöneten modüler servis.
public final class QuoteManager {
    public static let shared = QuoteManager()
    
    private let store = AppGroupStore.shared
    
    private init() {
        initializeDefaultQuotesIfNeeded()
    }
    
    private func initializeDefaultQuotesIfNeeded() {
        let currentQuotes = loadQuotes()
        if currentQuotes.isEmpty {
            let defaultQuotes = [
                MotivationQuote(text: "Kendine koyduğun sınır, gelecekteki özgürlüğündür.", author: "Anonim"),
                MotivationQuote(text: "Disiplin, istekleriniz ile elde edecekleriniz arasındaki köprüdür.", author: "Jim Rohn"),
                MotivationQuote(text: "Zaman en değerli sermayendir, onu başkalarının hayatlarını izleyerek harcama.", author: "Anonim"),
                MotivationQuote(text: "Bugün ertelediğin şeyler, yarın pişmanlıkların olacaktır. Ekranı kapat ve odaklan.", author: "Anonim"),
                MotivationQuote(text: "Bir saatlik odaklanma, bir günlük dağınıklıktan daha değerlidir.", author: "Anonim"),
                MotivationQuote(text: "Discipline is the bridge between goals and accomplishment.", author: "Jim Rohn"),
                MotivationQuote(text: "Control your screen, or it will control your life.", author: "Anonim"),
                MotivationQuote(text: "The pain of discipline is temporary, but the pain of regret is permanent.", author: "Anonim"),
                MotivationQuote(text: "Be present in your real life, not your digital one.", author: "Anonim")
            ]
            saveQuotes(defaultQuotes)
        }
    }
    
    // MARK: - Core Operations
    
    public func loadQuotes() -> [MotivationQuote] {
        return store.load(forKey: AppConfiguration.Keys.quotes) ?? []
    }
    
    public func saveQuotes(_ quotes: [MotivationQuote]) {
        store.save(quotes, forKey: AppConfiguration.Keys.quotes)
    }
    
    // MARK: - User Operations
    
    public func addQuote(text: String, author: String) {
        var quotes = loadQuotes()
        let newQuote = MotivationQuote(text: text, author: author, isActive: true, isCustom: true)
        quotes.append(newQuote)
        saveQuotes(quotes)
        
        LocalDataStore.shared.addLog(
            title: "Söz Eklendi",
            detail: "\"\(text.prefix(20))...\" motivasyon sözü yerel listeye eklendi.",
            type: .info
        )
    }
    
    public func updateQuote(id: UUID, text: String, author: String, isActive: Bool) {
        var quotes = loadQuotes()
        if let index = quotes.firstIndex(where: { $0.id == id }) {
            quotes[index].text = text
            quotes[index].author = author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Anonim" : author
            quotes[index].isActive = isActive
            saveQuotes(quotes)
        }
    }
    
    public func deleteQuote(id: UUID) {
        var quotes = loadQuotes()
        quotes.removeAll(where: { $0.id == id })
        saveQuotes(quotes)
    }
    
    /// Aktif sözlerden rastgele birini getirir.
    public func getRandomActiveQuote(onlyCustom: Bool = false) -> MotivationQuote {
        let allQuotes = loadQuotes()
        
        let filtered: [MotivationQuote]
        if onlyCustom {
            filtered = allQuotes.filter { $0.isActive && $0.isCustom }
        } else {
            filtered = allQuotes.filter { $0.isActive }
        }
        
        if filtered.isEmpty {
            return MotivationQuote(text: "Sınırlarına sadık kal ve odaklan.", author: "Boundary Shield")
        }
        
        return filtered.randomElement() ?? MotivationQuote(text: "Sınırlarına sadık kal ve odaklan.", author: "Boundary Shield")
    }
}
