//
//  DailyContentManager.swift
//  Ink - Pattern Drawing App
//
//  Manages daily free content, challenges, and streak tracking
//  Created on November 11, 2025.
//

import Foundation
import UserNotifications

class DailyContentManager {

    // MARK: - Properties

    private let userDefaults = UserDefaults.standard
    private let streakKey = "user_streak_status"
    private let lastAccessKey = "last_content_access_date"
    private let dailyContentKey = "daily_content_cache"

    // Template pool for daily rotation
    private var templatePool: [Template] = []
    private var tips: [PatternTip] = PatternTip.sampleTips()

    // MARK: - Initialization

    init(templates: [Template] = []) {
        self.templatePool = templates.filter { !$0.isLocked || $0.isDaily }
        if templatePool.isEmpty {
            templatePool = Template.createSampleTemplates()
        }
    }

    // MARK: - Daily Content

    /// Get today's free content
    func todaysContent() -> DailyContent {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Check cache first
        if let cached = loadCachedContent(), calendar.isDate(cached.date, inSameDayAs: today) {
            return cached
        }

        // Generate new daily content
        let content = generateDailyContent(for: today)

        // Cache it
        cacheContent(content)

        // Update streak
        updateStreak()

        return content
    }

    /// Generate daily content for a specific date
    private func generateDailyContent(for date: Date) -> DailyContent {
        // Use date as seed for consistent daily selection
        let daysSinceEpoch = Int(date.timeIntervalSince1970 / 86400)

        // Select template (rotate through pool)
        guard !templatePool.isEmpty else {
            print("❌ No templates available for daily content")
            return createFallbackContent(for: date)
        }
        let templateIndex = daysSinceEpoch % templatePool.count
        let freeTemplate = templatePool[templateIndex]

        // Select tip
        guard !tips.isEmpty else {
            print("❌ No tips available")
            return createContentWithoutTip(for: date, template: freeTemplate)
        }
        let tipIndex = daysSinceEpoch % tips.count
        let tip = tips[tipIndex]

        // Generate challenge (30% chance)
        let challenge: DailyChallenge?
        if daysSinceEpoch % 3 == 0 {
            challenge = generateChallenge(for: date)
        } else {
            challenge = nil
        }

        // Streak bonus (extra templates if returning)
        let streakBonus = calculateStreakBonus()

        return DailyContent(
            date: date,
            freeTemplate: freeTemplate,
            challenge: challenge,
            tipOfTheDay: "\(tip.title): \(tip.content)",
            streakBonus: streakBonus
        )
    }

    /// Generate a daily challenge
    private func generateChallenge(for date: Date) -> DailyChallenge {
        let daysSinceEpoch = Int(date.timeIntervalSince1970 / 86400)

        // Select technique for the day
        let techniques = PatternTechnique.allCases
        let techniqueIndex = daysSinceEpoch % techniques.count
        let technique = techniques[techniqueIndex]

        // Select a template that works well with this technique
        let suitableTemplates = templatePool.filter { template in
            template.primaryTechnique == technique || template.difficulty == .beginner
        }

        let templateIndex = daysSinceEpoch % max(suitableTemplates.count, 1)
        let template = suitableTemplates.isEmpty ? templatePool[0] : suitableTemplates[templateIndex]

        let titles = [
            .stippling: "Master Stippling Depth",
            .hatching: "Perfect Parallel Lines",
            .crossHatching: "Cross-Hatch Mastery",
            .contourHatching: "Follow the Form",
            .mixed: "Technique Combination",
            .waves: "Organic Wave Patterns"
        ]

        let descriptions = [
            .stippling: "Create smooth gradients using only stippling dots",
            .hatching: "Use parallel hatching to show depth and form",
            .crossHatching: "Layer multiple hatching angles for rich shadows",
            .contourHatching: "Make your lines follow the contours of the subject",
            .mixed: "Combine at least 3 different pattern techniques",
            .waves: "Use wave patterns to create organic textures"
        ]

        let expiresAt = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(86400)

        return DailyChallenge(
            title: titles[technique] ?? "Daily Challenge",
            description: descriptions[technique] ?? "Complete this template using \(technique.rawValue)",
            template: template,
            requiredTechnique: technique,
            reward: ChallengeReward(points: 10, achievementId: nil, unlockTemplateId: nil),
            expiresAt: expiresAt
        )
    }

    // MARK: - Streak Management

    /// Get current streak status
    func getStreakStatus() -> StreakStatus {
        if let data = userDefaults.data(forKey: streakKey),
           let streak = try? JSONDecoder().decode(StreakStatus.self, from: data) {
            return streak
        }

        // Initialize new streak
        return StreakStatus()
    }

    /// Update streak for today's access
    func updateStreak() {
        var streak = getStreakStatus()
        streak.updateForToday()
        saveStreak(streak)
    }

    /// Save streak status
    private func saveStreak(_ streak: StreakStatus) {
        if let data = try? JSONEncoder().encode(streak) {
            userDefaults.set(data, forKey: streakKey)
        }
    }

    /// Calculate streak bonus templates
    private func calculateStreakBonus() -> Int {
        let streak = getStreakStatus()

        // Check for comeback (missed days)
        let calendar = Calendar.current
        let daysSince = calendar.dateComponents([.day], from: streak.lastActiveDate, to: Date()).day ?? 0

        if daysSince > 1 && daysSince < 7 {
            // Comeback bonus (1 extra template)
            return 1
        } else if daysSince >= 7 {
            // Long absence bonus (3 extra templates)
            return 3
        }

        // Streak milestone bonuses
        switch streak.currentStreak {
        case 7, 30, 100:
            return 2  // Milestone bonus
        default:
            return 0
        }
    }

    // MARK: - Caching

    /// Cache daily content
    private func cacheContent(_ content: DailyContent) {
        if let data = try? JSONEncoder().encode(content) {
            userDefaults.set(data, forKey: dailyContentKey)
        }
    }

    /// Load cached content
    private func loadCachedContent() -> DailyContent? {
        guard let data = userDefaults.data(forKey: dailyContentKey),
              let content = try? JSONDecoder().decode(DailyContent.self, from: data) else {
            return nil
        }
        return content
    }

    // MARK: - Notifications

    /// Schedule daily notification for new content
    func scheduleDailyNotification() {
        let center = UNUserNotificationCenter.current()

        // Request permission
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                self.createDailyNotification()
            }
        }
    }

    /// Create the notification
    private func createDailyNotification() {
        let content = UNMutableNotificationContent()
        content.title = "New Template Available! 🎨"
        content.body = "Your daily free template is ready. Keep your streak going!"
        content.sound = .default
        content.badge = 1

        // Trigger at 9 AM every day
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "dailyContentNotification",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    /// Cancel daily notification
    func cancelDailyNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyContentNotification"])
    }

    // MARK: - Template Management

    /// Update template pool
    func updateTemplatePool(_ templates: [Template]) {
        self.templatePool = templates.filter { !$0.isLocked || $0.isDaily }
    }

    /// Add new templates to pool
    func addTemplatesToPool(_ templates: [Template]) {
        let newTemplates = templates.filter { !$0.isLocked || $0.isDaily }
        templatePool.append(contentsOf: newTemplates)
    }

    // MARK: - Statistics

    /// Get statistics for analytics
    func getStatistics() -> [String: Any] {
        let streak = getStreakStatus()

        return [
            "currentStreak": streak.currentStreak,
            "longestStreak": streak.longestStreak,
            "totalActiveDays": streak.totalActiveDays,
            "lastActiveDate": streak.lastActiveDate,
            "streakFreezeAvailable": streak.streakFreezeAvailable
        ]
    }

    /// Check if user accessed content today
    func hasAccessedToday() -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastAccess = userDefaults.object(forKey: lastAccessKey) as? Date {
            return calendar.isDate(lastAccess, inSameDayAs: today)
        }

        return false
    }

    /// Mark today as accessed
    func markTodayAccessed() {
        userDefaults.set(Date(), forKey: lastAccessKey)
    }

    // MARK: - Fallback Methods

    /// Create fallback content when no templates available
    private func createFallbackContent(for date: Date) -> DailyContent {
        // Create a minimal placeholder template
        let placeholderTemplate = Template(
            id: UUID(),
            name: "Placeholder",
            category: .geometric,
            difficulty: .beginner,
            thumbnailName: "",
            svgPath: "",
            estimatedTime: 10,
            primaryTechnique: .stippling
        )

        return DailyContent(
            date: date,
            freeTemplate: placeholderTemplate,
            challenge: nil,
            tipOfTheDay: "No tips available today",
            streakBonus: StreakBonus(currentStreak: 0, bonus: 0, extraTemplates: [])
        )
    }

    /// Create content without tip
    private func createContentWithoutTip(for date: Date, template: Template) -> DailyContent {
        let daysSinceEpoch = Int(date.timeIntervalSince1970 / 86400)

        let challenge: DailyChallenge?
        if daysSinceEpoch % 3 == 0 {
            challenge = generateChallenge(for: date)
        } else {
            challenge = nil
        }

        let streakBonus = calculateStreakBonus()

        return DailyContent(
            date: date,
            freeTemplate: template,
            challenge: challenge,
            tipOfTheDay: "Keep creating amazing pattern art!",
            streakBonus: streakBonus
        )
    }
}
