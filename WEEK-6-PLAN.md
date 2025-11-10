# Week 6 Development Plan
## Advanced Input & Polish Features

**Duration:** Week 6
**Focus:** Apple Pencil integration, advanced controls, UI polish
**Goal:** Professional-grade input handling and missing essential features

---

## Overview

Week 6 focuses on **advanced input handling** and **completing essential UI controls** that elevate the app from good to professional. These features are standard in apps like Procreate and are expected by serious users.

---

## Task Breakdown

### Task 6.1: Apple Pencil Tilt Support ⭐⭐⭐
**Priority:** High
**Estimated Time:** 3-4 hours
**Complexity:** Medium

**Goal:** Enable brush width/opacity control via Apple Pencil tilt angle.

**Features:**
- Read tilt angle from UITouch (altitudeAngle, azimuthAngle)
- Map tilt to brush size (0-90°)
- Optional: Map tilt to opacity
- Configurable sensitivity
- Preview in brush settings

**Technical Details:**
```swift
// UITouch properties (iOS 9.1+)
touch.altitudeAngle // 0 (flat) to π/2 (perpendicular)
touch.azimuthAngle(in: view) // 0 to 2π (direction)

// Tilt mapping
let tiltPercent = 1.0 - (touch.altitudeAngle / (.pi / 2))
let tiltedSize = baseSize * (1.0 - tiltPercent * tiltSensitivity)
```

**Files to Modify:**
- `EnhancedBrushEngine.swift` - Add tilt handling
- `BrushConfiguration.swift` - Add tilt settings
- `AdvancedBrushSettingsPanel.swift` - Add tilt controls
- `EnhancedCanvasViewController.swift` - Pass tilt data

**Acceptance Criteria:**
- [ ] Tilt angle read from Apple Pencil
- [ ] Brush size changes with tilt
- [ ] Configurable tilt sensitivity (0-100%)
- [ ] Works with all pattern types
- [ ] Smooth transitions
- [ ] No jitter or instability

---

### Task 6.2: Azimuth-Based Rotation ⭐⭐⭐
**Priority:** High
**Estimated Time:** 2-3 hours
**Complexity:** Medium

**Goal:** Rotate brush patterns based on Apple Pencil direction (azimuth).

**Features:**
- Read azimuth angle from UITouch
- Rotate pattern geometry
- Configurable: follow azimuth, fixed rotation, or manual
- Natural drawing feel (like real pen)

**Technical Details:**
```swift
// Azimuth angle (direction pencil points)
let azimuth = touch.azimuthAngle(in: view) // 0 to 2π
let azimuthDegrees = azimuth * 180 / .pi // 0 to 360°

// Rotation modes
enum RotationMode {
    case fixed(Float)      // User-set rotation
    case followAzimuth     // Rotate with pencil direction
    case manual           // No automatic rotation
}
```

**Use Cases:**
- **Parallel Lines:** Rotate to follow stroke direction
- **Cross-Hatch:** Natural pen behavior
- **Waves:** Follow curve direction
- **Dots:** No rotation needed (circular)

**Files to Modify:**
- `PatternBrush.swift` - Add rotation mode
- `EnhancedBrushEngine.swift` - Calculate azimuth rotation
- `PatternGenerator.swift` - Apply rotation to geometry
- `BrushSettingsPanel.swift` - Add rotation mode toggle

**Acceptance Criteria:**
- [ ] Azimuth angle read correctly
- [ ] Rotation applied to pattern geometry
- [ ] Three modes: Fixed, Follow Azimuth, Manual
- [ ] Smooth rotation (no sudden jumps)
- [ ] Works with all 5 pattern types
- [ ] Toggle in brush settings

---

### Task 6.3: Layer Opacity Slider ⭐⭐⭐
**Priority:** High
**Estimated Time:** 2-3 hours
**Complexity:** Low

**Goal:** Add opacity control to layer selector.

**Features:**
- Opacity slider (0-100%) per layer
- Real-time preview
- Smooth updates
- Context menu option + inline slider

**UI Design:**
```
Layer Card (expanded):
┌────────────────────────────────┐
│ [Thumbnail] Layer 1            │
│ Opacity: ▬▬▬▬▬▬▬▬○▬▬ 80%      │
└────────────────────────────────┘
```

**Technical Details:**
```swift
// LayerCardView addition
private let opacitySlider: UISlider
private let opacityLabel: UILabel

// LayerSelectorDelegate addition
func layerSelector(_ selector: LayerSelectorView,
                   didChangeOpacity opacity: Float,
                   for layer: Layer)
```

**Files to Modify:**
- `LayerSelectorView.swift` - Add opacity UI
- `LayerCardView.swift` - Add slider to card
- `EnhancedCanvasViewController.swift` - Handle opacity changes

**Acceptance Criteria:**
- [ ] Opacity slider in layer card
- [ ] Real-time compositing update
- [ ] Percentage label (0-100%)
- [ ] Smooth slider interaction
- [ ] Persists with layer
- [ ] Undo support (future)

---

### Task 6.4: Pressure Curve Graph Editor ⭐⭐
**Priority:** Medium
**Estimated Time:** 4-5 hours
**Complexity:** High

**Goal:** Visual curve editor for custom pressure curves.

**Features:**
- Interactive curve graph (11 control points)
- Preset curves (Linear, Ease In, Ease Out, S-Curve)
- Visual feedback
- Save/load custom curves

**UI Design:**
```
Pressure Curve Editor:
┌─────────────────────────────┐
│ Output                      │
│ 1.0 ┐                     ╱ │
│     │                  ╱    │
│ 0.5 ┤             ╱         │
│     │       ╱               │
│ 0.0 └──────────────────────→│
│     0.0        0.5       1.0│
│                       Input │
│                             │
│ [Linear][Ease In][Custom]  │
└─────────────────────────────┘
```

**Technical Details:**
```swift
struct CustomPressureCurve {
    var controlPoints: [Float] = [0, 0.1, 0.2, ..., 1.0] // 11 points

    func evaluate(at input: Float) -> Float {
        // Cubic interpolation between points
        let segment = Int(input * 10)
        let t = (input * 10) - Float(segment)
        return cubicInterpolate(
            controlPoints[segment],
            controlPoints[segment + 1],
            t
        )
    }
}
```

**Files to Create:**
- `PressureCurveEditorView.swift` - Graph UI (300+ lines)
- `CurveGraphView.swift` - Interactive graph (200+ lines)

**Files to Modify:**
- `BrushConfiguration.swift` - Add custom curve support
- `AdvancedBrushSettingsPanel.swift` - Add "Edit Curve" button

**Acceptance Criteria:**
- [ ] Interactive curve graph
- [ ] 11 draggable control points
- [ ] Real-time preview
- [ ] Preset curves
- [ ] Save custom curves
- [ ] Smooth cubic interpolation

---

### Task 6.5: Layer Reordering (Drag & Drop) ⭐⭐
**Priority:** Medium
**Estimated Time:** 3-4 hours
**Complexity:** Medium

**Goal:** Drag and drop layer cards to reorder.

**Features:**
- Long-press to pick up layer
- Drag to new position
- Visual feedback (lifted card)
- Drop animation
- Update z-order

**Technical Details:**
```swift
// UILongPressGestureRecognizer + UIPanGestureRecognizer
// Or use UICollectionView drag & drop (iOS 11+)

extension LayerSelectorView: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView,
                       itemsForBeginning session: UIDragSession,
                       at indexPath: IndexPath) -> [UIDragItem]
}
```

**Files to Modify:**
- `LayerSelectorView.swift` - Add drag/drop
- `LayerManager.swift` - Reorder method exists
- `EnhancedCanvasViewController.swift` - Handle reorder

**Acceptance Criteria:**
- [ ] Long-press to start drag
- [ ] Visual feedback (shadow/scale)
- [ ] Smooth drag animation
- [ ] Drop updates z-order
- [ ] Compositing updates
- [ ] Works on iPhone & iPad

---

### Task 6.6: Brush Presets Library ⭐
**Priority:** Low
**Estimated Time:** 3-4 hours
**Complexity:** Medium

**Goal:** Save and load custom brush configurations.

**Features:**
- Save current brush as preset
- Load preset
- Preset library UI
- 10+ built-in presets
- Custom presets

**Presets:**
1. **Sketchy Pencil** - Jitter, low stabilization
2. **Smooth Ink** - High stabilization, ease-out curve
3. **Watercolor** - Low opacity, flow, velocity dynamics
4. **Technical** - High stabilization, precise
5. **Charcoal** - Size jitter, texture
6. **Marker** - Medium flow, linear curve
7. **Airbrush** - Low flow, velocity dynamics
8. **Calligraphy** - Azimuth rotation, pressure curve
9. **Digital Pen** - Minimal processing
10. **Expressive** - High jitter, velocity dynamics

**Files to Create:**
- `BrushPresetManager.swift` - Save/load (150+ lines)
- `BrushPresetLibraryView.swift` - UI (300+ lines)

**Acceptance Criteria:**
- [ ] Save custom presets
- [ ] Load presets
- [ ] 10 built-in presets
- [ ] Preview thumbnails
- [ ] Rename/delete presets
- [ ] Import/export (JSON)

---

## Priority Order

### Week 6 Sprint 1 (High Priority)
1. ✅ Task 6.3: Layer Opacity Slider (2-3 hours)
2. ✅ Task 6.1: Apple Pencil Tilt Support (3-4 hours)
3. ✅ Task 6.2: Azimuth-Based Rotation (2-3 hours)

**Total:** 7-10 hours

### Week 6 Sprint 2 (Medium Priority)
4. Task 6.4: Pressure Curve Graph Editor (4-5 hours)
5. Task 6.5: Layer Reordering (3-4 hours)

**Total:** 7-9 hours

### Week 6 Sprint 3 (Polish)
6. Task 6.6: Brush Presets Library (3-4 hours)
7. Bug fixes and testing (2-3 hours)

**Total:** 5-7 hours

---

## Technical Architecture

### Apple Pencil Input Pipeline

```
UITouch (Apple Pencil)
    ↓
    ├─ force → pressure (0-1)
    ├─ altitudeAngle → tilt (0-π/2)
    ├─ azimuthAngle → direction (0-2π)
    └─ location → position (x, y)
    ↓
EnhancedBrushEngine
    ├─ Process tilt (size/opacity)
    ├─ Process azimuth (rotation)
    ├─ Apply pressure curve
    └─ Generate pattern geometry
    ↓
PatternRenderer
    └─ Render to layer texture
```

### Layer Opacity Pipeline

```
LayerSelectorView (opacity slider)
    ↓
LayerSelectorDelegate
    ↓
EnhancedCanvasViewController
    ↓
LayerManager.setLayerOpacity()
    ↓
EnhancedMetalRenderer.compositeLayersForDisplay()
    └─ Apply opacity in shader
```

---

## Success Criteria

### Week 6 Complete When:
- [ ] Apple Pencil tilt affects brush size
- [ ] Azimuth rotates parallel lines naturally
- [ ] Layer opacity slider works smoothly
- [ ] All features tested on iPad with Apple Pencil
- [ ] No performance regression (60fps maintained)
- [ ] Documentation updated

### Optional (If Time Permits):
- [ ] Pressure curve graph editor
- [ ] Layer drag & drop
- [ ] Brush presets library

---

## Testing Checklist

### Apple Pencil Tilt
- [ ] Test with Apple Pencil (Gen 1 & 2)
- [ ] Verify altitudeAngle range (0-90°)
- [ ] Test tilt sensitivity (0-100%)
- [ ] Check all 5 pattern types
- [ ] Test without Apple Pencil (finger)
- [ ] Verify smooth transitions

### Azimuth Rotation
- [ ] Test with Apple Pencil
- [ ] Verify azimuthAngle range (0-360°)
- [ ] Test parallel lines rotation
- [ ] Test cross-hatch rotation
- [ ] Check Fixed/Follow/Manual modes
- [ ] Test rapid direction changes

### Layer Opacity
- [ ] Test opacity 0% (invisible)
- [ ] Test opacity 50% (semi-transparent)
- [ ] Test opacity 100% (opaque)
- [ ] Verify real-time compositing
- [ ] Check blend modes with opacity
- [ ] Test multiple layers

---

## Performance Targets

| Metric | Target | Critical |
|--------|--------|----------|
| Frame rate | 60fps | 45fps+ |
| Input latency | <16ms | <33ms |
| Opacity update | <16ms | <33ms |
| Memory usage | <150MB | <250MB |

---

## Known Challenges

### 1. Apple Pencil Detection
- **Challenge:** Not all devices support Apple Pencil
- **Solution:** Graceful fallback to touch, feature detection

### 2. Azimuth Smoothing
- **Challenge:** Rapid direction changes cause jitter
- **Solution:** Apply exponential smoothing to azimuth

### 3. Opacity Performance
- **Challenge:** Changing opacity requires full recomposite
- **Solution:** Already handled by ping-pong buffers

### 4. Pressure Curve Complexity
- **Challenge:** Graph editor is complex UI
- **Solution:** Start with presets, add editor if time permits

---

## Future Enhancements (Week 7+)

### Advanced Features
- Tilt-based texture variation
- Azimuth-based shape morphing
- Wet edges simulation
- Brush dynamics recording/playback
- Multi-touch gestures
- Palm rejection tuning

### Polish
- Haptic feedback for milestones
- Tutorial/onboarding
- Cloud sync
- Artwork history
- Advanced export options (PSD)

---

## Comparison to Industry Apps

### Procreate

| Feature | Procreate | Ink (Week 6) |
|---------|-----------|--------------|
| Tilt Support | ✅ Yes | 🔄 Implementing |
| Azimuth | ✅ Yes | 🔄 Implementing |
| Layer Opacity | ✅ Yes | 🔄 Implementing |
| Curve Editor | ✅ Yes | ⏳ Optional |
| Presets | ✅ 200+ | ⏳ Optional |

**Goal:** Match Procreate's core input features by end of Week 6.

---

## Resources

### Documentation
- [Apple Pencil Programming Guide](https://developer.apple.com/documentation/uikit/touches_presses_and_gestures/handling_touches_in_your_view)
- [UITouch altitudeAngle](https://developer.apple.com/documentation/uikit/uitouch/1618110-altitudeangle)
- [UITouch azimuthAngle](https://developer.apple.com/documentation/uikit/uitouch/1618144-azimuthangle)

### References
- Procreate tilt behavior
- Adobe Fresco rotation modes
- Clip Studio Paint pressure curves

---

**Status:** Ready to implement
**Next Action:** Start with Task 6.3 (Layer Opacity Slider) - quickest win
