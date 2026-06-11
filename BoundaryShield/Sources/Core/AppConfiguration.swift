//
//  AppConfiguration.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import Foundation

/// Uygulamanın merkezi yapılandırma ve sabit tanımlamaları.
public struct AppConfiguration {
    /// Paylaşımlı App Group Tanımlayıcısı
    public static let appGroupId = "group.com.asujai.boundaryshield"
    
    /// Ana Uygulama Paket Tanımlayıcısı
    public static let mainAppBundleId = "com.asujai.boundaryshield"
    
    /// Device Activity için kullanılan izleme kimliği
    public static let activityName = "BoundaryShieldActivity"
    
    /// UserDefaults anahtarları
    public struct Keys {
        public static let rules = "boundaryshield_rules_v2"
        public static let disciplineState = "boundaryshield_discipline_state_v2"
        public static let quotes = "boundaryshield_quotes_v2"
        public static let logs = "boundaryshield_logs_v2"
        public static let theme = "boundaryshield_app_theme_v2"
        public static let language = "boundaryshield_app_language_v2"
        public static let onlyMyQuotes = "boundaryshield_only_my_quotes_v2"
    }
}
