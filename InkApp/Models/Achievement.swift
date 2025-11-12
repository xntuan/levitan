//
//  Achievement.swift
//  Ink - Pattern Drawing App
//
//  Achievement system for user progression and engagement
//  Created on November 11, 2025.
//

import Foundation

// MARK: - Achievement

/// Represents an unlockable achievement
struct Achievement: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let requirement: AchievementRequirement
    let reward: AchievementReward?
    let points: Int
    let tier: Tier

    enum Tier: String, Codable {
        case bronze = "Bronze"
        case silver = "Silver"
        case gold = "Gold"
        case platinum = "Platinum"
    }

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        icon: String,
        category: AchievementCategory,
        requirement: AchievementRequirement,
        reward: AchievementReward? = nil,
        points: Int = 10,
        tier: Tier = .bronze
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.category = category
        self.requirement = requirement
        self.reward = reward
        self.points = points
        self.tier = tier
    }
}

// MARK: - Achievement Category

enum AchievementCategory: String, Codable, CaseIterable {
    case technique = "Technique Mastery"
    case collection = "Collection Completion"
    case dedication = "Time & Dedication"
    case social = "Social & Sharing"
    case streak = "Daily Streak"
    case special = "Special"

    var icon: String {
        switch self {
        case .technique: return "🎨"
        case .collection: return "📚"
        case .dedication: return "⏰"
        case .social: return "👥"
        case .streak: return "🔥"
        case .special: return "⭐️"
        }
    }
}

// MARK: - Achievement Requirement

enum AchievementRequirement: Codable, Hashable {
    // Technique-based
    case completeTechniqueWorks(technique: PatternTechnique, count: Int)
    case useMixedTechniques(techniqueCount: Int, workCount: Int)
    case masterPrecision(undoLimit: Int, workCount: Int)

    // Collection-based
    case completeCategory(category: Template.Category)
    case completeDifficulty(difficulty: Template.Difficulty)
    case completeTemplates(count: Int)

    // Time-based
    case totalDrawingTime(minutes: Int)
    case completeQuickWork(minutes: Int)
    case completeLongWork(minutes: Int)

    // Streak-based
    case dailyStreak(days: Int)
    case totalActiveDays(days: Int)

    // Social-based
    case shareWorks(count: Int)
    case galleryViews(count: Int)
    case receiveLikes(count: Int)

    // Special
    case completeChallenge(count: Int)
    case reachLevel(level: Int)
}

// MARK: - Achievement Reward

struct AchievementReward: Codable {
    let templateUnlockIds: [UUID]
    let patternUnlocks: [String]  // Pattern names
    let title: String?  // Special title (e.g., "Master Stippler")
}

// MARK: - User Achievement Progress

struct UserAchievementProgress: Codable {
    var unlockedAchievements: Set<UUID>
    var achievementProgress: [UUID: Float]  // 0.0 to 1.0
    var totalPoints: Int
    var unlockedTitles: [String]

    // Statistics for tracking
    var techniqueStats: [PatternTechnique: Int]  // Count per technique
    var categoryStats: [Template.Category: Int]  // Count per category
    var difficultyStats: [Template.Difficulty: Int]  // Count per difficulty
    var totalDrawingMinutes: Int
    var totalCompletedWorks: Int
    var totalShares: Int
    var totalGalleryViews: Int
    var totalLikesReceived: Int
    var completedChallenges: Int

    init() {
        self.unlockedAchievements = []
        self.achievementProgress = [:]
        self.totalPoints = 0
        self.unlockedTitles = []
        self.techniqueStats = [:]
        self.categoryStats = [:]
        self.difficultyStats = [:]
        self.totalDrawingMinutes = 0
        self.totalCompletedWorks = 0
        self.totalShares = 0
        self.totalGalleryViews = 0
        self.totalLikesReceived = 0
        self.completedChallenges = 0
    }

    /// Calculate user level based on points
    var level: Int {
        // Exponential leveling: level = floor(sqrt(points / 10))
        return Int(floor(sqrt(Double(totalPoints) / 10.0)))
    }

    /// Points needed for next level
    var pointsForNextLevel: Int {
        let nextLevel = level + 1
        return nextLevel * nextLevel * 10
    }

    /// Progress to next level (0.0 to 1.0)
    var levelProgress: Float {
        let currentLevelPoints = level * level * 10
        let nextLevelPoints = pointsForNextLevel
        let pointsInCurrentLevel = totalPoints - currentLevelPoints
        let pointsNeededForLevel = nextLevelPoints - currentLevelPoints

        return Float(pointsInCurrentLevel) / Float(pointsNeededForLevel)
    }
}

// MARK: - Sample Achievements

extension Achievement {
    /// Create predefined achievements
    static func standardAchievements() -> [Achievement] {
        return [
            // TECHNIQUE MASTERY
            Achievement(
                title: "Stippling Novice",
                description: "Complete 5 works using stippling",
                icon: "⚫️",
                category: .technique,
                requirement: .completeTechniqueWorks(technique: .stippling, count: 5),
                points: 10,
                tier: .bronze
            ),
            Achievement(
                title: "Stippling Adept",
                description: "Complete 20 works using stippling",
                icon: "⚫️⚫️",
                category: .technique,
                requirement: .completeTechniqueWorks(technique: .stippling, count: 20),
                points: 25,
                tier: .silver
            ),
            Achievement(
                title: "Stippling Master",
                description: "Complete 50 works using stippling",
                icon: "⚫️⚫️⚫️",
                category: .technique,
                requirement: .completeTechniqueWorks(technique: .stippling, count: 50),
                reward: AchievementReward(templateUnlockIds: [], patternUnlocks: [], title: "Master Stippler"),
                points: 50,
                tier: .gold
            ),

            Achievement(
                title: "Hatching Novice",
                description: "Complete 5 works using hatching",
                icon: "📏",
                category: .technique,
                requirement: .completeTechniqueWorks(technique: .hatching, count: 5),
                points: 10,
                tier: .bronze
            ),
            Achievement(
                title: "Hatching Adept",
                description: "Complete 20 works using hatching",
                icon: "📏📏",
                category: .technique,
                requirement: .completeTechniqueWorks(technique: .hatching, count: 20),
                points: 25,
                tier: .silver
            ),
            Achievement(
                title: "Hatching Master",
                description: "Complete 50 works using hatching",
                icon: "📏📏📏",
                category: .technique,
                requirement: .completeTechniqueWorks(technique: .hatching, count: 50),
                reward: AchievementReward(templateUnlockIds: [], patternUnlocks: [], title: "Master Hatcher"),
                points: 50,
                tier: .gold
            ),

            Achievement(
                title: "Technique Explorer",
                description: "Use all 6 pattern techniques",
                icon: "🎨",
                category: .technique,
                requirement: .useMixedTechniques(techniqueCount: 6, workCount: 1),
                points: 20,
                tier: .silver
            ),
            Achievement(
                title: "Precision Artist",
                description: "Complete 5 works with fewer than 5 undos each",
                icon: "🎯",
                category: .technique,
                requirement: .masterPrecision(undoLimit: 5, workCount: 5),
                points: 30,
                tier: .gold
            ),

            // COLLECTION COMPLETION
            Achievement(
                title: "Beginner Collection",
                description: "Complete all beginner templates",
                icon: "⭐️",
                category: .collection,
                requirement: .completeDifficulty(difficulty: .beginner),
                points: 25,
                tier: .bronze
            ),
            Achievement(
                title: "Intermediate Collection",
                description: "Complete all intermediate templates",
                icon: "⭐️⭐️",
                category: .collection,
                requirement: .completeDifficulty(difficulty: .intermediate),
                points: 50,
                tier: .silver
            ),
            Achievement(
                title: "Advanced Collection",
                description: "Complete all advanced templates",
                icon: "⭐️⭐️⭐️",
                category: .collection,
                requirement: .completeDifficulty(difficulty: .advanced),
                points: 100,
                tier: .gold
            ),

            Achievement(
                title: "Animal Lover",
                description: "Complete 10 animal templates",
                icon: "🐱",
                category: .collection,
                requirement: .completeCategory(category: .animals),
                points: 20,
                tier: .bronze
            ),
            Achievement(
                title: "Nature Enthusiast",
                description: "Complete 10 nature templates",
                icon: "🌿",
                category: .collection,
                requirement: .completeCategory(category: .nature),
                points: 20,
                tier: .bronze
            ),

            Achievement(
                title: "First Steps",
                description: "Complete your first template",
                icon: "🎉",
                category: .collection,
                requirement: .completeTemplates(count: 1),
                points: 5,
                tier: .bronze
            ),
            Achievement(
                title: "Getting Started",
                description: "Complete 10 templates",
                icon: "📝",
                category: .collection,
                requirement: .completeTemplates(count: 10),
                points: 15,
                tier: .bronze
            ),
            Achievement(
                title: "Dedicated Artist",
                description: "Complete 50 templates",
                icon: "🎨",
                category: .collection,
                requirement: .completeTemplates(count: 50),
                points: 50,
                tier: .silver
            ),
            Achievement(
                title: "Master Collector",
                description: "Complete 100 templates",
                icon: "👑",
                category: .collection,
                requirement: .completeTemplates(count: 100),
                points: 100,
                tier: .gold
            ),

            // TIME & DEDICATION
            Achievement(
                title: "10 Hour Mark",
                description: "Spend 10 hours drawing",
                icon: "⏰",
                category: .dedication,
                requirement: .totalDrawingTime(minutes: 600),
                points: 20,
                tier: .bronze
            ),
            Achievement(
                title: "50 Hour Commitment",
                description: "Spend 50 hours drawing",
                icon: "⏰⏰",
                category: .dedication,
                requirement: .totalDrawingTime(minutes: 3000),
                points: 50,
                tier: .silver
            ),
            Achievement(
                title: "Lifetime Devotion",
                description: "Spend 100 hours drawing",
                icon: "⏰⏰⏰",
                category: .dedication,
                requirement: .totalDrawingTime(minutes: 6000),
                points: 100,
                tier: .gold
            ),

            // STREAK ACHIEVEMENTS
            Achievement(
                title: "Week Strong",
                description: "Maintain a 7-day streak",
                icon: "🔥",
                category: .streak,
                requirement: .dailyStreak(days: 7),
                points: 15,
                tier: .bronze
            ),
            Achievement(
                title: "Monthly Dedication",
                description: "Maintain a 30-day streak",
                icon: "🔥🔥",
                category: .streak,
                requirement: .dailyStreak(days: 30),
                points: 40,
                tier: .silver
            ),
            Achievement(
                title: "Century Streak",
                description: "Maintain a 100-day streak",
                icon: "🔥🔥🔥",
                category: .streak,
                requirement: .dailyStreak(days: 100),
                reward: AchievementReward(templateUnlockIds: [], patternUnlocks: [], title: "Streak Master"),
                points: 100,
                tier: .gold
            ),

            Achievement(
                title: "Active Member",
                description: "Be active for 30 total days",
                icon: "📅",
                category: .streak,
                requirement: .totalActiveDays(days: 30),
                points: 20,
                tier: .bronze
            ),
            Achievement(
                title: "Veteran Artist",
                description: "Be active for 100 total days",
                icon: "📅📅",
                category: .streak,
                requirement: .totalActiveDays(days: 100),
                points: 50,
                tier: .silver
            ),

            // SOCIAL ACHIEVEMENTS
            Achievement(
                title: "First Share",
                description: "Share your first completed work",
                icon: "📤",
                category: .social,
                requirement: .shareWorks(count: 1),
                points: 5,
                tier: .bronze
            ),
            Achievement(
                title: "Social Butterfly",
                description: "Share 10 works",
                icon: "🦋",
                category: .social,
                requirement: .shareWorks(count: 10),
                points: 15,
                tier: .bronze
            ),
            Achievement(
                title: "Community Star",
                description: "Get 100 gallery views",
                icon: "👁️",
                category: .social,
                requirement: .galleryViews(count: 100),
                points: 20,
                tier: .silver
            ),

            // SPECIAL ACHIEVEMENTS
            Achievement(
                title: "Challenge Accepted",
                description: "Complete your first daily challenge",
                icon: "🎯",
                category: .special,
                requirement: .completeChallenge(count: 1),
                points: 10,
                tier: .bronze
            ),
            Achievement(
                title: "Challenge Seeker",
                description: "Complete 10 daily challenges",
                icon: "🎯🎯",
                category: .special,
                requirement: .completeChallenge(count: 10),
                points: 30,
                tier: .silver
            ),
            Achievement(
                title: "Level 10",
                description: "Reach level 10",
                icon: "🔟",
                category: .special,
                requirement: .reachLevel(level: 10),
                points: 50,
                tier: .silver
            ),
            Achievement(
                title: "Level 25",
                description: "Reach level 25",
                icon: "2️⃣5️⃣",
                category: .special,
                requirement: .reachLevel(level: 25),
                points: 100,
                tier: .gold
            ),
            Achievement(
                title: "Level 50",
                description: "Reach level 50",
                icon: "5️⃣0️⃣",
                category: .special,
                requirement: .reachLevel(level: 50),
                reward: AchievementReward(templateUnlockIds: [], patternUnlocks: [], title: "Pattern Legend"),
                points: 200,
                tier: .platinum
            )
        ]
    }
}
