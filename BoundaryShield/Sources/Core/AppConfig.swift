//
//  AppConfig.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import Foundation

/// Uygulamanın merkezi yapılandırma sabitleri.
public struct AppConfig {
    /// Uygulama Grubu (App Group) Tanımlayıcısı - Extension'lar ve Ana Uygulama arası ortak depolama için.
    public static let appGroupId = "group.com.asujai.boundaryshield"
    
    /// Ana Uygulama Bundle Tanımlayıcısı.
    public static let mainAppBundleId = "com.asujai.boundaryshield"
    
    /// Device Activity için kullanılan izleme kategorisi adı.
    public static let activityName = "BoundaryShieldActivity"
    
    /// UserDefaults anahtar kelimeleri.
    public struct Keys {
        public static let rules = "boundaryshield_rules"
        public static let disciplineState = "boundaryshield_discipline_state"
        public static let quotes = "boundaryshield_quotes"
        public static let logs = "boundaryshield_logs"
        public static let appSettings = "boundaryshield_app_settings"
    }
}
