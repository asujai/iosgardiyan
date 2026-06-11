//
//  LocalDataStoreTests.swift
//  BoundaryShieldTests
//
//  Created by Antigravity on 2026-06-11.
//

import XCTest
@testable import BoundaryShield

final class LocalDataStoreTests: XCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        LocalDataStore.shared.clearAllData()
    }
    
    override func tearDownWithError() throws {
        LocalDataStore.shared.clearAllData()
        try super.tearDownWithError()
    }
    
    func testSaveAndLoadRules() throws {
        let store = LocalDataStore.shared
        
        let rule1 = AppLimitRule(name: "Test 1", dailyLimit: 1800)
        let rule2 = AppLimitRule(name: "Test 2", dailyLimit: 3600)
        
        store.saveRules([rule1, rule2])
        
        let loaded = store.loadRules()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].name, "Test 1")
        XCTAssertEqual(loaded[1].name, "Test 2")
    }
    
    func testClearAllDataClearsMetadataAsWell() throws {
        let store = LocalDataStore.shared
        let resetManager = SafeDailyResetManager.shared
        
        // 1. Veri ve metadata oluştur
        store.saveRules([AppLimitRule(name: "Test", dailyLimit: 1000)])
        _ = resetManager.checkAndPerformReset() // Metadata oluşur
        
        // Metadata olduğunu doğrula
        let defaults = UserDefaults(suiteName: AppConfiguration.appGroupId) ?? UserDefaults.standard
        let metadataKey = "boundaryshield_reset_metadata_v3"
        XCTAssertNotNil(defaults.data(forKey: metadataKey))
        
        // 2. Sıfırla
        store.clearAllData()
        
        // Kurallar ve metadata silinmiş olmalı
        XCTAssertTrue(store.loadRules().isEmpty)
        XCTAssertNil(defaults.data(forKey: metadataKey)) // Metadata silinmiş olmalı
    }
}
