# UI/UX Design Brief
## Pattern Drawing App - "Ink"

**Version:** 1.0  
**Date:** November 10, 2025  
**Author:** Design Team

---

## 1. Design Philosophy

### Core Principles

**Calm Over Excitement**
- Meditative experience, not gamified stimulation
- Gentle feedback, not aggressive rewards
- Soft transitions, not snappy animations
- Breathing room in layouts

**Simple Over Comprehensive**
- One primary action visible at a time
- Progressive disclosure of features
- Clear visual hierarchy
- Minimal cognitive load

**Beautiful Over Functional**
- Aesthetics are part of the meditation
- Form and function equally important
- Every pixel considered
- Inspired by nature and tranquility

**Guided Over Open-Ended**
- Clear next steps without hand-holding
- Suggestions without forcing
- Freedom within structure
- Success is inevitable

---

## 2. Lake Aesthetic Reference

### Visual DNA

**Color Palette:**
```
Primary Gradients:
├── Sunrise: #ffecd2 → #fcb69f
├── Ocean: #a8edea → #fed6e3  
├── Lavender: #667eea → #764ba2
└── Mint: #48c6ef → #6f86d6

Background Tints:
├── Off-white: #f8f9fa
├── Soft gray: #ecf0f1
└── Cloud: #fafbfc

Accent Colors:
├── Primary: #667eea (soft purple-blue)
├── Success: #4caf50 (muted green)
├── Subtle: #bdc3c7 (light gray)
└── Text: #2c3e50 (dark blue-gray, not black)

Never Use:
❌ Pure black (#000000)
❌ Harsh reds (#ff0000)
❌ Neon/saturated colors
❌ High contrast combinations
```

**Typography:**
```
Font Family: SF Pro (system default on iOS)

Weights to Use:
├── Light (300) - Main titles
├── Regular (400) - Body text
└── Semibold (600) - Emphasis only

Font Sizes:
├── Hero: 32pt (light)
├── Title: 24pt (light)
├── Headline: 18pt (regular)
├── Body: 15pt (regular)
├── Caption: 13pt (regular)
└── Tiny: 11pt (regular)

Line Height: 1.4-1.5x font size
Letter Spacing: 
  - Titles: +2% (airy)
  - Body: 0% (default)

Case:
  - Prefer sentence case
  - Lowercase for brand ("ink")
  - Never ALL CAPS for body text
```

**Spacing System:**
```
Base Unit: 4px

Spacing Scale:
├── xs: 4px
├── sm: 8px
├── md: 12px
├── lg: 16px
├── xl: 20px
├── 2xl: 24px
├── 3xl: 32px
└── 4xl: 40px

Padding:
  - Cards: 20-24px
  - Buttons: 12-16px vertical, 20-32px horizontal
  - Sections: 24-32px

Margins:
  - Between sections: 24-32px
  - Between elements: 12-16px
  - Between related items: 8px
```

**Shapes & Radius:**
```
Border Radius Scale:
├── Small: 8px (icons, badges)
├── Medium: 12px (buttons, inputs)
├── Large: 16px (cards, panels)
├── XLarge: 20px (modal sheets)
└── XXLarge: 24px (canvas, major elements)

Shadows:
├── Subtle: 
│   └── 0 2px 8px rgba(0,0,0,0.06)
├── Card:
│   └── 0 4px 16px rgba(0,0,0,0.1)
├── Floating:
│   └── 0 8px 24px rgba(0,0,0,0.12)
└── Dramatic:
    └── 0 20px 60px rgba(0,0,0,0.15)

Blur Effects:
├── Light: 10px
├── Medium: 20px (most common)
└── Heavy: 40px
```

---

## 3. Component Library

### 3.1 Buttons

**Primary Button:**
```
Style:
- Background: Gradient (#667eea → #764ba2)
- Foreground: White
- Height: 48px minimum
- Radius: 24px (pill shape)
- Font: 15pt semibold
- Shadow: 0 4px 12px rgba(102,126,234,0.3)

States:
- Default: Full opacity
- Pressed: Scale(0.96), opacity 0.9
- Disabled: Opacity 0.5

Animation:
- Transition: all 0.2s ease
- Haptic: Light impact on press
```

**Secondary Button:**
```
Style:
- Background: rgba(255,255,255,0.9)
- Foreground: #667eea
- Border: 2px solid #667eea
- Height: 48px
- Radius: 24px
- Font: 15pt semibold

States:
- Default: Full opacity
- Pressed: Background #f0f3ff, scale(0.98)
- Disabled: Opacity 0.5
```

**Icon Button:**
```
Style:
- Size: 44x44pt (minimum tap target)
- Background: rgba(255,255,255,0.9)
- Backdrop blur: 10px
- Radius: 22px (circle)
- Icon size: 20-24px
- Shadow: 0 4px 12px rgba(0,0,0,0.1)

States:
- Default: Full opacity
- Pressed: Scale(0.9)
- Active: Background gradient, white icon
```

### 3.2 Cards & Panels

**Floating Panel:**
```
Style:
- Background: rgba(255,255,255,0.95)
- Backdrop blur: 20px
- Radius: 20px
- Shadow: 0 12px 40px rgba(0,0,0,0.15)
- Padding: 20px

Usage:
- Tool palettes
- Brush settings
- Layer selector
- Modals

Animation:
- Enter: Fade in + scale from 0.9 to 1.0 (0.3s ease-out)
- Exit: Fade out + scale to 0.95 (0.2s ease-in)
```

**Template Card:**
```
Style:
- Background: White
- Radius: 16px
- Shadow: 0 4px 16px rgba(0,0,0,0.08)
- Aspect ratio: 1:1 (square)
- Image: Full bleed with 16px radius

Content:
- Image (fills card)
- Overlay gradient on bottom (for text)
- Title: 15pt semibold, white
- Subtitle: 13pt regular, rgba(255,255,255,0.8)

States:
- Default: Full opacity
- Pressed: Scale(0.97)
- Selected: Border 3px #667eea
```

### 3.3 Inputs & Sliders

**Slider:**
```
Style:
- Track height: 4px
- Track color: #e0e0e0
- Active track: #667eea
- Thumb size: 20x20px
- Thumb color: White
- Thumb shadow: 0 2px 6px rgba(0,0,0,0.15)

States:
- Default: As above
- Dragging: Thumb scale(1.2)

Labels:
- Min/Max: 11pt regular, #999
- Current value: 15pt semibold, #667eea
```

**Toggle:**
```
Style:
- Width: 52px
- Height: 32px
- Radius: 16px (pill)
- Off: Background #e0e0e0
- On: Background #667eea
- Thumb: 28x28px circle, white

Animation:
- Toggle: 0.3s ease with spring (damping 0.7)
- Haptic: Light impact on change
```

### 3.4 Lists & Layers

**Layer List Item:**
```
Layout:
┌────────────────────────────────────┐
│ [👁] [Thumbnail] Layer Name    [•] │
│      48x48px     15pt        Edit  │
└────────────────────────────────────┘

Style:
- Height: 64px
- Background: White (default), #f0f3ff (selected)
- Border bottom: 1px #f0f0f0
- Padding: 12px

Thumbnail:
- Size: 48x48px
- Radius: 8px
- Border: 1px #e0e0e0

Visibility Toggle:
- Icon: Eye (visible), Eye-slash (hidden)
- Size: 24x24px
- Color: #667eea (visible), #ccc (hidden)
```

---

## 4. Screen Layouts

### 4.1 Main Canvas Screen

```
┌─────────────────────────────────────┐
│ ┌─┐                           ┌─┐  │ ← Top bar (auto-hide after 3s)
│ │☰│         ink               │⚙│  │   Height: 56px
│ └─┘                           └─┘  │   Background: rgba(255,255,255,0.15)
│                                     │   Backdrop blur: 10px
│  ┌──────────────────────────────┐  │
│  │                              │  │
│  │                              │  │
│  │                              │  │
│  │        Canvas Area           │  │ ← Canvas (dominates)
│  │      (your artwork)          │  │   Center of screen
│  │                              │  │   Max width/height: 95% of screen
│  │                              │  │   Shadow: 0 20px 60px rgba(0,0,0,0.2)
│  │                              │  │   Radius: 20px
│  └──────────────────────────────┘  │
│                                     │
│  ╭─────────────────────────────╮   │ ← Layer selector (bottom)
│  │ □Sky  □Mountain □Water      │   │   Height: 80px
│  ╰─────────────────────────────╯   │   Floating panel style
│                                     │
│     ╭──────────────────────╮       │ ← Brush palette (bottom)
│     │ ⊙  ≡  ×  ···  ~     │       │   Height: 64px
│     ╰──────────────────────╯       │   Floating panel style
│                                     │   Gap from layer: 12px
└─────────────────────────────────────┘

Interactions:
- Tap canvas → UI fades (3s delay)
- Move finger → UI stays visible
- Tap layer → Activates, shows pattern suggestion
- Tap brush → Opens brush settings panel
```

### 4.2 Template Gallery

```
┌─────────────────────────────────────┐
│  ← Templates                    [×] │ ← Header bar
│                                     │   Height: 56px
├─────────────────────────────────────┤
│                                     │
│  ┌──────┐ ┌──────┐ ┌──────┐       │ ← Grid of templates
│  │      │ │      │ │      │       │   2 columns (iPad) / 1 column (iPhone)
│  │ Img  │ │ Img  │ │ Img  │       │   Spacing: 16px
│  │      │ │      │ │      │       │   Aspect: 1:1
│  └──────┘ └──────┘ └──────┘       │
│   Title    Title    Title         │   Title below: 15pt semibold
│   Tag      Tag      Tag           │   Tags: 11pt regular, #999
│                                     │
│  ┌──────┐ ┌──────┐ ┌──────┐       │
│  │      │ │      │ │      │       │
│  │ Img  │ │ Img  │ │ Img  │       │
│  │      │ │      │ │      │       │
│  └──────┘ └──────┘ └──────┘       │
│                                     │
├─────────────────────────────────────┤
│ Filters: [Nature] [Abstract] [Art] │ ← Filter chips
│                                     │   Height: 48px
└─────────────────────────────────────┘

Background: Gradient (sunrise/ocean)
Scroll: Vertical, bounces
```

### 4.3 Brush Settings Panel

```
╭─────────────────────────────────────╮
│  Brush Settings                     │ ← Panel header
│                                     │   Height: 48px
├─────────────────────────────────────┤
│  Pattern Preview                    │ ← Large preview
│  ┌─────────────────────────────┐   │   Square, centered
│  │                             │   │   Shows pattern result
│  │   ⊙⊙⊙⊙⊙⊙⊙⊙⊙⊙⊙⊙⊙⊙         │   │   Size: 200x200px
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│  Rotation                      45°  │ ← Slider + value
│  ├─────────●─────────────────┤     │   Label: 13pt regular
│                                     │   Value: 15pt semibold, #667eea
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
│      [Apply]         [Cancel]       │ ← Action buttons
╰─────────────────────────────────────╯   Height: 56px

Style:
- Background: rgba(255,255,255,0.98)
- Backdrop blur: 30px
- Radius: 24px (top corners)
- Shadow: 0 -8px 32px rgba(0,0,0,0.15)
- Padding: 20px
- Animation: Slide up from bottom (0.4s ease-out)
```

### 4.4 Completion Screen

```
┌─────────────────────────────────────┐
│                                     │
│         ✨                          │ ← Emoji animation
│      (bounce)                       │   Font size: 80px
│                                     │   Bounces in
│     Beautiful                       │
│                                     │ ← Title
│  You completed                      │   32pt light
│  "Mountain Sunset"                  │   Letter spacing: +2%
│                                     │
│  ┌──────────────────────────────┐  │ ← Artwork preview
│  │                              │  │   Size: 280x280px
│  │    Your finished artwork     │  │   Shadow: 0 20px 60px rgba(0,0,0,0.3)
│  │    (shows all layers)        │  │   Radius: 20px
│  │                              │  │   Zoom in animation
│  └──────────────────────────────┘  │
│                                     │
│      ╭──────────╮  ╭──────────╮    │ ← Action buttons
│      │  Share   │  │   Next   │    │   Height: 48px
│      ╰──────────╯  ╰──────────╯    │   Gap: 12px
│                                     │
└─────────────────────────────────────┘

Background: Gradient #667eea → #764ba2
Text: White
Animation sequence:
  1. Background fades in (0.3s)
  2. Emoji bounces in (0.4s, delay 0.2s)
  3. Text fades in (0.4s, delay 0.4s)
  4. Artwork zooms in (0.6s, delay 0.6s)
  5. Buttons fade in (0.3s, delay 1.0s)
```

---

## 5. Interaction Patterns

### 5.1 Touch Gestures

**Drawing (Canvas):**
```
Gesture: Single finger drag
Response: Draw pattern strokes
Feedback: 
  - Visual: Immediate stroke rendering
  - Haptic: Very light continuous during draw
  - Audio: Optional soft pen sound

Requirements:
- Latency: < 16ms
- Stroke smoothing: Catmull-Rom
- Pressure: Use if Apple Pencil detected
```

**Zoom (Canvas):**
```
Gesture: Pinch (2 fingers)
Response: Scale canvas
Constraints:
  - Min zoom: 0.5× (fit canvas to screen)
  - Max zoom: 4× (detail work)
  - Anchor: Pinch center point

Feedback:
  - Visual: Smooth scale
  - Haptic: None (too frequent)
```

**Pan (Canvas):**
```
Gesture: Two finger drag
Response: Move canvas viewport
Constraints:
  - Bounded by canvas edges (with bounce)
  - Momentum scrolling

Feedback:
  - Visual: Canvas moves
  - Haptic: None
```

**Undo:**
```
Gesture: Two finger tap OR shake device
Response: Undo last stroke
Confirmation: Brief "Undone" toast (1s)
Feedback:
  - Visual: Stroke fades out
  - Haptic: Medium impact
```

### 5.2 Transitions

**Screen Transitions:**
```
Gallery → Canvas:
  - Duration: 0.4s
  - Easing: ease-out
  - Type: Cross-dissolve + scale
  - Canvas scales from 0.9 to 1.0

Canvas → Completion:
  - Duration: 0.5s
  - Easing: ease-in-out
  - Type: Canvas fades, completion fades in
  - Background gradient crossfades
```

**Panel Animations:**
```
Brush Settings Panel:
  - Enter: Slide up from bottom (0.3s ease-out)
  - Exit: Slide down (0.25s ease-in)
  - Backdrop: Fade in/out (0.2s)

Layer Selector:
  - Toggle: Fade + slide vertical (0.2s)
  - Select: Highlight color change (0.15s)
```

**Button Press:**
```
All buttons:
  - Press: Scale(0.96), duration 0.1s
  - Release: Scale(1.0), duration 0.15s, spring damping 0.7
  - Haptic: Light impact on press
```

### 5.3 Loading States

**Template Loading:**
```
Visual:
  - Shimmer effect on thumbnail
  - Skeleton: Rounded rect, #f0f0f0
  - Animate: Shimmer left to right (1.5s infinite)

Text:
  - "Loading..." below skeleton
  - 13pt regular, #999
```

**Export Processing:**
```
Visual:
  - Full-screen overlay, rgba(0,0,0,0.6)
  - White card center, 280px wide
  - Spinner: System activity indicator
  - Progress bar if available

Text:
  - "Creating your artwork..."
  - 15pt regular, centered
  - Below spinner

Cancelable: Yes, "Cancel" button below
```

### 5.4 Error States

**Network Error:**
```
Visual:
  - Toast notification
  - Background: #e74c3c (soft red)
  - Icon: ⚠️
  - Text: White

Message: 
  - "Couldn't load template"
  - 13pt regular
  - Dismiss: Auto (4s) or manual tap

Position: Top of screen, safe area inset
```

**Export Error:**
```
Visual:
  - Alert dialog (system style)
  - Title: "Export Failed"
  - Message: "Please try again or contact support"

Actions:
  - Primary: "Try Again"
  - Secondary: "Cancel"
```

---

## 6. Accessibility

### 6.1 VoiceOver Support

**Canvas:**
```
Label: "Drawing canvas, [template name]"
Hint: "Double tap and drag to draw patterns"
Value: "[layer name] layer selected"
```

**Layer Selector:**
```
Label: "[Layer name] layer"
Hint: "Double tap to select this layer"
Value: "Selected" / "Not selected"
```

**Brush Button:**
```
Label: "[Pattern name] brush"
Hint: "Double tap to open brush settings"
```

**Sliders:**
```
Label: "[Property name] slider"
Value: "[Current value]"
Hint: "Swipe up or down to adjust"
Adjustable: Yes
Increment: Small steps (1-5%)
```

### 6.2 Dynamic Type

```
Support sizes: XS through XXXL (7 sizes)

Scaling behavior:
- Body text: Scales 1:1
- Titles: Scales 0.8:1 (max 40pt)
- UI labels: Scales 0.9:1 (max 20pt)
- Canvas: Does not scale

Layout:
- Adjust spacing proportionally
- Maintain minimum tap targets (44pt)
- Reflow text if needed
```

### 6.3 Color Blindness

```
Strategies:
- Don't rely on color alone
- Use icons + labels
- High contrast mode available
- Pattern differentiation uses shape, not just color

Testing:
- Deuteranopia (red-green)
- Protanopia (red-green)
- Tritanopia (blue-yellow)
```

### 6.4 Motor Accessibility

```
Features:
- Large touch targets (min 44×44pt)
- Adjustable brush size (larger for limited dexterity)
- Optional stroke stabilization (extra smoothing)
- Alternative to shake gesture (button for undo)
- Dwell cursor support (future)
```

---

## 7. Responsiveness

### 7.1 iPhone Layout

```
Portrait (primary):
- Canvas: 90% screen width
- Layer selector: Horizontal scroll, bottom
- Brush palette: Horizontal scroll, below layers
- Settings: Bottom sheet (modal)

Landscape:
- Canvas: Center, 80% screen
- Tools: Right sidebar (floating)
```

### 7.2 iPad Layout

```
Portrait:
- Canvas: Center, max 70% width
- Layer selector: Bottom, 2-3 items visible
- Brush palette: Bottom, all items visible
- Settings: Popover (right side)

Landscape:
- Canvas: Center-left
- Layers: Right sidebar (permanent)
- Brushes: Below layers
- More screen real estate for canvas
```

### 7.3 Safe Areas

```
Respect:
- Top safe area (notch/dynamic island)
- Bottom safe area (home indicator)
- Leading/trailing safe areas

Padding from safe area:
- Minimum: 12px
- Preferred: 16-20px
```

---

## 8. Design Tokens (Code)

```swift
// Colors
extension UIColor {
    static let inkPrimary = UIColor(hex: "667eea")
    static let inkSecondary = UIColor(hex: "764ba2")
    static let inkSuccess = UIColor(hex: "4caf50")
    static let inkTextPrimary = UIColor(hex: "2c3e50")
    static let inkTextSecondary = UIColor(hex: "7f8c8d")
    static let inkBackground = UIColor(hex: "f8f9fa")
}

// Spacing
extension CGFloat {
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 20
    static let spacing2XL: CGFloat = 24
    static let spacing3XL: CGFloat = 32
    static let spacing4XL: CGFloat = 40
}

// Radius
extension CGFloat {
    static let radiusSM: CGFloat = 8
    static let radiusMD: CGFloat = 12
    static let radiusLG: CGFloat = 16
    static let radiusXL: CGFloat = 20
    static let radiusXXL: CGFloat = 24
}

// Typography
extension UIFont {
    static let inkHero = UIFont.systemFont(ofSize: 32, weight: .light)
    static let inkTitle = UIFont.systemFont(ofSize: 24, weight: .light)
    static let inkHeadline = UIFont.systemFont(ofSize: 18, weight: .regular)
    static let inkBody = UIFont.systemFont(ofSize: 15, weight: .regular)
    static let inkCaption = UIFont.systemFont(ofSize: 13, weight: .regular)
}

// Shadows
extension CALayer {
    func applyShadowSubtle() {
        shadowColor = UIColor.black.cgColor
        shadowOpacity = 0.06
        shadowOffset = CGSize(width: 0, height: 2)
        shadowRadius = 8
    }
    
    func applyShadowCard() {
        shadowColor = UIColor.black.cgColor
        shadowOpacity = 0.1
        shadowOffset = CGSize(width: 0, height: 4)
        shadowRadius = 16
    }
}
```

---

## 9. Asset Specifications

### 9.1 App Icon

```
Sizes required:
- 1024×1024px (App Store)
- 180×180px (iPhone)
- 167×167px (iPad Pro)
- 152×152px (iPad)

Style:
- Gradient background (#667eea → #764ba2)
- White icon/symbol centered
- Radius: System default (iOS applies)
- No text in icon

Export:
- PNG, sRGB color space
- No transparency
- No rounded corners (iOS applies)
```

### 9.2 Screenshots

```
Required sizes:
- iPhone 6.7": 1290×2796px (Pro Max)
- iPhone 6.5": 1284×2778px (Plus)
- iPad Pro 12.9": 2048×2732px

Content:
- Screenshot 1: Main canvas with beautiful artwork
- Screenshot 2: Template gallery
- Screenshot 3: Layer selection UI
- Screenshot 4: Brush settings
- Screenshot 5: Completed artwork

Style:
- Gradient backgrounds
- Minimal text overlays
- Show actual UI, not mockups
```

### 9.3 Pattern Textures

```
Format: PNG, 8-bit alpha
Sizes: Power of 2 (256×256, 512×512)
Seamless: Yes (tile without visible seams)

Examples:
- diagonal_lines.png
- cross_hatch.png
- dots.png
- contour_lines.png
- waves.png

Optimization:
- Compress with TinyPNG
- Include @2x and @3x variants
- Black patterns on transparent
```

---

## 10. Animation Specifications

### 10.1 Timing Functions

```swift
// Ease out (entering)
let easeOut = CAMediaTimingFunction(
    controlPoints: 0.0, 0.0, 0.2, 1.0
)

// Ease in (exiting)
let easeIn = CAMediaTimingFunction(
    controlPoints: 0.4, 0.0, 1.0, 1.0
)

// Ease in-out (transitioning)
let easeInOut = CAMediaTimingFunction(
    controlPoints: 0.4, 0.0, 0.2, 1.0
)

// Spring (bouncy)
let spring = CASpringAnimation()
spring.damping = 0.7
spring.initialVelocity = 0.5
```

### 10.2 Durations

```
Very fast: 0.1-0.15s (button presses)
Fast: 0.2-0.3s (UI element transitions)
Medium: 0.3-0.4s (screen transitions)
Slow: 0.5-0.6s (dramatic reveals)

Rule: Faster for smaller movements, slower for larger
```

---

## 11. Checklist for Developers

**Before coding any screen:**
- [ ] Review this document
- [ ] Check color palette (no #000000!)
- [ ] Verify spacing uses system (4px increments)
- [ ] Confirm radius values from guide
- [ ] Plan animations (don't skip!)
- [ ] Consider both iPhone and iPad layouts
- [ ] Test with Dynamic Type
- [ ] Add VoiceOver labels
- [ ] Implement haptic feedback
- [ ] Use design tokens (not hard-coded values)

---

## 12. Resources

**Figma File:** (Link to design mockups)
**Asset Library:** (Link to Zeplin/asset export)
**Style Guide:** This document
**Prototype:** (Link to interactive prototype)

---

**Document Status:** ✅ Approved for Implementation  
**Design Review:** Weekly sync with design team

---

*Related Documents:*
- 01-PRD-Product-Requirements.md
- 02-Technical-Specification.md
- 04-Architecture-Document.md
