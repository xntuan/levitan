//
//  AppConfiguration.swift
//  Ink - Pattern Drawing App
//
//  Central configuration for app appearance and content
//  Created on November 10, 2025.
//

import UIKit

/// App-wide configuration (managed by admin)
struct AppConfiguration: Codable {

    // MARK: - Visual Configuration

    /// Primary brand color
    var primaryColor: String = "667eea"

    /// Accent color
    var accentColor: String = "764ba2"

    /// Gallery gradient colors
    var galleryGradientStart: String = "a8edea"
    var galleryGradientEnd: String = "fed6e3"

    // MARK: - Content Configuration

    /// Featured theme book IDs
    var featuredThemeBookIds: [String] = []

    /// Featured template IDs (shown on gallery home)
    var featuredTemplateIds: [String] = []

    /// Welcome message
    var welcomeTitle: String = "Welcome to Ink"
    var welcomeSubtitle: String = "Pattern drawing made simple"

    // MARK: - Feature Flags

    /// Show onboarding for new users
    var showOnboarding: Bool = true

    /// Enable pro mode features
    var enableProMode: Bool = true

    /// Enable social sharing
    var enableSharing: Bool = true

    /// Enable template purchases
    var enableInAppPurchases: Bool = false

    // MARK: - Gallery Configuration

    /// Number of columns in gallery (iPhone portrait)
    var galleryColumnsPhone: Int = 1

    /// Number of columns in gallery (iPad)
    var galleryColumnsTablet: Int = 2

    /// Show template difficulty badges
    var showDifficultyBadges: Bool = true

    /// Show estimated time
    var showEstimatedTime: Bool = true

    // MARK: - Admin Metadata

    var lastUpdated: Date = Date()
    var version: String = "1.0.0"

    // MARK: - Singleton Access

    static var shared: AppConfiguration {
        get {
            return AppConfigurationManager.shared.configuration
        }
        set {
            AppConfigurationManager.shared.configuration = newValue
        }
    }
}

// MARK: - Configuration Manager

class AppConfigurationManager {

    static let shared = AppConfigurationManager()

    private let configKey = "AppConfiguration"

    var configuration: AppConfiguration {
        didSet {
            saveConfiguration()
        }
    }

    private init() {
        self.configuration = Self.loadConfiguration() ?? AppConfiguration()
    }

    /// Save configuration to UserDefaults
    private func saveConfiguration() {
        if let data = try? JSONEncoder().encode(configuration) {
            UserDefaults.standard.set(data, forKey: configKey)
            print("✅ Configuration saved")
        }
    }

    /// Load configuration from UserDefaults
    private static func loadConfiguration() -> AppConfiguration? {
        guard let data = UserDefaults.standard.data(forKey: "AppConfiguration"),
              let config = try? JSONDecoder().decode(AppConfiguration.self, from: data) else {
            return nil
        }
        return config
    }

    /// Reset to defaults
    func resetToDefaults() {
        configuration = AppConfiguration()
        print("🔄 Configuration reset to defaults")
    }

    /// Import configuration from JSON
    func importConfiguration(from jsonData: Data) throws {
        let decoder = JSONDecoder()
        let newConfig = try decoder.decode(AppConfiguration.self, from: jsonData)
        configuration = newConfig
        print("📥 Configuration imported")
    }

    /// Export configuration as JSON
    func exportConfiguration() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(configuration)
    }
}
