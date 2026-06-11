//
//  NotificationManager.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import Foundation
import UserNotifications

/// Yerel bildirimlerin gönderimini ve izin durumlarını yöneten modüler servis.
public final class NotificationManager {
    public static let shared = NotificationManager()
    
    private init() {}
    
    /// Kullanıcıdan yerel bildirim izni talep eder (isteğe bağlı).
    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                LocalDataStore.shared.addLog(
                    title: "Bildirim İzni",
                    detail: "Yerel bildirim izni başarıyla onaylandı.",
                    type: .info
                )
            } else if let error = error {
                LocalDataStore.shared.addLog(
                    title: "Bildirim İzni Hatası",
                    detail: "Bildirim izni alınırken hata oluştu: \(error.localizedDescription)",
                    type: .error
                )
            }
        }
    }
    
    /// Belirtilen başlık ve içerikle anında yerel bildirim gönderir.
    public func sendLocalNotification(title: String, body: String, identifier: String = UUID().uuidString) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Tetikleyici (1 saniye sonra anında tetiklenmesi için)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("ERROR: Failed to deliver notification: \(error.localizedDescription)")
            }
        }
    }
}
