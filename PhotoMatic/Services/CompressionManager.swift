import UIKit
import Photos

class CompressionManager {
    
    func compress(image: UIImage, quality: CGFloat = 0.2) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }
    
    func compress(asset: PHAsset, quality: CGFloat = 0.2, completion: @escaping (UIImage?, Data?, Int, Int) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.version = .original
        options.isSynchronous = false

        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
            guard let originalData = data,
                  let image = UIImage(data: originalData),
                  let compressedData = image.jpegData(compressionQuality: quality) else {
                completion(nil, nil, 0, 0)
                return
            }

            let originalSize = originalData.count
            let compressedSize = compressedData.count

            completion(image, compressedData, originalSize, compressedSize)
        }
    }
    func compressImages(
        selectedImages: [SelectedImage],
        quality: CGFloat,
        backupLocation: BackupLocation?,
        originalsDeleted: Bool,
        completion: @escaping ([PhotoData]) -> Void
    ) {
        let manager = CompressionManager()
        var compressedPhotos: [PhotoData] = []
        let group = DispatchGroup()

        for selected in selectedImages {
            group.enter()

            if let asset = selected.asset {
                manager.compress(asset: asset, quality: quality) { image, compressedData, originalSize, compressedSize in
                    if let img = image, let compressedData = compressedData {
                        let compressedImage = UIImage(data: compressedData)
                        let photo = PhotoData(
                            originalImage: img,
                            compressedImage: compressedImage,
                            originalSize: originalSize,
                            compressedSize: compressedSize,
                            asset: asset
                        )
                        compressedPhotos.append(photo)
                    }
                    group.leave()
                }
            } else {
                if let compressedData = manager.compress(image: selected.image, quality: quality),
                   let compressedImage = UIImage(data: compressedData),
                   let originalData = selected.image.jpegData(compressionQuality: 1.0) {
                    let photo = PhotoData(
                        originalImage: selected.image,
                        compressedImage: compressedImage,
                        originalSize: originalData.count,
                        compressedSize: compressedData.count,
                        asset: nil
                    )
                    compressedPhotos.append(photo)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let records = compressedPhotos.map {
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
                originalsDeleted: originalsDeleted
            )

            CompressionHistoryManager.shared.append(result)
            completion(compressedPhotos)
        }
    }

}
