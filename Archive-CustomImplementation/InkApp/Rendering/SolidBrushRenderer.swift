//
//  SolidBrushRenderer.swift
//  Ink - Pattern Drawing App
//
//  Renders solid brush and marker strokes to Metal textures
//  Created on November 11, 2025.
//

import Metal
import MetalKit
import CoreGraphics

class SolidBrushRenderer {

    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState?

    // MARK: - Initialization

    init?(device: MTLDevice, commandQueue: MTLCommandQueue) {
        self.device = device
        self.commandQueue = commandQueue

        setupPipeline()
    }

    private func setupPipeline() {
        guard let library = device.makeDefaultLibrary() else {
            print("Failed to create default library")
            return
        }

        let vertexFunction = library.makeFunction(name: "brush_vertex")
        let fragmentFunction = library.makeFunction(name: "brush_fragment")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // Enable blending for brush strokes
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline state: \(error)")
        }
    }

    // MARK: - Brush Rendering

    /// Render brush stamp at position
    func renderBrushStamp(
        position: CGPoint,
        size: Float,
        hardness: Float,
        color: PatternBrush.Color,
        opacity: Float,
        to texture: MTLTexture,
        canvasSize: CGSize,
        commandBuffer: MTLCommandBuffer,
        isEraser: Bool = false
    ) {
        // Setup render pass
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .load // Don't clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(
            descriptor: renderPassDescriptor
        ) else {
            return
        }

        guard let pipelineState = pipelineState else {
            renderEncoder.endEncoding()
            return
        }

        renderEncoder.setRenderPipelineState(pipelineState)

        // For eraser, use transparent color
        let finalColor: PatternBrush.Color
        if isEraser {
            finalColor = PatternBrush.Color(red: 0, green: 0, blue: 0, alpha: 0)
        } else {
            finalColor = color
        }

        // Create vertices for a quad with the brush circle
        let radius = CGFloat(size / 2.0)
        let vertices = createBrushQuad(
            center: position,
            radius: radius,
            canvasSize: canvasSize
        )

        // Create vertex buffer
        guard !vertices.isEmpty else {
            renderEncoder.endEncoding()
            return
        }

        let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<BrushVertex>.stride,
            options: []
        )

        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        // Set fragment uniforms (color, opacity, hardness)
        var uniforms = BrushUniforms(
            color: simd_float4(finalColor.red, finalColor.green, finalColor.blue, finalColor.alpha * opacity),
            hardness: hardness
        )
        renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<BrushUniforms>.size, index: 0)

        // Draw the brush stamp (2 triangles = 6 vertices)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)

        renderEncoder.endEncoding()
    }

    // MARK: - Geometry Creation

    /// Create quad vertices for brush stamp
    private func createBrushQuad(center: CGPoint, radius: CGFloat, canvasSize: CGSize) -> [BrushVertex] {
        // Create a quad (2 triangles) centered at the brush position
        let topLeft = CGPoint(x: center.x - radius, y: center.y - radius)
        let topRight = CGPoint(x: center.x + radius, y: center.y - radius)
        let bottomLeft = CGPoint(x: center.x - radius, y: center.y + radius)
        let bottomRight = CGPoint(x: center.x + radius, y: center.y + radius)

        // Convert to normalized device coordinates
        let tlPos = normalizePoint(topLeft, canvasSize: canvasSize)
        let trPos = normalizePoint(topRight, canvasSize: canvasSize)
        let blPos = normalizePoint(bottomLeft, canvasSize: canvasSize)
        let brPos = normalizePoint(bottomRight, canvasSize: canvasSize)

        // UV coordinates (for circular gradient in fragment shader)
        // (0,0) = top-left, (1,1) = bottom-right
        return [
            // First triangle (top-left, top-right, bottom-left)
            BrushVertex(position: tlPos, uv: simd_float2(0, 0)),
            BrushVertex(position: trPos, uv: simd_float2(1, 0)),
            BrushVertex(position: blPos, uv: simd_float2(0, 1)),

            // Second triangle (top-right, bottom-right, bottom-left)
            BrushVertex(position: trPos, uv: simd_float2(1, 0)),
            BrushVertex(position: brPos, uv: simd_float2(1, 1)),
            BrushVertex(position: blPos, uv: simd_float2(0, 1))
        ]
    }

    /// Convert canvas coordinates to normalized device coordinates
    private func normalizePoint(_ point: CGPoint, canvasSize: CGSize) -> simd_float2 {
        let x = Float(point.x / canvasSize.width) * 2.0 - 1.0
        let y = -(Float(point.y / canvasSize.height) * 2.0 - 1.0) // Flip Y
        return simd_float2(x, y)
    }
}

// MARK: - Vertex Structure

struct BrushVertex {
    let position: simd_float2   // Normalized device coordinates
    let uv: simd_float2         // Texture coordinates for circular gradient
}

// MARK: - Fragment Uniforms

struct BrushUniforms {
    let color: simd_float4      // RGBA color
    let hardness: Float         // Edge softness (0=soft, 1=hard)
}
