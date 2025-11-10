//
//  ThemeBookGalleryViewController.swift
//  Ink - Pattern Drawing App
//
//  User-facing gallery for browsing theme books
//  Created on November 10, 2025.
//

import UIKit

class ThemeBookGalleryViewController: UIViewController {

    // MARK: - Properties

    private var themeBooks: [ThemeBook] = []
    private var collectionView: UICollectionView!

    // Layout
    private let spacing: CGFloat = 20
    private let edgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        loadThemeBooks()
        setupCollectionView()
        setupNavigation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup

    private func setupGradientBackground() {
        // Lake aesthetic gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(hex: AppConfiguration.shared.galleryGradientStart).cgColor,
            UIColor(hex: AppConfiguration.shared.galleryGradientEnd).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)

        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func loadThemeBooks() {
        // Load all theme books
        themeBooks = ThemeBook.createSampleThemeBooks()

        // Sort: featured first, then by order
        themeBooks.sort { book1, book2 in
            if book1.isFeatured != book2.isFeatured {
                return book1.isFeatured
            }
            return book1.order < book2.order
        }
    }

    private func setupCollectionView() {
        // Create flow layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = edgeInsets

        // Create collection view
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(
            ThemeBookCollectionViewCell.self,
            forCellWithReuseIdentifier: ThemeBookCollectionViewCell.reuseIdentifier
        )
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupNavigation() {
        title = "Theme Books"

        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.tintColor = DesignTokens.Colors.textPrimary

        // Make nav bar transparent
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.clear
        appearance.titleTextAttributes = [
            .foregroundColor: DesignTokens.Colors.textPrimary,
            .font: DesignTokens.Typography.systemFont(
                size: 20,
                weight: DesignTokens.Typography.semibold
            )
        ]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    // MARK: - Navigation

    private func navigateToTemplates(for themeBook: ThemeBook) {
        // Check if locked
        if themeBook.isLocked {
            showLockedAlert(for: themeBook)
            return
        }

        // Navigate to templates in this theme book
        let templatesVC = ThemeBookTemplatesViewController(themeBook: themeBook)
        navigationController?.pushViewController(templatesVC, animated: true)
    }

    private func showLockedAlert(for themeBook: ThemeBook) {
        let alert = UIAlertController(
            title: "Premium Theme Book",
            message: "\"\(themeBook.title)\" is a premium collection. Upgrade to unlock all theme books.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Maybe Later", style: .cancel))
        alert.addAction(UIAlertAction(title: "Upgrade", style: .default) { _ in
            // TODO: Navigate to premium upgrade screen
            print("Navigate to premium upgrade")
        })

        present(alert, animated: true)
    }

    // MARK: - Layout

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Update gradient frame
        if let gradientLayer = view.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = view.bounds
        }
    }
}

// MARK: - UICollectionViewDataSource

extension ThemeBookGalleryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return themeBooks.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ThemeBookCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? ThemeBookCollectionViewCell else {
            return UICollectionViewCell()
        }

        let themeBook = themeBooks[indexPath.item]
        cell.configure(with: themeBook)

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension ThemeBookGalleryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let themeBook = themeBooks[indexPath.item]

        // Animate cell
        if let cell = collectionView.cellForItem(at: indexPath) as? ThemeBookCollectionViewCell {
            cell.animatePress()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                cell.animateRelease()
            }
        }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Navigate after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.navigateToTemplates(for: themeBook)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? ThemeBookCollectionViewCell {
            cell.animatePress()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? ThemeBookCollectionViewCell {
            cell.animateRelease()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ThemeBookGalleryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Calculate item size based on device
        let availableWidth = collectionView.bounds.width - edgeInsets.left - edgeInsets.right

        // iPad: 2 columns, iPhone: 1 column
        let columns: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 2 : 1
        let itemSpacing = spacing * (columns - 1)
        let itemWidth = (availableWidth - itemSpacing) / columns

        // 3:2 aspect ratio (wider than square)
        let itemHeight = itemWidth * 0.66

        return CGSize(width: itemWidth, height: itemHeight)
    }
}

// MARK: - ThemeBookCollectionViewCell

class ThemeBookCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier = "ThemeBookCollectionViewCell"

    // UI Elements
    private var containerView: UIView!
    private var gradientLayer: CAGradientLayer!
    private var iconLabel: UILabel!
    private var titleLabel: UILabel!
    private var descriptionLabel: UILabel!
    private var templateCountLabel: UILabel!
    private var badgeLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // Container with shadow
        containerView = UIView()
        containerView.layer.cornerRadius = 20
        containerView.clipsToBounds = true
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.2
        containerView.layer.shadowOffset = CGSize(width: 0, height: 10)
        containerView.layer.shadowRadius = 20
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)

        // Gradient background
        gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        containerView.layer.insertSublayer(gradientLayer, at: 0)

        // Icon
        iconLabel = UILabel()
        iconLabel.font = .systemFont(ofSize: 60)
        iconLabel.textAlignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconLabel)

        // Title
        titleLabel = UILabel()
        titleLabel.font = DesignTokens.Typography.systemFont(size: 24, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        // Description
        descriptionLabel = UILabel()
        descriptionLabel.font = DesignTokens.Typography.systemFont(size: 14, weight: .regular)
        descriptionLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        descriptionLabel.textAlignment = .left
        descriptionLabel.numberOfLines = 2
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(descriptionLabel)

        // Template count
        templateCountLabel = UILabel()
        templateCountLabel.font = DesignTokens.Typography.systemFont(size: 13, weight: .medium)
        templateCountLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        templateCountLabel.textAlignment = .left
        templateCountLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(templateCountLabel)

        // Badge (featured/locked)
        badgeLabel = UILabel()
        badgeLabel.font = .systemFont(ofSize: 32)
        badgeLabel.textAlignment = .right
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(badgeLabel)

        // Layout
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            iconLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            iconLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            iconLabel.widthAnchor.constraint(equalToConstant: 70),
            iconLabel.heightAnchor.constraint(equalToConstant: 70),

            badgeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            badgeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            titleLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            templateCountLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            templateCountLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            templateCountLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = containerView.bounds
        containerView.layer.shadowPath = UIBezierPath(roundedRect: containerView.bounds, cornerRadius: 20).cgPath
    }

    func configure(with themeBook: ThemeBook) {
        // Gradient colors
        let baseColor = UIColor(hex: themeBook.color)
        let lighterColor = baseColor.lighter(by: 0.15) ?? baseColor
        let darkerColor = baseColor.darker(by: 0.15) ?? baseColor

        gradientLayer.colors = [
            lighterColor.cgColor,
            darkerColor.cgColor
        ]

        // Icon
        iconLabel.text = themeBook.icon

        // Title
        titleLabel.text = themeBook.title

        // Description
        descriptionLabel.text = themeBook.description

        // Template count
        let count = themeBook.templateIds.count
        templateCountLabel.text = "\(count) template\(count == 1 ? "" : "s")"

        // Badge
        if themeBook.isFeatured {
            badgeLabel.text = "⭐"
        } else if themeBook.isLocked {
            badgeLabel.text = "🔒"
        } else {
            badgeLabel.text = ""
        }
    }

    func animatePress() {
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }

    func animateRelease() {
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            self.transform = .identity
        }
    }
}

// MARK: - UIColor Extensions

extension UIColor {
    func lighter(by percentage: CGFloat = 0.3) -> UIColor? {
        return self.adjust(by: abs(percentage))
    }

    func darker(by percentage: CGFloat = 0.3) -> UIColor? {
        return self.adjust(by: -abs(percentage))
    }

    func adjust(by percentage: CGFloat) -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(
                red: min(red + percentage, 1.0),
                green: min(green + percentage, 1.0),
                blue: min(blue + percentage, 1.0),
                alpha: alpha
            )
        }
        return nil
    }
}
