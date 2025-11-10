//
//  PressureCurveEditorView.swift
//  Ink - Pattern Drawing App
//
//  Pressure curve editor with presets and graph
//  Created on November 10, 2025.
//

import UIKit

protocol PressureCurveEditorDelegate: AnyObject {
    func pressureCurveEditor(_ editor: PressureCurveEditorView, didUpdateCurve curveType: BrushConfiguration.PressureCurve.CurveType)
    func pressureCurveEditorDidCancel(_ editor: PressureCurveEditorView)
}

class PressureCurveEditorView: UIView {

    // MARK: - Properties

    weak var delegate: PressureCurveEditorDelegate?

    private var currentCurveType: BrushConfiguration.PressureCurve.CurveType = .linear
    private var customControlPoints: [Float] = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]

    // UI Elements
    private var containerView: UIView!
    private var titleLabel: UILabel!
    private var curveGraphView: CurveGraphView!
    private var presetStackView: UIStackView!
    private var cancelButton: UIButton!
    private var applyButton: UIButton!

    // Preset buttons
    private var presetButtons: [UIButton] = []

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        // Semi-transparent background
        backgroundColor = UIColor.black.withAlphaComponent(0.5)

        // Container view
        containerView = UIView()
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 20
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowOffset = CGSize(width: 0, height: 10)
        containerView.layer.shadowRadius = 20

        addSubview(containerView)

        // Title
        titleLabel = UILabel()
        titleLabel.text = "Pressure Curve Editor"
        titleLabel.font = DesignTokens.Typography.systemFont(size: 20, weight: .semibold)
        titleLabel.textColor = DesignTokens.Colors.textPrimary
        titleLabel.textAlignment = .center

        containerView.addSubview(titleLabel)

        // Curve graph
        curveGraphView = CurveGraphView()
        curveGraphView.delegate = self
        curveGraphView.backgroundColor = DesignTokens.Colors.surface

        containerView.addSubview(curveGraphView)

        // Preset buttons
        createPresetButtons()

        // Action buttons
        createActionButtons()

        // Layout
        setupConstraints()
    }

    private func createPresetButtons() {
        presetStackView = UIStackView()
        presetStackView.axis = .horizontal
        presetStackView.distribution = .fillEqually
        presetStackView.spacing = 8

        let presets: [(String, BrushConfiguration.PressureCurve.CurveType)] = [
            ("Linear", .linear),
            ("Ease In", .easeIn),
            ("Ease Out", .easeOut),
            ("S-Curve", .easeInOut),
            ("Custom", .custom([]))
        ]

        for (title, curveType) in presets {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = DesignTokens.Typography.systemFont(size: 14, weight: .medium)
            button.backgroundColor = DesignTokens.Colors.surface
            button.setTitleColor(DesignTokens.Colors.inkPrimary, for: .normal)
            button.layer.cornerRadius = 8
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.systemGray4.cgColor

            button.tag = presets.firstIndex(where: { $0.1.description == curveType.description }) ?? 0
            button.addTarget(self, action: #selector(presetButtonTapped(_:)), for: .touchUpInside)

            presetStackView.addArrangedSubview(button)
            presetButtons.append(button)
        }

        containerView.addSubview(presetStackView)
    }

    private func createActionButtons() {
        // Cancel button
        cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = DesignTokens.Typography.systemFont(size: 16, weight: .medium)
        cancelButton.setTitleColor(DesignTokens.Colors.textSecondary, for: .normal)
        cancelButton.backgroundColor = DesignTokens.Colors.surface
        cancelButton.layer.cornerRadius = 12
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)

        containerView.addSubview(cancelButton)

        // Apply button
        applyButton = UIButton(type: .system)
        applyButton.setTitle("Apply", for: .normal)
        applyButton.titleLabel?.font = DesignTokens.Typography.systemFont(size: 16, weight: .semibold)
        applyButton.setTitleColor(.white, for: .normal)
        applyButton.backgroundColor = DesignTokens.Colors.inkPrimary
        applyButton.layer.cornerRadius = 12
        applyButton.addTarget(self, action: #selector(applyButtonTapped), for: .touchUpInside)

        containerView.addSubview(applyButton)
    }

    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        curveGraphView.translatesAutoresizingMaskIntoConstraints = false
        presetStackView.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        applyButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Container view (centered)
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 400),
            containerView.heightAnchor.constraint(equalToConstant: 500),

            // Title
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            // Curve graph
            curveGraphView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            curveGraphView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            curveGraphView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            curveGraphView.heightAnchor.constraint(equalToConstant: 280),

            // Preset buttons
            presetStackView.topAnchor.constraint(equalTo: curveGraphView.bottomAnchor, constant: 20),
            presetStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            presetStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            presetStackView.heightAnchor.constraint(equalToConstant: 44),

            // Cancel button
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            cancelButton.widthAnchor.constraint(equalToConstant: 120),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),

            // Apply button
            applyButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            applyButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            applyButton.widthAnchor.constraint(equalToConstant: 120),
            applyButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Public Methods

    func configure(with curveType: BrushConfiguration.PressureCurve.CurveType) {
        currentCurveType = curveType

        // Generate control points from curve type
        let points = generateControlPoints(for: curveType)
        curveGraphView.setControlPoints(points)

        // Update button selection
        updatePresetButtonSelection()
    }

    private func generateControlPoints(for curveType: BrushConfiguration.PressureCurve.CurveType) -> [Float] {
        switch curveType {
        case .linear:
            return (0...10).map { Float($0) / 10.0 }

        case .easeIn:
            return (0...10).map { input in
                let t = Float(input) / 10.0
                return t * t
            }

        case .easeOut:
            return (0...10).map { input in
                let t = Float(input) / 10.0
                return 1.0 - (1.0 - t) * (1.0 - t)
            }

        case .easeInOut:
            return (0...10).map { input in
                let t = Float(input) / 10.0
                if t < 0.5 {
                    return 2.0 * t * t
                } else {
                    return 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0
                }
            }

        case .custom(let points):
            if points.count == 11 {
                return points
            } else {
                // Fallback to linear
                return (0...10).map { Float($0) / 10.0 }
            }
        }
    }

    private func updatePresetButtonSelection() {
        let selectedIndex: Int
        switch currentCurveType {
        case .linear: selectedIndex = 0
        case .easeIn: selectedIndex = 1
        case .easeOut: selectedIndex = 2
        case .easeInOut: selectedIndex = 3
        case .custom: selectedIndex = 4
        }

        for (index, button) in presetButtons.enumerated() {
            if index == selectedIndex {
                button.backgroundColor = DesignTokens.Colors.inkPrimary
                button.setTitleColor(.white, for: .normal)
                button.layer.borderWidth = 0
            } else {
                button.backgroundColor = DesignTokens.Colors.surface
                button.setTitleColor(DesignTokens.Colors.inkPrimary, for: .normal)
                button.layer.borderWidth = 1
            }
        }
    }

    // MARK: - Actions

    @objc private func presetButtonTapped(_ sender: UIButton) {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        let curveTypes: [BrushConfiguration.PressureCurve.CurveType] = [
            .linear, .easeIn, .easeOut, .easeInOut, .custom(customControlPoints)
        ]

        guard sender.tag < curveTypes.count else { return }

        currentCurveType = curveTypes[sender.tag]
        let points = generateControlPoints(for: currentCurveType)
        curveGraphView.setControlPoints(points)
        updatePresetButtonSelection()

        // If custom is selected, user can edit the curve
        if case .custom = currentCurveType {
            // Already showing graph, user can drag points
        }
    }

    @objc private func cancelButtonTapped() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        // Animate button
        UIView.animate(withDuration: 0.1) {
            self.cancelButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.cancelButton.transform = .identity
            }
        }

        delegate?.pressureCurveEditorDidCancel(self)
    }

    @objc private func applyButtonTapped() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Animate button
        UIView.animate(withDuration: 0.1) {
            self.applyButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.applyButton.transform = .identity
            }
        }

        // Get final curve type
        let finalCurveType: BrushConfiguration.PressureCurve.CurveType
        if case .custom = currentCurveType {
            // Use actual control points from graph
            finalCurveType = .custom(curveGraphView.getControlPoints())
        } else {
            finalCurveType = currentCurveType
        }

        delegate?.pressureCurveEditor(self, didUpdateCurve: finalCurveType)
    }

    // MARK: - Presentation

    func present(in parentView: UIView) {
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.9, y: 0.9)

        parentView.addSubview(self)

        frame = parentView.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]

        UIView.animate(
            withDuration: DesignTokens.Animation.durationMedium,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0,
            options: [.curveEaseOut],
            animations: {
                self.alpha = 1
                self.transform = .identity
            }
        )
    }

    func dismiss() {
        UIView.animate(
            withDuration: DesignTokens.Animation.durationFast,
            animations: {
                self.alpha = 0
                self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            },
            completion: { _ in
                self.removeFromSuperview()
            }
        )
    }
}

// MARK: - CurveGraphViewDelegate

extension PressureCurveEditorView: CurveGraphViewDelegate {
    func curveGraphView(_ graphView: CurveGraphView, didUpdateControlPoints points: [Float]) {
        // Store custom points
        customControlPoints = points

        // Switch to custom mode if not already
        if case .custom = currentCurveType {
            // Already in custom mode
        } else {
            currentCurveType = .custom(points)
            updatePresetButtonSelection()
        }
    }
}

// MARK: - CurveType Description Extension

extension BrushConfiguration.PressureCurve.CurveType {
    var description: String {
        switch self {
        case .linear: return "linear"
        case .easeIn: return "easeIn"
        case .easeOut: return "easeOut"
        case .easeInOut: return "easeInOut"
        case .custom: return "custom"
        }
    }
}
