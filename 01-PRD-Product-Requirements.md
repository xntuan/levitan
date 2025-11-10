# Product Requirements Document (PRD)
## Pattern Drawing App - "Ink" (Working Title)

**Version:** 1.0  
**Date:** November 10, 2025  
**Author:** Product Team

---

## 1. Executive Summary

### Vision
Create a meditative drawing app that combines the calming experience of Lake with the tactile satisfaction of pen & ink pattern drawing. Users transform pre-designed flat-color illustrations into textured artworks using guided pattern brushes.

### Core Value Proposition
- **Simple:** Import template, choose pattern, draw. No artistic skill required.
- **Meditative:** Rhythmic pattern drawing creates flow state (like zentangle/mandala)
- **Beautiful:** Professional-looking results, shareable on social media
- **Guided:** Pre-separated layers and pattern suggestions eliminate decision paralysis

### Success Metrics (Year 1)
- 100K downloads
- 4.3+ App Store rating
- 3% free-to-premium conversion
- $150K annual revenue
- 30% D7 retention

---

## 2. User Personas

### Primary: "Mindful Maya"
- **Age:** 28-45
- **Profile:** Works in tech/creative field, stressed, seeks mindful activities
- **Pain:** Adult coloring feels too passive, meditation is hard, journaling feels like work
- **Need:** Active but simple creative outlet for stress relief
- **Behavior:** Uses Lake, follows meditation accounts on Instagram, buys zen products

### Secondary: "Creative Casey"
- **Age:** 22-35
- **Profile:** Appreciates art but "can't draw," follows art accounts
- **Pain:** Intimidated by Procreate, wants to create art without blank canvas
- **Need:** Guided creativity with professional results
- **Behavior:** Saves art tutorials, follows illustration artists, buys art supplies

### Tertiary: "Art Student Sam"
- **Age:** 18-25
- **Profile:** Learning illustration, wants to practice hatching techniques
- **Pain:** Traditional practice feels like homework
- **Need:** Fun way to practice pen & ink techniques
- **Behavior:** Watches YouTube art tutorials, owns Procreate, active on art Reddit

---

## 3. User Stories & Use Cases

### Core User Flow
```
1. User opens app → sees beautiful template gallery (Lake-style aesthetic)
2. Selects template (e.g., "Mountain Sunset") → template loads on canvas
3. Sees layer panel with 4 layers (Sky, Mountain, Water, Trees)
4. Taps "Sky" layer → layer highlights, pattern suggestion appears
5. Chooses "Diagonal Lines" pattern → adjusts rotation slider
6. Draws on canvas → patterns appear where they draw
7. Continues for other layers → artwork gradually fills with textures
8. Taps "Done" → sees completion celebration
9. Exports to photos or shares to Instagram
```

### User Stories

**Must Have (MVP):**
- As a user, I want to import pre-made templates so I don't start with blank canvas
- As a user, I want to select layers so I know where to draw
- As a user, I want pattern brushes so I don't have to draw each line
- As a user, I want drawing to stay within layer boundaries so I don't "color outside lines"
- As a user, I want to undo mistakes so I feel safe experimenting
- As a user, I want to export high-quality images so I can share/print

**Should Have (V1.1):**
- As a user, I want brush dynamics (pressure, tilt) so drawing feels natural
- As a user, I want to see progress percentage so I feel accomplished
- As a user, I want pattern preview so I know what brush will do
- As a user, I want optional ambient sounds for deeper meditation

**Could Have (V1.2+):**
- As a user, I want to import my own PSD files (premium)
- As a user, I want custom pattern creator (advanced)
- As a user, I want animation of my drawing process (time-lapse)
- As a user, I want to collaborate on artworks with friends

---

## 4. Feature Requirements

### 4.1 Template System

**Description:** Pre-designed flat-color illustrations with pre-separated layers

**Requirements:**
- Support for PNG with layers OR PSD import
- Each template includes:
  - Base illustration (flat colors)
  - 4-8 separate layers with masks
  - Layer names (e.g., "Sky", "Mountain")
  - Suggested pattern for each layer
  - Suggested color scheme
- Template metadata (artist, difficulty, theme)
- Preview thumbnail
- Template gallery with categories

**Acceptance Criteria:**
- User can browse 10+ templates in MVP
- Selecting template loads within 2 seconds
- Layers are clearly separated and labeled
- Masks prevent drawing outside layer boundaries

### 4.2 Layer Management

**Description:** System to select and manage drawing layers

**Requirements:**
- Display list of layers (bottom panel)
- Highlight active layer
- Show layer preview thumbnail
- Show layer completion status (e.g., "60% filled")
- Toggle layer visibility (eye icon)
- Lock/unlock layers

**Acceptance Criteria:**
- Tapping layer makes it active
- Active layer has visual indicator
- Drawing only affects active layer
- Layer visibility toggles work instantly

### 4.3 Pattern Brush Engine

**Description:** Core drawing system that creates patterns from brush strokes

**Requirements:**

**MVP Patterns:**
1. Parallel Lines (diagonal hatching)
2. Cross-Hatch (perpendicular lines)
3. Dots/Stippling
4. Contour Lines (following form)
5. Waves (horizontal wavy lines)

**Brush Parameters:**
- Rotation (0-360°) - angle of pattern
- Spacing (pixels) - density of pattern
- Opacity (0-100%) - transparency
- Scale (50-200%) - size of pattern elements

**Technical Requirements:**
- Real-time rendering at 60fps on iPad Pro
- Pattern "stamping" along stroke path
- Pressure sensitivity (Apple Pencil)
- Tilt sensitivity (optional)
- Stroke smoothing (no jagged lines)
- Respects layer mask (clips to layer boundary)

**Acceptance Criteria:**
- Drawing feels immediate (no lag)
- Patterns are clearly visible
- Pressure affects opacity/size
- Drawing stops at layer edges
- Brush parameters update in real-time

### 4.4 Canvas & Rendering

**Description:** Display system for artwork and drawing surface

**Requirements:**
- Support up to 2048x2048 canvas (retina)
- Zoom and pan gestures
- Multi-touch support
- Preview mode (low-res) for performance
- Export mode (high-res) for quality
- GPU-accelerated rendering (Metal)
- Layer compositing with blend modes

**Technical Requirements:**
- Use Metal for GPU rendering
- Texture streaming for large canvases
- Render pipeline:
  1. Base layer (flat colors)
  2. Pattern layers (user strokes)
  3. Guide overlay (optional)
  4. UI overlay
- Off-screen rendering for export

**Acceptance Criteria:**
- Smooth 60fps drawing on all supported devices
- Zoom works smoothly (2-finger pinch)
- Pan works smoothly (2-finger drag)
- Export produces sharp 300 DPI image

### 4.5 UI/UX (Lake Aesthetic)

**Description:** Calming, minimal interface design

**Requirements:**

**Visual Design:**
- Pastel gradient backgrounds
- Soft shadows (blur: 20-40px)
- Rounded corners (16-24px radius)
- Translucent panels (backdrop blur)
- Gentle color palette (#667eea, #764ba2, #48c6ef)
- Light typography (300-400 weight)

**Interaction Design:**
- Auto-hide toolbars after 3 seconds of inactivity
- Smooth transitions (0.3-0.5s ease)
- Gentle scale animations (0.95 on tap)
- Haptic feedback on interactions
- No jarring popups or alerts
- Success states with celebration animations

**Layout:**
- Canvas dominates screen (80%)
- Floating tool panels (translucent)
- Minimal always-visible UI
- Clear visual hierarchy

**Acceptance Criteria:**
- App feels calming, not technical
- UI doesn't distract from canvas
- Animations are smooth, not snappy
- Colors match Lake aesthetic
- No visual clutter

### 4.6 Export & Sharing

**Description:** Save and share completed artwork

**Requirements:**
- Export to Photos (PNG)
- Share to Instagram/Twitter/etc
- High-resolution (300 DPI)
- Option to remove watermark (premium)
- Include metadata (artist credit, app name)
- Time-lapse video export (future)

**Acceptance Criteria:**
- Export completes within 5 seconds
- Image is sharp and print-quality
- Share sheet opens correctly
- Watermark is visible but not obtrusive (free)

### 4.7 Tutorial & Onboarding

**Description:** First-time user experience

**Requirements:**
- Welcome screen (skip button)
- Interactive tutorial (optional)
- First artwork is guaranteed success
  - Simple template (3-4 layers)
  - Clear instructions
  - Guided step-by-step
- Tooltips on first use of features
- Help button accessible anytime

**Acceptance Criteria:**
- 80%+ complete first artwork
- Tutorial can be skipped
- New users understand core mechanics in 2 minutes
- Help is accessible but not intrusive

---

## 5. Non-Functional Requirements

### 5.1 Performance
- App launch: < 2 seconds
- Template load: < 2 seconds
- Drawing latency: < 16ms (60fps)
- Export time: < 5 seconds for 2K image
- App size: < 150MB download

### 5.2 Compatibility
- iOS/iPadOS 15.0+
- iPhone 12+ (optimal on larger screens)
- iPad (7th gen)+, iPad Air (3rd gen)+, iPad Pro (all)
- Apple Pencil support (1st & 2nd gen)
- Supports landscape & portrait

### 5.3 Accessibility
- VoiceOver support for UI
- Dynamic Type support
- High contrast mode option
- Color blind friendly (not relying on color alone)
- Left-handed mode (swap UI sides)

### 5.4 Privacy & Data
- No tracking without consent
- No ads during drawing sessions
- Artworks stored locally (not uploaded)
- Optional analytics (opt-in)
- COPPA compliant

---

## 6. Monetization

### Free Tier
- 5 templates
- 5 pattern brushes
- Standard export (watermarked)
- 1 daily free unlock

### Premium ($4.99/month or $29.99/year)
- 100+ templates
- 20+ pattern brushes
- Unlimited access
- High-res export (no watermark)
- Weekly new content
- Custom brush creator (future)
- Ambient sounds
- Priority support

### One-Time Purchases
- Theme packs: $2.99 each
- Artist collections: $4.99 each
- Brush expansion: $1.99

---

## 7. Success Criteria

### MVP Launch Criteria
- ✅ 10 templates available
- ✅ 5 pattern brushes working
- ✅ Layer system functional
- ✅ Export to Photos works
- ✅ No critical bugs
- ✅ 4.0+ beta tester rating
- ✅ < 2 crashes per 100 sessions

### Post-Launch KPIs (30 days)
- 10K+ downloads
- 4.2+ App Store rating
- 25% D1 retention
- 10% D7 retention
- 2% conversion to premium
- < 3% crash rate

---

## 8. Out of Scope (V1.0)

The following features are NOT included in MVP:
- ❌ Custom template import (PSD)
- ❌ Social features (sharing within app)
- ❌ Animation/time-lapse export
- ❌ Collaboration features
- ❌ Web version
- ❌ Android version (iOS first)
- ❌ Custom pattern creator
- ❌ AI-generated templates
- ❌ Print integration
- ❌ Desktop version

---

## 9. Risks & Mitigation

### Risk 1: Technical Performance
**Risk:** Drawing lags on older devices  
**Mitigation:** Extensive device testing, graceful degradation, low-res preview mode

### Risk 2: User Adoption
**Risk:** Learning curve too steep compared to Lake  
**Mitigation:** Killer onboarding, first template guarantees success, video tutorials

### Risk 3: Competition
**Risk:** Lake adds pattern mode  
**Mitigation:** Move fast, build content moat, community features, patent tech

### Risk 4: Content Pipeline
**Risk:** Can't create templates fast enough  
**Mitigation:** Partner with artists, license artwork, community submissions (future)

---

## 10. Timeline

### Phase 1: MVP Development (8 weeks)
- Week 1-2: Core architecture & Metal setup
- Week 3-4: Brush engine & layer system
- Week 5-6: UI/UX implementation
- Week 7-8: Templates & polish

### Phase 2: Beta Testing (2 weeks)
- Week 9-10: TestFlight with 100 users

### Phase 3: Content Creation (4 weeks)
- Week 11-14: Create 50 templates, 15 brushes

### Phase 4: Launch Prep (2 weeks)
- Week 15-16: App Store submission, marketing prep

**Target Launch:** Week 17 (4 months from start)

---

## Appendix A: Glossary

- **Template:** Pre-designed flat-color illustration with layers
- **Layer:** Separate drawing area with mask boundary
- **Pattern:** Repeating visual texture (lines, dots, etc.)
- **Brush:** Tool that generates patterns from strokes
- **Mask:** Invisible boundary that constrains drawing area
- **Stroke:** User's drawing gesture (tap and drag)
- **Stamping:** Technique of placing patterns along stroke path
- **Hatching:** Parallel line pattern technique
- **Cross-hatch:** Perpendicular intersecting lines

---

## Appendix B: References

- Lake app (competitor analysis)
- Procreate brushes (technical reference)
- Zentangle method (meditative inspiration)
- Material Design (iOS adaptation)
- Apple HIG (iOS guidelines)

---

**Document Status:** ✅ Approved for Development  
**Next Review:** After MVP completion

---

*This PRD should be read alongside:*
- 02-Technical-Specification.md
- 03-UI-UX-Design-Brief.md
- 04-Architecture-Document.md
