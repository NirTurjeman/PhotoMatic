import UIKit
import ZIPFoundation
import SwiftUI
import Lottie
import PhotosUI
import FirebaseFirestore
import FirebaseDatabase
class SmartCleanViewController: UIViewController ,PhotoPickerDelegate{
    
    @IBOutlet weak var imageInfoText: UITextView!
    @IBOutlet weak var stepsInfoText: UITextView!
    @IBOutlet weak var selectPhotosView: UIView! //Background View with corner radius
    @IBOutlet weak var animationView: UIView! // image of lottie animation
    @IBOutlet weak var selectPhotosLabel: UILabel! // label in selectPhotosView
    @IBOutlet weak var step1Label: UILabel!
    @IBOutlet weak var nextStepButton: UIButton!
    private var PhotosGalleryAnimation: LottieAnimationView!
    private let viewModel = SmartCleanViewModel()
    private var stepCounter = 1
    private var photoPickerManager: PhotoPickerManager!
    @IBOutlet weak var photosCount: UILabel!
    //step 2
    @IBOutlet weak var backupView: UIStackView!
    @IBOutlet weak var card1View: UIView!
    @IBOutlet weak var card2View: UIView!
    @IBOutlet weak var card3View: UIView!
    
    @IBOutlet weak var NoBackupLabel: UILabel!
    @IBOutlet weak var ArchiveLabel: UILabel!
    @IBOutlet weak var cloudServiceLabel: UILabel!
    private let exportViewModel = ExportOptionsViewModel()
    private var backupLocation: BackupLocation!
    //step 3
    @IBOutlet weak var qualitySliderView: UIView!
    @IBOutlet weak var qualitySlider: UISlider!
    @IBOutlet weak var persentView: UIView!
    @IBOutlet weak var PersentViewTitle: UILabel!
    @IBOutlet weak var persentLabel: UILabel!
    @IBOutlet weak var smallerSizeLabel: UILabel!
    @IBOutlet weak var originalSizeLabel: UILabel!
    @IBOutlet weak var deleteAfterBackupSwitch: UISwitch!
    private var deleteAfterBackup: Bool = false
    @IBOutlet weak var loadingAniamtion: UIView!
    @IBOutlet weak var compressionProgLabel: UILabel!
    private var progressAnimation: LottieAnimationView!
    private var compressionVM : CompressionViewModel!
    private var storageService: StorageService!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.storageService = StorageService()
        setupInitalizeUI()
    }
    //MARK: - GENERAL FUNC
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("alert_ok", tableName: "SmartClean", comment: ""), style: .default))
        present(alert, animated: true)
    }

    //MARK: - NEXT STEP
    
    @IBAction func didTapNextStep(_ sender: Any) {
        switch(stepCounter){
        case 1:
            if !viewModel.canContinue() {
                let alert = UIAlertController(title: NSLocalizedString("Warning", tableName: "SmartClean", comment: ""),
                                              message: NSLocalizedString("warning_select_photo", tableName: "SmartClean", comment: ""),
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("alert_ok", tableName: "SmartClean", comment: ""), style: .default))
                present(alert, animated: true)
                return
            }
            setupNextStepUI()
            configureGestures()
            stepCounter += 1

            break
        case 2:
            setupNextStepUI()
            stepCounter += 1
            break
        case 3:

            if  !deleteAfterBackupSwitch.isHidden && deleteAfterBackupSwitch.isOn {
                deleteAfterBackup = true
            }else{
                deleteAfterBackup = false
            }
            setupNextStepUI()
            if startCompress(quality: CGFloat(qualitySlider.value) ,deleteOriginal: deleteAfterBackup,backupLocation: backupLocation) {
                
                guard deleteAfterBackup else {
                    setupNextStepUI()
                    return
                }

                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    guard status == .authorized || status == .limited else {
                        return
                    }

                    DispatchQueue.main.async {
                        let alert = UIAlertController(
                            title: NSLocalizedString("delete_originals", tableName: "SmartClean", comment: ""),
                            message: NSLocalizedString("Are_You_Sure", tableName: "SmartClean", comment: ""),
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: NSLocalizedString("delete", tableName: "SmartClean", comment: ""), style: .destructive) { _ in
                            self.viewModel.deleteOriginalAssets()
                        })
                        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", tableName: "SmartClean", comment: ""), style: .cancel))
                        self.present(alert, animated: true)
                    }
                }

                stepCounter += 1
                setupNextStepUI()

            } else {
                stepCounter -= 1
                setupNextStepUI()

                let alert = UIAlertController(
                    title: NSLocalizedString("compression_failed", tableName: "SmartClean", comment: ""),
                    message: "Could not compress the selected photos. Please try again.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }

            break
        case 4:
            self.navigationController?.popToRootViewController(animated: true)
            break
        default: break
            
        }
    }
    
    //MARK: - SLIDER
    @IBAction func sliderTouchDown(_ sender: UISlider) {
        persentLabel.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.persentView.alpha = 1.0
        }
    }
    
    @IBAction func sliderTouchUp(_ sender: UISlider) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            UIView.animate(withDuration: 0.2, animations: {
                self.persentView.alpha = 0.0
            }) { _ in
                self.persentView.isHidden = true
            }
        }
    }
    
    @IBAction func didChangeSlider(_ sender: UISlider) {
        let percent = Int(sender.value)
        persentLabel.text = "\(percent)%"
        persentView.alpha = 1.0
        persentView.isHidden = false
        updateBubblePosition()
    }
    private func updateBubblePosition() {
        let trackRect = qualitySlider.trackRect(forBounds: qualitySlider.bounds)
        let thumbRect = qualitySlider.thumbRect(forBounds: qualitySlider.bounds, trackRect: trackRect, value: qualitySlider.value)
        
        let sliderOrigin = qualitySlider.frame.origin
        let bubbleX = sliderOrigin.x + thumbRect.origin.x + (thumbRect.width / 2) - (persentView.frame.width / 2)
        let bubbleY = qualitySlider.frame.origin.y - persentView.frame.height + 15
        
        persentView.frame.origin = CGPoint(x: bubbleX, y: bubbleY)
    }
    
    //MARK: - COMPRESS STEP
    private func startCompress(quality: CGFloat,deleteOriginal:Bool,backupLocation: BackupLocation) -> Bool {
        compressionVM = CompressionViewModel()
        let selectedImages = viewModel.getAllImages()
        guard !selectedImages.isEmpty else {
            return false
        }

        let group = DispatchGroup()
        var didCompressAny = false
        var compressedPhotos: [PhotoData] = []

        for selected in selectedImages {
            group.enter()
            compressionVM.compress(image: selected.image, asset: selected.asset, quality: quality) { photoData in
                if let data = photoData {
                    didCompressAny = true
                    compressedPhotos.append(data)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if didCompressAny {
                self.compressionVM.saveAllCompressedImagesToPhotoLibrary()

                let records: [PhotoCompressionRecord] = compressedPhotos.map {
                    PhotoCompressionRecord(
                        originalSize: $0.originalSize,
                        compressedSize: $0.compressedSize,
                        savedPercentage: $0.savedPercentage
                    )
                }

                let result = CompressionResult(
                    items: records,
                    date: Date(),
                    backupLocation: backupLocation, 
                    originalsDeleted: deleteOriginal
                )

                CompressionHistoryManager.shared.append(result)
                CompressionHistoryManager.shared.saveToFirestore(result)
                let ref = Database.database().reference()
                let userId = UserManager.shared.userId

                self.storageService.fetchPhotoAndVideoCounts { images, videos, total in
                    print("📷 Total assets to save: \(total)")
                    ref.child("users/\(userId)/lastAssetCount").setValue(total) { error, _ in
                        if let error = error {
                            print("❌ Save failed: \(error.localizedDescription)")
                        } else {
                            print("✅ Successfully saved total = \(total) to Realtime DB")
                        }
                    }
                }

                let saved = self.compressionVM.totalSpaceSaved()
                self.photosCount.text = String(format: NSLocalizedString("total_space_saved", tableName: "SmartClean", comment: ""), saved)

                let alert = UIAlertController(
                    title: NSLocalizedString("compression_complete", tableName: "SmartClean", comment: ""),
                    message: String(format: NSLocalizedString("total_space_saved", tableName: "SmartClean", comment: ""), saved),
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: NSLocalizedString("ok", tableName: "SmartClean", comment: ""), style: .default))
                self.present(alert, animated: true)
            } else {
                print("⚠️ No images were compressed.")
            }
        }

        return true
    }
    
    //MARK: - TAP CARD
    private func configureGestures() {
        addTapGesture(to: card1View, action: #selector(handleCard1Tap))
        addTapGesture(to: card2View, action: #selector(handleCard2Tap))
        addTapGesture(to: card3View, action: #selector(handleCard3Tap))
    }
    
    private func addTapGesture(to view: UIView, action: Selector) {
        let tapGesture = UITapGestureRecognizer(target: self, action: action)
        view.addGestureRecognizer(tapGesture)
        view.isUserInteractionEnabled = true
    }
    @objc private func handleCard1Tap() {
        backupLocation = BackupLocation.iCloud
        highlightCard(card1View)

        let selectedImages = viewModel.getAllImages()
        let tempURLs = exportViewModel.generateTempImageURLs(from: selectedImages)

        guard !tempURLs.isEmpty else {
            showAlert(title: "No Images", message: "No images available to share.")
            return
        }

        let activityVC = UIActivityViewController(activityItems: tempURLs, applicationActivities: nil)
        activityVC.excludedActivityTypes = [.addToReadingList, .assignToContact]
        present(activityVC, animated: true)
    }

    @objc private func handleCard2Tap() {
        backupLocation = BackupLocation.Archive
        highlightCard(card2View)
        let selectedImages = viewModel.getAllImages()
        guard let archiveURL = exportViewModel.generateZip(from: selectedImages) else {
            showAlert(title: "Export Failed", message: "Could not generate ZIP file.")
            return
        }

        let activityVC = UIActivityViewController(activityItems: [archiveURL], applicationActivities: nil)
        activityVC.excludedActivityTypes = [.addToReadingList, .assignToContact]
        present(activityVC, animated: true)
    }

    
    
    @objc private func handleCard3Tap() {
        backupLocation = BackupLocation.none
        highlightCard(card3View)
    }
    private func highlightCard(_ selectedCard: UIView?) {
        let allCards: [UIView?] = [card1View, card2View, card3View]
        
        for card in allCards {
            guard let card = card else { continue }
            
            if card == selectedCard {
                card.layer.borderWidth = 2
                card.layer.borderColor = UIColor.systemBlue.cgColor
                card.layer.cornerRadius = 12
            } else {
                card.layer.borderWidth = 0
                card.layer.borderColor = nil
            }
        }
    }
    //MARK: - SELECT PHOTOS
    private func setupSelectPhotos() {
        selectPhotosView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapSelectPhotos))
        selectPhotosView.addGestureRecognizer(tapGesture)
    }
    @objc private func didTapSelectPhotos() {
        
        selectPhotosLabel.text = NSLocalizedString("select_photos_prompt", tableName: "SmartClean", comment: "")
        selectPhotosLabel.font = UIFont(name: "AvenirNext-Medium", size: 13)
        selectPhotosLabel.textColor = .darkGray
        photoPickerManager = PhotoPickerManager(
            presentingViewController: self,
            viewModel: viewModel.imageModel,
            delegate: self
        )

        photoPickerManager.openPhotoPicker()//create picker
    }
    func didFinishSelectingImages() {
        selectPhotosLabel.text = NSLocalizedString("select_photos_complete", tableName: "SmartClean", comment: "")
        photosCount.text = viewModel.imageCountText
        photosCount.isHidden = false
    }
    //MARK: - UI-SETUP
    private func applyShadow(to view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.layer.shadowRadius = 10
        view.layer.masksToBounds = false
        view.clipsToBounds = false
    }
    private func setupInitalizeUI(){
        setupImageInfoText()
        setupStepsInfo(text: NSLocalizedString("select_photos_to_compress", tableName: "SmartClean", comment: ""))
        configurePhotosAnimationAndUI()
        setupSelectPhotos()
        self.step1Label.textAlignment = .natural
        step1Label.textColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? .white : .black
        }
        self.step1Label.text = NSLocalizedString("step1_title", tableName: "SmartClean", comment: "")
        self.photosCount.isHidden = true
        self.qualitySliderView.isHidden = true
        nextStepButton.setTitle(
            NSLocalizedString("next_button", tableName: "SmartClean", comment: ""),
            for: .normal
        )
        applyCardBackgrounds()
    }
    private func applyCardBackgrounds() {
        let cards = [card1View, card2View, card3View]
        for card in cards {
            card?.backgroundColor = UIColor { trait in
                if trait.userInterfaceStyle == .dark {
                    return UIColor.systemGray4
                } else {
                    return UIColor.white
                }
            }
        }
    }

    private func setupImageInfoText() {
        let firstWord = NSLocalizedString("firstWordinfoText", tableName: "SmartClean", comment: "")
        let restOfBody = NSLocalizedString("restOfBodyinfoText", tableName: "SmartClean", comment: "")
    
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5

        let firstWordAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "AvenirNext-Medium", size: 32)!,
        ]

        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont(name: "AvenirNext-Regular", size: 18)!,
        ]
        
        let fullText = NSMutableAttributedString(string: firstWord, attributes: firstWordAttributes)
        fullText.append(NSAttributedString(string: restOfBody, attributes: bodyAttributes))
        imageInfoText.attributedText = fullText
        imageInfoText.textAlignment = .natural
        imageInfoText.isEditable = false
        imageInfoText.isScrollEnabled = false
        imageInfoText.backgroundColor = .clear
        imageInfoText.textContainerInset = UIEdgeInsets(top: 12, left: 5, bottom: 12, right: 5)
        imageInfoText.layer.cornerRadius = 12
        
        
    }
    private func setupStepsInfo(text: String) {
        let body = text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        let dynamicColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? .white : .black
        }
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont(name: "AvenirNext-Regular", size: 18)!,
            .foregroundColor: dynamicColor
        ]
        
        let attributedText = NSAttributedString(string: body, attributes: bodyAttributes)
        stepsInfoText.attributedText = attributedText
        stepsInfoText.textAlignment = .natural
        stepsInfoText.isEditable = false
        stepsInfoText.isScrollEnabled = false
        stepsInfoText.isUserInteractionEnabled = false
        
    }
    
    private func configurePhotosAnimationAndUI() {
        let animation = LottieAnimation.named("photos")
        PhotosGalleryAnimation = LottieAnimationView(animation: animation)
        PhotosGalleryAnimation.translatesAutoresizingMaskIntoConstraints = false
        PhotosGalleryAnimation.contentMode = .scaleAspectFit
        PhotosGalleryAnimation.loopMode = .autoReverse
        PhotosGalleryAnimation.backgroundColor = .clear
        
        selectPhotosView.layer.shadowColor = UIColor.black.cgColor
        selectPhotosView.layer.shadowOpacity = 0.15
        selectPhotosView.layer.shadowOffset = CGSize(width: 0, height: 4)
        selectPhotosView.layer.shadowRadius = 8
        selectPhotosView.layer.masksToBounds = false
        
        animationView.addSubview(PhotosGalleryAnimation)
        selectPhotosLabel.translatesAutoresizingMaskIntoConstraints = false
        selectPhotosLabel.font = UIFont(name: "AvenirNext-Medium", size: 15)
        selectPhotosLabel.text = NSLocalizedString("select_photos", tableName: "SmartClean", comment: "")
        selectPhotosLabel.textColor = .label
        
        NSLayoutConstraint.activate([
            selectPhotosLabel.centerXAnchor.constraint(equalTo: selectPhotosView.centerXAnchor),
            selectPhotosLabel.centerYAnchor.constraint(equalTo: selectPhotosView.bottomAnchor, constant: -15),
            PhotosGalleryAnimation.centerXAnchor.constraint(equalTo: animationView.centerXAnchor),
            PhotosGalleryAnimation.centerYAnchor.constraint(equalTo: animationView.centerYAnchor),
            PhotosGalleryAnimation.widthAnchor.constraint(equalToConstant: 80),
            PhotosGalleryAnimation.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        PhotosGalleryAnimation.play()
    }
    private func setupNextStepUI() {
        switch(stepCounter){
        case 1:
                step1Label.text = NSLocalizedString("step2_title", tableName: "SmartClean", comment: "")
                setupStepsInfo(text: NSLocalizedString("select_backup_method", tableName: "SmartClean", comment: ""))
            cloudServiceLabel.text = NSLocalizedString("cloud_service_label", tableName: "SmartClean", comment: "")
            ArchiveLabel.text = NSLocalizedString("archive_label", tableName: "SmartClean", comment: "")
            NoBackupLabel.text = NSLocalizedString("no_backup_label", tableName: "SmartClean", comment: "")
            cloudServiceLabel.textAlignment = .center
            cloudServiceLabel.textColor = .label
            ArchiveLabel.textAlignment = .center
            ArchiveLabel.textColor = .label
            NoBackupLabel.textAlignment = .center
            NoBackupLabel.textColor = .label
                selectPhotosView.isHidden = true
                backupView.isHidden = false
                backupView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    backupView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    backupView.centerYAnchor.constraint(equalTo: selectPhotosView.centerYAnchor)
                ])
            
                applyShadow(to: card1View)
                applyShadow(to: card2View)
                applyShadow(to: card3View)
            break
        case 2:
            step1Label.text = NSLocalizedString("step3_title", tableName: "SmartClean", comment: "")
            setupStepsInfo(text: NSLocalizedString("choose_compression_quality", tableName: "SmartClean", comment: ""))
            backupView.isHidden = true
            self.qualitySliderView.isHidden = false
            self.qualitySliderView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                self.qualitySliderView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                self.qualitySliderView.centerYAnchor.constraint(equalTo: selectPhotosView.centerYAnchor, constant: 40)
            ])
            break
        case 3:
            step1Label.text = NSLocalizedString("finish_button", tableName: "SmartClean", comment: "")
            setupStepsInfo(text: NSLocalizedString("finished_compressing_title", tableName: "SmartClean", comment: ""))
            qualitySliderView.isHidden = true
            photosCount.isHidden = true
            nextStepButton.isHidden = true
            loadingAniamtion.isHidden = false

            let animation = LottieAnimation.named("loading")
            progressAnimation = LottieAnimationView(animation: animation)
            progressAnimation.contentMode = .scaleAspectFit
            progressAnimation.backgroundColor = .clear
            progressAnimation.loopMode = .loop

            progressAnimation.translatesAutoresizingMaskIntoConstraints = false
            loadingAniamtion.translatesAutoresizingMaskIntoConstraints = false
            loadingAniamtion.backgroundColor = .clear
            loadingAniamtion.addSubview(progressAnimation)

            NSLayoutConstraint.activate([
                loadingAniamtion.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                loadingAniamtion.centerYAnchor.constraint(equalTo: stepsInfoText.centerYAnchor,constant: 50),
                
                progressAnimation.centerXAnchor.constraint(equalTo: loadingAniamtion.centerXAnchor),
                progressAnimation.centerYAnchor.constraint(equalTo: loadingAniamtion.centerYAnchor),
                progressAnimation.widthAnchor.constraint(equalTo: loadingAniamtion.widthAnchor),
                progressAnimation.heightAnchor.constraint(equalTo: loadingAniamtion.heightAnchor)
            ])
            progressAnimation.play()
        case 4:
            nextStepButton.isHidden = false
            nextStepButton.setTitle("Finish", for: .normal)
            photosCount.isHidden = false
            compressionProgLabel.text = NSLocalizedString("finished_compressing", tableName: "SmartClean", comment: "")
        default:break
            }
        }
    }
