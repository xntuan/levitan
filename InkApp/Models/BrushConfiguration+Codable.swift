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
}

extension BrushConfiguration.TiltDynamics: Codable {}
extension BrushConfiguration.RotationDynamics: Codable {}
extension BrushConfiguration.VelocityDynamics: Codable {}
extension BrushConfiguration.BrushJitter: Codable {}

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
