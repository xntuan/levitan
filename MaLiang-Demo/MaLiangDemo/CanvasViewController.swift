//
//  CanvasViewController.swift
//  MaLiangDemo
//
//  Simple drawing canvas using MaLiang
//

import UIKit
import MaLiang

class CanvasViewController: UIViewController {

    var canvas: Canvas!
    var brush: Brush!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        // Setup MaLiang canvas
        setupCanvas()

        // Setup controls
        setupControls()
    }

    private func setupCanvas() {
        // Create MaLiang canvas
        canvas = Canvas(frame: view.bounds)
        canvas.backgroundColor = .white
        view.addSubview(canvas)

        // Create a basic brush
        let texture = try? canvas.defaultBrush.makeTexture(size: 128)
        brush = Brush(
            name: "Default",
            textureID: texture?.id,
            target: canvas
        )
        brush.opacity = 1.0
        brush.pointSize = 10
        brush.pointStep = 2
        brush.color = .black

        // Set as current brush
        canvas.currentBrush = brush
    }

    private func setupControls() {
        // Create a simple toolbar
        let toolbar = UIView()
        toolbar.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)

        // Clear button
        let clearButton = UIButton(type: .system)
        clearButton.setTitle("Clear", for: .normal)
        clearButton.addTarget(self, action: #selector(clearCanvas), for: .touchUpInside)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(clearButton)

        // Undo button
        let undoButton = UIButton(type: .system)
        undoButton.setTitle("Undo", for: .normal)
        undoButton.addTarget(self, action: #selector(undo), for: .touchUpInside)
        undoButton.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(undoButton)

        // Redo button
        let redoButton = UIButton(type: .system)
        redoButton.setTitle("Redo", for: .normal)
        redoButton.addTarget(self, action: #selector(redo), for: .touchUpInside)
        redoButton.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(redoButton)

        // Size slider
        let sizeLabel = UILabel()
        sizeLabel.text = "Size:"
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(sizeLabel)

        let sizeSlider = UISlider()
        sizeSlider.minimumValue = 1
        sizeSlider.maximumValue = 50
        sizeSlider.value = 10
        sizeSlider.addTarget(self, action: #selector(sizeChanged(_:)), for: .valueChanged)
        sizeSlider.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(sizeSlider)

        // Layout
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 120),

            clearButton.topAnchor.constraint(equalTo: toolbar.topAnchor, constant: 16),
            clearButton.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 16),

            undoButton.topAnchor.constraint(equalTo: toolbar.topAnchor, constant: 16),
            undoButton.leadingAnchor.constraint(equalTo: clearButton.trailingAnchor, constant: 16),

            redoButton.topAnchor.constraint(equalTo: toolbar.topAnchor, constant: 16),
            redoButton.leadingAnchor.constraint(equalTo: undoButton.trailingAnchor, constant: 16),

            sizeLabel.topAnchor.constraint(equalTo: clearButton.bottomAnchor, constant: 16),
            sizeLabel.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 16),

            sizeSlider.centerYAnchor.constraint(equalTo: sizeLabel.centerYAnchor),
            sizeSlider.leadingAnchor.constraint(equalTo: sizeLabel.trailingAnchor, constant: 8),
            sizeSlider.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor, constant: -16)
        ])
    }

    @objc private func clearCanvas() {
        canvas.clear()
    }

    @objc private func undo() {
        canvas.undo()
    }

    @objc private func redo() {
        canvas.redo()
    }

    @objc private func sizeChanged(_ slider: UISlider) {
        brush.pointSize = CGFloat(slider.value)
    }
}
