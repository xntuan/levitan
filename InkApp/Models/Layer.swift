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
        case normal
        case multiply
        case screen
        case overlay
        // Add more blend modes as needed
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
