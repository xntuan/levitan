# Technical Specification
## Pattern Drawing App - "Ink"

**Version:** 1.0  
**Date:** November 10, 2025  
**Author:** Engineering Team

---

## 1. Technical Overview

### 1.1 Architecture Philosophy
- **Native iOS** for performance and Apple Pencil support
- **GPU-first** rendering using Metal framework
- **Raster-based** (not vector) for real-time performance
- **Layer-compositing** model similar to Photoshop
- **Modular design** for maintainability

### 1.2 Technology Stack

```
Platform: iOS/iPadOS 15.0+
Language: Swift 5.5+
Frameworks:
├── UIKit - Main UI framework
├── Metal/MetalKit - GPU rendering ⭐
├── Core Graphics - Image processing
├── Core Image - Filters & effects
├── QuartzCore - Animations
└── AVFoundation - Export (future video)

Third-party (minimal):
├── None required for MVP
└── Optional: PSDocumentProvider for PSD import
```

---

## 2. System Architecture

### 2.1 High-Level Architecture Diagram

```
┌─────────────────────────────────────────┐
│          UI Layer (UIKit)               │
│  ┌──────────┐  ┌──────────┐            │
│  │ Canvas   │  │ Tool     │            │
│  │ View     │  │ Panels   │            │
│  └────┬─────┘  └─────┬────┘            │
└───────┼──────────────┼──────────────────┘
        │              │
┌───────▼──────────────▼──────────────────┐
│      Business Logic Layer               │
│  ┌─────────────┐  ┌─────────────┐      │
│  │ Layer       │  │ Brush       │      │
│  │ Manager     │  │ Engine      │      │
│  └──────┬──────┘  └──────┬──────┘      │
│  ┌──────▼─────────────────▼──────┐     │
│  │    Drawing State Manager      │     │
│  └───────────────┬────────────────┘     │
└──────────────────┼──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│      Rendering Layer (Metal)            │
│  ┌──────────┐  ┌──────────┐            │
│  │ Metal    │  │ Texture  │            │
│  │ Renderer │  │ Manager  │            │
│  └────┬─────┘  └─────┬────┘            │
└───────┼──────────────┼──────────────────┘
        │              │
┌───────▼──────────────▼──────────────────┐
│        Data Layer                       │
│  ┌──────────┐  ┌──────────┐            │
│  │ Template │  │ Project  │            │
│  │ Storage  │  │ Storage  │            │
│  └──────────┘  └──────────┘            │
└─────────────────────────────────────────┘
```

### 2.2 Module Breakdown

#### Module 1: Canvas View (`CanvasViewController`)
**Responsibility:** Touch handling and display
```swift
class CanvasViewController: UIViewController {
    // Properties
    var metalView: MTKView
    var renderer: MetalRenderer
    var layerManager: LayerManager
    var brushEngine: BrushEngine
    
    // Touch handling
    func touchesBegan()
    func touchesMoved()
    func touchesEnded()
    
    // Gesture handling
    func handlePinch() // Zoom
    func handlePan()   // Pan canvas
}
```

#### Module 2: Layer Manager (`LayerManager`)
**Responsibility:** Layer state and operations
```swift
class LayerManager {
    var layers: [Layer]
    var activeLayer: Layer?
    
    func selectLayer(_ id: String)
    func getLayerMask(_ id: String) -> MTLTexture
    func isPointInLayer(_ point: CGPoint, layer: Layer) -> Bool
}

struct Layer {
    let id: UUID
    let name: String
    let maskTexture: MTLTexture  // White = drawable area
    var contentTexture: MTLTexture  // User's strokes
    var opacity: Float
    var blendMode: BlendMode
    var isVisible: Bool
    var isLocked: Bool
}
```

#### Module 3: Brush Engine (`BrushEngine`)
**Responsibility:** Pattern generation and stroke rendering
```swift
class BrushEngine {
    var currentBrush: PatternBrush
    var strokeBuffer: [StrokePoint]
    
    func beginStroke(at: CGPoint, pressure: Float)
    func continueStroke(to: CGPoint, pressure: Float)
    func endStroke()
    
    func generatePatternStamp(
        for brush: PatternBrush,
        at point: CGPoint
    ) -> [Line]
}

struct PatternBrush {
    var type: PatternType
    var rotation: Float      // degrees
    var spacing: Float       // pixels
    var opacity: Float       // 0-1
    var scale: Float         // 0.5-2.0
    
    enum PatternType {
        case parallelLines
        case crossHatch
        case dots
        case contourLines
        case waves
    }
}

struct StrokePoint {
    var position: CGPoint
    var pressure: Float
    var timestamp: TimeInterval
}
```

#### Module 4: Metal Renderer (`MetalRenderer`)
**Responsibility:** GPU rendering pipeline
```swift
class MetalRenderer: NSObject, MTKViewDelegate {
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState
    
    func draw(in view: MTKView)
    
    func renderStroke(
        _ stroke: Stroke,
        to layer: MTLTexture,
        clippedBy mask: MTLTexture
    )
    
    func compositeLayersToScreen(
        _ layers: [Layer],
        viewport: CGRect
    )
}
```

---

## 3. Core Systems Deep Dive

### 3.1 Brush Stamping Algorithm

**Problem:** User draws one stroke, we need to generate pattern along that stroke.

**Solution:**

```swift
func stampPatternAlongStroke(
    points: [StrokePoint],
    brush: PatternBrush,
    layer: Layer
) {
    // 1. Smooth the input points
    let smoothedPoints = catmullRomInterpolation(points)
    
    // 2. Calculate spacing between stamps
    let spacing = brush.spacing * brush.scale
    
    // 3. Walk along stroke path
    var distanceAccumulator: Float = 0.0
    var previousPoint = smoothedPoints[0]
    
    for point in smoothedPoints {
        let distance = point.position.distance(to: previousPoint.position)
        distanceAccumulator += distance
        
        // Time to place stamp?
        if distanceAccumulator >= spacing {
            // Generate pattern at this point
            let pattern = generatePattern(
                type: brush.type,
                center: point.position,
                rotation: brush.rotation,
                scale: brush.scale
            )
            
            // Render to GPU
            renderPattern(
                pattern,
                opacity: brush.opacity * point.pressure,
                to: layer.contentTexture,
                clippedBy: layer.maskTexture
            )
            
            distanceAccumulator = 0.0
        }
        
        previousPoint = point
    }
}
```

### 3.2 Pattern Generation

**Parallel Lines Pattern:**
```swift
func generateParallelLines(
    center: CGPoint,
    rotation: Float,
    spacing: Float,
    count: Int = 7
) -> [Line] {
    var lines: [Line] = []
    let rad = rotation * .pi / 180
    
    // Perpendicular vector
    let perpX = cos(rad + .pi/2)
    let perpY = sin(rad + .pi/2)
    
    // Generate lines around center
    for i in -count/2...count/2 {
        let offset = Float(i) * spacing
        let offsetX = perpX * offset
        let offsetY = perpY * offset
        
        // Line start and end
        let length: Float = 20.0
        let start = CGPoint(
            x: center.x + offsetX - cos(rad) * length/2,
            y: center.y + offsetY - sin(rad) * length/2
        )
        let end = CGPoint(
            x: center.x + offsetX + cos(rad) * length/2,
            y: center.y + offsetY + sin(rad) * length/2
        )
        
        lines.append(Line(start: start, end: end))
    }
    
    return lines
}
```

**Cross-Hatch Pattern:**
```swift
func generateCrossHatch(
    center: CGPoint,
    rotation: Float,
    spacing: Float
) -> [Line] {
    // Generate two sets of parallel lines
    let horizontal = generateParallelLines(
        center: center,
        rotation: rotation,
        spacing: spacing
    )
    let vertical = generateParallelLines(
        center: center,
        rotation: rotation + 90,
        spacing: spacing
    )
    
    return horizontal + vertical
}
```

**Dots Pattern:**
```swift
func generateDots(
    center: CGPoint,
    spacing: Float,
    radius: Float = 2.0
) -> [Circle] {
    var circles: [Circle] = []
    let gridSize = 5
    
    for i in -gridSize...gridSize {
        for j in -gridSize...gridSize {
            let x = center.x + Float(i) * spacing
            let y = center.y + Float(j) * spacing
            circles.append(Circle(
                center: CGPoint(x: x, y: y),
                radius: radius
            ))
        }
    }
    
    return circles
}
```

### 3.3 Metal Rendering Pipeline

**Vertex Shader (lines):**
```metal
struct VertexIn {
    float2 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 worldPosition;
};

vertex VertexOut vertex_main(
    VertexIn in [[stage_in]],
    constant float4x4 &mvpMatrix [[buffer(1)]]
) {
    VertexOut out;
    out.position = mvpMatrix * float4(in.position, 0.0, 1.0);
    out.worldPosition = in.position;
    return out;
}
```

**Fragment Shader (with masking):**
```metal
fragment float4 fragment_pattern(
    VertexOut in [[stage_in]],
    texture2d<float> maskTexture [[texture(0)]],
    constant FragmentUniforms &uniforms [[buffer(0)]]
) {
    constexpr sampler s(
        address::clamp_to_edge,
        filter::linear
    );
    
    // Sample mask at this position
    float2 uv = (in.worldPosition + 1.0) * 0.5;  // NDC to UV
    float mask = maskTexture.sample(s, uv).r;
    
    // Pattern color
    float4 color = float4(
        uniforms.color.rgb,
        uniforms.opacity * mask  // Clip by mask
    );
    
    return color;
}
```

**Render Pass Setup:**
```swift
func renderStroke(
    stroke: Stroke,
    to texture: MTLTexture,
    mask: MTLTexture
) {
    guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
    
    // Setup render pass
    let renderPass = MTLRenderPassDescriptor()
    renderPass.colorAttachments[0].texture = texture
    renderPass.colorAttachments[0].loadAction = .load  // Keep existing
    renderPass.colorAttachments[0].storeAction = .store
    
    // Encoder
    guard let encoder = commandBuffer.makeRenderCommandEncoder(
        descriptor: renderPass
    ) else { return }
    
    encoder.setRenderPipelineState(pipelineState)
    
    // Bind mask texture
    encoder.setFragmentTexture(mask, index: 0)
    
    // Bind uniforms
    var uniforms = FragmentUniforms(
        color: stroke.color,
        opacity: stroke.opacity
    )
    encoder.setFragmentBytes(
        &uniforms,
        length: MemoryLayout<FragmentUniforms>.size,
        index: 0
    )
    
    // Bind geometry
    encoder.setVertexBuffer(stroke.vertexBuffer, offset: 0, index: 0)
    
    // Draw
    encoder.drawPrimitives(
        type: .line,
        vertexStart: 0,
        vertexCount: stroke.vertexCount
    )
    
    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
}
```

### 3.4 Layer Mask System

**Mask Generation from Color:**
```swift
func generateMaskFromColor(
    sourceImage: UIImage,
    targetColor: UIColor,
    tolerance: Float = 0.1
) -> MTLTexture {
    // Convert to Core Image
    let ciImage = CIImage(image: sourceImage)!
    
    // Extract alpha channel (assumes layers are pre-separated)
    let alphaMask = ciImage.applyingFilter("CIMaskToAlpha")
    
    // Apply morphological operations to smooth
    let dilated = alphaMask.applyingFilter("CIMorphologyMaximum", parameters: [
        "inputRadius": 2.0
    ])
    
    let smoothed = dilated.applyingFilter("CIGaussianBlur", parameters: [
        "inputRadius": 1.0
    ])
    
    // Convert to Metal texture
    let context = CIContext(mtlDevice: metalDevice)
    let texture = try! context.createMetalTexture(
        from: smoothed,
        format: .r8Unorm
    )
    
    return texture
}
```

**Alternative: Pre-separated PSD Layers:**
```swift
func loadTemplateFromPSD(_ url: URL) -> Template {
    let provider = PSDocumentProvider(url: url)
    let document = try! provider.loadDocument()
    
    var layers: [Layer] = []
    
    for psdLayer in document.layers {
        // Each PSD layer becomes app layer
        let maskTexture = psdLayer.alphaChannel.toMetalTexture()
        let contentTexture = createEmptyTexture(
            size: document.size,
            format: .rgba8Unorm
        )
        
        let layer = Layer(
            id: UUID(),
            name: psdLayer.name,
            maskTexture: maskTexture,
            contentTexture: contentTexture,
            opacity: psdLayer.opacity,
            blendMode: .normal,
            isVisible: psdLayer.isVisible,
            isLocked: false
        )
        
        layers.append(layer)
    }
    
    return Template(
        id: UUID(),
        name: document.name,
        size: document.size,
        layers: layers,
        baseImage: document.flattenedImage
    )
}
```

### 3.5 Stroke Smoothing

**Catmull-Rom Spline Interpolation:**
```swift
func catmullRomInterpolation(
    points: [CGPoint],
    subdivisions: Int = 10
) -> [CGPoint] {
    guard points.count >= 4 else { return points }
    
    var smoothed: [CGPoint] = []
    smoothed.append(points[0])
    
    for i in 0..<(points.count - 3) {
        let p0 = points[i]
        let p1 = points[i + 1]
        let p2 = points[i + 2]
        let p3 = points[i + 3]
        
        for t in 0..<subdivisions {
            let t = Float(t) / Float(subdivisions)
            let point = catmullRom(p0, p1, p2, p3, t: t)
            smoothed.append(point)
        }
    }
    
    smoothed.append(points.last!)
    return smoothed
}

func catmullRom(
    _ p0: CGPoint,
    _ p1: CGPoint,
    _ p2: CGPoint,
    _ p3: CGPoint,
    t: Float
) -> CGPoint {
    let t2 = t * t
    let t3 = t2 * t
    
    let x = 0.5 * (
        (2 * p1.x) +
        (-p0.x + p2.x) * t +
        (2*p0.x - 5*p1.x + 4*p2.x - p3.x) * t2 +
        (-p0.x + 3*p1.x - 3*p2.x + p3.x) * t3
    )
    
    let y = 0.5 * (
        (2 * p1.y) +
        (-p0.y + p2.y) * t +
        (2*p0.y - 5*p1.y + 4*p2.y - p3.y) * t2 +
        (-p0.y + 3*p1.y - 3*p2.y + p3.y) * t3
    )
    
    return CGPoint(x: x, y: y)
}
```

---

## 4. Data Models & File Formats

### 4.1 Project File Format (JSON)

```json
{
  "version": "1.0",
  "id": "uuid-string",
  "name": "Mountain Sunset",
  "createdAt": "2025-11-10T10:30:00Z",
  "modifiedAt": "2025-11-10T11:45:00Z",
  "canvasSize": {
    "width": 2048,
    "height": 2048
  },
  "baseImage": "base64_encoded_png",
  "layers": [
    {
      "id": "layer-uuid-1",
      "name": "Sky",
      "order": 0,
      "maskImage": "base64_encoded_png",
      "contentImage": "base64_encoded_png",
      "opacity": 1.0,
      "blendMode": "normal",
      "isVisible": true,
      "isLocked": false,
      "suggestedPattern": {
        "type": "parallelLines",
        "rotation": 45,
        "spacing": 6,
        "color": "#667eea"
      }
    },
    {
      "id": "layer-uuid-2",
      "name": "Mountain",
      "order": 1,
      "maskImage": "base64_encoded_png",
      "contentImage": "base64_encoded_png",
      "opacity": 1.0,
      "blendMode": "normal",
      "isVisible": true,
      "isLocked": false,
      "suggestedPattern": {
        "type": "crossHatch",
        "rotation": 0,
        "spacing": 5,
        "color": "#764ba2"
      }
    }
  ],
  "metadata": {
    "difficulty": "beginner",
    "theme": "nature",
    "artist": "Artist Name",
    "tags": ["landscape", "mountain", "sunset"]
  }
}
```

### 4.2 Template Bundle Format

```
Template.inktemplate/
├── manifest.json         # Template metadata
├── base.png             # Flat-color base image
├── layers/
│   ├── layer1_mask.png  # Layer 1 mask
│   ├── layer2_mask.png  # Layer 2 mask
│   └── ...
├── preview.png          # Gallery thumbnail
└── guide.png (optional) # Overlay guide lines
```

**manifest.json:**
```json
{
  "id": "template-uuid",
  "name": "Mountain Sunset",
  "version": "1.0",
  "canvasSize": { "width": 2048, "height": 2048 },
  "layers": [
    {
      "name": "Sky",
      "maskFile": "layers/layer1_mask.png",
      "suggestedPattern": {
        "type": "parallelLines",
        "rotation": 45,
        "color": "#667eea"
      }
    }
  ],
  "metadata": {
    "difficulty": "beginner",
    "estimatedTime": "15-20 minutes",
    "theme": "nature",
    "artist": "Artist Name",
    "license": "Exclusive"
  }
}
```

### 4.3 Brush Preset Format

```json
{
  "id": "brush-uuid",
  "name": "Diagonal Hatching",
  "type": "parallelLines",
  "defaults": {
    "rotation": 45,
    "spacing": 6,
    "opacity": 0.8,
    "scale": 1.0
  },
  "dynamics": {
    "pressureAffectsOpacity": true,
    "pressureAffectsSize": true,
    "tiltAffectsRotation": false
  },
  "thumbnail": "brush_preview.png"
}
```

---

## 5. Performance Optimization

### 5.1 Rendering Strategy

**Dual-Resolution Rendering:**
```swift
class PerformanceRenderer {
    // Display texture (low-res for preview)
    var displayTexture: MTLTexture  // 1080p
    
    // Working texture (high-res for export)
    var workingTexture: MTLTexture  // 2048p or 4K
    
    var renderToWorkingAsync: Bool = true
    
    func handleStroke(_ stroke: Stroke) {
        // Immediate: render to display (fast)
        renderStroke(stroke, to: displayTexture)
        updateDisplay()  // User sees immediately
        
        // Background: render to working (quality)
        if renderToWorkingAsync {
            DispatchQueue.global(qos: .userInitiated).async {
                self.renderStroke(stroke, to: self.workingTexture)
            }
        }
    }
}
```

**Viewport Culling:**
```swift
func visibleLayers(in viewport: CGRect) -> [Layer] {
    return layers.filter { layer in
        layer.bounds.intersects(viewport)
    }
}

// Only render visible layers
func draw() {
    let viewport = getCurrentViewport()
    let visible = visibleLayers(in: viewport)
    
    for layer in visible {
        renderLayer(layer, in: viewport)
    }
}
```

### 5.2 Memory Management

**Texture Pooling:**
```swift
class TexturePool {
    private var pool: [MTLPixelFormat: [MTLTexture]] = [:]
    
    func getTexture(
        size: MTLSize,
        format: MTLPixelFormat
    ) -> MTLTexture {
        if let texture = pool[format]?.first(where: { 
            $0.width == size.width && $0.height == size.height 
        }) {
            return texture
        }
        
        // Create new
        return device.makeTexture(descriptor: ...)!
    }
    
    func returnTexture(_ texture: MTLTexture) {
        pool[texture.pixelFormat, default: []].append(texture)
    }
}
```

**Lazy Loading:**
```swift
class Template {
    var id: UUID
    var name: String
    
    // Lazy loaded
    private var _baseImage: UIImage?
    private var _layers: [Layer]?
    
    var baseImage: UIImage {
        if _baseImage == nil {
            _baseImage = loadImageFromDisk(id: id)
        }
        return _baseImage!
    }
    
    var layers: [Layer] {
        if _layers == nil {
            _layers = loadLayersFromDisk(id: id)
        }
        return _layers!
    }
}
```

### 5.3 Target Performance Metrics

```
Device Tier 1 (iPad Pro 2021+):
- Drawing latency: < 10ms
- Frame rate: 120fps (ProMotion)
- Stroke render: < 5ms
- Export time (2K): < 3s

Device Tier 2 (iPad Air 2020+):
- Drawing latency: < 16ms
- Frame rate: 60fps
- Stroke render: < 8ms
- Export time (2K): < 5s

Device Tier 3 (iPad 7th gen):
- Drawing latency: < 20ms
- Frame rate: 60fps
- Stroke render: < 12ms
- Export time (2K): < 7s
```

---

## 6. Testing Requirements

### 6.1 Unit Tests

```swift
// BrushEngineTests.swift
class BrushEngineTests: XCTestCase {
    func testParallelLineGeneration() {
        let brush = PatternBrush(type: .parallelLines, rotation: 45, spacing: 10)
        let lines = brushEngine.generateParallelLines(
            center: CGPoint(x: 100, y: 100),
            brush: brush
        )
        
        XCTAssertEqual(lines.count, 7)
        XCTAssertTrue(lines[0].start.x < lines[0].end.x)
    }
    
    func testStrokeSmoothing() {
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 10, y: 5),
            CGPoint(x: 20, y: 10)
        ]
        
        let smoothed = catmullRomInterpolation(points: points)
        XCTAssertGreaterThan(smoothed.count, points.count)
    }
}

// LayerManagerTests.swift
class LayerManagerTests: XCTestCase {
    func testLayerSelection() {
        let manager = LayerManager()
        manager.layers = createTestLayers()
        
        manager.selectLayer("layer-1")
        XCTAssertEqual(manager.activeLayer?.id, "layer-1")
    }
    
    func testMaskClipping() {
        let manager = LayerManager()
        let layer = createTestLayer()
        let point = CGPoint(x: 100, y: 100)
        
        let isInside = manager.isPointInLayer(point, layer: layer)
        XCTAssertTrue(isInside)
    }
}
```

### 6.2 Integration Tests

```swift
class IntegrationTests: XCTestCase {
    func testFullDrawingFlow() {
        // 1. Load template
        let template = templateManager.load("mountain-sunset")
        XCTAssertNotNil(template)
        
        // 2. Select layer
        layerManager.selectLayer("sky")
        
        // 3. Simulate stroke
        let points = generateTestStroke()
        brushEngine.drawStroke(points, on: layerManager.activeLayer!)
        
        // 4. Verify stroke rendered
        let layerTexture = layerManager.activeLayer!.contentTexture
        XCTAssertTrue(hasNonZeroPixels(layerTexture))
    }
    
    func testExportPipeline() {
        // ... draw some strokes
        
        // Export
        let image = exportManager.exportToPNG(project: currentProject)
        
        XCTAssertNotNil(image)
        XCTAssertEqual(image.size.width, 2048)
        XCTAssertEqual(image.size.height, 2048)
    }
}
```

### 6.3 Performance Tests

```swift
class PerformanceTests: XCTestCase {
    func testStrokeRenderPerformance() {
        measure {
            let stroke = generateRandomStroke(pointCount: 100)
            brushEngine.renderStroke(stroke, on: testLayer)
        }
        // Should complete in < 10ms on iPad Pro
    }
    
    func testLayerCompositePerformance() {
        let layers = create10TestLayers()
        
        measure {
            renderer.compositeLayersToScreen(layers, viewport: fullScreen)
        }
        // Should complete in < 16ms (60fps)
    }
}
```

### 6.4 Device Testing Matrix

```
Priority 1 (Must test):
- iPad Pro 11" (2021) - M1
- iPad Air (4th gen) - A14
- iPad (9th gen) - A13

Priority 2 (Should test):
- iPad Pro 12.9" (2021) - M1
- iPad mini (6th gen) - A15

Priority 3 (Nice to have):
- iPad (7th gen) - A10
- iPhone 13 Pro Max - A15
```

---

## 7. Security & Privacy

### 7.1 Data Storage
- All artworks stored locally in app sandbox
- No cloud sync without explicit user opt-in
- Project files encrypted at rest (iOS default)

### 7.2 Network
- No analytics without consent (opt-in)
- Template downloads over HTTPS only
- No user data sent to servers

### 7.3 Permissions
```xml
<!-- Info.plist -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Save your completed artworks to Photos</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>Export your artwork to share or print</string>
```

---

## 8. Build & Deployment

### 8.1 Build Configuration

```ruby
# Podfile (if using CocoaPods)
platform :ios, '15.0'
use_frameworks!

target 'InkApp' do
  # Minimal dependencies
  # pod 'PSDocumentProvider' (optional, for PSD)
end
```

**Xcode Project Settings:**
```
Deployment Target: iOS 15.0
Devices: iPhone, iPad
Supported Orientations: 
  - Portrait (iPhone)
  - Landscape Left/Right (iPad)
  - Portrait (iPad)
  
Code Signing:
  - Development: Automatic
  - Release: Manual

Build Settings:
  - Swift Language Version: 5.5
  - Metal Language Version: 2.4
  - Optimization Level (Release): -O -whole-module-optimization
```

### 8.2 App Store Configuration

```
Bundle ID: com.yourcompany.inkapp
Version: 1.0.0 (Build 1)
Category: Graphics & Design (or Entertainment)
Age Rating: 4+

Required Device Capabilities:
  - metal (GPU required)
  - arm64

Supported Languages:
  - English (primary)
  - Vietnamese (future)
  - Spanish, French, German (future)
```

---

## 9. Appendix

### 9.1 Third-Party Libraries (Optional)

```
PSDocumentProvider:
- Purpose: PSD file import
- License: Check license
- Alternative: Write custom PSD parser

SwiftImage:
- Purpose: Image manipulation helpers
- License: MIT
- Alternative: Use Core Graphics directly
```

### 9.2 Useful Resources

- Apple Metal Best Practices: https://developer.apple.com/metal/
- Metal Shading Language Spec: https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf
- Core Graphics Reference: https://developer.apple.com/documentation/coregraphics
- PSD File Format: Adobe documentation

---

## 10. Change Log

**v1.0 (2025-11-10)**
- Initial technical specification
- Metal rendering pipeline defined
- Data models specified

---

**Document Status:** ✅ Ready for Implementation  
**Next Steps:** Begin Module 1 (Canvas View) development

---

*Related Documents:*
- 01-PRD-Product-Requirements.md
- 03-UI-UX-Design-Brief.md
- 04-Architecture-Document.md
- 05-API-Reference.md
