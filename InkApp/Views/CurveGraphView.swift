//
//  CurveGraphView.swift
//  Ink - Pattern Drawing App
//
//  Interactive curve graph for pressure curve editing
//  Created on November 10, 2025.
//

import UIKit

protocol CurveGraphViewDelegate: AnyObject {
    func curveGraphView(_ graphView: CurveGraphView, didUpdateControlPoints points: [Float])
}

class CurveGraphView: UIView {

    // MARK: - Properties

    weak var delegate: CurveGraphViewDelegate?

    // Control points (11 points from 0% to 100% in 10% increments)
    private var controlPoints: [Float] = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]

    // Dragging state
    private var draggingPointIndex: Int?
    private var controlPointViews: [UIView] = []

    // Visual properties
    private let gridColor = UIColor.systemGray4
    private let curveColor = DesignTokens.Colors.inkPrimary
    private let controlPointSize: CGFloat = 20
    private let lineWidth: CGFloat = 3

    // Graph area (with padding)
    private var graphRect: CGRect {
        let padding: CGFloat = 40
        return bounds.inset(by: UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding))
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        createControlPointViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray5.cgColor

        // Add pan gesture for dragging control points
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }

    private func createControlPointViews() {
        // Create 11 control point views
        for _ in 0..<11 {
            let pointView = UIView()
            pointView.backgroundColor = curveColor
            pointView.layer.cornerRadius = controlPointSize / 2
            pointView.layer.borderWidth = 2
            pointView.layer.borderColor = UIColor.white.cgColor
            pointView.layer.shadowColor = UIColor.black.cgColor
            pointView.layer.shadowOpacity = 0.3
            pointView.layer.shadowOffset = CGSize(width: 0, height: 2)
            pointView.layer.shadowRadius = 4
            pointView.isUserInteractionEnabled = false

            addSubview(pointView)
            controlPointViews.append(pointView)
        }

        updateControlPointPositions()
    }

    // MARK: - Public Methods

    func setControlPoints(_ points: [Float]) {
        guard points.count == 11 else {
            print("⚠️ Control points must have exactly 11 values")
            return
        }

        controlPoints = points.map { max(0, min(1, $0)) }
        updateControlPointPositions()
        setNeedsDisplay()
    }

    func getControlPoints() -> [Float] {
        return controlPoints
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }

        // Draw grid
        drawGrid(in: context)

        // Draw axes labels
        drawLabels()

        // Draw curve
        drawCurve(in: context)
    }

    private func drawGrid(in context: CGContext) {
        context.setStrokeColor(gridColor.cgColor)
        context.setLineWidth(1)

        let rect = graphRect

        // Horizontal lines (5 lines at 0%, 25%, 50%, 75%, 100%)
        for i in 0...4 {
            let y = rect.minY + CGFloat(i) * rect.height / 4
            context.move(to: CGPoint(x: rect.minX, y: y))
            context.addLine(to: CGPoint(x: rect.maxX, y: y))
        }

        // Vertical lines (5 lines at 0%, 25%, 50%, 75%, 100%)
        for i in 0...4 {
            let x = rect.minX + CGFloat(i) * rect.width / 4
            context.move(to: CGPoint(x: x, y: rect.minY))
            context.addLine(to: CGPoint(x: x, y: rect.maxY))
        }

        context.strokePath()
    }

    private func drawLabels() {
        let rect = graphRect
        let font = UIFont.systemFont(ofSize: 10, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.systemGray
        ]

        // Y-axis labels (Output)
        for i in 0...4 {
            let value = 1.0 - Float(i) * 0.25
            let text = String(format: "%.2f", value)
            let y = rect.minY + CGFloat(i) * rect.height / 4 - 6

            let textSize = (text as NSString).size(withAttributes: attributes)
            let textRect = CGRect(
                x: rect.minX - textSize.width - 8,
                y: y,
                width: textSize.width,
                height: textSize.height
            )

            (text as NSString).draw(in: textRect, withAttributes: attributes)
        }

        // X-axis labels (Input)
        for i in 0...4 {
            let value = Float(i) * 0.25
            let text = String(format: "%.2f", value)
            let x = rect.minX + CGFloat(i) * rect.width / 4

            let textSize = (text as NSString).size(withAttributes: attributes)
            let textRect = CGRect(
                x: x - textSize.width / 2,
                y: rect.maxY + 8,
                width: textSize.width,
                height: textSize.height
            )

            (text as NSString).draw(in: textRect, withAttributes: attributes)
        }

        // Axis titles
        let titleFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.darkGray
        ]

        // "Output" label (rotated on left)
        let outputTitle = "Output"
        let outputSize = (outputTitle as NSString).size(withAttributes: titleAttributes)
        let outputRect = CGRect(
            x: 8,
            y: bounds.midY - outputSize.width / 2,
            width: outputSize.width,
            height: outputSize.height
        )

        // Rotate context for vertical text
        UIGraphicsGetCurrentContext()?.saveGState()
        UIGraphicsGetCurrentContext()?.translateBy(x: outputRect.midX, y: outputRect.midY)
        UIGraphicsGetCurrentContext()?.rotate(by: -.pi / 2)
        (outputTitle as NSString).draw(
            at: CGPoint(x: -outputSize.width / 2, y: -outputSize.height / 2),
            withAttributes: titleAttributes
        )
        UIGraphicsGetCurrentContext()?.restoreGState()

        // "Input" label (bottom)
        let inputTitle = "Input"
        let inputSize = (inputTitle as NSString).size(withAttributes: titleAttributes)
        let inputRect = CGRect(
            x: bounds.midX - inputSize.width / 2,
            y: bounds.height - 20,
            width: inputSize.width,
            height: inputSize.height
        )
        (inputTitle as NSString).draw(in: inputRect, withAttributes: titleAttributes)
    }

    private func drawCurve(in context: CGContext) {
        let rect = graphRect

        context.setStrokeColor(curveColor.cgColor)
        context.setLineWidth(lineWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        // Create path through all control points with cubic interpolation
        let path = CGMutablePath()

        let resolution = 50 // Points per segment
        var isFirst = true

        for segment in 0..<10 {
            let p0 = controlPoints[segment]
            let p1 = controlPoints[segment + 1]

            // Get control points for cubic Bezier (with clamping for edges)
            let p_1 = segment > 0 ? controlPoints[segment - 1] : p0
            let p2 = segment < 9 ? controlPoints[segment + 2] : p1

            // Generate smooth curve through this segment
            for i in 0...resolution {
                let t = Float(i) / Float(resolution)
                let x = (Float(segment) + t) / 10.0 // 0 to 1

                // Cubic interpolation
                let y = cubicInterpolate(p_1, p0, p1, p2, t)

                // Convert to screen coordinates
                let screenX = rect.minX + CGFloat(x) * rect.width
                let screenY = rect.maxY - CGFloat(y) * rect.height

                if isFirst {
                    path.move(to: CGPoint(x: screenX, y: screenY))
                    isFirst = false
                } else {
                    path.addLine(to: CGPoint(x: screenX, y: screenY))
                }
            }
        }

        context.addPath(path)
        context.strokePath()
    }

    private func cubicInterpolate(_ p0: Float, _ p1: Float, _ p2: Float, _ p3: Float, _ t: Float) -> Float {
        // Catmull-Rom spline
        let t2 = t * t
        let t3 = t2 * t

        let v0 = (p2 - p0) * 0.5
        let v1 = (p3 - p1) * 0.5

        return (2 * p1 - 2 * p2 + v0 + v1) * t3 +
               (-3 * p1 + 3 * p2 - 2 * v0 - v1) * t2 +
               v0 * t + p1
    }

    // MARK: - Control Point Management

    private func updateControlPointPositions() {
        let rect = graphRect

        for (index, value) in controlPoints.enumerated() {
            let x = rect.minX + CGFloat(index) / 10.0 * rect.width
            let y = rect.maxY - CGFloat(value) * rect.height

            let pointView = controlPointViews[index]
            pointView.frame = CGRect(
                x: x - controlPointSize / 2,
                y: y - controlPointSize / 2,
                width: controlPointSize,
                height: controlPointSize
            )
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        let rect = graphRect

        switch gesture.state {
        case .began:
            // Find nearest control point
            draggingPointIndex = findNearestControlPoint(at: location)

            if draggingPointIndex != nil {
                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()

                // Highlight dragging point
                if let index = draggingPointIndex {
                    UIView.animate(withDuration: 0.1) {
                        self.controlPointViews[index].transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                    }
                }
            }

        case .changed:
            guard let index = draggingPointIndex else { return }

            // Calculate new value based on Y position
            let normalizedY = 1.0 - ((location.y - rect.minY) / rect.height)
            let clampedY = max(0.0, min(1.0, normalizedY))

            // Update control point
            controlPoints[index] = Float(clampedY)

            // Update visual
            updateControlPointPositions()
            setNeedsDisplay()

            // Notify delegate
            delegate?.curveGraphView(self, didUpdateControlPoints: controlPoints)

        case .ended, .cancelled:
            // Reset highlight
            if let index = draggingPointIndex {
                UIView.animate(withDuration: 0.1) {
                    self.controlPointViews[index].transform = .identity
                }
            }

            draggingPointIndex = nil

        default:
            break
        }
    }

    private func findNearestControlPoint(at location: CGPoint) -> Int? {
        let threshold: CGFloat = 30 // Touch radius

        for (index, pointView) in controlPointViews.enumerated() {
            let distance = hypot(
                pointView.center.x - location.x,
                pointView.center.y - location.y
            )

            if distance < threshold {
                return index
            }
        }

        return nil
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        updateControlPointPositions()
        setNeedsDisplay()
    }
}
