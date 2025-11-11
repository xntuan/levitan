//
//  EnhancedBrushEngine.swift
//  Ink - Pattern Drawing App
//
//  Industry-standard brush engine with professional features
//  Features: Stabilization, Prediction, Dynamics, Pressure Curves
//  Created on November 10, 2025.
//

import CoreGraphics
import Metal
import simd

// MARK: - Brush Configuration

/// Advanced brush configuration with industry-standard features
struct BrushConfiguration {
    // Basic settings
    var patternBrush: PatternBrush
    var isEraserMode: Bool = false  // When true, erases instead of drawing

    // Stabilization (0-100)
    var stabilization: Float = 30.0  // 0 = none, 100 = maximum smoothing

    // Stroke prediction (0-100)
    var prediction: Float = 50.0  // Predictive stroke rendering

    // Dynamics
    var velocityDynamics: VelocityDynamics = VelocityDynamics()
    var pressureCurve: PressureCurve = PressureCurve()
    var jitter: BrushJitter = BrushJitter()

    // Spacing
    var adaptiveSpacing: Bool = true  // Adjust spacing based on velocity
    var minimumDistance: Float = 2.0  // Minimum pixels between stamps

    // Flow
    var flow: Float = 1.0  // 0-1, affects build-up

    // Tilt (Apple Pencil)
    var tiltDynamics: TiltDynamics = TiltDynamics()

    // Rotation (Apple Pencil azimuth)
    var rotationDynamics: RotationDynamics = RotationDynamics()

    struct TiltDynamics {
        var enabled: Bool = false
        var affectsSize: Bool = true
        var affectsOpacity: Bool = false
        var sizeSensitivity: Float = 0.5   // 0-1, how much tilt affects size
        var opacitySensitivity: Float = 0.3  // 0-1, how much tilt affects opacity
        var minimumTilt: Float = 0.0   // 0-90°, angle below which max effect
        var maximumTilt: Float = 90.0  // 0-90°, angle above which no effect
    }

    struct RotationDynamics {
        var mode: RotationMode = .manual
        var fixedRotation: Float = 45.0  // Used when mode is .fixed (0-360°)
        var smoothing: Float = 0.3       // 0-1, exponential smoothing for azimuth changes

        enum RotationMode: String, Codable {
            case manual         // No automatic rotation, use PatternBrush.rotation
            case fixed          // Use fixedRotation value
            case followAzimuth  // Rotate to follow Apple Pencil direction
        }
    }

    struct VelocityDynamics {
        var enabled: Bool = true
        var sizeMin: Float = 0.7   // Size multiplier at high velocity
        var sizeMax: Float = 1.3   // Size multiplier at low velocity
        var opacityMin: Float = 0.8  // Opacity at high velocity
        var opacityMax: Float = 1.0  // Opacity at low velocity
        var velocityRange: Float = 1000.0  // Velocity range in pixels/second
    }

    struct PressureCurve {
        var enabled: Bool = true
        var curveType: CurveType = .linear
        var minimum: Float = 0.1   // Minimum pressure output
        var maximum: Float = 1.0   // Maximum pressure output

        enum CurveType {
            case linear
            case easeIn      // Soft start
            case easeOut     // Soft end
            case easeInOut   // Soft both ends
            case custom([Float])  // Custom curve with 11 points (0%, 10%, ..., 100%)
        }

        func apply(_ pressure: Float) -> Float {
            guard enabled else { return pressure }

            let normalized = max(0, min(1, pressure))
            let curved: Float

            switch curveType {
            case .linear:
                curved = normalized

            case .easeIn:
                curved = normalized * normalized

            case .easeOut:
                curved = 1 - (1 - normalized) * (1 - normalized)

            case .easeInOut:
                if normalized < 0.5 {
                    curved = 2 * normalized * normalized
                } else {
                    let t = normalized - 0.5
                    curved = 0.5 + 2 * t * (1 - 0.5 * t)
                }

            case .custom(let points):
                // Interpolate through custom curve
                let index = normalized * Float(points.count - 1)
                let i0 = Int(floor(index))
                let i1 = min(i0 + 1, points.count - 1)
                let t = index - Float(i0)
                curved = points[i0] * (1 - t) + points[i1] * t
            }

            return minimum + curved * (maximum - minimum)
        }
    }

    struct BrushJitter {
        var enabled: Bool = false
        var sizeJitter: Float = 0.0    // 0-1, random size variation
        var rotationJitter: Float = 0.0  // 0-360, random rotation variation
        var opacityJitter: Float = 0.0  // 0-1, random opacity variation
        var positionJitter: Float = 0.0  // pixels, random position scatter
    }
}

// MARK: - Enhanced Brush Engine

class EnhancedBrushEngine {

    // MARK: - Properties

    var config: BrushConfiguration
    private(set) var currentStroke: Stroke?

    // Stroke data
    private var rawPoints: [StrokePoint] = []
    private var smoothedPoints: [StrokePoint] = []
    private var predictedPoints: [StrokePoint] = []

    // Stabilization state
    private var stabilizationBuffer: [StrokePoint] = []
    private let maxStabilizationBuffer = 20

    // Velocity tracking
    private var velocityWindow: [(point: CGPoint, time: TimeInterval)] = []
    private let velocityWindowSize = 5

    // Azimuth tracking (for rotation smoothing)
    private var smoothedAzimuth: Float?

    // Last stamp tracking
    private var lastStampPosition: CGPoint?
    private var distanceSinceLastStamp: CGFloat = 0

    // Performance
    private var rng = SystemRandomNumberGenerator()

    // MARK: - Initialization

    init(brush: PatternBrush) {
        self.config = BrushConfiguration(patternBrush: brush)
    }

    init(configuration: BrushConfiguration) {
        self.config = configuration
    }

    // MARK: - Stroke Management

    func beginStroke(at point: CGPoint, pressure: Float = 1.0, layerId: UUID, tiltAngle: Float? = nil, azimuthAngle: Float? = nil) {
        let timestamp = Date().timeIntervalSince1970
        let strokePoint = StrokePoint(
            position: point,
            pressure: pressure,
            timestamp: timestamp,
            tiltAngle: tiltAngle,
            azimuthAngle: azimuthAngle
        )

        currentStroke = Stroke(points: [strokePoint], brush: config.patternBrush, layerId: layerId, isEraserMode: config.isEraserMode)

        rawPoints = [strokePoint]
        smoothedPoints = [strokePoint]
        predictedPoints = []
        stabilizationBuffer = [strokePoint]
        velocityWindow = [(point, timestamp)]
        smoothedAzimuth = nil  // Reset azimuth smoothing for new stroke
        lastStampPosition = point
        distanceSinceLastStamp = 0

        print("🖌️ Enhanced brush stroke began")
    }

    func addPoint(_ point: CGPoint, pressure: Float = 1.0, tiltAngle: Float? = nil, azimuthAngle: Float? = nil) {
        guard var stroke = currentStroke else { return }

        let timestamp = Date().timeIntervalSince1970
        let strokePoint = StrokePoint(
            position: point,
            pressure: pressure,
            timestamp: timestamp,
            tiltAngle: tiltAngle,
            azimuthAngle: azimuthAngle
        )

        // Add to raw points
        rawPoints.append(strokePoint)

        // Update velocity window
        velocityWindow.append((point, timestamp))
        if velocityWindow.count > velocityWindowSize {
            velocityWindow.removeFirst()
        }

        // Apply stabilization
        let stabilized = applyStabilization(strokePoint)

        // Add to smoothed points
        smoothedPoints.append(stabilized)

        // Update stroke
        stroke.points = smoothedPoints
        currentStroke = stroke

        // Generate predictions
        if config.prediction > 0 {
            predictedPoints = generatePredictions()
        }
    }

    func endStroke() -> Stroke? {
        // Flush stabilization buffer
        if !stabilizationBuffer.isEmpty {
            smoothedPoints.append(contentsOf: stabilizationBuffer)
        }

        let completedStroke = currentStroke
        currentStroke = nil

        // Clear state
        rawPoints.removeAll()
        smoothedPoints.removeAll()
        predictedPoints.removeAll()
        stabilizationBuffer.removeAll()
        velocityWindow.removeAll()
        lastStampPosition = nil
        distanceSinceLastStamp = 0

        if let stroke = completedStroke {
            print("✅ Enhanced stroke completed: \(stroke.points.count) points")
        }

        return completedStroke
    }

    func cancelStroke() {
        currentStroke = nil
        rawPoints.removeAll()
        smoothedPoints.removeAll()
        predictedPoints.removeAll()
        stabilizationBuffer.removeAll()
        velocityWindow.removeAll()
        lastStampPosition = nil
    }

    // MARK: - Stabilization

    private func applyStabilization(_ point: StrokePoint) -> StrokePoint {
        guard config.stabilization > 0 else { return point }

        // Add to buffer
        stabilizationBuffer.append(point)
        if stabilizationBuffer.count > maxStabilizationBuffer {
            stabilizationBuffer.removeFirst()
        }

        // Calculate stabilization amount (0-1)
        let amount = config.stabilization / 100.0

        // Use exponential moving average for smoothing
        let windowSize = max(2, Int(amount * Float(maxStabilizationBuffer)))
        let recentPoints = stabilizationBuffer.suffix(min(windowSize, stabilizationBuffer.count))

        // Weighted average (more recent = more weight)
        var totalWeight: Float = 0
        var weightedX: CGFloat = 0
        var weightedY: CGFloat = 0
        var weightedPressure: Float = 0

        for (index, p) in recentPoints.enumerated() {
            let weight = Float(index + 1)  // Linear weighting
            totalWeight += weight
            weightedX += p.position.x * CGFloat(weight)
            weightedY += p.position.y * CGFloat(weight)
            weightedPressure += p.pressure * weight
        }

        let smoothedPosition = CGPoint(
            x: weightedX / CGFloat(totalWeight),
            y: weightedY / CGFloat(totalWeight)
        )
        let smoothedPressure = weightedPressure / totalWeight

        return StrokePoint(
            position: smoothedPosition,
            pressure: smoothedPressure,
            timestamp: point.timestamp
        )
    }

    // MARK: - Prediction

    private func generatePredictions() -> [StrokePoint] {
        guard smoothedPoints.count >= 3, config.prediction > 0 else {
            return []
        }

        let predictionStrength = config.prediction / 100.0
        let predictionCount = max(1, Int(predictionStrength * 5))

        var predictions: [StrokePoint] = []

        // Use last 3 points to extrapolate
        let count = smoothedPoints.count
        let p0 = smoothedPoints[count - 3]
        let p1 = smoothedPoints[count - 2]
        let p2 = smoothedPoints[count - 1]

        // Calculate velocity vector
        let v1 = simd_float2(Float(p1.position.x - p0.position.x), Float(p1.position.y - p0.position.y))
        let v2 = simd_float2(Float(p2.position.x - p1.position.x), Float(p2.position.y - p1.position.y))

        // Average velocity with slight acceleration
        let avgVelocity = (v1 + v2 * 1.2) / 2.0

        // Generate predicted points
        for i in 1...predictionCount {
            let t = Float(i) * 0.5  // Time step
            let predicted = simd_float2(Float(p2.position.x), Float(p2.position.y)) + avgVelocity * t

            // Fade out pressure for predictions
            let pressureFade = 1.0 - (Float(i) / Float(predictionCount)) * 0.5

            predictions.append(StrokePoint(
                position: CGPoint(x: CGFloat(predicted.x), y: CGFloat(predicted.y)),
                pressure: p2.pressure * pressureFade,
                timestamp: p2.timestamp
            ))
        }

        return predictions
    }

    // MARK: - Pattern Generation with Dynamics

    func generatePatternStamps(for stroke: Stroke) -> [PatternStamp] {
        var stamps: [PatternStamp] = []
        guard stroke.points.count >= 2 else { return stamps }

        // Use combined points (smoothed + predicted)
        let allPoints = smoothedPoints + predictedPoints

        // Calculate spacing
        let baseSpacing = CGFloat(config.patternBrush.spacing)

        var distanceTraveled: CGFloat = 0
        var lastStampDistance: CGFloat = 0

        for i in 1..<allPoints.count {
            let p0 = allPoints[i - 1]
            let p1 = allPoints[i]

            // Calculate velocity for this segment
            let velocity = calculateVelocity(at: i, in: allPoints)

            // Adjust spacing based on velocity if enabled
            let spacing: CGFloat
            if config.adaptiveSpacing && velocity > 0 {
                // Faster = more spacing (for performance and natural look)
                let velocityFactor = min(2.0, max(0.5, velocity / 500.0))
                spacing = baseSpacing * velocityFactor
            } else {
                spacing = baseSpacing
            }

            let segmentDistance = distance(from: p0.position, to: p1.position)
            distanceTraveled += segmentDistance

            // Place stamps along segment
            while distanceTraveled - lastStampDistance >= spacing {
                lastStampDistance += spacing

                // Check minimum distance
                if lastStampDistance - CGFloat(config.minimumDistance) < 0 {
                    continue
                }

                let t = (lastStampDistance - (distanceTraveled - segmentDistance)) / segmentDistance
                var position = interpolate(from: p0.position, to: p1.position, t: t)

                // Interpolate pressure
                let pressure = p0.pressure * Float(1 - t) + p1.pressure * Float(t)

                // Apply pressure curve
                let curvedPressure = config.pressureCurve.apply(pressure)

                // Interpolate tilt angle (if available)
                let tiltAngle: Float?
                if let tilt0 = p0.tiltAngle, let tilt1 = p1.tiltAngle {
                    tiltAngle = tilt0 * Float(1 - t) + tilt1 * Float(t)
                } else {
                    tiltAngle = p0.tiltAngle ?? p1.tiltAngle
                }

                // Interpolate azimuth angle (if available)
                let azimuthAngle: Float?
                if let azimuth0 = p0.azimuthAngle, let azimuth1 = p1.azimuthAngle {
                    azimuthAngle = azimuth0 * Float(1 - t) + azimuth1 * Float(t)
                } else {
                    azimuthAngle = p0.azimuthAngle ?? p1.azimuthAngle
                }

                // Calculate velocity dynamics
                let velocityMultipliers = calculateVelocityDynamics(velocity: velocity)

                // Calculate tilt dynamics
                let tiltMultipliers = calculateTiltDynamics(tiltAngle: tiltAngle)

                // Apply jitter
                if config.jitter.enabled {
                    position = applyPositionJitter(position)
                }

                // Create modified brush with dynamics
                var dynamicBrush = config.patternBrush

                // Apply velocity size and tilt
                dynamicBrush.scale *= velocityMultipliers.size * tiltMultipliers.size

                // Calculate rotation based on mode (manual, fixed, or azimuth)
                dynamicBrush.rotation = calculateRotation(azimuthAngle: azimuthAngle)

                // Apply jitter
                if config.jitter.enabled {
                    dynamicBrush.scale *= applyScaleJitter()
                    dynamicBrush.rotation += applyRotationJitter()
                    dynamicBrush.opacity *= velocityMultipliers.opacity * tiltMultipliers.opacity * applyOpacityJitter()
                } else {
                    dynamicBrush.opacity *= velocityMultipliers.opacity * tiltMultipliers.opacity
                }

                // Apply flow
                dynamicBrush.opacity *= config.flow

                stamps.append(PatternStamp(
                    position: position,
                    brush: dynamicBrush,
                    pressure: curvedPressure
                ))
            }
        }

        return stamps
    }

    // MARK: - Dynamics Calculations

    private func calculateVelocity(at index: Int, in points: [StrokePoint]) -> CGFloat {
        guard index > 0 else { return 0 }

        let p0 = points[index - 1]
        let p1 = points[index]

        let distance = self.distance(from: p0.position, to: p1.position)
        let timeDelta = p1.timestamp - p0.timestamp

        guard timeDelta > 0 else { return 0 }

        // Velocity in pixels per second
        return distance / CGFloat(timeDelta)
    }

    private func calculateVelocityDynamics(velocity: CGFloat) -> (size: Float, opacity: Float) {
        guard config.velocityDynamics.enabled else {
            return (1.0, 1.0)
        }

        let dynamics = config.velocityDynamics

        // Normalize velocity (0 = slow, 1 = fast)
        let normalizedVelocity = min(1.0, Float(velocity) / dynamics.velocityRange)

        // Inverse for size (slower = bigger)
        let sizeMultiplier = dynamics.sizeMax - (dynamics.sizeMax - dynamics.sizeMin) * normalizedVelocity

        // Inverse for opacity (slower = more opaque)
        let opacityMultiplier = dynamics.opacityMax - (dynamics.opacityMax - dynamics.opacityMin) * normalizedVelocity

        return (sizeMultiplier, opacityMultiplier)
    }

    private func calculateTiltDynamics(tiltAngle: Float?) -> (size: Float, opacity: Float) {
        guard config.tiltDynamics.enabled,
              let tilt = tiltAngle else {
            return (1.0, 1.0)
        }

        let dynamics = config.tiltDynamics

        // Clamp tilt to configured range
        let clampedTilt = max(dynamics.minimumTilt, min(dynamics.maximumTilt, tilt))

        // Normalize tilt (0 = flat, 1 = perpendicular)
        // tilt is in degrees (0-90°)
        let tiltRange = dynamics.maximumTilt - dynamics.minimumTilt
        guard tiltRange > 0 else { return (1.0, 1.0) }

        let normalizedTilt = (clampedTilt - dynamics.minimumTilt) / tiltRange

        // Apply tilt effects
        var sizeMultiplier: Float = 1.0
        var opacityMultiplier: Float = 1.0

        if dynamics.affectsSize {
            // Flat pencil (0°) = full effect, perpendicular (90°) = no effect
            let tiltPercent = 1.0 - normalizedTilt
            sizeMultiplier = 1.0 - (tiltPercent * dynamics.sizeSensitivity)
            sizeMultiplier = max(0.1, sizeMultiplier) // Minimum 10% size
        }

        if dynamics.affectsOpacity {
            // Flat pencil (0°) = full effect, perpendicular (90°) = no effect
            let tiltPercent = 1.0 - normalizedTilt
            opacityMultiplier = 1.0 - (tiltPercent * dynamics.opacitySensitivity)
            opacityMultiplier = max(0.1, opacityMultiplier) // Minimum 10% opacity
        }

        return (sizeMultiplier, opacityMultiplier)
    }

    private func calculateRotation(azimuthAngle: Float?) -> Float {
        let dynamics = config.rotationDynamics

        switch dynamics.mode {
        case .manual:
            // Use the rotation from PatternBrush (no dynamic change)
            return config.patternBrush.rotation

        case .fixed:
            // Use fixed rotation value
            return dynamics.fixedRotation

        case .followAzimuth:
            // Rotate to follow Apple Pencil direction
            guard let azimuth = azimuthAngle else {
                return config.patternBrush.rotation
            }

            // Apply exponential smoothing to prevent jitter
            if let prevAzimuth = smoothedAzimuth {
                let alpha = 1.0 - dynamics.smoothing
                smoothedAzimuth = alpha * azimuth + dynamics.smoothing * prevAzimuth
            } else {
                smoothedAzimuth = azimuth
            }

            return smoothedAzimuth ?? azimuth
        }
    }

    // MARK: - Jitter

    private func applyPositionJitter(_ position: CGPoint) -> CGPoint {
        guard config.jitter.positionJitter > 0 else { return position }

        let jitterAmount = CGFloat(config.jitter.positionJitter)
        let randomX = CGFloat.random(in: -jitterAmount...jitterAmount, using: &rng)
        let randomY = CGFloat.random(in: -jitterAmount...jitterAmount, using: &rng)

        return CGPoint(x: position.x + randomX, y: position.y + randomY)
    }

    private func applyScaleJitter() -> Float {
        guard config.jitter.sizeJitter > 0 else { return 1.0 }

        let variation = Float.random(in: -config.jitter.sizeJitter...config.jitter.sizeJitter, using: &rng)
        return 1.0 + variation
    }

    private func applyRotationJitter() -> Float {
        guard config.jitter.rotationJitter > 0 else { return 0 }

        return Float.random(in: -config.jitter.rotationJitter...config.jitter.rotationJitter, using: &rng)
    }

    private func applyOpacityJitter() -> Float {
        guard config.jitter.opacityJitter > 0 else { return 1.0 }

        let variation = Float.random(in: -config.jitter.opacityJitter...config.jitter.opacityJitter, using: &rng)
        return max(0, min(1, 1.0 + variation))
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

// MARK: - Preset Configurations

extension BrushConfiguration {
    /// Smooth and stable, great for detailed work
    static var precise: BrushConfiguration {
        var config = BrushConfiguration(patternBrush: PatternBrush())
        config.stabilization = 60
        config.prediction = 30
        config.velocityDynamics.enabled = true
        config.minimumDistance = 3.0
        return config
    }

    /// Fast and responsive, minimal processing
    static var sketchy: BrushConfiguration {
        var config = BrushConfiguration(patternBrush: PatternBrush())
        config.stabilization = 10
        config.prediction = 70
        config.velocityDynamics.enabled = true
        config.velocityDynamics.sizeMin = 0.5
        config.velocityDynamics.sizeMax = 1.5
        config.jitter.enabled = true
        config.jitter.rotationJitter = 15
        config.adaptiveSpacing = true
        return config
    }

    /// Organic and natural, with pressure sensitivity
    static var natural: BrushConfiguration {
        var config = BrushConfiguration(patternBrush: PatternBrush())
        config.stabilization = 30
        config.prediction = 50
        config.pressureCurve.curveType = .easeInOut
        config.velocityDynamics.enabled = true
        config.jitter.enabled = true
        config.jitter.sizeJitter = 0.1
        config.jitter.opacityJitter = 0.1
        return config
    }

    /// Smooth and flowing, like ink
    static var ink: BrushConfiguration {
        var config = BrushConfiguration(patternBrush: PatternBrush())
        config.stabilization = 80
        config.prediction = 20
        config.pressureCurve.curveType = .easeOut
        config.velocityDynamics.enabled = true
        config.velocityDynamics.opacityMin = 0.6
        config.flow = 0.8
        return config
    }
}
