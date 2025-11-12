//
//  CanvasViewController.swift
//  Ink - Pattern Drawing App
//
//  Created on November 10, 2025.
//

import UIKit
import MetalKit

class CanvasViewController: UIViewController {

    // MARK: - Properties
    var metalView: MTKView!
    var renderer: MetalRenderer?

    // Canvas state
    var canvasSize: CGSize = CGSize(width: 2048, height: 2048)
    var zoom: CGFloat = 1.0
    var offset: CGPoint = .zero

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMetalView()
        setupGestures()
    }

    // MARK: - Setup
    private func setupMetalView() {
        metalView = MTKView(frame: view.bounds)
        metalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(metalView)

        renderer = MetalRenderer(metalView: metalView)

        // Configure view
        metalView.clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        metalView.colorPixelFormat = .bgra8Unorm
    }

    private func setupGestures() {
        // Pinch to zoom
        let pinch = UIPinchGestureRecognizer(
            target: self,
            action: #selector(handlePinch(_:))
        )
        metalView.addGestureRecognizer(pinch)

        // Two-finger pan
        let pan = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePan(_:))
        )
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        metalView.addGestureRecognizer(pan)
    }

    // MARK: - Gesture Handlers
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard gesture.state == .changed else { return }

        let newZoom = zoom * gesture.scale
        zoom = max(0.5, min(4.0, newZoom))

        gesture.scale = 1.0

        // TODO: Update renderer transform
        print("Zoom: \(zoom)")
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state == .changed else { return }

        let translation = gesture.translation(in: metalView)
        offset.x += translation.x
        offset.y += translation.y

        gesture.setTranslation(.zero, in: metalView)

        // TODO: Update renderer transform
        print("Offset: \(offset)")
    }

    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: metalView)

        // TODO: Begin stroke
        print("Touch began at: \(point)")
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        _ = touch.location(in: metalView)

        // TODO: Continue stroke
        // print("Touch moved to: \(point)")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // TODO: End stroke
        print("Touch ended")
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // TODO: Cancel stroke
        print("Touch cancelled")
    }
}
