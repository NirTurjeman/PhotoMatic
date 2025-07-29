import UIKit

class CleanHistoryCell: UITableViewCell {
    private let dateLabel = UILabel()
    private let sizeLabel = UILabel()
    private let backupLabel = UILabel()
    private let deletedLabel = UILabel()

    private let stackView = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        selectionStyle = .none

        let dateRow = makeRow(icon: "🕒", label: dateLabel)
        let sizeRow = makeRow(icon: "💾", label: sizeLabel)
        let backupRow = makeRow(icon: "📤", label: backupLabel)
        let deletedRow = makeRow(icon: "🗑️", label: deletedLabel)

        stackView.axis = .vertical
        stackView.spacing = 6
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(dateRow)
        stackView.addArrangedSubview(sizeRow)
        stackView.addArrangedSubview(backupRow)
        stackView.addArrangedSubview(deletedRow)

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])

        [dateLabel, sizeLabel, backupLabel, deletedLabel].forEach {
            $0.font = UIFont.systemFont(ofSize: 15)
            $0.textColor = .label
            $0.numberOfLines = 0
        }

        dateLabel.font = .boldSystemFont(ofSize: 16)
    }

    private func makeRow(icon: String, label: UILabel) -> UIStackView {
        let iconLabel = UILabel()
        iconLabel.text = icon
        iconLabel.font = UIFont.systemFont(ofSize: 16)
        iconLabel.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [iconLabel, label])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .firstBaseline
        return row
    }

    func configure(with result: CompressionResult, formatter: DateFormatter) {
        let isRTL = UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute) == .rightToLeft
        let alignment: NSTextAlignment = isRTL ? .right : .left

        contentView.semanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight

        [dateLabel, sizeLabel, backupLabel, deletedLabel].forEach {
            $0.textAlignment = alignment
        }

        dateLabel.text = formatter.string(from: result.date)

        let original = Double(result.totalOriginalSize) / 1_073_741_824.0
        let compressed = Double(result.totalCompressedSize) / 1_073_741_824.0

        sizeLabel.text = String(format:
            NSLocalizedString("compression_size_format", tableName: "CleanHistory", comment: "Compression size format"),
            original, compressed
        )

        backupLabel.text = String(
            format: NSLocalizedString("backup_label", tableName: "CleanHistory", comment: "Backup label"),
            result.backupLocation?.rawValue ?? NSLocalizedString("none", tableName: "CleanHistory", comment: "None")
        )

        deletedLabel.text = result.originalsDeleted
            ? NSLocalizedString("deleted_true", tableName: "CleanHistory", comment: "")
            : NSLocalizedString("deleted_false", tableName: "CleanHistory", comment: "")
    }
}
