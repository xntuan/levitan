//
//  TemplateMaskExporter.swift
//  Ink - Pattern Drawing App
//
//  Exports programmatically generated masks as PNG files
//  Created on November 10, 2025.
//

import UIKit
import CoreGraphics

class TemplateMaskExporter {

    /// Export all masks for all sample templates
    static func exportAllTemplateMasks() {
        let templates = Template.createSampleTemplates()
        let size = CGSize(width: 2048, height: 2048)

        print("🎨 Exporting masks for \(templates.count) templates...")

        for template in templates {
            exportMasksForTemplate(template, size: size)
        }

        print("✅ All masks exported successfully!")
    }

    /// Export masks for a single template
    static func exportMasksForTemplate(_ template: Template, size: CGSize = CGSize(width: 2048, height: 2048)) {
        print("\n📄 Template: \(template.name)")

        for layerDef in template.layerDefinitions {
            guard let maskImageName = layerDef.maskImageName else {
                continue
            }

            // Generate mask
            let region = inferRegion(from: layerDef.name, order: layerDef.order, totalLayers: template.layerDefinitions.count)

            guard let mask = MaskGenerator.generateGradientMask(size: size, region: region, feather: 100) else {
                print("  ❌ Failed to generate mask for: \(layerDef.name)")
                continue
            }

            // Save to Documents directory
            if let url = saveMaskToDocuments(mask, name: maskImageName) {
                print("  ✅ Saved: \(maskImageName).png")
                print("     Path: \(url.path)")
            }
        }
    }

    /// Save mask to Documents directory
    private static func saveMaskToDocuments(_ image: UIImage, name: String) -> URL? {
        guard let data = image.pngData() else {
            return nil
        }

        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        // Create Masks subdirectory
        let masksURL = documentsURL.appendingPathComponent("Masks", isDirectory: true)
        try? fileManager.createDirectory(at: masksURL, withIntermediateDirectories: true)

        let fileURL = masksURL.appendingPathComponent("\(name).png")

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("  ❌ Error saving mask: \(error)")
            return nil
        }
    }

    /// Infer region from layer name
    private static func inferRegion(from name: String, order: Int, totalLayers: Int) -> MaskGenerator.Region {
        let lowercaseName = name.lowercased()

        if lowercaseName.contains("sky") || lowercaseName.contains("background") {
            return .top
        } else if lowercaseName.contains("mountain") || lowercaseName.contains("tree") || lowercaseName.contains("clouds") || lowercaseName.contains("middle") {
            return .middle
        } else if lowercaseName.contains("foreground") || lowercaseName.contains("shore") || lowercaseName.contains("path") || lowercaseName.contains("water") {
            return .bottom
        }

        // Fallback: divide evenly
        if totalLayers == 2 {
            return order == 0 ? .top : .bottom
        } else if totalLayers == 3 {
            return order == 0 ? .top : (order == 1 ? .middle : .bottom)
        } else {
            let fraction = CGFloat(order) / CGFloat(totalLayers)
            let height = 1.0 / CGFloat(totalLayers)
            return .custom(fraction, fraction + height)
        }
    }

    /// Generate example base images (with outlines)
    static func generateExampleBaseImages() {
        print("\n🖼️ Generating example base images...")

        let templates = Template.createSampleTemplates()
        let size = CGSize(width: 2048, height: 2048)

        for template in templates {
            guard let baseImage = generateBaseImageForTemplate(template, size: size) else {
                continue
            }

            if saveImageToDocuments(baseImage, name: template.baseImageName) != nil {
                print("  ✅ Saved base image: \(template.baseImageName).png")
            }
        }
    }

    /// Generate a simple base image with layer outlines
    private static func generateBaseImageForTemplate(_ template: Template, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        // White background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        // Draw layer boundaries with light gray
        context.setStrokeColor(UIColor.lightGray.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(2)

        for layerDef in template.layerDefinitions {
            let region = inferRegion(from: layerDef.name, order: layerDef.order, totalLayers: template.layerDefinitions.count)

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

            // Draw horizontal lines
            if yStart > 0 {
                context.move(to: CGPoint(x: 0, y: yStart))
                context.addLine(to: CGPoint(x: size.width, y: yStart))
                context.strokePath()
            }

            if yEnd < size.height {
                context.move(to: CGPoint(x: 0, y: yEnd))
                context.addLine(to: CGPoint(x: size.width, y: yEnd))
                context.strokePath()
            }
        }

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    /// Save image to Documents
    private static func saveImageToDocuments(_ image: UIImage, name: String) -> URL? {
        guard let data = image.pngData() else {
            return nil
        }

        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let baseImagesURL = documentsURL.appendingPathComponent("BaseImages", isDirectory: true)
        try? fileManager.createDirectory(at: baseImagesURL, withIntermediateDirectories: true)

        let fileURL = baseImagesURL.appendingPathComponent("\(name).png")

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("  ❌ Error saving base image: \(error)")
            return nil
        }
    }
}
