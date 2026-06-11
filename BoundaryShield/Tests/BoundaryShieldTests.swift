//
//  BoundaryShieldTests.swift
//  BoundaryShieldTests
//
//  Created by Antigravity on 2026-06-11.
//

import XCTest
@testable import BoundaryShield
import FamilyControls

final class BoundaryShieldTests: XCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        // Her test öncesi verileri sıfırlayalım
        LocalDataStore.shared.clearAllData()
    }
    
    override func tearDownWithError() throws {
        LocalDataStore.shared.clearAllData()
        try super.tearDownWithError()
    }
    
    // MARK: - DisciplineEngine Tests
    
    func testDisciplineViolationAndRedemption() throws {
        let engine = DisciplineEngine.shared
        var state = engine.loadState()
        
        // Başlangıç durumu
        XCTAssertEqual(state.level, 1)
        XCTAssertFalse(state.hasRedBadge)
        
        // 1. İhlal Kaydetme
        engine.recordViolation()
        state = engine.loadState()
        
        XCTAssertEqual(state.level, 1)
        XCTAssertTrue(state.hasRedBadge)
        XCTAssertEqual(state.activeRedemptionDaysLeft, 2)
        XCTAssertEqual(state.consecutiveSuccessDays, 0)
        
        // 2. İlk Telafi Günü Başarısı
        engine.recordSuccess()
        state = engine.loadState()
        
        XCTAssertTrue(state.hasRedBadge) // Hala kırmızı rozet olmalı (2 gün hedefti)
        XCTAssertEqual(state.activeRedemptionDaysLeft, 1)
        
        // 3. İkinci Telafi Günü Başarısı
        // Test amaçlı farklı bir gün simülasyonu yapalım
        let nextDay = Date().addingTimeInterval(24 * 3600)
        engine.recordSuccess(for: nextDay)
        state = engine.loadState()
        
        XCTAssertFalse(state.hasRedBadge) // Kırmızı rozet kalkmış olmalı
        XCTAssertEqual(state.activeRedemptionDaysLeft, 0)
    }
    
    func testLevelProgression() throws {
        let engine = DisciplineEngine.shared
        
        // 3 Başarılı gün serisi -> Level 2
        engine.recordSuccess(for: Date())
        engine.recordSuccess(for: Date().addingTimeInterval(24 * 3600))
        engine.recordSuccess(for: Date().addingTimeInterval(48 * 3600))
        
        let state = engine.loadState()
        XCTAssertEqual(state.level, 2)
        XCTAssertEqual(state.consecutiveSuccessDays, 3)
    }
    
    // MARK: - SafeDailyResetManager Tests
    
    func testTimeBypassPrevention() throws {
        let resetManager = SafeDailyResetManager.shared
        
        // İlk reset gerçekleşsin
        let success = resetManager.checkAndPerformReset()
        XCTAssertTrue(success)
        
        // Zamanı geriye alıp tetikleyelim (Bypass Girişimi)
        // System clock geriye alınmış gibi simüle edelim.
        // Dahili metadata'yı mock'lamak veya doğrudan check tetiklemek:
        // Cihaz saati geriye alındığı için checkAndPerformReset false dönmeli.
        // Test verisini UserDefaults'a manuel yazarak zamanı simüle edebiliriz.
        let defaults = UserDefaults(suiteName: AppConfig.appGroupId) ?? UserDefaults.standard
        let futureTime = Date().addingTimeInterval(10 * 3600).timeIntervalSince1970
        
        // Son bilinen wall clock zamanını geleceğe çekelim
        struct MockResetMetadata: Codable {
            var lastResetDate: Date
            var lastResetWallClockTime: TimeInterval
            var lastResetSystemUptime: TimeInterval
            var lastKnownWallClockTime: TimeInterval
            var lastKnownTimeZoneIdentifier: String
        }
        
        let mockMetadata = MockResetMetadata(
            lastResetDate: Date(),
            lastResetWallClockTime: Date().timeIntervalSince1970,
            lastResetSystemUptime: 1000,
            lastKnownWallClockTime: futureTime, // Gelecekte bir zaman
            lastKnownTimeZoneIdentifier: TimeZone.current.identifier
        )
        
        if let encoded = try? JSONEncoder().encode(mockMetadata) {
            defaults.set(encoded, forKey: "boundaryshield_reset_metadata")
            defaults.synchronize()
        }
        
        // Şu anki zaman (şimdi), son bilinen zamandan (gelecek) küçük olacağı için bypass koruması devreye girmeli
        let resetResult = resetManager.checkAndPerformReset()
        XCTAssertFalse(resetResult) // Reset engellenmiş olmalı
    }
    
    // MARK: - QuoteManager Tests
    
    func testQuoteOperations() throws {
        let manager = QuoteManager.shared
        
        let initialCount = manager.loadQuotes().count
        
        // Söz Ekleme
        manager.addQuote(text: "Test Motivasyon Sözü", author: "Test Yazar")
        let quotes = manager.loadQuotes()
        
        XCTAssertEqual(quotes.count, initialCount + 1)
        XCTAssertEqual(quotes.last?.text, "Test Motivasyon Sözü")
        XCTAssertEqual(quotes.last?.author, "Test Yazar")
        XCTAssertTrue(quotes.last?.isCustom ?? false)
        
        // Söz Silme
        if let lastId = quotes.last?.id {
            manager.deleteQuote(id: lastId)
            let updatedQuotes = manager.loadQuotes()
            XCTAssertEqual(updatedQuotes.count, initialCount)
        }
    }
}
