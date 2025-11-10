# Development Roadmap & Task Breakdown
## Pattern Drawing App - "Ink"

**Version:** 1.0  
**Date:** November 10, 2025  
**Author:** Engineering Team

---

## 1. Project Timeline Overview

```
Total Duration: 16 weeks (4 months)

Phase 1: Core Development (8 weeks)
Phase 2: Beta Testing (2 weeks)
Phase 3: Content Creation (4 weeks)
Phase 4: Launch Preparation (2 weeks)
```

```
Week 1-2:   Foundation & Setup
Week 3-4:   Brush Engine
Week 5-6:   UI/UX Implementation
Week 7-8:   Polish & Integration
Week 9-10:  Beta Testing
Week 11-14: Content Creation
Week 15-16: Launch Prep
Week 17:    App Store Launch
```

---

## 2. Phase 1: Core Development (Weeks 1-8)

### Week 1-2: Foundation & Metal Setup

**Goals:**
- Project setup
- Metal rendering pipeline
- Basic canvas display

#### Task 1.1: Project Initialization
**Assigned to:** Backend/Setup Agent  
**Duration:** 1 day  
**Dependencies:** None

**Deliverables:**
- [x] Create Xcode project
- [x] Configure build settings
- [x] Setup folder structure
- [x] Add Info.plist permissions
- [x] Create .gitignore

**File Structure:**
```
InkApp/
├── App/
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
├── Models/
│   ├── Layer.swift
│   ├── Brush.swift
│   └── Project.swift
├── Views/
│   └── (UI components)
├── ViewControllers/
│   └── CanvasViewController.swift
├── Rendering/
│   ├── MetalRenderer.swift
│   └── Shaders.metal
├── Managers/
│   ├── LayerManager.swift
│   └── BrushEngine.swift
├── Resources/
│   ├── Templates/
│   ├── Patterns/
│   └── Assets.xcassets
└── Supporting Files/
    └── Info.plist
```

**Acceptance Criteria:**
- Project builds successfully
- No warnings
- Runs on simulator

---

#### Task 1.2: Metal Setup & Basic Renderer
**Assigned to:** Graphics Agent  
**Duration:** 3 days  
**Dependencies:** Task 1.1

**Deliverables:**
- [x] MTKView setup
- [x] Metal device initialization
- [x] Command queue creation
- [x] Basic render pipeline
- [x] Clear color rendering

**Implementation Guide:**

```swift
// File: Rendering/MetalRenderer.swift

import Metal
import MetalKit

class MetalRenderer: NSObject {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState?
    
    init?(metalView: MTKView) {
        // Get default Metal device
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return nil
        }
        self.device = device
        metalView.device = device
        
        // Create command queue
        guard let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        self.commandQueue = commandQueue
        
        super.init()
        
        // Setup pipeline
        setupPipeline()
        
        metalView.delegate = self
    }
    
    private func setupPipeline() {
        // Load shaders
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Could not load default library")
        }
        
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
        
        // Create pipeline descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        // Create pipeline state
        do {
            pipelineState = try device.makeRenderPipelineState(
                descriptor: pipelineDescriptor
            )
        } catch {
            fatalError("Could not create pipeline state: \(error)")
        }
    }
}

extension MetalRenderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle size changes
    }
    
    func draw(in view: MTKView) {
        // Get command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        
        // Get render pass descriptor
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(
                descriptor: renderPassDescriptor
              ) else {
            return
        }
        
        // Clear to white
        renderPassDescriptor.colorAttachments[0].clearColor = 
            MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        
        // End encoding
        renderEncoder.endEncoding()
        
        // Present drawable
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        
        // Commit
        commandBuffer.commit()
    }
}
```

```metal
// File: Rendering/Shaders.metal

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = float4(in.position, 0.0, 1.0);
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    return float4(1.0, 1.0, 1.0, 1.0); // White
}
```

**Acceptance Criteria:**
- White canvas displays in MTKView
- No Metal errors in console
- Runs at 60fps

---

#### Task 1.3: Canvas View Controller
**Assigned to:** UI Agent  
**Duration:** 2 days  
**Dependencies:** Task 1.2

**Deliverables:**
- [x] CanvasViewController
- [x] MTKView integration
- [x] Touch handling skeleton
- [x] Zoom/pan gestures

**Implementation:**

```swift
// File: ViewControllers/CanvasViewController.swift

import UIKit
import MetalKit

class CanvasViewController: UIViewController {
    
    // MARK: - Properties
    var metalView: MTKView!
    var renderer: MetalRenderer!
    
    // Canvas state
    var canvasSize: CGSize = CGSize(width: 2048, height: 2048)
    var zoom: CGFloat = 1.0
    var offset: CGPoint = .zero
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMetalView()
        setupGestures()
    }
    
    // MARK: - Setup
    private func setupMetalView() {
        metalView = MTKView(frame: view.bounds)
        metalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(metalView)
        
        renderer = MetalRenderer(metalView: metalView)
        
        // Configure view
        metalView.clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        metalView.colorPixelFormat = .bgra8Unorm
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
    
    // MARK: - Gesture Handlers
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard gesture.state == .changed else { return }
        
        let newZoom = zoom * gesture.scale
        zoom = max(0.5, min(4.0, newZoom))
        
        gesture.scale = 1.0
        
        // TODO: Update renderer transform
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state == .changed else { return }
        
        let translation = gesture.translation(in: metalView)
        offset.x += translation.x
        offset.y += translation.y
        
        gesture.setTranslation(.zero, in: metalView)
        
        // TODO: Update renderer transform
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: metalView)
        
        // TODO: Begin stroke
        print("Touch began at: \(point)")
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: metalView)
        
        // TODO: Continue stroke
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // TODO: End stroke
        print("Touch ended")
    }
}
```

**Acceptance Criteria:**
- Canvas displays in view controller
- Pinch zoom works (0.5× to 4×)
- Two-finger pan works
- Touch events logged to console

---

### Week 3-4: Brush Engine Core

**Goals:**
- Pattern generation algorithms
- Stroke stamping system
- Basic drawing works

#### Task 2.1: Data Models
**Assigned to:** Backend Agent  
**Duration:** 1 day  
**Dependencies:** Task 1.1

**Deliverables:**
- [x] Layer model
- [x] Brush model
- [x] Stroke model
- [x] Project model

**Implementation:**

```swift
// File: Models/Layer.swift

import Metal
import CoreGraphics

struct Layer {
    let id: UUID
    var name: String
    var maskTexture: MTLTexture
    var contentTexture: MTLTexture
    var opacity: Float
    var blendMode: BlendMode
    var isVisible: Bool
    var isLocked: Bool
    
    enum BlendMode {
        case normal
        case multiply
        case screen
        // Add more as needed
    }
}

// File: Models/Brush.swift

struct PatternBrush {
    var type: PatternType
    var rotation: Float = 0.0      // degrees (0-360)
    var spacing: Float = 10.0      // pixels
    var opacity: Float = 1.0       // 0-1
    var scale: Float = 1.0         // 0.5-2.0
    var color: Color = .black
    
    enum PatternType {
        case parallelLines
        case crossHatch
        case dots
        case contourLines
        case waves
    }
    
    struct Color {
        let red: Float
        let green: Float
        let blue: Float
        
        static let black = Color(red: 0, green: 0, blue: 0)
    }
}

// File: Models/Stroke.swift

struct Stroke {
    var points: [StrokePoint]
    var brush: PatternBrush
    var layerId: UUID
}

struct StrokePoint {
    var position: CGPoint
    var pressure: Float
    var timestamp: TimeInterval
}

// File: Models/Project.swift

struct Project {
    let id: UUID
    var name: String
    var canvasSize: CGSize
    var layers: [Layer]
    var baseImageData: Data?
    var createdAt: Date
    var modifiedAt: Date
}
```

**Acceptance Criteria:**
- All models compile
- Properties are appropriately typed
- Models are Codable (for save/load)

---

#### Task 2.2: Pattern Generation Algorithms
**Assigned to:** Algorithm Agent  
**Duration:** 3 days  
**Dependencies:** Task 2.1

**Deliverables:**
- [x] Parallel lines generator
- [x] Cross-hatch generator
- [x] Dots generator
- [x] Contour lines generator
- [x] Waves generator

**Implementation:**

```swift
// File: Managers/PatternGenerator.swift

import CoreGraphics

class PatternGenerator {
    
    // MARK: - Parallel Lines
    static func generateParallelLines(
        center: CGPoint,
        rotation: Float,
        spacing: Float,
        length: Float = 20.0,
        count: Int = 7
    ) -> [Line] {
        var lines: [Line] = []
        
        let rad = rotation * .pi / 180
        let perpX = cos(rad + .pi/2)
        let perpY = sin(rad + .pi/2)
        
        for i in -count/2...count/2 {
            let offset = Float(i) * spacing
            let offsetX = perpX * offset
            let offsetY = perpY * offset
            
            let start = CGPoint(
                x: CGFloat(center.x + offsetX - cos(rad) * length/2),
                y: CGFloat(center.y + offsetY - sin(rad) * length/2)
            )
            let end = CGPoint(
                x: CGFloat(center.x + offsetX + cos(rad) * length/2),
                y: CGFloat(center.y + offsetY + sin(rad) * length/2)
            )
            
            lines.append(Line(start: start, end: end))
        }
        
        return lines
    }
    
    // MARK: - Cross-Hatch
    static func generateCrossHatch(
        center: CGPoint,
        rotation: Float,
        spacing: Float,
        length: Float = 20.0
    ) -> [Line] {
        let horizontal = generateParallelLines(
            center: center,
            rotation: rotation,
            spacing: spacing,
            length: length
        )
        let vertical = generateParallelLines(
            center: center,
            rotation: rotation + 90,
            spacing: spacing,
            length: length
        )
        
        return horizontal + vertical
    }
    
    // MARK: - Dots
    static func generateDots(
        center: CGPoint,
        spacing: Float,
        radius: Float = 2.0,
        gridSize: Int = 5
    ) -> [Circle] {
        var circles: [Circle] = []
        
        for i in -gridSize...gridSize {
            for j in -gridSize...gridSize {
                let x = center.x + CGFloat(Float(i) * spacing)
                let y = center.y + CGFloat(Float(j) * spacing)
                circles.append(Circle(
                    center: CGPoint(x: x, y: y),
                    radius: CGFloat(radius)
                ))
            }
        }
        
        return circles
    }
    
    // MARK: - Contour Lines
    static func generateContourLines(
        center: CGPoint,
        spacing: Float,
        count: Int = 5
    ) -> [Arc] {
        var arcs: [Arc] = []
        
        for i in 0..<count {
            let radius = CGFloat(Float(i + 1) * spacing)
            arcs.append(Arc(
                center: center,
                radius: radius,
                startAngle: 0,
                endAngle: 2 * .pi
            ))
        }
        
        return arcs
    }
    
    // MARK: - Waves
    static func generateWaves(
        center: CGPoint,
        spacing: Float,
        amplitude: Float = 3.0,
        wavelength: Float = 20.0,
        count: Int = 5,
        width: Float = 40.0
    ) -> [[CGPoint]] {
        var waves: [[CGPoint]] = []
        
        for i in 0..<count {
            var wave: [CGPoint] = []
            let yOffset = Float(i) * spacing - Float(count/2) * spacing
            
            let steps = Int(width / 2)
            for step in 0...steps {
                let x = Float(step) * 2
                let y = sin(x / wavelength * .pi * 2) * amplitude + yOffset
                wave.append(CGPoint(
                    x: CGFloat(center.x + x - width/2),
                    y: CGFloat(center.y + y)
                ))
            }
            
            waves.append(wave)
        }
        
        return waves
    }
}

// MARK: - Supporting Types

struct Line {
    let start: CGPoint
    let end: CGPoint
}

struct Circle {
    let center: CGPoint
    let radius: CGFloat
}

struct Arc {
    let center: CGPoint
    let radius: CGFloat
    let startAngle: CGFloat
    let endAngle: CGFloat
}
```

**Acceptance Criteria:**
- All pattern generators work correctly
- Visual tests pass (can render patterns)
- Performance: < 5ms per pattern generation

---

#### Task 2.3: Brush Engine
**Assigned to:** Graphics Agent  
**Duration:** 4 days  
**Dependencies:** Task 2.2

**Deliverables:**
- [x] BrushEngine class
- [x] Stroke stamping logic
- [x] Stroke smoothing (Catmull-Rom)
- [x] Pressure handling

**Implementation:** (See Technical Specification document, section 3.1 & 3.5)

**Acceptance Criteria:**
- Drawing creates patterns along stroke
- Patterns respect spacing parameter
- Strokes are smoothed
- Pressure affects opacity/size

---

### Week 5-6: UI/UX Implementation

**Goals:**
- Implement all UI screens
- Lake aesthetic applied
- Navigation working

#### Task 3.1: Template Gallery
**Assigned to:** UI Agent  
**Duration:** 3 days  
**Dependencies:** None

**Deliverables:**
- [x] Gallery view controller
- [x] Template grid layout
- [x] Template card design
- [x] Template selection

**Acceptance Criteria:**
- Grid displays templates
- Lake aesthetic matches design
- Tap navigates to canvas
- Smooth transitions

---

#### Task 3.2: Canvas UI Components
**Assigned to:** UI Agent  
**Duration:** 3 days  
**Dependencies:** Task 1.3

**Deliverables:**
- [x] Layer selector panel
- [x] Brush palette
- [x] Settings panel
- [x] Auto-hide behavior

**Acceptance Criteria:**
- All panels match Lake aesthetic
- Auto-hide after 3s
- Smooth animations
- Floating panel blur effect

---

#### Task 3.3: Completion Screen
**Assigned to:** UI Agent  
**Duration:** 2 days  
**Dependencies:** Task 3.2

**Deliverables:**
- [x] Completion view controller
- [x] Celebration animation
- [x] Share functionality
- [x] Next artwork button

**Acceptance Criteria:**
- Beautiful gradient background
- Smooth animation sequence
- Share sheet works
- Returns to gallery

---

### Week 7-8: Polish & Integration

**Goals:**
- Connect all components
- Export functionality
- Bug fixes
- Performance optimization

#### Task 4.1: Layer System Integration
**Assigned to:** Integration Agent  
**Duration:** 3 days  
**Dependencies:** All previous tasks

**Deliverables:**
- [x] LayerManager implementation
- [x] Layer switching
- [x] Mask clipping working
- [x] Layer visibility toggle

**Acceptance Criteria:**
- Drawing respects layer masks
- Switch layers seamlessly
- No cross-layer bleeding
- Performance maintained

---

#### Task 4.2: Export System
**Assigned to:** Backend Agent  
**Duration:** 2 days  
**Dependencies:** Task 4.1

**Deliverables:**
- [x] PNG export
- [x] High-res rendering
- [x] Share sheet integration
- [x] Save to Photos

**Acceptance Criteria:**
- Export produces 300 DPI PNG
- Image quality is high
- Share sheet opens correctly
- Photos permission handled

---

#### Task 4.3: Performance Optimization
**Assigned to:** Performance Agent  
**Duration:** 3 days  
**Dependencies:** Task 4.2

**Deliverables:**
- [x] Profile app with Instruments
- [x] Optimize render pipeline
- [x] Reduce memory usage
- [x] Fix any lag

**Acceptance Criteria:**
- 60fps during drawing
- < 200MB memory usage
- Export < 5s for 2K image
- No crashes

---

## 3. Phase 2: Beta Testing (Weeks 9-10)

### Week 9-10: TestFlight Beta

**Goals:**
- 100 beta testers
- Collect feedback
- Fix critical bugs

#### Task 5.1: TestFlight Setup
**Assigned to:** DevOps Agent  
**Duration:** 1 day

**Deliverables:**
- [x] App Store Connect setup
- [x] TestFlight build uploaded
- [x] External testing enabled
- [x] Invite beta testers

---

#### Task 5.2: Bug Fixing Sprint
**Assigned to:** All Agents  
**Duration:** 9 days

**Process:**
1. Collect bug reports daily
2. Triage by severity
3. Fix critical bugs immediately
4. Push updates every 2-3 days
5. Monitor crash reports

**Success Metrics:**
- < 3% crash rate
- 80%+ complete first artwork
- 4.0+ average rating from testers

---

## 4. Phase 3: Content Creation (Weeks 11-14)

### Goals:
- 50 templates created
- 15 pattern brushes
- Themed collections

#### Task 6.1: Template Creation
**Assigned to:** Content Agent  
**Duration:** 4 weeks

**Deliverables:**
- [x] 50 flat-color templates
- [x] Pre-separated layers for each
- [x] 5 themed collections
- [x] Template metadata

**Categories:**
- Nature (15 templates)
- Abstract (10 templates)
- Animals (10 templates)
- Landscapes (10 templates)
- Patterns (5 templates)

---

## 5. Phase 4: Launch Prep (Weeks 15-16)

### Week 15-16: App Store & Marketing

#### Task 7.1: App Store Listing
**Assigned to:** Marketing Agent  
**Duration:** 3 days

**Deliverables:**
- [x] App Store description
- [x] Screenshots (all sizes)
- [x] App preview video
- [x] Keywords research
- [x] Pricing setup

---

#### Task 7.2: Final Build
**Assigned to:** DevOps Agent  
**Duration:** 2 days

**Deliverables:**
- [x] Production build
- [x] App Store submission
- [x] Review response ready

---

#### Task 7.3: Marketing Materials
**Assigned to:** Marketing Agent  
**Duration:** 5 days

**Deliverables:**
- [x] Landing page
- [x] Social media assets
- [x] Press kit
- [x] Influencer outreach list

---

## 6. Agent Assignment Guide

### Agent Roles & Responsibilities

**Backend Agent:**
- Data models
- File I/O
- Project save/load
- Export system

**Graphics Agent:**
- Metal rendering
- Shaders
- Brush engine
- Pattern generation

**UI Agent:**
- All view controllers
- UI components
- Animations
- Layout

**Integration Agent:**
- Connect components
- System integration
- Cross-module communication

**Performance Agent:**
- Profiling
- Optimization
- Memory management
- Bug fixes

**Content Agent:**
- Template creation
- Asset preparation
- Metadata

**DevOps Agent:**
- Build configuration
- TestFlight
- App Store submission

**Marketing Agent:**
- App Store listing
- Marketing materials
- User acquisition

---

## 7. Communication Protocol

### Daily Sync (Async)
Each agent posts:
1. Tasks completed today
2. Blockers encountered
3. Tasks for tomorrow
4. Questions for other agents

### Code Review Process
1. Create pull request
2. Tag relevant agents
3. Wait for approval (1-2 agents)
4. Merge to develop branch

### Dependency Management
- Check dependencies before starting task
- Communicate delays immediately
- Use feature flags for incomplete features

---

## 8. Testing Checklist

### Per Task Testing
- [ ] Unit tests written
- [ ] Code compiles without warnings
- [ ] Manual testing done
- [ ] Screenshots attached to PR

### Integration Testing
- [ ] Works with other modules
- [ ] No regressions
- [ ] Performance acceptable
- [ ] Memory leaks checked

### Pre-Release Testing
- [ ] Full user flow works
- [ ] All templates load
- [ ] Export works
- [ ] Share works
- [ ] No crashes in 30min session

---

## 9. Success Criteria

### MVP Complete When:
- [x] 10 templates available
- [x] 5 pattern brushes working
- [x] Can complete full artwork
- [x] Export to PNG works
- [x] Lake aesthetic applied
- [x] 60fps drawing performance
- [x] < 3% crash rate

### Ready for Launch When:
- [x] 50+ templates
- [x] 15+ brushes
- [x] 4.2+ beta rating
- [x] App Store approved
- [x] Marketing ready
- [x] Support email setup

---

## 10. Risk Mitigation

### Technical Risks
**Risk:** Metal rendering too complex  
**Mitigation:** Start with simple shader, iterate

**Risk:** Performance issues on old devices  
**Mitigation:** Profile early, graceful degradation

**Risk:** App Store rejection  
**Mitigation:** Follow guidelines, test thoroughly

### Timeline Risks
**Risk:** Tasks take longer than estimated  
**Mitigation:** 20% buffer in schedule, prioritize features

**Risk:** Agent blocked by dependencies  
**Mitigation:** Clear communication, parallel tasks where possible

---

**Document Status:** ✅ Ready to Start Development  
**Next Action:** Assign tasks to agents

---

*Related Documents:*
- 01-PRD-Product-Requirements.md
- 02-Technical-Specification.md
- 03-UI-UX-Design-Brief.md
