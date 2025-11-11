//
//  PatternCreator.swift
//  Ink - Pattern Drawing App
//
//  Tool for creating and editing custom patterns
//  Created on November 11, 2025.
//

import Foundation
import CoreGraphics
import Metal
import UIKit

/// Manager for creating and rendering custom patterns
class PatternCreator {

    // MARK: - Properties

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue

    // Current pattern being edited
    var currentPattern: CustomPattern?

    // Callbacks
    var onPatternUpdated: ((CustomPattern) -> Void)?
    var onElementAdded: ((PatternElement) -> Void)?
    var onElementRemoved: ((UUID) -> Void)?

    // MARK: - Initialization

    init(device: MTLDevice, commandQueue: MTLCommandQueue) {
        self.device = device
        self.commandQueue = commandQueue
    }

    // MARK: - Pattern Creation

    /// Create a new blank pattern
    func createNew(
        name: String,
        arrangement: PatternArrangement,
        category: PatternCategory,
        creatorID: String
    ) -> CustomPattern {

        let pattern = CustomPattern(
            name: name,
            elements: [],
            arrangement: arrangement,
            creatorID: creatorID,
            category: category
        )

        currentPattern = pattern
        return pattern
    }

    /// Load existing pattern for editing
    func loadPattern(_ pattern: CustomPattern) {
        currentPattern = pattern
    }

    // MARK: - Element Management

    /// Add element to pattern
    func addElement(_ element: PatternElement) {
        guard var pattern = currentPattern else { return }

        pattern.elements.append(element)
        pattern.updatedAt = Date()

        currentPattern = pattern
        onElementAdded?(element)
        onPatternUpdated?(pattern)
    }

    /// Remove element from pattern
    func removeElement(id: UUID) {
        guard var pattern = currentPattern else { return }

        pattern.elements.removeAll { $0.id == id }
        pattern.updatedAt = Date()

        currentPattern = pattern
        onElementRemoved?(id)
        onPatternUpdated?(pattern)
    }

    /// Update element
    func updateElement(id: UUID, transform: (inout PatternElement) -> Void) {
        guard var pattern = currentPattern else { return }
        guard let index = pattern.elements.firstIndex(where: { $0.id == id }) else { return }

        transform(&pattern.elements[index])
        pattern.updatedAt = Date()

        currentPattern = pattern
        onPatternUpdated?(pattern)
    }

    // MARK: - Pattern Rendering

    /// Render pattern to UIImage
    func renderPattern(
        _ pattern: CustomPattern,
        size: CGSize,
        backgroundColor: UIColor = .white
    ) -> UIImage? {

        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let cgContext = context.cgContext

            // Background
            cgContext.setFillColor(backgroundColor.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))

            // Render pattern elements based on arrangement
            let instances = generateElementInstances(pattern: pattern, bounds: size)

            for instance in instances {
                renderElement(instance.element, at: instance.position, rotation: instance.rotation, in: cgContext)
            }
        }
    }

    /// Generate pattern geometry for use in drawing
    func generateGeometry(
        from pattern: CustomPattern,
        center: CGPoint,
        scale: Float
    ) -> PatternGeometry {

        var lines: [Line] = []
        var circles: [Circle] = []
        var arcs: [Arc] = []

        let instances = generateElementInstances(
            pattern: pattern,
            bounds: CGSize(width: pattern.bounds.width * CGFloat(scale), height: pattern.bounds.height * CGFloat(scale))
        )

        for instance in instances {
            let element = instance.element
            let position = CGPoint(
                x: center.x + instance.position.x - pattern.bounds.width / 2 * CGFloat(scale),
                y: center.y + instance.position.y - pattern.bounds.height / 2 * CGFloat(scale)
            )

            switch element.shape {
            case .circle:
                circles.append(Circle(
                    center: position,
                    radius: element.size.width / 2 * CGFloat(scale)
                ))

            case .rectangle:
                // Convert rectangle to 4 lines
                let rect = CGRect(
                    x: position.x,
                    y: position.y,
                    width: element.size.width * CGFloat(scale),
                    height: element.size.height * CGFloat(scale)
                )
                lines.append(contentsOf: rectangleToLines(rect))

            case .line(let start, let end):
                lines.append(Line(
                    start: CGPoint(x: position.x + start.x, y: position.y + start.y),
                    end: CGPoint(x: position.x + end.x, y: position.y + end.y)
                ))

            case .arc(let startAngle, let endAngle):
                arcs.append(Arc(
                    center: position,
                    radius: element.size.width / 2 * CGFloat(scale),
                    startAngle: CGFloat(startAngle * .pi / 180),
                    endAngle: CGFloat(endAngle * .pi / 180)
                ))

            default:
                // Other shapes can be converted similarly
                break
            }
        }

        return PatternGeometry(lines: lines, circles: circles, arcs: arcs, waves: [])
    }

    // MARK: - Helper Methods

    private struct ElementInstance {
        let element: PatternElement
        let position: CGPoint
        let rotation: Float
    }

    private func generateElementInstances(pattern: CustomPattern, bounds: CGSize) -> [ElementInstance] {
        var instances: [ElementInstance] = []

        switch pattern.arrangement {
        case .grid(let rows, let columns, let spacing):
            for row in 0..<rows {
                for col in 0..<columns {
                    for element in pattern.elements {
                        let x = CGFloat(col) * spacing.width + element.position.x
                        let y = CGFloat(row) * spacing.height + element.position.y

                        instances.append(ElementInstance(
                            element: element,
                            position: CGPoint(x: x, y: y),
                            rotation: element.rotation
                        ))
                    }
                }
            }

        case .radial(let count, let radius, let angleOffset):
            for i in 0..<count {
                let angle = (Float(i) / Float(count)) * 360.0 + angleOffset
                let rad = CGFloat(angle * .pi / 180)

                for element in pattern.elements {
                    let x = cos(rad) * CGFloat(radius) + bounds.width / 2
                    let y = sin(rad) * CGFloat(radius) + bounds.height / 2

                    instances.append(ElementInstance(
                        element: element,
                        position: CGPoint(x: x, y: y),
                        rotation: angle + element.rotation
                    ))
                }
            }

        case .spiral(let count, let spacing, let rotation):
            for i in 0..<count {
                let t = Float(i) / Float(count)
                let angle = t * 360.0 * rotation
                let rad = CGFloat(angle * .pi / 180)
                let radius = t * spacing

                for element in pattern.elements {
                    let x = cos(rad) * CGFloat(radius) + bounds.width / 2
                    let y = sin(rad) * CGFloat(radius) + bounds.height / 2

                    instances.append(ElementInstance(
                        element: element,
                        position: CGPoint(x: x, y: y),
                        rotation: angle + element.rotation
                    ))
                }
            }

        case .random(let count, let seed):
            var generator = SeededRandomGenerator(seed: seed)

            for _ in 0..<count {
                for element in pattern.elements {
                    let x = CGFloat(generator.next()) * bounds.width
                    let y = CGFloat(generator.next()) * bounds.height
                    let rotation = generator.next() * 360

                    instances.append(ElementInstance(
                        element: element,
                        position: CGPoint(x: x, y: y),
                        rotation: rotation
                    ))
                }
            }

        case .organic(let algorithm):
            instances = generateOrganicInstances(
                pattern: pattern,
                bounds: bounds,
                algorithm: algorithm
            )

        case .custom:
            // Custom arrangement - just use original positions
            for element in pattern.elements {
                instances.append(ElementInstance(
                    element: element,
                    position: element.position,
                    rotation: element.rotation
                ))
            }
        }

        return instances
    }

    private func renderElement(
        _ element: PatternElement,
        at position: CGPoint,
        rotation: Float,
        in context: CGContext
    ) {
        context.saveGState()

        // Apply transform
        context.translateBy(x: position.x, y: position.y)
        context.rotate(by: CGFloat(rotation * .pi / 180))

        // Set opacity
        context.setAlpha(CGFloat(element.opacity))

        // Render shape
        switch element.shape {
        case .circle:
            context.addEllipse(in: CGRect(
                x: -element.size.width / 2,
                y: -element.size.height / 2,
                width: element.size.width,
                height: element.size.height
            ))
            context.strokePath()

        case .rectangle:
            context.addRect(CGRect(
                x: -element.size.width / 2,
                y: -element.size.height / 2,
                width: element.size.width,
                height: element.size.height
            ))
            context.strokePath()

        case .triangle:
            let path = createTrianglePath(size: element.size)
            context.addPath(path)
            context.strokePath()

        case .line(let start, let end):
            context.move(to: start)
            context.addLine(to: end)
            context.strokePath()

        case .arc(let startAngle, let endAngle):
            context.addArc(
                center: .zero,
                radius: element.size.width / 2,
                startAngle: CGFloat(startAngle * .pi / 180),
                endAngle: CGFloat(endAngle * .pi / 180),
                clockwise: false
            )
            context.strokePath()

        case .bezier(let cp1, let cp2, let end):
            context.move(to: .zero)
            context.addCurve(to: end, control1: cp1, control2: cp2)
            context.strokePath()

        case .polygon(let points):
            guard let first = points.first else { break }
            context.move(to: first)
            points.dropFirst().forEach { context.addLine(to: $0) }
            context.closePath()
            context.strokePath()

        case .custom:
            // Custom SVG path rendering would go here
            break
        }

        context.restoreGState()
    }

    private func createTrianglePath(size: CGSize) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: -size.height / 2))
        path.addLine(to: CGPoint(x: size.width / 2, y: size.height / 2))
        path.addLine(to: CGPoint(x: -size.width / 2, y: size.height / 2))
        path.closeSubpath()
        return path
    }

    private func rectangleToLines(_ rect: CGRect) -> [Line] {
        return [
            Line(start: rect.origin, end: CGPoint(x: rect.maxX, y: rect.minY)),
            Line(start: CGPoint(x: rect.maxX, y: rect.minY), end: CGPoint(x: rect.maxX, y: rect.maxY)),
            Line(start: CGPoint(x: rect.maxX, y: rect.maxY), end: CGPoint(x: rect.minX, y: rect.maxY)),
            Line(start: CGPoint(x: rect.minX, y: rect.maxY), end: rect.origin)
        ]
    }

    private func generateOrganicInstances(
        pattern: CustomPattern,
        bounds: CGSize,
        algorithm: OrganicAlgorithm
    ) -> [ElementInstance] {
        // Simplified organic pattern generation
        // In production, implement Voronoi, Perlin noise, etc.
        var instances: [ElementInstance] = []

        switch algorithm {
        case .scatter:
            for i in 0..<20 {
                let angle = Float(i) * 17.5  // Prime number spacing
                let radius = Float(i) * 3.0

                for element in pattern.elements {
                    let rad = CGFloat(angle * .pi / 180)
                    let x = cos(rad) * CGFloat(radius) + bounds.width / 2
                    let y = sin(rad) * CGFloat(radius) + bounds.height / 2

                    instances.append(ElementInstance(
                        element: element,
                        position: CGPoint(x: x, y: y),
                        rotation: angle
                    ))
                }
            }

        default:
            // Other algorithms would be implemented similarly
            break
        }

        return instances
    }

    // MARK: - Pattern Templates

    /// Create a preset pattern
    static func createPreset(_ preset: PatternPreset, creatorID: String) -> CustomPattern {
        switch preset {
        case .dots:
            return CustomPattern(
                name: "Dots Grid",
                elements: [
                    PatternElement(
                        shape: .circle,
                        position: .zero,
                        size: CGSize(width: 4, height: 4)
                    )
                ],
                arrangement: .grid(rows: 5, columns: 5, spacing: CGSize(width: 10, height: 10)),
                creatorID: creatorID,
                category: .geometric
            )

        case .stars:
            let starPoints: [CGPoint] = [
                CGPoint(x: 0, y: -10),
                CGPoint(x: 3, y: -3),
                CGPoint(x: 10, y: 0),
                CGPoint(x: 3, y: 3),
                CGPoint(x: 0, y: 10),
                CGPoint(x: -3, y: 3),
                CGPoint(x: -10, y: 0),
                CGPoint(x: -3, y: -3)
            ]

            return CustomPattern(
                name: "Stars",
                elements: [
                    PatternElement(
                        shape: .polygon(points: starPoints),
                        position: .zero,
                        size: CGSize(width: 20, height: 20)
                    )
                ],
                arrangement: .radial(count: 8, radius: 40, angleOffset: 0),
                creatorID: creatorID,
                category: .decorative
            )

        case .hexagons:
            return CustomPattern(
                name: "Hexagons",
                elements: [
                    PatternElement(
                        shape: .polygon(points: createHexagonPoints()),
                        position: .zero,
                        size: CGSize(width: 15, height: 15)
                    )
                ],
                arrangement: .grid(rows: 4, columns: 4, spacing: CGSize(width: 18, height: 16)),
                creatorID: creatorID,
                category: .geometric
            )

        case .waves:
            return CustomPattern(
                name: "Waves",
                elements: [
                    PatternElement(
                        shape: .bezier(
                            controlPoint1: CGPoint(x: 10, y: -5),
                            controlPoint2: CGPoint(x: 20, y: 5),
                            endPoint: CGPoint(x: 30, y: 0)
                        ),
                        position: .zero,
                        size: CGSize(width: 30, height: 10)
                    )
                ],
                arrangement: .grid(rows: 5, columns: 3, spacing: CGSize(width: 35, height: 15)),
                creatorID: creatorID,
                category: .organic
            )
        }
    }

    private static func createHexagonPoints() -> [CGPoint] {
        let angles: [CGFloat] = [0, 60, 120, 180, 240, 300]
        return angles.map { angle in
            let rad = angle * .pi / 180
            return CGPoint(
                x: cos(rad) * 10,
                y: sin(rad) * 10
            )
        }
    }
}

// MARK: - Seeded Random Generator

struct SeededRandomGenerator {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(seed)
    }

    mutating func next() -> Float {
        // Simple LCG (Linear Congruential Generator)
        state = (state &* 1103515245 &+ 12345) & 0x7fffffff
        return Float(state) / Float(0x7fffffff)
    }
}

// MARK: - Pattern Presets

enum PatternPreset {
    case dots
    case stars
    case hexagons
    case waves
}
