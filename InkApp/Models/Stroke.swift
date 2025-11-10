//
//  Stroke.swift
//  Ink - Pattern Drawing App
//
//  Created on November 10, 2025.
//

import CoreGraphics
import Foundation

/// Represents a drawing stroke with multiple points
struct Stroke: Codable {
    var points: [StrokePoint]
    var brush: PatternBrush
    var layerId: UUID

    init(points: [StrokePoint] = [], brush: PatternBrush, layerId: UUID) {
        self.points = points
        self.brush = brush
        self.layerId = layerId
    }
}

/// Represents a single point in a stroke with pressure and timing information
struct StrokePoint: Codable {
    var position: CGPoint
    var pressure: Float       // 0-1, from Apple Pencil or default to 1.0
    var timestamp: TimeInterval
    var tiltAngle: Float?     // 0-90°, altitude angle from Apple Pencil (optional)
    var azimuthAngle: Float?  // 0-360°, direction angle from Apple Pencil (optional)

    init(position: CGPoint, pressure: Float = 1.0, timestamp: TimeInterval = Date().timeIntervalSince1970, tiltAngle: Float? = nil, azimuthAngle: Float? = nil) {
        self.position = position
        self.pressure = pressure
        self.timestamp = timestamp
        self.tiltAngle = tiltAngle
        self.azimuthAngle = azimuthAngle
    }
}

// MARK: - CGPoint Codable Extension
extension CGPoint: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
}
