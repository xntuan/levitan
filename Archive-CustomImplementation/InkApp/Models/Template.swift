//
//  Template.swift
//  Ink - Pattern Drawing App
//
//  Template data model for artwork templates
//  Created on November 10, 2025.
//

import UIKit
import CoreGraphics

/// Technique used in pattern drawing
enum PatternTechnique: String, Codable, CaseIterable {
    case stippling = "Stippling"
    case hatching = "Hatching"
    case crossHatching = "Cross-Hatching"
    case contourHatching = "Contour Hatching"
    case mixed = "Mixed Techniques"
    case waves = "Wave Patterns"

    var icon: String {
        switch self {
        case .stippling: return "⚫️"
        case .hatching: return "📏"
        case .crossHatching: return "✖️"
        case .contourHatching: return "🌊"
        case .mixed: return "🎨"
        case .waves: return "〰️"
        }
    }

    var description: String {
        switch self {
        case .stippling: return "Create shading with individual dots"
        case .hatching: return "Parallel lines create tone"
        case .crossHatching: return "Overlapping lines for depth"
        case .contourHatching: return "Lines follow the form"
        case .mixed: return "Combination of multiple techniques"
        case .waves: return "Organic wave patterns"
        }
    }
}

/// Represents an artwork template with pre-defined layers and metadata
struct Template: Codable, Identifiable {

    // MARK: - Properties

    let id: UUID
    var name: String
    var description: String
    var category: Category
    var difficulty: Difficulty
    var estimatedMinutes: Int
    var tags: [String]

    // Template assets
    var thumbnailImageName: String
    var baseImageName: String
    var layerDefinitions: [LayerDefinition]

    // NEW: Pattern-specific metadata
    var primaryTechnique: PatternTechnique
    var suggestedColors: [PatternBrush.Color]

    // NEW: Artist attribution
    var artistName: String?
    var artistBio: String?

    // NEW: Daily content system
    var isDaily: Bool
    var unlockDate: Date?  // When this template becomes available

    // Metadata
    var createdAt: Date
    var isFeatured: Bool
    var isLocked: Bool  // Premium templates

    // MARK: - Nested Types

    enum Category: String, Codable, CaseIterable {
        case nature = "Nature"
        case abstract = "Abstract"
        case animals = "Animals"
        case landscapes = "Landscapes"
        case patterns = "Patterns"

        var emoji: String {
            switch self {
            case .nature: return "🌿"
            case .abstract: return "🎨"
            case .animals: return "🐱"
            case .landscapes: return "🏔️"
            case .patterns: return "✨"
            }
        }

        var colorGradient: [UIColor] {
            switch self {
            case .nature:
                return [
                    UIColor(hex: "a8edea")!,
                    UIColor(hex: "fed6e3")!
                ]
            case .abstract:
                return [
                    UIColor(hex: "667eea")!,
                    UIColor(hex: "764ba2")!
                ]
            case .animals:
                return [
                    UIColor(hex: "ffecd2")!,
                    UIColor(hex: "fcb69f")!
                ]
            case .landscapes:
                return [
                    UIColor(hex: "48c6ef")!,
                    UIColor(hex: "6f86d6")!
                ]
            case .patterns:
                return [
                    UIColor(hex: "667eea")!,
                    UIColor(hex: "764ba2")!
                ]
            }
        }
    }

    enum Difficulty: String, Codable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"

        var emoji: String {
            switch self {
            case .beginner: return "⭐️"
            case .intermediate: return "⭐️⭐️"
            case .advanced: return "⭐️⭐️⭐️"
            }
        }
    }

    /// Definition for a template layer
    struct LayerDefinition: Codable, Identifiable {
        let id: UUID
        var name: String
        var maskImageName: String?  // Optional mask image
        var suggestedPattern: PatternBrush.PatternType?
        var order: Int  // Layer stacking order

        init(
            id: UUID = UUID(),
            name: String,
            maskImageName: String? = nil,
            suggestedPattern: PatternBrush.PatternType? = nil,
            order: Int
        ) {
            self.id = id
            self.name = name
            self.maskImageName = maskImageName
            self.suggestedPattern = suggestedPattern
            self.order = order
        }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        category: Category,
        difficulty: Difficulty = .beginner,
        estimatedMinutes: Int = 15,
        tags: [String] = [],
        thumbnailImageName: String,
        baseImageName: String,
        layerDefinitions: [LayerDefinition],
        primaryTechnique: PatternTechnique = .mixed,
        suggestedColors: [PatternBrush.Color] = [.black],
        artistName: String? = nil,
        artistBio: String? = nil,
        isDaily: Bool = false,
        unlockDate: Date? = nil,
        createdAt: Date = Date(),
        isFeatured: Bool = false,
        isLocked: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.estimatedMinutes = estimatedMinutes
        self.tags = tags
        self.thumbnailImageName = thumbnailImageName
        self.baseImageName = baseImageName
        self.layerDefinitions = layerDefinitions.sorted { $0.order < $1.order }
        self.primaryTechnique = primaryTechnique
        self.suggestedColors = suggestedColors
        self.artistName = artistName
        self.artistBio = artistBio
        self.isDaily = isDaily
        self.unlockDate = unlockDate
        self.createdAt = createdAt
        self.isFeatured = isFeatured
        self.isLocked = isLocked
    }

    // MARK: - Helper Methods

    /// Load thumbnail image
    func loadThumbnail() -> UIImage? {
        return UIImage(named: thumbnailImageName)
    }

    /// Load base image
    func loadBaseImage() -> UIImage? {
        return UIImage(named: baseImageName)
    }

    /// Load mask image for specific layer
    func loadMaskImage(for layerDef: LayerDefinition) -> UIImage? {
        guard let maskImageName = layerDef.maskImageName else {
            return nil
        }

        // Try to load from asset catalog first
        if let image = UIImage(named: maskImageName) {
            return image
        }

        // Fallback: Generate mask programmatically
        print("  ⚠️ Mask image '\(maskImageName)' not found, generating programmatically")
        return generateMaskForLayer(layerDef)
    }

    /// Generate mask programmatically if asset doesn't exist
    private func generateMaskForLayer(_ layerDef: LayerDefinition) -> UIImage? {
        let size = CGSize(width: 2048, height: 2048)

        // Infer region from layer order and name
        let totalLayers = layerDefinitions.count
        let region: MaskGenerator.Region

        let lowercaseName = layerDef.name.lowercased()

        if lowercaseName.contains("sky") || lowercaseName.contains("background") {
            region = .top
        } else if lowercaseName.contains("mountain") || lowercaseName.contains("tree") || lowercaseName.contains("clouds") || lowercaseName.contains("middle") {
            region = .middle
        } else if lowercaseName.contains("foreground") || lowercaseName.contains("shore") || lowercaseName.contains("path") || lowercaseName.contains("water") {
            region = .bottom
        } else {
            // Fallback to order-based division
            if totalLayers == 2 {
                region = layerDef.order == 0 ? .top : .bottom
            } else if totalLayers == 3 {
                region = layerDef.order == 0 ? .top : (layerDef.order == 1 ? .middle : .bottom)
            } else {
                let fraction = CGFloat(layerDef.order) / CGFloat(totalLayers)
                let height = 1.0 / CGFloat(totalLayers)
                region = .custom(fraction, fraction + height)
            }
        }

        return MaskGenerator.generateGradientMask(size: size, region: region, feather: 100)
    }

    /// Get display string for duration
    var durationDisplay: String {
        if estimatedMinutes < 60 {
            return "\(estimatedMinutes) min"
        } else {
            let hours = estimatedMinutes / 60
            let minutes = estimatedMinutes % 60
            if minutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(minutes)m"
            }
        }
    }
}

// MARK: - Sample Templates

extension Template {
    /// Create sample templates for development
    static func createSampleTemplates() -> [Template] {
        return [
            // Nature Category
            Template(
                name: "Mountain Sunset",
                description: "Draw a peaceful mountain landscape at sunset with layered silhouettes",
                category: .nature,
                difficulty: .beginner,
                estimatedMinutes: 15,
                tags: ["mountains", "sunset", "landscape"],
                thumbnailImageName: "template_mountain_sunset_thumb",
                baseImageName: "template_mountain_sunset_base",
                layerDefinitions: [
                    LayerDefinition(name: "Sky", maskImageName: "template_mountain_sunset_sky_mask", suggestedPattern: .parallelLines, order: 0),
                    LayerDefinition(name: "Mountains", maskImageName: "template_mountain_sunset_mountains_mask", suggestedPattern: .contourLines, order: 1),
                    LayerDefinition(name: "Foreground", maskImageName: "template_mountain_sunset_foreground_mask", suggestedPattern: .crossHatch, order: 2)
                ],
                isFeatured: true
            ),

            Template(
                name: "Forest Path",
                description: "Create a serene forest path with trees and dappled light",
                category: .nature,
                difficulty: .intermediate,
                estimatedMinutes: 20,
                tags: ["forest", "trees", "path"],
                thumbnailImageName: "template_forest_path_thumb",
                baseImageName: "template_forest_path_base",
                layerDefinitions: [
                    LayerDefinition(name: "Sky", suggestedPattern: .dots, order: 0),
                    LayerDefinition(name: "Trees", suggestedPattern: .parallelLines, order: 1),
                    LayerDefinition(name: "Path", suggestedPattern: .waves, order: 2)
                ]
            ),

            Template(
                name: "Ocean Waves",
                description: "Draw rolling ocean waves with a gradient sky",
                category: .nature,
                difficulty: .beginner,
                estimatedMinutes: 12,
                tags: ["ocean", "waves", "water"],
                thumbnailImageName: "template_ocean_waves_thumb",
                baseImageName: "template_ocean_waves_base",
                layerDefinitions: [
                    LayerDefinition(name: "Sky", suggestedPattern: .parallelLines, order: 0),
                    LayerDefinition(name: "Water", suggestedPattern: .waves, order: 1),
                    LayerDefinition(name: "Shore", suggestedPattern: .dots, order: 2)
                ],
                isFeatured: true
            ),

            Template(
                name: "Cherry Blossom",
                description: "Draw delicate cherry blossom branches against the sky",
                category: .nature,
                difficulty: .advanced,
                estimatedMinutes: 30,
                tags: ["flowers", "spring", "tree"],
                thumbnailImageName: "template_cherry_blossom_thumb",
                baseImageName: "template_cherry_blossom_base",
                layerDefinitions: [
                    LayerDefinition(name: "Sky", suggestedPattern: .dots, order: 0),
                    LayerDefinition(name: "Branches", suggestedPattern: .crossHatch, order: 1),
                    LayerDefinition(name: "Petals", suggestedPattern: .dots, order: 2)
                ]
            ),

            Template(
                name: "Desert Dunes",
                description: "Create a vast desert landscape with rolling dunes",
                category: .nature,
                difficulty: .intermediate,
                estimatedMinutes: 18,
                tags: ["desert", "sand", "dunes"],
                thumbnailImageName: "template_desert_dunes_thumb",
                baseImageName: "template_desert_dunes_base",
                layerDefinitions: [
                    LayerDefinition(name: "Sky", suggestedPattern: .parallelLines, order: 0),
                    LayerDefinition(name: "Dunes", suggestedPattern: .contourLines, order: 1),
                    LayerDefinition(name: "Cacti", suggestedPattern: .crossHatch, order: 2)
                ]
            ),

            // Abstract Category
            Template(
                name: "Geometric Shapes",
                description: "Fill abstract geometric shapes with patterns",
                category: .abstract,
                difficulty: .beginner,
                estimatedMinutes: 10,
                tags: ["geometric", "shapes", "modern"],
                thumbnailImageName: "template_geometric_shapes_thumb",
                baseImageName: "template_geometric_shapes_base",
                layerDefinitions: [
                    LayerDefinition(name: "Circles", suggestedPattern: .contourLines, order: 0),
                    LayerDefinition(name: "Triangles", suggestedPattern: .crossHatch, order: 1),
                    LayerDefinition(name: "Lines", suggestedPattern: .parallelLines, order: 2)
                ],
                isFeatured: true
            ),

            Template(
                name: "Flowing Curves",
                description: "Draw organic flowing curves with wave patterns",
                category: .abstract,
                difficulty: .intermediate,
                estimatedMinutes: 15,
                tags: ["curves", "organic", "flow"],
                thumbnailImageName: "template_flowing_curves_thumb",
                baseImageName: "template_flowing_curves_base",
                layerDefinitions: [
                    LayerDefinition(name: "Background", suggestedPattern: .dots, order: 0),
                    LayerDefinition(name: "Curves", suggestedPattern: .waves, order: 1)
                ]
            ),

            Template(
                name: "Mandala",
                description: "Create a symmetrical mandala with intricate patterns",
                category: .abstract,
                difficulty: .advanced,
                estimatedMinutes: 40,
                tags: ["mandala", "symmetry", "meditative"],
                thumbnailImageName: "template_mandala_thumb",
                baseImageName: "template_mandala_base",
                layerDefinitions: [
                    LayerDefinition(name: "Outer Ring", suggestedPattern: .contourLines, order: 0),
                    LayerDefinition(name: "Middle Ring", suggestedPattern: .dots, order: 1),
                    LayerDefinition(name: "Center", suggestedPattern: .crossHatch, order: 2)
                ]
            ),

            // Animals Category
            Template(
                name: "Sleeping Cat",
                description: "Draw a cozy sleeping cat with soft patterns",
                category: .animals,
                difficulty: .beginner,
                estimatedMinutes: 12,
                tags: ["cat", "pet", "cute"],
                thumbnailImageName: "template_sleeping_cat_thumb",
                baseImageName: "template_sleeping_cat_base",
                layerDefinitions: [
                    LayerDefinition(name: "Background", suggestedPattern: .dots, order: 0),
                    LayerDefinition(name: "Body", suggestedPattern: .parallelLines, order: 1),
                    LayerDefinition(name: "Details", suggestedPattern: .crossHatch, order: 2)
                ]
            ),

            Template(
                name: "Bird in Flight",
                description: "Capture a bird soaring through the clouds",
                category: .animals,
                difficulty: .intermediate,
                estimatedMinutes: 20,
                tags: ["bird", "flight", "sky"],
                thumbnailImageName: "template_bird_flight_thumb",
                baseImageName: "template_bird_flight_base",
                layerDefinitions: [
                    LayerDefinition(name: "Sky", suggestedPattern: .parallelLines, order: 0),
                    LayerDefinition(name: "Clouds", suggestedPattern: .dots, order: 1),
                    LayerDefinition(name: "Bird", suggestedPattern: .crossHatch, order: 2)
                ],
                isFeatured: true
            )
        ]
    }
}

// UIColor hex extension is defined in Extensions.swift
