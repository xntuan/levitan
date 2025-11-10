//
//  PatternGenerator.swift
//  Ink - Pattern Drawing App
//
//  Generates geometric patterns (lines, dots, waves, etc.)
//  Created on November 10, 2025.
//

import CoreGraphics
import Foundation

class PatternGenerator {

    // MARK: - Parallel Lines Pattern

    /// Generate parallel lines at given rotation
    static func generateParallelLines(
        center: CGPoint,
        rotation: Float,
        spacing: Float,
        length: Float = 20.0,
        count: Int = 7
    ) -> [Line] {
        var lines: [Line] = []

        let rad = CGFloat(rotation * .pi / 180)
        let perpX = cos(rad + .pi / 2)
        let perpY = sin(rad + .pi / 2)

        for i in -count / 2...count / 2 {
            let offset = CGFloat(Float(i) * spacing)
            let offsetX = perpX * offset
            let offsetY = perpY * offset

            let halfLength = CGFloat(length / 2)
            let start = CGPoint(
                x: center.x + offsetX - cos(rad) * halfLength,
                y: center.y + offsetY - sin(rad) * halfLength
            )
            let end = CGPoint(
                x: center.x + offsetX + cos(rad) * halfLength,
                y: center.y + offsetY + sin(rad) * halfLength
            )

            lines.append(Line(start: start, end: end))
        }

        return lines
    }

    // MARK: - Cross-Hatch Pattern

    /// Generate cross-hatch (perpendicular intersecting lines)
    static func generateCrossHatch(
        center: CGPoint,
        rotation: Float,
        spacing: Float,
        length: Float = 20.0,
        count: Int = 5
    ) -> [Line] {
        let horizontal = generateParallelLines(
            center: center,
            rotation: rotation,
            spacing: spacing,
            length: length,
            count: count
        )
        let vertical = generateParallelLines(
            center: center,
            rotation: rotation + 90,
            spacing: spacing,
            length: length,
            count: count
        )

        return horizontal + vertical
    }

    // MARK: - Dots Pattern (Stippling)

    /// Generate dot grid pattern
    static func generateDots(
        center: CGPoint,
        spacing: Float,
        radius: Float = 2.0,
        gridSize: Int = 5
    ) -> [Circle] {
        var circles: [Circle] = []

        for i in -gridSize...gridSize {
            for j in -gridSize...gridSize {
                let x = center.x + CGFloat(Float(i) * spacing)
                let y = center.y + CGFloat(Float(j) * spacing)
                circles.append(Circle(
                    center: CGPoint(x: x, y: y),
                    radius: CGFloat(radius)
                ))
            }
        }

        return circles
    }

    // MARK: - Contour Lines Pattern

    /// Generate concentric circles (contour lines)
    static func generateContourLines(
        center: CGPoint,
        spacing: Float,
        count: Int = 5
    ) -> [Arc] {
        var arcs: [Arc] = []

        for i in 0..<count {
            let radius = CGFloat(Float(i + 1) * spacing)
            arcs.append(Arc(
                center: center,
                radius: radius,
                startAngle: 0,
                endAngle: 2 * .pi
            ))
        }

        return arcs
    }

    // MARK: - Waves Pattern

    /// Generate wavy horizontal lines
    static func generateWaves(
        center: CGPoint,
        spacing: Float,
        amplitude: Float = 3.0,
        wavelength: Float = 20.0,
        count: Int = 5,
        width: Float = 40.0
    ) -> [[CGPoint]] {
        var waves: [[CGPoint]] = []

        for i in 0..<count {
            var wave: [CGPoint] = []
            let yOffset = Float(i) * spacing - Float(count / 2) * spacing

            let steps = Int(width / 2)
            for step in 0...steps {
                let x = Float(step) * 2
                let y = sin(x / wavelength * .pi * 2) * amplitude + yOffset
                wave.append(CGPoint(
                    x: CGFloat(center.x + CGFloat(x) - CGFloat(width / 2)),
                    y: CGFloat(center.y) + CGFloat(y)
                ))
            }

            waves.append(wave)
        }

        return waves
    }

    // MARK: - Pattern Rendering Helpers

    /// Convert pattern to drawable paths
    static func generatePattern(
        type: PatternBrush.PatternType,
        center: CGPoint,
        rotation: Float,
        spacing: Float,
        scale: Float
    ) -> PatternGeometry {
        let adjustedSpacing = spacing * scale

        switch type {
        case .parallelLines:
            let lines = generateParallelLines(
                center: center,
                rotation: rotation,
                spacing: adjustedSpacing,
                length: 20.0 * scale
            )
            return PatternGeometry(lines: lines)

        case .crossHatch:
            let lines = generateCrossHatch(
                center: center,
                rotation: rotation,
                spacing: adjustedSpacing,
                length: 20.0 * scale
            )
            return PatternGeometry(lines: lines)

        case .dots:
            let circles = generateDots(
                center: center,
                spacing: adjustedSpacing,
                radius: 2.0 * scale
            )
            return PatternGeometry(circles: circles)

        case .contourLines:
            let arcs = generateContourLines(
                center: center,
                spacing: adjustedSpacing
            )
            return PatternGeometry(arcs: arcs)

        case .waves:
            let waves = generateWaves(
                center: center,
                spacing: adjustedSpacing,
                amplitude: 3.0 * scale,
                wavelength: 20.0 * scale,
                width: 40.0 * scale
            )
            return PatternGeometry(waves: waves)
        }
    }
}

// MARK: - Geometric Types

struct Line {
    let start: CGPoint
    let end: CGPoint
}

struct Circle {
    let center: CGPoint
    let radius: CGFloat
}

struct Arc {
    let center: CGPoint
    let radius: CGFloat
    let startAngle: CGFloat
    let endAngle: CGFloat
}

// MARK: - Pattern Geometry Container

struct PatternGeometry {
    var lines: [Line] = []
    var circles: [Circle] = []
    var arcs: [Arc] = []
    var waves: [[CGPoint]] = []

    init(lines: [Line] = [], circles: [Circle] = [], arcs: [Arc] = [], waves: [[CGPoint]] = []) {
        self.lines = lines
        self.circles = circles
        self.arcs = arcs
        self.waves = waves
    }

    var isEmpty: Bool {
        return lines.isEmpty && circles.isEmpty && arcs.isEmpty && waves.isEmpty
    }
}
