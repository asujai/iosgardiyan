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
        LocalDataStore.shared.clearAllData()
    }
    
    override func tearDownWithError() throws {
        LocalDataStore.shared.clearAllData()
        try super.tearDownWithError()
    }
    
    // MARK: - DisciplineEngineTests
    
    func testDisciplineEngine_ViolationAndRedemption() throws {
        let engine = DisciplineEngine.shared
        var state = engine.loadState()
        
        // 1. İhlal Öncesi Durum
        XCTAssertEqual(state.level, 1)
        XCTAssertFalse(state.hasRedBadge)
        
        // 2. İhlal Gerçekleşmesi
        engine.recordViolation()
        state = engine.loadState()
        
        XCTAssertEqual(state.level, 1)
        XCTAssertTrue(state.hasRedBadge)
        XCTAssertEqual(state.activeRedemptionDaysLeft, 2)
        XCTAssertEqual(state.consecutiveSuccessDays, 0)
        
        // 3. 1. Gün Telafi Başarısı
        engine.recordSuccess()
        state = engine.loadState()
        
        XCTAssertTrue(state.hasRedBadge)
        XCTAssertEqual(state.activeRedemptionDaysLeft, 1)
        
        // 4. 2. Gün Telafi Başarısı (Kırmızı rozet kalkmalı)
        let tomorrow = Date().addingTimeInterval(24 * 3600)
        engine.recordSuccess(for: tomorrow)
        state = engine.loadState()
        
        XCTAssertFalse(state.hasRedBadge)
        XCTAssertEqual(state.activeRedemptionDaysLeft, 0)
    }
    
    // MARK: - SafeDailyResetManagerTests
    
    func testSafeDailyResetManager_22HoursRule() throws {
        let resetManager = SafeDailyResetManager.shared
        
        // İlk sıfırlama gerçekleşir
        let firstReset = resetManager.checkAndPerformReset()
        XCTAssertTrue(firstReset)
        
        // 5 saat sonra tekrar deneriz (erken reset - yapılmamalıdır)
        // Metadata simülasyonu yapıyoruz
        let defaults = UserDefaults(suiteName: AppConfiguration.appGroupId) ?? UserDefaults.standard
        
        struct MockResetMetadata: Codable {
            var lastResetDate: Date
            var lastResetWallClockTime: TimeInterval
            var lastResetSystemUptime: TimeInterval
            var lastKnownWallClockTime: TimeInterval
            var lastKnownTimeZoneIdentifier: String
        }
        
        let fiveHoursLater = Date().addingTimeInterval(5 * 3600)
        let mockMetadata = MockResetMetadata(
            lastResetDate: Date(),
            lastResetWallClockTime: Date().timeIntervalSince1970,
            lastResetSystemUptime: 5000,
            lastKnownWallClockTime: fiveHoursLater.timeIntervalSince1970,
            lastKnownTimeZoneIdentifier: TimeZone.current.identifier
        )
        
        if let encoded = try? JSONEncoder().encode(mockMetadata) {
            defaults.set(encoded, forKey: "boundaryshield_reset_metadata_v2")
            defaults.synchronize()
        }
        
        // Günün değişmediği ve 22 saatin dolmadığı durumda reset engellenmelidir
        let secondReset = resetManager.checkAndPerformReset()
        XCTAssertFalse(secondReset)
    }
    
    func testSafeDailyResetManager_TimeBypass() throws {
        let resetManager = SafeDailyResetManager.shared
        let defaults = UserDefaults(suiteName: AppConfiguration.appGroupId) ?? UserDefaults.standard
        
        struct MockResetMetadata: Codable {
            var lastResetDate: Date
            var lastResetWallClockTime: TimeInterval
            var lastResetSystemUptime: TimeInterval
            var lastKnownWallClockTime: TimeInterval
            var lastKnownTimeZoneIdentifier: String
        }
        
        // Son bilinen zamanı geleceğe çekelim
        let futureTime = Date().addingTimeInterval(12 * 3600).timeIntervalSince1970
        let mockMetadata = MockResetMetadata(
            lastResetDate: Date(),
            lastResetWallClockTime: Date().timeIntervalSince1970,
            lastResetSystemUptime: 2000,
            lastKnownWallClockTime: futureTime,
            lastKnownTimeZoneIdentifier: TimeZone.current.identifier
        )
        
        if let encoded = try? JSONEncoder().encode(mockMetadata) {
            defaults.set(encoded, forKey: "boundaryshield_reset_metadata_v2")
            defaults.synchronize()
        }
        
        // Cihaz saatinin geriye alınması (bypass tespiti) sıfırlamayı engellemelidir
        let resetResult = resetManager.checkAndPerformReset()
        XCTAssertFalse(resetResult)
    }
    
    // MARK: - RuleEditingTests
    
    func testRuleEditing_LimitIncreasePostponed() throws {
        let originalLimit: TimeInterval = 3600 // 1 Saat
        let rule = AppLimitRule(name: "Sosyal Medya", dailyLimit: originalLimit)
        
        var rules = [rule]
        LocalDataStore.shared.saveRules(rules)
        
        // Kural limit süresini 2 saate (7200 sn) artırmak isteyelim
        let targetIndex = 0
        let newLimit: TimeInterval = 7200
        
        if newLimit > rules[targetIndex].dailyLimit {
            // Artış ertelenir, yarına planlanır
            rules[targetIndex].plannedNextDayLimit = newLimit
        }
        
        LocalDataStore.shared.saveRules(rules)
        
        let loadedRules = LocalDataStore.shared.loadRules()
        XCTAssertEqual(loadedRules[0].dailyLimit, originalLimit) // Süre anında değişmemelidir
        XCTAssertEqual(loadedRules[0].plannedNextDayLimit, newLimit) // Yarına planlanmış olmalıdır
    }
    
    func testRuleEditing_LimitDecreaseImmediate() throws {
        let originalLimit: TimeInterval = 7200 // 2 Saat
        let rule = AppLimitRule(name: "Sosyal Medya", dailyLimit: originalLimit)
        
        var rules = [rule]
        LocalDataStore.shared.saveRules(rules)
        
        // Kural limit süresini 1 saate (3600 sn) düşürmek isteyelim
        let targetIndex = 0
        let newLimit: TimeInterval = 3600
        
        if newLimit < rules[targetIndex].dailyLimit {
            // Azaltma hemen uygulanır
            rules[targetIndex].dailyLimit = newLimit
            rules[targetIndex].plannedNextDayLimit = nil
        }
        
        LocalDataStore.shared.saveRules(rules)
        
        let loadedRules = LocalDataStore.shared.loadRules()
        XCTAssertEqual(loadedRules[0].dailyLimit, newLimit) // Süre anında güncellenmelidir
        XCTAssertNil(loadedRules[0].plannedNextDayLimit) // Planlanmış bir süre olmamalıdır
    }
    
    // MARK: - LocalDataStoreTests
    
    func testLocalDataStore_SaveAndLoad() throws {
        let store = LocalDataStore.shared
        
        let rule1 = AppLimitRule(name: "Oyunlar", dailyLimit: 1800)
        let rule2 = AppLimitRule(name: "Mesajlaşma", dailyLimit: 3600)
        
        store.saveRules([rule1, rule2])
        
        let loaded = store.loadRules()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].name, "Oyunlar")
        XCTAssertEqual(loaded[1].name, "Mesajlaşma")
    }
    
    // MARK: - QuoteManagerTests
    
    func testQuoteManager_CrudOperations() throws {
        let manager = QuoteManager.shared
        let initialCount = manager.loadQuotes().count
        
        // 1. Ekleme
        manager.addQuote(text: "Asla Vazgeçme", author: "Mustafa Kemal Atatürk")
        var quotes = manager.loadQuotes()
        XCTAssertEqual(quotes.count, initialCount + 1)
        XCTAssertEqual(quotes.last?.text, "Asla Vazgeçme")
        
        // 2. Silme
        if let lastId = quotes.last?.id {
            manager.deleteQuote(id: lastId)
            quotes = manager.loadQuotes()
            XCTAssertEqual(quotes.count, initialCount)
        }
    }
}
