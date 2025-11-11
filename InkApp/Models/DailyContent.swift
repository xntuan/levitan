//
//  DailyContent.swift
//  Ink - Pattern Drawing App
//
//  Models for daily content, challenges, and streak tracking
//  Created on November 11, 2025.
//

import Foundation

// MARK: - Daily Content

/// Represents the daily free content available to users
struct DailyContent: Codable {
    let date: Date
    let freeTemplate: Template
    let challenge: DailyChallenge?
    let tipOfTheDay: String
    let streakBonus: Int  // Extra templates if returning after absence
}

// MARK: - Daily Challenge

/// A daily challenge to encourage specific techniques and patterns
struct DailyChallenge: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let template: Template
    let requiredTechnique: PatternTechnique
    let reward: ChallengeReward
    let expiresAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        template: Template,
        requiredTechnique: PatternTechnique,
        reward: ChallengeReward,
        expiresAt: Date
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.template = template
        self.requiredTechnique = requiredTechnique
        self.reward = reward
        self.expiresAt = expiresAt
    }
}

/// Reward for completing a challenge
struct ChallengeReward: Codable {
    let points: Int
    let achievementId: UUID?
    let unlockTemplateId: UUID?
}

// MARK: - Streak Tracking

/// User's daily streak information
struct StreakStatus: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: Date
    var streakFreezeAvailable: Bool  // Allow one missed day
    var totalActiveDays: Int

    init(
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastActiveDate: Date = Date(),
        streakFreezeAvailable: Bool = true,
        totalActiveDays: Int = 0
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastActiveDate = lastActiveDate
        self.streakFreezeAvailable = streakFreezeAvailable
        self.totalActiveDays = totalActiveDays
    }

    /// Check if streak should continue or reset
    mutating func updateForToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastActive = calendar.startOfDay(for: lastActiveDate)

        let daysSince = calendar.dateComponents([.day], from: lastActive, to: today).day ?? 0

        if daysSince == 0 {
            // Already active today, no change
            return
        } else if daysSince == 1 {
            // Consecutive day
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
            lastActiveDate = Date()
            totalActiveDays += 1
        } else if daysSince == 2 && streakFreezeAvailable {
            // Missed one day but freeze is available
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
            streakFreezeAvailable = false
            lastActiveDate = Date()
            totalActiveDays += 1
        } else {
            // Streak broken
            currentStreak = 1
            lastActiveDate = Date()
            totalActiveDays += 1
            streakFreezeAvailable = true  // Reset freeze for new streak
        }
    }
}

// MARK: - Tip of the Day

/// Pattern drawing tips for education
struct PatternTip: Codable {
    let id: UUID
    let title: String
    let content: String
    let technique: PatternTechnique
    let difficulty: Template.Difficulty

    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        technique: PatternTechnique,
        difficulty: Template.Difficulty
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.technique = technique
        self.difficulty = difficulty
    }
}

// MARK: - Sample Tips

extension PatternTip {
    /// Get a pool of tips for rotation
    static func sampleTips() -> [PatternTip] {
        return [
            PatternTip(
                title: "Stippling Spacing",
                content: "For smooth gradients, gradually increase dot spacing rather than reducing dot size. This creates more natural-looking transitions.",
                technique: .stippling,
                difficulty: .beginner
            ),
            PatternTip(
                title: "Hatching Direction",
                content: "Always follow the form with your hatching lines. For rounded objects, use curved contour hatching instead of straight lines.",
                technique: .contourHatching,
                difficulty: .intermediate
            ),
            PatternTip(
                title: "Cross-Hatching Angles",
                content: "Start with 45° and -45° angles for your first two layers. Add more angles at 30° increments for deeper shadows.",
                technique: .crossHatching,
                difficulty: .intermediate
            ),
            PatternTip(
                title: "Consistent Pressure",
                content: "With Apple Pencil, maintain consistent pressure within each hatching stroke for even line weight. Vary density, not darkness.",
                technique: .hatching,
                difficulty: .beginner
            ),
            PatternTip(
                title: "Wave Pattern Rhythm",
                content: "Create organic textures by varying wave amplitude and frequency. Keep the rhythm consistent but not mechanical.",
                technique: .waves,
                difficulty: .beginner
            ),
            PatternTip(
                title: "Building Density",
                content: "Add patterns in layers: start sparse, then add more where shadows fall. It's easier to darken than to lighten!",
                technique: .mixed,
                difficulty: .intermediate
            ),
            PatternTip(
                title: "Stipple Size Variety",
                content: "Mix different dot sizes in the same area for more organic textures. Larger dots in shadows, smaller in highlights.",
                technique: .stippling,
                difficulty: .advanced
            ),
            PatternTip(
                title: "Pattern Blending",
                content: "Transition smoothly between pattern types by overlapping them in the transition zone. Don't create hard boundaries.",
                technique: .mixed,
                difficulty: .advanced
            )
        ]
    }
}
