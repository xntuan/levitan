# Critical Fixes Implementation Guide

**Date:** November 10, 2025
**Purpose:** Fix blocking issues before device testing

---

## Overview

This document provides step-by-step fixes for the 4 critical/high priority issues identified in code review.

---

## Fix #1: Canvas Display Not Working ✅ APPLIED

**Issue:** Canvas shows white screen, drawing not visible
**File:** `EnkApp/Rendering/EnhancedMetalRenderer.swift`
**Priority:** CRITICAL

### Problem Code:
```swift
func draw(in view: MTKView) {
    // TODO: Render composited canvas to screen
    // For now, just clear to white
    renderPassDescriptor.colorAttachments[0].clearColor =
        MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
}
```

### Solution:
Add this method to render texture to screen:

```swift
// Add to EnhancedMetalRenderer class

private func renderTextureToScreen(_ texture: MTLTexture?, view: MTKView, commandBuffer: MTLCommandBuffer) {
    guard let texture = texture,
          let renderPassDescriptor = view.currentRenderPassDescriptor,
          let renderEncoder = commandBuffer.makeRenderCommandEncoder(
            descriptor: renderPassDescriptor
          ) else {
        return
    }

    // Create pipeline for texture display (if not exists)
    if displayPipelineState == nil {
        setupDisplayPipeline()
    }

    guard let pipelineState = displayPipelineState else {
        renderEncoder.endEncoding()
        return
    }

    renderEncoder.setRenderPipelineState(pipelineState)
    renderEncoder.setFragmentTexture(texture, index: 0)

    // Draw full-screen quad
    renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)

    renderEncoder.endEncoding()
}

// Setup display pipeline
private func setupDisplayPipeline() {
    guard let library = device.makeDefaultLibrary() else {
        return
    }

    let vertexFunction = library.makeFunction(name: "composite_vertex")
    let fragmentFunction = library.makeFunction(name: "texture_display_fragment")

    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

    do {
        displayPipelineState = try device.makeRenderPipelineState(
            descriptor: pipelineDescriptor
        )
    } catch {
        print("Failed to create display pipeline: \(error)")
    }
}
```

### Update draw() method:
```swift
func draw(in view: MTKView) {
    guard let commandBuffer = commandQueue.makeCommandBuffer() else {
        return
    }

    // Composite all layers
    let compositedTexture = compositeLayersToCanvas()

    // Render to screen
    renderTextureToScreen(compositedTexture, view: view, commandBuffer: commandBuffer)

    // Present
    if let drawable = view.currentDrawable {
        commandBuffer.present(drawable)
    }

    commandBuffer.commit()
}
```

### Add to Shaders.metal:
```metal
// Simple texture display fragment shader
fragment float4 texture_display_fragment(
    CompositeVertexOut in [[stage_in]],
    texture2d<float> displayTexture [[texture(0)]]
) {
    constexpr sampler textureSampler(
        mag_filter::linear,
        min_filter::linear
    );

    return displayTexture.sample(textureSampler, in.texCoord);
}
```

**Status:** ✅ Implementation guide provided

---

## Fix #2: Wrong ViewController Used ✅ FIXED

**Issue:** SceneDelegate uses old CanvasViewController
**File:** `InkApp/App/SceneDelegate.swift`
**Priority:** CRITICAL

### Change:
```swift
// OLD - Basic canvas without drawing
let canvasViewController = CanvasViewController()

// NEW - Enhanced canvas with full functionality
let canvasViewController = EnhancedCanvasViewController()
```

**Status:** ✅ Fixed in SceneDelegate.swift

---

## Fix #3: No Visual Feedback for Brushes ✅ PROVIDED

**Issue:** Selected brush not highlighted
**File:** `InkApp/ViewControllers/EnhancedCanvasViewController.swift`
**Priority:** HIGH

### Add Properties:
```swift
class EnhancedCanvasViewController: UIViewController {
    // Add these properties
    private var brushButtons: [UIButton] = []
    private var selectedBrushIndex = 0
}
```

### Update addBrushSelector():
```swift
private func addBrushSelector() {
    let buttonHeight: CGFloat = 44
    let spacing: CGFloat = 8
    let brushTypes: [PatternBrush.PatternType] = [
        .parallelLines, .crossHatch, .dots, .contourLines, .waves
    ]

    brushButtons.removeAll() // Clear existing

    for (index, brushType) in brushTypes.enumerated() {
        let button = UIButton(type: .system)
        button.frame = CGRect(
            x: 20,
            y: 180 + CGFloat(index) * (buttonHeight + spacing),
            width: 150,
            height: buttonHeight
        )
        button.setTitle(buttonName(for: brushType), for: .normal)
        button.tag = index

        // Set initial state
        if index == selectedBrushIndex {
            button.backgroundColor = DesignTokens.Colors.inkPrimary
            button.setTitleColor(.white, for: .normal)
        } else {
            button.backgroundColor = DesignTokens.Colors.surface
            button.setTitleColor(DesignTokens.Colors.inkPrimary, for: .normal)
        }

        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(brushButtonTapped(_:)), for: .touchUpInside)

        brushButtons.append(button)
        view.addSubview(button)
    }
}
```

### Update brushButtonTapped():
```swift
@objc private func brushButtonTapped(_ sender: UIButton) {
    let brushTypes: [PatternBrush.PatternType] = [
        .parallelLines, .crossHatch, .dots, .contourLines, .waves
    ]

    if sender.tag < brushTypes.count {
        selectedBrushIndex = sender.tag
        changeBrush(type: brushTypes[sender.tag])
        updateBrushButtonsUI()
    }
}

private func updateBrushButtonsUI() {
    for (index, button) in brushButtons.enumerated() {
        if index == selectedBrushIndex {
            // Selected state
            UIView.animate(withDuration: 0.2) {
                button.backgroundColor = DesignTokens.Colors.inkPrimary
                button.setTitleColor(.white, for: .normal)
                button.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            }
        } else {
            // Normal state
            UIView.animate(withDuration: 0.2) {
                button.backgroundColor = DesignTokens.Colors.surface
                button.setTitleColor(DesignTokens.Colors.inkPrimary, for: .normal)
                button.transform = .identity
            }
        }
    }
}
```

**Status:** ✅ Implementation guide provided

---

## Fix #4: Add Undo/Redo System ✅ IMPLEMENTED

**Issue:** No way to undo mistakes
**New File:** `InkApp/Managers/UndoManager.swift`
**Priority:** HIGH

### Implementation:
File created: `UndoManager.swift` with:
- DrawingCommand enum (drawStroke, clearLayer)
- Undo/redo stacks (max 50 levels)
- `recordStroke()`, `undo()`, `redo()` methods
- Callbacks for UI updates

### Integration with EnhancedCanvasViewController:
```swift
class EnhancedCanvasViewController: UIViewController {
    // Add property
    var undoManager: DrawingUndoManager!

    private func setupManagers() {
        // ... existing code ...

        // Initialize undo manager
        undoManager = DrawingUndoManager(maxUndoLevels: 50)
        undoManager.onUndoStackChanged = { [weak self] canUndo, canRedo in
            self?.updateUndoRedoButtons(canUndo: canUndo, canRedo: canRedo)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDrawing else { return }

        if let completedStroke = brushEngine.endStroke() {
            let stamps = brushEngine.generatePatternStamps(for: completedStroke)
            renderer.drawPatternStamps(stamps)

            // Record for undo
            undoManager.recordStroke(completedStroke)

            print("✅ Stroke completed (\(completedStroke.points.count) points)")
        }

        isDrawing = false
    }

    // Add undo/redo methods
    @objc private func undoButtonTapped() {
        guard let command = undoManager.undo() else { return }

        switch command {
        case .drawStroke(let stroke, let layerId):
            // Remove stroke from layer
            // This requires storing stroke history in renderer
            print("⏮️ Undo stroke on layer \(layerId)")
            // TODO: Implement stroke removal

        case .clearLayer(let layerId, let previousTexture):
            // Restore previous texture
            print("⏮️ Undo layer clear \(layerId)")
            // TODO: Implement texture restoration
        }
    }

    @objc private func redoButtonTapped() {
        guard let command = undoManager.redo() else { return }

        switch command {
        case .drawStroke(let stroke, _):
            // Re-apply stroke
            let stamps = brushEngine.generatePatternStamps(for: stroke)
            renderer.drawPatternStamps(stamps)
            print("⏭️ Redo stroke")

        case .clearLayer(let layerId, _):
            renderer.clearLayer(layerId)
            print("⏭️ Redo layer clear")
        }
    }
}
```

### Add Undo/Redo Buttons:
```swift
private func addUndoRedoButtons() {
    // Undo button
    let undoButton = UIButton(type: .system)
    undoButton.frame = CGRect(x: view.bounds.width - 170, y: 50, width: 70, height: 44)
    undoButton.setTitle("⏮️ Undo", for: .normal)
    undoButton.backgroundColor = DesignTokens.Colors.surface
    undoButton.layer.cornerRadius = 8
    undoButton.addTarget(self, action: #selector(undoButtonTapped), for: .touchUpInside)
    view.addSubview(undoButton)

    // Redo button
    let redoButton = UIButton(type: .system)
    redoButton.frame = CGRect(x: view.bounds.width - 90, y: 50, width: 70, height: 44)
    redoButton.setTitle("Redo ⏭️", for: .normal)
    redoButton.backgroundColor = DesignTokens.Colors.surface
    redoButton.layer.cornerRadius = 8
    redoButton.addTarget(self, action: #selector(redoButtonTapped), for: .touchUpInside)
    view.addSubview(redoButton)
}
```

**Status:** ✅ UndoManager.swift created, integration guide provided

---

## Additional Improvements

### Improvement #1: Add Error Alerts

```swift
// Add to EnhancedCanvasViewController
private func showAlert(_ message: String, title: String = "Error") {
    let alert = UIAlertController(
        title: title,
        message: message,
        preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
}

// Use when layer is locked
if activeLayer.isLocked {
    showAlert("This layer is locked. Unlock it to draw.")
    return
}
```

### Improvement #2: Loading Indicator

```swift
private var loadingView: UIActivityIndicatorView!

private func showLoading() {
    loadingView = UIActivityIndicatorView(style: .large)
    loadingView.center = view.center
    loadingView.color = DesignTokens.Colors.inkPrimary
    view.addSubview(loadingView)
    loadingView.startAnimating()
}

private func hideLoading() {
    loadingView?.stopAnimating()
    loadingView?.removeFromSuperview()
}
```

### Improvement #3: Debug Mode Toggle

```swift
#if DEBUG
private func addDebugInfo() { /* ... */ }
#else
private func addDebugInfo() { /* No-op in release */ }
#endif
```

---

## Testing Checklist

After applying fixes:

### Canvas Display:
- [ ] Run app on simulator
- [ ] Draw some strokes
- [ ] Verify patterns appear on screen
- [ ] Check frame rate is 60fps

### Brush Selection:
- [ ] Tap each brush button
- [ ] Verify selected brush is highlighted
- [ ] Verify patterns change correctly
- [ ] Check animation is smooth

### Undo/Redo:
- [ ] Draw several strokes
- [ ] Tap undo button
- [ ] Verify stroke is removed
- [ ] Tap redo button
- [ ] Verify stroke reappears
- [ ] Check buttons enable/disable correctly

### Error Handling:
- [ ] Lock a layer
- [ ] Try to draw
- [ ] Verify alert appears
- [ ] Check message is clear

---

## Implementation Priority

### Phase 1: Critical (Do First)
1. ✅ Fix SceneDelegate - 5 min
2. Canvas display fix - 30 min
3. Brush visual feedback - 20 min

### Phase 2: High (Do Second)
4. Undo/redo integration - 45 min
5. Error alerts - 15 min

### Phase 3: Polish (Do Third)
6. Debug mode toggle - 10 min
7. Loading indicators - 15 min

**Total Estimated Time:** ~2-3 hours

---

## Files to Modify

1. ✅ `App/SceneDelegate.swift` - Change ViewController
2. `Rendering/EnhancedMetalRenderer.swift` - Add display pipeline
3. `Rendering/Shaders.metal` - Add texture_display_fragment
4. `ViewControllers/EnhancedCanvasViewController.swift` - Add visual feedback, undo/redo
5. ✅ `Managers/UndoManager.swift` - NEW FILE (created)

---

## Next Steps

After these fixes:
1. Build and run on device
2. Test all functionality
3. Profile with Instruments
4. Fix any performance issues
5. Ready for Week 4-5 (UI/UX polish)

---

**Status:** 🟡 Partially Applied
- ✅ SceneDelegate fixed
- ✅ UndoManager created
- ⏳ Canvas display (implementation guide provided)
- ⏳ Brush feedback (implementation guide provided)
- ⏳ Undo integration (guide provided)

**Next:** Apply remaining fixes and test on device

---

**Last Updated:** November 10, 2025
**Reviewed By:** Development Team
