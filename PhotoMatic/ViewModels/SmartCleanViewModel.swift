import UIKit
import Photos

class SmartCleanViewModel {
    let imageModel = ImageSelectionManager()

    var imageCountText: String {
        let count = imageModel.imageCount()
        let sizeInGB = totalImageSizeInGB()
        let sizeText = String(format: "%.2f", sizeInGB)
        return String(
                format: NSLocalizedString("selected_images_info",
                                          tableName: "SmartClean",
                                          comment: "Info about how many images were selected and total size"),
                count,
                sizeText
            )
    }
    func addImage(_ image: UIImage, asset: PHAsset?) {
        imageModel.add(image: image, asset: asset)
    }
    func deleteOriginalAssets() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            if status == .authorized {
                let assetsToDelete = self.imageModel.selectedImages.compactMap { $0.asset }

                guard !assetsToDelete.isEmpty else {
                    return
                }

                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.deleteAssets(assetsToDelete as NSArray)
                }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                        }
                    }
                }
            }
        }
    }

    func getAllImages() -> [SelectedImage] {
        return imageModel.selectedImages
    }

    func getAllAssets() -> [PHAsset] {
        return imageModel.allAssets()
    }
    
    func removeImage(at index: Int) {
        imageModel.removeImage(at: index)
    }

    func canContinue() -> Bool {
        return !imageModel.selectedImages.isEmpty
    }

    private func totalImageSizeInGB() -> Double {
        let totalBytes = imageModel.selectedImages.reduce(0) { total, selected in
            if let data = selected.image.jpegData(compressionQuality: 1.0) {
                return total + Double(data.count)
            }
            return total
        }

        return totalBytes / (1024 * 1024 * 1024) // GB
    }

}
