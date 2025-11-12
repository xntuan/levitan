//
//  ThemeBookCreatorViewController.swift
//  Ink - Pattern Drawing App
//
//  Theme book creator for admin panel
//  Created on November 10, 2025.
//

import UIKit

protocol ThemeBookCreatorDelegate: AnyObject {
    func themeBookCreatorDidCreateThemeBook(_ controller: ThemeBookCreatorViewController, themeBook: ThemeBook)
}

class ThemeBookCreatorViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: ThemeBookCreatorDelegate?

    private let templates: [Template]
    private let existingThemeBooks: [ThemeBook]
    private var selectedTemplateIds: Set<UUID> = []

    private var scrollView: UIScrollView!
    private var contentStack: UIStackView!

    // Form fields
    private var titleField: UITextField!
    private var descriptionField: UITextField!
    private var iconField: UITextField!
    private var colorField: UITextField!
    private var featuredToggle: UISwitch!
    private var lockedToggle: UISwitch!
    private var templateSelectionTable: UITableView!

    // MARK: - Initialization

    init(templates: [Template], existingThemeBooks: [ThemeBook]) {
        self.templates = templates
        self.existingThemeBooks = existingThemeBooks
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Create Theme Book"
        view.backgroundColor = .systemGroupedBackground

        // Navigation items
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Create",
            style: .done,
            target: self,
            action: #selector(createButtonTapped)
        )

        // Scroll view
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
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

        // Build form
        buildForm()
    }

    private func buildForm() {
        // Basic Info Section
        let basicSection = createSection(title: "Basic Information")

        titleField = createInputField(placeholder: "e.g., Nature's Beauty")
        basicSection.addArrangedSubview(createFieldRow(label: "Title", field: titleField))

        descriptionField = createInputField(placeholder: "Brief description")
        basicSection.addArrangedSubview(createFieldRow(label: "Description", field: descriptionField))

        iconField = createInputField(placeholder: "e.g., 🌿")
        basicSection.addArrangedSubview(createFieldRow(label: "Icon (Emoji)", field: iconField))

        colorField = createInputField(placeholder: "e.g., 48c6ef")
        basicSection.addArrangedSubview(createFieldRow(label: "Color (Hex)", field: colorField))

        contentStack.addArrangedSubview(basicSection)

        // Settings Section
        let settingsSection = createSection(title: "Settings")

        featuredToggle = UISwitch()
        settingsSection.addArrangedSubview(createToggleRow(label: "Featured", toggle: featuredToggle))

        lockedToggle = UISwitch()
        settingsSection.addArrangedSubview(createToggleRow(label: "Premium (Locked)", toggle: lockedToggle))

        contentStack.addArrangedSubview(settingsSection)

        // Template Selection Section
        let templatesSection = createSection(title: "Templates (\(selectedTemplateIds.count) selected)")

        let templatesLabel = UILabel()
        templatesLabel.text = "Tap templates to add them to this theme book"
        templatesLabel.font = .systemFont(ofSize: 13)
        templatesLabel.textColor = .secondaryLabel
        templatesLabel.numberOfLines = 0
        templatesSection.addArrangedSubview(templatesLabel)

        // Template table
        templateSelectionTable = UITableView(frame: .zero, style: .plain)
        templateSelectionTable.delegate = self
        templateSelectionTable.dataSource = self
        templateSelectionTable.register(UITableViewCell.self, forCellReuseIdentifier: "TemplateCell")
        templateSelectionTable.layer.cornerRadius = 8
        templateSelectionTable.isScrollEnabled = false
        templateSelectionTable.translatesAutoresizingMaskIntoConstraints = false
        templateSelectionTable.heightAnchor.constraint(equalToConstant: CGFloat(templates.count * 44)).isActive = true
        templatesSection.addArrangedSubview(templateSelectionTable)

        contentStack.addArrangedSubview(templatesSection)

        // Quick select buttons
        let quickSelectStack = UIStackView()
        quickSelectStack.axis = .horizontal
        quickSelectStack.spacing = 12
        quickSelectStack.distribution = .fillEqually

        let selectAllButton = createQuickButton(title: "Select All", action: #selector(selectAllTemplates))
        let deselectAllButton = createQuickButton(title: "Deselect All", action: #selector(deselectAllTemplates))

        quickSelectStack.addArrangedSubview(selectAllButton)
        quickSelectStack.addArrangedSubview(deselectAllButton)

        contentStack.addArrangedSubview(quickSelectStack)
    }

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

    private func createInputField(placeholder: String) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.autocapitalizationType = .sentences
        return field
    }

    private func createFieldRow(label: String, field: UITextField) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8

        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 14, weight: .medium)
        labelView.textColor = .secondaryLabel

        stack.addArrangedSubview(labelView)
        stack.addArrangedSubview(field)

        return stack
    }

    private func createToggleRow(label: String, toggle: UISwitch) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center

        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 16)
        labelView.textColor = .label

        stack.addArrangedSubview(labelView)
        stack.addArrangedSubview(toggle)

        labelView.setContentHuggingPriority(.defaultLow, for: .horizontal)

        return stack
    }

    private func createQuickButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        button.setTitleColor(.systemBlue, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // MARK: - Actions

    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func createButtonTapped() {
        // Validate inputs
        guard let title = titleField.text, !title.isEmpty else {
            showAlert(title: "Missing Title", message: "Please enter a title for the theme book.")
            return
        }

        guard let description = descriptionField.text, !description.isEmpty else {
            showAlert(title: "Missing Description", message: "Please enter a description.")
            return
        }

        guard let icon = iconField.text, !icon.isEmpty else {
            showAlert(title: "Missing Icon", message: "Please enter an emoji icon.")
            return
        }

        guard let color = colorField.text, !color.isEmpty else {
            showAlert(title: "Missing Color", message: "Please enter a hex color code.")
            return
        }

        guard !selectedTemplateIds.isEmpty else {
            showAlert(title: "No Templates", message: "Please select at least one template.")
            return
        }

        // Create theme book
        let order = existingThemeBooks.count
        let themeBook = ThemeBook(
            id: UUID(),
            title: title,
            description: description,
            coverImageName: "", // Could be set to first template's thumbnail
            icon: icon,
            color: color,
            templateIds: Array(selectedTemplateIds),
            order: order,
            isFeatured: featuredToggle.isOn,
            isLocked: lockedToggle.isOn,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Notify delegate
        delegate?.themeBookCreatorDidCreateThemeBook(self, themeBook: themeBook)

        // Dismiss
        dismiss(animated: true)
    }

    @objc private func selectAllTemplates() {
        selectedTemplateIds = Set(templates.map { $0.id })
        templateSelectionTable.reloadData()
        updateSectionTitle()
    }

    @objc private func deselectAllTemplates() {
        selectedTemplateIds.removeAll()
        templateSelectionTable.reloadData()
        updateSectionTitle()
    }

    private func updateSectionTitle() {
        // Update the templates section title
        if let templatesSection = contentStack.arrangedSubviews.last(where: { view in
            if let stack = view as? UIStackView,
               let titleLabel = stack.arrangedSubviews.first as? UILabel {
                return titleLabel.text?.contains("Templates") == true
            }
            return false
        }) as? UIStackView,
           let titleLabel = templatesSection.arrangedSubviews.first as? UILabel {
            titleLabel.text = "Templates (\(selectedTemplateIds.count) selected)"
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension ThemeBookCreatorViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return templates.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TemplateCell", for: indexPath)
        let template = templates[indexPath.row]

        cell.textLabel?.text = template.name
        cell.textLabel?.font = .systemFont(ofSize: 15)

        // Show checkmark if selected
        if selectedTemplateIds.contains(template.id) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }
}

// MARK: - UITableViewDelegate

extension ThemeBookCreatorViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let template = templates[indexPath.row]

        // Toggle selection
        if selectedTemplateIds.contains(template.id) {
            selectedTemplateIds.remove(template.id)
        } else {
            selectedTemplateIds.insert(template.id)
        }

        // Reload cell
        tableView.reloadRows(at: [indexPath], with: .automatic)

        // Update section title
        updateSectionTitle()

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}
