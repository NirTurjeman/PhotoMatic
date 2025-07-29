import UIKit

class DashboardCardView: UIView {

    // MARK: - Outlets
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var iconBackgroundView: UIView!

    required init?(coder aDecoder: NSCoder) {
          super.init(coder: aDecoder)
          loadFromNib()
      }

      override init(frame: CGRect) {
          super.init(frame: frame)
          loadFromNib()
      }

    private func loadFromNib() {
        let nib = UINib(nibName: "DashboardCardView", bundle: nil)
        guard let contentView = nib.instantiate(withOwner: self).first as? UIView else { return }

        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.layer.cornerRadius = 20
        contentView.clipsToBounds = true
        addSubview(contentView)

        iconBackgroundView.layer.cornerRadius = 30
        iconBackgroundView.clipsToBounds = true

        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.textAlignment = .center
        subtitleLabel.textAlignment = .center
    }


    func configure(icon: UIImage, color: UIColor, title: String, subtitle: String) {
        iconImageView.image = icon
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit

        iconBackgroundView.backgroundColor = color
        iconBackgroundView.layer.cornerRadius = 12
        iconBackgroundView.clipsToBounds = true

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label

        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel

        self.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
        
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        iconBackgroundView.layer.cornerRadius = iconBackgroundView.frame.width / 2
        iconBackgroundView.clipsToBounds = true
    }
  }
