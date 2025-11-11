//
//  DrawingRecorder.swift
//  Ink - Pattern Drawing App
//
//  Records drawing process for time-lapse video export
//  Created on November 11, 2025.
//

import AVFoundation
import CoreGraphics
import Metal
import UIKit

/// Records drawing strokes and generates time-lapse videos
class DrawingRecorder {

    // MARK: - Properties

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue

    // Recording state
    private(set) var isRecording: Bool = false
    private(set) var isPaused: Bool = false

    // Recorded frames
    private var frames: [RecordedFrame] = []
    private var startTime: Date?
    private var totalPausedTime: TimeInterval = 0
    private var pauseStartTime: Date?

    // Recording configuration
    var fps: Int = 30                   // Playback frames per second
    var speedMultiplier: Float = 10.0   // 10x speed time-lapse
    var resolution: CGSize = CGSize(width: 1920, height: 1920)
    var quality: ExportQuality = .high
    var maxFrames: Int = 3600           // Maximum frames to store (10 min at 1 frame/sec = 360, 1 hour = 3600)

    // Callbacks
    var onFrameCaptured: ((Int) -> Void)?
    var onExportProgress: ((Float) -> Void)?

    // MARK: - Initialization

    init(device: MTLDevice, commandQueue: MTLCommandQueue) {
        self.device = device
        self.commandQueue = commandQueue
    }

    // MARK: - Recording Control

    /// Start recording
    func startRecording() {
        guard !isRecording else {
            print("⚠️ Already recording")
            return
        }

        frames.removeAll()
        startTime = Date()
        totalPausedTime = 0
        pauseStartTime = nil
        isRecording = true
        isPaused = false

        print("🔴 Recording started")
    }

    /// Pause recording
    func pauseRecording() {
        guard isRecording && !isPaused else { return }

        pauseStartTime = Date()
        isPaused = true

        print("⏸️ Recording paused")
    }

    /// Resume recording
    func resumeRecording() {
        guard isRecording && isPaused else { return }

        if let pauseStart = pauseStartTime {
            totalPausedTime += Date().timeIntervalSince(pauseStart)
        }

        pauseStartTime = nil
        isPaused = false

        print("▶️ Recording resumed")
    }

    /// Stop recording
    func stopRecording() {
        guard isRecording else { return }

        isRecording = false
        isPaused = false
        pauseStartTime = nil

        print("⏹️ Recording stopped: \(frames.count) frames captured")
    }

    // MARK: - Frame Capture

    /// Capture current canvas state
    func captureFrame(texture: MTLTexture, strokeCount: Int) {
        guard isRecording && !isPaused else { return }
        guard let startTime = startTime else { return }

        // Check frame limit to prevent unbounded memory growth
        guard frames.count < maxFrames else {
            print("⚠️ Maximum frame limit reached (\(maxFrames)). Skipping frame.")
            return
        }

        // Calculate timestamp (excluding paused time)
        let timestamp = Date().timeIntervalSince(startTime) - totalPausedTime

        // Capture texture
        guard let image = textureToUIImage(texture) else {
            print("❌ Failed to capture frame")
            return
        }

        let frame = RecordedFrame(
            timestamp: timestamp,
            image: image,
            strokeCount: strokeCount
        )

        frames.append(frame)
        onFrameCaptured?(frames.count)
    }

    // MARK: - Export

    /// Export time-lapse video
    func exportVideo(
        outputURL: URL,
        completion: @escaping (Result<VideoExportResult, RecorderError>) -> Void
    ) {
        guard !frames.isEmpty else {
            completion(.failure(.noFrames))
            return
        }

        // Input validation
        guard fps > 0 && fps <= 120 else {
            completion(.failure(.exportFailed("Invalid FPS: must be 1-120")))
            return
        }

        guard speedMultiplier > 0 && speedMultiplier <= 100 else {
            completion(.failure(.exportFailed("Invalid speed multiplier: must be 0.1-100")))
            return
        }

        guard resolution.width > 0 && resolution.height > 0 else {
            completion(.failure(.exportFailed("Invalid resolution")))
            return
        }

        print("📹 Exporting video: \(frames.count) frames at \(fps)fps, \(speedMultiplier)x speed")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                // Create video writer
                let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

                let videoSettings = self.createVideoSettings()
                let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                writerInput.expectsMediaDataInRealTime = false

                let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                    assetWriterInput: writerInput,
                    sourcePixelBufferAttributes: self.createPixelBufferAttributes()
                )

                writer.add(writerInput)
                writer.startWriting()
                writer.startSession(atSourceTime: .zero)

                // Write frames
                var frameIndex = 0
                let frameDuration = CMTime(value: 1, timescale: CMTimeScale(self.fps))

                for frame in self.frames {
                    // Wait until input is ready
                    while !writerInput.isReadyForMoreMediaData {
                        Thread.sleep(forTimeInterval: 0.01)
                    }

                    // Create pixel buffer from image
                    guard let pixelBuffer = self.pixelBuffer(from: frame.image) else {
                        throw RecorderError.frameProcessingFailed
                    }

                    let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameIndex))
                    adaptor.append(pixelBuffer, withPresentationTime: presentationTime)

                    frameIndex += 1

                    // Update progress
                    let progress = Float(frameIndex) / Float(self.frames.count)
                    DispatchQueue.main.async {
                        self.onExportProgress?(progress)
                    }
                }

                // Finish writing
                writerInput.markAsFinished()
                writer.finishWriting {
                    let result = VideoExportResult(
                        videoURL: outputURL,
                        duration: Double(frameIndex) / Double(self.fps),
                        frameCount: frameIndex,
                        fileSize: self.fileSize(at: outputURL)
                    )

                    DispatchQueue.main.async {
                        completion(.success(result))
                        print("✅ Video exported: \(result.duration)s, \(result.fileSize / 1024 / 1024)MB")
                    }
                }

            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.exportFailed(error.localizedDescription)))
                }
            }
        }
    }

    // MARK: - Helpers

    private func textureToUIImage(_ texture: MTLTexture) -> UIImage? {
        let width = texture.width
        let height = texture.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let byteCount = bytesPerRow * height

        var pixelData = [UInt8](repeating: 0, count: byteCount)

        let region = MTLRegionMake2D(0, 0, width, height)
        texture.getBytes(&pixelData, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)

        guard let providerRef = CGDataProvider(
            data: Data(bytes: &pixelData, count: byteCount) as CFData
        ) else {
            return nil
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        ) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    private func pixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        let width = Int(resolution.width)
        let height = Int(resolution.height)

        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!,
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height,
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32ARGB
        ] as CFDictionary

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attrs,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(
            data: pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }

        context.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: width, height: height))

        return buffer
    }

    private func createVideoSettings() -> [String: Any] {
        var compressionSettings: [String: Any] = [:]

        switch quality {
        case .low:
            compressionSettings = [
                AVVideoAverageBitRateKey: 2_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel
            ]
        case .medium:
            compressionSettings = [
                AVVideoAverageBitRateKey: 5_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264MainAutoLevel
            ]
        case .high:
            compressionSettings = [
                AVVideoAverageBitRateKey: 10_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        }

        return [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: resolution.width,
            AVVideoHeightKey: resolution.height,
            AVVideoCompressionPropertiesKey: compressionSettings
        ]
    }

    private func createPixelBufferAttributes() -> [String: Any] {
        return [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: resolution.width,
            kCVPixelBufferHeightKey as String: resolution.height
        ]
    }

    private func fileSize(at url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }

    // MARK: - Statistics

    func getStatistics() -> RecordingStatistics {
        let duration = frames.last?.timestamp ?? 0
        let exportDuration = duration / Double(speedMultiplier)

        return RecordingStatistics(
            frameCount: frames.count,
            recordingDuration: duration,
            exportDuration: exportDuration,
            fps: fps,
            speedMultiplier: speedMultiplier,
            estimatedFileSize: estimateFileSize()
        )
    }

    private func estimateFileSize() -> Int64 {
        let pixelCount = resolution.width * resolution.height
        let duration = (frames.last?.timestamp ?? 0) / Double(speedMultiplier)
        let bitrate: Int64

        switch quality {
        case .low: bitrate = 2_000_000
        case .medium: bitrate = 5_000_000
        case .high: bitrate = 10_000_000
        }

        return Int64(duration) * bitrate / 8
    }
}

// MARK: - Supporting Types

struct RecordedFrame {
    let timestamp: TimeInterval
    let image: UIImage
    let strokeCount: Int
}

struct VideoExportResult {
    let videoURL: URL
    let duration: TimeInterval
    let frameCount: Int
    let fileSize: Int64
}

struct RecordingStatistics {
    let frameCount: Int
    let recordingDuration: TimeInterval
    let exportDuration: TimeInterval
    let fps: Int
    let speedMultiplier: Float
    let estimatedFileSize: Int64

    var recordingDurationFormatted: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var exportDurationFormatted: String {
        let minutes = Int(exportDuration) / 60
        let seconds = Int(exportDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var estimatedFileSizeFormatted: String {
        let mb = Double(estimatedFileSize) / 1024.0 / 1024.0
        return String(format: "%.1f MB", mb)
    }
}

enum ExportQuality: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var displayName: String { rawValue }

    var bitrate: Int {
        switch self {
        case .low: return 2_000_000
        case .medium: return 5_000_000
        case .high: return 10_000_000
        }
    }
}

enum RecorderError: Error, LocalizedError {
    case noFrames
    case frameProcessingFailed
    case exportFailed(String)
    case insufficientStorage

    var errorDescription: String? {
        switch self {
        case .noFrames:
            return "No frames recorded"
        case .frameProcessingFailed:
            return "Failed to process frame"
        case .exportFailed(let message):
            return "Export failed: \(message)"
        case .insufficientStorage:
            return "Insufficient storage space"
        }
    }
}
