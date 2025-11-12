//
//  TemplateManagerViewController.swift
//  Ink - Pattern Drawing App
//
//  Template management screen for admin panel
//  Created on November 10, 2025.
//

import UIKit

class TemplateManagerViewController: UIViewController {

    // MARK: - Properties

    private var templates: [Template]
    private var tableView: UITableView!

    // MARK: - Initialization

    init(templates: [Template]) {
        self.templates = templates
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
        title = "Manage Templates"
        view.backgroundColor = .systemGroupedBackground

        // Navigation items
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeButtonTapped)
        )

        // Table view
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TemplateManagementCell.self, forCellReuseIdentifier: TemplateManagementCell.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Actions

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension TemplateManagerViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        // Group by category
        return Template.Category.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let category = Template.Category.allCases[section]
        return templates.filter { $0.category == category }.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let category = Template.Category.allCases[section]
        let count = templates.filter { $0.category == category }.count
        return count > 0 ? "\(category.rawValue) (\(count))" : nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TemplateManagementCell.reuseIdentifier,
            for: indexPath
        ) as? TemplateManagementCell else {
            return UITableViewCell()
        }

        let category = Template.Category.allCases[indexPath.section]
        let templatesInCategory = templates.filter { $0.category == category }
        let template = templatesInCategory[indexPath.row]

        cell.configure(with: template)

        return cell
    }
}

// MARK: - UITableViewDelegate

extension TemplateManagerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let category = Template.Category.allCases[indexPath.section]
        let templatesInCategory = templates.filter { $0.category == category }
        let template = templatesInCategory[indexPath.row]

        // Show template details
        showTemplateDetails(template)
    }

    private func showTemplateDetails(_ template: Template) {
        let alert = UIAlertController(
            title: template.name,
            message: """
            Category: \(template.category.rawValue)
            Difficulty: \(template.difficulty.rawValue)
            Layers: \(template.layerDefinitions.count)
            Duration: \(template.estimatedMinutes) min
            Featured: \(template.isFeatured ? "Yes" : "No")
            Locked: \(template.isLocked ? "Yes" : "No")
            """,
            preferredStyle: .actionSheet
        )

        alert.addAction(UIAlertAction(title: "Toggle Featured", style: .default) { _ in
            // Note: In a real app, this would persist the change
            print("Toggle featured status for: \(template.name)")
            self.showToast("Featured status updated")
        })

        alert.addAction(UIAlertAction(title: "Toggle Locked", style: .default) { _ in
            // Note: In a real app, this would persist the change
            print("Toggle locked status for: \(template.name)")
            self.showToast("Locked status updated")
        })

        alert.addAction(UIAlertAction(title: "Close", style: .cancel))

        // iPad: popover presentation
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)
    }

    private func showToast(_ message: String) {
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        present(alert, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true)
        }
    }
}

// MARK: - TemplateManagementCell

class TemplateManagementCell: UITableViewCell {

    static let reuseIdentifier = "TemplateManagementCell"

    // UI Elements
    private var thumbnailView: UIImageView!
    private var nameLabel: UILabel!
    private var infoLabel: UILabel!
    private var badgesStack: UIStackView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // Thumbnail
        thumbnailView = UIImageView()
        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.layer.cornerRadius = 8
        thumbnailView.clipsToBounds = true
        thumbnailView.backgroundColor = .systemGray5
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(thumbnailView)

        // Name label
        nameLabel = UILabel()
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)

        // Info label
        infoLabel = UILabel()
        infoLabel.font = .systemFont(ofSize: 13)
        infoLabel.textColor = .secondaryLabel
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(infoLabel)

        // Badges stack
        badgesStack = UIStackView()
        badgesStack.axis = .horizontal
        badgesStack.spacing = 4
        badgesStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(badgesStack)

        // Layout
        NSLayoutConstraint.activate([
            thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumbnailView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailView.widthAnchor.constraint(equalToConstant: 60),
            thumbnailView.heightAnchor.constraint(equalToConstant: 60),

            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            infoLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            infoLabel.leadingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: 12),
            infoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            badgesStack.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 4),
            badgesStack.leadingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: 12),
            badgesStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with template: Template) {
        // Thumbnail
        if let thumbnail = template.loadThumbnail() {
            thumbnailView.image = thumbnail
        } else {
            thumbnailView.image = nil
            thumbnailView.backgroundColor = .systemGray5
        }

        // Name
        nameLabel.text = template.name

        // Info
        infoLabel.text = "\(template.difficulty.rawValue) • \(template.layerDefinitions.count) layers • \(template.estimatedMinutes) min"

        // Badges
        badgesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if template.isFeatured {
            let badge = createBadge(text: "⭐ Featured", color: .systemOrange)
            badgesStack.addArrangedSubview(badge)
        }

        if template.isLocked {
            let badge = createBadge(text: "🔒 Premium", color: .systemPurple)
            badgesStack.addArrangedSubview(badge)
        }
    }

    private func createBadge(text: String, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = color
        label.backgroundColor = color.withAlphaComponent(0.1)
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.textAlignment = .center
        label.contentEdgeInsets = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
        return label
    }
}

// MARK: - UILabel ContentEdgeInsets Extension

extension UILabel {
    var contentEdgeInsets: UIEdgeInsets {
        get {
            return UIEdgeInsets.zero
        }
        set {
            // Note: This is a simplified approach. In production, you might use a custom label class.
        }
    }
}
