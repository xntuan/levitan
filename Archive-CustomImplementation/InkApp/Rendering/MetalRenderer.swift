//
//  MetalRenderer.swift
//  Ink - Pattern Drawing App
//
//  Created on November 10, 2025.
//

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
            print("Failed to create command queue")
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
            print("Could not load default library")
            return
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
            print("Could not create pipeline state: \(error)")
        }
    }
}

// MARK: - MTKViewDelegate
extension MetalRenderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle size changes
        print("Drawable size changed to: \(size)")
    }

    func draw(in view: MTKView) {
        // Get command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }

        // Get render pass descriptor
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }

        // Clear to white
        renderPassDescriptor.colorAttachments[0].clearColor =
            MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)

        // Create render encoder
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(
            descriptor: renderPassDescriptor
        ) else {
            return
        }

        // TODO: Actual rendering will be implemented here

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
