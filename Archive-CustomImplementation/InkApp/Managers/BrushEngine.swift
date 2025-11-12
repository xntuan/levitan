//
//  BrushEngine.swift
//  Ink - Pattern Drawing App
//
//  Core drawing engine that converts strokes to patterns
//  Created on November 10, 2025.
//

import CoreGraphics
import Metal

class BrushEngine {

    // MARK: - Properties
    var currentBrush: PatternBrush
    var currentStroke: Stroke?

    // Stroke smoothing
    private var strokeBuffer: [StrokePoint] = []
    private let smoothingWindowSize = 5

    // MARK: - Initialization
    init(brush: PatternBrush = PatternBrush()) {
        self.currentBrush = brush
    }

    // MARK: - Stroke Management

    /// Begin a new stroke
    func beginStroke(at point: CGPoint, pressure: Float = 1.0, layerId: UUID) {
        let strokePoint = StrokePoint(position: point, pressure: pressure)
        currentStroke = Stroke(points: [strokePoint], brush: currentBrush, layerId: layerId)
        strokeBuffer = [strokePoint]
    }

    /// Add point to current stroke
    func addPoint(_ point: CGPoint, pressure: Float = 1.0) {
        guard var stroke = currentStroke else { return }

        let strokePoint = StrokePoint(position: point, pressure: pressure)
        strokeBuffer.append(strokePoint)

        // Smooth the stroke
        if strokeBuffer.count >= smoothingWindowSize {
            let smoothedPoint = smoothPoint()
            stroke.points.append(smoothedPoint)
            currentStroke = stroke

            // Keep only recent points for smoothing
            if strokeBuffer.count > smoothingWindowSize * 2 {
                strokeBuffer.removeFirst()
            }
        }
    }

    /// End current stroke
    func endStroke() -> Stroke? {
        // Add remaining points
        if let stroke = currentStroke, !strokeBuffer.isEmpty {
            var finalStroke = stroke
            finalStroke.points.append(contentsOf: strokeBuffer)
            strokeBuffer.removeAll()
            currentStroke = nil
            return finalStroke
        }

        let completedStroke = currentStroke
        currentStroke = nil
        strokeBuffer.removeAll()
        return completedStroke
    }

    /// Cancel current stroke
    func cancelStroke() {
        currentStroke = nil
        strokeBuffer.removeAll()
    }

    // MARK: - Stroke Smoothing (Catmull-Rom)

    private func smoothPoint() -> StrokePoint {
        guard strokeBuffer.count >= 4 else {
            return strokeBuffer.last ?? StrokePoint(position: .zero)
        }

        let count = strokeBuffer.count
        let p0 = strokeBuffer[count - 4].position
        let p1 = strokeBuffer[count - 3].position
        let p2 = strokeBuffer[count - 2].position
        let p3 = strokeBuffer[count - 1].position

        // Catmull-Rom spline interpolation (t = 0.5 for middle point)
        let t: CGFloat = 0.5
        let t2 = t * t
        let t3 = t2 * t

        let x = 0.5 * ((2 * p1.x) +
                       (-p0.x + p2.x) * t +
                       (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 +
                       (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3)

        let y = 0.5 * ((2 * p1.y) +
                       (-p0.y + p2.y) * t +
                       (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 +
                       (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3)

        // Average pressure
        let avgPressure = strokeBuffer.suffix(smoothingWindowSize)
            .map { $0.pressure }
            .reduce(0, +) / Float(smoothingWindowSize)

        return StrokePoint(position: CGPoint(x: x, y: y), pressure: avgPressure)
    }

    // MARK: - Pattern Generation

    /// Generate pattern stamps along a stroke
    func generatePatternStamps(for stroke: Stroke) -> [PatternStamp] {
        var stamps: [PatternStamp] = []
        guard stroke.points.count >= 2 else { return stamps }

        let spacing = CGFloat(stroke.brush.spacing)
        var distanceTraveled: CGFloat = 0
        var lastStampDistance: CGFloat = 0

        for i in 1..<stroke.points.count {
            let p0 = stroke.points[i - 1].position
            let p1 = stroke.points[i].position
            let pressure = stroke.points[i].pressure

            let segmentDistance = distance(from: p0, to: p1)
            distanceTraveled += segmentDistance

            // Place stamps along segment
            while distanceTraveled - lastStampDistance >= spacing {
                lastStampDistance += spacing
                let t = (lastStampDistance - (distanceTraveled - segmentDistance)) / segmentDistance
                let position = interpolate(from: p0, to: p1, t: t)

                stamps.append(PatternStamp(
                    position: position,
                    brush: stroke.brush,
                    pressure: pressure,
                    isEraserMode: stroke.isEraserMode
                ))
            }
        }

        return stamps
    }

    // MARK: - Helper Methods

    private func distance(from p0: CGPoint, to p1: CGPoint) -> CGFloat {
        let dx = p1.x - p0.x
        let dy = p1.y - p0.y
        return sqrt(dx * dx + dy * dy)
    }

    private func interpolate(from p0: CGPoint, to p1: CGPoint, t: CGFloat) -> CGPoint {
        return CGPoint(
            x: p0.x + (p1.x - p0.x) * t,
            y: p0.y + (p1.y - p0.y) * t
        )
    }
}

// MARK: - Pattern Stamp

/// Represents a single pattern stamp to be rendered
struct PatternStamp {
    let position: CGPoint
    let brush: PatternBrush
    let pressure: Float
    let isEraserMode: Bool  // When true, erases instead of drawing
}
