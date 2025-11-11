//
//  Brush.swift
//  Ink - Pattern Drawing App
//
//  Created on November 10, 2025.
//

import Foundation

// MARK: - Pattern Density Configuration

/// Configuration for pattern density and pressure sensitivity
struct PatternDensityConfig: Codable {
    var baseDensity: Float              // Base density (0.0 = sparse, 1.0 = dense)
    var pressureModulation: Bool        // Enable Apple Pencil pressure to affect density
    var pressureSensitivity: Float      // How much pressure affects density (0.0-1.0)
    var autoShading: Bool               // AI-suggested density based on form (future feature)

    init(
        baseDensity: Float = 0.5,
        pressureModulation: Bool = true,
        pressureSensitivity: Float = 0.5,
        autoShading: Bool = false
    ) {
        self.baseDensity = baseDensity
        self.pressureModulation = pressureModulation
        self.pressureSensitivity = pressureSensitivity
        self.autoShading = autoShading
    }

    /// Calculate effective density based on pressure input
    func effectiveDensity(pressure: Float) -> Float {
        guard pressureModulation else {
            return baseDensity
        }

        // Pressure ranges from 0.0 to 1.0
        // Apply sensitivity curve
        let pressureInfluence = (pressure - 0.5) * pressureSensitivity
        let effectiveDensity = baseDensity + pressureInfluence

        // Clamp to valid range
        return max(0.0, min(1.0, effectiveDensity))
    }
}

// MARK: - Pattern Brush

/// Represents a pattern brush with configurable parameters
struct PatternBrush: Codable {
    var type: PatternType
    var rotation: Float       // degrees (0-360)
    var spacing: Float        // pixels between stamps
    var opacity: Float        // 0-1
    var scale: Float          // 0.5-2.0
    var color: Color
    var density: Float        // 0.0 (sparse) to 1.0 (dense) - simple density control
    var densityConfig: PatternDensityConfig  // Advanced density configuration with pressure support

    enum PatternType: String, Codable {
        case parallelLines
        case crossHatch
        case dots
        case contourLines
        case waves
    }

    struct Color: Codable {
        let red: Float
        let green: Float
        let blue: Float
        let alpha: Float

        static let black = Color(red: 0, green: 0, blue: 0, alpha: 1)
        static let white = Color(red: 1, green: 1, blue: 1, alpha: 1)
    }

    /// Default brush settings
    init(type: PatternType = .parallelLines,
         rotation: Float = 45.0,
         spacing: Float = 10.0,
         opacity: Float = 1.0,
         scale: Float = 1.0,
         color: Color = .black,
         density: Float = 0.5,
         densityConfig: PatternDensityConfig = PatternDensityConfig()) {
        self.type = type
        self.rotation = rotation
        self.spacing = spacing
        self.opacity = opacity
        self.scale = scale
        self.color = color
        self.density = density
        self.densityConfig = densityConfig
    }

    /// Get effective density considering pressure input
    func effectiveDensity(pressure: Float = 0.5) -> Float {
        // Use densityConfig if pressure modulation is enabled
        if densityConfig.pressureModulation {
            return densityConfig.effectiveDensity(pressure: pressure)
        }
        // Otherwise use simple density value
        return density
    }
}
