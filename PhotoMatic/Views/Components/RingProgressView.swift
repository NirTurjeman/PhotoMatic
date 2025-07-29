import UIKit

class RingProgressView: UIView {

    private let backgroundLayer = CAShapeLayer()
    private let mediaLayer = CAShapeLayer()
    private let otherLayer = CAShapeLayer()
    private let percentLabel = UILabel()
    private let infoLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        createCircleLayer(layer: backgroundLayer, color: UIColor.systemGray5, width: 10)
        createCircleLayer(layer: otherLayer, color: UIColor.systemOrange.withAlphaComponent(0.5), width: 15)
        createCircleLayer(layer: mediaLayer, color: UIColor.systemBlue, width: 20)

        layer.addSublayer(backgroundLayer)
        layer.addSublayer(otherLayer)
        layer.addSublayer(mediaLayer)
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4

        percentLabel.font = .boldSystemFont(ofSize: 28)
        percentLabel.textColor = .label
        percentLabel.textAlignment = .center
        percentLabel.translatesAutoresizingMaskIntoConstraints = false

        infoLabel.font = .systemFont(ofSize: 14)
        infoLabel.textColor = .secondaryLabel
        infoLabel.textAlignment = .center
        infoLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(percentLabel)
        addSubview(infoLabel)

        NSLayoutConstraint.activate([
            percentLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            percentLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -10),

            infoLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            infoLabel.topAnchor.constraint(equalTo: percentLabel.bottomAnchor, constant: 4),
        ])
    }

    private func createCircleLayer(layer: CAShapeLayer, color: UIColor, width: CGFloat) {
        layer.strokeColor = color.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = width
        layer.lineCap = .round
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let centerPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 4
        let path = UIBezierPath(
            arcCenter: centerPoint,
            radius: radius,
            startAngle: -CGFloat.pi / 2,
            endAngle: 3 * CGFloat.pi / 2,
            clockwise: true
        )

        [backgroundLayer, mediaLayer, otherLayer].forEach {
            $0.path = path.cgPath
            $0.frame = bounds
        }

        backgroundLayer.strokeEnd = 1
    }

    func setProgress(mediaPercent: CGFloat, otherPercent: CGFloat, totalBytes: Int64, duration: TimeInterval = 1.0) {
        let clampedMedia = min(max(mediaPercent, 0), 1)
        let clampedOther = min(max(otherPercent, 0), 1)
        _ = clampedMedia + clampedOther

        let bytesInGB = 1024.0 * 1024.0 * 1024.0
        let mediaGB = Double(totalBytes) * Double(clampedMedia) / bytesInGB
        let totalGB = calcHardCodedTotalGB(totalGB: Double(totalBytes) / bytesInGB)
        let percentDisplay = clampedMedia * 100

        percentLabel.text = String(format: "%.1f GB", mediaGB)
        percentLabel.textColor = .systemBlue
        infoLabel.text = String(format: NSLocalizedString("used_of_total_format", tableName: "Dashboard", comment: ""), totalGB, percentDisplay)

        // Animate media layer
        let mediaAnimation = CABasicAnimation(keyPath: "strokeEnd")
        mediaAnimation.fromValue = 0
        mediaAnimation.toValue = clampedMedia
        mediaAnimation.duration = duration
        mediaAnimation.fillMode = .forwards
        mediaAnimation.isRemovedOnCompletion = false
        mediaLayer.add(mediaAnimation, forKey: "mediaProgress")

        otherLayer.strokeStart = clampedMedia
        otherLayer.strokeEnd = clampedMedia + clampedOther
    }
    
    func getProgressLayer() -> CAShapeLayer { mediaLayer }
    func getBackgroundLayer() -> CAShapeLayer { backgroundLayer }
    func getOtherLayer() -> CAShapeLayer { otherLayer }
    
    func calcHardCodedTotalGB(totalGB: Double) -> Double {
        switch totalGB {
        case 0...128: return 128.0
        case 129...512: return 512.0
        case 513...1024: return 1024.0
        default: return totalGB
        }
    }
}
