//
//  AppGroupStore.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import Foundation

/// App Group UserDefaults kullanarak thread-safe (atomik) ve Codable veri depolama sağlayan alt seviye katman.
public final class AppGroupStore {
    public static let shared = AppGroupStore()
    
    private let defaults: UserDefaults
    private let lock = NSLock()
    
    private init() {
        if let appGroupDefaults = UserDefaults(suiteName: AppConfiguration.appGroupId) {
            self.defaults = appGroupDefaults
        } else {
            print("WARNING: AppGroup defaults not available. Falling back to standard defaults.")
            self.defaults = UserDefaults.standard
        }
    }
    
    /// Verilen anahtara göre nesneyi kaydeder (Atomik / Thread-safe).
    public func save<T: Encodable>(_ object: T, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        
        do {
            let data = try JSONEncoder().encode(object)
            defaults.set(data, forKey: key)
            defaults.synchronize()
        } catch {
            print("ERROR: AppGroupStore failed to encode object for key \(key): \(error.localizedDescription)")
        }
    }
    
    /// Verilen anahtara göre nesneyi yükler (Atomik / Thread-safe).
    public func load<T: Decodable>(forKey key: String) -> T? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let data = defaults.data(forKey: key) else { return nil }
        
        do {
            let object = try JSONDecoder().decode(T.self, from: data)
            return object
        } catch {
            print("ERROR: AppGroupStore failed to decode object for key \(key): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Belirtilen anahtardaki veriyi siler.
    public func remove(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        defaults.removeObject(forKey: key)
        defaults.synchronize()
    }
}
