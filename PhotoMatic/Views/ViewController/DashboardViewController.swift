import UIKit
import PhotosUI
import Lottie
import FirebaseDatabase

class DashboardViewController: UIViewController {

    // MARK: - Outlets
    
    //#---CARDS---#
    @IBOutlet weak var stackViewUpperCard: UIStackView!
    @IBOutlet weak var stackViewLowerCards: UIStackView!
    @IBOutlet weak var card1View: UIView!
    @IBOutlet weak var card1: DashboardCardView!
    @IBOutlet weak var card2View: UIView!
    @IBOutlet weak var card2: DashboardCardView!
    @IBOutlet weak var card3View: UIView!
    @IBOutlet weak var card3: DashboardCardView!
    @IBOutlet weak var card4View: UIView!
    @IBOutlet weak var card4: DashboardCardView!
    //#---BACKGROUND---#
    @IBOutlet weak var haloRingView: UIView!
    @IBOutlet weak var bgHalo: UIView!
    @IBOutlet weak var titleHaloView: UILabel!
    @IBOutlet weak var titleHaloDivLine: UIView!
    @IBOutlet weak var legendView: UIView!
    @IBOutlet weak var legendStack: UIStackView!
    @IBOutlet weak var legendPhotosLabel: UILabel!
    @IBOutlet weak var legendOtherLabel: UILabel!
    @IBOutlet weak var legendFreeLabel: UILabel!
    @IBOutlet weak var scanButton: AnimatedActionButton!
    @IBOutlet weak var personalImage: UIImageView!
    private let personalImageContainer = UIView()

    // MARK: - Private Properties
    private var ringView: RingProgressView!
    private var storage: StorageService!
    private var diskInfo: DiskInfo?
    private var animationView: LottieAnimationView!
    private var storageService: StorageService!
    private var profileViewController: ProfileViewController!


    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        profileViewController = ProfileViewController()
        profileViewController.loadSettings()
        storage = StorageService()
        configureView()
        configureGestures()
        storageService = StorageService()
        checkPhotosCount()
        storage.getCompleteDiskInfo { disk in
            self.diskInfo = disk
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureView()
        configureGestures()
        animateSmartCleanCardDown()
        spawnOrbitingDots(around: haloRingView, count: 10, radius: 185)
        checkPhotosCount()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeOrbitingDots(from: haloRingView)
    }
    // MARK: - Gesture
    private func configureGestures() {
        // Card 1 – Smart Clean
        let tapGesture1 = UITapGestureRecognizer(target: self,
                                                 action: #selector(handleSmartCleanCardTap))
        card1View.addGestureRecognizer(tapGesture1)
        card1View.isUserInteractionEnabled = true
        // Card 2 - Analyze Storage
        let tapGesture2 = UITapGestureRecognizer(target: self,
                                                 action: #selector(handleAnalyzeStorageCardTap))
        card2.addGestureRecognizer(tapGesture2)
        card2.isUserInteractionEnabled = true
        card2.bringSubviewToFront(bgHalo)
        // Profile Icon
        let tapGesture3 = UITapGestureRecognizer(target: self,
                                                 action: #selector(handleProfileIconTap))
        personalImage.addGestureRecognizer(tapGesture3)
        personalImage.isUserInteractionEnabled = true
        personalImage.bringSubviewToFront(bgHalo)
        // Card 3 - Clean History
        let tapGesture4 = UITapGestureRecognizer(target: self,
                                                 action: #selector(handleCleanHistoryCardTap))
        card3View.addGestureRecognizer(tapGesture4)
        card3View.isUserInteractionEnabled = true
        // Card 4 – About
        let tapGesture5 = UITapGestureRecognizer(target: self,
                                                 action: #selector(handleAboutCardTap))
        card4View.addGestureRecognizer(tapGesture5)
        card4View.isUserInteractionEnabled = true
    }

    // MARK: - Action
    @objc private func handleAnalyzeStorageCardTap() {
        let storyboard = UIStoryboard(name: "AnalyzeStorage", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "AnalyzeStorageViewController") as? AnalyzeStorageViewController {
            vc.totalStorageGB = diskInfo?.totalGB
            vc.imageStorageGB = diskInfo?.mediaSizeGB
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    @objc private func handleCleanHistoryCardTap() {
        pushViewController(fromStoryboard: "CleanHistory", id: "CleanHistoryViewController")
    }
    @objc private func handleSmartCleanCardTap() {
        pushViewController(fromStoryboard: "SmartClean", id: "SmartCleanViewController")
    }
    @objc private func handleProfileIconTap() {
        pushViewController(fromStoryboard: "Profile", id: "ProfileViewController")
    }
    @objc func handleAboutCardTap() {
        pushViewController(fromStoryboard: "About", id: "AboutViewController")
    }
    private func pushViewController(fromStoryboard name: String, id: String) {
        let storyboard = UIStoryboard(name: name, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: id)
        navigationController?.pushViewController(vc, animated: true)
    }
    @objc private func handleScanTap() {
        scanButton.animateLoading()
        showSpinningArcOnly()

        if self.diskInfo != nil {
            continueWithScan()
        } else {
            storage.getCompleteDiskInfo { disk in
                self.diskInfo = disk
                self.continueWithScan()
            }
        }
    }
    private func checkPhotosCount() {
        let ref = Database.database().reference()
        let userId = UserManager.shared.userId
        
        self.storageService.fetchPhotoAndVideoCounts { images, videos, total in
            ref.child("users/\(userId)/lastAssetCount")
                .observeSingleEvent(of: .value) { snapshot in
                    let lastCount = snapshot.value as? Int ?? 0
                    print("📸 lastCount: \(lastCount)")
                    print("📸 total: \(total)")
                    if total > lastCount {
                        let difference = total - lastCount
                        self.showNewAssetsAlert(count: difference)
                    }
                }
        }
    }

    private func continueWithScan() {
        updateRingWithPhotoUsage {
            self.stopSpinningProgressArc()
            self.scanButton.animateSuccess()
            self.animationView?.removeFromSuperview()
            self.animationView = nil
            self.animateSmartCleanCardUp()
        }
    }
    // MARK: - UI Setup
    func configureView() {
        configureHaloTitle()
        configureHaloLegend()
        configureCards()
        configureScanButton()
        configureRing()
        spawnOrbitingDots(around: haloRingView, count: 10, radius: 185)
        configureRocket()
        configurePersonalImage()

    }
    func showNewAssetsAlert(count: Int) {
        let alert = UIAlertController(
            title: "New Media Detected",
            message: "\(count) new photos or videos have been added since your last compression. Consider compressing again to save space.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
        }
    private func configureHaloTitle() {
        titleHaloView.text = NSLocalizedString("title_halo", tableName: "Dashboard", comment: "")
        titleHaloView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleHaloView.topAnchor.constraint(equalTo: bgHalo.topAnchor, constant: 90),
            titleHaloView.leadingAnchor.constraint(equalTo: bgHalo.leadingAnchor, constant: 20),
            titleHaloView.trailingAnchor.constraint(lessThanOrEqualTo: bgHalo.trailingAnchor, constant: -20)
        ])
        
        titleHaloDivLine.backgroundColor = .separator
        titleHaloDivLine.layer.cornerRadius = 1
        titleHaloDivLine.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleHaloDivLine.topAnchor.constraint(equalTo: titleHaloView.bottomAnchor, constant: 8),
            titleHaloDivLine.leadingAnchor.constraint(equalTo: titleHaloView.leadingAnchor),
            titleHaloDivLine.widthAnchor.constraint(equalToConstant: 280),
            titleHaloDivLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    private func configureHaloLegend() {
        legendView.backgroundColor = .secondarySystemBackground
        legendView.layer.cornerRadius = 12
        legendView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            legendView.bottomAnchor.constraint(equalTo: bgHalo.bottomAnchor, constant: -20),
            legendView.leadingAnchor.constraint(equalTo: bgHalo.leadingAnchor, constant: 20),
            legendView.trailingAnchor.constraint(lessThanOrEqualTo: bgHalo.trailingAnchor, constant: -20)
        ])

        legendStack.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        legendStack.isLayoutMarginsRelativeArrangement = true

        legendStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            legendStack.topAnchor.constraint(equalTo: legendView.topAnchor),
            legendStack.bottomAnchor.constraint(equalTo: legendView.bottomAnchor),
            legendStack.leadingAnchor.constraint(equalTo: legendView.leadingAnchor),
            legendStack.trailingAnchor.constraint(equalTo: legendView.trailingAnchor)
        ])

        legendPhotosLabel.text = NSLocalizedString("legend_photos", tableName: "Dashboard", comment: "")
        legendOtherLabel.text = NSLocalizedString("legend_other", tableName: "Dashboard", comment: "")
        legendFreeLabel.text = NSLocalizedString("legend_free", tableName: "Dashboard", comment: "")
        legendPhotosLabel.textColor = .label
        legendOtherLabel.textColor = .label
        legendFreeLabel.textColor = .label
    }

    private func configureCards() {
        stackViewLowerCards.semanticContentAttribute = .forceLeftToRight
        let cards = [(card1, card1View), (card2, card2View), (card3, card3View), (card4, card4View)]
        cards.forEach { card, view in
            applyShadow(to: view!)
        }
        card1.configure(icon: UIImage(systemName: "wand.and.sparkles")!, color: .systemPurple,
                        title: NSLocalizedString("card1_title", tableName: "Dashboard", comment: ""),
                        subtitle: NSLocalizedString("card1_subtitle", tableName: "Dashboard", comment: ""))
        card2.configure(icon: UIImage(systemName: "chart.pie.fill")!, color: .systemRed,
                        title: NSLocalizedString("card2_title", tableName: "Dashboard", comment: ""),
                        subtitle: NSLocalizedString("card2_subtitle", tableName: "Dashboard", comment: ""))
        card3.configure(icon: UIImage(systemName: "clock.arrow.circlepath")!, color: .systemOrange,
                        title: NSLocalizedString("card3_title", tableName: "Dashboard", comment: ""),
                        subtitle: NSLocalizedString("card3_subtitle", tableName: "Dashboard", comment: ""))
        card4.configure(icon: UIImage(systemName: "info.circle.fill")!, color: .systemBlue,
                        title: NSLocalizedString("card4_title", tableName: "Dashboard", comment: ""),
                        subtitle: NSLocalizedString("card4_subtitle", tableName: "Dashboard", comment: ""))
        stackViewUpperCard.translatesAutoresizingMaskIntoConstraints = false
        stackViewLowerCards.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackViewUpperCard.topAnchor.constraint(equalTo: scanButton.bottomAnchor, constant: 50),
            stackViewUpperCard.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackViewUpperCard.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),

            stackViewLowerCards.topAnchor.constraint(equalTo: stackViewUpperCard.bottomAnchor, constant: 20),
            stackViewLowerCards.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackViewLowerCards.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9)
        ])

    }

    private func configureScanButton() {
        scanButton.setTitle(NSLocalizedString("Scan_Button", tableName: "Dashboard", comment: ""), for: .normal)
        scanButton.addTarget(self, action: #selector(handleScanTap), for: .touchUpInside)
    }

    private func configureRing() {
        ringView = RingProgressView()
        stopSpinningProgressArc()

        ringView.getProgressLayer().isHidden = true
        ringView.getOtherLayer().isHidden = true
        ringView.getBackgroundLayer().isHidden = true


        ringView.translatesAutoresizingMaskIntoConstraints = false
        haloRingView.addSubview(ringView)
        haloRingView.backgroundColor = .systemBackground

        NSLayoutConstraint.activate([
            ringView.centerXAnchor.constraint(equalTo: haloRingView.centerXAnchor),
            ringView.centerYAnchor.constraint(equalTo: haloRingView.centerYAnchor),
            ringView.widthAnchor.constraint(equalToConstant: DashboardStyle.ringSize),
            ringView.heightAnchor.constraint(equalToConstant: DashboardStyle.ringSize)
        ])
    }


    private func configureRocket() {
        self.animationView?.removeFromSuperview()
        self.animationView = nil
        let animation = LottieAnimation.named("rocket")
        animationView = LottieAnimationView(animation: animation)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.backgroundColor = .clear
        haloRingView.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.centerXAnchor.constraint(equalTo: haloRingView.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: haloRingView.centerYAnchor),
            animationView.widthAnchor.constraint(equalToConstant: 200),
            animationView.heightAnchor.constraint(equalToConstant: 200)
        ])
        animationView.play()
    }
    private func configurePersonalImage() {
        personalImageContainer.translatesAutoresizingMaskIntoConstraints = false
        personalImageContainer.layer.shadowColor   = DashboardStyle.personalImageShadowColor.cgColor
        personalImageContainer.layer.shadowOpacity = DashboardStyle.personalImageShadowOpacity
        personalImageContainer.layer.shadowOffset  = DashboardStyle.personalImageShadowOffset
        personalImageContainer.layer.shadowRadius  = DashboardStyle.personalImageShadowRadius
        personalImageContainer.layer.masksToBounds = false
        view.addSubview(personalImageContainer)

        personalImage.translatesAutoresizingMaskIntoConstraints = false
        personalImage.image           = UIImage(named: "user")
        personalImage.contentMode     = .scaleAspectFill
        personalImage.clipsToBounds   = true
        personalImage.layer.cornerRadius   = DashboardStyle.imageSize / 2
        personalImage.layer.borderWidth    = DashboardStyle.personalImageBorderWidth
        personalImage.layer.borderColor    = DashboardStyle.personalImageBorderColor.cgColor
        personalImageContainer.addSubview(personalImage)

        NSLayoutConstraint.activate([
            personalImageContainer.widthAnchor.constraint(equalToConstant: DashboardStyle.imageSize),
            personalImageContainer.heightAnchor.constraint(equalToConstant: DashboardStyle.imageSize),
            personalImageContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant:         DashboardStyle.imageTopOffset),

            personalImage.topAnchor.constraint(equalTo: personalImageContainer.topAnchor),
            personalImage.bottomAnchor.constraint(equalTo: personalImageContainer.bottomAnchor),
            personalImage.leftAnchor.constraint(equalTo: personalImageContainer.leftAnchor),
            personalImage.rightAnchor.constraint(equalTo: personalImageContainer.rightAnchor)
        ])

        let isRTL = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft

        if isRTL {
            personalImageContainer.leftAnchor
                .constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant:         DashboardStyle.imageSideOffset
)
                .isActive = true
        } else {
            personalImageContainer.rightAnchor
                .constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -DashboardStyle.imageSideOffset
)
                .isActive = true
        }
    }

    private func alignView(_ view: UIView, toSafeAreaSideWithOffset offset: CGFloat) {
        let isRTL = UIView.userInterfaceLayoutDirection(for: view.semanticContentAttribute) == .rightToLeft

        if isRTL {
            view.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: offset).isActive = true
        } else {
            view.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -offset).isActive = true
        }
    }
    func updateRingWithPhotoUsage(completion: @escaping () -> Void) {
        guard let disk = self.diskInfo else { return }
        print("percent used: \(disk.percentUsed)")
        ringView.setProgress(mediaPercent: CGFloat(disk.mediaPercentUsed),
                             otherPercent: CGFloat(disk.percentUsed),
                             totalBytes: disk.total)
        completion()
    }
    private func applyShadow(to view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.layer.shadowRadius = 10
        view.layer.masksToBounds = false
        view.clipsToBounds = false
        view.backgroundColor = .clear
    }
    private func showSpinningArcOnly() {
        let layer = ringView.getProgressLayer()

        ringView.getBackgroundLayer().isHidden = true
        ringView.getOtherLayer().isHidden = true

        layer.isHidden = false
        layer.strokeStart = 0.0
        layer.strokeEnd = 0.1

        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 4
        rotation.repeatCount = .infinity
        rotation.timingFunction = CAMediaTimingFunction(name: .linear)

        layer.add(rotation, forKey: "rotation")
    }

    func stopSpinningProgressArc() {
        let layer = ringView.getProgressLayer()
        layer.removeAnimation(forKey: "rotation")

        ringView.getBackgroundLayer().isHidden = false
        ringView.getOtherLayer().isHidden = false
    }


    private func animateSmartCleanCardUp() {
        guard let disk = self.diskInfo else { return }
        let bytesInGB = 1024.0 * 1024.0 * 1024.0
        let totalGB = Double(disk.total) / bytesInGB
        let percent = Double(disk.mediaSizeBytes) / Double(disk.total)
        let estimatedFreed = totalGB * percent

        card1.subtitleLabel.text = String(format: NSLocalizedString("card1_subtitle_edited", tableName: "Dashboard", comment: ""), estimatedFreed)

        UIView.animate(withDuration: 1.0,
                       delay: 0.2,
                       options: [.curveEaseInOut],
                       animations: {
            self.card1View.transform = CGAffineTransform(translationX: 0, y: -30)
            self.card1View.layer.shadowOpacity = 0.7
        })
    }
    private func animateSmartCleanCardDown() {
        UIView.animate(withDuration: 1.0,
                       delay: 0.2,
                       options: [.curveEaseInOut],
                       animations: {
            self.card1View.transform = CGAffineTransform.identity
            self.card1View.layer.shadowOpacity = 0
        })
    }
    private func spawnOrbitingDots(around targetView: UIView, count: Int = 8, radius: CGFloat = 90) {
        let center = CGPoint(x: targetView.bounds.midX, y: targetView.bounds.midY)
        for i in 0..<count {
            let size: CGFloat = CGFloat.random(in: 6...22)
            let dot = UIView()
            let colors: [UIColor] = [.systemBlue, .systemPurple, .systemTeal, .black]
            dot.backgroundColor = colors.randomElement()?.withAlphaComponent(0.5)
            dot.layer.cornerRadius = size / 2
            dot.frame = CGRect(x: 0, y: 0, width: size, height: size)
            dot.center = center
            targetView.addSubview(dot)

            let path = UIBezierPath(
                arcCenter: center,
                radius: radius + CGFloat.random(in: -10...20),
                startAngle: CGFloat(i) * (2 * .pi / CGFloat(count)),
                endAngle: CGFloat(i) * (2 * .pi / CGFloat(count)) + 2 * .pi,
                clockwise: true)

            let animation = CAKeyframeAnimation(keyPath: "position")
            animation.path = path.cgPath
            animation.duration = Double.random(in: 40.0...50.0)
            animation.repeatCount = .infinity
            animation.calculationMode = .paced
            animation.rotationMode = .rotateAuto
            dot.layer.add(animation, forKey: "orbit")
        }
    }
    private func removeOrbitingDots(from targetView: UIView) {
        for subview in targetView.subviews {
            if subview.layer.animation(forKey: "orbit") != nil {
                subview.removeFromSuperview()
            }
        }
    }
}
