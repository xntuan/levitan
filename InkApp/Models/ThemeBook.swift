//
//  ThemeBook.swift
//  Ink - Pattern Drawing App
//
//  ThemeBook represents a curated collection of templates
//  Created on November 10, 2025.
//

import UIKit

/// A curated collection of templates (like a chapter in a coloring book)
struct ThemeBook: Codable, Identifiable {

    let id: UUID
    var title: String
    var description: String
    var coverImageName: String
    var icon: String  // Emoji
    var color: String  // Hex color for theme
    var templateIds: [UUID]  // References to templates
    var order: Int  // Display order
    var isFeatured: Bool
    var isLocked: Bool  // Premium content
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        coverImageName: String,
        icon: String,
        color: String,
        templateIds: [UUID] = [],
        order: Int = 0,
        isFeatured: Bool = false,
        isLocked: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.coverImageName = coverImageName
        self.icon = icon
        self.color = color
        self.templateIds = templateIds
        self.order = order
        self.isFeatured = isFeatured
        self.isLocked = isLocked
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Load cover image
    func loadCoverImage() -> UIImage? {
        return UIImage(named: coverImageName)
    }

    /// Get theme color
    func getThemeColor() -> UIColor {
        return UIColor(hex: color)
    }
}

// MARK: - Sample ThemeBooks

extension ThemeBook {
    /// Create sample theme books with template assignments
    static func createSampleThemeBooks(from templates: [Template] = []) -> [ThemeBook] {
        // If no templates provided, return empty theme books
        // (Admins can use Theme Book Creator to assign templates)
        guard !templates.isEmpty else {
            return createEmptyThemeBooks()
        }

        // Categorize templates
        let natureTemplates = templates.filter { $0.category == .nature }
        let abstractTemplates = templates.filter { $0.category == .abstract }
        let geometricTemplates = templates.filter { $0.category == .geometric }

        // Get easy templates for beginners (all Easy difficulty)
        let beginnerTemplates = templates.filter { $0.difficulty == .easy }.prefix(3).map { $0.id }

        // Nature theme book gets all nature templates
        let natureIds = natureTemplates.map { $0.id }

        // Abstract theme book gets abstract + some geometric
        let abstractIds = abstractTemplates.map { $0.id } + geometricTemplates.prefix(2).map { $0.id }

        // Animal theme book - currently empty (waiting for animal category templates)
        let animalIds: [UUID] = []

        // Zen theme book - advanced geometric patterns
        let zenIds = geometricTemplates.filter { $0.difficulty == .challenging }.map { $0.id }

        // Seasonal - some nature templates
        let seasonalIds = natureTemplates.suffix(2).map { $0.id }

        return [
            // Beginner's Journey
            ThemeBook(
                title: "Beginner's Journey",
                description: "Perfect for first-time artists. Simple templates with relaxing patterns.",
                coverImageName: "themebook_beginners_cover",
                icon: "🌱",
                color: "a8edea",
                templateIds: Array(beginnerTemplates),
                order: 0,
                isFeatured: true
            ),

            // Nature's Canvas
            ThemeBook(
                title: "Nature's Canvas",
                description: "Explore landscapes, sunsets, and the beauty of the natural world.",
                coverImageName: "themebook_nature_cover",
                icon: "🌿",
                color: "48c6ef",
                templateIds: natureIds,
                order: 1,
                isFeatured: true
            ),

            // Abstract Dreams
            ThemeBook(
                title: "Abstract Dreams",
                description: "Geometric shapes, flowing curves, and modern art patterns.",
                coverImageName: "themebook_abstract_cover",
                icon: "✨",
                color: "667eea",
                templateIds: abstractIds,
                order: 2,
                isFeatured: false
            ),

            // Animal Kingdom
            ThemeBook(
                title: "Animal Kingdom",
                description: "Cute and majestic creatures waiting for your patterns.",
                coverImageName: "themebook_animals_cover",
                icon: "🐾",
                color: "ffecd2",
                templateIds: animalIds,
                order: 3,
                isFeatured: false
            ),

            // Zen & Meditation
            ThemeBook(
                title: "Zen & Meditation",
                description: "Mandalas and calming patterns for mindful coloring.",
                coverImageName: "themebook_zen_cover",
                icon: "🧘",
                color: "c471ed",
                templateIds: zenIds,
                order: 4,
                isFeatured: false,
                isLocked: true  // Premium
            ),

            // Seasonal Celebrations
            ThemeBook(
                title: "Seasonal Celebrations",
                description: "Cherry blossoms, autumn leaves, winter wonderlands.",
                coverImageName: "themebook_seasonal_cover",
                icon: "🍂",
                color: "fa709a",
                templateIds: seasonalIds,
                order: 5,
                isFeatured: false
            )
        ]
    }

    /// Create empty theme books (for when no templates are available)
    private static func createEmptyThemeBooks() -> [ThemeBook] {
        return [
            ThemeBook(
                title: "Beginner's Journey",
                description: "Perfect for first-time artists. Simple templates with relaxing patterns.",
                coverImageName: "themebook_beginners_cover",
                icon: "🌱",
                color: "a8edea",
                order: 0,
                isFeatured: true
            ),
            ThemeBook(
                title: "Nature's Canvas",
                description: "Explore landscapes, sunsets, and the beauty of the natural world.",
                coverImageName: "themebook_nature_cover",
                icon: "🌿",
                color: "48c6ef",
                order: 1,
                isFeatured: true
            ),
            ThemeBook(
                title: "Abstract Dreams",
                description: "Geometric shapes, flowing curves, and modern art patterns.",
                coverImageName: "themebook_abstract_cover",
                icon: "✨",
                color: "667eea",
                order: 2,
                isFeatured: false
            ),
            ThemeBook(
                title: "Animal Kingdom",
                description: "Cute and majestic creatures waiting for your patterns.",
                coverImageName: "themebook_animals_cover",
                icon: "🐾",
                color: "ffecd2",
                order: 3,
                isFeatured: false
            ),
            ThemeBook(
                title: "Zen & Meditation",
                description: "Mandalas and calming patterns for mindful coloring.",
                coverImageName: "themebook_zen_cover",
                icon: "🧘",
                color: "c471ed",
                order: 4,
                isFeatured: false,
                isLocked: true
            ),
            ThemeBook(
                title: "Seasonal Celebrations",
                description: "Cherry blossoms, autumn leaves, winter wonderlands.",
                coverImageName: "themebook_seasonal_cover",
                icon: "🍂",
                color: "fa709a",
                order: 5,
                isFeatured: false
            )
        ]
    }
}
