//
//  QuoteManagerTests.swift
//  BoundaryShieldTests
//
//  Created by Antigravity on 2026-06-11.
//

import XCTest
@testable import BoundaryShield

final class QuoteManagerTests: XCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        LocalDataStore.shared.clearAllData()
    }
    
    override func tearDownWithError() throws {
        LocalDataStore.shared.clearAllData()
        try super.tearDownWithError()
    }
    
    func testQuoteCrudOperations() throws {
        let manager = QuoteManager.shared
        let initialCount = manager.loadQuotes().count
        
        // Ekleme
        manager.addQuote(text: "İradeni Sınırla", author: "Seneca")
        var quotes = manager.loadQuotes()
        XCTAssertEqual(quotes.count, initialCount + 1)
        XCTAssertEqual(quotes.last?.text, "İradeni Sınırla")
        XCTAssertEqual(quotes.last?.author, "Seneca")
        XCTAssertTrue(quotes.last?.isCustom ?? false)
        
        // Rastgele getirme doğrulaması
        let randomQuote = manager.getRandomActiveQuote(onlyCustom: true)
        XCTAssertEqual(randomQuote.text, "İradeni Sınırla")
        
        // Silme
        if let lastId = quotes.last?.id {
            manager.deleteQuote(id: lastId)
            quotes = manager.loadQuotes()
            XCTAssertEqual(quotes.count, initialCount)
        }
    }
}
