//
//  UserProfile.swift
//  Ink - Pattern Drawing App
//
//  User profile model for community features
//  Created on November 11, 2025.
//

import Foundation

/// Represents a user in the Ink community
struct UserProfile: Codable, Identifiable {
    let id: String              // Firebase UID
    var username: String
    var displayName: String
    var bio: String?
    var avatarURL: String?

    // Statistics
    var totalWorks: Int = 0
    var totalLikes: Int = 0
    var totalFollowers: Int = 0
    var totalFollowing: Int = 0
    var level: Int = 0

    // Achievements
    var unlockedAchievementIDs: [UUID] = []
    var selectedTitle: String?

    // Dates
    var joinDate: Date
    var lastActiveDate: Date

    // Preferences
    var isPublic: Bool = true
    var allowComments: Bool = true
    var allowFollows: Bool = true

    // Social links
    var instagramHandle: String?
    var twitterHandle: String?
    var websiteURL: String?

    init(
        id: String,
        username: String,
        displayName: String,
        bio: String? = nil,
        avatarURL: String? = nil,
        joinDate: Date = Date()
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.bio = bio
        self.avatarURL = avatarURL
        self.joinDate = joinDate
        self.lastActiveDate = Date()
    }

    /// Check if username is valid
    static func isValidUsername(_ username: String) -> Bool {
        // 3-20 characters, alphanumeric and underscores only
        let regex = "^[a-zA-Z0-9_]{3,20}$"
        return username.range(of: regex, options: .regularExpression) != nil
    }
}

// MARK: - Gallery Artwork

/// Represents an artwork shared to the community gallery
struct GalleryArtwork: Codable, Identifiable {
    let id: UUID
    let userID: String
    var title: String
    var description: String?

    // Template info
    var templateID: UUID
    var templateName: String
    var category: Template.Category
    var difficulty: Template.Difficulty
    var technique: PatternTechnique

    // Artwork data
    var imageURL: String            // Main artwork image
    var thumbnailURL: String        // Smaller thumbnail for gallery
    var timelapseURL: String?       // Optional time-lapse video

    // Metadata
    var drawingTime: Int            // Minutes spent drawing
    var strokeCount: Int            // Total strokes
    var tools: [DrawingTool]        // Tools used
    var colors: [String]            // Hex color codes used

    // Engagement
    var views: Int = 0
    var likes: Int = 0
    var comments: Int = 0
    var shares: Int = 0

    // Dates
    var createdAt: Date
    var updatedAt: Date

    // Visibility
    var isPublic: Bool = true
    var isFeatured: Bool = false
    var tags: [String] = []

    init(
        id: UUID = UUID(),
        userID: String,
        title: String,
        description: String? = nil,
        templateID: UUID,
        templateName: String,
        category: Template.Category,
        difficulty: Template.Difficulty,
        technique: PatternTechnique,
        imageURL: String,
        thumbnailURL: String,
        timelapseURL: String? = nil,
        drawingTime: Int,
        strokeCount: Int,
        tools: [DrawingTool],
        colors: [String]
    ) {
        self.id = id
        self.userID = userID
        self.title = title
        self.description = description
        self.templateID = templateID
        self.templateName = templateName
        self.category = category
        self.difficulty = difficulty
        self.technique = technique
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
        self.timelapseURL = timelapseURL
        self.drawingTime = drawingTime
        self.strokeCount = strokeCount
        self.tools = tools
        self.colors = colors
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Social Interactions

/// Like on an artwork
struct ArtworkLike: Codable, Identifiable {
    let id: UUID
    let artworkID: UUID
    let userID: String
    let createdAt: Date

    init(id: UUID = UUID(), artworkID: UUID, userID: String) {
        self.id = id
        self.artworkID = artworkID
        self.userID = userID
        self.createdAt = Date()
    }
}

/// Comment on an artwork
struct ArtworkComment: Codable, Identifiable {
    let id: UUID
    let artworkID: UUID
    let userID: String
    var username: String
    var avatarURL: String?
    var text: String
    var likes: Int = 0
    let createdAt: Date
    var updatedAt: Date
    var isEdited: Bool = false

    init(
        id: UUID = UUID(),
        artworkID: UUID,
        userID: String,
        username: String,
        avatarURL: String? = nil,
        text: String
    ) {
        self.id = id
        self.artworkID = artworkID
        self.userID = userID
        self.username = username
        self.avatarURL = avatarURL
        self.text = text
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// User follow relationship
struct UserFollow: Codable, Identifiable {
    let id: UUID
    let followerID: String      // User who is following
    let followingID: String     // User being followed
    let createdAt: Date

    init(id: UUID = UUID(), followerID: String, followingID: String) {
        self.id = id
        self.followerID = followerID
        self.followingID = followingID
        self.createdAt = Date()
    }
}

// MARK: - Gallery Filters

/// Filters for browsing gallery
struct GalleryFilter {
    var category: Template.Category?
    var difficulty: Template.Difficulty?
    var technique: PatternTechnique?
    var sortBy: SortOption = .recent
    var timeRange: TimeRange = .allTime
    var searchQuery: String?

    enum SortOption: String, CaseIterable {
        case recent = "Recent"
        case popular = "Popular"
        case trending = "Trending"
        case mostLiked = "Most Liked"
        case mostViewed = "Most Viewed"
    }

    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case allTime = "All Time"
    }
}

// MARK: - Notification Types

/// User notification
struct UserNotification: Codable, Identifiable {
    let id: UUID
    let userID: String
    var type: NotificationType
    var title: String
    var message: String
    var actionURL: String?      // Deep link to relevant content
    var thumbnailURL: String?
    var isRead: Bool = false
    let createdAt: Date

    enum NotificationType: String, Codable {
        case like = "like"
        case comment = "comment"
        case follow = "follow"
        case achievement = "achievement"
        case challenge = "challenge"
        case featured = "featured"
        case system = "system"
    }

    init(
        id: UUID = UUID(),
        userID: String,
        type: NotificationType,
        title: String,
        message: String,
        actionURL: String? = nil,
        thumbnailURL: String? = nil
    ) {
        self.id = id
        self.userID = userID
        self.type = type
        self.title = title
        self.message = message
        self.actionURL = actionURL
        self.thumbnailURL = thumbnailURL
        self.createdAt = Date()
    }
}
