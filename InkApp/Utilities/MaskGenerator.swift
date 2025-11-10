//
//  MaskGenerator.swift
//  Ink - Pattern Drawing App
//
//  Programmatically generates mask images for template layers
//  Created on November 10, 2025.
//

import UIKit
import CoreGraphics

class MaskGenerator {

    /// Generate a simple horizontal band mask
    /// - Parameters:
    ///   - size: Size of the mask texture (should match canvas size)
    ///   - region: Which region to make white (drawable)
    ///   - Returns: Grayscale UIImage (white = drawable, black = protected)
    static func generateHorizontalBandMask(size: CGSize, region: Region) -> UIImage? {
        // Create grayscale context
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGImageAlphaInfo.none.rawValue

        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerRow = width

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }

        // Fill with black (protected)
        context.setFillColor(gray: 0.0, alpha: 1.0)
        context.fill(CGRect(origin: .zero, size: size))

        // Draw white region (drawable)
        context.setFillColor(gray: 1.0, alpha: 1.0)

        let yStart: CGFloat
        let yEnd: CGFloat

        switch region {
        case .top:
            yStart = 0
            yEnd = size.height * 0.4
        case .middle:
            yStart = size.height * 0.4
            yEnd = size.height * 0.7
        case .bottom:
            yStart = size.height * 0.7
            yEnd = size.height
        case .full:
            yStart = 0
            yEnd = size.height
        case .custom(let y1, let y2):
            yStart = size.height * y1
            yEnd = size.height * y2
        }

        let rect = CGRect(x: 0, y: yStart, width: size.width, height: yEnd - yStart)
        context.fill(rect)

        // Create image
        guard let cgImage = context.makeImage() else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    /// Generate a gradient mask (soft edges)
    static func generateGradientMask(size: CGSize, region: Region, feather: CGFloat = 50) -> UIImage? {
        // Create grayscale context
        let colorSpace = CGColorSpaceCreateDeviceGray()

        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        // Fill with black
        context.setFillColor(gray: 0.0, alpha: 1.0)
        context.fill(CGRect(origin: .zero, size: size))

        // Calculate region bounds
        let yStart: CGFloat
        let yEnd: CGFloat

        switch region {
        case .top:
            yStart = 0
            yEnd = size.height * 0.4
        case .middle:
            yStart = size.height * 0.4
            yEnd = size.height * 0.7
        case .bottom:
            yStart = size.height * 0.7
            yEnd = size.height
        case .full:
            yStart = 0
            yEnd = size.height
        case .custom(let y1, let y2):
            yStart = size.height * y1
            yEnd = size.height * y2
        }

        // Draw white region with gradient edges
        let regionRect = CGRect(x: 0, y: yStart, width: size.width, height: yEnd - yStart)

        // Main white area
        context.setFillColor(gray: 1.0, alpha: 1.0)
        context.fill(regionRect)

        // Top gradient (if not at top edge)
        if yStart > 0 {
            let gradientColors = [
                CGColor(gray: 0.0, alpha: 1.0),
                CGColor(gray: 1.0, alpha: 1.0)
            ]
            let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: gradientColors as CFArray,
                locations: [0.0, 1.0]
            )!

            let gradientStart = CGPoint(x: size.width / 2, y: max(0, yStart - feather))
            let gradientEnd = CGPoint(x: size.width / 2, y: yStart)

            context.drawLinearGradient(
                gradient,
                start: gradientStart,
                end: gradientEnd,
                options: []
            )
        }

        // Bottom gradient (if not at bottom edge)
        if yEnd < size.height {
            let gradientColors = [
                CGColor(gray: 1.0, alpha: 1.0),
                CGColor(gray: 0.0, alpha: 1.0)
            ]
            let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: gradientColors as CFArray,
                locations: [0.0, 1.0]
            )!

            let gradientStart = CGPoint(x: size.width / 2, y: yEnd)
            let gradientEnd = CGPoint(x: size.width / 2, y: min(size.height, yEnd + feather))

            context.drawLinearGradient(
                gradient,
                start: gradientStart,
                end: gradientEnd,
                options: []
            )
        }

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    /// Generate masks for a template
    static func generateTemplateMasks(template: Template, size: CGSize = CGSize(width: 2048, height: 2048)) -> [String: UIImage] {
        var masks: [String: UIImage] = [:]

        for layerDef in template.layerDefinitions {
            guard let maskImageName = layerDef.maskImageName else {
                continue
            }

            // Determine region based on layer name
            let region = inferRegion(from: layerDef.name, order: layerDef.order, totalLayers: template.layerDefinitions.count)

            if let mask = generateGradientMask(size: size, region: region, feather: 100) {
                masks[maskImageName] = mask
            }
        }

        return masks
    }

    /// Infer region from layer name
    private static func inferRegion(from name: String, order: Int, totalLayers: Int) -> Region {
        let lowercaseName = name.lowercased()

        // Specific pattern matching
        if lowercaseName.contains("sky") || lowercaseName.contains("background") {
            return .top
        } else if lowercaseName.contains("mountain") || lowercaseName.contains("tree") || lowercaseName.contains("clouds") {
            return .middle
        } else if lowercaseName.contains("foreground") || lowercaseName.contains("shore") || lowercaseName.contains("path") || lowercaseName.contains("water") {
            return .bottom
        }

        // Animal-specific
        if lowercaseName.contains("body") {
            return .middle
        } else if lowercaseName.contains("details") {
            return .custom(0.35, 0.65)
        }

        // Abstract patterns - divide evenly
        if totalLayers == 2 {
            return order == 0 ? .top : .bottom
        } else if totalLayers == 3 {
            return order == 0 ? .top : (order == 1 ? .middle : .bottom)
        } else {
            // Fallback to even division
            let fraction = CGFloat(order) / CGFloat(totalLayers)
            let height = 1.0 / CGFloat(totalLayers)
            return .custom(fraction, fraction + height)
        }
    }

    /// Save masks to temporary directory for testing
    static func saveMasksToTempDirectory(template: Template, size: CGSize = CGSize(width: 2048, height: 2048)) -> [String: URL] {
        let masks = generateTemplateMasks(template: template, size: size)
        var urls: [String: URL] = [:]

        let tempDir = FileManager.default.temporaryDirectory

        for (name, image) in masks {
            let fileURL = tempDir.appendingPathComponent("\(name).png")

            if let data = image.pngData() {
                try? data.write(to: fileURL)
                urls[name] = fileURL
                print("💾 Saved mask: \(name).png")
            }
        }

        return urls
    }

    // MARK: - Region Definition

    enum Region {
        case top        // Top 40%
        case middle     // Middle 30% (40-70%)
        case bottom     // Bottom 30% (70-100%)
        case full       // Entire canvas
        case custom(CGFloat, CGFloat)  // Custom range (0.0-1.0)
    }
}

// MARK: - UIImage PNG Extension

extension UIImage {
    func pngData() -> Data? {
        return self.pngData()
    }
}
