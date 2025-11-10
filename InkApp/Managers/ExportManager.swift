//
//  ExportManager.swift
//  Ink - Pattern Drawing App
//
//  Handles exporting artwork to various formats
//  Created on November 10, 2025.
//

import UIKit
import CoreGraphics

class ExportManager {

    // MARK: - Export Settings
    struct ExportSettings {
        let format: ExportFormat
        let quality: ExportQuality
        let includeWatermark: Bool
        let backgroundColor: UIColor

        enum ExportFormat {
            case png
            case jpeg
            // Future: pdf, svg
        }

        enum ExportQuality {
            case standard  // 72 DPI
            case high      // 150 DPI
            case print     // 300 DPI

            var dpi: CGFloat {
                switch self {
                case .standard: return 72
                case .high: return 150
                case .print: return 300
                }
            }
        }

        static let `default` = ExportSettings(
            format: .png,
            quality: .high,
            includeWatermark: false,
            backgroundColor: .white
        )
    }

    // MARK: - Export Methods

    /// Export project to image
    func exportImage(
        project: Project,
        settings: ExportSettings = .default,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // TODO: Implement actual rendering from Metal textures
                // For now, create placeholder
                let image = try self.renderProjectToImage(project: project, settings: settings)

                DispatchQueue.main.async {
                    completion(.success(image))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    /// Save to Photos library
    func saveToPhotos(
        image: UIImage,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        UIImageWriteToSavedPhotosAlbum(
            image,
            self,
            #selector(image(_:didFinishSavingWithError:contextInfo:)),
            nil
        )

        // Store completion handler
        self.saveCompletionHandler = completion
    }

    private var saveCompletionHandler: ((Result<Bool, Error>) -> Void)?

    @objc private func image(
        _ image: UIImage,
        didFinishSavingWithError error: Error?,
        contextInfo: UnsafeRawPointer
    ) {
        if let error = error {
            saveCompletionHandler?(.failure(error))
        } else {
            saveCompletionHandler?(.success(true))
        }
        saveCompletionHandler = nil
    }

    /// Share using activity controller
    func share(
        image: UIImage,
        from viewController: UIViewController,
        sourceView: UIView? = nil
    ) {
        let activityController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        // For iPad
        if let popover = activityController.popoverPresentationController {
            popover.sourceView = sourceView ?? viewController.view
            popover.sourceRect = sourceView?.bounds ?? viewController.view.bounds
        }

        viewController.present(activityController, animated: true)
    }

    // MARK: - Private Rendering

    private func renderProjectToImage(
        project: Project,
        settings: ExportSettings
    ) throws -> UIImage {
        let size = project.canvasSize
        let scale = settings.quality.dpi / 72.0

        // Create graphics context
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        let image = renderer.image { context in
            let cgContext = context.cgContext

            // Fill background
            cgContext.setFillColor(settings.backgroundColor.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))

            // TODO: Render base image
            if let baseImageData = project.baseImageData,
               let baseImage = UIImage(data: baseImageData) {
                baseImage.draw(in: CGRect(origin: .zero, size: size))
            }

            // TODO: Render all visible layers
            // This will be implemented when Metal rendering is complete

            // Add watermark if needed
            if settings.includeWatermark {
                addWatermark(to: cgContext, size: size)
            }
        }

        return image
    }

    private func addWatermark(to context: CGContext, size: CGSize) {
        let watermarkText = "Made with Ink"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .light),
            .foregroundColor: UIColor.black.withAlphaComponent(0.3)
        ]

        let attributedString = NSAttributedString(string: watermarkText, attributes: attributes)
        let textSize = attributedString.size()

        let point = CGPoint(
            x: size.width - textSize.width - 20,
            y: size.height - textSize.height - 20
        )

        attributedString.draw(at: point)
    }

    // MARK: - Format Conversion

    func imageData(from image: UIImage, format: ExportSettings.ExportFormat) -> Data? {
        switch format {
        case .png:
            return image.pngData()
        case .jpeg:
            return image.jpegData(compressionQuality: 0.9)
        }
    }
}

// MARK: - Export Errors

enum ExportError: LocalizedError {
    case renderingFailed
    case insufficientMemory
    case invalidProject
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .renderingFailed:
            return "Failed to render the artwork"
        case .insufficientMemory:
            return "Not enough memory to export at this quality"
        case .invalidProject:
            return "Project data is invalid"
        case .saveFailed:
            return "Failed to save to Photos"
        }
    }
}
