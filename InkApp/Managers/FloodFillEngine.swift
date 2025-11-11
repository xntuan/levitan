//
//  FloodFillEngine.swift
//  Ink - Pattern Drawing App
//
//  Implements flood fill algorithm for fill bucket tool
//  Created on November 11, 2025.
//

import CoreGraphics
import Metal
import UIKit

class FloodFillEngine {

    // MARK: - Properties

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue

    // MARK: - Initialization

    init(device: MTLDevice, commandQueue: MTLCommandQueue) {
        self.device = device
        self.commandQueue = commandQueue
    }

    // MARK: - Flood Fill

    /// Perform flood fill on a texture at the specified point
    func floodFill(
        texture: MTLTexture,
        at point: CGPoint,
        fillColor: PatternBrush.Color,
        tolerance: Float,
        contiguous: Bool = true
    ) -> MTLTexture? {
        // Read texture pixels into CPU memory
        guard let pixelData = readTexturePixels(texture: texture) else {
            print("❌ Failed to read texture pixels")
            return nil
        }

        let width = texture.width
        let height = texture.height

        // Get the color at the clicked point
        let x = Int(point.x)
        let y = Int(point.y)

        guard x >= 0 && x < width && y >= 0 && y < height else {
            print("❌ Point out of bounds: \(point)")
            return nil
        }

        let targetColor = getPixelColor(pixelData: pixelData, x: x, y: y, width: width)

        // Check if already the same color (within tolerance)
        if colorsMatch(targetColor, fillColor, tolerance: tolerance) {
            print("ℹ️ Already filled with this color")
            return nil // Already filled
        }

        // Perform flood fill algorithm
        var filledPixels = pixelData
        if contiguous {
            floodFillContiguous(
                pixels: &filledPixels,
                width: width,
                height: height,
                startX: x,
                startY: y,
                targetColor: targetColor,
                fillColor: fillColor,
                tolerance: tolerance
            )
        } else {
            floodFillGlobal(
                pixels: &filledPixels,
                width: width,
                height: height,
                targetColor: targetColor,
                fillColor: fillColor,
                tolerance: tolerance
            )
        }

        // Create new texture with filled pixels
        return createTexture(from: filledPixels, width: width, height: height)
    }

    // MARK: - Contiguous Fill (Scanline Algorithm)

    private func floodFillContiguous(
        pixels: inout [UInt8],
        width: Int,
        height: Int,
        startX: Int,
        startY: Int,
        targetColor: PatternBrush.Color,
        fillColor: PatternBrush.Color,
        tolerance: Float
    ) {
        var stack: [(Int, Int)] = [(startX, startY)]
        var visited = Set<Int>() // Use flat index for visited tracking

        while !stack.isEmpty {
            let (x, y) = stack.removeLast()

            // Skip if out of bounds
            guard x >= 0 && x < width && y >= 0 && y < height else { continue }

            let index = (y * width + x) * 4
            let flatIndex = y * width + x

            // Skip if already visited
            guard !visited.contains(flatIndex) else { continue }
            visited.insert(flatIndex)

            let currentColor = getPixelColor(pixelData: pixels, x: x, y: y, width: width)

            // Skip if color doesn't match target
            guard colorsMatch(currentColor, targetColor, tolerance: tolerance) else { continue }

            // Fill this pixel
            setPixelColor(pixels: &pixels, x: x, y: y, width: width, color: fillColor)

            // Add neighbors to stack (4-way connectivity)
            stack.append((x + 1, y))
            stack.append((x - 1, y))
            stack.append((x, y + 1))
            stack.append((x, y - 1))
        }

        print("✅ Flood fill complete: \(visited.count) pixels filled")
    }

    // MARK: - Global Fill (All Matching Pixels)

    private func floodFillGlobal(
        pixels: inout [UInt8],
        width: Int,
        height: Int,
        targetColor: PatternBrush.Color,
        fillColor: PatternBrush.Color,
        tolerance: Float
    ) {
        var count = 0
        for y in 0..<height {
            for x in 0..<width {
                let currentColor = getPixelColor(pixelData: pixels, x: x, y: y, width: width)
                if colorsMatch(currentColor, targetColor, tolerance: tolerance) {
                    setPixelColor(pixels: &pixels, x: x, y: y, width: width, color: fillColor)
                    count += 1
                }
            }
        }
        print("✅ Global fill complete: \(count) pixels filled")
    }

    // MARK: - Color Utilities

    private func getPixelColor(pixelData: [UInt8], x: Int, y: Int, width: Int) -> PatternBrush.Color {
        let index = (y * width + x) * 4
        let b = Float(pixelData[index]) / 255.0
        let g = Float(pixelData[index + 1]) / 255.0
        let r = Float(pixelData[index + 2]) / 255.0
        let a = Float(pixelData[index + 3]) / 255.0
        return PatternBrush.Color(red: r, green: g, blue: b, alpha: a)
    }

    private func setPixelColor(pixels: inout [UInt8], x: Int, y: Int, width: Int, color: PatternBrush.Color) {
        let index = (y * width + x) * 4
        pixels[index] = UInt8(color.blue * 255.0)      // B
        pixels[index + 1] = UInt8(color.green * 255.0) // G
        pixels[index + 2] = UInt8(color.red * 255.0)   // R
        pixels[index + 3] = UInt8(color.alpha * 255.0) // A
    }

    private func colorsMatch(_ color1: PatternBrush.Color, _ color2: PatternBrush.Color, tolerance: Float) -> Bool {
        let rDiff = abs(color1.red - color2.red)
        let gDiff = abs(color1.green - color2.green)
        let bDiff = abs(color1.blue - color2.blue)
        let aDiff = abs(color1.alpha - color2.alpha)

        // Use Euclidean distance for color matching
        let distance = sqrt(rDiff * rDiff + gDiff * gDiff + bDiff * bDiff + aDiff * aDiff)
        return distance <= tolerance
    }

    // MARK: - Texture I/O

    private func readTexturePixels(texture: MTLTexture) -> [UInt8]? {
        let width = texture.width
        let height = texture.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let byteCount = bytesPerRow * height

        var pixelData = [UInt8](repeating: 0, count: byteCount)

        let region = MTLRegionMake2D(0, 0, width, height)
        texture.getBytes(
            &pixelData,
            bytesPerRow: bytesPerRow,
            from: region,
            mipmapLevel: 0
        )

        return pixelData
    }

    private func createTexture(from pixelData: [UInt8], width: Int, height: Int) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]

        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            print("❌ Failed to create filled texture")
            return nil
        }

        let bytesPerRow = 4 * width
        let region = MTLRegionMake2D(0, 0, width, height)

        texture.replace(
            region: region,
            mipmapLevel: 0,
            withBytes: pixelData,
            bytesPerRow: bytesPerRow
        )

        return texture
    }
}
