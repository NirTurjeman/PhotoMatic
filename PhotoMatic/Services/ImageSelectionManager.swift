// MARK: - ImageSelectionManager

import Photos
import UIKit
class ImageSelectionManager {
    private(set) var selectedImages: [SelectedImage] = []

    func add(image: UIImage, asset: PHAsset?) {
        selectedImages.append(SelectedImage(image: image, asset: asset))
    }

    func removeImage(at index: Int) {
        guard selectedImages.indices.contains(index) else { return }
        selectedImages.remove(at: index)
    }

    func clearImages() {
        selectedImages.removeAll()
    }

    func imageCount() -> Int {
        return selectedImages.count
    }

    func image(at index: Int) -> UIImage? {
        guard selectedImages.indices.contains(index) else { return nil }
        return selectedImages[index].image
    }

    func allUIImages() -> [UIImage] {
        return selectedImages.map { $0.image }
    }

    func allAssets() -> [PHAsset] {
        return selectedImages.compactMap { $0.asset }
    }
}
