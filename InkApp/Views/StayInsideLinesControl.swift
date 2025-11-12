//
//  StayInsideLinesControl.swift
//  Ink - Pattern Drawing App
//
//  Toggle control for Stay Inside Lines mode
//  Created on November 11, 2025.
//

import UIKit

protocol StayInsideLinesControlDelegate: AnyObject {
    func stayInsideLinesControl(_ control: StayInsideLinesControl, didToggle enabled: Bool)
}

class StayInsideLinesControl: UIView {

    // MARK: - Properties

    weak var delegate: StayInsideLinesControlDelegate?

    private(set) var isEnabled: Bool = false {
        didSet {
            updateAppearance()
        }
    }

    // UI Elements
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.95)
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        return view
    }()

    private let iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20)
        label.textAlignment = .center
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Stay Inside Lines"
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = DesignTokens.Colors.textPrimary
        return label
    }()

    private let toggleSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = DesignTokens.Colors.inkPrimary
        return toggle
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        updateAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        addSubview(containerView)
        containerView.addSubview(iconLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(toggleSwitch)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Container fills the view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Icon on left
            iconLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            iconLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 24),

            // Title next to icon
            titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            // Toggle on right
            toggleSwitch.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            toggleSwitch.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            // Container height
            containerView.heightAnchor.constraint(equalToConstant: 50)
        ])

        // Add target for toggle
        toggleSwitch.addTarget(self, action: #selector(toggleSwitchChanged), for: .valueChanged)
    }

    // MARK: - Actions

    @objc private func toggleSwitchChanged() {
        isEnabled = toggleSwitch.isOn

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        // Notify delegate
        delegate?.stayInsideLinesControl(self, didToggle: isEnabled)
    }

    // MARK: - Public Methods

    func setEnabled(_ enabled: Bool, animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.toggleSwitch.setOn(enabled, animated: true)
                self.isEnabled = enabled
            }
        } else {
            toggleSwitch.setOn(enabled, animated: false)
            isEnabled = enabled
        }
    }

    // MARK: - Appearance

    private func updateAppearance() {
        iconLabel.text = isEnabled ? "🔒" : "🔓"

        if isEnabled {
            containerView.layer.borderWidth = 2
            containerView.layer.borderColor = DesignTokens.Colors.inkPrimary.cgColor
        } else {
            containerView.layer.borderWidth = 1
            containerView.layer.borderColor = UIColor.systemGray4.cgColor
        }
    }
}
