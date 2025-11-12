//
//  TemplateCollectionViewCell.swift
//  Ink - Pattern Drawing App
//
//  Collection view cell for displaying template cards
//  Created on November 10, 2025.
//

import UIKit

class TemplateCollectionViewCell: UICollectionViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "TemplateCollectionViewCell"

    // UI Elements
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = DesignTokens.Colors.surface
        return iv
    }()

    private let gradientOverlay: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = DesignTokens.Typography.systemFont(
            size: 15,
            weight: DesignTokens.Typography.semibold
        )
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = DesignTokens.Typography.systemFont(
            size: 13,
            weight: DesignTokens.Typography.regular
        )
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.numberOfLines = 1
        return label
    }()

    private let difficultyLabel: UILabel = {
        let label = UILabel()
        label.font = DesignTokens.Typography.systemFont(
            size: 11,
            weight: DesignTokens.Typography.regular
        )
        label.textColor = UIColor.white.withAlphaComponent(0.9)
        return label
    }()

    private let lockIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "lock.fill")
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    private let featuredBadge: UIView = {
        let view = UIView()
        view.backgroundColor = DesignTokens.Colors.inkPrimary
        view.layer.cornerRadius = 12
        view.isHidden = true

        let label = UILabel()
        label.text = "★"
        label.font = DesignTokens.Typography.systemFont(
            size: 14,
            weight: DesignTokens.Typography.semibold
        )
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            view.widthAnchor.constraint(equalToConstant: 24),
            view.heightAnchor.constraint(equalToConstant: 24)
        ])

        return view
    }()

    // State
    private var gradientLayer: CAGradientLayer?

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
        // Add subviews
        contentView.addSubview(imageView)
        contentView.addSubview(gradientOverlay)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(difficultyLabel)
        contentView.addSubview(lockIcon)
        contentView.addSubview(featuredBadge)

        // Layout
        imageView.translatesAutoresizingMaskIntoConstraints = false
        gradientOverlay.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        difficultyLabel.translatesAutoresizingMaskIntoConstraints = false
        lockIcon.translatesAutoresizingMaskIntoConstraints = false
        featuredBadge.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Image fills cell
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Gradient overlay on bottom half
            gradientOverlay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gradientOverlay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gradientOverlay.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            gradientOverlay.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),

            // Title label
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: subtitleLabel.topAnchor, constant: -4),

            // Subtitle label
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            subtitleLabel.bottomAnchor.constraint(equalTo: difficultyLabel.topAnchor, constant: -4),

            // Difficulty label
            difficultyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            difficultyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            difficultyLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            // Lock icon (top-right)
            lockIcon.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            lockIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            lockIcon.widthAnchor.constraint(equalToConstant: 20),
            lockIcon.heightAnchor.constraint(equalToConstant: 20),

            // Featured badge (top-left)
            featuredBadge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            featuredBadge.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12)
        ])
    }

    private func setupAppearance() {
        // Card appearance
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true

        // Card shadow (Lake aesthetic)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        layer.masksToBounds = false

        // Gradient overlay
        setupGradientOverlay()
    }

    private func setupGradientOverlay() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.6).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)

        gradientOverlay.layer.addSublayer(gradientLayer)
        self.gradientLayer = gradientLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Update gradient frame
        gradientLayer?.frame = gradientOverlay.bounds

        // Update shadow path for performance
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: 16
        ).cgPath
    }

    // MARK: - Configuration

    func configure(with template: Template) {
        // Set title and subtitle
        titleLabel.text = template.name
        subtitleLabel.text = "\(template.category.emoji) \(template.durationDisplay)"
        difficultyLabel.text = template.difficulty.emoji

        // Load thumbnail image
        if let thumbnail = template.loadThumbnail() {
            imageView.image = thumbnail
        } else {
            // Placeholder: Use category gradient as fallback
            imageView.image = createPlaceholderImage(for: template)
        }

        // Show/hide lock icon
        lockIcon.isHidden = !template.isLocked

        // Show/hide featured badge
        featuredBadge.isHidden = !template.isFeatured

        // Reset selection state
        updateSelectionState(isSelected: false)
    }

    private func createPlaceholderImage(for template: Template) -> UIImage? {
        let size = CGSize(width: 400, height: 400)
        let colors = template.category.colorGradient

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        // Draw gradient
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let cgColors = colors.map { $0.cgColor } as CFArray
        guard let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: cgColors,
            locations: nil
        ) else {
            return nil
        }

        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: size.width, y: size.height),
            options: []
        )

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    // MARK: - Selection State

    func updateSelectionState(isSelected: Bool) {
        if isSelected {
            // Selected: Add border
            contentView.layer.borderWidth = 3
            contentView.layer.borderColor = DesignTokens.Colors.inkPrimary.cgColor
        } else {
            // Not selected: No border
            contentView.layer.borderWidth = 0
        }
    }

    // MARK: - Animations

    func animatePress() {
        UIView.animate(
            withDuration: DesignTokens.Animation.durationFast,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction],
            animations: {
                self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            }
        )
    }

    func animateRelease() {
        UIView.animate(
            withDuration: DesignTokens.Animation.durationFast,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: [.curveEaseOut, .allowUserInteraction],
            animations: {
                self.transform = .identity
            }
        )
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()

        imageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        difficultyLabel.text = nil
        lockIcon.isHidden = true
        featuredBadge.isHidden = true
        updateSelectionState(isSelected: false)
        transform = .identity
    }
}
