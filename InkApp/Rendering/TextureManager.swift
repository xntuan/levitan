//
//  TextureManager.swift
//  Ink - Pattern Drawing App
//
//  Manages Metal textures for layers and rendering
//  Created on November 10, 2025.
//

import Metal
import MetalKit
import CoreGraphics
import UIKit

class TextureManager {

    let device: MTLDevice
    private var textureCache: [UUID: MTLTexture] = [:]

    // MARK: - Initialization

    init?(device: MTLDevice) {
        self.device = device
    }

    // MARK: - Texture Creation

    /// Create blank texture for layer content
    func createBlankTexture(size: CGSize, pixelFormat: MTLPixelFormat = .bgra8Unorm) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: Int(size.width),
            height: Int(size.height),
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        descriptor.storageMode = .private

        return device.makeTexture(descriptor: descriptor)
    }

    /// Create texture from UIImage (for base templates)
    func createTexture(from image: UIImage) -> MTLTexture? {
        guard let cgImage = image.cgImage else { return nil }

        let textureLoader = MTKTextureLoader(device: device)

        do {
            let texture = try textureLoader.newTexture(
                cgImage: cgImage,
                options: [
                    .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
                    .SRGB: false
                ]
            )
            return texture
        } catch {
            print("Error creating texture from image: \(error)")
            return nil
        }
    }

    /// Create texture from Data
    func createTexture(from data: Data, size: CGSize) -> MTLTexture? {
        guard let image = UIImage(data: data) else { return nil }
        return createTexture(from: image)
    }

    /// Create mask texture from grayscale image
    func createMaskTexture(from image: UIImage) -> MTLTexture? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height

        // Create descriptor for R8 (single channel) texture
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .r8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead]

        guard let texture = device.makeTexture(descriptor: descriptor) else {
            return nil
        }

        // Extract grayscale data
        let bytesPerRow = width
        let region = MTLRegion(
            origin: MTLOrigin(x: 0, y: 0, z: 0),
            size: MTLSize(width: width, height: height, depth: 1)
        )

        // Convert to grayscale
        var pixelData = [UInt8](repeating: 0, count: width * height)

        let colorSpace = CGColorSpaceCreateDeviceGray()
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )

        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        texture.replace(
            region: region,
            mipmapLevel: 0,
            withBytes: pixelData,
            bytesPerRow: bytesPerRow
        )

        return texture
    }

    // MARK: - Texture Cache Management

    /// Cache texture with ID
    func cacheTexture(_ texture: MTLTexture, for id: UUID) {
        textureCache[id] = texture
    }

    /// Retrieve cached texture
    func getCachedTexture(for id: UUID) -> MTLTexture? {
        return textureCache[id]
    }

    /// Remove cached texture
    func removeCachedTexture(for id: UUID) {
        textureCache.removeValue(forKey: id)
    }

    /// Clear all cached textures
    func clearCache() {
        textureCache.removeAll()
    }

    // MARK: - Texture Operations

    /// Copy texture contents
    func copyTexture(from source: MTLTexture, to destination: MTLTexture, commandBuffer: MTLCommandBuffer) {
        guard let blitEncoder = commandBuffer.makeBlitCommandEncoder() else {
            return
        }

        let origin = MTLOrigin(x: 0, y: 0, z: 0)
        let size = MTLSize(width: source.width, height: source.height, depth: 1)

        blitEncoder.copy(
            from: source,
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: origin,
            sourceSize: size,
            to: destination,
            destinationSlice: 0,
            destinationLevel: 0,
            destinationOrigin: origin
        )

        blitEncoder.endEncoding()
    }

    /// Clear texture to color
    func clearTexture(_ texture: MTLTexture, to color: MTLClearColor, commandBuffer: MTLCommandBuffer) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = color
        renderPassDescriptor.colorAttachments[0].storeAction = .store

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        renderEncoder.endEncoding()
    }

    // MARK: - Utility

    /// Convert UIImage to Data (for saving)
    func textureToImage(_ texture: MTLTexture) -> UIImage? {
        let width = texture.width
        let height = texture.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let dataSize = height * bytesPerRow

        var pixelData = [UInt8](repeating: 0, count: dataSize)

        let region = MTLRegion(
            origin: MTLOrigin(x: 0, y: 0, z: 0),
            size: MTLSize(width: width, height: height, depth: 1)
        )

        texture.getBytes(
            &pixelData,
            bytesPerRow: bytesPerRow,
            from: region,
            mipmapLevel: 0
        )

        // Create CGImage from pixel data
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let dataProvider = CGDataProvider(data: Data(pixelData) as CFData),
              let cgImage = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: bytesPerPixel * 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo,
                provider: dataProvider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              ) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    // MARK: - Memory Management

    /// Get total memory used by cached textures (approximate)
    func getCacheMemoryUsage() -> Int {
        var totalBytes = 0

        for texture in textureCache.values {
            let bytesPerPixel = 4 // Assuming BGRA8
            totalBytes += texture.width * texture.height * bytesPerPixel
        }

        return totalBytes
    }

    /// Release textures if memory pressure
    func releaseUnusedTextures(keep: Set<UUID>) {
        let keysToRemove = textureCache.keys.filter { !keep.contains($0) }
        keysToRemove.forEach { textureCache.removeValue(forKey: $0) }

        print("Released \(keysToRemove.count) unused textures")
    }
}
