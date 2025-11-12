//
//  ThemeBookTemplatesViewController.swift
//  Ink - Pattern Drawing App
//
//  Shows templates within a specific theme book
//  Created on November 10, 2025.
//

import UIKit

class ThemeBookTemplatesViewController: UIViewController {

    // MARK: - Properties

    private let themeBook: ThemeBook
    private var templates: [Template] = []
    private var collectionView: UICollectionView!

    // Layout
    private let spacing: CGFloat = 16
    private let edgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

    // MARK: - Initialization

    init(themeBook: ThemeBook) {
        self.themeBook = themeBook
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        loadTemplates()
        setupCollectionView()
        setupNavigation()
    }

    // MARK: - Setup

    private func setupGradientBackground() {
        // Use theme book color for gradient
        let baseColor = UIColor(hex: themeBook.color)!
        let lighterColor = baseColor.lighter(by: 0.2) ?? baseColor

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            lighterColor.cgColor,
            UIColor(hex: "fed6e3")!.cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)

        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func loadTemplates() {
        // Load all templates
        let allTemplates = Template.createSampleTemplates()

        // Filter by theme book's template IDs
        templates = allTemplates.filter { template in
            themeBook.templateIds.contains(template.id)
        }

        print("📚 Theme Book: \(themeBook.title) - \(templates.count) templates")
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
            TemplateCollectionViewCell.self,
            forCellWithReuseIdentifier: TemplateCollectionViewCell.reuseIdentifier
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
        title = themeBook.title

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

    private func navigateToCanvas(with template: Template) {
        // Check if locked
        if template.isLocked {
            showLockedAlert(for: template)
            return
        }

        // Create canvas view controller with template
        let canvasVC = EnhancedCanvasViewController()
        canvasVC.loadTemplate(template)
        canvasVC.modalPresentationStyle = .fullScreen

        navigationController?.pushViewController(canvasVC, animated: true)
    }

    private func showLockedAlert(for template: Template) {
        let alert = UIAlertController(
            title: "Premium Template",
            message: "\"\(template.name)\" is a premium template. Upgrade to unlock all templates.",
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

extension ThemeBookTemplatesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return templates.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TemplateCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? TemplateCollectionViewCell else {
            return UICollectionViewCell()
        }

        let template = templates[indexPath.item]
        cell.configure(with: template)

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension ThemeBookTemplatesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let template = templates[indexPath.item]

        // Animate cell
        if let cell = collectionView.cellForItem(at: indexPath) as? TemplateCollectionViewCell {
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
            self.navigateToCanvas(with: template)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? TemplateCollectionViewCell {
            cell.animatePress()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? TemplateCollectionViewCell {
            cell.animateRelease()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ThemeBookTemplatesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Calculate item size based on device
        let availableWidth = collectionView.bounds.width - edgeInsets.left - edgeInsets.right

        // iPad: 2 columns, iPhone: 1 column
        let columns: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 2 : 1
        let itemSpacing = spacing * (columns - 1)
        let itemWidth = (availableWidth - itemSpacing) / columns

        // Square aspect ratio (1:1)
        return CGSize(width: itemWidth, height: itemWidth)
    }
}
