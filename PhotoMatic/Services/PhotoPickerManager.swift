import UIKit
import Photos
import PhotosUI

protocol PhotoPickerDelegate: AnyObject {
    func didFinishSelectingImages()
}

class PhotoPickerManager: NSObject, PHPickerViewControllerDelegate {
    
    weak var presentingViewController: UIViewController?
    weak var delegate: PhotoPickerDelegate?
    let viewModel: ImageSelectionManager 

    init(presentingViewController: UIViewController, viewModel: ImageSelectionManager, delegate: PhotoPickerDelegate? = nil) {
        self.presentingViewController = presentingViewController
        self.viewModel = viewModel
        self.delegate = delegate
    }
    
    func openPhotoPicker() {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.selectionLimit = 0
        config.filter = .images
        config.selection = .default
        config.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        presentingViewController?.present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        let dispatchGroup = DispatchGroup()

        for result in results {
            var asset: PHAsset? = nil

            if let assetId = result.assetIdentifier {
                let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
                asset = fetchResult.firstObject
            }

            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                dispatchGroup.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    defer { dispatchGroup.leave() }
                    guard let self = self else { return }

                    if error != nil {
                        return
                    }

                    guard let uiImage = image as? UIImage else {
                        return
                    }

                    DispatchQueue.main.async {
                        self.viewModel.add(image: uiImage, asset: asset)
                    }
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.delegate?.didFinishSelectingImages()
        }
    }
}
