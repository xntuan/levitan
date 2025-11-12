//
//  BrushLibraryView.swift
//  Ink - Pattern Drawing App
//
//  Brush presets library UI
//  Created on November 10, 2025.
//

import UIKit

protocol BrushLibraryViewDelegate: AnyObject {
    func brushLibrary(_ library: BrushLibraryView, didSelectPreset preset: BrushPreset)
    func brushLibraryDidRequestSavePreset(_ library: BrushLibraryView, currentConfiguration: BrushConfiguration)
    func brushLibraryDidCancel(_ library: BrushLibraryView)
}

class BrushLibraryView: UIView {

    // MARK: - Properties

    weak var delegate: BrushLibraryViewDelegate?

    private var currentConfiguration: BrushConfiguration?
    private var allPresets: [BrushPreset] = []

    // UI Elements
    private var containerView: UIView!
    private var titleLabel: UILabel!
    private var scrollView: UIScrollView!
    private var contentStack: UIStackView!
    private var saveButton: UIButton!
    private var closeButton: UIButton!

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        loadPresets()
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
        titleLabel.text = "Brush Library"
        titleLabel.font = DesignTokens.Typography.systemFont(size: 20, weight: .semibold)
        titleLabel.textColor = DesignTokens.Colors.textPrimary
        titleLabel.textAlignment = .center

        containerView.addSubview(titleLabel)

        // Close button
        closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = DesignTokens.Colors.textSecondary
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        containerView.addSubview(closeButton)

        // Scroll view for presets
        scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true

        containerView.addSubview(scrollView)

        // Content stack
        contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.distribution = .fill

        scrollView.addSubview(contentStack)

        // Save button
        saveButton = UIButton(type: .system)
        saveButton.setTitle("💾 Save Current", for: .normal)
        saveButton.titleLabel?.font = DesignTokens.Typography.systemFont(size: 16, weight: .semibold)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = DesignTokens.Colors.inkPrimary
        saveButton.layer.cornerRadius = 12
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)

        containerView.addSubview(saveButton)

        // Layout
        setupConstraints()
    }

    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Container view (centered, large)
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 500),
            containerView.heightAnchor.constraint(equalToConstant: 600),

            // Title
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            // Close button
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            // Scroll view
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -16),

            // Content stack
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Save button
            saveButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            saveButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Public Methods

    func configure(with currentConfiguration: BrushConfiguration) {
        self.currentConfiguration = currentConfiguration
        loadPresets()
    }

    private func loadPresets() {
        // Clear existing
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        allPresets = BrushPresetsLibrary.shared.getAllPresets()

        // Built-in section
        let builtInHeader = createSectionHeader(title: "Built-in Presets")
        contentStack.addArrangedSubview(builtInHeader)

        let builtInPresets = BrushPresetsLibrary.shared.builtInPresets()
        let builtInGrid = createPresetGrid(presets: builtInPresets)
        contentStack.addArrangedSubview(builtInGrid)

        // Custom section
        let customPresets = BrushPresetsLibrary.shared.getCustomPresets()
        if !customPresets.isEmpty {
            let customHeader = createSectionHeader(title: "My Presets")
            contentStack.addArrangedSubview(customHeader)

            let customGrid = createPresetGrid(presets: customPresets)
            contentStack.addArrangedSubview(customGrid)
        }
    }

    private func createSectionHeader(title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = DesignTokens.Typography.systemFont(size: 16, weight: .semibold)
        label.textColor = DesignTokens.Colors.textPrimary
        return label
    }

    private func createPresetGrid(presets: [BrushPreset]) -> UIView {
        let gridView = UIView()

        let columns = 5
        let cellSize: CGFloat = 80
        let spacing: CGFloat = 12

        for (index, preset) in presets.enumerated() {
            let row = index / columns
            let col = index % columns

            let cell = BrushPresetCell()
            cell.configure(with: preset)
            cell.onTap = { [weak self] in
                self?.presetSelected(preset)
            }
            cell.onLongPress = { [weak self] in
                self?.showPresetOptions(for: preset)
            }

            gridView.addSubview(cell)

            cell.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                cell.leadingAnchor.constraint(equalTo: gridView.leadingAnchor, constant: CGFloat(col) * (cellSize + spacing)),
                cell.topAnchor.constraint(equalTo: gridView.topAnchor, constant: CGFloat(row) * (cellSize + spacing)),
                cell.widthAnchor.constraint(equalToConstant: cellSize),
                cell.heightAnchor.constraint(equalToConstant: cellSize)
            ])
        }

        // Calculate grid height
        let rows = (presets.count + columns - 1) / columns
        let height = CGFloat(rows) * (cellSize + spacing)

        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.heightAnchor.constraint(equalToConstant: height).isActive = true

        return gridView
    }

    private func presetSelected(_ preset: BrushPreset) {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        delegate?.brushLibrary(self, didSelectPreset: preset)
    }

    private func showPresetOptions(for preset: BrushPreset) {
        guard !preset.isBuiltIn else { return }

        let alert = UIAlertController(title: preset.name, message: nil, preferredStyle: .actionSheet)

        // Rename
        alert.addAction(UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            self?.showRenameDialog(for: preset)
        })

        // Export
        alert.addAction(UIAlertAction(title: "Export", style: .default) { [weak self] _ in
            self?.exportPreset(preset)
        })

        // Delete
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deletePreset(preset)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let viewController = findViewController() {
            viewController.present(alert, animated: true)
        }
    }

    private func showRenameDialog(for preset: BrushPreset) {
        let alert = UIAlertController(title: "Rename Preset", message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.text = preset.name
            textField.placeholder = "Preset name"
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            guard let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }

            var updatedPreset = preset
            updatedPreset.name = newName
            BrushPresetsLibrary.shared.updateCustomPreset(updatedPreset)
            self?.loadPresets()
        })

        if let viewController = findViewController() {
            viewController.present(alert, animated: true)
        }
    }

    private func exportPreset(_ preset: BrushPreset) {
        guard let fileURL = BrushPresetsLibrary.shared.exportPresetToFile(preset) else {
            print("❌ Failed to export preset")
            return
        }

        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

        if let viewController = findViewController() {
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = viewController.view
                popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            }
            viewController.present(activityVC, animated: true)
        }
    }

    private func deletePreset(_ preset: BrushPreset) {
        BrushPresetsLibrary.shared.deleteCustomPreset(preset)
        loadPresets()
    }

    // MARK: - Actions

    @objc private func saveButtonTapped() {
        guard let config = currentConfiguration else { return }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        delegate?.brushLibraryDidRequestSavePreset(self, currentConfiguration: config)
    }

    @objc private func closeButtonTapped() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        delegate?.brushLibraryDidCancel(self)
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

    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            responder = responder?.next
            if let viewController = responder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

// MARK: - BrushPresetCell

class BrushPresetCell: UIView {

    var onTap: (() -> Void)?
    var onLongPress: (() -> Void)?

    private var iconLabel: UILabel!
    private var nameLabel: UILabel!
    private var preset: BrushPreset?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = DesignTokens.Colors.surface
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray5.cgColor

        // Icon
        iconLabel = UILabel()
        iconLabel.font = UIFont.systemFont(ofSize: 32)
        iconLabel.textAlignment = .center

        addSubview(iconLabel)

        // Name
        nameLabel = UILabel()
        nameLabel.font = DesignTokens.Typography.systemFont(size: 11, weight: .medium)
        nameLabel.textColor = DesignTokens.Colors.textPrimary
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2

        addSubview(nameLabel)

        // Layout
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -8),

            nameLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4)
        ])
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        addGestureRecognizer(longPressGesture)
    }

    func configure(with preset: BrushPreset) {
        self.preset = preset
        iconLabel.text = preset.icon
        nameLabel.text = preset.name

        // Built-in presets have subtle border
        if preset.isBuiltIn {
            layer.borderColor = UIColor.systemGray5.cgColor
        } else {
            layer.borderColor = DesignTokens.Colors.inkPrimary.withAlphaComponent(0.3).cgColor
        }
    }

    @objc private func handleTap() {
        // Animate
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }

        onTap?()
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        onLongPress?()
    }
}
