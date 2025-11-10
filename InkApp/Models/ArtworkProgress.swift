//
//  ArtworkProgress.swift
//  Ink - Pattern Drawing App
//
//  Tracks completion progress for template artwork
//  Created on November 10, 2025.
//

import Foundation

struct ArtworkProgress: Codable {
    var templateId: UUID
    var layerProgress: [UUID: Double]  // Layer ID → % complete (0.0-1.0)
    var startedAt: Date
    var lastModified: Date

    init(templateId: UUID) {
        self.templateId = templateId
        self.layerProgress = [:]
        self.startedAt = Date()
        self.lastModified = Date()
    }

    /// Overall completion percentage (0.0-1.0)
    var overallCompletion: Double {
        guard !layerProgress.isEmpty else { return 0.0 }

        let total = layerProgress.values.reduce(0.0, +)
        return total / Double(layerProgress.count)
    }

    /// Check if layer is completed (> 50% filled)
    func isLayerComplete(_ layerId: UUID) -> Bool {
        return (layerProgress[layerId] ?? 0.0) > 0.5
    }

    /// Update layer progress
    mutating func updateLayerProgress(_ layerId: UUID, progress: Double) {
        layerProgress[layerId] = min(1.0, max(0.0, progress))
        lastModified = Date()
    }

    /// Mark layer as completed
    mutating func completeLayer(_ layerId: UUID) {
        layerProgress[layerId] = 1.0
        lastModified = Date()
    }

    /// Check if all layers are completed
    func isArtworkComplete(totalLayers: Int) -> Bool {
        guard layerProgress.count == totalLayers else { return false }

        for progress in layerProgress.values {
            if progress < 0.5 {
                return false
            }
        }

        return true
    }

    /// Get completed layer count
    func completedLayerCount() -> Int {
        return layerProgress.values.filter { $0 > 0.5 }.count
    }

    /// Format completion percentage as string
    var completionString: String {
        let percentage = Int(overallCompletion * 100)
        return "\(percentage)%"
    }
}
