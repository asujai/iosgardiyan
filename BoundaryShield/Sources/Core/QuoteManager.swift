//
//  QuoteManager.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import Foundation

/// Motivasyon sözü veri modeli.
public struct MotivationQuote: Codable, Identifiable, Equatable {
    public let id: UUID
    public var text: String
    public var author: String
    public var isActive: Bool
    public var isCustom: Bool
    
    public init(id: UUID = UUID(), text: String, author: String = "", isActive: Bool = true, isCustom: Bool = false) {
        self.id = id
        self.text = text
        self.author = author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Anonim" : author
        self.isActive = isActive
        self.isCustom = isCustom
    }
    
    public static func == (lhs: MotivationQuote, rhs: MotivationQuote) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Motivasyon sözlerini yöneten servis.
public final class QuoteManager {
    public static let shared = QuoteManager()
    
    private let defaults: UserDefaults
    
    private init() {
        self.defaults = UserDefaults(suiteName: AppConfig.appGroupId) ?? UserDefaults.standard
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
        guard let data = defaults.data(forKey: AppConfig.Keys.quotes),
              let quotes = try? JSONDecoder().decode([MotivationQuote].self, from: data) else {
            return []
        }
        return quotes
    }
    
    public func saveQuotes(_ quotes: [MotivationQuote]) {
        if let encoded = try? JSONEncoder().encode(quotes) {
            defaults.set(encoded, forKey: AppConfig.Keys.quotes)
            defaults.synchronize()
        }
    }
    
    // MARK: - User Operations
    
    public func addQuote(text: String, author: String) {
        var quotes = loadQuotes()
        let newQuote = MotivationQuote(text: text, author: author, isActive: true, isCustom: true)
        quotes.append(newQuote)
        saveQuotes(quotes)
        LocalDataStore.shared.addLog(
            title: "Söz Eklendi",
            detail: "\"\(text.prefix(30))...\" motivasyon sözü başarıyla eklendi.",
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
    
    /// Aktif ayarlara göre rastgele bir motivasyon sözü döner.
    public func getRandomActiveQuote(onlyCustom: Bool = false) -> MotivationQuote {
        let allQuotes = loadQuotes()
        
        let filteredQuotes: [MotivationQuote]
        if onlyCustom {
            filteredQuotes = allQuotes.filter { $0.isActive && $0.isCustom }
        } else {
            filteredQuotes = allQuotes.filter { $0.isActive }
        }
        
        if filteredQuotes.isEmpty {
            // Hiç aktif söz yoksa varsayılan acil durum sözü
            return MotivationQuote(text: "Odaklan ve disiplinli kal.", author: "Boundary Shield")
        }
        
        return filteredQuotes.randomElement() ?? MotivationQuote(text: "Odaklan ve disiplinli kal.", author: "Boundary Shield")
    }
}
