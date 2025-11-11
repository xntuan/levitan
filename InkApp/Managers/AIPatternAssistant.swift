//
//  AIPatternAssistant.swift
//  Ink - Pattern Drawing App
//
//  AI-powered pattern suggestions and drawing assistance
//  Created on November 11, 2025.
//

import Foundation
import CoreGraphics
import Metal

/// AI assistant for pattern drawing suggestions and analysis
class AIPatternAssistant {

    // MARK: - Properties

    static let shared = AIPatternAssistant()

    // AI Configuration
    var isEnabled: Bool = true
    var suggestionFrequency: SuggestionFrequency = .moderate

    // Callbacks
    var onSuggestionAvailable: ((PatternSuggestion) -> Void)?
    var onAnalysisComplete: ((ArtworkAnalysis) -> Void)?

    // Analysis cache
    private var recentSuggestions: [PatternSuggestion] = []
    private var analysisHistory: [UUID: ArtworkAnalysis] = [:]

    private init() {}

    // MARK: - Context-Aware Suggestions

    /// Analyze current artwork and suggest next patterns
    func suggestNextPattern(
        currentTechnique: PatternTechnique,
        recentTools: [DrawingTool],
        drawingTime: Int,
        strokeCount: Int,
        density: Float,
        templateCategory: Template.Category?
    ) -> PatternSuggestion {

        // AI logic: Analyze context and suggest complementary patterns
        var suggestions: [PatternRecommendation] = []

        // Rule 1: Complement current technique
        let complementaryTechniques = getComplementaryTechniques(for: currentTechnique)
        for technique in complementaryTechniques {
            suggestions.append(PatternRecommendation(
                technique: technique,
                reason: "Works well with \(currentTechnique.rawValue)",
                confidence: 0.85
            ))
        }

        // Rule 2: Suggest based on density
        if density < 0.3 {
            suggestions.append(PatternRecommendation(
                technique: .stippling,
                reason: "Add detail with stippling in light areas",
                confidence: 0.75
            ))
        } else if density > 0.7 {
            suggestions.append(PatternRecommendation(
                technique: .crossHatching,
                reason: "Enhance shadows with cross-hatching",
                confidence: 0.80
            ))
        }

        // Rule 3: Template category hints
        if let category = templateCategory {
            let categoryTechniques = getRecommendedTechniques(for: category)
            for technique in categoryTechniques {
                suggestions.append(PatternRecommendation(
                    technique: technique,
                    reason: "Popular for \(category.rawValue.lowercased()) subjects",
                    confidence: 0.70
                ))
            }
        }

        // Rule 4: Time-based suggestions
        if drawingTime > 30 && strokeCount < 100 {
            suggestions.append(PatternRecommendation(
                technique: .stippling,
                reason: "Take your time - stippling rewards patience",
                confidence: 0.65
            ))
        }

        // Sort by confidence and take top 3
        let topSuggestions = suggestions
            .sorted { $0.confidence > $1.confidence }
            .prefix(3)
            .map { $0 }

        let suggestion = PatternSuggestion(
            id: UUID(),
            recommendations: topSuggestions,
            context: SuggestionContext(
                currentTechnique: currentTechnique,
                density: density,
                category: templateCategory
            ),
            timestamp: Date()
        )

        recentSuggestions.append(suggestion)
        onSuggestionAvailable?(suggestion)

        return suggestion
    }

    /// Get technique tips for current situation
    func getTechniqueGuidance(
        technique: PatternTechnique,
        skill: SkillLevel = .intermediate
    ) -> TechniqueGuidance {

        switch technique {
        case .stippling:
            return TechniqueGuidance(
                technique: technique,
                tips: [
                    "🎯 Vary dot density for shading",
                    "⚫ Smaller dots = lighter areas",
                    "⏱️ Be patient - stippling takes time",
                    "🔄 Rotate as you work for natural randomness"
                ],
                commonMistakes: [
                    "Dots too uniform - vary spacing",
                    "Working too fast - slow down",
                    "Not enough density variation"
                ],
                suggestedSettings: BrushSettings(
                    density: 0.4,
                    spacing: 8.0,
                    scale: 0.8,
                    opacity: 0.9
                )
            )

        case .hatching:
            return TechniqueGuidance(
                technique: technique,
                tips: [
                    "📏 Keep lines parallel and consistent",
                    "↗️ Angle affects the mood (45° is balanced)",
                    "📊 Closer lines = darker values",
                    "🎨 Follow form contours for realism"
                ],
                commonMistakes: [
                    "Lines not parallel enough",
                    "Inconsistent spacing",
                    "Ignoring object form"
                ],
                suggestedSettings: BrushSettings(
                    density: 0.5,
                    spacing: 10.0,
                    scale: 1.0,
                    opacity: 0.8
                )
            )

        case .crossHatching:
            return TechniqueGuidance(
                technique: technique,
                tips: [
                    "✖️ Layer perpendicular lines gradually",
                    "🌗 Build darkness layer by layer",
                    "📐 Common angles: 45° and 135°",
                    "⚡ More layers = richer shadows"
                ],
                commonMistakes: [
                    "Too many layers too quickly",
                    "Inconsistent angles",
                    "Not varying line density"
                ],
                suggestedSettings: BrushSettings(
                    density: 0.6,
                    spacing: 12.0,
                    scale: 1.0,
                    opacity: 0.7
                )
            )

        case .contourHatching:
            return TechniqueGuidance(
                technique: technique,
                tips: [
                    "🌊 Follow the form's curves",
                    "🎭 Reveals volume and dimension",
                    "🔄 Lines should wrap around surfaces",
                    "📏 Spacing controls shading intensity"
                ],
                commonMistakes: [
                    "Lines don't follow form",
                    "Inconsistent curvature",
                    "Too rigid - needs flow"
                ],
                suggestedSettings: BrushSettings(
                    density: 0.5,
                    spacing: 10.0,
                    scale: 1.2,
                    opacity: 0.75
                )
            )

        case .waves:
            return TechniqueGuidance(
                technique: technique,
                tips: [
                    "〰️ Smooth, flowing waves work best",
                    "🌊 Great for water and organic textures",
                    "📊 Vary amplitude for natural look",
                    "🎵 Keep rhythm consistent"
                ],
                commonMistakes: [
                    "Waves too regular/mechanical",
                    "Inconsistent wave height",
                    "Not enough variation"
                ],
                suggestedSettings: BrushSettings(
                    density: 0.4,
                    spacing: 15.0,
                    scale: 1.0,
                    opacity: 0.65
                )
            )

        case .mixed:
            return TechniqueGuidance(
                technique: technique,
                tips: [
                    "🎨 Combine 2-3 techniques maximum",
                    "⚖️ Balance is key - don't overdo it",
                    "🎯 Use different techniques for different areas",
                    "✨ Mixing creates unique style"
                ],
                commonMistakes: [
                    "Too many techniques at once",
                    "No coherent approach",
                    "Techniques fighting each other"
                ],
                suggestedSettings: BrushSettings(
                    density: 0.5,
                    spacing: 10.0,
                    scale: 1.0,
                    opacity: 0.8
                )
            )
        }
    }

    // MARK: - Artwork Analysis

    /// Analyze completed artwork
    func analyzeArtwork(
        texture: MTLTexture,
        template: Template,
        drawingTime: Int,
        strokeCount: Int,
        tools: [DrawingTool],
        techniques: [PatternTechnique]
    ) -> ArtworkAnalysis {

        // Analyze texture for pattern density, coverage, etc.
        let coverageAnalysis = analyzeCoverage(texture: texture)
        let densityAnalysis = analyzeDensityDistribution(texture: texture)

        // Calculate skill metrics
        let efficiency = calculateEfficiency(
            drawingTime: drawingTime,
            strokeCount: strokeCount,
            coverage: coverageAnalysis.percentage
        )

        let techniqueScore = calculateTechniqueScore(
            techniques: techniques,
            difficulty: template.difficulty
        )

        // Generate feedback
        let strengths = identifyStrengths(
            coverage: coverageAnalysis,
            density: densityAnalysis,
            efficiency: efficiency
        )

        let improvements = identifyImprovements(
            coverage: coverageAnalysis,
            density: densityAnalysis,
            techniques: techniques
        )

        let analysis = ArtworkAnalysis(
            id: UUID(),
            templateID: template.id,
            coveragePercentage: coverageAnalysis.percentage,
            averageDensity: densityAnalysis.average,
            densityVariation: densityAnalysis.variation,
            drawingTime: drawingTime,
            strokeCount: strokeCount,
            efficiency: efficiency,
            techniqueScore: techniqueScore,
            overallScore: calculateOverallScore(efficiency: efficiency, technique: techniqueScore),
            strengths: strengths,
            improvements: improvements,
            estimatedSkillLevel: estimateSkillLevel(score: techniqueScore),
            timestamp: Date()
        )

        analysisHistory[template.id] = analysis
        onAnalysisComplete?(analysis)

        return analysis
    }

    // MARK: - Smart Tool Selection

    /// Suggest best tool for current task
    func suggestTool(
        for region: DrawingRegion,
        desiredEffect: DrawingEffect
    ) -> ToolSuggestion {

        switch desiredEffect {
        case .fill:
            return ToolSuggestion(
                tool: .fillBucket,
                reason: "Quick fill for large areas",
                settings: nil
            )

        case .detail:
            return ToolSuggestion(
                tool: .pattern,
                reason: "Pattern brush for detailed work",
                settings: BrushSettings(density: 0.7, spacing: 8.0, scale: 0.8, opacity: 1.0)
            )

        case .shading:
            return ToolSuggestion(
                tool: .pattern,
                reason: "Vary density for realistic shading",
                settings: BrushSettings(density: 0.5, spacing: 10.0, scale: 1.0, opacity: 0.8)
            )

        case .smoothBlend:
            return ToolSuggestion(
                tool: .marker,
                reason: "Marker for smooth gradients",
                settings: BrushSettings(density: 0.3, spacing: 5.0, scale: 1.5, opacity: 0.4)
            )

        case .texture:
            return ToolSuggestion(
                tool: .pattern,
                reason: "Patterns create interesting textures",
                settings: BrushSettings(density: 0.6, spacing: 12.0, scale: 1.2, opacity: 0.9)
            )
        }
    }

    // MARK: - Helper Methods

    private func getComplementaryTechniques(for technique: PatternTechnique) -> [PatternTechnique] {
        switch technique {
        case .stippling:
            return [.hatching, .contourHatching]
        case .hatching:
            return [.crossHatching, .stippling]
        case .crossHatching:
            return [.hatching, .contourHatching]
        case .contourHatching:
            return [.hatching, .stippling]
        case .waves:
            return [.stippling, .hatching]
        case .mixed:
            return [.stippling, .hatching, .crossHatching]
        }
    }

    private func getRecommendedTechniques(for category: Template.Category) -> [PatternTechnique] {
        switch category {
        case .nature:
            return [.contourHatching, .stippling, .waves]
        case .animals:
            return [.hatching, .stippling, .contourHatching]
        case .geometric:
            return [.crossHatching, .hatching]
        case .abstract:
            return [.mixed, .waves, .stippling]
        case .mandalas:
            return [.stippling, .hatching, .crossHatching]
        case .flowers:
            return [.contourHatching, .stippling]
        }
    }

    private func analyzeCoverage(texture: MTLTexture) -> CoverageAnalysis {
        // Mock analysis - in production, read texture pixels
        return CoverageAnalysis(percentage: 0.75, uncoveredRegions: [])
    }

    private func analyzeDensityDistribution(texture: MTLTexture) -> DensityAnalysis {
        // Mock analysis - in production, analyze pixel density
        return DensityAnalysis(average: 0.5, variation: 0.3, histogram: [])
    }

    private func calculateEfficiency(drawingTime: Int, strokeCount: Int, coverage: Float) -> Float {
        // Efficiency = coverage per minute
        let timeInMinutes = Float(drawingTime)
        return coverage / max(1.0, timeInMinutes)
    }

    private func calculateTechniqueScore(techniques: [PatternTechnique], difficulty: Template.Difficulty) -> Float {
        let techniqueCount = Float(techniques.count)
        let difficultyMultiplier: Float = {
            switch difficulty {
            case .beginner: return 0.7
            case .intermediate: return 1.0
            case .advanced: return 1.3
            case .expert: return 1.6
            }
        }()

        return min(1.0, (techniqueCount / 3.0) * difficultyMultiplier)
    }

    private func calculateOverallScore(efficiency: Float, technique: Float) -> Float {
        return (efficiency * 0.4 + technique * 0.6)
    }

    private func identifyStrengths(coverage: CoverageAnalysis, density: DensityAnalysis, efficiency: Float) -> [String] {
        var strengths: [String] = []

        if coverage.percentage > 0.9 {
            strengths.append("✅ Excellent coverage - very thorough")
        }

        if density.variation > 0.25 {
            strengths.append("✅ Great density variation - nice shading")
        }

        if efficiency > 0.05 {
            strengths.append("✅ Good efficiency - steady progress")
        }

        if strengths.isEmpty {
            strengths.append("✅ Completed the artwork")
        }

        return strengths
    }

    private func identifyImprovements(coverage: CoverageAnalysis, density: DensityAnalysis, techniques: [PatternTechnique]) -> [String] {
        var improvements: [String] = []

        if coverage.percentage < 0.7 {
            improvements.append("💡 Try to cover more of the template")
        }

        if density.variation < 0.15 {
            improvements.append("💡 Vary density more for better depth")
        }

        if techniques.count == 1 {
            improvements.append("💡 Mix techniques for more interesting results")
        }

        return improvements
    }

    private func estimateSkillLevel(score: Float) -> SkillLevel {
        switch score {
        case 0..<0.3: return .beginner
        case 0.3..<0.6: return .intermediate
        case 0.6..<0.85: return .advanced
        default: return .expert
        }
    }
}

// MARK: - Supporting Types

struct PatternSuggestion: Identifiable {
    let id: UUID
    let recommendations: [PatternRecommendation]
    let context: SuggestionContext
    let timestamp: Date
}

struct PatternRecommendation {
    let technique: PatternTechnique
    let reason: String
    let confidence: Float  // 0.0 to 1.0
}

struct SuggestionContext {
    let currentTechnique: PatternTechnique
    let density: Float
    let category: Template.Category?
}

struct TechniqueGuidance {
    let technique: PatternTechnique
    let tips: [String]
    let commonMistakes: [String]
    let suggestedSettings: BrushSettings
}

struct BrushSettings {
    let density: Float
    let spacing: Float
    let scale: Float
    let opacity: Float
}

struct ArtworkAnalysis: Identifiable {
    let id: UUID
    let templateID: UUID
    let coveragePercentage: Float
    let averageDensity: Float
    let densityVariation: Float
    let drawingTime: Int
    let strokeCount: Int
    let efficiency: Float
    let techniqueScore: Float
    let overallScore: Float
    let strengths: [String]
    let improvements: [String]
    let estimatedSkillLevel: SkillLevel
    let timestamp: Date

    var grade: String {
        switch overallScore {
        case 0.9...: return "A+"
        case 0.8..<0.9: return "A"
        case 0.7..<0.8: return "B+"
        case 0.6..<0.7: return "B"
        case 0.5..<0.6: return "C+"
        case 0.4..<0.5: return "C"
        default: return "D"
        }
    }
}

struct CoverageAnalysis {
    let percentage: Float
    let uncoveredRegions: [CGRect]
}

struct DensityAnalysis {
    let average: Float
    let variation: Float
    let histogram: [Int]
}

struct ToolSuggestion {
    let tool: DrawingTool
    let reason: String
    let settings: BrushSettings?
}

enum SkillLevel: String, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
}

enum SuggestionFrequency {
    case minimal
    case moderate
    case frequent
}

enum DrawingRegion {
    case background
    case foreground
    case detail
    case shadow
    case highlight
}

enum DrawingEffect {
    case fill
    case detail
    case shading
    case smoothBlend
    case texture
}
