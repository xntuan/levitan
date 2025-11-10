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
    var undoManager: DrawingUndoManager!

    // Canvas state
    var canvasSize: CGSize = CGSize(width: 2048, height: 2048)
    var zoom: CGFloat = 1.0
    var offset: CGPoint = .zero

    // Drawing state
    var isDrawing = false

    // UI elements
    private var brushButtons: [UIButton] = []
    private var selectedBrushIndex = 0
    private var debugLabel: UILabel?

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

        // Initialize undo manager
        undoManager = DrawingUndoManager(maxUndoLevels: 50)
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
        addUndoRedoButtons()
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
            showAlert("Layer '\(activeLayer.name)' is locked.\nUnlock it to draw.", title: "Layer Locked")
            print("⚠️ Layer '\(activeLayer.name)' is locked!")
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

            // Record for undo
            undoManager.recordStroke(completedStroke)

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
        #if DEBUG
        let label = UILabel()
        label.frame = CGRect(x: 20, y: 50, width: 300, height: 100)
        label.numberOfLines = 0
        label.font = DesignTokens.Typography.systemFont(
            size: DesignTokens.Typography.bodySmall,
            weight: DesignTokens.Typography.regular
        )
        label.textColor = DesignTokens.Colors.textSecondary
        label.backgroundColor = DesignTokens.Colors.surface.withAlphaComponent(0.9)
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.textAlignment = .left
        label.text = """
        🎨 Ink Drawing App
        📄 Layer: \(layerManager.activeLayer?.name ?? "None")
        🖌️ Brush: Parallel Lines
        👆 Tap to draw
        """

        debugLabel = label
        view.addSubview(label)
        #endif
    }

    private func updateDebugInfo() {
        #if DEBUG
        guard let label = debugLabel,
              let activeLayer = layerManager.activeLayer else { return }

        let brushName = buttonName(for: brushEngine.currentBrush.type)

        label.text = """
        🎨 Ink Drawing App
        📄 Layer: \(activeLayer.name)
        🖌️ Brush: \(brushName)
        👆 Tap to draw
        """
        #endif
    }

    private func addBrushSelector() {
        let buttonHeight: CGFloat = 44
        let spacing: CGFloat = 8
        let brushTypes: [PatternBrush.PatternType] = [
            .parallelLines, .crossHatch, .dots, .contourLines, .waves
        ]

        brushButtons.removeAll()

        for (index, brushType) in brushTypes.enumerated() {
            let button = UIButton(type: .system)
            button.frame = CGRect(
                x: 20,
                y: 180 + CGFloat(index) * (buttonHeight + spacing),
                width: 150,
                height: buttonHeight
            )
            button.setTitle(buttonName(for: brushType), for: .normal)
            button.layer.cornerRadius = 8
            button.tag = index

            // Set initial state
            if index == selectedBrushIndex {
                button.backgroundColor = DesignTokens.Colors.inkPrimary
                button.setTitleColor(.white, for: .normal)
            } else {
                button.backgroundColor = DesignTokens.Colors.surface
                button.setTitleColor(DesignTokens.Colors.inkPrimary, for: .normal)
            }

            button.addTarget(self, action: #selector(brushButtonTapped(_:)), for: .touchUpInside)

            brushButtons.append(button)
            view.addSubview(button)
        }
    }

    @objc private func brushButtonTapped(_ sender: UIButton) {
        let brushTypes: [PatternBrush.PatternType] = [
            .parallelLines, .crossHatch, .dots, .contourLines, .waves
        ]

        if sender.tag < brushTypes.count {
            selectedBrushIndex = sender.tag
            changeBrush(type: brushTypes[sender.tag])
            updateBrushButtonsUI()
            updateDebugInfo()
        }
    }

    private func updateBrushButtonsUI() {
        for (index, button) in brushButtons.enumerated() {
            UIView.animate(withDuration: DesignTokens.Animation.durationFast) {
                if index == self.selectedBrushIndex {
                    // Selected state
                    button.backgroundColor = DesignTokens.Colors.inkPrimary
                    button.setTitleColor(.white, for: .normal)
                    button.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                } else {
                    // Normal state
                    button.backgroundColor = DesignTokens.Colors.surface
                    button.setTitleColor(DesignTokens.Colors.inkPrimary, for: .normal)
                    button.transform = .identity
                }
            }
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

    // MARK: - Undo/Redo

    private func addUndoRedoButtons() {
        let buttonWidth: CGFloat = 80
        let buttonHeight: CGFloat = 44
        let spacing: CGFloat = 10

        // Undo button
        let undoButton = UIButton(type: .system)
        undoButton.frame = CGRect(
            x: view.bounds.width - (buttonWidth * 2 + spacing + 20),
            y: 50,
            width: buttonWidth,
            height: buttonHeight
        )
        undoButton.setTitle("⏮️ Undo", for: .normal)
        undoButton.backgroundColor = DesignTokens.Colors.surface
        undoButton.setTitleColor(DesignTokens.Colors.inkPrimary, for: .normal)
        undoButton.layer.cornerRadius = 8
        undoButton.addTarget(self, action: #selector(undoButtonTapped), for: .touchUpInside)
        view.addSubview(undoButton)

        // Redo button
        let redoButton = UIButton(type: .system)
        redoButton.frame = CGRect(
            x: view.bounds.width - (buttonWidth + 20),
            y: 50,
            width: buttonWidth,
            height: buttonHeight
        )
        redoButton.setTitle("Redo ⏭️", for: .normal)
        redoButton.backgroundColor = DesignTokens.Colors.surface
        redoButton.setTitleColor(DesignTokens.Colors.inkPrimary, for: .normal)
        redoButton.layer.cornerRadius = 8
        redoButton.addTarget(self, action: #selector(redoButtonTapped), for: .touchUpInside)
        view.addSubview(redoButton)
    }

    @objc private func undoButtonTapped() {
        guard undoManager.canUndo() else {
            showAlert("Nothing to undo", title: "Info")
            return
        }

        // For now, just show message
        // TODO: Implement actual undo rendering
        _ = undoManager.undo()
        showAlert("Undo not yet fully implemented\nWill clear layer for now", title: "Undo")
        clearCurrentLayer()

        print("⏮️ Undo (\(undoManager.undoCount()) remaining)")
    }

    @objc private func redoButtonTapped() {
        guard undoManager.canRedo() else {
            showAlert("Nothing to redo", title: "Info")
            return
        }

        _ = undoManager.redo()
        print("⏭️ Redo (\(undoManager.redoCount()) remaining)")
    }

    // MARK: - Error Handling

    private func showAlert(_ message: String, title: String = "Notice") {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
