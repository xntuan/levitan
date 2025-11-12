//
//  MaskManager.swift
//  Ink - Pattern Drawing App
//
//  Manages drawing masks for "Stay Inside Lines" mode
//  Created on November 11, 2025.
//

import CoreGraphics
import Metal
import UIKit

class MaskManager {

    // MARK: - Properties

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue

    // Current mask state
    private(set) var currentMask: MTLTexture?
    private(set) var isMaskEnabled: Bool = false

    // MARK: - Initialization

    init(device: MTLDevice, commandQueue: MTLCommandQueue) {
        self.device = device
        self.commandQueue = commandQueue
    }

    // MARK: - Mask Generation

    /// Generate a mask texture from template paths
    /// White = drawable area, Black = restricted area
    func generateMask(from template: Template, size: CGSize) -> MTLTexture? {
        // Create CGContext to render mask
        let width = Int(size.width)
        let height = Int(size.height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGImageAlphaInfo.none.rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            print("❌ Failed to create mask context")
            return nil
        }

        // Fill with black (restricted by default)
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Draw template paths in white (drawable areas)
        context.setFillColor(UIColor.white.cgColor)
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(2.0)

        // Convert template vector paths to CGPath
        for region in template.drawableRegions {
            let path = createCGPath(from: region, in: size)
            context.addPath(path)
            context.fillPath()
        }

        // Get pixel data
        guard let data = context.data else {
            print("❌ Failed to get mask pixel data")
            return nil
        }

        // Create Metal texture from pixel data
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .r8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead]

        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            print("❌ Failed to create mask texture")
            return nil
        }

        let region = MTLRegionMake2D(0, 0, width, height)
        texture.replace(
            region: region,
            mipmapLevel: 0,
            withBytes: data,
            bytesPerRow: width
        )

        print("✅ Generated mask texture: \(width)×\(height)")
        return texture
    }

    /// Create CGPath from region definition
    private func createCGPath(from region: Template.DrawableRegion, in size: CGSize) -> CGPath {
        let path = CGMutablePath()

        switch region.shape {
        case .rectangle(let rect):
            let scaledRect = CGRect(
                x: rect.origin.x * size.width,
                y: rect.origin.y * size.height,
                width: rect.size.width * size.width,
                height: rect.size.height * size.height
            )
            path.addRect(scaledRect)

        case .circle(let center, let radius):
            let scaledCenter = CGPoint(
                x: center.x * size.width,
                y: center.y * size.height
            )
            let scaledRadius = radius * min(size.width, size.height)
            path.addEllipse(in: CGRect(
                x: scaledCenter.x - scaledRadius,
                y: scaledCenter.y - scaledRadius,
                width: scaledRadius * 2,
                height: scaledRadius * 2
            ))

        case .polygon(let points):
            guard let firstPoint = points.first else { return path }
            let scaledFirstPoint = CGPoint(
                x: firstPoint.x * size.width,
                y: firstPoint.y * size.height
            )
            path.move(to: scaledFirstPoint)

            for point in points.dropFirst() {
                let scaledPoint = CGPoint(
                    x: point.x * size.width,
                    y: point.y * size.height
                )
                path.addLine(to: scaledPoint)
            }
            path.closeSubpath()

        case .custom(let cgPath):
            // Scale custom path
            var transform = CGAffineTransform(scaleX: size.width, y: size.height)
            if let scaledPath = cgPath.copy(using: &transform) {
                path.addPath(scaledPath)
            }
        }

        return path
    }

    // MARK: - Mask Management

    /// Set the current mask
    func setMask(_ texture: MTLTexture?) {
        currentMask = texture
        if texture != nil {
            print("✅ Mask texture set: \(texture!.width)×\(texture!.height)")
        }
    }

    /// Enable or disable mask enforcement
    func setMaskEnabled(_ enabled: Bool) {
        isMaskEnabled = enabled
        print(enabled ? "🔒 Stay Inside Lines: ON" : "🔓 Stay Inside Lines: OFF")
    }

    /// Check if a point is inside the drawable area
    func isPointInDrawableArea(_ point: CGPoint, textureSize: CGSize) -> Bool {
        guard let mask = currentMask, isMaskEnabled else {
            return true  // No mask or disabled = everywhere is drawable
        }

        // Convert point to texture coordinates
        let x = Int(point.x * CGFloat(mask.width) / textureSize.width)
        let y = Int(point.y * CGFloat(mask.height) / textureSize.height)

        // Bounds check
        guard x >= 0, x < mask.width, y >= 0, y < mask.height else {
            return false
        }

        // Read pixel value from mask
        var pixelValue: UInt8 = 0
        let region = MTLRegionMake2D(x, y, 1, 1)
        mask.getBytes(&pixelValue, bytesPerRow: 1, from: region, mipmapLevel: 0)

        // White (255) = drawable, Black (0) = restricted
        return pixelValue > 127
    }

    /// Clear current mask
    func clearMask() {
        currentMask = nil
        isMaskEnabled = false
        print("🗑️ Mask cleared")
    }
}

// MARK: - Template Extension for Drawable Regions

extension Template {

    /// Defines a region that can be drawn in
    struct DrawableRegion {
        let shape: RegionShape

        enum RegionShape {
            case rectangle(CGRect)
            case circle(center: CGPoint, radius: CGFloat)
            case polygon([CGPoint])
            case custom(CGPath)
        }
    }

    /// Drawable regions for this template (used for Stay Inside Lines mode)
    /// Note: This is a placeholder. In production, regions would be defined
    /// per template or generated from vector artwork.
    var drawableRegions: [DrawableRegion] {
        // Default: entire canvas is drawable
        return [
            DrawableRegion(shape: .rectangle(CGRect(x: 0, y: 0, width: 1, height: 1)))
        ]
    }
}
