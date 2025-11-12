//
//  AdminPanelViewController.swift
//  Ink - Pattern Drawing App
//
//  Admin panel for managing templates, theme books, and app configuration
//  Created on November 10, 2025.
//

import UIKit
import UniformTypeIdentifiers

class AdminPanelViewController: UIViewController {

    // MARK: - Properties

    private var scrollView: UIScrollView!
    private var contentStack: UIStackView!

    private var templates: [Template] = []
    private var themeBooks: [ThemeBook] = []
    private var configuration = AppConfiguration.shared

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Admin Panel"
        view.backgroundColor = .systemGroupedBackground

        // Navigation items
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeButtonTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Export Config",
            style: .plain,
            target: self,
            action: #selector(exportConfigButtonTapped)
        )

        // Scroll view
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // Content stack
        contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])

        // Build sections
        buildSections()
    }

    private func buildSections() {
        // Header
        addHeaderSection()

        // Actions
        addActionsSection()

        // Configuration
        addConfigurationSection()

        // Templates
        addTemplatesSection()

        // Theme Books
        addThemeBooksSection()

        // Export Tools
        addExportToolsSection()
    }

    // MARK: - Header Section

    private func addHeaderSection() {
        let header = createSectionHeader(title: "🎛️ Admin Panel", subtitle: "Manage templates, themes, and configuration")
        contentStack.addArrangedSubview(header)
    }

    // MARK: - Actions Section

    private func addActionsSection() {
        let section = createSection(title: "Quick Actions")

        // Export masks button
        let exportMasksButton = createActionButton(
            title: "Export All Masks as PNG",
            subtitle: "Generate and save mask images to Documents",
            action: #selector(exportMasksButtonTapped)
        )
        section.addArrangedSubview(exportMasksButton)

        // Generate base images button
        let generateBasesButton = createActionButton(
            title: "Generate Base Images",
            subtitle: "Create outline images for templates",
            action: #selector(generateBaseImagesButtonTapped)
        )
        section.addArrangedSubview(generateBasesButton)

        // Reset config button
        let resetButton = createActionButton(
            title: "Reset Configuration",
            subtitle: "Restore default app settings",
            action: #selector(resetConfigButtonTapped),
            color: .systemRed
        )
        section.addArrangedSubview(resetButton)

        contentStack.addArrangedSubview(section)
    }

    // MARK: - Configuration Section

    private func addConfigurationSection() {
        let section = createSection(title: "App Configuration")

        // Primary color
        let primaryColorField = createColorField(
            label: "Primary Color",
            value: configuration.primaryColor,
            tag: 100
        )
        section.addArrangedSubview(primaryColorField)

        // Welcome message
        let welcomeField = createTextField(
            label: "Welcome Title",
            value: configuration.welcomeTitle,
            tag: 200
        )
        section.addArrangedSubview(welcomeField)

        // Feature toggles
        let onboardingToggle = createToggle(
            label: "Show Onboarding",
            isOn: configuration.showOnboarding,
            tag: 300
        )
        section.addArrangedSubview(onboardingToggle)

        let proModeToggle = createToggle(
            label: "Enable Pro Mode",
            isOn: configuration.enableProMode,
            tag: 301
        )
        section.addArrangedSubview(proModeToggle)

        let sharingToggle = createToggle(
            label: "Enable Sharing",
            isOn: configuration.enableSharing,
            tag: 302
        )
        section.addArrangedSubview(sharingToggle)

        // Save button
        let saveButton = createPrimaryButton(title: "Save Configuration", action: #selector(saveConfigButtonTapped))
        section.addArrangedSubview(saveButton)

        contentStack.addArrangedSubview(section)
    }

    // MARK: - Templates Section

    private func addTemplatesSection() {
        let section = createSection(title: "Templates (\(templates.count))")

        let templatesLabel = UILabel()
        templatesLabel.text = "Manage templates, set featured status, and organize into theme books."
        templatesLabel.font = .systemFont(ofSize: 14)
        templatesLabel.textColor = .secondaryLabel
        templatesLabel.numberOfLines = 0
        section.addArrangedSubview(templatesLabel)

        // Show template list button
        let manageButton = createActionButton(
            title: "Manage Templates",
            subtitle: "View and edit all templates",
            action: #selector(manageTemplatesButtonTapped)
        )
        section.addArrangedSubview(manageButton)

        contentStack.addArrangedSubview(section)
    }

    // MARK: - Theme Books Section

    private func addThemeBooksSection() {
        let section = createSection(title: "Theme Books (\(themeBooks.count))")

        for themeBook in themeBooks {
            let bookRow = createThemeBookRow(themeBook: themeBook)
            section.addArrangedSubview(bookRow)
        }

        // Add new theme book button
        let addButton = createActionButton(
            title: "+ Create New Theme Book",
            subtitle: "Group templates into collections",
            action: #selector(createThemeBookButtonTapped),
            color: .systemGreen
        )
        section.addArrangedSubview(addButton)

        contentStack.addArrangedSubview(section)
    }

    // MARK: - Export Tools Section

    private func addExportToolsSection() {
        let section = createSection(title: "Export Tools")

        let exportConfigButton = createActionButton(
            title: "Export Configuration JSON",
            subtitle: "Download config for backup or sharing",
            action: #selector(exportConfigButtonTapped)
        )
        section.addArrangedSubview(exportConfigButton)

        let importConfigButton = createActionButton(
            title: "Import Configuration JSON",
            subtitle: "Load config from file",
            action: #selector(importConfigButtonTapped)
        )
        section.addArrangedSubview(importConfigButton)

        contentStack.addArrangedSubview(section)
    }

    // MARK: - UI Helpers

    private func createSection(title: String) -> UIStackView {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 12
        container.clipsToBounds = true

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        stack.addArrangedSubview(titleLabel)

        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return stack
    }

    private func createSectionHeader(title: String, subtitle: String) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 16)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(subtitleLabel)

        return stack
    }

    private func createActionButton(title: String, subtitle: String, action: Selector, color: UIColor = .systemBlue) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = color.withAlphaComponent(0.1)
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        button.addTarget(self, action: action, for: .touchUpInside)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.isUserInteractionEnabled = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = color

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(subtitleLabel)

        button.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: button.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -12)
        ])

        return button
    }

    private func createPrimaryButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func createTextField(label: String, value: String, tag: Int) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8

        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 14, weight: .medium)
        labelView.textColor = .secondaryLabel

        let textField = UITextField()
        textField.text = value
        textField.borderStyle = .roundedRect
        textField.tag = tag
        textField.delegate = self

        container.addArrangedSubview(labelView)
        container.addArrangedSubview(textField)

        return container
    }

    private func createColorField(label: String, value: String, tag: Int) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 12
        container.alignment = .center

        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 14, weight: .medium)
        labelView.textColor = .secondaryLabel

        let colorPreview = UIView()
        colorPreview.backgroundColor = UIColor(hex: value)
        colorPreview.layer.cornerRadius = 12
        colorPreview.layer.borderWidth = 1
        colorPreview.layer.borderColor = UIColor.separator.cgColor
        colorPreview.widthAnchor.constraint(equalToConstant: 44).isActive = true
        colorPreview.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let textField = UITextField()
        textField.text = value
        textField.borderStyle = .roundedRect
        textField.placeholder = "RRGGBB"
        textField.tag = tag
        textField.delegate = self

        container.addArrangedSubview(labelView)
        container.addArrangedSubview(colorPreview)
        container.addArrangedSubview(textField)

        labelView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)

        return container
    }

    private func createToggle(label: String, isOn: Bool, tag: Int) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 12
        container.alignment = .center

        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 14, weight: .medium)
        labelView.textColor = .label

        let toggle = UISwitch()
        toggle.isOn = isOn
        toggle.tag = tag
        toggle.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged)

        container.addArrangedSubview(labelView)
        container.addArrangedSubview(toggle)

        labelView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        return container
    }

    private func createThemeBookRow(themeBook: ThemeBook) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(hex: themeBook.color)!.withAlphaComponent(0.1)
        container.layer.cornerRadius = 8
        container.heightAnchor.constraint(equalToConstant: 60).isActive = true

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        stack.isLayoutMarginsRelativeArrangement = true

        let icon = UILabel()
        icon.text = themeBook.icon
        icon.font = .systemFont(ofSize: 32)

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2

        let title = UILabel()
        title.text = themeBook.title
        title.font = .systemFont(ofSize: 16, weight: .semibold)

        let templates = UILabel()
        templates.text = "\(themeBook.templateIds.count) templates"
        templates.font = .systemFont(ofSize: 13)
        templates.textColor = .secondaryLabel

        textStack.addArrangedSubview(title)
        textStack.addArrangedSubview(templates)

        let badge = UILabel()
        if themeBook.isFeatured {
            badge.text = "⭐"
        } else if themeBook.isLocked {
            badge.text = "🔒"
        }
        badge.font = .systemFont(ofSize: 20)

        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(textStack)
        stack.addArrangedSubview(badge)

        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)

        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    // MARK: - Data Loading

    private func loadData() {
        templates = Template.createSampleTemplates()
        themeBooks = ThemeBook.createSampleThemeBooks(from: templates)
    }

    // MARK: - Actions

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func exportMasksButtonTapped() {
        let alert = UIAlertController(
            title: "Export Masks",
            message: "This will generate PNG masks for all templates and save them to Documents/Masks folder.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Export", style: .default) { _ in
            TemplateMaskExporter.exportAllTemplateMasks()

            let success = UIAlertController(
                title: "Success!",
                message: "Masks exported to Documents/Masks folder. Check Xcode console for file paths.",
                preferredStyle: .alert
            )
            success.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(success, animated: true)
        })

        present(alert, animated: true)
    }

    @objc private func generateBaseImagesButtonTapped() {
        TemplateMaskExporter.generateExampleBaseImages()

        let alert = UIAlertController(
            title: "Success!",
            message: "Base images generated and saved to Documents/BaseImages folder.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func resetConfigButtonTapped() {
        let alert = UIAlertController(
            title: "Reset Configuration?",
            message: "This will restore all default settings.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { _ in
            AppConfigurationManager.shared.resetToDefaults()
            self.configuration = AppConfiguration.shared

            let success = UIAlertController(
                title: "Configuration Reset",
                message: "All settings restored to defaults.",
                preferredStyle: .alert
            )
            success.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                // Rebuild UI
                self.contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
                self.buildSections()
            })
            self.present(success, animated: true)
        })

        present(alert, animated: true)
    }

    @objc private func saveConfigButtonTapped() {
        // Configuration auto-saves via property observer
        let alert = UIAlertController(
            title: "Configuration Saved",
            message: "Your changes have been applied.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func manageTemplatesButtonTapped() {
        // Show template management screen
        let managerVC = TemplateManagerViewController(templates: templates)
        let navController = UINavigationController(rootViewController: managerVC)
        present(navController, animated: true)
    }

    @objc private func createThemeBookButtonTapped() {
        // Show theme book creator
        let creatorVC = ThemeBookCreatorViewController(templates: templates, existingThemeBooks: themeBooks)
        creatorVC.delegate = self
        let navController = UINavigationController(rootViewController: creatorVC)
        present(navController, animated: true)
    }

    @objc private func exportConfigButtonTapped() {
        do {
            let data = try AppConfigurationManager.shared.exportConfiguration()

            let activityVC = UIActivityViewController(
                activityItems: [data],
                applicationActivities: nil
            )

            if let popover = activityVC.popoverPresentationController {
                popover.barButtonItem = navigationItem.rightBarButtonItem
            }

            present(activityVC, animated: true)
        } catch {
            let alert = UIAlertController(
                title: "Export Failed",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    @objc private func importConfigButtonTapped() {
        // Show document picker for JSON files
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    @objc private func toggleChanged(_ sender: UISwitch) {
        switch sender.tag {
        case 300:
            configuration.showOnboarding = sender.isOn
        case 301:
            configuration.enableProMode = sender.isOn
        case 302:
            configuration.enableSharing = sender.isOn
        default:
            break
        }

        AppConfiguration.shared = configuration
    }
}

// MARK: - UITextFieldDelegate

extension AdminPanelViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text else { return }

        switch textField.tag {
        case 100:
            configuration.primaryColor = text
        case 200:
            configuration.welcomeTitle = text
        default:
            break
        }

        AppConfiguration.shared = configuration
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - ThemeBookCreatorDelegate

extension AdminPanelViewController: ThemeBookCreatorDelegate {
    func themeBookCreatorDidCreateThemeBook(_ controller: ThemeBookCreatorViewController, themeBook: ThemeBook) {
        // Add new theme book to list
        themeBooks.append(themeBook)

        // Reload UI
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        buildSections()

        print("✅ Theme book created: \(themeBook.title)")
    }
}

// MARK: - UIDocumentPickerDelegate

extension AdminPanelViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        // Ensure we can access the file
        guard url.startAccessingSecurityScopedResource() else {
            showImportError("Unable to access file")
            return
        }

        defer { url.stopAccessingSecurityScopedResource() }

        do {
            // Read JSON data
            let data = try Data(contentsOf: url)

            // Import configuration
            try AppConfigurationManager.shared.importConfiguration(from: data)
            configuration = AppConfiguration.shared

            // Reload UI
            contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            buildSections()

            // Show success
            let alert = UIAlertController(
                title: "Import Successful",
                message: "Configuration has been imported and applied.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)

            print("✅ Configuration imported from: \(url.lastPathComponent)")
        } catch {
            showImportError(error.localizedDescription)
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("ℹ️ Configuration import cancelled")
    }

    private func showImportError(_ message: String) {
        let alert = UIAlertController(
            title: "Import Failed",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
