//
//  Challenge.swift
//  Ink - Pattern Drawing App
//
//  Challenge system for community engagement
//  Created on November 11, 2025.
//

import Foundation

/// Represents a drawing challenge
struct Challenge: Codable, Identifiable {
    let id: UUID
    var title: String
    var description: String
    var bannerImageURL: String?

    // Challenge type and requirements
    var type: ChallengeType
    var requirements: ChallengeRequirements

    // Templates
    var templateIDs: [UUID]         // Allowed templates (empty = any)
    var category: Template.Category?
    var difficulty: Template.Difficulty?
    var technique: PatternTechnique?

    // Timing
    var startDate: Date
    var endDate: Date
    var duration: ChallengeDuration

    // Participation
    var participantCount: Int = 0
    var submissionCount: Int = 0
    var voteCount: Int = 0

    // Rewards
    var rewards: ChallengeRewards

    // Status
    var status: ChallengeStatus
    var isFeatured: Bool = false

    // Creator
    var creatorID: String?          // System challenges have nil
    var isOfficial: Bool = true

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        bannerImageURL: String? = nil,
        type: ChallengeType,
        requirements: ChallengeRequirements,
        templateIDs: [UUID] = [],
        category: Template.Category? = nil,
        difficulty: Template.Difficulty? = nil,
        technique: PatternTechnique? = nil,
        startDate: Date,
        endDate: Date,
        duration: ChallengeDuration,
        rewards: ChallengeRewards,
        creatorID: String? = nil,
        isOfficial: Bool = true
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.bannerImageURL = bannerImageURL
        self.type = type
        self.requirements = requirements
        self.templateIDs = templateIDs
        self.category = category
        self.difficulty = difficulty
        self.technique = technique
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.rewards = rewards
        self.status = .upcoming
        self.creatorID = creatorID
        self.isOfficial = isOfficial
    }

    /// Check if challenge is currently active
    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }

    /// Time remaining in challenge
    var timeRemaining: TimeInterval {
        return endDate.timeIntervalSinceNow
    }

    /// Time remaining formatted
    var timeRemainingFormatted: String {
        let remaining = timeRemaining
        if remaining < 0 { return "Ended" }

        let days = Int(remaining) / 86400
        let hours = (Int(remaining) % 86400) / 3600

        if days > 0 {
            return "\(days)d \(hours)h remaining"
        } else {
            return "\(hours)h remaining"
        }
    }
}

// MARK: - Challenge Types

enum ChallengeType: String, Codable {
    case technique      // Master a specific technique
    case category       // Complete templates in a category
    case timed          // Complete within time limit
    case collaborative  // Community goal
    case themed         // Follow a creative theme
    case vs             // Head-to-head competition
}

enum ChallengeDuration: String, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case custom = "Custom"
}

enum ChallengeStatus: String, Codable {
    case upcoming = "Upcoming"
    case active = "Active"
    case ended = "Ended"
    case judging = "Judging"
    case completed = "Completed"
}

// MARK: - Challenge Requirements

struct ChallengeRequirements: Codable {
    var minWorks: Int = 1
    var maxWorks: Int = 1
    var minTime: Int?               // Minimum minutes per work
    var maxTime: Int?               // Maximum minutes per work
    var requiredTools: [DrawingTool]?
    var requiredTechniques: [PatternTechnique]?
    var colorPalette: [String]?     // Required hex colors
    var maxUndos: Int?              // Maximum undo count
    var mustCompleteInOrder: Bool = false

    var description: String {
        var parts: [String] = []

        if minWorks > 1 {
            parts.append("Complete \(minWorks) works")
        }

        if let minTime = minTime {
            parts.append("At least \(minTime) min per work")
        }

        if let maxTime = maxTime {
            parts.append("Complete within \(maxTime) min")
        }

        if let tools = requiredTools, !tools.isEmpty {
            let toolNames = tools.map { $0.displayName }.joined(separator: ", ")
            parts.append("Use: \(toolNames)")
        }

        if let techniques = requiredTechniques, !techniques.isEmpty {
            let techniqueNames = techniques.map { $0.rawValue }.joined(separator: ", ")
            parts.append("Techniques: \(techniqueNames)")
        }

        if let maxUndos = maxUndos {
            parts.append("Max \(maxUndos) undos")
        }

        return parts.joined(separator: " • ")
    }
}

// MARK: - Challenge Rewards

struct ChallengeRewards: Codable {
    var points: Int
    var badge: Badge?
    var title: String?
    var templateUnlocks: [UUID]?
    var premiumDays: Int?           // Days of premium access

    struct Badge: Codable {
        var name: String
        var icon: String
        var rarity: Rarity

        enum Rarity: String, Codable {
            case common = "Common"
            case rare = "Rare"
            case epic = "Epic"
            case legendary = "Legendary"

            var color: String {
                switch self {
                case .common: return "#8E8E93"
                case .rare: return "#007AFF"
                case .epic: return "#AF52DE"
                case .legendary: return "#FF9500"
                }
            }
        }
    }
}

// MARK: - Challenge Submission

/// User submission to a challenge
struct ChallengeSubmission: Codable, Identifiable {
    let id: UUID
    let challengeID: UUID
    let userID: String
    var username: String
    var avatarURL: String?

    // Artwork
    var artworkID: UUID
    var thumbnailURL: String
    var imageURL: String

    // Metadata
    var drawingTime: Int
    var tools: [DrawingTool]
    var technique: PatternTechnique

    // Engagement
    var votes: Int = 0
    var views: Int = 0
    var comments: Int = 0

    // Status
    var isQualified: Bool = true
    var disqualificationReason: String?
    var rank: Int?                  // Final ranking

    // Dates
    var submittedAt: Date
    var lastUpdatedAt: Date

    init(
        id: UUID = UUID(),
        challengeID: UUID,
        userID: String,
        username: String,
        avatarURL: String? = nil,
        artworkID: UUID,
        thumbnailURL: String,
        imageURL: String,
        drawingTime: Int,
        tools: [DrawingTool],
        technique: PatternTechnique
    ) {
        self.id = id
        self.challengeID = challengeID
        self.userID = userID
        self.username = username
        self.avatarURL = avatarURL
        self.artworkID = artworkID
        self.thumbnailURL = thumbnailURL
        self.imageURL = imageURL
        self.drawingTime = drawingTime
        self.tools = tools
        self.technique = technique
        self.submittedAt = Date()
        self.lastUpdatedAt = Date()
    }
}

// MARK: - Challenge Vote

/// Vote on a challenge submission
struct ChallengeVote: Codable, Identifiable {
    let id: UUID
    let submissionID: UUID
    let userID: String
    let createdAt: Date

    init(id: UUID = UUID(), submissionID: UUID, userID: String) {
        self.id = id
        self.submissionID = submissionID
        self.userID = userID
        self.createdAt = Date()
    }
}

// MARK: - Challenge Participation

/// Tracks user participation in a challenge
struct ChallengeParticipation: Codable, Identifiable {
    let id: UUID
    let challengeID: UUID
    let userID: String

    var isCompleted: Bool = false
    var progress: Float = 0.0       // 0.0 to 1.0
    var worksCompleted: Int = 0

    var joinedAt: Date
    var completedAt: Date?

    init(id: UUID = UUID(), challengeID: UUID, userID: String) {
        self.id = id
        self.challengeID = challengeID
        self.userID = userID
        self.joinedAt = Date()
    }

    mutating func updateProgress(worksCompleted: Int, required: Int) {
        self.worksCompleted = worksCompleted
        self.progress = Float(worksCompleted) / Float(required)

        if worksCompleted >= required {
            self.isCompleted = true
            self.completedAt = Date()
        }
    }
}

// MARK: - Challenge Leaderboard

/// Leaderboard entry for a challenge
struct ChallengeLeaderboardEntry: Codable, Identifiable {
    let id: UUID
    let challengeID: UUID
    let userID: String
    var username: String
    var avatarURL: String?

    var rank: Int
    var score: Int
    var submissionID: UUID?
    var thumbnailURL: String?

    var badge: ChallengeRewards.Badge?
    var reward: String?
}
