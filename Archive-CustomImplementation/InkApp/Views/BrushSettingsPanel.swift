//
//  BrushSettingsPanel.swift
//  Ink - Pattern Drawing App
//
//  Modal panel for adjusting brush settings with live preview
//  Created on November 10, 2025.
//

import UIKit

protocol BrushSettingsPanelDelegate: AnyObject {
    func brushSettingsPanel(_ panel: BrushSettingsPanel, didUpdateBrush brush: PatternBrush)
    func brushSettingsPanelDidCancel(_ panel: BrushSettingsPanel)
}

class BrushSettingsPanel: UIView {

    // MARK: - Properties

    weak var delegate: BrushSettingsPanelDelegate?

    private var originalBrush: PatternBrush
    private var currentBrush: PatternBrush

    // UI Elements
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.98)
        view.layer.cornerRadius = 24
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.masksToBounds = true
        return view
    }()

    private let handleBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray3
        view.layer.cornerRadius = 2.5
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Brush Settings"
        label.font = DesignTokens.Typography.systemFont(
            size: 18,
            weight: DesignTokens.Typography.semibold
        )
        label.textColor = DesignTokens.Colors.textPrimary
        label.textAlignment = .center
        return label
    }()

    private let previewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = DesignTokens.Colors.surface
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGray5.cgColor
        return view
    }()

    private let previewImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .white
        return iv
    }()

    // Sliders
    private var rotationSlider: SliderControl!
    private var spacingSlider: SliderControl!
    private var opacitySlider: SliderControl!
    private var scaleSlider: SliderControl!
    private var densitySlider: SliderControl!

    // Buttons
    private let applyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Apply", for: .normal)
        button.titleLabel?.font = DesignTokens.Typography.systemFont(
            size: 15,
            weight: DesignTokens.Typography.semibold
        )
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 24
        return button
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = DesignTokens.Typography.systemFont(
            size: 15,
            weight: DesignTokens.Typography.semibold
        )
        button.setTitleColor(DesignTokens.Colors.inkPrimary, for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 24
        button.layer.borderWidth = 2
        button.layer.borderColor = DesignTokens.Colors.inkPrimary.cgColor
        return button
    }()

    private let dimView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        return view
    }()

    // MARK: - Initialization

    init(brush: PatternBrush) {
        self.originalBrush = brush
        self.currentBrush = brush
        super.init(frame: .zero)
        setupViews()
        setupSliders()
        setupButtons()
        updatePreview()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .clear

        // Dim background
        addSubview(dimView)

        // Add blur to container
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = containerView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.insertSubview(blurView, at: 0)

        addSubview(containerView)

        // Add subviews to container
        containerView.addSubview(handleBar)
        containerView.addSubview(titleLabel)
        containerView.addSubview(previewContainer)
        previewContainer.addSubview(previewImageView)
        containerView.addSubview(applyButton)
        containerView.addSubview(cancelButton)

        // Layout
        dimView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        handleBar.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Dim view fills entire view
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Container view at bottom
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 584),

            // Handle bar
            handleBar.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            handleBar.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            handleBar.widthAnchor.constraint(equalToConstant: 40),
            handleBar.heightAnchor.constraint(equalToConstant: 5),

            // Title
            titleLabel.topAnchor.constraint(equalTo: handleBar.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            // Preview container
            previewContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            previewContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            previewContainer.widthAnchor.constraint(equalToConstant: 200),
            previewContainer.heightAnchor.constraint(equalToConstant: 200),

            // Preview image
            previewImageView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            previewImageView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            previewImageView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),

            // Buttons at bottom
            applyButton.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            applyButton.trailingAnchor.constraint(equalTo: containerView.centerXAnchor, constant: -6),
            applyButton.widthAnchor.constraint(equalToConstant: 140),
            applyButton.heightAnchor.constraint(equalToConstant: 48),

            cancelButton.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.centerXAnchor, constant: 6),
            cancelButton.widthAnchor.constraint(equalToConstant: 140),
            cancelButton.heightAnchor.constraint(equalToConstant: 48)
        ])

        // Apply button gradient
        applyButton.applyGradient(
            colors: DesignTokens.Colors.gradientLavender,
            direction: .leftToRight
        )

        // Shadow
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.15
        containerView.layer.shadowOffset = CGSize(width: 0, height: -8)
        containerView.layer.shadowRadius = 16
        containerView.layer.masksToBounds = false

        // Tap gesture on dim view to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dimViewTapped))
        dimView.addGestureRecognizer(tapGesture)
    }

    private func setupSliders() {
        // Rotation slider (0-360°)
        rotationSlider = SliderControl(
            title: "Rotation",
            minValue: 0,
            maxValue: 360,
            currentValue: currentBrush.rotation,
            unit: "°"
        )
        rotationSlider.delegate = self
        containerView.addSubview(rotationSlider)
        rotationSlider.translatesAutoresizingMaskIntoConstraints = false

        // Spacing slider (5-50px)
        spacingSlider = SliderControl(
            title: "Spacing",
            minValue: 5,
            maxValue: 50,
            currentValue: currentBrush.spacing,
            unit: "px"
        )
        spacingSlider.delegate = self
        containerView.addSubview(spacingSlider)
        spacingSlider.translatesAutoresizingMaskIntoConstraints = false

        // Opacity slider (0-100%)
        opacitySlider = SliderControl(
            title: "Opacity",
            minValue: 0,
            maxValue: 100,
            currentValue: currentBrush.opacity * 100,
            unit: "%"
        )
        opacitySlider.delegate = self
        containerView.addSubview(opacitySlider)
        opacitySlider.translatesAutoresizingMaskIntoConstraints = false

        // Scale slider (0.5-2.0×)
        scaleSlider = SliderControl(
            title: "Scale",
            minValue: 0.5,
            maxValue: 2.0,
            currentValue: currentBrush.scale,
            unit: "×",
            decimalPlaces: 1
        )
        scaleSlider.delegate = self
        containerView.addSubview(scaleSlider)
        scaleSlider.translatesAutoresizingMaskIntoConstraints = false

        // Density slider (0.0-1.0)
        densitySlider = SliderControl(
            title: "Density",
            minValue: 0.0,
            maxValue: 1.0,
            currentValue: currentBrush.density,
            unit: "",
            decimalPlaces: 2
        )
        densitySlider.delegate = self
        containerView.addSubview(densitySlider)
        densitySlider.translatesAutoresizingMaskIntoConstraints = false

        // Layout sliders
        NSLayoutConstraint.activate([
            rotationSlider.topAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: 24),
            rotationSlider.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            rotationSlider.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            spacingSlider.topAnchor.constraint(equalTo: rotationSlider.bottomAnchor, constant: 16),
            spacingSlider.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            spacingSlider.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            opacitySlider.topAnchor.constraint(equalTo: spacingSlider.bottomAnchor, constant: 16),
            opacitySlider.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            opacitySlider.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            scaleSlider.topAnchor.constraint(equalTo: opacitySlider.bottomAnchor, constant: 16),
            scaleSlider.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            scaleSlider.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            densitySlider.topAnchor.constraint(equalTo: scaleSlider.bottomAnchor, constant: 16),
            densitySlider.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            densitySlider.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
        ])
    }

    private func setupButtons() {
        applyButton.addTarget(self, action: #selector(applyButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
    }

    // MARK: - Preview

    private func updatePreview() {
        // Generate pattern preview
        let previewSize = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: previewSize)

        let previewImage = renderer.image { context in
            let cgContext = context.cgContext

            // White background
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: previewSize))

            // Draw pattern at center
            let center = CGPoint(x: previewSize.width / 2, y: previewSize.height / 2)

            // Generate pattern geometry
            let geometry = generatePatternGeometry(center: center)

            // Draw based on pattern type
            drawPatternGeometry(geometry, in: cgContext)
        }

        previewImageView.image = previewImage
    }

    private func generatePatternGeometry(center: CGPoint) -> PatternGeometry {
        // Use the unified pattern generator with density support
        let patternGeom = PatternGenerator.generatePattern(
            type: currentBrush.type,
            center: center,
            rotation: currentBrush.rotation,
            spacing: currentBrush.spacing,
            scale: currentBrush.scale,
            density: currentBrush.density
        )

        // Convert to local enum for drawing
        if !patternGeom.lines.isEmpty {
            return .lines(patternGeom.lines)
        } else if !patternGeom.circles.isEmpty {
            return .circles(patternGeom.circles)
        } else if !patternGeom.arcs.isEmpty {
            return .arcs(patternGeom.arcs)
        } else if !patternGeom.waves.isEmpty {
            return .waves(patternGeom.waves)
        }

        // Fallback to empty lines
        return .lines([])
    }

    private enum PatternGeometry {
        case lines([Line])
        case circles([Circle])
        case arcs([Arc])
        case waves([[CGPoint]])
    }

    private func drawPatternGeometry(_ geometry: PatternGeometry, in context: CGContext) {
        // Set stroke color with opacity
        let color = currentBrush.color
        context.setStrokeColor(
            red: CGFloat(color.red),
            green: CGFloat(color.green),
            blue: CGFloat(color.blue),
            alpha: CGFloat(currentBrush.opacity)
        )
        context.setLineWidth(1.5)
        context.setLineCap(.round)

        switch geometry {
        case .lines(let lines):
            for line in lines {
                context.move(to: line.start)
                context.addLine(to: line.end)
            }
            context.strokePath()

        case .circles(let circles):
            for circle in circles {
                context.addEllipse(in: CGRect(
                    x: circle.center.x - circle.radius,
                    y: circle.center.y - circle.radius,
                    width: circle.radius * 2,
                    height: circle.radius * 2
                ))
            }
            context.strokePath()

        case .arcs(let arcs):
            for arc in arcs {
                context.addArc(
                    center: arc.center,
                    radius: arc.radius,
                    startAngle: arc.startAngle,
                    endAngle: arc.endAngle,
                    clockwise: false
                )
            }
            context.strokePath()

        case .waves(let waves):
            for wave in waves {
                guard let firstPoint = wave.first else { continue }
                context.move(to: firstPoint)
                for point in wave.dropFirst() {
                    context.addLine(to: point)
                }
            }
            context.strokePath()
        }
    }

    // MARK: - Actions

    @objc private func applyButtonTapped() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Notify delegate
        delegate?.brushSettingsPanel(self, didUpdateBrush: currentBrush)

        // Dismiss
        dismiss()
    }

    @objc private func cancelButtonTapped() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        // Notify delegate
        delegate?.brushSettingsPanelDidCancel(self)

        // Dismiss
        dismiss()
    }

    @objc private func dimViewTapped() {
        cancelButtonTapped()
    }

    // MARK: - Presentation

    func present(in view: UIView) {
        frame = view.bounds
        view.addSubview(self)

        // Initial state: container off-screen
        containerView.transform = CGAffineTransform(translationX: 0, y: 584)
        dimView.alpha = 0

        // Animate in
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut,
            animations: {
                self.containerView.transform = .identity
                self.dimView.alpha = 1
            }
        )
    }

    private func dismiss() {
        // Animate out
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                self.containerView.transform = CGAffineTransform(translationX: 0, y: 584)
                self.dimView.alpha = 0
            },
            completion: { _ in
                self.removeFromSuperview()
            }
        )
    }
}

// MARK: - SliderControlDelegate

extension BrushSettingsPanel: SliderControlDelegate {
    func sliderControl(_ slider: SliderControl, didChangeValue value: Float) {
        // Update current brush
        switch slider {
        case rotationSlider:
            currentBrush.rotation = value
        case spacingSlider:
            currentBrush.spacing = value
        case opacitySlider:
            currentBrush.opacity = value / 100.0
        case scaleSlider:
            currentBrush.scale = value
        case densitySlider:
            currentBrush.density = value
            // Also update the densityConfig base density
            currentBrush.densityConfig.baseDensity = value
        default:
            break
        }

        // Update preview
        updatePreview()
    }
}

// MARK: - SliderControl

protocol SliderControlDelegate: AnyObject {
    func sliderControl(_ slider: SliderControl, didChangeValue value: Float)
}

class SliderControl: UIView {

    // MARK: - Properties

    weak var delegate: SliderControlDelegate?

    private let minValue: Float
    private let maxValue: Float
    private var currentValue: Float
    private let unit: String
    private let decimalPlaces: Int

    // UI Elements
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = DesignTokens.Typography.systemFont(
            size: 13,
            weight: DesignTokens.Typography.regular
        )
        label.textColor = DesignTokens.Colors.textSecondary
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = DesignTokens.Typography.systemFont(
            size: 15,
            weight: DesignTokens.Typography.semibold
        )
        label.textColor = DesignTokens.Colors.inkPrimary
        label.textAlignment = .right
        return label
    }()

    private let slider: UISlider = {
        let slider = UISlider()
        slider.minimumTrackTintColor = DesignTokens.Colors.inkPrimary
        slider.maximumTrackTintColor = UIColor.systemGray5
        return slider
    }()

    // MARK: - Initialization

    init(title: String, minValue: Float, maxValue: Float, currentValue: Float, unit: String, decimalPlaces: Int = 0) {
        self.minValue = minValue
        self.maxValue = maxValue
        self.currentValue = currentValue
        self.unit = unit
        self.decimalPlaces = decimalPlaces

        super.init(frame: .zero)

        titleLabel.text = title
        slider.minimumValue = minValue
        slider.maximumValue = maxValue
        slider.value = currentValue

        setupViews()
        updateValueLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(slider)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        slider.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Title on left
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),

            // Value on right
            valueLabel.topAnchor.constraint(equalTo: topAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            // Slider below
            slider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            slider.leadingAnchor.constraint(equalTo: leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: trailingAnchor),
            slider.bottomAnchor.constraint(equalTo: bottomAnchor),

            heightAnchor.constraint(equalToConstant: 48)
        ])

        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
    }

    // MARK: - Actions

    @objc private func sliderValueChanged() {
        currentValue = slider.value
        updateValueLabel()
        delegate?.sliderControl(self, didChangeValue: currentValue)
    }

    private func updateValueLabel() {
        if decimalPlaces > 0 {
            valueLabel.text = String(format: "%.\(decimalPlaces)f%@", currentValue, unit)
        } else {
            valueLabel.text = "\(Int(currentValue))\(unit)"
        }
    }
}

// MARK: - UIView Gradient Extension

extension UIView {
    func applyGradient(colors: [UIColor], direction: GradientDirection) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map { $0.cgColor }

        switch direction {
        case .topToBottom:
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        case .leftToRight:
            gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        case .diagonal:
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        }

        layer.insertSublayer(gradientLayer, at: 0)
    }

    enum GradientDirection {
        case topToBottom, leftToRight, diagonal
    }
}
