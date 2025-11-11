//
//  AchievementManager.swift
//  Ink - Pattern Drawing App
//
//  Manages achievement tracking, progress, and unlocking
//  Created on November 11, 2025.
//

import Foundation

// MARK: - User Action

/// Actions that can trigger achievement progress
enum UserAction {
    case completedWork(template: Template, technique: PatternTechnique, drawingMinutes: Int, undoCount: Int)
    case sharedWork
    case receivedGalleryView
    case receivedLike
    case completedChallenge
    case openedApp
}

// MARK: - Achievement Manager

class AchievementManager {

    // MARK: - Properties

    private let userDefaults = UserDefaults.standard
    private let progressKey = "user_achievement_progress"
    private var achievements: [Achievement]
    private var progress: UserAchievementProgress

    // Callbacks
    var onAchievementUnlocked: ((Achievement) -> Void)?
    var onProgressUpdated: ((Achievement, Float) -> Void)?

    // MARK: - Initialization

    init() {
        self.achievements = Achievement.standardAchievements()
        self.progress = Self.loadProgress() ?? UserAchievementProgress()
    }

    // MARK: - Progress Tracking

    /// Record a user action and check for achievement progress
    func recordAction(_ action: UserAction) {
        switch action {
        case .completedWork(let template, let technique, let drawingMinutes, let undoCount):
            handleCompletedWork(template: template, technique: technique, drawingMinutes: drawingMinutes, undoCount: undoCount)

        case .sharedWork:
            progress.totalShares += 1

        case .receivedGalleryView:
            progress.totalGalleryViews += 1

        case .receivedLike:
            progress.totalLikesReceived += 1

        case .completedChallenge:
            progress.completedChallenges += 1

        case .openedApp:
            // Used for streak tracking (handled by DailyContentManager)
            break
        }

        // Check all achievements for progress
        checkAchievements()

        // Save progress
        saveProgress()
    }

    /// Handle completed work with detailed stats
    private func handleCompletedWork(template: Template, technique: PatternTechnique, drawingMinutes: Int, undoCount: Int) {
        // Update general stats
        progress.totalCompletedWorks += 1
        progress.totalDrawingMinutes += drawingMinutes

        // Update technique stats
        progress.techniqueStats[technique, default: 0] += 1

        // Update category stats
        progress.categoryStats[template.category, default: 0] += 1

        // Update difficulty stats
        progress.difficultyStats[template.difficulty, default: 0] += 1
    }

    /// Check all achievements and update progress
    private func checkAchievements() {
        for achievement in achievements {
            // Skip already unlocked
            if progress.unlockedAchievements.contains(achievement.id) {
                continue
            }

            let (progress, isUnlocked) = calculateProgress(for: achievement)

            // Update progress
            self.progress.achievementProgress[achievement.id] = progress

            // Notify progress update
            onProgressUpdated?(achievement, progress)

            // Check if unlocked
            if isUnlocked {
                unlockAchievement(achievement)
            }
        }
    }

    /// Calculate progress for a specific achievement
    private func calculateProgress(for achievement: Achievement) -> (progress: Float, isUnlocked: Bool) {
        switch achievement.requirement {
        // Technique-based
        case .completeTechniqueWorks(let technique, let count):
            let current = progress.techniqueStats[technique, default: 0]
            let progress = min(1.0, Float(current) / Float(count))
            return (progress, current >= count)

        case .useMixedTechniques(let techniqueCount, let workCount):
            let uniqueTechniques = progress.techniqueStats.count
            if uniqueTechniques >= techniqueCount {
                let totalWorks = progress.totalCompletedWorks
                let progress = min(1.0, Float(totalWorks) / Float(workCount))
                return (progress, totalWorks >= workCount)
            }
            return (Float(uniqueTechniques) / Float(techniqueCount) * 0.5, false)

        case .masterPrecision(let undoLimit, let workCount):
            // This requires tracking per-work undo counts (future enhancement)
            // For now, estimate based on total works
            let estimated = progress.totalCompletedWorks
            let progress = min(1.0, Float(estimated) / Float(workCount))
            return (progress, estimated >= workCount)

        // Collection-based
        case .completeCategory(let category):
            let completed = progress.categoryStats[category, default: 0]
            // Assume 10 templates per category for progress calculation
            let progress = min(1.0, Float(completed) / 10.0)
            return (progress, completed >= 10)

        case .completeDifficulty(let difficulty):
            let completed = progress.difficultyStats[difficulty, default: 0]
            // Dynamic check based on actual template count (would need template manager reference)
            // For now, use fixed numbers
            let required: Int
            switch difficulty {
            case .beginner: required = 10
            case .intermediate: required = 15
            case .advanced: required = 10
            }
            let progress = min(1.0, Float(completed) / Float(required))
            return (progress, completed >= required)

        case .completeTemplates(let count):
            let current = progress.totalCompletedWorks
            let progress = min(1.0, Float(current) / Float(count))
            return (progress, current >= count)

        // Time-based
        case .totalDrawingTime(let minutes):
            let current = progress.totalDrawingMinutes
            let progress = min(1.0, Float(current) / Float(minutes))
            return (progress, current >= minutes)

        case .completeQuickWork(let minutes):
            // Requires per-work time tracking (future enhancement)
            return (0.0, false)

        case .completeLongWork(let minutes):
            // Requires per-work time tracking (future enhancement)
            return (0.0, false)

        // Streak-based (requires DailyContentManager)
        case .dailyStreak(let days):
            // This should be checked with DailyContentManager
            // For now, return 0
            return (0.0, false)

        case .totalActiveDays(let days):
            // This should be checked with DailyContentManager
            return (0.0, false)

        // Social-based
        case .shareWorks(let count):
            let current = progress.totalShares
            let progress = min(1.0, Float(current) / Float(count))
            return (progress, current >= count)

        case .galleryViews(let count):
            let current = progress.totalGalleryViews
            let progress = min(1.0, Float(current) / Float(count))
            return (progress, current >= count)

        case .receiveLikes(let count):
            let current = progress.totalLikesReceived
            let progress = min(1.0, Float(current) / Float(count))
            return (progress, current >= count)

        // Special
        case .completeChallenge(let count):
            let current = progress.completedChallenges
            let progress = min(1.0, Float(current) / Float(count))
            return (progress, current >= count)

        case .reachLevel(let level):
            let currentLevel = progress.level
            let progress = min(1.0, Float(currentLevel) / Float(level))
            return (progress, currentLevel >= level)
        }
    }

    /// Unlock an achievement
    func unlockAchievement(_ achievement: Achievement) {
        // Mark as unlocked
        progress.unlockedAchievements.insert(achievement.id)

        // Add points
        progress.totalPoints += achievement.points

        // Add title if any
        if let title = achievement.reward?.title {
            progress.unlockedTitles.append(title)
        }

        // Save progress
        saveProgress()

        // Notify
        onAchievementUnlocked?(achievement)

        print("🏆 Achievement Unlocked: \(achievement.title) (+\(achievement.points) pts)")
    }

    // MARK: - Queries

    /// Get all achievements
    func getAllAchievements() -> [Achievement] {
        return achievements
    }

    /// Get unlocked achievements
    func getUnlockedAchievements() -> [Achievement] {
        return achievements.filter { progress.unlockedAchievements.contains($0.id) }
    }

    /// Get locked achievements
    func getLockedAchievements() -> [Achievement] {
        return achievements.filter { !progress.unlockedAchievements.contains($0.id) }
    }

    /// Get achievements by category
    func getAchievements(in category: AchievementCategory) -> [Achievement] {
        return achievements.filter { $0.category == category }
    }

    /// Get progress for specific achievement
    func getProgress(for achievement: Achievement) -> Float {
        return progress.achievementProgress[achievement.id] ?? 0.0
    }

    /// Check if achievement is unlocked
    func isUnlocked(_ achievement: Achievement) -> Bool {
        return progress.unlockedAchievements.contains(achievement.id)
    }

    /// Get user progress
    func getUserProgress() -> UserAchievementProgress {
        return progress
    }

    /// Get recently unlocked achievements (last 5)
    func getRecentlyUnlocked(limit: Int = 5) -> [Achievement] {
        let unlocked = getUnlockedAchievements()
        // Sort by points (proxy for unlock order)
        return Array(unlocked.suffix(limit))
    }

    // MARK: - Persistence

    /// Save progress to UserDefaults
    private func saveProgress() {
        if let data = try? JSONEncoder().encode(progress) {
            userDefaults.set(data, forKey: progressKey)
        }
    }

    /// Load progress from UserDefaults
    private static func loadProgress() -> UserAchievementProgress? {
        guard let data = UserDefaults.standard.data(forKey: "user_achievement_progress"),
              let progress = try? JSONDecoder().decode(UserAchievementProgress.self, from: data) else {
            return nil
        }
        return progress
    }

    /// Reset progress (for testing)
    func resetProgress() {
        progress = UserAchievementProgress()
        saveProgress()
    }

    // MARK: - Statistics

    /// Get achievement statistics
    func getStatistics() -> [String: Any] {
        let total = achievements.count
        let unlocked = progress.unlockedAchievements.count
        let percentage = total > 0 ? Float(unlocked) / Float(total) * 100 : 0

        return [
            "totalAchievements": total,
            "unlockedAchievements": unlocked,
            "completionPercentage": percentage,
            "totalPoints": progress.totalPoints,
            "currentLevel": progress.level,
            "levelProgress": progress.levelProgress,
            "unlockedTitles": progress.unlockedTitles
        ]
    }

    // MARK: - Integration with Streak

    /// Update streak-based achievements (called by DailyContentManager)
    func updateStreakAchievements(currentStreak: Int, totalActiveDays: Int) {
        // Check streak achievements
        for achievement in achievements where achievement.category == .streak {
            if progress.unlockedAchievements.contains(achievement.id) {
                continue
            }

            switch achievement.requirement {
            case .dailyStreak(let days):
                if currentStreak >= days {
                    unlockAchievement(achievement)
                } else {
                    let progress = min(1.0, Float(currentStreak) / Float(days))
                    self.progress.achievementProgress[achievement.id] = progress
                    onProgressUpdated?(achievement, progress)
                }

            case .totalActiveDays(let days):
                if totalActiveDays >= days {
                    unlockAchievement(achievement)
                } else {
                    let progress = min(1.0, Float(totalActiveDays) / Float(days))
                    self.progress.achievementProgress[achievement.id] = progress
                    onProgressUpdated?(achievement, progress)
                }

            default:
                break
            }
        }

        saveProgress()
    }
}
