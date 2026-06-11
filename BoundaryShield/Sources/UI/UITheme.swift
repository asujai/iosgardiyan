//
//  UITheme.swift
//  BoundaryShield
//
//  Created by Antigravity on 2026-06-11.
//

import SwiftUI

/// Avant-Garde ve premium tasarım sistemi renkleri ve stilleri.
public struct UITheme {
    /// HSL bazlı özel renk paletimiz
    public static let backgroundDark = Color(red: 0.05, green: 0.05, blue: 0.06) // Sleek Premium Obsidian
    public static let cardDark = Color(red: 0.10, green: 0.10, blue: 0.12)       // Glassmorphic Obsidian
    public static let copperAccent = Color(red: 0.82, green: 0.45, blue: 0.32)    // Luxury Copper Accent
    public static let copperLight = Color(red: 0.92, green: 0.62, blue: 0.52)
    public static let copperDark = Color(red: 0.65, green: 0.32, blue: 0.22)
    
    public static let successGreen = Color(red: 0.22, green: 0.70, blue: 0.44)   // Mint Emerald
    public static let errorRed = Color(red: 0.85, green: 0.30, blue: 0.30)       // Crimson Red
    public static let textPrimary = Color.white
    public static let textSecondary = Color.gray
    
    /// Yumuşak premium gradyanımız
    public static let copperGradient = LinearGradient(
        colors: [copperLight, copperAccent, copperDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let obsidianGradient = LinearGradient(
        colors: [backgroundDark, cardDark],
        startPoint: .top,
        endPoint: .bottom
    )
}

/// SwiftUI View uzantısı ile şık kart görünümü (Glassmorphism).
public struct PremiumCardModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding()
            .background(UITheme.cardDark)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(LinearGradient(
                        colors: [Color.white.opacity(0.15), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

extension View {
    public func premiumCard() -> some View {
        self.modifier(PremiumCardModifier())
    }
}
