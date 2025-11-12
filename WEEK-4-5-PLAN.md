# Week 4-5 Implementation Plan
## UI/UX Polish & Template Gallery

**Date:** November 10, 2025
**Phase:** UI/UX Implementation (Week 5-6 in Roadmap)
**Duration:** ~2 weeks
**Status:** 📋 Planning

---

## Overview

Week 4-5 focuses on implementing the complete UI/UX layer for the Ink app, bringing the Lake aesthetic to life and creating a delightful user experience. This builds on the solid technical foundation from Weeks 1-3.

**Primary Goals:**
1. Template Gallery - Browse and select artwork templates
2. Enhanced Canvas UI - Layer selector, brush settings panel, auto-hide behavior
3. Completion Screen - Celebration and sharing
4. Lake Aesthetic Polish - Gradients, animations, blur effects
5. Enhanced Rendering - Proper multi-layer compositing, blend modes

---

## Implementation Tasks

### Task 3.1: Template Gallery ⭐️ HIGH PRIORITY
**Duration:** 3 days
**Files:** `TemplateGalleryViewController.swift`, `TemplateCollectionViewCell.swift`, `Template.swift`

#### Deliverables:
1. **Template Model** (`Models/Template.swift`)
   - Template data structure (id, name, description, image, layers, category)
   - Template metadata (difficulty, estimated time, tags)
   - Category enum (nature, abstract, animals, landscapes, patterns)

2. **Gallery View Controller** (`ViewControllers/TemplateGalleryViewController.swift`)
   - UICollectionView with 2-column grid (iPad) / 1-column (iPhone)
   - Template cards with images and metadata
   - Category filter chips at bottom
   - Gradient background (Lake aesthetic)
   - Navigation to canvas on selection

3. **Template Card Cell** (`Views/TemplateCollectionViewCell.swift`)
   - Square aspect ratio (1:1)
   - Template image with rounded corners (16px radius)
   - Bottom gradient overlay for text
   - Title (15pt semibold, white)
   - Tags (11pt regular, subtle)
   - Card shadow: `0 4px 16px rgba(0,0,0,0.08)`
   - Press animation: scale(0.97)
   - Selected state: 3px border #667eea

#### UI Specifications:
```swift
Layout:
- Spacing: 16px between cards
- Padding: 20px edge insets
- Card size: Calculated for 2 columns with spacing
- Filter bar: 48px height, sticky at bottom

Colors:
- Background: Gradient (sunrise or ocean from DesignTokens)
- Card background: White
- Selected border: #667eea

Animations:
- Card press: scale(0.97), duration 0.2s
- Card selection: border grow, duration 0.3s
- Filter selection: background change, duration 0.2s
```

#### Sample Templates (Initial Set):
```
Nature Category:
1. "Mountain Sunset" - Mountains + sky layers
2. "Forest Path" - Trees + path layers
3. "Ocean Waves" - Water + sky + shore layers
4. "Cherry Blossom" - Branches + flowers + sky layers
5. "Desert Dunes" - Sand + sky + cacti layers

Abstract Category:
6. "Geometric Shapes" - Circles + triangles + lines
7. "Flowing Curves" - Wave patterns + gradients
8. "Mandala" - Circular pattern layers

Animals Category:
9. "Sleeping Cat" - Body + details layers
10. "Bird in Flight" - Bird + sky + clouds layers
```

**Acceptance Criteria:**
- ✅ Grid displays 10 initial templates
- ✅ Lake aesthetic matches design brief
- ✅ Tap navigates to canvas with selected template
- ✅ Category filters work
- ✅ Smooth scroll performance
- ✅ Cards have press animations
- ✅ Gradients look beautiful

---

### Task 3.2: Enhanced Canvas UI ⭐️ HIGH PRIORITY
**Duration:** 3 days
**Files:** `EnhancedCanvasViewController.swift`, `LayerSelectorView.swift`, `BrushSettingsPanel.swift`

#### Deliverables:

#### 1. Layer Selector Panel (`Views/LayerSelectorView.swift`)
**Visual Design:**
```
╭─────────────────────────────────╮
│ □Sky   □Mountain  □Water [+]   │
╰─────────────────────────────────╯
```

**Features:**
- Floating panel at bottom (above brush palette)
- Height: 80px
- Horizontal scroll of layer cards
- Each layer card:
  - Thumbnail: 48x48px with 8px radius
  - Layer name: 13pt regular
  - Visibility toggle: Eye icon (24x24px)
  - Lock indicator: Lock icon if locked
  - Selected state: Background #f0f3ff, border 2px #667eea
- Add layer button (+) at end
- Panel style:
  - Background: rgba(255,255,255,0.95)
  - Backdrop blur: 20px
  - Radius: 20px
  - Shadow: `0 12px 40px rgba(0,0,0,0.15)`
  - Padding: 16px

**Interactions:**
- Tap layer → Select and switch active layer
- Tap eye icon → Toggle layer visibility
- Long press → Show context menu (lock, duplicate, delete, rename)
- Tap + → Add new blank layer

#### 2. Brush Settings Panel (`Views/BrushSettingsPanel.swift`)
**Visual Design:**
```
╭─────────────────────────────────────╮
│  Brush Settings                     │
├─────────────────────────────────────┤
│  Pattern Preview                    │
│  ┌─────────────────────────────┐   │
│  │      ⊙⊙⊙⊙⊙⊙⊙⊙⊙⊙            │   │
│  └─────────────────────────────┘   │
│                                     │
│  Rotation                      45°  │
│  ├─────────●─────────────────┤     │
│                                     │
│  Spacing                       8px  │
│  ├───────●───────────────────┤     │
│                                     │
│  Opacity                      100%  │
│  ├─────────────────────────●┤      │
│                                     │
│  Scale                        1.0×  │
│  ├──────────────●──────────┤       │
│                                     │
├─────────────────────────────────────┤
│      [Apply]         [Cancel]       │
╰─────────────────────────────────────╯
```

**Features:**
- Modal sheet presentation (slide up from bottom)
- Pattern preview: 200x200px square showing current pattern
- 4 sliders with live updates:
  - Rotation: 0-360° (0° default)
  - Spacing: 5-50px (10px default)
  - Opacity: 0-100% (80% default)
  - Scale: 0.5-2.0× (1.0× default)
- Slider style (Lake aesthetic):
  - Track height: 4px
  - Track color: #e0e0e0
  - Active track: #667eea
  - Thumb: 20x20px white with shadow
  - Dragging: Thumb scale(1.2)
- Apply/Cancel buttons at bottom

**Interactions:**
- Slider drag → Update preview in real-time
- Apply → Save settings and dismiss
- Cancel → Revert and dismiss
- Tap outside → Same as Cancel

#### 3. Auto-Hide Behavior
**Implementation:**
- Timer-based auto-hide after 3 seconds of inactivity
- UI elements to auto-hide:
  - Layer selector panel
  - Brush palette
  - Top navigation bar (if exists)
- Fade-out animation: 0.3s ease-out, opacity 0
- Tap anywhere (except canvas) → Show UI again
- Drawing gesture → Keep UI hidden
- Zoom/pan gesture → Show UI

**Code Structure:**
```swift
class EnhancedCanvasViewController: UIViewController {
    private var autoHideTimer: Timer?
    private var isUIVisible = true

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
        UIView.animate(withDuration: 0.3) {
            self.layerSelectorView.alpha = 0
            self.brushPaletteView.alpha = 0
        }
        isUIVisible = false
    }

    private func showUI() {
        guard !isUIVisible else { return }
        UIView.animate(withDuration: 0.3) {
            self.layerSelectorView.alpha = 1
            self.brushPaletteView.alpha = 1
        }
        isUIVisible = true
        scheduleAutoHide()
    }
}
```

**Acceptance Criteria:**
- ✅ Layer selector displays all layers with thumbnails
- ✅ Can switch between layers
- ✅ Visibility toggle works
- ✅ Brush settings panel slides up smoothly
- ✅ Sliders update pattern preview in real-time
- ✅ Settings persist when applied
- ✅ Auto-hide works after 3 seconds
- ✅ UI returns on tap
- ✅ Lake aesthetic matches design brief

---

### Task 3.3: Completion Screen 🎉
**Duration:** 2 days
**Files:** `CompletionViewController.swift`

#### Deliverables:

**Visual Design:**
```
┌─────────────────────────────────────┐
│         ✨                          │
│      (bounce)                       │
│                                     │
│     Beautiful                       │
│                                     │
│  You completed                      │
│  "Mountain Sunset"                  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │                              │  │
│  │    Your finished artwork     │  │
│  │    (shows all layers)        │  │
│  │                              │  │
│  └──────────────────────────────┘  │
│                                     │
│      ╭──────────╮  ╭──────────╮    │
│      │  Share   │  │   Next   │    │
│      ╰──────────╯  ╰──────────╯    │
│                                     │
└─────────────────────────────────────┘
```

**Features:**
1. Gradient background: #667eea → #764ba2
2. Celebration emoji: ✨ (80pt, bounce animation)
3. Title: "Beautiful" (32pt light, white)
4. Subtitle: "You completed [Template Name]" (18pt regular, white)
5. Artwork preview: 280×280px with shadow and radius
6. Action buttons:
   - Share: Opens UIActivityViewController
   - Next: Returns to template gallery

**Animation Sequence:**
```swift
1. Background fades in (0.3s, delay 0s)
2. Emoji bounces in (0.4s, delay 0.2s, spring animation)
3. Text fades in (0.4s, delay 0.4s)
4. Artwork zooms in (0.6s, delay 0.6s, scale 0.8→1.0)
5. Buttons fade in (0.3s, delay 1.0s)
```

**Share Functionality:**
- Export canvas to PNG (2048×2048 resolution)
- Include all visible layers, composited
- Save to temporary file
- Present UIActivityViewController with image
- Options: Save to Photos, Share via Messages/Social, etc.

**Trigger:**
- Show completion screen when:
  - All layers have at least one stroke drawn
  - User taps "Complete" button (add to canvas UI)
  - Or automatically after template is "complete"

**Acceptance Criteria:**
- ✅ Beautiful gradient background
- ✅ Smooth animation sequence
- ✅ Artwork displays correctly
- ✅ Share exports high-quality PNG
- ✅ Share sheet works
- ✅ Next button returns to gallery
- ✅ Haptic feedback on completion

---

### Task 3.4: Lake Aesthetic Polish 🎨
**Duration:** 2 days (ongoing throughout other tasks)
**Files:** `DesignTokens.swift` (update), All view controllers

#### Deliverables:

#### 1. Update DesignTokens.swift
Add missing Lake aesthetic components:
```swift
// Add to DesignTokens.Colors
static let gradientSunrise = [
    UIColor(hex: "ffecd2"),
    UIColor(hex: "fcb69f")
]
static let gradientOcean = [
    UIColor(hex: "a8edea"),
    UIColor(hex: "fed6e3")
]
static let gradientLavender = [
    UIColor(hex: "667eea"),
    UIColor(hex: "764ba2")
]
static let gradientMint = [
    UIColor(hex: "48c6ef"),
    UIColor(hex: "6f86d6")
]

// Add to DesignTokens.Shadows
static let subtle = CALayer.Shadow(
    color: UIColor.black,
    alpha: 0.06,
    x: 0, y: 2,
    blur: 8,
    spread: 0
)
static let card = CALayer.Shadow(
    color: UIColor.black,
    alpha: 0.1,
    x: 0, y: 4,
    blur: 16,
    spread: 0
)
static let floating = CALayer.Shadow(
    color: UIColor.black,
    alpha: 0.12,
    x: 0, y: 8,
    blur: 24,
    spread: 0
)
static let dramatic = CALayer.Shadow(
    color: UIColor.black,
    alpha: 0.15,
    x: 0, y: 20,
    blur: 60,
    spread: 0
)

// Add to DesignTokens
enum BlurEffects {
    static let light: CGFloat = 10
    static let medium: CGFloat = 20
    static let heavy: CGFloat = 40
}

enum Animation {
    static let durationFast: TimeInterval = 0.2
    static let durationMedium: TimeInterval = 0.3
    static let durationSlow: TimeInterval = 0.4
    static let spring = UISpringTimingParameters(
        dampingRatio: 0.7,
        initialVelocity: CGVector(dx: 0, dy: 0)
    )
}
```

#### 2. Gradient Helpers
```swift
extension UIView {
    func applyGradient(colors: [UIColor], direction: GradientDirection = .topToBottom) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map { $0.cgColor }

        switch direction {
        case .topToBottom:
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        case .leftToRight:
            gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        case .diagonal:
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        }

        layer.insertSublayer(gradientLayer, at: 0)
    }

    enum GradientDirection {
        case topToBottom, leftToRight, diagonal
    }
}
```

#### 3. Blur Effect Views
```swift
extension UIView {
    func addBlurEffect(style: UIBlurEffect.Style = .systemUltraThinMaterial) {
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(blurView, at: 0)
    }
}
```

#### 4. Shadow Helpers
```swift
extension CALayer {
    struct Shadow {
        let color: UIColor
        let alpha: Float
        let x: CGFloat
        let y: CGFloat
        let blur: CGFloat
        let spread: CGFloat
    }

    func applyShadow(_ shadow: Shadow) {
        shadowColor = shadow.color.cgColor
        shadowOpacity = shadow.alpha
        shadowOffset = CGSize(width: shadow.x, height: shadow.y)
        shadowRadius = shadow.blur / 2

        if shadow.spread == 0 {
            shadowPath = nil
        } else {
            let dx = -shadow.spread
            let rect = bounds.insetBy(dx: dx, dy: dx)
            shadowPath = UIBezierPath(rect: rect).cgPath
        }
    }
}
```

**Apply Throughout:**
- All floating panels use backdrop blur
- All cards have appropriate shadows
- Buttons use gradient backgrounds
- Template gallery has gradient background
- Completion screen has gradient background
- All animations use DesignTokens durations
- All colors from DesignTokens (no hardcoded colors)

**Acceptance Criteria:**
- ✅ All gradients match Lake aesthetic
- ✅ All blur effects work correctly
- ✅ All shadows match design specifications
- ✅ No hardcoded colors in view controllers
- ✅ Animations feel smooth and calming
- ✅ Overall aesthetic matches Lake app

---

### Task 3.5: Enhanced Rendering Features 🖥️
**Duration:** 3 days
**Files:** `EnhancedMetalRenderer.swift`, `Shaders.metal`

#### Deliverables:

#### 1. Proper Multi-Layer Compositing
**Current Issue:** `compositeLayersForDisplay()` returns only first visible layer

**Fix:**
```swift
private func compositeLayersForDisplay() -> MTLTexture? {
    guard let outputTexture = textureManager?.createBlankTexture(size: canvasSize),
          let commandBuffer = commandQueue.makeCommandBuffer(),
          let compositePipeline = compositePipelineState else {
        return nil
    }

    // Clear to white background
    textureManager?.clearTexture(
        outputTexture,
        to: MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1),
        commandBuffer: commandBuffer
    )

    // Composite each visible layer in order
    var currentTexture = outputTexture
    for layer in layerManager.layers where layer.isVisible {
        guard let layerTexture = layerTextures[layer.id] else { continue }

        // Create intermediate texture for result
        guard let nextTexture = textureManager?.createBlankTexture(size: canvasSize) else {
            continue
        }

        // Composite current + layer → next
        compositeLayer(
            base: currentTexture,
            layer: layerTexture,
            mask: layerMaskTextures[layer.id],
            opacity: layer.opacity,
            blendMode: layer.blendMode,
            output: nextTexture,
            commandBuffer: commandBuffer
        )

        currentTexture = nextTexture
    }

    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    return currentTexture
}

private func compositeLayer(
    base: MTLTexture,
    layer: MTLTexture,
    mask: MTLTexture?,
    opacity: Float,
    blendMode: Layer.BlendMode,
    output: MTLTexture,
    commandBuffer: MTLCommandBuffer
) {
    // Use composite shader to blend layers
    // Implementation using composite_fragment shader
    // ...
}
```

#### 2. Blend Modes Implementation
**Add to Shaders.metal:**
```metal
// Blend mode functions
float4 blendNormal(float4 base, float4 layer, float alpha) {
    return base * (1.0 - alpha) + layer * alpha;
}

float4 blendMultiply(float4 base, float4 layer, float alpha) {
    float4 blended = base * layer;
    return blendNormal(base, blended, alpha);
}

float4 blendScreen(float4 base, float4 layer, float alpha) {
    float4 blended = 1.0 - (1.0 - base) * (1.0 - layer);
    return blendNormal(base, blended, alpha);
}

float4 blendOverlay(float4 base, float4 layer, float alpha) {
    float4 blended;
    blended.rgb = mix(
        2.0 * base.rgb * layer.rgb,
        1.0 - 2.0 * (1.0 - base.rgb) * (1.0 - layer.rgb),
        step(0.5, base.rgb)
    );
    blended.a = 1.0;
    return blendNormal(base, blended, alpha);
}

// Updated composite fragment shader
fragment float4 composite_fragment(
    CompositeVertexOut in [[stage_in]],
    texture2d<float> baseTexture [[texture(0)]],
    texture2d<float> layerTexture [[texture(1)]],
    texture2d<float> maskTexture [[texture(2)]],
    constant float &opacity [[buffer(0)]],
    constant int &blendMode [[buffer(1)]]
) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);

    float4 baseColor = baseTexture.sample(textureSampler, in.texCoord);
    float4 layerColor = layerTexture.sample(textureSampler, in.texCoord);
    float maskValue = maskTexture.sample(textureSampler, in.texCoord).r;

    float alpha = layerColor.a * maskValue * opacity;

    float4 result;
    switch (blendMode) {
        case 0: // Normal
            result = blendNormal(baseColor, layerColor, alpha);
            break;
        case 1: // Multiply
            result = blendMultiply(baseColor, layerColor, alpha);
            break;
        case 2: // Screen
            result = blendScreen(baseColor, layerColor, alpha);
            break;
        case 3: // Overlay
            result = blendOverlay(baseColor, layerColor, alpha);
            break;
        default:
            result = blendNormal(baseColor, layerColor, alpha);
    }

    result.a = baseColor.a;
    return result;
}
```

#### 3. Mask Clipping
**Implementation:**
- Create mask texture for each layer from template
- Mask textures are grayscale: white (1.0) = draw, black (0.0) = clip
- Use mask in composite shader (already supported)
- Load mask images from template data

#### 4. Zoom/Pan Viewport Transform
**Add to EnhancedMetalRenderer:**
```swift
struct ViewportTransform {
    var zoom: Float
    var offsetX: Float
    var offsetY: Float

    func toMatrix() -> simd_float4x4 {
        // Create transform matrix for viewport
        var matrix = matrix_identity_float4x4

        // Apply zoom (scale)
        matrix.columns.0.x = zoom
        matrix.columns.1.y = zoom

        // Apply offset (translation)
        matrix.columns.3.x = offsetX
        matrix.columns.3.y = offsetY

        return matrix
    }
}

// Pass to shaders as uniform buffer
var viewportTransform: ViewportTransform = ViewportTransform(zoom: 1.0, offsetX: 0, offsetY: 0)
```

**Update display shaders to use transform:**
```metal
vertex CompositeVertexOut display_vertex(
    uint vertexID [[vertex_id]],
    constant float4x4 &transform [[buffer(0)]]
) {
    // Apply viewport transform
    float4 position = float4(positions[vertexID], 0.0, 1.0);
    position = transform * position;

    CompositeVertexOut out;
    out.position = position;
    out.texCoord = positions[vertexID] * 0.5 + 0.5;
    return out;
}
```

**Acceptance Criteria:**
- ✅ Multiple layers composite correctly
- ✅ Layer opacity works
- ✅ Blend modes (normal, multiply, screen, overlay) work
- ✅ Mask clipping prevents drawing outside layer bounds
- ✅ Zoom/pan viewport updates rendering
- ✅ Performance maintained (60fps)

---

## File Structure Changes

### New Files to Create:
```
InkApp/
├── Models/
│   └── Template.swift                    [NEW]
├── ViewControllers/
│   ├── TemplateGalleryViewController.swift  [NEW]
│   └── CompletionViewController.swift       [NEW]
└── Views/
    ├── TemplateCollectionViewCell.swift     [NEW]
    ├── LayerSelectorView.swift              [NEW]
    └── BrushSettingsPanel.swift             [NEW]
```

### Files to Modify:
```
InkApp/
├── Supporting Files/
│   └── DesignTokens.swift                [MODIFY - Add gradients, shadows, blur]
├── Supporting Files/
│   └── Extensions.swift                  [MODIFY - Add gradient, blur, shadow helpers]
├── ViewControllers/
│   └── EnhancedCanvasViewController.swift [MODIFY - Add UI panels, auto-hide]
├── Rendering/
│   └── EnhancedMetalRenderer.swift       [MODIFY - Fix compositing, add blend modes]
└── Rendering/
    └── Shaders.metal                      [MODIFY - Add blend mode functions]
```

---

## Testing Plan

### Unit Tests
Create `TemplateTests.swift`:
- Template model creation
- Template loading from JSON
- Category filtering

### Manual Testing Checklist

#### Template Gallery:
- [ ] Gallery displays all templates
- [ ] Grid layout responsive (2-col iPad, 1-col iPhone)
- [ ] Category filters work
- [ ] Tap template navigates to canvas
- [ ] Card animations smooth
- [ ] Gradients look beautiful
- [ ] Scroll performance good

#### Layer Selector:
- [ ] All layers display
- [ ] Thumbnails update correctly
- [ ] Can switch layers
- [ ] Visibility toggle works
- [ ] Selected state visible
- [ ] Lock prevents drawing
- [ ] Add layer works

#### Brush Settings:
- [ ] Panel slides up smoothly
- [ ] Pattern preview updates live
- [ ] Sliders work smoothly
- [ ] Value labels update
- [ ] Apply saves settings
- [ ] Cancel reverts changes
- [ ] Settings persist across reopens

#### Auto-Hide:
- [ ] UI hides after 3 seconds
- [ ] Tap shows UI again
- [ ] Drawing keeps UI hidden
- [ ] Animation smooth

#### Completion Screen:
- [ ] Animation sequence beautiful
- [ ] Artwork displays correctly
- [ ] Share exports PNG
- [ ] Share sheet works
- [ ] Next returns to gallery
- [ ] Haptic feedback triggers

#### Rendering:
- [ ] Multiple layers composite correctly
- [ ] Opacity works
- [ ] Blend modes work
- [ ] Mask clipping works
- [ ] Zoom/pan updates viewport
- [ ] Performance maintained

---

## Implementation Schedule

### Week 4 (Days 1-5):
**Monday-Tuesday (Days 1-2):**
- Task 3.1: Template Gallery (Part 1)
  - Create Template model
  - Create TemplateGalleryViewController
  - Create TemplateCollectionViewCell
  - Basic grid layout working

**Wednesday (Day 3):**
- Task 3.1: Template Gallery (Part 2)
  - Add category filters
  - Add 10 sample templates
  - Polish animations and transitions
  - Navigation to canvas

**Thursday (Day 4):**
- Task 3.2: Enhanced Canvas UI (Part 1)
  - Create LayerSelectorView
  - Integrate with EnhancedCanvasViewController
  - Layer switching works

**Friday (Day 5):**
- Task 3.2: Enhanced Canvas UI (Part 2)
  - Create BrushSettingsPanel
  - Add sliders and live preview
  - Integration complete

### Week 5 (Days 6-10):
**Monday (Day 6):**
- Task 3.2: Enhanced Canvas UI (Part 3)
  - Implement auto-hide behavior
  - Polish animations
  - Bug fixes

**Tuesday (Day 7):**
- Task 3.3: Completion Screen (Part 1)
  - Create CompletionViewController
  - Layout and styling
  - Animation sequence

**Wednesday (Day 8):**
- Task 3.3: Completion Screen (Part 2)
  - Share functionality
  - Integration with canvas
  - Trigger logic

**Thursday (Day 9):**
- Task 3.5: Enhanced Rendering (Part 1)
  - Fix multi-layer compositing
  - Implement blend modes

**Friday (Day 10):**
- Task 3.5: Enhanced Rendering (Part 2)
  - Mask clipping
  - Zoom/pan viewport
  - Performance optimization

### Weekend/Buffer:
- Task 3.4: Lake Aesthetic Polish (ongoing)
- Bug fixes and testing
- Documentation updates

---

## Priority & Risk Assessment

### Must-Have (P0):
- ✅ Template Gallery with navigation
- ✅ Layer Selector with switching
- ✅ Brush Settings Panel
- ✅ Multi-layer compositing fix

### Should-Have (P1):
- ✅ Completion Screen with sharing
- ✅ Auto-hide behavior
- ✅ Blend modes
- ✅ Lake aesthetic polish

### Nice-to-Have (P2):
- Mask clipping (can defer to Week 6-7)
- Zoom/pan viewport transform (can defer)
- Buffer pooling optimization (can defer)

### Risks:
1. **Multi-layer compositing complexity**
   - Mitigation: Start simple, iterate
   - Fallback: Single visible layer (current state)

2. **Performance with multiple layers**
   - Mitigation: Profile early, optimize
   - Fallback: Limit to 5 layers max

3. **UI animation performance**
   - Mitigation: Use Core Animation, not manual updates
   - Fallback: Reduce animation complexity

4. **Template asset creation**
   - Mitigation: Start with simple placeholder templates
   - Fallback: Use solid color shapes

---

## Success Criteria

### Week 4-5 Complete When:
- [ ] Template gallery fully functional
- [ ] Can browse and select templates
- [ ] Layer selector allows switching layers
- [ ] Brush settings panel works with live preview
- [ ] Auto-hide behavior works
- [ ] Completion screen shows on finish
- [ ] Share exports PNG correctly
- [ ] Multiple layers composite correctly
- [ ] Lake aesthetic applied throughout
- [ ] All animations smooth (60fps)
- [ ] No crashes or major bugs

### Quality Metrics:
- UI responsiveness: < 16ms per frame
- Animation smoothness: 60fps constant
- Memory usage: < 250MB
- Cold start time: < 2s
- Template load time: < 0.5s
- Share export time: < 3s

---

## Next Steps After Week 4-5

### Week 6-7: Polish & Integration
- Mask clipping implementation
- Zoom/pan viewport transform
- Performance optimization
- Bug fixes from Week 4-5
- Load actual template images (50 templates)
- Export system refinement

### Week 8: Pre-Beta Polish
- Final UI/UX tweaks
- Accessibility support
- Error handling improvements
- Crash prevention
- Memory optimization

---

**Status:** 📋 Ready to Start Implementation
**Next Action:** Begin Task 3.1 - Template Gallery

**Notes:**
- Keep Lake aesthetic in mind for every design decision
- Test on actual device frequently (especially iPad with Apple Pencil)
- Profile performance after each major feature
- Get user feedback on aesthetics and UX

---

*Related Documents:*
- 04-Development-Roadmap.md (Week 5-6 tasks)
- 03-UI-UX-Design-Brief.md (Lake aesthetic specs)
- PULL-REQUEST-SUMMARY.md (Week 1-3 summary)
- CRITICAL-FIXES.md (Applied fixes)
