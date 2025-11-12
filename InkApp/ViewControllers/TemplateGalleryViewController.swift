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
    private var themeBooks: [ThemeBook] = []
    private var selectedCategory: Template.Category?
    private var selectedTemplateId: UUID?

    // UI Elements
    private var themeBookScrollView: UIScrollView!
    private var themeBookStack: UIStackView!
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
        loadThemeBooks()
        setupThemeBookSection()
        setupCollectionView()
        setupFilterBar()
        setupNavigation()
        setupAdminGesture()
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
            UIColor(hex: "a8edea")!.cgColor,
            UIColor(hex: "fed6e3")!.cgColor
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

    private func loadThemeBooks() {
        // Load theme books with template assignments
        themeBooks = ThemeBook.createSampleThemeBooks(from: templates)

        // Filter to featured theme books only
        themeBooks = themeBooks.filter { $0.isFeatured }.sorted { $0.order < $1.order }
    }

    private func setupThemeBookSection() {
        // Only show if there are featured theme books
        guard !themeBooks.isEmpty else { return }

        // Section header
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.distribution = .equalSpacing
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "✨ Featured Collections"
        titleLabel.font = DesignTokens.Typography.systemFont(size: 20, weight: .bold)
        titleLabel.textColor = DesignTokens.Colors.textPrimary

        let seeAllButton = UIButton(type: .system)
        seeAllButton.setTitle("See All →", for: .normal)
        seeAllButton.titleLabel?.font = DesignTokens.Typography.systemFont(size: 15, weight: .medium)
        seeAllButton.setTitleColor(DesignTokens.Colors.inkPrimary, for: .normal)
        seeAllButton.addTarget(self, action: #selector(seeAllThemeBooksButtonTapped), for: .touchUpInside)

        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(seeAllButton)

        view.addSubview(headerStack)

        // Horizontal scroll view for theme books
        themeBookScrollView = UIScrollView()
        themeBookScrollView.showsHorizontalScrollIndicator = false
        themeBookScrollView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        themeBookScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(themeBookScrollView)

        // Stack for theme book cards
        themeBookStack = UIStackView()
        themeBookStack.axis = .horizontal
        themeBookStack.spacing = 16
        themeBookStack.alignment = .center
        themeBookStack.translatesAutoresizingMaskIntoConstraints = false
        themeBookScrollView.addSubview(themeBookStack)

        // Create theme book cards
        for themeBook in themeBooks {
            let card = createThemeBookCard(themeBook: themeBook)
            themeBookStack.addArrangedSubview(card)
        }

        // Layout constraints
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            themeBookScrollView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 12),
            themeBookScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            themeBookScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            themeBookScrollView.heightAnchor.constraint(equalToConstant: 140),

            themeBookStack.topAnchor.constraint(equalTo: themeBookScrollView.topAnchor),
            themeBookStack.leadingAnchor.constraint(equalTo: themeBookScrollView.leadingAnchor, constant: 20),
            themeBookStack.trailingAnchor.constraint(equalTo: themeBookScrollView.trailingAnchor, constant: -20),
            themeBookStack.bottomAnchor.constraint(equalTo: themeBookScrollView.bottomAnchor),
            themeBookStack.heightAnchor.constraint(equalToConstant: 140)
        ])
    }

    private func createThemeBookCard(themeBook: ThemeBook) -> UIView {
        let card = UIButton(type: .custom)
        card.tag = themeBooks.firstIndex(where: { $0.id == themeBook.id }) ?? 0
        card.addTarget(self, action: #selector(themeBookCardTapped(_:)), for: .touchUpInside)

        // Set size
        card.widthAnchor.constraint(equalToConstant: 260).isActive = true
        card.heightAnchor.constraint(equalToConstant: 140).isActive = true

        // Background gradient
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 260, height: 140)
        gradientLayer.cornerRadius = 16

        let baseColor = UIColor(hex: themeBook.color)!
        let lighterColor = baseColor.lighter(by: 0.15) ?? baseColor
        let darkerColor = baseColor.darker(by: 0.15) ?? baseColor

        gradientLayer.colors = [lighterColor.cgColor, darkerColor.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)

        card.layer.insertSublayer(gradientLayer, at: 0)
        card.layer.cornerRadius = 16
        card.clipsToBounds = true

        // Shadow
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.15
        card.layer.shadowOffset = CGSize(width: 0, height: 5)
        card.layer.shadowRadius = 10

        // Icon
        let iconLabel = UILabel()
        iconLabel.text = themeBook.icon
        iconLabel.font = .systemFont(ofSize: 40)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(iconLabel)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = themeBook.title
        titleLabel.font = DesignTokens.Typography.systemFont(size: 18, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        // Template count
        let countLabel = UILabel()
        let count = themeBook.templateIds.count
        countLabel.text = "\(count) template\(count == 1 ? "" : "s")"
        countLabel.font = DesignTokens.Typography.systemFont(size: 13, weight: .medium)
        countLabel.textColor = UIColor.white.withAlphaComponent(0.9)
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(countLabel)

        NSLayoutConstraint.activate([
            iconLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            iconLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            titleLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            countLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            countLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16)
        ])

        return card
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
        let collectionTopAnchor: NSLayoutYAxisAnchor
        if !themeBooks.isEmpty, let themeBookScrollView = themeBookScrollView {
            // If theme books exist, position collection view below them
            collectionTopAnchor = themeBookScrollView.bottomAnchor
        } else {
            // Otherwise, position at top of safe area
            collectionTopAnchor = view.safeAreaLayoutGuide.topAnchor
        }

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
            collectionView.topAnchor.constraint(equalTo: collectionTopAnchor, constant: 16),
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

        // Use modern UIButton.Configuration for iOS 15+
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
            button.configuration = config
        } else {
            button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        }

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

    private func setupAdminGesture() {
        // Secret gesture: triple-tap with 3 fingers to open admin panel
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(adminGestureTriggered))
        tapGesture.numberOfTapsRequired = 3
        tapGesture.numberOfTouchesRequired = 3
        view.addGestureRecognizer(tapGesture)
    }

    // MARK: - Actions

    @objc private func adminGestureTriggered() {
        print("🎛️ Admin gesture detected - opening Admin Panel")

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()

        // Show admin panel
        let adminVC = AdminPanelViewController()
        let navController = UINavigationController(rootViewController: adminVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    @objc private func seeAllThemeBooksButtonTapped() {
        // Navigate to full theme book gallery
        let themeBookGalleryVC = ThemeBookGalleryViewController()
        navigationController?.pushViewController(themeBookGalleryVC, animated: true)

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    @objc private func themeBookCardTapped(_ sender: UIButton) {
        guard sender.tag < themeBooks.count else { return }
        let themeBook = themeBooks[sender.tag]

        // Animate card
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        } completion: { _ in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5) {
                sender.transform = .identity
            }
        }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Navigate to theme book templates
        if themeBook.isLocked {
            showLockedAlert(for: themeBook)
        } else {
            let templatesVC = ThemeBookTemplatesViewController(themeBook: themeBook)
            navigationController?.pushViewController(templatesVC, animated: true)
        }
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

        // Store current template
        currentTemplate = template

        // Initialize artwork progress
        artworkProgress = ArtworkProgress(templateId: template.id)

        // 1. Clear existing layers
        layerManager.clearAllLayers()
        renderer.clearAllLayers()

        // 2. Load base image (optional - can be used as background reference)
        if template.loadBaseImage() != nil {
            print("  ✅ Loaded base image: \(template.baseImageName)")
            // TODO: Optionally display as background guide layer
        }

        // 3. Create layers from template definitions
        print("  📑 Creating \(template.layerDefinitions.count) layers:")

        for layerDef in template.layerDefinitions.sorted(by: { $0.order < $1.order }) {
            // Create layer
            let layer = Layer(name: layerDef.name, opacity: 1.0)
            layerManager.addLayer(layer)

            // Initialize layer progress
            artworkProgress?.updateLayerProgress(layer.id, progress: 0.0)

            // Load mask image if available
            let maskImage = template.loadMaskImage(for: layerDef)

            // Add layer to renderer with mask
            renderer.addLayer(layer, maskImage: maskImage)

            print("    • \(layerDef.name) (order: \(layerDef.order))")
            if let pattern = layerDef.suggestedPattern {
                print("      Suggested: \(pattern.rawValue)")
            }
        }

        // 4. Select first layer
        if !layerManager.layers.isEmpty {
            layerManager.selectLayer(at: 0)

            // Apply suggested pattern for first layer if available
            if let firstLayerDef = template.layerDefinitions.first,
               let suggestedPattern = firstLayerDef.suggestedPattern {
                applyPatternToBrush(suggestedPattern)
                print("  🎨 Applied suggested pattern: \(suggestedPattern.rawValue)")
            }
        }

        // 5. Update UI
        updateLayerSelectorView()
        updateProgressLabel()
        print("✅ Template loaded successfully")
    }

    /// Apply a pattern type to the current brush
    private func applyPatternToBrush(_ patternType: PatternBrush.PatternType) {
        brushEngine.config.patternBrush.type = patternType

        // Set pattern-specific defaults
        switch patternType {
        case .parallelLines:
            brushEngine.config.patternBrush.rotation = 45
            brushEngine.config.patternBrush.spacing = 10
        case .crossHatch:
            brushEngine.config.patternBrush.rotation = 45
            brushEngine.config.patternBrush.spacing = 12
        case .dots:
            brushEngine.config.patternBrush.rotation = 0
            brushEngine.config.patternBrush.spacing = 15
        case .contourLines:
            brushEngine.config.patternBrush.rotation = 0
            brushEngine.config.patternBrush.spacing = 8
        case .waves:
            brushEngine.config.patternBrush.rotation = 0
            brushEngine.config.patternBrush.spacing = 12
        }
    }

    /// Update layer selector view to reflect new layers
    private func updateLayerSelectorView() {
        if let layerSelector = layerSelectorView {
            layerSelector.removeFromSuperview()
        }
        addLayerSelector()
    }
}
