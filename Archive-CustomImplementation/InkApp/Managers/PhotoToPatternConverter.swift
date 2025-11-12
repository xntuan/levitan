//
//  PhotoToPatternConverter.swift
//  Ink - Pattern Drawing App
//
//  Converts photos to line art templates for pattern drawing
//  Created on November 11, 2025.
//

import Foundation
import CoreImage
import CoreGraphics
import Metal
import UIKit

/// Converts photos to line art templates
class PhotoToPatternConverter {

    // MARK: - Properties

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let ciContext: CIContext

    // Conversion settings
    var edgeThreshold: Float = 0.5      // 0-1, lower = more edges
    var lineWidth: Float = 2.0          // pixels
    var simplification: Float = 0.3     // 0-1, higher = fewer details
    var contrastBoost: Float = 1.2      // 1.0 = no boost

    // Callbacks
    var onProgress: ((Float, String) -> Void)?

    // MARK: - Initialization

    init(device: MTLDevice, commandQueue: MTLCommandQueue) {
        self.device = device
        self.commandQueue = commandQueue
        self.ciContext = CIContext(mtlDevice: device)
    }

    // MARK: - Conversion

    /// Convert photo to template
    func convertPhoto(
        _ image: UIImage,
        style: ConversionStyle,
        completion: @escaping (Result<Template, ConversionError>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                // Input validation
                guard image.size.width > 0 && image.size.height > 0 else {
                    throw ConversionError.invalidImage
                }

                // Prevent memory allocation failures with huge images
                guard image.size.width <= 4096 && image.size.height <= 4096 else {
                    throw ConversionError.imageTooLarge
                }

                // Step 1: Prepare image
                self.updateProgress(0.1, "Preparing image...")
                guard let cgImage = image.cgImage else {
                    throw ConversionError.invalidImage
                }

                let ciImage = CIImage(cgImage: cgImage)

                // Step 2: Apply filters based on style
                self.updateProgress(0.3, "Detecting edges...")
                let processedImage = try self.applyStyle(ciImage, style: style)

                // Step 3: Extract edges
                self.updateProgress(0.5, "Extracting paths...")
                let paths = try self.extractPaths(from: processedImage)

                // Step 4: Simplify paths
                self.updateProgress(0.7, "Simplifying...")
                let simplifiedPaths = self.simplifyPaths(paths)

                // Step 5: Create template
                self.updateProgress(0.9, "Creating template...")
                let template = try self.createTemplate(
                    from: simplifiedPaths,
                    originalImage: image,
                    style: style
                )

                self.updateProgress(1.0, "Complete!")

                DispatchQueue.main.async {
                    completion(.success(template))
                }

            } catch let error as ConversionError {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.processingFailed(error.localizedDescription)))
                }
            }
        }
    }

    // MARK: - Image Processing

    private func applyStyle(_ image: CIImage, style: ConversionStyle) throws -> CIImage {
        var result = image

        switch style {
        case .sketch:
            // Grayscale + edge detection
            result = applyGrayscale(result)
            result = applyContrastBoost(result)
            result = applyEdgeDetection(result, intensity: 1.0)

        case .comic:
            // Posterize + bold edges
            result = applyPosterize(result, levels: 6)
            result = applyEdgeDetection(result, intensity: 1.5)
            result = applyLineEnhancement(result)

        case .outline:
            // Strong edge detection only
            result = applyGrayscale(result)
            result = applyEdgeDetection(result, intensity: 2.0)
            result = applyThreshold(result)

        case .watercolor:
            // Soft edges + simplified shapes
            result = applyGaussianBlur(result, radius: 2.0)
            result = applyEdgeDetection(result, intensity: 0.7)
            result = applySimplification(result)

        case .geometric:
            // Posterize + strong edges + simplification
            result = applyPosterize(result, levels: 4)
            result = applyEdgeDetection(result, intensity: 1.8)
            result = applyThreshold(result)
        }

        return result
    }

    private func applyGrayscale(_ image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIPhotoEffectMono") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage ?? image
    }

    private func applyContrastBoost(_ image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorControls") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(contrastBoost, forKey: kCIInputContrastKey)
        return filter.outputImage ?? image
    }

    private func applyEdgeDetection(_ image: CIImage, intensity: Float) -> CIImage {
        guard let filter = CIFilter(name: "CIEdges") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(intensity, forKey: kCIInputIntensityKey)
        return filter.outputImage ?? image
    }

    private func applyPosterize(_ image: CIImage, levels: Int) -> CIImage {
        guard let filter = CIFilter(name: "CIColorPosterize") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(levels, forKey: "inputLevels")
        return filter.outputImage ?? image
    }

    private func applyGaussianBlur(_ image: CIImage, radius: Float) -> CIImage {
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        return filter.outputImage ?? image
    }

    private func applyThreshold(_ image: CIImage) -> CIImage {
        // Convert to black and white using threshold
        guard let filter = CIFilter(name: "CIColorControls") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(0.0, forKey: kCIInputSaturationKey)
        filter.setValue(2.0, forKey: kCIInputContrastKey)
        return filter.outputImage ?? image
    }

    private func applyLineEnhancement(_ image: CIImage) -> CIImage {
        // Enhance line visibility
        guard let filter = CIFilter(name: "CIUnsharpMask") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(2.0, forKey: kCIInputRadiusKey)
        filter.setValue(1.5, forKey: kCIInputIntensityKey)
        return filter.outputImage ?? image
    }

    private func applySimplification(_ image: CIImage) -> CIImage {
        // Reduce detail
        let blurred = applyGaussianBlur(image, radius: 1.5)
        return applyPosterize(blurred, levels: 8)
    }

    // MARK: - Path Extraction

    private func extractPaths(from image: CIImage) throws -> [CGPath] {
        // Convert CIImage to CGImage
        guard let cgImage = ciContext.createCGImage(image, from: image.extent) else {
            throw ConversionError.processingFailed("Failed to create CGImage")
        }

        // Get pixel data
        guard let pixelData = getPixelData(from: cgImage) else {
            throw ConversionError.processingFailed("Failed to extract pixel data")
        }

        // Trace edges to create paths
        let paths = traceEdges(
            pixelData: pixelData,
            width: cgImage.width,
            height: cgImage.height
        )

        return paths
    }

    private func getPixelData(from image: CGImage) -> Data? {
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = Data(count: width * height * bytesPerPixel)

        pixelData.withUnsafeMutableBytes { ptr in
            guard let context = CGContext(
                data: ptr.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return
            }

            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        return pixelData
    }

    private func traceEdges(pixelData: Data, width: Int, height: Int) -> [CGPath] {
        var paths: [CGPath] = []
        let threshold = UInt8(edgeThreshold * 255)

        // Simple edge tracing algorithm
        // In production, use more sophisticated algorithms like Marching Squares

        var visited = Array(repeating: Array(repeating: false, count: width), count: height)

        for y in 0..<height {
            for x in 0..<width {
                if visited[y][x] { continue }

                let index = (y * width + x) * 4
                guard index + 2 < pixelData.count else { continue }

                // Calculate proper grayscale intensity using luminance formula
                let r = Float(pixelData[index])
                let g = Float(pixelData[index + 1])
                let b = Float(pixelData[index + 2])
                let intensity = UInt8(0.299 * r + 0.587 * g + 0.114 * b)

                if intensity > threshold {
                    // Found an edge pixel - trace path
                    let path = tracePath(
                        from: CGPoint(x: x, y: y),
                        pixelData: pixelData,
                        width: width,
                        height: height,
                        visited: &visited,
                        threshold: threshold
                    )

                    if !path.isEmpty {
                        paths.append(path)
                    }
                }
            }
        }

        return paths
    }

    private func tracePath(
        from start: CGPoint,
        pixelData: Data,
        width: Int,
        height: Int,
        visited: inout [[Bool]],
        threshold: UInt8
    ) -> CGPath {

        let path = CGMutablePath()
        var currentPoint = start
        var points: [CGPoint] = [start]

        path.move(to: start)
        visited[Int(start.y)][Int(start.x)] = true

        // Simple 8-direction neighbor search
        let directions: [(Int, Int)] = [
            (1, 0), (1, 1), (0, 1), (-1, 1),
            (-1, 0), (-1, -1), (0, -1), (1, -1)
        ]

        var maxSteps = 1000
        while maxSteps > 0 {
            maxSteps -= 1
            var found = false

            for (dx, dy) in directions {
                let nx = Int(currentPoint.x) + dx
                let ny = Int(currentPoint.y) + dy

                guard nx >= 0, nx < width, ny >= 0, ny < height else { continue }
                guard !visited[ny][nx] else { continue }

                let index = (ny * width + nx) * 4
                guard index + 2 < pixelData.count else { continue }

                // Calculate proper grayscale intensity using luminance formula
                let r = Float(pixelData[index])
                let g = Float(pixelData[index + 1])
                let b = Float(pixelData[index + 2])
                let intensity = UInt8(0.299 * r + 0.587 * g + 0.114 * b)

                if intensity > threshold {
                    currentPoint = CGPoint(x: nx, y: ny)
                    points.append(currentPoint)
                    path.addLine(to: currentPoint)
                    visited[ny][nx] = true
                    found = true
                    break
                }
            }

            if !found { break }
        }

        return path
    }

    // MARK: - Path Simplification

    private func simplifyPaths(_ paths: [CGPath]) -> [CGPath] {
        return paths.map { simplifyPath($0) }
    }

    private func simplifyPath(_ path: CGPath) -> CGPath {
        // Ramer-Douglas-Peucker algorithm for path simplification
        // Simplified implementation

        let simplified = CGMutablePath()
        var points: [CGPoint] = []

        // Extract points from path
        path.applyWithBlock { element in
            switch element.pointee.type {
            case .moveToPoint:
                points.append(element.pointee.points[0])
            case .addLineToPoint:
                points.append(element.pointee.points[0])
            default:
                break
            }
        }

        guard !points.isEmpty else { return path }

        // Apply simplification
        let tolerance = CGFloat(simplification * 5.0)
        let simplifiedPoints = douglasPeucker(points: points, tolerance: tolerance)

        // Rebuild path
        if let first = simplifiedPoints.first {
            simplified.move(to: first)
            simplifiedPoints.dropFirst().forEach { simplified.addLine(to: $0) }
        }

        return simplified
    }

    private func douglasPeucker(points: [CGPoint], tolerance: CGFloat) -> [CGPoint] {
        guard points.count > 2 else { return points }

        // Find point with maximum distance
        var maxDistance: CGFloat = 0
        var index = 0

        let start = points.first!
        let end = points.last!

        for i in 1..<points.count - 1 {
            let distance = perpendicularDistance(point: points[i], lineStart: start, lineEnd: end)
            if distance > maxDistance {
                maxDistance = distance
                index = i
            }
        }

        // If max distance is greater than tolerance, recursively simplify
        if maxDistance > tolerance {
            let left = douglasPeucker(points: Array(points[0...index]), tolerance: tolerance)
            let right = douglasPeucker(points: Array(points[index..<points.count]), tolerance: tolerance)

            return left.dropLast() + right
        } else {
            return [start, end]
        }
    }

    private func perpendicularDistance(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> CGFloat {
        let dx = lineEnd.x - lineStart.x
        let dy = lineEnd.y - lineStart.y

        let numerator = abs(dy * point.x - dx * point.y + lineEnd.x * lineStart.y - lineEnd.y * lineStart.x)
        let denominator = sqrt(dx * dx + dy * dy)

        // Prevent division by zero when start == end (zero-length line)
        guard denominator > 0 else {
            // Return distance to the point
            let distX = point.x - lineStart.x
            let distY = point.y - lineStart.y
            return sqrt(distX * distX + distY * distY)
        }

        return numerator / denominator
    }

    // MARK: - Template Creation

    private func createTemplate(
        from paths: [CGPath],
        originalImage: UIImage,
        style: ConversionStyle
    ) throws -> Template {

        // Create template with extracted paths
        let template = Template(
            id: UUID(),
            name: "Converted from Photo",
            description: "Template created from photo conversion",
            category: .patterns,
            difficulty: .intermediate,
            estimatedMinutes: 30,
            thumbnailImageName: "",  // Will be generated
            baseImageName: "",  // Not used for photo conversions
            layerDefinitions: [],  // Will be populated separately
            primaryTechnique: .hatching
        )

        // Note: In production, paths would be saved to template
        // For now, we return a basic template

        return template
    }

    // MARK: - Helpers

    private func updateProgress(_ progress: Float, _ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.onProgress?(progress, message)
        }
    }
}

// MARK: - Supporting Types

enum ConversionStyle: String, CaseIterable {
    case sketch = "Sketch"
    case comic = "Comic"
    case outline = "Outline"
    case watercolor = "Watercolor"
    case geometric = "Geometric"

    var description: String {
        switch self {
        case .sketch:
            return "Pencil sketch style with soft edges"
        case .comic:
            return "Bold comic book style with strong lines"
        case .outline:
            return "Clean outline style, minimal detail"
        case .watercolor:
            return "Soft, flowing watercolor style"
        case .geometric:
            return "Simplified geometric shapes"
        }
    }

    var icon: String {
        switch self {
        case .sketch: return "✏️"
        case .comic: return "💥"
        case .outline: return "📝"
        case .watercolor: return "🎨"
        case .geometric: return "📐"
        }
    }
}

enum ConversionError: Error, LocalizedError {
    case invalidImage
    case processingFailed(String)
    case insufficientDetail
    case imageTooLarge

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid or corrupted image"
        case .processingFailed(let message):
            return "Processing failed: \(message)"
        case .insufficientDetail:
            return "Image doesn't have enough detail to convert"
        case .imageTooLarge:
            return "Image is too large (max 4096×4096)"
        }
    }
}
