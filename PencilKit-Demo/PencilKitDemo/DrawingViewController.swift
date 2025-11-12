//
//  DrawingViewController.swift
//  PencilKitDemo
//
//  Simple drawing canvas using Apple's PencilKit
//

import UIKit
import PencilKit

class DrawingViewController: UIViewController {

    var canvasView: PKCanvasView!
    var toolPicker: PKToolPicker!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        // Setup PencilKit canvas
        setupCanvas()

        // Setup tool picker (Apple's built-in tool UI)
        setupToolPicker()

        // Setup controls
        setupControls()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Show tool picker
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()
    }

    private func setupCanvas() {
        // Create PencilKit canvas
        canvasView = PKCanvasView(frame: view.bounds)
        canvasView.backgroundColor = .white
        canvasView.drawingPolicy = .anyInput  // Allow finger and pencil
        canvasView.delegate = self
        view.addSubview(canvasView)

        // Set default drawing
        canvasView.drawing = PKDrawing()
    }

    private func setupToolPicker() {
        // Get the shared tool picker (Apple's built-in UI)
        toolPicker = PKToolPicker()
        toolPicker.addObserver(canvasView)
    }

    private func setupControls() {
        // Create a simple toolbar at the top
        let toolbar = UIView()
        toolbar.backgroundColor = UIColor.white.withAlphaComponent(0.95)
        toolbar.layer.shadowColor = UIColor.black.cgColor
        toolbar.layer.shadowOpacity = 0.1
        toolbar.layer.shadowOffset = CGSize(width: 0, height: 2)
        toolbar.layer.shadowRadius = 4
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)

        // Clear button
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear", for: .normal)
        clearButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        clearButton.addTarget(self, action: #selector(clearCanvas), for: .touchUpInside)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(clearButton)

        // Undo button
        let undoButton = UIButton(type: .system)
        undoButton.setTitle("↶ Undo", for: .normal)
        undoButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        undoButton.addTarget(self, action: #selector(undo), for: .touchUpInside)
        undoButton.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(undoButton)

        // Redo button
        let redoButton = UIButton(type: .system)
        redoButton.setTitle("Redo ↷", for: .normal)
        redoButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        redoButton.addTarget(self, action: #selector(redo), for: .touchUpInside)
        redoButton.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(redoButton)

        // Layout
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 60),

            clearButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            clearButton.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 16),

            undoButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            undoButton.leadingAnchor.constraint(equalTo: clearButton.trailingAnchor, constant: 20),

            redoButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            redoButton.leadingAnchor.constraint(equalTo: undoButton.trailingAnchor, constant: 20)
        ])
    }

    @objc private func clearCanvas() {
        canvasView.drawing = PKDrawing()
    }

    @objc private func undo() {
        canvasView.undoManager?.undo()
    }

    @objc private func redo() {
        canvasView.undoManager?.redo()
    }
}

// MARK: - PKCanvasViewDelegate

extension DrawingViewController: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        // Called whenever the drawing changes
        // You can add progress tracking here if needed
    }
}
