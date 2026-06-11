//
//  DisciplineEngineTests.swift
//  BoundaryShieldTests
//
//  Created by Antigravity on 2026-06-11.
//

import XCTest
@testable import BoundaryShield

final class DisciplineEngineTests: XCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        LocalDataStore.shared.clearAllData()
    }
    
    override func tearDownWithError() throws {
        LocalDataStore.shared.clearAllData()
        try super.tearDownWithError()
    }
    
    func testViolationDropsLevelAndSetsRedBadge() throws {
        let engine = DisciplineEngine.shared
        var state = engine.loadState()
        
        // Önce seviyemizi 3 yapalım
        engine.recordSuccess(for: Date())
        engine.recordSuccess(for: Date().addingTimeInterval(24 * 3600))
        engine.recordSuccess(for: Date().addingTimeInterval(48 * 3600))
        engine.recordSuccess(for: Date().addingTimeInterval(72 * 3600))
        engine.recordSuccess(for: Date().addingTimeInterval(96 * 3600))
        engine.recordSuccess(for: Date().addingTimeInterval(120 * 3600))
        engine.recordSuccess(for: Date().addingTimeInterval(144 * 3600)) // 7 başarılı gün -> Level 3
        
        state = engine.loadState()
        XCTAssertEqual(state.level, 3)
        XCTAssertFalse(state.hasRedBadge)
        
        // İhlal kaydet
        engine.recordViolation()
        state = engine.loadState()
        
        XCTAssertEqual(state.level, 1) // Level 1'e düşmeli
        XCTAssertTrue(state.hasRedBadge) // Kırmızı rozet verilmeli
        XCTAssertEqual(state.activeRedemptionDaysLeft, 2) // Telafi gün hedefi 2 olmalı
        XCTAssertEqual(state.consecutiveSuccessDays, 0) // Başarı serisi sıfırlanmalı
    }
    
    func testTwoRedemptionDaysClearRedBadge() throws {
        let engine = DisciplineEngine.shared
        
        engine.recordViolation()
        var state = engine.loadState()
        XCTAssertTrue(state.hasRedBadge)
        XCTAssertEqual(state.activeRedemptionDaysLeft, 2)
        
        // 1. Telafi başarısı
        engine.recordSuccess(for: Date())
        state = engine.loadState()
        XCTAssertTrue(state.hasRedBadge)
        XCTAssertEqual(state.activeRedemptionDaysLeft, 1)
        
        // 2. Telafi başarısı
        engine.recordSuccess(for: Date().addingTimeInterval(24 * 3600))
        state = engine.loadState()
        XCTAssertFalse(state.hasRedBadge) // Rozet temizlenmiş olmalı
        XCTAssertEqual(state.activeRedemptionDaysLeft, 0)
    }
}
