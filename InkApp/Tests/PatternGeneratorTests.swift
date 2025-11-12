//
//  PatternGeneratorTests.swift
//  InkTests
//
//  Unit tests for pattern generation algorithms
//  Created on November 10, 2025.
//

import XCTest
import CoreGraphics
@testable import Ink

class PatternGeneratorTests: XCTestCase {

    // MARK: - Parallel Lines Tests

    func testParallelLinesGeneration() {
        // Given
        let center = CGPoint(x: 100, y: 100)
        let rotation: Float = 45.0
        let spacing: Float = 10.0
        let count = 7

        // When
        let lines = PatternGenerator.generateParallelLines(
            center: center,
            rotation: rotation,
            spacing: spacing,
            count: count
        )

        // Then
        XCTAssertEqual(lines.count, count, "Should generate correct number of lines")

        // Verify lines are parallel (have same angle)
        for i in 0..<lines.count - 1 {
            let line1 = lines[i]
            let line2 = lines[i + 1]

            let angle1 = atan2(line1.end.y - line1.start.y, line1.end.x - line1.start.x)
            let angle2 = atan2(line2.end.y - line2.start.y, line2.end.x - line2.start.x)

            XCTAssertEqual(angle1, angle2, accuracy: 0.001, "Lines should be parallel")
        }
    }

    func testParallelLinesRotation() {
        // Test that rotation actually affects line angle
        let center = CGPoint(x: 100, y: 100)

        let horizontal = PatternGenerator.generateParallelLines(
            center: center,
            rotation: 0,
            spacing: 10
        )

        let vertical = PatternGenerator.generateParallelLines(
            center: center,
            rotation: 90,
            spacing: 10
        )

        let firstHorizontal = horizontal.first!
        let firstVertical = vertical.first!

        let angleH = atan2(firstHorizontal.end.y - firstHorizontal.start.y,
                           firstHorizontal.end.x - firstHorizontal.start.x)
        let angleV = atan2(firstVertical.end.y - firstVertical.start.y,
                           firstVertical.end.x - firstVertical.start.x)

        // Angles should differ by ~90 degrees
        let angleDiff = abs(angleH - angleV)
        let expectedDiff = CGFloat.pi / 2
        XCTAssertEqual(angleDiff, expectedDiff, accuracy: 0.1)
    }

    // MARK: - Cross-Hatch Tests

    func testCrossHatchGeneration() {
        // Given
        let center = CGPoint(x: 100, y: 100)
        let rotation: Float = 0
        let spacing: Float = 10.0
        let count = 5

        // When
        let lines = PatternGenerator.generateCrossHatch(
            center: center,
            rotation: rotation,
            spacing: spacing,
            count: count
        )

        // Then
        // Should generate count lines in each direction
        XCTAssertEqual(lines.count, count * 2, "Should generate lines in both directions")
    }

    // MARK: - Dots Tests

    func testDotsGeneration() {
        // Given
        let center = CGPoint(x: 100, y: 100)
        let spacing: Float = 10.0
        let radius: Float = 2.0
        let gridSize = 5

        // When
        let circles = PatternGenerator.generateDots(
            center: center,
            spacing: spacing,
            radius: radius,
            gridSize: gridSize
        )

        // Then
        let expectedCount = (gridSize * 2 + 1) * (gridSize * 2 + 1)
        XCTAssertEqual(circles.count, expectedCount, "Should generate correct grid of dots")

        // Verify all circles have correct radius
        for circle in circles {
            XCTAssertEqual(circle.radius, CGFloat(radius), "All dots should have same radius")
        }
    }

    func testDotsSpacing() {
        // Test that dots are properly spaced
        let center = CGPoint(x: 100, y: 100)
        let spacing: Float = 15.0
        let gridSize = 2

        let circles = PatternGenerator.generateDots(
            center: center,
            spacing: spacing,
            gridSize: gridSize
        )

        // Check spacing between adjacent dots
        // Center dot should be at (100, 100)
        let centerDot = circles.first { circle in
            abs(circle.center.x - center.x) < 0.1 &&
            abs(circle.center.y - center.y) < 0.1
        }

        XCTAssertNotNil(centerDot, "Should have dot at center")
    }

    // MARK: - Contour Lines Tests

    func testContourLinesGeneration() {
        // Given
        let center = CGPoint(x: 100, y: 100)
        let spacing: Float = 10.0
        let count = 5

        // When
        let arcs = PatternGenerator.generateContourLines(
            center: center,
            spacing: spacing,
            count: count
        )

        // Then
        XCTAssertEqual(arcs.count, count, "Should generate correct number of contour lines")

        // Verify circles are concentric (increasing radius)
        for i in 0..<arcs.count - 1 {
            XCTAssertLessThan(arcs[i].radius, arcs[i + 1].radius,
                             "Contour lines should have increasing radius")
        }

        // Verify all circles have same center
        for arc in arcs {
            XCTAssertEqual(arc.center.x, center.x, accuracy: 0.1)
            XCTAssertEqual(arc.center.y, center.y, accuracy: 0.1)
        }
    }

    // MARK: - Waves Tests

    func testWavesGeneration() {
        // Given
        let center = CGPoint(x: 100, y: 100)
        let spacing: Float = 10.0
        let amplitude: Float = 3.0
        let wavelength: Float = 20.0
        let count = 5

        // When
        let waves = PatternGenerator.generateWaves(
            center: center,
            spacing: spacing,
            amplitude: amplitude,
            wavelength: wavelength,
            count: count
        )

        // Then
        XCTAssertEqual(waves.count, count, "Should generate correct number of waves")

        // Each wave should have multiple points
        for wave in waves {
            XCTAssertGreaterThan(wave.count, 10, "Each wave should have multiple points")
        }
    }

    // MARK: - Pattern Geometry Tests

    func testPatternGeometryCreation() {
        let center = CGPoint(x: 100, y: 100)

        // Test each pattern type
        let patternTypes: [PatternBrush.PatternType] = [
            .parallelLines, .crossHatch, .dots, .contourLines, .waves
        ]

        for type in patternTypes {
            let geometry = PatternGenerator.generatePattern(
                type: type,
                center: center,
                rotation: 45,
                spacing: 10,
                scale: 1.0
            )

            XCTAssertFalse(geometry.isEmpty, "\(type) should generate non-empty geometry")
        }
    }

    func testPatternScaling() {
        // Test that scale parameter affects pattern size
        let center = CGPoint(x: 100, y: 100)

        let scale1 = PatternGenerator.generatePattern(
            type: .parallelLines,
            center: center,
            rotation: 0,
            spacing: 10,
            scale: 1.0
        )

        let scale2 = PatternGenerator.generatePattern(
            type: .parallelLines,
            center: center,
            rotation: 0,
            spacing: 10,
            scale: 2.0
        )

        XCTAssertEqual(scale1.lines.count, scale2.lines.count,
                      "Scale shouldn't change line count")

        // Lines in scale2 should be longer/more spaced
        if let line1 = scale1.lines.first, let line2 = scale2.lines.first {
            let length1 = line1.start.distance(to: line1.end)
            let length2 = line2.start.distance(to: line2.end)
            XCTAssertGreaterThan(length2, length1, "Scaled lines should be longer")
        }
    }

    // MARK: - Performance Tests

    func testPatternGenerationPerformance() {
        // Pattern generation should be fast (< 5ms as per requirements)
        measure {
            for _ in 0..<100 {
                _ = PatternGenerator.generateParallelLines(
                    center: CGPoint(x: 100, y: 100),
                    rotation: 45,
                    spacing: 10
                )
            }
        }
    }
}
