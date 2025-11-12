//
//  CompletionViewController.swift
//  Ink - Pattern Drawing App
//
//  Celebration screen when artwork is completed
//  Created on November 10, 2025.
//

import UIKit

protocol CompletionViewControllerDelegate: AnyObject {
    func completionViewControllerDidSelectNextArtwork(_ controller: CompletionViewController)
    func completionViewControllerDidRequestShare(_ controller: CompletionViewController, image: UIImage)
}

class CompletionViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: CompletionViewControllerDelegate?

    private let completedImage: UIImage
    private let artworkName: String
    private let completionTime: TimeInterval

    // UI elements
    private var backgroundView: UIView!
    private var artworkImageView: UIImageView!
    private var celebrationLabel: UILabel!
    private var titleLabel: UILabel!
    private var subtitleLabel: UILabel!
    private var shareButton: UIButton!
    private var nextButton: UIButton!
    private var closeButton: UIButton!

    // Celebration emojis
    private var emojiViews: [UILabel] = []
    private let celebrationEmojis = ["🎉", "✨", "🌟", "⭐", "💫", "🎨", "🖌️", "👏"]

    // MARK: - Initialization

    init(completedImage: UIImage, artworkName: String, completionTime: TimeInterval) {
        self.completedImage = completedImage
        self.artworkName = artworkName
        self.completionTime = completionTime
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCelebrationAnimation()
    }

    // MARK: - Setup

    private func setupUI() {
        // Gradient background
        backgroundView = UIView(frame: view.bounds)
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(backgroundView)

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(hex: "667eea")!.cgColor,
            UIColor(hex: "764ba2")!.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        backgroundView.layer.insertSublayer(gradientLayer, at: 0)

        // Close button (top-right)
        closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = DesignTokens.Typography.systemFont(size: 24, weight: .medium)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        closeButton.layer.cornerRadius = 20
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])

        // Celebration label (top)
        celebrationLabel = UILabel()
        celebrationLabel.text = "🎉"
        celebrationLabel.font = DesignTokens.Typography.systemFont(size: 80, weight: .bold)
        celebrationLabel.textAlignment = .center
        celebrationLabel.alpha = 0 // Will fade in
        view.addSubview(celebrationLabel)

        celebrationLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            celebrationLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            celebrationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        // Title label
        titleLabel = UILabel()
        titleLabel.text = "Masterpiece Complete!"
        titleLabel.font = DesignTokens.Typography.systemFont(size: 32, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.alpha = 0 // Will fade in
        view.addSubview(titleLabel)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: celebrationLabel.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])

        // Subtitle label (artwork name + time)
        let timeString = formatTime(completionTime)
        subtitleLabel = UILabel()
        subtitleLabel.text = "\"\(artworkName)\" • Completed in \(timeString)"
        subtitleLabel.font = DesignTokens.Typography.systemFont(size: 16, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2
        subtitleLabel.alpha = 0 // Will fade in
        view.addSubview(subtitleLabel)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])

        // Artwork image view (center)
        artworkImageView = UIImageView(image: completedImage)
        artworkImageView.contentMode = .scaleAspectFit
        artworkImageView.layer.cornerRadius = 20
        artworkImageView.clipsToBounds = true
        artworkImageView.layer.borderColor = UIColor.white.cgColor
        artworkImageView.layer.borderWidth = 4
        artworkImageView.layer.shadowColor = UIColor.black.cgColor
        artworkImageView.layer.shadowOpacity = 0.4
        artworkImageView.layer.shadowOffset = CGSize(width: 0, height: 20)
        artworkImageView.layer.shadowRadius = 30
        artworkImageView.alpha = 0 // Will fade in
        artworkImageView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8) // Will scale up
        view.addSubview(artworkImageView)

        artworkImageView.translatesAutoresizingMaskIntoConstraints = false

        let imageSize: CGFloat = min(view.bounds.width - 80, 400)
        NSLayoutConstraint.activate([
            artworkImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            artworkImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 20),
            artworkImageView.widthAnchor.constraint(equalToConstant: imageSize),
            artworkImageView.heightAnchor.constraint(equalToConstant: imageSize)
        ])

        // Share button
        shareButton = createActionButton(
            title: "Share Artwork",
            icon: "↗️",
            backgroundColor: UIColor.white.withAlphaComponent(0.25),
            action: #selector(shareButtonTapped)
        )
        shareButton.alpha = 0 // Will fade in
        view.addSubview(shareButton)

        shareButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            shareButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            shareButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            shareButton.heightAnchor.constraint(equalToConstant: 56)
        ])

        // Next artwork button
        nextButton = createActionButton(
            title: "Next Artwork",
            icon: "→",
            backgroundColor: UIColor.white,
            action: #selector(nextButtonTapped)
        )
        nextButton.setTitleColor(DesignTokens.Colors.inkPrimary, for: .normal)
        nextButton.alpha = 0 // Will fade in
        view.addSubview(nextButton)

        nextButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            nextButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func createActionButton(title: String, icon: String, backgroundColor: UIColor, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("\(icon)  \(title)", for: .normal)
        button.titleLabel?.font = DesignTokens.Typography.systemFont(size: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 28
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 10)
        button.layer.shadowRadius = 20
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // MARK: - Celebration Animation

    private func startCelebrationAnimation() {
        // Sequence of animations with delays

        // 1. Fade in celebration emoji (0s)
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut) {
            self.celebrationLabel.alpha = 1
            self.celebrationLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.celebrationLabel.transform = .identity
            }
        }

        // 2. Fade in title (0.2s)
        UIView.animate(withDuration: 0.5, delay: 0.2, options: .curveEaseOut) {
            self.titleLabel.alpha = 1
        }

        // 3. Fade in subtitle (0.4s)
        UIView.animate(withDuration: 0.5, delay: 0.4, options: .curveEaseOut) {
            self.subtitleLabel.alpha = 1
        }

        // 4. Scale up and fade in artwork image (0.6s)
        UIView.animate(
            withDuration: 0.8,
            delay: 0.6,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            self.artworkImageView.alpha = 1
            self.artworkImageView.transform = .identity
        }

        // 5. Fade in share button (1.0s)
        UIView.animate(withDuration: 0.5, delay: 1.0, options: .curveEaseOut) {
            self.shareButton.alpha = 1
        }

        // 6. Fade in next button (1.2s)
        UIView.animate(withDuration: 0.5, delay: 1.2, options: .curveEaseOut) {
            self.nextButton.alpha = 1
        }

        // 7. Create floating emojis (starts at 0.8s)
        createFloatingEmojis()
    }

    private func createFloatingEmojis() {
        // Create 12 floating emojis around the screen
        let positions: [(CGFloat, CGFloat)] = [
            (0.1, 0.2), (0.9, 0.25), (0.15, 0.4), (0.85, 0.45),
            (0.1, 0.6), (0.9, 0.65), (0.2, 0.8), (0.8, 0.85),
            (0.05, 0.35), (0.95, 0.55), (0.3, 0.15), (0.7, 0.75)
        ]

        for (index, (xPercent, yPercent)) in positions.enumerated() {
            let emoji = celebrationEmojis.randomElement() ?? "✨"
            let delay = 0.8 + Double(index) * 0.1

            createFloatingEmoji(
                emoji: emoji,
                xPercent: xPercent,
                yPercent: yPercent,
                delay: delay
            )
        }
    }

    private func createFloatingEmoji(emoji: String, xPercent: CGFloat, yPercent: CGFloat, delay: TimeInterval) {
        let label = UILabel()
        label.text = emoji
        label.font = DesignTokens.Typography.systemFont(size: 36, weight: .regular)
        label.textAlignment = .center
        label.alpha = 0

        let x = view.bounds.width * xPercent
        let y = view.bounds.height * yPercent
        label.frame = CGRect(x: x, y: y, width: 40, height: 40)

        view.insertSubview(label, belowSubview: artworkImageView)
        emojiViews.append(label)

        // Animate: fade in, float up, rotate, fade out
        UIView.animate(
            withDuration: 0.5,
            delay: delay,
            options: .curveEaseOut
        ) {
            label.alpha = 0.8
            label.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }

        UIView.animate(
            withDuration: 3.0,
            delay: delay + 0.5,
            options: [.curveEaseInOut, .autoreverse, .repeat]
        ) {
            label.transform = CGAffineTransform(translationX: 0, y: -30)
                .rotated(by: .pi / 8)
        }

        UIView.animate(
            withDuration: 1.0,
            delay: delay + 3.5,
            options: .curveEaseIn
        ) {
            label.alpha = 0
        } completion: { _ in
            label.removeFromSuperview()
        }
    }

    // MARK: - Helper Methods

    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60

        if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        } else {
            return "\(remainingSeconds)s"
        }
    }

    // MARK: - Actions

    @objc private func shareButtonTapped() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Animate button
        UIView.animate(withDuration: 0.1) {
            self.shareButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.shareButton.transform = .identity
            }
        }

        // Show share sheet
        let activityVC = UIActivityViewController(
            activityItems: [completedImage],
            applicationActivities: nil
        )

        // iPad: popover presentation
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = shareButton
            popover.sourceRect = shareButton.bounds
        }

        activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            if completed {
                print("✅ Artwork shared via \(activityType?.rawValue ?? "unknown")")
            }
        }

        present(activityVC, animated: true)

        // Also notify delegate
        delegate?.completionViewControllerDidRequestShare(self, image: completedImage)
    }

    @objc private func nextButtonTapped() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Animate button
        UIView.animate(withDuration: 0.1) {
            self.nextButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.nextButton.transform = .identity
            }
        }

        print("→ Next artwork requested")

        // Dismiss and notify delegate
        dismiss(animated: true) {
            self.delegate?.completionViewControllerDidSelectNextArtwork(self)
        }
    }

    @objc private func closeButtonTapped() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        // Animate button
        UIView.animate(withDuration: 0.1) {
            self.closeButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.closeButton.transform = .identity
            }
        }

        // Dismiss
        dismiss(animated: true)
        print("✕ Completion screen closed")
    }
}
