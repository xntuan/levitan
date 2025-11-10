//
//  Layer.swift
//  Ink - Pattern Drawing App
//
//  Created on November 10, 2025.
//

import Metal
import CoreGraphics

/// Represents a drawing layer with mask and content textures
struct Layer: Codable {
    let id: UUID
    var name: String
    var opacity: Float
    var blendMode: BlendMode
    var isVisible: Bool
    var isLocked: Bool

    // Note: MTLTexture cannot be Codable, will be handled separately
    // var maskTexture: MTLTexture
    // var contentTexture: MTLTexture

    enum BlendMode: String, Codable {
        case normal     // 0
        case multiply   // 1
        case screen     // 2
        case overlay    // 3
        case add        // 4 (linear dodge)
        case darken     // 5
        case lighten    // 6

        /// Convert blend mode to shader integer value
        var shaderValue: Int {
            switch self {
            case .normal: return 0
            case .multiply: return 1
            case .screen: return 2
            case .overlay: return 3
            case .add: return 4
            case .darken: return 5
            case .lighten: return 6
            }
        }

        /// Display name for UI
        var displayName: String {
            switch self {
            case .normal: return "Normal"
            case .multiply: return "Multiply"
            case .screen: return "Screen"
            case .overlay: return "Overlay"
            case .add: return "Add"
            case .darken: return "Darken"
            case .lighten: return "Lighten"
            }
        }
    }

    init(id: UUID = UUID(), name: String, opacity: Float = 1.0, blendMode: BlendMode = .normal, isVisible: Bool = true, isLocked: Bool = false) {
        self.id = id
        self.name = name
        self.opacity = opacity
        self.blendMode = blendMode
        self.isVisible = isVisible
        self.isLocked = isLocked
    }
}
