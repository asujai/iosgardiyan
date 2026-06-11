//
//  AppGroupStore.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import Foundation

/// App Group paylaşımlı klasöründe dosya tabanlı, atomik yazma desteği olan ve thread-safe veri depolama katmanı.
public final class AppGroupStore {
    public static let shared = AppGroupStore()
    
    private let lock = NSLock()
    private let currentSchemaVersion = 1
    
    private init() {
        createContainerDirectoryIfNeeded()
    }
    
    /// Her key için özel JSON zarf modeli.
    private struct StoreEnvelope<T: Codable>: Codable {
        let schemaVersion: Int
        let data: T
    }
    
    private var containerURL: URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConfiguration.appGroupId)
    }
    
    private func fileURL(for key: String) -> URL? {
        return containerURL?.appendingPathComponent("\(key).json")
    }
    
    private func createContainerDirectoryIfNeeded() {
        guard let url = containerURL else { return }
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    // MARK: - Core Operations
    
    /// Veriyi atomik olarak JSON dosyası halinde kaydeder.
    public func save<T: Encodable>(_ object: T, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        
        guard let url = fileURL(for: key) else {
            print("ERROR: BoundaryShield AppGroup container URL not available.")
            return
        }
        
        let envelope = StoreEnvelope(schemaVersion: currentSchemaVersion, data: object)
        
        do {
            let data = try JSONEncoder().encode(envelope)
            // Atomik yazma seçeneği (.atomic) ile yarıda kesilme veya veri bozulmaları engellenir.
            try data.write(to: url, options: .atomic)
        } catch {
            print("ERROR: BoundaryShield failed to save atomic write data for key \(key): \(error.localizedDescription)")
        }
    }
    
    /// Veriyi dosyadan yükler, bozulma durumunda fallback sağlar.
    public func load<T: Decodable>(forKey key: String) -> T? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let url = fileURL(for: key), FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let envelope = try JSONDecoder().decode(StoreEnvelope<T>.self, from: data)
            
            // Basit Şema Sürüm Kontrolü / Migration Tetikleyici
            if envelope.schemaVersion == currentSchemaVersion {
                return envelope.data
            } else {
                print("WARNING: BoundaryShield schema version mismatch for \(key). Fallback triggered.")
                return nil
            }
        } catch {
            print("ERROR: BoundaryShield failed to load or decode file data for key \(key) (Data corrupted?): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Belirtilen dosyayı siler.
    public func remove(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        
        guard let url = fileURL(for: key) else { return }
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
