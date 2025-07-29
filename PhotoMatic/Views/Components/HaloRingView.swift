import UIKit

class HaloRingView: UIView {

    var outerRingColor: UIColor = .gray

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let shadow = NSShadow()
        shadow.shadowColor = UIColor.black.withAlphaComponent(0.15)
        shadow.shadowBlurRadius = 10
        shadow.shadowOffset = CGSize(width: 0, height: 4)

        context.saveGState()
        context.setShadow(offset: shadow.shadowOffset,
                          blur: shadow.shadowBlurRadius,
                          color: (shadow.shadowColor as! UIColor).cgColor)

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let margin: CGFloat = bounds.width * 0.05
        let maxRadius = min(bounds.width, bounds.height) / 2 - margin

        let innerRadius = maxRadius * 0.7
        let innerPath = UIBezierPath(
            arcCenter: center,
            radius: innerRadius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        )
        UIColor.white.setFill()
        innerPath.fill()

        context.restoreGState()

        let outerRingCount = 2
        let ringSpacing = (maxRadius - innerRadius) / CGFloat(outerRingCount + 1)

        for i in 0..<outerRingCount {
            let radius = innerRadius + CGFloat(i + 1) * ringSpacing
            let alpha = CGFloat(0.1) / CGFloat(i + 1)

            let outerPath = UIBezierPath(
                arcCenter: center,
                radius: radius,
                startAngle: 0,
                endAngle: .pi * 2,
                clockwise: true
            )

            outerRingColor.withAlphaComponent(alpha).setFill()
            outerPath.fill()
        }
    }

}
