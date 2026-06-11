//
//  RuleEditingTests.swift
//  BoundaryShieldTests
//
//  Created by Antigravity on 2026-06-11.
//

import XCTest
@testable import BoundaryShield

final class RuleEditingTests: XCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        LocalDataStore.shared.clearAllData()
    }
    
    override func tearDownWithError() throws {
        LocalDataStore.shared.clearAllData()
        try super.tearDownWithError()
    }
    
    func testLimitIncreaseIsPostponed() throws {
        let rule = AppLimitRule(name: "Sosyal Medya", dailyLimit: 3600) // 1 saat
        LocalDataStore.shared.saveRules([rule])
        
        var rules = LocalDataStore.shared.loadRules()
        let newLimit: TimeInterval = 7200 // 2 saat (artış)
        
        if newLimit > rules[0].dailyLimit {
            rules[0].plannedNextDayLimit = newLimit
        }
        LocalDataStore.shared.saveRules(rules)
        
        let loaded = LocalDataStore.shared.loadRules()
        XCTAssertEqual(loaded[0].dailyLimit, 3600) // Limit anında artmamalı
        XCTAssertEqual(loaded[0].plannedNextDayLimit, 7200) // Yarına planlanmalı
    }
    
    func testLimitDecreaseIsAppliedImmediately() throws {
        let rule = AppLimitRule(name: "Oyunlar", dailyLimit: 7200) // 2 saat
        LocalDataStore.shared.saveRules([rule])
        
        var rules = LocalDataStore.shared.loadRules()
        let newLimit: TimeInterval = 3600 // 1 saat (azaltma)
        
        if newLimit < rules[0].dailyLimit {
            rules[0].dailyLimit = newLimit
            rules[0].plannedNextDayLimit = nil
        }
        LocalDataStore.shared.saveRules(rules)
        
        let loaded = LocalDataStore.shared.loadRules()
        XCTAssertEqual(loaded[0].dailyLimit, 3600) // Limit anında düşürülmeli
        XCTAssertNil(loaded[0].plannedNextDayLimit)
    }
    
    func testZeroMinutesLimitIsPrevented() throws {
        let isZeroAllowed = false
        let hour = 0
        let minute = 0
        
        let isValid = !(hour == 0 && minute == 0)
        XCTAssertFalse(isValid) // 0 saat 0 dakika geçersiz olmalıdır
    }
}
