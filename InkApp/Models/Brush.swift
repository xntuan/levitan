//
//  Brush.swift
//  Ink - Pattern Drawing App
//
//  Created on November 10, 2025.
//

import Foundation

/// Represents a pattern brush with configurable parameters
struct PatternBrush: Codable {
    var type: PatternType
    var rotation: Float       // degrees (0-360)
    var spacing: Float        // pixels between stamps
    var opacity: Float        // 0-1
    var scale: Float          // 0.5-2.0
    var color: Color

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
         color: Color = .black) {
        self.type = type
        self.rotation = rotation
        self.spacing = spacing
        self.opacity = opacity
        self.scale = scale
        self.color = color
    }
}
