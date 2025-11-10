//
//  TemplateGalleryViewController.swift
//  Ink - Pattern Drawing App
//
//  Template gallery with grid layout and category filters
//  Created on November 10, 2025.
//

import UIKit

class TemplateGalleryViewController: UIViewController {

    // MARK: - Properties

    private var templates: [Template] = []
    private var filteredTemplates: [Template] = []
    private var selectedCategory: Template.Category?
    private var selectedTemplateId: UUID?

    // UI Elements
    private var collectionView: UICollectionView!
    private var filterScrollView: UIScrollView!
    private var filterStack: UIStackView!
    private var filterChips: [UIButton] = []

    // Layout
    private let spacing: CGFloat = 16
    private let edgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        loadTemplates()
        setupCollectionView()
        setupFilterBar()
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
            UIColor(hex: "a8edea").cgColor,
            UIColor(hex: "fed6e3").cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)

        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func loadTemplates() {
        // Load sample templates
        templates = Template.createSampleTemplates()
        filteredTemplates = templates
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
    }

    private func setupFilterBar() {
        // Create scroll view for filter chips
        filterScrollView = UIScrollView()
        filterScrollView.showsHorizontalScrollIndicator = false
        filterScrollView.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        filterScrollView.layer.cornerRadius = 0
        filterScrollView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

        // Add blur effect
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        filterScrollView.insertSubview(blurView, at: 0)

        // Create stack view for chips
        filterStack = UIStackView()
        filterStack.axis = .horizontal
        filterStack.spacing = 12
        filterStack.alignment = .center
        filterStack.distribution = .equalSpacing

        filterScrollView.addSubview(filterStack)
        view.addSubview(filterScrollView)

        filterScrollView.translatesAutoresizingMaskIntoConstraints = false
        filterStack.translatesAutoresizingMaskIntoConstraints = false

        // Create filter chips
        createFilterChips()

        // Layout constraints
        NSLayoutConstraint.activate([
            // Blur view fills scroll view
            blurView.topAnchor.constraint(equalTo: filterScrollView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: filterScrollView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: filterScrollView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: filterScrollView.bottomAnchor),

            // Filter scroll view at bottom
            filterScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filterScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            filterScrollView.heightAnchor.constraint(equalToConstant: 68),

            // Collection view fills remaining space
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: filterScrollView.topAnchor, constant: -8),

            // Stack view inside scroll view
            filterStack.topAnchor.constraint(equalTo: filterScrollView.topAnchor, constant: 12),
            filterStack.leadingAnchor.constraint(equalTo: filterScrollView.leadingAnchor, constant: 20),
            filterStack.trailingAnchor.constraint(equalTo: filterScrollView.trailingAnchor, constant: -20),
            filterStack.bottomAnchor.constraint(equalTo: filterScrollView.bottomAnchor, constant: -12),
            filterStack.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func createFilterChips() {
        // All templates chip
        let allChip = createFilterChip(title: "All", category: nil)
        allChip.isSelected = true
        filterChips.append(allChip)
        filterStack.addArrangedSubview(allChip)

        // Category chips
        for category in Template.Category.allCases {
            let chip = createFilterChip(title: category.rawValue, category: category)
            filterChips.append(chip)
            filterStack.addArrangedSubview(chip)
        }
    }

    private func createFilterChip(title: String, category: Template.Category?) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = DesignTokens.Typography.systemFont(
            size: 15,
            weight: DesignTokens.Typography.semibold
        )
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        button.layer.cornerRadius = 22
        button.tag = category?.hashValue ?? -1

        // Initial style (unselected)
        updateChipStyle(button, isSelected: false)

        // Action
        button.addTarget(self, action: #selector(filterChipTapped(_:)), for: .touchUpInside)

        return button
    }

    private func updateChipStyle(_ button: UIButton, isSelected: Bool) {
        if isSelected {
            // Selected state
            button.backgroundColor = DesignTokens.Colors.inkPrimary
            button.setTitleColor(.white, for: .normal)
            button.layer.borderWidth = 0
        } else {
            // Unselected state
            button.backgroundColor = .white
            button.setTitleColor(DesignTokens.Colors.inkPrimary, for: .normal)
            button.layer.borderWidth = 2
            button.layer.borderColor = DesignTokens.Colors.inkPrimary.cgColor
        }
    }

    private func setupNavigation() {
        title = "Templates"

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

    // MARK: - Actions

    @objc private func filterChipTapped(_ sender: UIButton) {
        // Update selected chip
        filterChips.forEach { chip in
            let isSelected = chip == sender
            chip.isSelected = isSelected
            updateChipStyle(chip, isSelected: isSelected)
        }

        // Find category
        selectedCategory = Template.Category.allCases.first { $0.hashValue == sender.tag }

        // Filter templates
        filterTemplates()

        // Add haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    private func filterTemplates() {
        if let category = selectedCategory {
            filteredTemplates = templates.filter { $0.category == category }
        } else {
            filteredTemplates = templates
        }

        // Reload collection view with animation
        UIView.transition(
            with: collectionView,
            duration: DesignTokens.Animation.durationMedium,
            options: .transitionCrossDissolve,
            animations: {
                self.collectionView.reloadData()
            }
        )
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

extension TemplateGalleryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredTemplates.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TemplateCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? TemplateCollectionViewCell else {
            return UICollectionViewCell()
        }

        let template = filteredTemplates[indexPath.item]
        cell.configure(with: template)

        // Update selection state
        cell.updateSelectionState(isSelected: template.id == selectedTemplateId)

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension TemplateGalleryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let template = filteredTemplates[indexPath.item]
        selectedTemplateId = template.id

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

extension TemplateGalleryViewController: UICollectionViewDelegateFlowLayout {
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

// MARK: - EnhancedCanvasViewController Extension

extension EnhancedCanvasViewController {
    /// Load a template and configure layers
    func loadTemplate(_ template: Template) {
        print("📄 Loading template: \(template.name)")

        // TODO: Implement template loading
        // 1. Load base image
        // 2. Create layers from template.layerDefinitions
        // 3. Load mask textures for each layer
        // 4. Set suggested patterns for each layer
        // 5. Update UI

        // For now, just log
        print("  - Layers: \(template.layerDefinitions.count)")
        for layerDef in template.layerDefinitions {
            print("    • \(layerDef.name) - \(layerDef.suggestedPattern?.rawValue ?? "none")")
        }
    }
}
