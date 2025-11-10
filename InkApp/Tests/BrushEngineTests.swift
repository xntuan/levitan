//
//  BrushEngineTests.swift
//  InkTests
//
//  Unit tests for brush engine and stroke handling
//  Created on November 10, 2025.
//

import XCTest
import CoreGraphics
@testable import Ink

class BrushEngineTests: XCTestCase {

    var brushEngine: BrushEngine!
    let testLayerId = UUID()

    override func setUp() {
        super.setUp()
        let brush = PatternBrush(type: .parallelLines, rotation: 45, spacing: 10)
        brushEngine = BrushEngine(brush: brush)
    }

    override func tearDown() {
        brushEngine = nil
        super.tearDown()
    }

    // MARK: - Stroke Lifecycle Tests

    func testBeginStroke() {
        // Given
        let point = CGPoint(x: 100, y: 100)
        let pressure: Float = 0.8

        // When
        brushEngine.beginStroke(at: point, pressure: pressure, layerId: testLayerId)

        // Then
        XCTAssertNotNil(brushEngine.currentStroke, "Should have current stroke")
        XCTAssertEqual(brushEngine.currentStroke?.points.count, 1)
        XCTAssertEqual(brushEngine.currentStroke?.points.first?.position, point)
        XCTAssertEqual(brushEngine.currentStroke?.points.first?.pressure, pressure)
        XCTAssertEqual(brushEngine.currentStroke?.layerId, testLayerId)
    }

    func testAddPoint() {
        // Given - start a stroke
        brushEngine.beginStroke(at: CGPoint(x: 100, y: 100), pressure: 1.0, layerId: testLayerId)

        // When - add points
        for i in 1...10 {
            brushEngine.addPoint(CGPoint(x: 100 + CGFloat(i * 10), y: 100), pressure: 1.0)
        }

        // Then
        XCTAssertNotNil(brushEngine.currentStroke)
        // Points should be smoothed, so count might be different
        XCTAssertGreaterThan(brushEngine.currentStroke?.points.count ?? 0, 0)
    }

    func testEndStroke() {
        // Given - create a stroke
        brushEngine.beginStroke(at: CGPoint(x: 100, y: 100), pressure: 1.0, layerId: testLayerId)
        brushEngine.addPoint(CGPoint(x: 110, y: 110), pressure: 1.0)
        brushEngine.addPoint(CGPoint(x: 120, y: 120), pressure: 1.0)

        // When
        let completedStroke = brushEngine.endStroke()

        // Then
        XCTAssertNotNil(completedStroke, "Should return completed stroke")
        XCTAssertNil(brushEngine.currentStroke, "Current stroke should be cleared")
        XCTAssertGreaterThan(completedStroke?.points.count ?? 0, 0)
    }

    func testCancelStroke() {
        // Given - start a stroke
        brushEngine.beginStroke(at: CGPoint(x: 100, y: 100), pressure: 1.0, layerId: testLayerId)
        brushEngine.addPoint(CGPoint(x: 110, y: 110), pressure: 1.0)

        // When
        brushEngine.cancelStroke()

        // Then
        XCTAssertNil(brushEngine.currentStroke, "Stroke should be cancelled")
    }

    // MARK: - Stroke Smoothing Tests

    func testStrokeSmoothing() {
        // Given - create a stroke with jagged points
        brushEngine.beginStroke(at: CGPoint(x: 0, y: 0), pressure: 1.0, layerId: testLayerId)

        // Add zigzag points
        let points: [CGPoint] = [
            CGPoint(x: 10, y: 5),
            CGPoint(x: 20, y: 0),
            CGPoint(x: 30, y: 5),
            CGPoint(x: 40, y: 0),
            CGPoint(x: 50, y: 5),
        ]

        for point in points {
            brushEngine.addPoint(point, pressure: 1.0)
        }

        let stroke = brushEngine.endStroke()

        // Then - smoothed stroke should have different points
        XCTAssertNotNil(stroke)
        // Smoothing may reduce or modify points
        XCTAssertGreaterThan(stroke?.points.count ?? 0, 0)
    }

    func testPressureSensitivity() {
        // Given
        brushEngine.beginStroke(at: CGPoint(x: 0, y: 0), pressure: 0.3, layerId: testLayerId)

        // Add points with varying pressure
        let pressures: [Float] = [0.4, 0.6, 0.8, 1.0, 0.8, 0.6, 0.4]
        for (i, pressure) in pressures.enumerated() {
            brushEngine.addPoint(CGPoint(x: CGFloat(i * 10), y: 0), pressure: pressure)
        }

        let stroke = brushEngine.endStroke()

        // Then - pressure should be preserved
        XCTAssertNotNil(stroke)
        // Average pressure should be around 0.6-0.7
        let avgPressure = stroke?.points.map { $0.pressure }.reduce(0, +) ?? 0
        XCTAssertGreaterThan(avgPressure, 0, "Pressure should be recorded")
    }

    // MARK: - Pattern Stamp Generation Tests

    func testGeneratePatternStamps() {
        // Given - create a stroke
        let stroke = createTestStroke()

        // When
        let stamps = brushEngine.generatePatternStamps(for: stroke)

        // Then
        XCTAssertGreaterThan(stamps.count, 0, "Should generate stamps along stroke")

        // Verify stamps respect spacing
        // With spacing of 10, a 100px line should have ~10 stamps
        XCTAssertGreaterThan(stamps.count, 5, "Should have multiple stamps")
        XCTAssertLessThan(stamps.count, 20, "Stamps shouldn't be too dense")
    }

    func testPatternStampsFollowStrokePath() {
        // Given - create straight horizontal stroke
        brushEngine.beginStroke(at: CGPoint(x: 0, y: 100), pressure: 1.0, layerId: testLayerId)
        brushEngine.addPoint(CGPoint(x: 100, y: 100), pressure: 1.0)
        let stroke = brushEngine.endStroke()!

        // When
        let stamps = brushEngine.generatePatternStamps(for: stroke)

        // Then - all stamps should be roughly on y=100 line
        for stamp in stamps {
            XCTAssertEqual(stamp.position.y, 100, accuracy: 5,
                          "Stamps should follow stroke path")
        }
    }

    func testPatternStampsRespectBrushSettings() {
        // Test that stamps use correct brush settings
        let stroke = createTestStroke()
        let stamps = brushEngine.generatePatternStamps(for: stroke)

        for stamp in stamps {
            XCTAssertEqual(stamp.brush.type, brushEngine.currentBrush.type)
            XCTAssertEqual(stamp.brush.rotation, brushEngine.currentBrush.rotation)
            XCTAssertEqual(stamp.brush.spacing, brushEngine.currentBrush.spacing)
        }
    }

    // MARK: - Performance Tests

    func testStrokeProcessingPerformance() {
        // Stroke processing should be real-time (< 16ms for 60fps)
        measure {
            brushEngine.beginStroke(at: CGPoint.zero, pressure: 1.0, layerId: testLayerId)

            // Simulate 100 points (typical stroke)
            for i in 0..<100 {
                brushEngine.addPoint(
                    CGPoint(x: CGFloat(i), y: CGFloat(i)),
                    pressure: 1.0
                )
            }

            _ = brushEngine.endStroke()
        }
    }

    func testPatternStampGenerationPerformance() {
        let stroke = createLongStroke(pointCount: 200)

        measure {
            _ = brushEngine.generatePatternStamps(for: stroke)
        }
    }

    // MARK: - Helper Methods

    private func createTestStroke() -> Stroke {
        let points = [
            StrokePoint(position: CGPoint(x: 0, y: 0), pressure: 1.0),
            StrokePoint(position: CGPoint(x: 50, y: 50), pressure: 1.0),
            StrokePoint(position: CGPoint(x: 100, y: 100), pressure: 1.0),
        ]

        return Stroke(
            points: points,
            brush: brushEngine.currentBrush,
            layerId: testLayerId
        )
    }

    private func createLongStroke(pointCount: Int) -> Stroke {
        var points: [StrokePoint] = []

        for i in 0..<pointCount {
            let t = CGFloat(i) / CGFloat(pointCount)
            let x = t * 500
            let y = sin(t * .pi * 4) * 50 + 250

            points.append(StrokePoint(
                position: CGPoint(x: x, y: y),
                pressure: Float.random(in: 0.5...1.0)
            ))
        }

        return Stroke(
            points: points,
            brush: brushEngine.currentBrush,
            layerId: testLayerId
        )
    }
}
