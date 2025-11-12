//
//  AdvancedBrushSettingsPanel.swift
//  Ink - Pattern Drawing App
//
//  Advanced settings panel for EnhancedBrushEngine
//  All professional features accessible
//  Created on November 10, 2025.
//

import UIKit

protocol AdvancedBrushSettingsPanelDelegate: AnyObject {
    func advancedBrushSettingsPanel(_ panel: AdvancedBrushSettingsPanel, didUpdateConfiguration config: BrushConfiguration)
    func advancedBrushSettingsPanelDidCancel(_ panel: AdvancedBrushSettingsPanel)
}

class AdvancedBrushSettingsPanel: UIView {

    // MARK: - Properties

    weak var delegate: AdvancedBrushSettingsPanelDelegate?

    private var originalConfig: BrushConfiguration
    private var currentConfig: BrushConfiguration

    // UI Elements
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = true
        return sv
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.98)
        view.layer.cornerRadius = 24
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.masksToBounds = true
        return view
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.distribution = .fill
        return stack
    }()

    private let handleBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray3
        view.layer.cornerRadius = 2.5
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Advanced Brush Settings"
        label.font = DesignTokens.Typography.systemFont(
            size: 20,
            weight: DesignTokens.Typography.semibold
        )
        label.textColor = DesignTokens.Colors.textPrimary
        label.textAlignment = .center
        return label
    }()

    // Preset selector
    private var presetSegmentedControl: UISegmentedControl!

    // Sliders
    private var stabilizationSlider: AdvancedSlider!
    private var predictionSlider: AdvancedSlider!
    private var flowSlider: AdvancedSlider!

    // Pressure curve
    private var pressureCurveControl: UISegmentedControl!

    // Velocity dynamics
    private var velocityDynamicsSwitch: UISwitch!
    private var velocitySettingsStack: UIStackView!

    // Jitter
    private var jitterSwitch: UISwitch!
    private var jitterSettingsStack: UIStackView!

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

    init(configuration: BrushConfiguration) {
        self.originalConfig = configuration
        self.currentConfig = configuration
        super.init(frame: .zero)
        setupViews()
        setupControls()
        updateUIFromConfig()
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

        // Add subviews
        containerView.addSubview(handleBar)
        containerView.addSubview(titleLabel)
        containerView.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        containerView.addSubview(applyButton)
        containerView.addSubview(cancelButton)

        // Layout
        dimView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        handleBar.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),

            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 700),

            handleBar.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            handleBar.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            handleBar.widthAnchor.constraint(equalToConstant: 40),
            handleBar.heightAnchor.constraint(equalToConstant: 5),

            titleLabel.topAnchor.constraint(equalTo: handleBar.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: applyButton.topAnchor, constant: -20),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

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

        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dimViewTapped))
        dimView.addGestureRecognizer(tapGesture)

        // Button actions
        applyButton.addTarget(self, action: #selector(applyButtonTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
    }

    private func setupControls() {
        // Preset Selector
        let presetSection = createSection(title: "Presets")
        presetSegmentedControl = UISegmentedControl(items: ["Precise", "Sketchy", "Natural", "Ink"])
        presetSegmentedControl.addTarget(self, action: #selector(presetChanged), for: .valueChanged)
        presetSection.addArrangedSubview(presetSegmentedControl)
        contentStack.addArrangedSubview(presetSection)

        // Stabilization
        let stabilizationSection = createSection(title: "Stabilization")
        stabilizationSlider = AdvancedSlider(
            title: "Amount",
            minValue: 0,
            maxValue: 100,
            currentValue: currentConfig.stabilization,
            unit: "",
            showValue: true
        )
        stabilizationSlider.valueChanged = { [weak self] value in
            self?.currentConfig.stabilization = value
        }
        stabilizationSection.addArrangedSubview(stabilizationSlider)
        stabilizationSection.addArrangedSubview(createHelpLabel("Smooths hand tremors. Higher = smoother, slight lag."))
        contentStack.addArrangedSubview(stabilizationSection)

        // Prediction
        let predictionSection = createSection(title: "Prediction")
        predictionSlider = AdvancedSlider(
            title: "Amount",
            minValue: 0,
            maxValue: 100,
            currentValue: currentConfig.prediction,
            unit: "",
            showValue: true
        )
        predictionSlider.valueChanged = { [weak self] value in
            self?.currentConfig.prediction = value
        }
        predictionSection.addArrangedSubview(predictionSlider)
        predictionSection.addArrangedSubview(createHelpLabel("Predicts stroke path. Reduces perceived lag."))
        contentStack.addArrangedSubview(predictionSection)

        // Pressure Curve
        let pressureSection = createSection(title: "Pressure Curve")
        pressureCurveControl = UISegmentedControl(items: ["Linear", "Ease In", "Ease Out", "Ease In-Out"])
        pressureCurveControl.addTarget(self, action: #selector(pressureCurveChanged), for: .valueChanged)
        pressureSection.addArrangedSubview(pressureCurveControl)

        // Edit Curve button
        let editCurveButton = UIButton(type: .system)
        editCurveButton.setTitle("✎ Edit Curve", for: .normal)
        editCurveButton.titleLabel?.font = DesignTokens.Typography.systemFont(size: 14, weight: .medium)
        editCurveButton.setTitleColor(DesignTokens.Colors.inkPrimary, for: .normal)
        editCurveButton.backgroundColor = DesignTokens.Colors.surface
        editCurveButton.layer.cornerRadius = 8
        editCurveButton.layer.borderWidth = 1
        editCurveButton.layer.borderColor = DesignTokens.Colors.inkPrimary.withAlphaComponent(0.3).cgColor
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            editCurveButton.configuration = config
        } else {
            editCurveButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        }
        editCurveButton.addTarget(self, action: #selector(editCurveButtonTapped), for: .touchUpInside)
        pressureSection.addArrangedSubview(editCurveButton)

        pressureSection.addArrangedSubview(createHelpLabel("How pressure input is mapped to output."))
        contentStack.addArrangedSubview(pressureSection)

        // Velocity Dynamics
        let velocitySection = createSection(title: "Velocity Dynamics")
        let velocityToggle = createToggleRow(title: "Enable", isOn: currentConfig.velocityDynamics.enabled) { [weak self] isOn in
            self?.currentConfig.velocityDynamics.enabled = isOn
            self?.velocitySettingsStack.isHidden = !isOn
        }
        velocityDynamicsSwitch = velocityToggle.arrangedSubviews.last as? UISwitch
        velocitySection.addArrangedSubview(velocityToggle)

        velocitySettingsStack = UIStackView()
        velocitySettingsStack.axis = .vertical
        velocitySettingsStack.spacing = 12
        velocitySettingsStack.isHidden = !currentConfig.velocityDynamics.enabled
        velocitySection.addArrangedSubview(velocitySettingsStack)

        velocitySection.addArrangedSubview(createHelpLabel("Adjust size/opacity based on stroke speed."))
        contentStack.addArrangedSubview(velocitySection)

        // Jitter
        let jitterSection = createSection(title: "Jitter (Randomness)")
        let jitterToggle = createToggleRow(title: "Enable", isOn: currentConfig.jitter.enabled) { [weak self] isOn in
            self?.currentConfig.jitter.enabled = isOn
            self?.jitterSettingsStack.isHidden = !isOn
        }
        jitterSwitch = jitterToggle.arrangedSubviews.last as? UISwitch
        jitterSection.addArrangedSubview(jitterToggle)

        jitterSettingsStack = UIStackView()
        jitterSettingsStack.axis = .vertical
        jitterSettingsStack.spacing = 12
        jitterSettingsStack.isHidden = !currentConfig.jitter.enabled

        let sizeJitterSlider = AdvancedSlider(
            title: "Size Jitter",
            minValue: 0,
            maxValue: 1.0,
            currentValue: currentConfig.jitter.sizeJitter,
            unit: "",
            decimalPlaces: 2,
            showValue: true
        )
        sizeJitterSlider.valueChanged = { [weak self] value in
            self?.currentConfig.jitter.sizeJitter = value
        }
        jitterSettingsStack.addArrangedSubview(sizeJitterSlider)

        let rotationJitterSlider = AdvancedSlider(
            title: "Rotation Jitter",
            minValue: 0,
            maxValue: 180,
            currentValue: currentConfig.jitter.rotationJitter,
            unit: "°",
            showValue: true
        )
        rotationJitterSlider.valueChanged = { [weak self] value in
            self?.currentConfig.jitter.rotationJitter = value
        }
        jitterSettingsStack.addArrangedSubview(rotationJitterSlider)

        let opacityJitterSlider = AdvancedSlider(
            title: "Opacity Jitter",
            minValue: 0,
            maxValue: 1.0,
            currentValue: currentConfig.jitter.opacityJitter,
            unit: "",
            decimalPlaces: 2,
            showValue: true
        )
        opacityJitterSlider.valueChanged = { [weak self] value in
            self?.currentConfig.jitter.opacityJitter = value
        }
        jitterSettingsStack.addArrangedSubview(opacityJitterSlider)

        jitterSection.addArrangedSubview(jitterSettingsStack)
        jitterSection.addArrangedSubview(createHelpLabel("Adds controlled randomness for organic strokes."))
        contentStack.addArrangedSubview(jitterSection)

        // Flow
        let flowSection = createSection(title: "Flow")
        flowSlider = AdvancedSlider(
            title: "Amount",
            minValue: 0.1,
            maxValue: 1.0,
            currentValue: currentConfig.flow,
            unit: "",
            decimalPlaces: 2,
            showValue: true
        )
        flowSlider.valueChanged = { [weak self] value in
            self?.currentConfig.flow = value
        }
        flowSection.addArrangedSubview(flowSlider)
        flowSection.addArrangedSubview(createHelpLabel("Controls opacity build-up. Lower = more layering."))
        contentStack.addArrangedSubview(flowSection)
    }

    // MARK: - Helper Methods

    private func createSection(title: String) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fill

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = DesignTokens.Typography.systemFont(
            size: 16,
            weight: DesignTokens.Typography.semibold
        )
        titleLabel.textColor = DesignTokens.Colors.textPrimary

        let separator = UIView()
        separator.backgroundColor = DesignTokens.Colors.divider
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(separator)

        return stack
    }

    private func createToggleRow(title: String, isOn: Bool, valueChanged: @escaping (Bool) -> Void) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .fill

        let label = UILabel()
        label.text = title
        label.font = DesignTokens.Typography.systemFont(
            size: 15,
            weight: DesignTokens.Typography.regular
        )
        label.textColor = DesignTokens.Colors.textPrimary

        let toggle = UISwitch()
        toggle.isOn = isOn
        toggle.onTintColor = DesignTokens.Colors.inkPrimary
        toggle.addAction(UIAction { _ in
            valueChanged(toggle.isOn)
        }, for: .valueChanged)

        stack.addArrangedSubview(label)
        stack.addArrangedSubview(toggle)

        return stack
    }

    private func createHelpLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = DesignTokens.Typography.systemFont(
            size: 12,
            weight: DesignTokens.Typography.regular
        )
        label.textColor = DesignTokens.Colors.textSecondary
        label.numberOfLines = 0
        return label
    }

    private func updateUIFromConfig() {
        // Update preset (guess based on settings)
        if currentConfig.stabilization == 60 && currentConfig.prediction == 30 {
            presetSegmentedControl.selectedSegmentIndex = 0 // Precise
        } else if currentConfig.stabilization == 10 && currentConfig.prediction == 70 {
            presetSegmentedControl.selectedSegmentIndex = 1 // Sketchy
        } else if currentConfig.stabilization == 30 && currentConfig.prediction == 50 {
            presetSegmentedControl.selectedSegmentIndex = 2 // Natural
        } else if currentConfig.stabilization == 80 && currentConfig.prediction == 20 {
            presetSegmentedControl.selectedSegmentIndex = 3 // Ink
        } else {
            presetSegmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
        }

        // Update pressure curve
        switch currentConfig.pressureCurve.curveType {
        case .linear: pressureCurveControl.selectedSegmentIndex = 0
        case .easeIn: pressureCurveControl.selectedSegmentIndex = 1
        case .easeOut: pressureCurveControl.selectedSegmentIndex = 2
        case .easeInOut: pressureCurveControl.selectedSegmentIndex = 3
        case .custom: pressureCurveControl.selectedSegmentIndex = UISegmentedControl.noSegment
        }

        // Update switches
        velocityDynamicsSwitch.isOn = currentConfig.velocityDynamics.enabled
        velocitySettingsStack.isHidden = !currentConfig.velocityDynamics.enabled

        jitterSwitch.isOn = currentConfig.jitter.enabled
        jitterSettingsStack.isHidden = !currentConfig.jitter.enabled
    }

    // MARK: - Actions

    @objc private func presetChanged() {
        let index = presetSegmentedControl.selectedSegmentIndex
        guard index != UISegmentedControl.noSegment else { return }

        let brush = currentConfig.patternBrush
        switch index {
        case 0: currentConfig = .precise
        case 1: currentConfig = .sketchy
        case 2: currentConfig = .natural
        case 3: currentConfig = .ink
        default: break
        }
        currentConfig.patternBrush = brush

        updateUIFromConfig()

        // Update all sliders
        stabilizationSlider.setValue(currentConfig.stabilization)
        predictionSlider.setValue(currentConfig.prediction)
        flowSlider.setValue(currentConfig.flow)
    }

    @objc private func pressureCurveChanged() {
        let index = pressureCurveControl.selectedSegmentIndex
        switch index {
        case 0: currentConfig.pressureCurve.curveType = .linear
        case 1: currentConfig.pressureCurve.curveType = .easeIn
        case 2: currentConfig.pressureCurve.curveType = .easeOut
        case 3: currentConfig.pressureCurve.curveType = .easeInOut
        default: break
        }
    }

    @objc private func editCurveButtonTapped() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Show pressure curve editor
        let editor = PressureCurveEditorView()
        editor.delegate = self
        editor.configure(with: currentConfig.pressureCurve.curveType)

        if let parentView = superview {
            editor.present(in: parentView)
        }

        print("✎ Opening pressure curve editor")
    }

    @objc private func applyButtonTapped() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        delegate?.advancedBrushSettingsPanel(self, didUpdateConfiguration: currentConfig)
        dismiss()
    }

    @objc private func cancelButtonTapped() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        delegate?.advancedBrushSettingsPanelDidCancel(self)
        dismiss()
    }

    @objc private func dimViewTapped() {
        cancelButtonTapped()
    }

    // MARK: - Presentation

    func present(in view: UIView) {
        frame = view.bounds
        view.addSubview(self)

        containerView.transform = CGAffineTransform(translationX: 0, y: 700)
        dimView.alpha = 0

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
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                self.containerView.transform = CGAffineTransform(translationX: 0, y: 700)
                self.dimView.alpha = 0
            },
            completion: { _ in
                self.removeFromSuperview()
            }
        )
    }
}

// MARK: - PressureCurveEditorDelegate

extension AdvancedBrushSettingsPanel: PressureCurveEditorDelegate {
    func pressureCurveEditor(_ editor: PressureCurveEditorView, didUpdateCurve curveType: BrushConfiguration.PressureCurve.CurveType) {
        // Update configuration with new curve type
        currentConfig.pressureCurve.curveType = curveType

        // Update segmented control if it's a preset
        switch curveType {
        case .linear:
            pressureCurveControl.selectedSegmentIndex = 0
        case .easeIn:
            pressureCurveControl.selectedSegmentIndex = 1
        case .easeOut:
            pressureCurveControl.selectedSegmentIndex = 2
        case .easeInOut:
            pressureCurveControl.selectedSegmentIndex = 3
        case .custom:
            // Custom curve - deselect all presets
            pressureCurveControl.selectedSegmentIndex = UISegmentedControl.noSegment
        }

        // Dismiss editor
        editor.dismiss()

        print("✓ Updated pressure curve to: \(curveType)")
    }

    func pressureCurveEditorDidCancel(_ editor: PressureCurveEditorView) {
        editor.dismiss()
        print("❌ Pressure curve editor cancelled")
    }
}

// MARK: - AdvancedSlider

class AdvancedSlider: UIView {

    var valueChanged: ((Float) -> Void)?

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
            size: 13,
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

    private let minValue: Float
    private let maxValue: Float
    private let unit: String
    private let decimalPlaces: Int
    private let showValue: Bool

    init(title: String, minValue: Float, maxValue: Float, currentValue: Float, unit: String = "", decimalPlaces: Int = 0, showValue: Bool = false) {
        self.minValue = minValue
        self.maxValue = maxValue
        self.unit = unit
        self.decimalPlaces = decimalPlaces
        self.showValue = showValue

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

    private func setupViews() {
        addSubview(titleLabel)
        if showValue {
            addSubview(valueLabel)
        }
        addSubview(slider)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        slider.translatesAutoresizingMaskIntoConstraints = false

        if showValue {
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: topAnchor),
                titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),

                valueLabel.topAnchor.constraint(equalTo: topAnchor),
                valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
                valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),

                slider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
                slider.leadingAnchor.constraint(equalTo: leadingAnchor),
                slider.trailingAnchor.constraint(equalTo: trailingAnchor),
                slider.bottomAnchor.constraint(equalTo: bottomAnchor),

                heightAnchor.constraint(equalToConstant: 48)
            ])
        } else {
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: topAnchor),
                titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),

                slider.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
                slider.leadingAnchor.constraint(equalTo: leadingAnchor),
                slider.trailingAnchor.constraint(equalTo: trailingAnchor),
                slider.bottomAnchor.constraint(equalTo: bottomAnchor),

                heightAnchor.constraint(equalToConstant: 48)
            ])
        }

        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
    }

    @objc private func sliderValueChanged() {
        updateValueLabel()
        valueChanged?(slider.value)
    }

    private func updateValueLabel() {
        guard showValue else { return }

        if decimalPlaces > 0 {
            valueLabel.text = String(format: "%.\(decimalPlaces)f%@", slider.value, unit)
        } else {
            valueLabel.text = "\(Int(slider.value))\(unit)"
        }
    }

    func setValue(_ value: Float) {
        slider.value = value
        updateValueLabel()
    }
}
