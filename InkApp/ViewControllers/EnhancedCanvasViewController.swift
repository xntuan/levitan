//
//  EnhancedCanvasViewController.swift
//  Ink - Pattern Drawing App
//
//  Enhanced canvas with full drawing integration
//  Created on November 10, 2025.
//

import UIKit
import MetalKit

class EnhancedCanvasViewController: UIViewController {

    // MARK: - Properties

    // View
    var metalView: MTKView!

    // Managers and Engine
    var renderer: EnhancedMetalRenderer!
    var layerManager: LayerManager!
    var brushEngine: BrushEngine!

    // Canvas state
    var canvasSize: CGSize = CGSize(width: 2048, height: 2048)
    var zoom: CGFloat = 1.0
    var offset: CGPoint = .zero

    // Drawing state
    var isDrawing = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupManagers()
        setupMetalView()
        setupGestures()
        setupTestEnvironment()
    }

    // MARK: - Setup

    private func setupManagers() {
        // Initialize layer manager with test layers
        layerManager = LayerManager()

        // Create test layers
        let layer1 = Layer(name: "Sky", opacity: 1.0)
        let layer2 = Layer(name: "Mountains", opacity: 1.0)
        let layer3 = Layer(name: "Water", opacity: 1.0)

        layerManager.addLayer(layer1)
        layerManager.addLayer(layer2)
        layerManager.addLayer(layer3)

        // Select first layer
        layerManager.selectLayer(at: 0)

        // Initialize brush engine with default brush
        let defaultBrush = PatternBrush(
            type: .parallelLines,
            rotation: 45,
            spacing: 10,
            opacity: 0.8,
            scale: 1.0
        )
        brushEngine = BrushEngine(brush: defaultBrush)
    }

    private func setupMetalView() {
        metalView = MTKView(frame: view.bounds)
        metalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(metalView)

        // Initialize enhanced renderer
        renderer = EnhancedMetalRenderer(metalView: metalView, layerManager: layerManager)

        // Configure view
        metalView.clearColor = MTLClearColor(red: 0.97, green: 0.98, blue: 0.98, alpha: 1)
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.framebufferOnly = false // Allow texture reading
    }

    private func setupGestures() {
        // Pinch to zoom
        let pinch = UIPinchGestureRecognizer(
            target: self,
            action: #selector(handlePinch(_:))
        )
        metalView.addGestureRecognizer(pinch)

        // Two-finger pan
        let pan = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePan(_:))
        )
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        metalView.addGestureRecognizer(pan)
    }

    private func setupTestEnvironment() {
        // Add test UI for debugging
        addDebugInfo()
        addBrushSelector()
    }

    // MARK: - Gesture Handlers

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard gesture.state == .changed else { return }

        let newZoom = zoom * gesture.scale
        zoom = max(0.5, min(4.0, newZoom))
        gesture.scale = 1.0

        print("Zoom: \(String(format: "%.2f", zoom))×")
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state == .changed else { return }

        let translation = gesture.translation(in: metalView)
        offset.x += translation.x
        offset.y += translation.y
        gesture.setTranslation(.zero, in: metalView)

        print("Offset: (\(Int(offset.x)), \(Int(offset.y)))")
    }

    // MARK: - Touch Handling (Drawing)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Don't draw with two fingers (that's pan gesture)
        guard touches.count == 1,
              let touch = touches.first,
              let activeLayer = layerManager.activeLayer else {
            return
        }

        // Check if layer is locked
        if activeLayer.isLocked {
            print("Layer '\(activeLayer.name)' is locked!")
            return
        }

        let point = touch.location(in: metalView)
        let canvasPoint = viewToCanvasPoint(point)
        let pressure = touch.force > 0 ? Float(touch.force / touch.maximumPossibleForce) : 1.0

        // Begin stroke
        brushEngine.beginStroke(at: canvasPoint, pressure: pressure, layerId: activeLayer.id)
        isDrawing = true

        print("✏️ Drawing started on layer '\(activeLayer.name)' at \(canvasPoint)")
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawing,
              touches.count == 1,
              let touch = touches.first else {
            return
        }

        let point = touch.location(in: metalView)
        let canvasPoint = viewToCanvasPoint(point)
        let pressure = touch.force > 0 ? Float(touch.force / touch.maximumPossibleForce) : 1.0

        // Add point to stroke
        brushEngine.addPoint(canvasPoint, pressure: pressure)

        // Real-time rendering: draw pattern stamps
        if let currentStroke = brushEngine.currentStroke {
            let stamps = brushEngine.generatePatternStamps(for: currentStroke)

            // Draw only recent stamps (last 5 for performance)
            let recentStamps = Array(stamps.suffix(5))
            renderer.drawPatternStamps(recentStamps)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawing else { return }

        // End stroke
        if let completedStroke = brushEngine.endStroke() {
            // Generate all pattern stamps
            let stamps = brushEngine.generatePatternStamps(for: completedStroke)

            // Render to layer
            renderer.drawPatternStamps(stamps)

            print("✅ Stroke completed with \(completedStroke.points.count) points, \(stamps.count) stamps")
        }

        isDrawing = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isDrawing {
            brushEngine.cancelStroke()
            isDrawing = false
            print("❌ Stroke cancelled")
        }
    }

    // MARK: - Coordinate Conversion

    /// Convert view coordinates to canvas coordinates
    private func viewToCanvasPoint(_ viewPoint: CGPoint) -> CGPoint {
        // Account for zoom and offset
        let x = (viewPoint.x - offset.x) / zoom
        let y = (viewPoint.y - offset.y) / zoom

        // Map to canvas size
        let canvasX = (x / metalView.bounds.width) * canvasSize.width
        let canvasY = (y / metalView.bounds.height) * canvasSize.height

        return CGPoint(x: canvasX, y: canvasY)
    }

    // MARK: - Brush Control

    func changeBrush(type: PatternBrush.PatternType) {
        brushEngine.currentBrush.type = type
        print("🖌️ Brush changed to: \(type)")
    }

    func changeBrushRotation(_ degrees: Float) {
        brushEngine.currentBrush.rotation = degrees
        print("🔄 Brush rotation: \(degrees)°")
    }

    func changeBrushSpacing(_ spacing: Float) {
        brushEngine.currentBrush.spacing = spacing
        print("📏 Brush spacing: \(spacing)px")
    }

    // MARK: - Layer Control

    func selectLayer(at index: Int) {
        layerManager.selectLayer(at: index)
        if let layer = layerManager.activeLayer {
            print("📄 Selected layer: '\(layer.name)'")
        }
    }

    func toggleLayerVisibility(at index: Int) {
        layerManager.toggleLayerVisibility(at: index)
        let layer = layerManager.layers[index]
        print("👁️ Layer '\(layer.name)' visibility: \(layer.isVisible)")
    }

    func clearCurrentLayer() {
        renderer.clearActiveLayer()
        if let layer = layerManager.activeLayer {
            print("🗑️ Cleared layer: '\(layer.name)'")
        }
    }

    // MARK: - Debug UI

    private func addDebugInfo() {
        let label = UILabel()
        label.frame = CGRect(x: 20, y: 50, width: 300, height: 100)
        label.numberOfLines = 0
        label.font = DesignTokens.Typography.systemFont(
            size: DesignTokens.Typography.bodySmall,
            weight: DesignTokens.Typography.regular
        )
        label.textColor = DesignTokens.Colors.textSecondary
        label.backgroundColor = DesignTokens.Colors.surface.withAlphaComponent(0.8)
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.textAlignment = .left

        label.text = """
        🎨 Ink Drawing App
        📄 Layer: Sky
        🖌️ Brush: Parallel Lines
        👆 Tap to draw
        """

        view.addSubview(label)
    }

    private func addBrushSelector() {
        let buttonHeight: CGFloat = 44
        let spacing: CGFloat = 8
        let brushTypes: [PatternBrush.PatternType] = [
            .parallelLines, .crossHatch, .dots, .contourLines, .waves
        ]

        for (index, brushType) in brushTypes.enumerated() {
            let button = UIButton(type: .system)
            button.frame = CGRect(
                x: 20,
                y: 180 + CGFloat(index) * (buttonHeight + spacing),
                width: 150,
                height: buttonHeight
            )
            button.setTitle(buttonName(for: brushType), for: .normal)
            button.backgroundColor = DesignTokens.Colors.surface
            button.setTitleColor(DesignTokens.Colors.inkPrimary, for: .normal)
            button.layer.cornerRadius = 8
            button.tag = index

            button.addTarget(self, action: #selector(brushButtonTapped(_:)), for: .touchUpInside)

            view.addSubview(button)
        }
    }

    @objc private func brushButtonTapped(_ sender: UIButton) {
        let brushTypes: [PatternBrush.PatternType] = [
            .parallelLines, .crossHatch, .dots, .contourLines, .waves
        ]

        if sender.tag < brushTypes.count {
            changeBrush(type: brushTypes[sender.tag])
        }
    }

    private func buttonName(for brushType: PatternBrush.PatternType) -> String {
        switch brushType {
        case .parallelLines: return "∥ Lines"
        case .crossHatch: return "✖️ Cross-Hatch"
        case .dots: return "· Dots"
        case .contourLines: return "◯ Contour"
        case .waves: return "〜 Waves"
        }
    }
}
