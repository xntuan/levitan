//
//  EnhancedMetalRenderer.swift
//  Ink - Pattern Drawing App
//
//  Enhanced Metal renderer with pattern and layer support
//  Created on November 10, 2025.
//

import Metal
import MetalKit
import CoreGraphics

class EnhancedMetalRenderer: NSObject {

    let device: MTLDevice
    let commandQueue: MTLCommandQueue

    // Managers
    var textureManager: TextureManager!
    var patternRenderer: PatternRenderer!
    var layerManager: LayerManager!

    // Textures
    var canvasTexture: MTLTexture?
    var layerTextures: [UUID: MTLTexture] = [:]

    // Display pipeline
    var displayPipelineState: MTLRenderPipelineState?

    // Canvas state
    var canvasSize: CGSize = CGSize(width: 2048, height: 2048)

    // MARK: - Initialization

    init?(metalView: MTKView, layerManager: LayerManager) {
        // Get default Metal device
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return nil
        }
        self.device = device
        metalView.device = device

        // Create command queue
        guard let commandQueue = device.makeCommandQueue() else {
            print("Failed to create command queue")
            return nil
        }
        self.commandQueue = commandQueue

        self.layerManager = layerManager

        super.init()

        // Initialize managers
        textureManager = TextureManager(device: device)
        patternRenderer = PatternRenderer(device: device, commandQueue: commandQueue)

        // Setup canvas texture
        setupCanvasTexture()

        // Setup layer textures
        setupLayerTextures()

        // Setup display pipeline
        setupDisplayPipeline()

        metalView.delegate = self
    }

    // MARK: - Setup

    private func setupCanvasTexture() {
        canvasTexture = textureManager?.createBlankTexture(size: canvasSize)

        // Clear to white
        guard let texture = canvasTexture,
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }

        textureManager?.clearTexture(
            texture,
            to: MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1),
            commandBuffer: commandBuffer
        )

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }

    private func setupLayerTextures() {
        for layer in layerManager.layers {
            if let texture = textureManager?.createBlankTexture(size: canvasSize) {
                layerTextures[layer.id] = texture

                // Clear to transparent
                guard let commandBuffer = commandQueue.makeCommandBuffer() else {
                    continue
                }

                textureManager?.clearTexture(
                    texture,
                    to: MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0),
                    commandBuffer: commandBuffer
                )

                commandBuffer.commit()
            }
        }
    }

    // MARK: - Drawing Methods

    /// Draw pattern stamp to active layer
    func drawPatternStamp(_ stamp: PatternStamp) {
        guard let activeLayer = layerManager.activeLayer,
              let layerTexture = layerTextures[activeLayer.id],
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }

        // Check if layer is locked
        if activeLayer.isLocked {
            print("Cannot draw on locked layer")
            return
        }

        // Render pattern stamp
        patternRenderer?.renderPatternStamp(
            stamp,
            to: layerTexture,
            canvasSize: canvasSize,
            commandBuffer: commandBuffer
        )

        commandBuffer.commit()
    }

    /// Draw multiple pattern stamps (for stroke)
    func drawPatternStamps(_ stamps: [PatternStamp]) {
        guard let activeLayer = layerManager.activeLayer,
              let layerTexture = layerTextures[activeLayer.id],
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }

        if activeLayer.isLocked {
            print("Cannot draw on locked layer")
            return
        }

        // Render all stamps in one command buffer
        for stamp in stamps {
            patternRenderer?.renderPatternStamp(
                stamp,
                to: layerTexture,
                canvasSize: canvasSize,
                commandBuffer: commandBuffer
            )
        }

        commandBuffer.commit()
    }

    /// Composite all layers for display
    private func compositeLayersToCanvas() -> MTLTexture? {
        guard let outputTexture = textureManager?.createBlankTexture(size: canvasSize),
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return nil
        }

        // Start with white background
        textureManager?.clearTexture(
            outputTexture,
            to: MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1),
            commandBuffer: commandBuffer
        )

        // Composite each visible layer
        for layer in layerManager.layers {
            guard layer.isVisible,
                  let layerTexture = layerTextures[layer.id] else {
                continue
            }

            // TODO: Apply layer opacity and blend mode
            // For now, just copy the layer
            if let blitEncoder = commandBuffer.makeBlitCommandEncoder() {
                let origin = MTLOrigin(x: 0, y: 0, z: 0)
                let size = MTLSize(width: Int(canvasSize.width), height: Int(canvasSize.height), depth: 1)

                blitEncoder.copy(
                    from: layerTexture,
                    sourceSlice: 0,
                    sourceLevel: 0,
                    sourceOrigin: origin,
                    sourceSize: size,
                    to: outputTexture,
                    destinationSlice: 0,
                    destinationLevel: 0,
                    destinationOrigin: origin
                )

                blitEncoder.endEncoding()
            }
        }

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return outputTexture
    }

    // MARK: - Layer Management

    /// Add new layer
    func addLayer(_ layer: Layer) {
        if let texture = textureManager?.createBlankTexture(size: canvasSize) {
            layerTextures[layer.id] = texture

            // Clear to transparent
            guard let commandBuffer = commandQueue.makeCommandBuffer() else {
                return
            }

            textureManager?.clearTexture(
                texture,
                to: MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0),
                commandBuffer: commandBuffer
            )

            commandBuffer.commit()
        }
    }

    /// Remove layer
    func removeLayer(_ layerId: UUID) {
        layerTextures.removeValue(forKey: layerId)
    }

    /// Clear active layer
    func clearActiveLayer() {
        guard let activeLayer = layerManager.activeLayer,
              let layerTexture = layerTextures[activeLayer.id],
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }

        textureManager?.clearTexture(
            layerTexture,
            to: MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0),
            commandBuffer: commandBuffer
        )

        commandBuffer.commit()
    }
}

// MARK: - MTKViewDelegate

extension EnhancedMetalRenderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle size changes
        print("Drawable size changed to: \(size)")
    }

    func draw(in view: MTKView) {
        // Get command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }

        // Composite all visible layers to single texture
        let compositedTexture = compositeLayersForDisplay()

        // Render composited texture to screen
        renderTextureToScreen(compositedTexture, view: view, commandBuffer: commandBuffer)

        // Present drawable
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }

        // Commit
        commandBuffer.commit()
    }

    // MARK: - Display Pipeline

    private func setupDisplayPipeline() {
        guard let library = device.makeDefaultLibrary() else {
            print("ERROR: Could not load default library for display pipeline")
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
            print("ERROR: Failed to create display pipeline: \(error)")
        }
    }

    private func renderTextureToScreen(_ texture: MTLTexture?, view: MTKView, commandBuffer: MTLCommandBuffer) {
        guard let texture = texture,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let pipelineState = displayPipelineState else {
            // Fallback: clear to white if no texture
            if let renderPassDescriptor = view.currentRenderPassDescriptor,
               let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
                renderEncoder.endEncoding()
            }
            return
        }

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setFragmentTexture(texture, index: 0)

        // Draw full-screen quad (6 vertices for 2 triangles)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)

        renderEncoder.endEncoding()
    }

    private func compositeLayersForDisplay() -> MTLTexture? {
        // For now, just return the first visible layer
        // TODO: Properly composite all layers with blend modes
        for layer in layerManager.layers {
            if layer.isVisible, let texture = layerTextures[layer.id] {
                return texture
            }
        }

        // If no visible layers, return white canvas
        return canvasTexture
    }
}
