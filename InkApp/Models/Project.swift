//
//  Project.swift
//  Ink - Pattern Drawing App
//
//  Created on November 10, 2025.
//

import CoreGraphics
import Foundation

/// Represents a complete drawing project with layers and metadata
struct Project: Codable {
    let id: UUID
    var name: String
    var canvasSize: CGSize
    var layers: [Layer]
    var baseImageData: Data?  // PNG data of the base template
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(),
         name: String = "Untitled",
         canvasSize: CGSize = CGSize(width: 2048, height: 2048),
         layers: [Layer] = [],
         baseImageData: Data? = nil,
         createdAt: Date = Date(),
         modifiedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.canvasSize = canvasSize
        self.layers = layers
        self.baseImageData = baseImageData
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    mutating func updateModifiedDate() {
        self.modifiedAt = Date()
    }
}

// MARK: - CGSize Codable Extension
extension CGSize: Codable {
    enum CodingKeys: String, CodingKey {
        case width, height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        self.init(width: width, height: height)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
}
