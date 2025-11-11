//
//  BrushStamp.swift
//  Ink - Pattern Drawing App
//
//  Represents a single brush or marker stamp for solid rendering
//  Created on November 11, 2025.
//

import CoreGraphics
import Foundation

/// Represents a single brush/marker stamp to be rendered
struct BrushStamp {
    let position: CGPoint
    let size: Float             // Diameter in pixels
    let opacity: Float          // 0-1
    let hardness: Float         // 0=soft, 1=hard
    let color: PatternBrush.Color
    let isEraser: Bool         // When true, erases instead of drawing
    let tool: DrawingTool      // brush or marker

    init(
        position: CGPoint,
        size: Float,
        opacity: Float,
        hardness: Float,
        color: PatternBrush.Color,
        isEraser: Bool = false,
        tool: DrawingTool = .brush
    ) {
        self.position = position
        self.size = size
        self.opacity = opacity
        self.hardness = hardness
        self.color = color
        self.isEraser = isEraser
        self.tool = tool
    }
}
