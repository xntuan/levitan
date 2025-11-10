//
//  LayerManager.swift
//  Ink - Pattern Drawing App
//
//  Manages layers, selection, visibility, and layer operations
//  Created on November 10, 2025.
//

import Metal
import CoreGraphics

class LayerManager {

    // MARK: - Properties
    private(set) var layers: [Layer] = []
    private(set) var activeLayerIndex: Int = 0

    var activeLayer: Layer? {
        guard activeLayerIndex < layers.count else { return nil }
        return layers[activeLayerIndex]
    }

    // MARK: - Initialization
    init() {
        // Start with empty layer list
    }

    // MARK: - Layer Operations

    /// Add a new layer
    func addLayer(_ layer: Layer) {
        layers.append(layer)
    }

    /// Remove layer at index
    func removeLayer(at index: Int) {
        guard index < layers.count else { return }
        layers.remove(at: index)

        // Adjust active layer if needed
        if activeLayerIndex >= layers.count {
            activeLayerIndex = max(0, layers.count - 1)
        }
    }

    /// Select layer at index
    func selectLayer(at index: Int) {
        guard index >= 0 && index < layers.count else { return }
        activeLayerIndex = index
    }

    /// Toggle layer visibility
    func toggleLayerVisibility(at index: Int) {
        guard index < layers.count else { return }
        layers[index].isVisible.toggle()
    }

    /// Lock/unlock layer
    func toggleLayerLock(at index: Int) {
        guard index < layers.count else { return }
        layers[index].isLocked.toggle()
    }

    /// Move layer
    func moveLayer(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex < layers.count && destinationIndex < layers.count else { return }
        let layer = layers.remove(at: sourceIndex)
        layers.insert(layer, at: destinationIndex)

        // Update active layer index
        if activeLayerIndex == sourceIndex {
            activeLayerIndex = destinationIndex
        }
    }

    /// Update layer opacity
    func setLayerOpacity(_ opacity: Float, at index: Int) {
        guard index < layers.count else { return }
        layers[index].opacity = max(0.0, min(1.0, opacity))
    }

    /// Update layer blend mode
    func setLayerBlendMode(_ blendMode: Layer.BlendMode, at index: Int) {
        guard index < layers.count else { return }
        layers[index].blendMode = blendMode
    }

    // MARK: - Query Methods

    /// Get visible layers
    func getVisibleLayers() -> [Layer] {
        return layers.filter { $0.isVisible }
    }

    /// Check if active layer is locked
    func isActiveLayerLocked() -> Bool {
        return activeLayer?.isLocked ?? true
    }

    /// Get layer count
    func layerCount() -> Int {
        return layers.count
    }

    // MARK: - Helper Methods

    /// Calculate completion percentage for a layer
    /// (This would require analyzing the content texture)
    func calculateLayerCompletion(at index: Int) -> Float {
        guard index < layers.count else { return 0.0 }
        // TODO: Implement actual completion calculation based on filled pixels
        // For now, return placeholder
        return 0.0
    }

    /// Clear all layers
    func clearAllLayers() {
        layers.removeAll()
        activeLayerIndex = 0
    }

    /// Load layers from project
    func loadLayers(_ newLayers: [Layer]) {
        layers = newLayers
        activeLayerIndex = 0
    }
}

// MARK: - Layer Extensions
extension Layer {
    /// Check if point is within layer mask
    func containsPoint(_ point: CGPoint) -> Bool {
        // TODO: Implement actual mask checking using maskTexture
        // For now, return true (no clipping)
        return true
    }
}
