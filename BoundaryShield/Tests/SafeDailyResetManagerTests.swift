//
//  SafeDailyResetManagerTests.swift
//  BoundaryShieldTests
//
//  Created by Antigravity on 2026-06-11.
//

import XCTest
@testable import BoundaryShield

final class SafeDailyResetManagerTests: XCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        LocalDataStore.shared.clearAllData()
    }
    
    override func tearDownWithError() throws {
        LocalDataStore.shared.clearAllData()
        try super.tearDownWithError()
    }
    
    func testFirstInstallationDoesNotRecordSuccessOrLog() throws {
        let resetManager = SafeDailyResetManager.shared
        
        // İlk kurulum reset tetiklenmesi
        let success = resetManager.checkAndPerformReset()
        XCTAssertTrue(success)
        
        let state = DisciplineEngine.shared.loadState()
        XCTAssertEqual(state.totalSuccessDays, 0)
        XCTAssertEqual(state.consecutiveSuccessDays, 0)
        
        // Logların temiz kaldığını doğrula (sıfırlama logu dışında)
        let logs = LocalDataStore.shared.loadLogs()
        XCTAssertTrue(logs.isEmpty || (logs.count == 1 && logs[0].title == "Sistem Sıfırlandı"))
    }
    
    func testResetBlockedIfUnder22Hours() throws {
        let resetManager = SafeDailyResetManager.shared
        
        // İlk kurulum
        _ = resetManager.checkAndPerformReset()
        
        // 5 saat sonra tekrar tetikleme simülasyonu
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
        
        try! defaults.set(JSONEncoder().encode(mockMetadata), forKey: "boundaryshield_reset_metadata_v3")
        defaults.synchronize()
        
        let result = resetManager.checkAndPerformReset()
        XCTAssertFalse(result) // Sıfırlama engellenmelidir
    }
    
    func testResetBlockedIfTimeManipulatedBackwards() throws {
        let resetManager = SafeDailyResetManager.shared
        let defaults = UserDefaults(suiteName: AppConfiguration.appGroupId) ?? UserDefaults.standard
        
        struct MockResetMetadata: Codable {
            var lastResetDate: Date
            var lastResetWallClockTime: TimeInterval
            var lastResetSystemUptime: TimeInterval
            var lastKnownWallClockTime: TimeInterval
            var lastKnownTimeZoneIdentifier: String
        }
        
        // Son bilinen zamanı geleceğe çekelim (Saat geriye alınmış gibi simüle edelim)
        let futureTime = Date().addingTimeInterval(12 * 3600).timeIntervalSince1970
        let mockMetadata = MockResetMetadata(
            lastResetDate: Date(),
            lastResetWallClockTime: Date().timeIntervalSince1970,
            lastResetSystemUptime: 2000,
            lastKnownWallClockTime: futureTime,
            lastKnownTimeZoneIdentifier: TimeZone.current.identifier
        )
        
        try! defaults.set(JSONEncoder().encode(mockMetadata), forKey: "boundaryshield_reset_metadata_v3")
        defaults.synchronize()
        
        let result = resetManager.checkAndPerformReset()
        XCTAssertFalse(result) // Zaman manipülasyonu nedeniyle engellenmeli
    }
    
    func testPreviousDayFailDoesNotRecordSuccess() throws {
        let resetManager = SafeDailyResetManager.shared
        
        // 1. Dün aktif ve fail olmuş kural oluşturup kaydet
        let yesterday = Date().addingTimeInterval(-24 * 3600)
        let calendar = Calendar.current
        let yesterdayWeekday = calendar.component(.weekday, from: yesterday)
        
        var rule = AppLimitRule(name: "Sosyal Medya", dailyLimit: 3600, activeWeekdays: [yesterdayWeekday])
        rule.isFailed = true // Dün fail oldu
        LocalDataStore.shared.saveRules([rule])
        
        // Metadata simülasyonu: Son sıfırlama dün yapılmış
        let defaults = UserDefaults(suiteName: AppConfiguration.appGroupId) ?? UserDefaults.standard
        
        struct MockResetMetadata: Codable {
            var lastResetDate: Date
            var lastResetWallClockTime: TimeInterval
            var lastResetSystemUptime: TimeInterval
            var lastKnownWallClockTime: TimeInterval
            var lastKnownTimeZoneIdentifier: String
        }
        
        let mockMetadata = MockResetMetadata(
            lastResetDate: yesterday,
            lastResetWallClockTime: yesterday.timeIntervalSince1970,
            lastResetSystemUptime: 1000,
            lastKnownWallClockTime: Date().timeIntervalSince1970,
            lastKnownTimeZoneIdentifier: TimeZone.current.identifier
        )
        
        try! defaults.set(JSONEncoder().encode(mockMetadata), forKey: "boundaryshield_reset_metadata_v3")
        defaults.synchronize()
        
        // Sıfırlama tetiklensin (Şartlar sağlanıyor: Gün değişti ve 24 saat geçti)
        let result = resetManager.checkAndPerformReset()
        XCTAssertTrue(result)
        
        // Dün fail olduğu için başarı serisi 0 olmalı ve violation kaydedilmelidir
        let state = DisciplineEngine.shared.loadState()
        XCTAssertEqual(state.consecutiveSuccessDays, 0)
        XCTAssertTrue(state.hasRedBadge)
    }
    
    func testPreviousDaySuccessRecordsSuccessCorrectly() throws {
        let resetManager = SafeDailyResetManager.shared
        
        // 1. Dün aktif olan ve fail olmayan kural
        let yesterday = Date().addingTimeInterval(-24 * 3600)
        let calendar = Calendar.current
        let yesterdayWeekday = calendar.component(.weekday, from: yesterday)
        
        var rule = AppLimitRule(name: "Sosyal Medya", dailyLimit: 3600, activeWeekdays: [yesterdayWeekday])
        rule.isFailed = false // Dün başarılı
        LocalDataStore.shared.saveRules([rule])
        
        let defaults = UserDefaults(suiteName: AppConfiguration.appGroupId) ?? UserDefaults.standard
        
        struct MockResetMetadata: Codable {
            var lastResetDate: Date
            var lastResetWallClockTime: TimeInterval
            var lastResetSystemUptime: TimeInterval
            var lastKnownWallClockTime: TimeInterval
            var lastKnownTimeZoneIdentifier: String
        }
        
        let mockMetadata = MockResetMetadata(
            lastResetDate: yesterday,
            lastResetWallClockTime: yesterday.timeIntervalSince1970,
            lastResetSystemUptime: 1000,
            lastKnownWallClockTime: Date().timeIntervalSince1970,
            lastKnownTimeZoneIdentifier: TimeZone.current.identifier
        )
        
        try! defaults.set(JSONEncoder().encode(mockMetadata), forKey: "boundaryshield_reset_metadata_v3")
        defaults.synchronize()
        
        let result = resetManager.checkAndPerformReset()
        XCTAssertTrue(result)
        
        // Başarı serisi kaydedilmiş olmalı
        let state = DisciplineEngine.shared.loadState()
        XCTAssertEqual(state.consecutiveSuccessDays, 1)
        XCTAssertFalse(state.hasRedBadge)
    }
}
