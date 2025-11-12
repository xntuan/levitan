//
//  DesignTokens.swift
//  Ink - Pattern Drawing App
//
//  Design tokens following Lake aesthetic
//  Created on November 10, 2025.
//

import UIKit

/// Design tokens for consistent UI styling (Lake aesthetic)
enum DesignTokens {

    // MARK: - Colors
    enum Colors {
        // Primary palette
        static let inkPrimary = UIColor(red: 0.4, green: 0.49, blue: 0.92, alpha: 1.0)      // #667eea
        static let inkSecondary = UIColor(red: 0.46, green: 0.29, blue: 0.64, alpha: 1.0)   // #764ba2
        static let inkAccent = UIColor(red: 0.28, green: 0.78, blue: 0.94, alpha: 1.0)      // #48c6ef

        // Semantic colors
        static let success = UIColor(red: 0.3, green: 0.69, blue: 0.31, alpha: 1.0)         // #4caf50
        static let warning = UIColor(red: 1.0, green: 0.76, blue: 0.03, alpha: 1.0)         // #ffc107
        static let error = UIColor(red: 0.96, green: 0.26, blue: 0.21, alpha: 1.0)          // #f44336

        // Neutrals
        static let textPrimary = UIColor(red: 0.17, green: 0.24, blue: 0.31, alpha: 1.0)    // #2c3e50
        static let textSecondary = UIColor(red: 0.58, green: 0.65, blue: 0.72, alpha: 1.0)  // #95a5a6
        static let subtleGray = UIColor(red: 0.74, green: 0.76, blue: 0.78, alpha: 1.0)     // #bdc3c7
        static let background = UIColor(red: 0.97, green: 0.98, blue: 0.98, alpha: 1.0)     // #f8f9fa
        static let surface = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)           // #ffffff
        static let divider = UIColor(red: 0.93, green: 0.94, blue: 0.95, alpha: 1.0)        // #eceff1

        // Lake aesthetic gradients
        static let gradientSunrise: [UIColor] = [
            UIColor(hex: "ffecd2")!,
            UIColor(hex: "fcb69f")!
        ]

        static let gradientOcean: [UIColor] = [
            UIColor(hex: "a8edea")!,
            UIColor(hex: "fed6e3")!
        ]

        static let gradientLavender: [UIColor] = [
            UIColor(hex: "667eea")!,
            UIColor(hex: "764ba2")!
        ]

        static let gradientMint: [UIColor] = [
            UIColor(hex: "48c6ef")!,
            UIColor(hex: "6f86d6")!
        ]
    }

    // MARK: - Typography
    enum Typography {
        // Font sizes
        static let displayLarge: CGFloat = 32
        static let displayMedium: CGFloat = 28
        static let headlineLarge: CGFloat = 24
        static let headlineMedium: CGFloat = 20
        static let titleLarge: CGFloat = 18
        static let titleMedium: CGFloat = 16
        static let bodyLarge: CGFloat = 16
        static let bodyMedium: CGFloat = 14
        static let bodySmall: CGFloat = 12
        static let labelLarge: CGFloat = 14
        static let labelMedium: CGFloat = 12
        static let labelSmall: CGFloat = 11

        // Font weights
        static let light = UIFont.Weight.light       // 300
        static let regular = UIFont.Weight.regular   // 400
        static let semibold = UIFont.Weight.semibold // 600
        static let bold = UIFont.Weight.bold         // 700

        // Font helpers
        static func systemFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
            return UIFont.systemFont(ofSize: size, weight: weight)
        }
    }

    // MARK: - Spacing
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
    }

    // MARK: - Border Radius
    enum Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let round: CGFloat = 9999  // Fully rounded
    }

    // MARK: - Shadows
    enum Shadow {
        static let small = ShadowStyle(
            color: UIColor.black.withAlphaComponent(0.08),
            offset: CGSize(width: 0, height: 2),
            radius: 4,
            opacity: 1.0
        )

        static let medium = ShadowStyle(
            color: UIColor.black.withAlphaComponent(0.12),
            offset: CGSize(width: 0, height: 4),
            radius: 12,
            opacity: 1.0
        )

        static let large = ShadowStyle(
            color: UIColor.black.withAlphaComponent(0.12),
            offset: CGSize(width: 0, height: 8),
            radius: 24,
            opacity: 1.0
        )
    }

    struct ShadowStyle {
        let color: UIColor
        let offset: CGSize
        let radius: CGFloat
        let opacity: Float

        func apply(to layer: CALayer) {
            layer.shadowColor = color.cgColor
            layer.shadowOffset = offset
            layer.shadowRadius = radius
            layer.shadowOpacity = opacity
        }
    }

    // MARK: - Animation
    enum Animation {
        static let durationFast: TimeInterval = 0.2
        static let durationMedium: TimeInterval = 0.3
        static let durationNormal: TimeInterval = 0.3
        static let durationSlow: TimeInterval = 0.5

        static let curveEaseOut = UIView.AnimationOptions.curveEaseOut
        static let curveEaseIn = UIView.AnimationOptions.curveEaseIn
        static let curveEaseInOut = UIView.AnimationOptions.curveEaseInOut
    }

    // MARK: - Canvas
    enum Canvas {
        static let defaultSize = CGSize(width: 2048, height: 2048)
        static let minZoom: CGFloat = 0.5
        static let maxZoom: CGFloat = 4.0
        static let targetFPS: Int = 60
    }
}

// MARK: - UIView Extension for Design Tokens
extension UIView {
    func applyShadow(_ shadow: DesignTokens.ShadowStyle) {
        shadow.apply(to: layer)
    }

    func applyCornerRadius(_ radius: CGFloat, masksToBounds: Bool = true) {
        layer.cornerRadius = radius
        layer.masksToBounds = masksToBounds
    }
}

// UIColor hex extension is defined in Extensions.swift
