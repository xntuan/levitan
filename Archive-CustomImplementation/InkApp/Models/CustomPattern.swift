//
//  CustomPattern.swift
//  Ink - Pattern Drawing App
//
//  Models for custom user-created patterns
//  Created on November 11, 2025.
//

import Foundation
import CoreGraphics

/// User-created custom pattern
struct CustomPattern: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String?
    var thumbnailData: Data?

    // Pattern definition
    var elements: [PatternElement]
    var arrangement: PatternArrangement
    var bounds: CGSize

    // Metadata
    var creatorID: String
    var isPublic: Bool
    var downloads: Int = 0
    var likes: Int = 0

    // Dates
    var createdAt: Date
    var updatedAt: Date

    // Categories
    var tags: [String] = []
    var category: PatternCategory

    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        elements: [PatternElement],
        arrangement: PatternArrangement,
        bounds: CGSize = CGSize(width: 100, height: 100),
        creatorID: String,
        category: PatternCategory,
        isPublic: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.elements = elements
        self.arrangement = arrangement
        self.bounds = bounds
        self.creatorID = creatorID
        self.category = category
        self.isPublic = isPublic
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Pattern Elements

/// Individual element in a pattern
struct PatternElement: Codable, Identifiable {
    let id: UUID
    var shape: ElementShape
    var position: CGPoint
    var size: CGSize
    var rotation: Float  // degrees
    var opacity: Float   // 0-1

    init(
        id: UUID = UUID(),
        shape: ElementShape,
        position: CGPoint,
        size: CGSize,
        rotation: Float = 0,
        opacity: Float = 1.0
    ) {
        self.id = id
        self.shape = shape
        self.position = position
        self.size = size
        self.rotation = rotation
        self.opacity = opacity
    }
}

enum ElementShape: Codable {
    case circle
    case rectangle
    case triangle
    case line(start: CGPoint, end: CGPoint)
    case arc(startAngle: Float, endAngle: Float)
    case bezier(controlPoint1: CGPoint, controlPoint2: CGPoint, endPoint: CGPoint)
    case polygon(points: [CGPoint])
    case custom(path: String)  // SVG path string

    var displayName: String {
        switch self {
        case .circle: return "Circle"
        case .rectangle: return "Rectangle"
        case .triangle: return "Triangle"
        case .line: return "Line"
        case .arc: return "Arc"
        case .bezier: return "Curve"
        case .polygon: return "Polygon"
        case .custom: return "Custom"
        }
    }
}

// MARK: - Pattern Arrangement

/// How pattern elements are arranged
enum PatternArrangement: Codable {
    case grid(rows: Int, columns: Int, spacing: CGSize)
    case radial(count: Int, radius: Float, angleOffset: Float)
    case spiral(count: Int, spacing: Float, rotation: Float)
    case random(count: Int, seed: Int)
    case organic(algorithm: OrganicAlgorithm)
    case custom

    var displayName: String {
        switch self {
        case .grid: return "Grid"
        case .radial: return "Radial"
        case .spiral: return "Spiral"
        case .random: return "Random"
        case .organic: return "Organic"
        case .custom: return "Custom"
        }
    }
}

enum OrganicAlgorithm: String, Codable {
    case voronoi = "Voronoi"
    case perlin = "Perlin Noise"
    case fractal = "Fractal"
    case scatter = "Scatter"
}

// MARK: - Pattern Category

enum PatternCategory: String, Codable, CaseIterable {
    case geometric = "Geometric"
    case organic = "Organic"
    case decorative = "Decorative"
    case technical = "Technical"
    case artistic = "Artistic"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .geometric: return "📐"
        case .organic: return "🌿"
        case .decorative: return "✨"
        case .technical: return "⚙️"
        case .artistic: return "🎨"
        case .custom: return "🔧"
        }
    }
}

// MARK: - Pattern Library Entry

/// Pattern in the community library
struct PatternLibraryEntry: Codable, Identifiable {
    let id: UUID
    let patternID: UUID
    var name: String
    var description: String
    var thumbnailURL: String

    // Creator info
    var creatorID: String
    var creatorUsername: String
    var creatorAvatarURL: String?

    // Engagement
    var downloads: Int
    var likes: Int
    var rating: Float  // 0-5 stars

    // Metadata
    var category: PatternCategory
    var tags: [String]
    var isPremium: Bool
    var price: Int?  // Points cost

    var createdAt: Date

    var isPopular: Bool {
        downloads > 100 || likes > 50
    }

    var isTrending: Bool {
        let daysSinceCreation = Date().timeIntervalSince(createdAt) / 86400
        return daysSinceCreation < 7 && downloads > 20
    }
}
