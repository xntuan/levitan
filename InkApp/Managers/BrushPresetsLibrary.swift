//
//  BrushPresetsLibrary.swift
//  Ink - Pattern Drawing App
//
//  Manages brush presets: built-in + custom
//  Created on November 10, 2025.
//

import Foundation
import UIKit

class BrushPresetsLibrary {

    // MARK: - Singleton

    static let shared = BrushPresetsLibrary()

    // MARK: - Properties

    private var customPresets: [BrushPreset] = []
    private let userDefaultsKey = "com.ink.customBrushPresets"

    // MARK: - Initialization

    private init() {
        loadCustomPresets()
    }

    // MARK: - Built-in Presets

    func builtInPresets() -> [BrushPreset] {
        return [
            createPencilPreset(),
            createInkPenPreset(),
            createWatercolorPreset(),
            createTechnicalPreset(),
            createCalligraphyPreset(),
            createCharcoalPreset(),
            createAirbrushPreset(),
            createMarkerPreset(),
            createChalkPreset(),
            createSketchPreset()
        ]
    }

    // MARK: - Preset Creation

    private func createPencilPreset() -> BrushPreset {
        var config = BrushConfiguration(patternBrush: PatternBrush(
            type: .parallelLines,
            rotation: 45,
            spacing: 8,
            opacity: 0.8,
            scale: 1.0
        ))

        // Tilt-sensitive, linear pressure
        config.tiltDynamics.enabled = true
        config.tiltDynamics.affectsSize = true
        config.tiltDynamics.sizeSensitivity = 0.6
        config.pressureCurve.curveType = .linear
        config.stabilization = 20
        config.flow = 0.9

        return BrushPreset(
            name: "Pencil",
            icon: "✏️",
            configuration: config,
            isBuiltIn: true
        )
    }

    private func createInkPenPreset() -> BrushPreset {
        var config = BrushConfiguration(patternBrush: PatternBrush(
            type: .crossHatch,
            rotation: 0,
            spacing: 5,
            opacity: 1.0,
            scale: 0.8
        ))

        // No tilt, sharp pressure curve
        config.tiltDynamics.enabled = false
        config.pressureCurve.curveType = .easeIn
        config.stabilization = 40
        config.flow = 1.0
        config.minimumDistance = 1.0

        return BrushPreset(
            name: "Ink Pen",
            icon: "🖊️",
            configuration: config,
            isBuiltIn: true
        )
    }

    private func createWatercolorPreset() -> BrushPreset {
        var config = BrushConfiguration(patternBrush: PatternBrush(
            type: .dots,
            rotation: 0,
            spacing: 12,
            opacity: 0.4,
            scale: 1.5
        ))

        // Low flow, high jitter
        config.flow = 0.5
        config.jitter.enabled = true
        config.jitter.sizeJitter = 0.3
        config.jitter.opacityJitter = 0.2
        config.jitter.positionJitter = 3.0
        config.pressureCurve.curveType = .easeOut
        config.stabilization = 50

        return BrushPreset(
            name: "Watercolor",
            icon: "🎨",
            configuration: config,
            isBuiltIn: true
        )
    }

    private func createTechnicalPreset() -> BrushPreset {
        var config = BrushConfiguration(patternBrush: PatternBrush(
            type: .parallelLines,
            rotation: 0,
            spacing: 3,
            opacity: 1.0,
            scale: 0.6
        ))

        // Fixed rotation, high stabilization
        config.rotationDynamics.mode = .fixed
        config.rotationDynamics.fixedRotation = 0
        config.stabilization = 80
        config.velocityDynamics.enabled = false
        config.flow = 1.0

        return BrushPreset(
            name: "Technical",
            icon: "📐",
            configuration: config,
            isBuiltIn: true
        )
    }

    private func createCalligraphyPreset() -> BrushPreset {
        var config = BrushConfiguration(patternBrush: PatternBrush(
            type: .parallelLines,
            rotation: 45,
            spacing: 4,
            opacity: 0.95,
            scale: 1.2
        ))

        // Azimuth rotation, ease-out curve
        config.rotationDynamics.mode = .followAzimuth
        config.rotationDynamics.smoothing = 0.4
        config.pressureCurve.curveType = .easeOut
        config.tiltDynamics.enabled = true
        config.tiltDynamics.affectsSize = true
        config.tiltDynamics.sizeSensitivity = 0.7
        config.stabilization = 30

        return BrushPreset(
            name: "Calligraphy",
            icon: "✒️",
            configuration: config,
            isBuiltIn: true
        )
    }

    private func createCharcoalPreset() -> BrushPreset {
        var config = BrushConfiguration(patternBrush: PatternBrush(
            type: .contourLines,
            rotation: 0,
            spacing: 10,
            opacity: 0.7,
            scale: 1.3
        ))

        // High jitter, velocity dynamics
        config.jitter.enabled = true
        config.jitter.sizeJitter = 0.4
        config.jitter.rotationJitter = 15
        config.jitter.opacityJitter = 0.3
        config.jitter.positionJitter = 2.0
        config.velocityDynamics.enabled = true
        config.flow = 0.8
        config.stabilization = 25

        return BrushPreset(
            name: "Charcoal",
            icon: "🌫️",
            configuration: config,
            isBuiltIn: true
        )
    }

    private func createAirbrushPreset() -> BrushPreset {
        var config = BrushConfiguration(patternBrush: PatternBrush(
            type: .dots,
            rotation: 0,
            spacing: 15,
            opacity: 0.3,
            scale: 2.0
        ))

        // Soft pressure, high flow
        config.pressureCurve.curveType = .easeInOut
        config.flow = 0.6
        config.jitter.enabled = true
        config.jitter.positionJitter = 5.0
        config.jitter.opacityJitter = 0.15
        config.stabilization = 60

        return BrushPreset(
            name: "Airbrush",
            icon: "💨",
            configuration: config,
            isBuiltIn: true
        )
    }

    private func createMarkerPreset() -> BrushPreset {
        var config = BrushConfiguration(patternBrush: PatternBrush(
            type: .parallelLines,
            rotation: 90,
            spacing: 6,
            opacity: 0.7,
            scale: 1.5
        ))

        // No velocity dynamics, flat pressure
        config.velocityDynamics.enabled = false
        config.pressureCurve.curveType = .linear
        config.flow = 1.0
        config.stabilization = 35

        return BrushPreset(
            name: "Marker",
            icon: "🖍️",
            configuration: config,
            isBuiltIn: true
        )
    }

    private func createChalkPreset() -> BrushPreset {
        var config = BrushConfiguration(patternBrush: PatternBrush(
            type: .dots,
            rotation: 0,
            spacing: 8,
            opacity: 0.85,
            scale: 1.0
        ))

        // Position jitter, texture
        config.jitter.enabled = true
        config.jitter.positionJitter = 3.0
        config.jitter.sizeJitter = 0.25
        config.jitter.opacityJitter = 0.2
        config.flow = 0.85
        config.stabilization = 20

        return BrushPreset(
            name: "Chalk",
            icon: "🧱",
            configuration: config,
            isBuiltIn: true
        )
    }

    private func createSketchPreset() -> BrushPreset {
        var config = BrushConfiguration(patternBrush: PatternBrush(
            type: .crossHatch,
            rotation: 45,
            spacing: 7,
            opacity: 0.75,
            scale: 0.9
        ))

        // Prediction, low stabilization
        config.prediction = 80
        config.stabilization = 15
        config.velocityDynamics.enabled = true
        config.flow = 0.9

        return BrushPreset(
            name: "Sketch",
            icon: "✏️",
            configuration: config,
            isBuiltIn: true
        )
    }

    // MARK: - Custom Presets

    func getCustomPresets() -> [BrushPreset] {
        return customPresets
    }

    func getAllPresets() -> [BrushPreset] {
        return builtInPresets() + customPresets
    }

    func saveCustomPreset(name: String, icon: String, configuration: BrushConfiguration) {
        let preset = BrushPreset(
            name: name,
            icon: icon,
            configuration: configuration,
            isBuiltIn: false
        )

        customPresets.append(preset)
        saveCustomPresets()

        print("💾 Saved custom preset: '\(name)'")
    }

    func deleteCustomPreset(_ preset: BrushPreset) {
        guard !preset.isBuiltIn else {
            print("⚠️ Cannot delete built-in preset")
            return
        }

        customPresets.removeAll { $0.id == preset.id }
        saveCustomPresets()

        print("🗑️ Deleted custom preset: '\(preset.name)'")
    }

    func updateCustomPreset(_ preset: BrushPreset) {
        guard !preset.isBuiltIn else {
            print("⚠️ Cannot update built-in preset")
            return
        }

        if let index = customPresets.firstIndex(where: { $0.id == preset.id }) {
            customPresets[index] = preset
            saveCustomPresets()
            print("✏️ Updated custom preset: '\(preset.name)'")
        }
    }

    // MARK: - Persistence

    private func saveCustomPresets() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(customPresets)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            print("💾 Saved \(customPresets.count) custom presets")
        } catch {
            print("❌ Failed to save custom presets: \(error)")
        }
    }

    private func loadCustomPresets() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("ℹ️ No custom presets found")
            return
        }

        do {
            let decoder = JSONDecoder()
            customPresets = try decoder.decode([BrushPreset].self, from: data)
            print("✅ Loaded \(customPresets.count) custom presets")
        } catch {
            print("❌ Failed to load custom presets: \(error)")
            customPresets = []
        }
    }

    // MARK: - Import/Export

    func exportPreset(_ preset: BrushPreset) -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(preset)
            return data
        } catch {
            print("❌ Failed to export preset: \(error)")
            return nil
        }
    }

    func importPreset(from data: Data) -> BrushPreset? {
        do {
            let decoder = JSONDecoder()
            var preset = try decoder.decode(BrushPreset.self, from: data)

            // Reset to custom (not built-in)
            preset.isBuiltIn = false
            preset.createdAt = Date()

            // Check for duplicate names
            var baseName = preset.name
            var counter = 1
            while customPresets.contains(where: { $0.name == preset.name }) {
                preset.name = "\(baseName) (\(counter))"
                counter += 1
            }

            customPresets.append(preset)
            saveCustomPresets()

            print("📥 Imported preset: '\(preset.name)'")
            return preset
        } catch {
            print("❌ Failed to import preset: \(error)")
            return nil
        }
    }

    func exportPresetToFile(_ preset: BrushPreset) -> URL? {
        guard let data = exportPreset(preset) else { return nil }

        let fileName = "\(preset.name).inkbrush"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            print("📤 Exported preset to: \(fileURL.path)")
            return fileURL
        } catch {
            print("❌ Failed to write preset file: \(error)")
            return nil
        }
    }
}
