import UIKit

class AnimatedActionButton: UIButton {

    private let loadingLayer = CAGradientLayer()
    private let checkmarkView = UIImageView(image: UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysTemplate))
    
    private var originalTitle: String?
    private var originalBackgroundColor: UIColor?
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyle()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStyle()
    }

    private func setupStyle() {
        if #available(iOS 15.0, *) {
            self.configuration = nil
        }

        layer.cornerRadius = 20
        backgroundColor = .systemBlue
        setTitleColor(.white, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowOffset = CGSize(width: 0, height: 5)
        layer.shadowRadius = 6
        clipsToBounds = false

        checkmarkView.tintColor = .white
        checkmarkView.contentMode = .scaleAspectFit
        checkmarkView.alpha = 0
        checkmarkView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(checkmarkView)
        NSLayoutConstraint.activate([
            checkmarkView.centerXAnchor.constraint(equalTo: centerXAnchor),
            checkmarkView.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkmarkView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkView.heightAnchor.constraint(equalToConstant: 24)
        ])

        addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            activityIndicator.leadingAnchor.constraint(equalTo: titleLabel!.leadingAnchor, constant: -30)
        ])

    }

    func animateLoading() {
        isUserInteractionEnabled = false
        originalTitle = title(for: .normal)
        originalBackgroundColor = backgroundColor
        
        animatePressIn()
        activityIndicator.startAnimating()
        setTitle(NSLocalizedString("Scanning_Progress",tableName: "Dashboard",comment: ""), for: .normal)
        
    }

    private func animatePressIn() {
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            self.layer.shadowOpacity = 0
        }
    }

    private func startLoadingAnimation() {
        loadingLayer.colors = [
            UIColor.white.withAlphaComponent(0.3).cgColor,
            UIColor.white.withAlphaComponent(0.1).cgColor
        ]
        loadingLayer.isGeometryFlipped = true
        loadingLayer.startPoint = CGPoint(x: 0, y: 0.5)
        loadingLayer.endPoint = CGPoint(x: 1, y: 0.5)
        loadingLayer.frame = bounds
        loadingLayer.cornerRadius = layer.cornerRadius
        loadingLayer.name = "loading"
        layer.addSublayer(loadingLayer)

        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.duration = 1.0
        animation.repeatCount = .infinity
        loadingLayer.locations = [0.0, 0.5, 1.0]
        loadingLayer.add(animation, forKey: "shimmer")
    }

    private func stopLoadingAnimation() {
        loadingLayer.removeAllAnimations()
        loadingLayer.removeFromSuperlayer()
    }

    func animateSuccess() {
        self.activityIndicator.stopAnimating()
        UIView.animate(withDuration: 0.5, animations: {
            self.layer.backgroundColor = UIColor.systemGreen.cgColor
            self.setNeedsDisplay()
        }, completion: { _ in
            self.showCheckmarkAndDismiss()
        })
    }

    private func showCheckmarkAndDismiss() {
        UIView.animate(withDuration: 1.0, animations: {
            self.checkmarkView.alpha = 1
            self.backgroundColor = .systemGreen
            self.setTitle("", for: .normal)
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 0.5, options: [], animations: {
                self.alpha = 0
                self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }, completion: nil)
        })
    }
}
