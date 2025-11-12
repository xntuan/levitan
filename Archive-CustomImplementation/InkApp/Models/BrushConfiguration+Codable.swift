//
//  BrushConfiguration+Codable.swift
//  Ink - Pattern Drawing App
//
//  Codable conformance for BrushConfiguration and nested types
//  Created on November 10, 2025.
//

import Foundation

// MARK: - BrushConfiguration Codable

extension BrushConfiguration: Codable {
    enum CodingKeys: String, CodingKey {
        case patternBrush, stabilization, prediction
        case velocityDynamics, pressureCurve, jitter
        case adaptiveSpacing, minimumDistance, flow
        case tiltDynamics, rotationDynamics
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(patternBrush, forKey: .patternBrush)
        try container.encode(stabilization, forKey: .stabilization)
        try container.encode(prediction, forKey: .prediction)
        try container.encode(velocityDynamics, forKey: .velocityDynamics)
        try container.encode(pressureCurve, forKey: .pressureCurve)
        try container.encode(jitter, forKey: .jitter)
        try container.encode(adaptiveSpacing, forKey: .adaptiveSpacing)
        try container.encode(minimumDistance, forKey: .minimumDistance)
        try container.encode(flow, forKey: .flow)
        try container.encode(tiltDynamics, forKey: .tiltDynamics)
        try container.encode(rotationDynamics, forKey: .rotationDynamics)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        patternBrush = try container.decode(PatternBrush.self, forKey: .patternBrush)
        stabilization = try container.decode(Float.self, forKey: .stabilization)
        prediction = try container.decode(Float.self, forKey: .prediction)
        velocityDynamics = try container.decode(VelocityDynamics.self, forKey: .velocityDynamics)
        pressureCurve = try container.decode(PressureCurve.self, forKey: .pressureCurve)
        jitter = try container.decode(BrushJitter.self, forKey: .jitter)
        adaptiveSpacing = try container.decode(Bool.self, forKey: .adaptiveSpacing)
        minimumDistance = try container.decode(Float.self, forKey: .minimumDistance)
        flow = try container.decode(Float.self, forKey: .flow)
        tiltDynamics = try container.decode(TiltDynamics.self, forKey: .tiltDynamics)
        rotationDynamics = try container.decode(RotationDynamics.self, forKey: .rotationDynamics)

        // Initialize non-codable properties with defaults
        isEraserMode = false
        currentTool = .pattern
        brushConfig = BrushToolConfig()
        markerConfig = MarkerToolConfig()
        fillBucketConfig = FillBucketConfig()
    }
}

extension BrushConfiguration.TiltDynamics: Codable {
    enum CodingKeys: String, CodingKey {
        case enabled, affectsSize, affectsOpacity, sizeSensitivity, opacitySensitivity, minimumTilt, maximumTilt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(affectsSize, forKey: .affectsSize)
        try container.encode(affectsOpacity, forKey: .affectsOpacity)
        try container.encode(sizeSensitivity, forKey: .sizeSensitivity)
        try container.encode(opacitySensitivity, forKey: .opacitySensitivity)
        try container.encode(minimumTilt, forKey: .minimumTilt)
        try container.encode(maximumTilt, forKey: .maximumTilt)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try container.decode(Bool.self, forKey: .enabled)
        affectsSize = try container.decode(Bool.self, forKey: .affectsSize)
        affectsOpacity = try container.decode(Bool.self, forKey: .affectsOpacity)
        sizeSensitivity = try container.decode(Float.self, forKey: .sizeSensitivity)
        opacitySensitivity = try container.decode(Float.self, forKey: .opacitySensitivity)
        minimumTilt = try container.decode(Float.self, forKey: .minimumTilt)
        maximumTilt = try container.decode(Float.self, forKey: .maximumTilt)
    }
}

extension BrushConfiguration.RotationDynamics: Codable {
    enum CodingKeys: String, CodingKey {
        case mode, fixedRotation, smoothing
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mode, forKey: .mode)
        try container.encode(fixedRotation, forKey: .fixedRotation)
        try container.encode(smoothing, forKey: .smoothing)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mode = try container.decode(RotationMode.self, forKey: .mode)
        fixedRotation = try container.decode(Float.self, forKey: .fixedRotation)
        smoothing = try container.decode(Float.self, forKey: .smoothing)
    }
}

extension BrushConfiguration.VelocityDynamics: Codable {
    enum CodingKeys: String, CodingKey {
        case enabled, sizeMin, sizeMax, opacityMin, opacityMax, velocityRange
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(sizeMin, forKey: .sizeMin)
        try container.encode(sizeMax, forKey: .sizeMax)
        try container.encode(opacityMin, forKey: .opacityMin)
        try container.encode(opacityMax, forKey: .opacityMax)
        try container.encode(velocityRange, forKey: .velocityRange)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try container.decode(Bool.self, forKey: .enabled)
        sizeMin = try container.decode(Float.self, forKey: .sizeMin)
        sizeMax = try container.decode(Float.self, forKey: .sizeMax)
        opacityMin = try container.decode(Float.self, forKey: .opacityMin)
        opacityMax = try container.decode(Float.self, forKey: .opacityMax)
        velocityRange = try container.decode(Float.self, forKey: .velocityRange)
    }
}

extension BrushConfiguration.BrushJitter: Codable {
    enum CodingKeys: String, CodingKey {
        case enabled, sizeJitter, rotationJitter, opacityJitter, positionJitter
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(sizeJitter, forKey: .sizeJitter)
        try container.encode(rotationJitter, forKey: .rotationJitter)
        try container.encode(opacityJitter, forKey: .opacityJitter)
        try container.encode(positionJitter, forKey: .positionJitter)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try container.decode(Bool.self, forKey: .enabled)
        sizeJitter = try container.decode(Float.self, forKey: .sizeJitter)
        rotationJitter = try container.decode(Float.self, forKey: .rotationJitter)
        opacityJitter = try container.decode(Float.self, forKey: .opacityJitter)
        positionJitter = try container.decode(Float.self, forKey: .positionJitter)
    }
}

extension BrushConfiguration.PressureCurve: Codable {
    enum CodingKeys: String, CodingKey {
        case enabled, curveType, minimum, maximum
    }

    enum CurveTypeCodingKeys: String, CodingKey {
        case type, points
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(minimum, forKey: .minimum)
        try container.encode(maximum, forKey: .maximum)

        // Encode curve type
        var curveContainer = container.nestedContainer(keyedBy: CurveTypeCodingKeys.self, forKey: .curveType)
        switch curveType {
        case .linear:
            try curveContainer.encode("linear", forKey: .type)
        case .easeIn:
            try curveContainer.encode("easeIn", forKey: .type)
        case .easeOut:
            try curveContainer.encode("easeOut", forKey: .type)
        case .easeInOut:
            try curveContainer.encode("easeInOut", forKey: .type)
        case .custom(let points):
            try curveContainer.encode("custom", forKey: .type)
            try curveContainer.encode(points, forKey: .points)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try container.decode(Bool.self, forKey: .enabled)
        minimum = try container.decode(Float.self, forKey: .minimum)
        maximum = try container.decode(Float.self, forKey: .maximum)

        // Decode curve type
        let curveContainer = try container.nestedContainer(keyedBy: CurveTypeCodingKeys.self, forKey: .curveType)
        let type = try curveContainer.decode(String.self, forKey: .type)

        switch type {
        case "linear":
            curveType = .linear
        case "easeIn":
            curveType = .easeIn
        case "easeOut":
            curveType = .easeOut
        case "easeInOut":
            curveType = .easeInOut
        case "custom":
            let points = try curveContainer.decode([Float].self, forKey: .points)
            curveType = .custom(points)
        default:
            curveType = .linear
        }
    }
}

// MARK: - BrushPreset

struct BrushPreset: Codable, Identifiable {
    let id: UUID
    var name: String
    var icon: String  // Emoji or SF Symbol name
    var configuration: BrushConfiguration
    var isBuiltIn: Bool = false
    var createdAt: Date = Date()

    init(id: UUID = UUID(), name: String, icon: String, configuration: BrushConfiguration, isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.configuration = configuration
        self.isBuiltIn = isBuiltIn
        self.createdAt = Date()
    }
}
