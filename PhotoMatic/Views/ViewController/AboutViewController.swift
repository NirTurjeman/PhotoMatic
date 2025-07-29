import UIKit

class AboutViewController: UIViewController {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 28)
        label.textColor = .label
        label.textAlignment = .natural
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let summaryLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = .secondaryLabel
        label.textAlignment = .natural
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let footerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTexts()
        setupLayout()
    }

    private func setupTexts() {
        titleLabel.text = NSLocalizedString("about_title", tableName: "About", comment: "")
        summaryLabel.text = NSLocalizedString("about_summary", tableName: "About", comment: "")
        footerLabel.text = NSLocalizedString("about_footer", tableName: "About", comment: "")
    }

    private func setupLayout() {
        // Scrollable content
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        contentView.addSubview(titleLabel)
        contentView.addSubview(summaryLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            summaryLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            summaryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            summaryLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            summaryLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])

        view.addSubview(footerLabel)
        NSLayoutConstraint.activate([
            footerLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            footerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}
