//
//  LayerSelectorView.swift
//  Ink - Pattern Drawing App
//
//  Floating panel for layer selection and management
//  Created on November 10, 2025.
//

import UIKit

protocol LayerSelectorDelegate: AnyObject {
    func layerSelector(_ selector: LayerSelectorView, didSelectLayer layer: Layer)
    func layerSelector(_ selector: LayerSelectorView, didToggleVisibilityFor layer: Layer)
    func layerSelectorDidRequestAddLayer(_ selector: LayerSelectorView)
    func layerSelector(_ selector: LayerSelectorView, didRequestDeleteLayer layer: Layer)
    func layerSelector(_ selector: LayerSelectorView, didRequestRenameLayer layer: Layer)
    func layerSelector(_ selector: LayerSelectorView, didRequestToggleLockFor layer: Layer)
    func layerSelector(_ selector: LayerSelectorView, didChangeBlendMode blendMode: Layer.BlendMode, for layer: Layer)
    func layerSelector(_ selector: LayerSelectorView, didChangeOpacity opacity: Float, for layer: Layer)
    func layerSelector(_ selector: LayerSelectorView, didReorderLayer layer: Layer, fromIndex: Int, toIndex: Int)
}

class LayerSelectorView: UIView {

    // MARK: - Properties

    weak var delegate: LayerSelectorDelegate?

    private var layers: [Layer] = []
    private var selectedLayerId: UUID?

    // UI Elements
    private var scrollView: UIScrollView!
    private var stackView: UIStackView!
    private var addButton: UIButton!
    private var layerCards: [UUID: LayerCardView] = [:]

    // Drag & Drop state
    private var isDragging = false
    private var draggingCard: LayerCardView?
    private var draggingLayer: Layer?
    private var draggingStartIndex: Int = 0
    private var draggingCurrentIndex: Int = 0
    private var dragOffset: CGPoint = .zero
    private var placeholderView: UIView?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        // Scroll view for horizontal scrolling
        scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        addSubview(scrollView)

        // Stack view for layer cards
        stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center
        stackView.distribution = .equalSpacing

        scrollView.addSubview(stackView)

        // Layout
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            stackView.heightAnchor.constraint(equalToConstant: 64)
        ])

        // Add layer button (always at the end)
        createAddButton()
    }

    private func setupAppearance() {
        // Lake aesthetic floating panel
        backgroundColor = UIColor.white.withAlphaComponent(0.95)
        layer.cornerRadius = 20
        layer.masksToBounds = false

        // Shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowOffset = CGSize(width: 0, height: 12)
        layer.shadowRadius = 20

        // Blur effect
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.layer.cornerRadius = 20
        blurView.clipsToBounds = true
        insertSubview(blurView, at: 0)
    }

    private func createAddButton() {
        addButton = UIButton(type: .system)
        addButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addButton.tintColor = DesignTokens.Colors.inkPrimary
        addButton.contentVerticalAlignment = .fill
        addButton.contentHorizontalAlignment = .fill
        addButton.imageView?.contentMode = .scaleAspectFit

        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)

        stackView.addArrangedSubview(addButton)

        addButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            addButton.widthAnchor.constraint(equalToConstant: 40),
            addButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    // MARK: - Public Methods

    func configure(with layers: [Layer], selectedLayerId: UUID?) {
        self.layers = layers
        self.selectedLayerId = selectedLayerId

        // Clear existing layer cards
        layerCards.values.forEach { $0.removeFromSuperview() }
        layerCards.removeAll()

        // Create card for each layer
        for layer in layers {
            let card = LayerCardView()
            card.configure(with: layer, isSelected: layer.id == selectedLayerId)
            card.delegate = self

            // Insert before add button
            let index = stackView.arrangedSubviews.count - 1
            stackView.insertArrangedSubview(card, at: index)

            layerCards[layer.id] = card
        }
    }

    func updateLayer(_ layer: Layer) {
        guard let card = layerCards[layer.id] else { return }
        card.configure(with: layer, isSelected: layer.id == selectedLayerId)
    }

    func updateSelection(_ layerId: UUID) {
        selectedLayerId = layerId

        // Update all cards
        for (id, card) in layerCards {
            card.updateSelection(isSelected: id == layerId)
        }
    }

    func updateThumbnail(for layerId: UUID, image: UIImage?) {
        guard let card = layerCards[layerId] else { return }
        card.updateThumbnail(image)
    }

    // MARK: - Actions

    @objc private func addButtonTapped() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        // Animate button
        UIView.animate(
            withDuration: DesignTokens.Animation.durationFast,
            animations: {
                self.addButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            },
            completion: { _ in
                UIView.animate(withDuration: DesignTokens.Animation.durationFast) {
                    self.addButton.transform = .identity
                }
            }
        )

        delegate?.layerSelectorDidRequestAddLayer(self)
    }
}

// MARK: - LayerCardDelegate

extension LayerSelectorView: LayerCardDelegate {
    func layerCard(_ card: LayerCardView, didSelectLayer layer: Layer) {
        updateSelection(layer.id)
        delegate?.layerSelector(self, didSelectLayer: layer)

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    func layerCard(_ card: LayerCardView, didToggleVisibilityFor layer: Layer) {
        delegate?.layerSelector(self, didToggleVisibilityFor: layer)

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    func layerCard(_ card: LayerCardView, didLongPressLayer layer: Layer) {
        // Only show context menu if not dragging
        if !isDragging {
            showContextMenu(for: layer, from: card)
        }
    }

    private func showContextMenu(for layer: Layer, from sourceView: UIView) {
        guard let viewController = findViewController() else { return }

        let alert = UIAlertController(title: layer.name, message: nil, preferredStyle: .actionSheet)

        // Opacity
        let opacityPercent = Int(layer.opacity * 100)
        alert.addAction(UIAlertAction(title: "Opacity: \(opacityPercent)%", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.showOpacitySlider(for: layer, from: sourceView)
        })

        // Blend Mode
        let currentBlendMode = layer.blendMode.displayName
        alert.addAction(UIAlertAction(title: "Blend Mode: \(currentBlendMode)", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.showBlendModeMenu(for: layer, from: sourceView)
        })

        // Lock/Unlock
        let lockTitle = layer.isLocked ? "Unlock Layer" : "Lock Layer"
        let lockIcon = layer.isLocked ? "lock.open" : "lock"
        alert.addAction(UIAlertAction(title: lockTitle, style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.layerSelector(self, didRequestToggleLockFor: layer)
        })

        // Rename
        alert.addAction(UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.layerSelector(self, didRequestRenameLayer: layer)
        })

        // Delete
        if layers.count > 1 {  // Don't allow deleting last layer
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.layerSelector(self, didRequestDeleteLayer: layer)
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // For iPad, set source view
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }

        viewController.present(alert, animated: true)
    }

    private func showOpacitySlider(for layer: Layer, from sourceView: UIView) {
        guard let viewController = findViewController() else { return }

        let alert = UIAlertController(title: "Layer Opacity", message: nil, preferredStyle: .alert)

        // Add slider
        let sliderHeight: CGFloat = 50
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.value = layer.opacity * 100
        slider.translatesAutoresizingMaskIntoConstraints = false

        // Add label
        let label = UILabel()
        label.text = "\(Int(slider.value))%"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false

        // Container view
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(label)
        containerView.addSubview(slider)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: containerView.topAnchor),
            label.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            slider.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            slider.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            slider.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            slider.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            containerView.heightAnchor.constraint(equalToConstant: 80)
        ])

        // Update label on slider change
        slider.addTarget(self, action: #selector(opacitySliderChanged(_:)), for: .valueChanged)

        // Store layer reference for slider action
        slider.accessibilityIdentifier = layer.id.uuidString
        slider.accessibilityLabel = String(format: "%.0f", slider.value)

        alert.view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 50),
            containerView.leadingAnchor.constraint(equalTo: alert.view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: alert.view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -70)
        ])

        // Actions
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Apply", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let opacity = slider.value / 100.0
            self.delegate?.layerSelector(self, didChangeOpacity: opacity, for: layer)
        })

        viewController.present(alert, animated: true)
    }

    @objc private func opacitySliderChanged(_ slider: UISlider) {
        // Find label and update
        if let containerView = slider.superview,
           let label = containerView.subviews.first(where: { $0 is UILabel }) as? UILabel {
            label.text = "\(Int(slider.value))%"
        }
    }

    private func showBlendModeMenu(for layer: Layer, from sourceView: UIView) {
        guard let viewController = findViewController() else { return }

        let alert = UIAlertController(title: "Select Blend Mode", message: nil, preferredStyle: .actionSheet)

        // All 7 blend modes
        let allBlendModes: [Layer.BlendMode] = [
            .normal, .multiply, .screen, .overlay, .add, .darken, .lighten
        ]

        for blendMode in allBlendModes {
            let isCurrentMode = blendMode == layer.blendMode
            let title = isCurrentMode ? "✓ \(blendMode.displayName)" : blendMode.displayName

            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.layerSelector(self, didChangeBlendMode: blendMode, for: layer)
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // For iPad, set source view
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }

        viewController.present(alert, animated: true)
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

    // MARK: - Drag & Drop

    func layerCard(_ card: LayerCardView, didStartDraggingLayer layer: Layer, gesture: UILongPressGestureRecognizer) {
        guard let cardIndex = stackView.arrangedSubviews.firstIndex(of: card) else { return }

        isDragging = true
        draggingCard = card
        draggingLayer = layer
        draggingStartIndex = cardIndex
        draggingCurrentIndex = cardIndex

        // Visual feedback - lift card
        UIView.animate(withDuration: 0.2) {
            card.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            card.alpha = 0.9
            card.layer.shadowColor = UIColor.black.cgColor
            card.layer.shadowOpacity = 0.3
            card.layer.shadowOffset = CGSize(width: 0, height: 8)
            card.layer.shadowRadius = 16
        }

        // Create placeholder
        createPlaceholder(at: cardIndex)
    }

    func layerCard(_ card: LayerCardView, didDragLayer layer: Layer, gesture: UIPanGestureRecognizer) {
        guard isDragging, card == draggingCard else { return }

        let translation = gesture.translation(in: scrollView)

        switch gesture.state {
        case .changed:
            // Move card with finger
            card.center = CGPoint(
                x: card.center.x + translation.x,
                y: card.center.y + translation.y
            )
            gesture.setTranslation(.zero, in: scrollView)

            // Check if we need to reorder
            updateDragPosition(for: card)

        case .ended, .cancelled:
            // End dragging
            endDragging(card: card)

        default:
            break
        }
    }

    private func createPlaceholder(at index: Int) {
        // Remove existing placeholder
        placeholderView?.removeFromSuperview()

        // Create new placeholder with same size as card
        let placeholder = UIView()
        placeholder.backgroundColor = DesignTokens.Colors.inkPrimary.withAlphaComponent(0.2)
        placeholder.layer.cornerRadius = 12
        placeholder.layer.borderWidth = 2
        placeholder.layer.borderColor = DesignTokens.Colors.inkPrimary.withAlphaComponent(0.5).cgColor

        placeholder.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            placeholder.widthAnchor.constraint(equalToConstant: 80),
            placeholder.heightAnchor.constraint(equalToConstant: 64)
        ])

        placeholderView = placeholder
        stackView.insertArrangedSubview(placeholder, at: index)
    }

    private func updateDragPosition(for card: LayerCardView) {
        guard let cardIndex = stackView.arrangedSubviews.firstIndex(of: card) else { return }

        // Find which position the card is over
        let cardCenterX = card.center.x
        var newIndex = cardIndex

        for (index, view) in stackView.arrangedSubviews.enumerated() {
            guard view != card, view != placeholderView, view != addButton else { continue }

            let viewFrame = view.convert(view.bounds, to: scrollView)
            if cardCenterX > viewFrame.minX && cardCenterX < viewFrame.maxX {
                newIndex = index
                break
            }
        }

        // Update placeholder position if changed
        if newIndex != draggingCurrentIndex {
            draggingCurrentIndex = newIndex

            // Animate placeholder move
            UIView.animate(withDuration: 0.3) {
                if let placeholder = self.placeholderView {
                    self.stackView.removeArrangedSubview(placeholder)
                    self.stackView.insertArrangedSubview(placeholder, at: newIndex)
                    self.stackView.layoutIfNeeded()
                }
            }
        }
    }

    private func endDragging(card: LayerCardView) {
        guard isDragging, let layer = draggingLayer else { return }

        // Calculate final index (accounting for placeholder)
        let finalIndex = draggingCurrentIndex
        let originalIndex = draggingStartIndex

        // Animate card back to position
        UIView.animate(withDuration: 0.3, animations: {
            // Move card to placeholder position
            if let placeholder = self.placeholderView {
                let targetFrame = placeholder.convert(placeholder.bounds, to: self.scrollView)
                card.center = CGPoint(
                    x: targetFrame.midX,
                    y: targetFrame.midY
                )
            }

            // Reset visual effects
            card.transform = .identity
            card.alpha = 1.0
            card.layer.shadowOpacity = 0

        }) { _ in
            // Remove placeholder
            self.placeholderView?.removeFromSuperview()
            self.placeholderView = nil

            // Reinsert card at correct position
            self.stackView.removeArrangedSubview(card)
            self.stackView.insertArrangedSubview(card, at: finalIndex)
            self.stackView.layoutIfNeeded()

            // Notify delegate if position changed
            if finalIndex != originalIndex {
                self.delegate?.layerSelector(self, didReorderLayer: layer, fromIndex: originalIndex, toIndex: finalIndex)
            }

            // Reset drag state
            self.isDragging = false
            self.draggingCard = nil
            self.draggingLayer = nil
        }
    }
}

// MARK: - LayerCardView

protocol LayerCardDelegate: AnyObject {
    func layerCard(_ card: LayerCardView, didSelectLayer layer: Layer)
    func layerCard(_ card: LayerCardView, didToggleVisibilityFor layer: Layer)
    func layerCard(_ card: LayerCardView, didLongPressLayer layer: Layer)
    func layerCard(_ card: LayerCardView, didStartDraggingLayer layer: Layer, gesture: UILongPressGestureRecognizer)
    func layerCard(_ card: LayerCardView, didDragLayer layer: Layer, gesture: UIPanGestureRecognizer)
}

class LayerCardView: UIView {

    // MARK: - Properties

    weak var delegate: LayerCardDelegate?
    private var layer: Layer?

    // UI Elements
    private let thumbnailView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = DesignTokens.Colors.surface
        iv.layer.cornerRadius = 8
        iv.layer.borderWidth = 1
        iv.layer.borderColor = UIColor.systemGray5.cgColor
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = DesignTokens.Typography.systemFont(
            size: 11,
            weight: DesignTokens.Typography.regular
        )
        label.textColor = DesignTokens.Colors.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private let visibilityButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = DesignTokens.Colors.inkPrimary
        return button
    }()

    private let lockIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "lock.fill")
        iv.tintColor = DesignTokens.Colors.subtleGray
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        // Add subviews
        addSubview(thumbnailView)
        addSubview(nameLabel)
        addSubview(visibilityButton)
        addSubview(lockIcon)

        // Layout
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        visibilityButton.translatesAutoresizingMaskIntoConstraints = false
        lockIcon.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Card size
            widthAnchor.constraint(equalToConstant: 80),
            heightAnchor.constraint(equalToConstant: 64),

            // Thumbnail at top
            thumbnailView.topAnchor.constraint(equalTo: topAnchor),
            thumbnailView.centerXAnchor.constraint(equalTo: centerXAnchor),
            thumbnailView.widthAnchor.constraint(equalToConstant: 48),
            thumbnailView.heightAnchor.constraint(equalToConstant: 48),

            // Name label below thumbnail
            nameLabel.topAnchor.constraint(equalTo: thumbnailView.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),

            // Visibility button (top-left of thumbnail)
            visibilityButton.topAnchor.constraint(equalTo: thumbnailView.topAnchor, constant: -4),
            visibilityButton.leadingAnchor.constraint(equalTo: thumbnailView.leadingAnchor, constant: -4),
            visibilityButton.widthAnchor.constraint(equalToConstant: 24),
            visibilityButton.heightAnchor.constraint(equalToConstant: 24),

            // Lock icon (top-right of thumbnail)
            lockIcon.topAnchor.constraint(equalTo: thumbnailView.topAnchor, constant: 2),
            lockIcon.trailingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: -2),
            lockIcon.widthAnchor.constraint(equalToConstant: 12),
            lockIcon.heightAnchor.constraint(equalToConstant: 12)
        ])

        // Actions
        visibilityButton.addTarget(self, action: #selector(visibilityButtonTapped), for: .touchUpInside)
    }

    // MARK: - Properties (Drag State)
    private var isDraggingCard = false
    private var longPressTriggered = false

    private func setupGestures() {
        // Tap to select
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        addGestureRecognizer(tapGesture)

        // Long press for context menu or drag start
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(cardLongPressed))
        longPressGesture.minimumPressDuration = 0.5
        addGestureRecognizer(longPressGesture)

        // Pan gesture for dragging
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(cardPanned))
        addGestureRecognizer(panGesture)

        // Allow long press and pan to work together
        longPressGesture.require(toFail: tapGesture)
    }

    // MARK: - Configuration

    func configure(with layer: Layer, isSelected: Bool) {
        self.layer = layer

        nameLabel.text = layer.name

        // Visibility icon
        let eyeIcon = layer.isVisible ? "eye.fill" : "eye.slash.fill"
        visibilityButton.setImage(UIImage(systemName: eyeIcon), for: .normal)
        visibilityButton.alpha = layer.isVisible ? 1.0 : 0.5

        // Lock icon
        lockIcon.isHidden = !layer.isLocked

        // Selection state
        updateSelection(isSelected: isSelected)
    }

    func updateSelection(isSelected: Bool) {
        if isSelected {
            thumbnailView.layer.borderWidth = 2
            thumbnailView.layer.borderColor = DesignTokens.Colors.inkPrimary.cgColor
            backgroundColor = UIColor(hex: "f0f3ff")
            layer?.cornerRadius = 12
        } else {
            thumbnailView.layer.borderWidth = 1
            thumbnailView.layer.borderColor = UIColor.systemGray5.cgColor
            backgroundColor = .clear
        }
    }

    func updateThumbnail(_ image: UIImage?) {
        thumbnailView.image = image
    }

    // MARK: - Actions

    @objc private func cardTapped() {
        guard let layer = layer else { return }
        delegate?.layerCard(self, didSelectLayer: layer)
    }

    @objc private func cardLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard let layer = layer else { return }

        switch gesture.state {
        case .began:
            // Mark that long press was triggered
            longPressTriggered = true

            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()

            // Delay to see if user starts dragging
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                // If user hasn't started dragging, show context menu
                if self.longPressTriggered && !self.isDraggingCard {
                    self.delegate?.layerCard(self, didLongPressLayer: layer)
                    self.longPressTriggered = false
                }
            }

        case .ended, .cancelled:
            longPressTriggered = false
            isDraggingCard = false

        default:
            break
        }
    }

    @objc private func cardPanned(_ gesture: UIPanGestureRecognizer) {
        guard let layer = layer else { return }

        switch gesture.state {
        case .began:
            // If long press was triggered, start drag mode
            if longPressTriggered {
                isDraggingCard = true
                longPressTriggered = false

                // Notify delegate to start dragging
                if let longPressGesture = gestureRecognizers?.first(where: { $0 is UILongPressGestureRecognizer }) as? UILongPressGestureRecognizer {
                    delegate?.layerCard(self, didStartDraggingLayer: layer, gesture: longPressGesture)
                }
            }

        case .changed:
            // Continue dragging if in drag mode
            if isDraggingCard {
                delegate?.layerCard(self, didDragLayer: layer, gesture: gesture)
            }

        case .ended, .cancelled:
            // End dragging
            if isDraggingCard {
                delegate?.layerCard(self, didDragLayer: layer, gesture: gesture)
            }
            isDraggingCard = false

        default:
            break
        }
    }

    @objc private func visibilityButtonTapped() {
        guard let layer = layer else { return }
        delegate?.layerCard(self, didToggleVisibilityFor: layer)

        // Animate button
        UIView.animate(
            withDuration: DesignTokens.Animation.durationFast,
            animations: {
                self.visibilityButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            },
            completion: { _ in
                UIView.animate(withDuration: DesignTokens.Animation.durationFast) {
                    self.visibilityButton.transform = .identity
                }
            }
        )
    }
}
