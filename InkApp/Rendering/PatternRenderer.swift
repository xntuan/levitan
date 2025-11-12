//
//  PatternRenderer.swift
//  Ink - Pattern Drawing App
//
//  Renders pattern geometry to Metal textures
//  Created on November 10, 2025.
//

import Metal
import MetalKit
import CoreGraphics

class PatternRenderer {

    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState?

    // Vertex buffer for line rendering
    private var lineVertexBuffer: MTLBuffer?

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

        let vertexFunction = library.makeFunction(name: "pattern_vertex")
        let fragmentFunction = library.makeFunction(name: "pattern_fragment")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // Enable blending for layering
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

    // MARK: - Pattern Rendering

    /// Render pattern stamp to texture
    func renderPatternStamp(
        _ stamp: PatternStamp,
        to texture: MTLTexture,
        canvasSize: CGSize,
        commandBuffer: MTLCommandBuffer
    ) {
        // Generate pattern geometry
        let geometry = PatternGenerator.generatePattern(
            type: stamp.brush.type,
            center: stamp.position,
            rotation: stamp.brush.rotation,
            spacing: stamp.brush.spacing,
            scale: stamp.brush.scale
        )

        // For eraser mode, use transparent color (alpha 0) to erase
        let finalColor: PatternBrush.Color
        let finalOpacity: Float

        if stamp.isEraserMode {
            // Eraser: render with alpha 0 to erase pixels
            finalColor = PatternBrush.Color(red: 0, green: 0, blue: 0, alpha: 0)
            finalOpacity = 1.0  // Full strength eraser
        } else {
            // Normal drawing mode
            finalColor = stamp.brush.color
            finalOpacity = stamp.brush.opacity * stamp.pressure
        }

        // Render geometry
        renderGeometry(
            geometry,
            to: texture,
            color: finalColor,
            opacity: finalOpacity,
            canvasSize: canvasSize,
            commandBuffer: commandBuffer
        )
    }

    /// Render pattern geometry to texture
    private func renderGeometry(
        _ geometry: PatternGeometry,
        to texture: MTLTexture,
        color: PatternBrush.Color,
        opacity: Float,
        canvasSize: CGSize,
        commandBuffer: MTLCommandBuffer
    ) {
        // Setup render pass
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .load // Don't clear, we're adding to existing
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

        // Set color uniform
        var colorData = simd_float4(color.red, color.green, color.blue, opacity)
        renderEncoder.setFragmentBytes(&colorData, length: MemoryLayout<simd_float4>.size, index: 0)

        // Render lines
        if !geometry.lines.isEmpty {
            renderLines(geometry.lines, encoder: renderEncoder, canvasSize: canvasSize)
        }

        // Render circles
        if !geometry.circles.isEmpty {
            renderCircles(geometry.circles, encoder: renderEncoder, canvasSize: canvasSize)
        }

        // Render arcs
        if !geometry.arcs.isEmpty {
            renderArcs(geometry.arcs, encoder: renderEncoder, canvasSize: canvasSize)
        }

        // Render waves
        if !geometry.waves.isEmpty {
            renderWaves(geometry.waves, encoder: renderEncoder, canvasSize: canvasSize)
        }

        renderEncoder.endEncoding()
    }

    // MARK: - Geometry Rendering

    private func renderLines(_ lines: [Line], encoder: MTLRenderCommandEncoder, canvasSize: CGSize) {
        // Convert lines to vertex data
        var vertices: [simd_float2] = []

        for line in lines {
            // Convert canvas coordinates to normalized device coordinates (-1 to 1)
            let start = normalizePoint(line.start, canvasSize: canvasSize)
            let end = normalizePoint(line.end, canvasSize: canvasSize)

            vertices.append(start)
            vertices.append(end)
        }

        guard !vertices.isEmpty else { return }

        // Create vertex buffer
        let vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<simd_float2>.stride,
            options: []
        )

        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: vertices.count)
    }

    private func renderCircles(_ circles: [Circle], encoder: MTLRenderCommandEncoder, canvasSize: CGSize) {
        // Render each circle as a triangle fan
        for circle in circles {
            var vertices: [simd_float2] = []

            let center = normalizePoint(circle.center, canvasSize: canvasSize)
            let radiusNormalized = Float(circle.radius / canvasSize.width * 2.0)

            // Center point
            vertices.append(center)

            // Circle points (20 segments for smoothness)
            let segments = 20
            for i in 0...segments {
                let angle = Float(i) / Float(segments) * 2.0 * .pi
                let x = center.x + radiusNormalized * cos(angle)
                let y = center.y + radiusNormalized * sin(angle)
                vertices.append(simd_float2(x, y))
            }

            let vertexBuffer = device.makeBuffer(
                bytes: vertices,
                length: vertices.count * MemoryLayout<simd_float2>.stride,
                options: []
            )

            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.drawPrimitives(type: .triangleFan, vertexStart: 0, vertexCount: vertices.count)
        }
    }

    private func renderArcs(_ arcs: [Arc], encoder: MTLRenderCommandEncoder, canvasSize: CGSize) {
        // Render each arc as line strip
        for arc in arcs {
            var vertices: [simd_float2] = []

            let center = normalizePoint(arc.center, canvasSize: canvasSize)
            let radiusNormalized = Float(arc.radius / canvasSize.width * 2.0)

            // Arc points
            let segments = 40
            for i in 0...segments {
                let t = Float(i) / Float(segments)
                let angle = Float(arc.startAngle) + t * Float(arc.endAngle - arc.startAngle)
                let x = center.x + radiusNormalized * cos(angle)
                let y = center.y + radiusNormalized * sin(angle)
                vertices.append(simd_float2(x, y))
            }

            let vertexBuffer = device.makeBuffer(
                bytes: vertices,
                length: vertices.count * MemoryLayout<simd_float2>.stride,
                options: []
            )

            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: vertices.count)
        }
    }

    private func renderWaves(_ waves: [[CGPoint]], encoder: MTLRenderCommandEncoder, canvasSize: CGSize) {
        // Render each wave as line strip
        for wave in waves {
            var vertices: [simd_float2] = []

            for point in wave {
                vertices.append(normalizePoint(point, canvasSize: canvasSize))
            }

            guard !vertices.isEmpty else { continue }

            let vertexBuffer = device.makeBuffer(
                bytes: vertices,
                length: vertices.count * MemoryLayout<simd_float2>.stride,
                options: []
            )

            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: vertices.count)
        }
    }

    // MARK: - Helper Methods

    /// Convert canvas coordinates to normalized device coordinates
    private func normalizePoint(_ point: CGPoint, canvasSize: CGSize) -> simd_float2 {
        let x = Float(point.x / canvasSize.width) * 2.0 - 1.0
        let y = -(Float(point.y / canvasSize.height) * 2.0 - 1.0) // Flip Y
        return simd_float2(x, y)
    }
}
