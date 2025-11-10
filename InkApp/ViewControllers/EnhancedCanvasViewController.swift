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
    private var layerSelectorView: LayerSelectorView!
    private var brushPaletteView: UIView!

    // Auto-hide
    private var autoHideTimer: Timer?
    private var isUIVisible = true

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
        addLayerSelector()
        addBrushPalette()
        addUndoRedoButtons()

        // Start auto-hide timer
        scheduleAutoHide()
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
    // Note: touchesBegan is implemented below with auto-hide logic

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

    // MARK: - Layer Selector

    private func addLayerSelector() {
        layerSelectorView = LayerSelectorView()
        layerSelectorView.delegate = self
        layerSelectorView.configure(
            with: layerManager.layers,
            selectedLayerId: layerManager.activeLayer?.id
        )

        view.addSubview(layerSelectorView)

        layerSelectorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            layerSelectorView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            layerSelectorView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            layerSelectorView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -90),
            layerSelectorView.heightAnchor.constraint(equalToConstant: 96)
        ])
    }

    private func addBrushPalette() {
        // Create brush palette container
        brushPaletteView = UIView()
        brushPaletteView.backgroundColor = UIColor.white.withAlphaComponent(0.95)
        brushPaletteView.layer.cornerRadius = 20
        brushPaletteView.layer.masksToBounds = false

        // Add blur effect
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = brushPaletteView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.layer.cornerRadius = 20
        blurView.clipsToBounds = true
        brushPaletteView.insertSubview(blurView, at: 0)

        // Shadow
        brushPaletteView.layer.shadowColor = UIColor.black.cgColor
        brushPaletteView.layer.shadowOpacity = 0.15
        brushPaletteView.layer.shadowOffset = CGSize(width: 0, height: 12)
        brushPaletteView.layer.shadowRadius = 20

        view.addSubview(brushPaletteView)

        brushPaletteView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            brushPaletteView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            brushPaletteView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            brushPaletteView.heightAnchor.constraint(equalToConstant: 64),
            brushPaletteView.widthAnchor.constraint(equalToConstant: 340)
        ])

        // Create brush buttons in palette
        let brushTypes: [PatternBrush.PatternType] = [
            .parallelLines, .crossHatch, .dots, .contourLines, .waves
        ]

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8

        brushPaletteView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: brushPaletteView.topAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: brushPaletteView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: brushPaletteView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: brushPaletteView.bottomAnchor, constant: -10)
        ])

        brushButtons.removeAll()

        for (index, brushType) in brushTypes.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(brushIcon(for: brushType), for: .normal)
            button.titleLabel?.font = DesignTokens.Typography.systemFont(size: 20, weight: .semibold)
            button.layer.cornerRadius = 22
            button.tag = index

            // Long press for settings
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(brushButtonLongPressed(_:)))
            button.addGestureRecognizer(longPress)

            // Set initial state
            updateBrushButton(button, index: index, isSelected: index == selectedBrushIndex)

            button.addTarget(self, action: #selector(brushButtonTapped(_:)), for: .touchUpInside)
            brushButtons.append(button)
            stackView.addArrangedSubview(button)
        }
    }

    private func updateBrushButton(_ button: UIButton, index: Int, isSelected: Bool) {
        UIView.animate(withDuration: DesignTokens.Animation.durationFast) {
            if isSelected {
                button.backgroundColor = DesignTokens.Colors.inkPrimary
                button.setTitleColor(.white, for: .normal)
                button.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            } else {
                button.backgroundColor = DesignTokens.Colors.surface
                button.setTitleColor(DesignTokens.Colors.inkPrimary, for: .normal)
                button.transform = .identity
            }
        }
    }

    private func brushIcon(for type: PatternBrush.PatternType) -> String {
        switch type {
        case .parallelLines: return "≡"
        case .crossHatch: return "⊞"
        case .dots: return "⊙"
        case .contourLines: return "◎"
        case .waves: return "≈"
        }
    }

    @objc private func brushButtonLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let button = gesture.view as? UIButton else { return }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Show brush settings panel
        let panel = BrushSettingsPanel(brush: brushEngine.currentBrush)
        panel.delegate = self
        panel.present(in: view)

        // Animate button
        UIView.animate(withDuration: 0.1) {
            button.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                button.transform = self.selectedBrushIndex == button.tag ?
                    CGAffineTransform(scaleX: 1.05, y: 1.05) : .identity
            }
        }
    }

    // MARK: - Auto-Hide Behavior

    private func scheduleAutoHide() {
        autoHideTimer?.invalidate()
        autoHideTimer = Timer.scheduledTimer(
            withTimeInterval: 3.0,
            repeats: false
        ) { [weak self] _ in
            self?.hideUI()
        }
    }

    private func hideUI() {
        guard isUIVisible else { return }

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.layerSelectorView?.alpha = 0
            self.brushPaletteView?.alpha = 0
        }

        isUIVisible = false
    }

    private func showUI() {
        guard !isUIVisible else {
            // If already visible, just reschedule
            scheduleAutoHide()
            return
        }

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.layerSelectorView?.alpha = 1
            self.brushPaletteView?.alpha = 1
        }

        isUIVisible = true
        scheduleAutoHide()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Show UI on touch
        if !isUIVisible {
            showUI()
        } else {
            // Reschedule hide if UI is visible
            scheduleAutoHide()
        }

        // Continue with existing touch handling...
        // (rest of touchesBegan implementation stays the same)
        guard touches.count == 1,
              let touch = touches.first,
              let activeLayer = layerManager.activeLayer else {
            return
        }

        if activeLayer.isLocked {
            showAlert("Layer '\(activeLayer.name)' is locked.\nUnlock it to draw.", title: "Layer Locked")
            print("⚠️ Layer '\(activeLayer.name)' is locked!")
            return
        }

        let point = touch.location(in: metalView)
        let canvasPoint = viewToCanvasPoint(point)
        let pressure = touch.force > 0 ? Float(touch.force / touch.maximumPossibleForce) : 1.0

        brushEngine.beginStroke(at: canvasPoint, pressure: pressure, layerId: activeLayer.id)
        isDrawing = true

        print("✏️ Drawing started on layer '\(activeLayer.name)' at \(canvasPoint)")
    }
}

// MARK: - LayerSelectorDelegate

extension EnhancedCanvasViewController: LayerSelectorDelegate {
    func layerSelector(_ selector: LayerSelectorView, didSelectLayer layer: Layer) {
        // Find layer index
        if let index = layerManager.layers.firstIndex(where: { $0.id == layer.id }) {
            layerManager.selectLayer(at: index)
            updateDebugInfo()
            print("📄 Selected layer: '\(layer.name)'")
        }
    }

    func layerSelector(_ selector: LayerSelectorView, didToggleVisibilityFor layer: Layer) {
        if let index = layerManager.layers.firstIndex(where: { $0.id == layer.id }) {
            layerManager.toggleLayerVisibility(at: index)

            // Update layer selector
            if let updatedLayer = layerManager.layers.first(where: { $0.id == layer.id }) {
                layerSelectorView.updateLayer(updatedLayer)
            }

            print("👁️ Toggled visibility for layer: '\(layer.name)'")
        }
    }

    func layerSelectorDidRequestAddLayer(_ selector: LayerSelectorView) {
        // Create new layer
        let newLayerNumber = layerManager.layers.count + 1
        let newLayer = Layer(name: "Layer \(newLayerNumber)", opacity: 1.0)

        layerManager.addLayer(newLayer)

        // Refresh layer selector
        layerSelectorView.configure(
            with: layerManager.layers,
            selectedLayerId: layerManager.activeLayer?.id
        )

        print("➕ Added new layer: '\(newLayer.name)'")
    }

    func layerSelector(_ selector: LayerSelectorView, didRequestDeleteLayer layer: Layer) {
        guard layerManager.layers.count > 1 else {
            showAlert("Cannot delete the last layer", title: "Error")
            return
        }

        if let index = layerManager.layers.firstIndex(where: { $0.id == layer.id }) {
            layerManager.removeLayer(at: index)

            // Refresh layer selector
            layerSelectorView.configure(
                with: layerManager.layers,
                selectedLayerId: layerManager.activeLayer?.id
            )

            print("🗑️ Deleted layer: '\(layer.name)'")
        }
    }

    func layerSelector(_ selector: LayerSelectorView, didRequestRenameLayer layer: Layer) {
        let alert = UIAlertController(
            title: "Rename Layer",
            message: nil,
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.text = layer.name
            textField.placeholder = "Layer name"
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            guard let self = self,
                  let newName = alert.textFields?.first?.text,
                  !newName.isEmpty else {
                return
            }

            if let index = self.layerManager.layers.firstIndex(where: { $0.id == layer.id }) {
                self.layerManager.renameLayer(at: index, to: newName)

                // Update layer selector
                if let updatedLayer = self.layerManager.layers.first(where: { $0.id == layer.id }) {
                    self.layerSelectorView.updateLayer(updatedLayer)
                }

                self.updateDebugInfo()
                print("✏️ Renamed layer to: '\(newName)'")
            }
        })

        present(alert, animated: true)
    }

    func layerSelector(_ selector: LayerSelectorView, didRequestToggleLockFor layer: Layer) {
        if let index = layerManager.layers.firstIndex(where: { $0.id == layer.id }) {
            layerManager.toggleLayerLock(at: index)

            // Update layer selector
            if let updatedLayer = layerManager.layers.first(where: { $0.id == layer.id }) {
                layerSelectorView.updateLayer(updatedLayer)
            }

            let status = layer.isLocked ? "unlocked" : "locked"
            print("🔒 \(status.capitalized) layer: '\(layer.name)'")
        }
    }
}

// MARK: - BrushSettingsPanelDelegate

extension EnhancedCanvasViewController: BrushSettingsPanelDelegate {
    func brushSettingsPanel(_ panel: BrushSettingsPanel, didUpdateBrush brush: PatternBrush) {
        // Update brush engine
        brushEngine.currentBrush = brush
        updateDebugInfo()

        print("🖌️ Updated brush settings:")
        print("  - Rotation: \(brush.rotation)°")
        print("  - Spacing: \(brush.spacing)px")
        print("  - Opacity: \(Int(brush.opacity * 100))%")
        print("  - Scale: \(brush.scale)×")
    }

    func brushSettingsPanelDidCancel(_ panel: BrushSettingsPanel) {
        print("❌ Brush settings cancelled")
    }
}
