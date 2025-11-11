//
//  DrawingTool.swift
//  Ink - Pattern Drawing App
//
//  Defines the various drawing tool types available in the app
//  Created on November 11, 2025.
//

import Foundation

/// Represents the different drawing tool types
enum DrawingTool: String, Codable, CaseIterable {
    case pattern    // Pattern-based drawing (lines, dots, waves, etc.)
    case brush      // Solid brush with pressure sensitivity
    case marker     // Semi-transparent marker with blending
    case fillBucket // Flood fill tool
    case eraser     // Eraser tool (already implemented via isEraserMode)

    var displayName: String {
        switch self {
        case .pattern: return "Pattern"
        case .brush: return "Brush"
        case .marker: return "Marker"
        case .fillBucket: return "Fill"
        case .eraser: return "Eraser"
        }
    }

    var icon: String {
        switch self {
        case .pattern: return "✨"
        case .brush: return "🖌️"
        case .marker: return "🖍️"
        case .fillBucket: return "🪣"
        case .eraser: return "🧹"
        }
    }

    var requiresDragging: Bool {
        // Fill bucket is tap-based, others are drag-based
        return self != .fillBucket
    }
}

/// Configuration for brush tool (solid painting)
struct BrushToolConfig: Codable {
    var size: Float = 10.0              // Brush diameter in pixels
    var opacity: Float = 1.0            // Base opacity (0-1)
    var hardness: Float = 0.8           // Edge softness (0=soft, 1=hard)
    var pressureAffectsSize: Bool = true    // Pressure controls size
    var pressureAffectsOpacity: Bool = true // Pressure controls opacity
    var minSize: Float = 0.3            // Minimum size multiplier with pressure
    var minOpacity: Float = 0.3         // Minimum opacity multiplier with pressure
    var spacing: Float = 0.05           // Spacing between stamps (0-1, as fraction of size)
    var color: PatternBrush.Color = .black
}

/// Configuration for marker tool (semi-transparent blending)
struct MarkerToolConfig: Codable {
    var size: Float = 20.0              // Marker diameter in pixels
    var opacity: Float = 0.3            // Base opacity (typically lower than brush)
    var hardness: Float = 0.3           // Softer edges than brush
    var pressureAffectsSize: Bool = false   // Markers typically constant size
    var pressureAffectsOpacity: Bool = true // Pressure controls opacity
    var minOpacity: Float = 0.1         // Minimum opacity multiplier
    var spacing: Float = 0.02           // Tighter spacing for smoother strokes
    var blendMode: BlendMode = .normal
    var color: PatternBrush.Color = .black

    enum BlendMode: String, Codable {
        case normal
        case multiply
        case screen
        case overlay
    }
}

/// Configuration for fill bucket tool
struct FillBucketConfig: Codable {
    var tolerance: Float = 0.1          // Color matching tolerance (0-1)
    var opacity: Float = 1.0            // Fill opacity
    var contiguous: Bool = true         // Only fill connected pixels
    var antiAlias: Bool = true          // Smooth edges
    var color: PatternBrush.Color = .black
}
