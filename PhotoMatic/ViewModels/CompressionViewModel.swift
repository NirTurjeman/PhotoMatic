// MARK: - CompressionViewModel

import UIKit
import Photos
// MARK: - CompressionViewModel
class CompressionViewModel {
    private let compressionManager = CompressionManager()
    private(set) var compressedPhotos: [PhotoData] = []
    private let storageService = StorageService()
    private var albumManager = PhotoAlbumManager()
   
    func compress(image: UIImage, asset: PHAsset?, quality: CGFloat = 0.2, completion: @escaping (PhotoData?) -> Void) {
        if let asset = asset {
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            options.version = .original
            options.isSynchronous = false

            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                guard let originalData = data,
                      let fullImage = UIImage(data: originalData),
                      let compressedData = fullImage.jpegData(compressionQuality: quality),
                      let compressedImage = UIImage(data: compressedData) else {
                    completion(nil)
                    return
                }

                let photo = PhotoData(
                    originalImage: fullImage,
                    compressedImage: compressedImage,
                    originalSize: originalData.count,
                    compressedSize: compressedData.count,
                    asset: asset
                )
                self.compressedPhotos.append(photo)
                completion(photo)
            }
        } else {
            guard let compressedData = image.jpegData(compressionQuality: quality),
                  let compressedImage = UIImage(data: compressedData) else {
                completion(nil)
                return
            }

            let originalData = image.jpegData(compressionQuality: 1.0)
            let originalSize = originalData?.count ?? 0
            let compressedSize = compressedData.count

            let photo = PhotoData(
                originalImage: image,
                compressedImage: compressedImage,
                originalSize: originalSize,
                compressedSize: compressedSize,
                asset: nil
            )
            self.compressedPhotos.append(photo)
            completion(photo)
        }
    }



    func getOriginalAssetSize(asset: PHAsset?, completion: @escaping (Int) -> Void) {
        guard let asset = asset else {
            completion(0)
            return
        }

        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
            completion(data?.count ?? 0)
        }
    }

    func saveAllCompressedImagesToPhotoLibrary() {
        for photo in compressedPhotos {
            if let compressed = photo.compressedImage {
                albumManager.saveImage(compressed)
            }
        }
    }

       func saveCompressedImage(_ photo: PhotoData, completion: @escaping (Result<Void, Error>) -> Void) {
           guard let image = photo.compressedImage else {
               completion(.failure(NSError(domain: "Image missing", code: 0)))
               return
           }
           albumManager.saveImage(image)
           completion(.success(()))
       }

       func summaryText(for photo: PhotoData) -> String {
           return String(format: "נשמרו %.2fMB (%.0f%% חיסכון)",
                         photo.savedSpaceInMB,
                         photo.savedPercentage * 100)
       }

    func getCompressionResult() -> CompressionResult {
        let records: [PhotoCompressionRecord] = compressedPhotos.map {
            PhotoCompressionRecord(
                originalSize: $0.originalSize,
                compressedSize: $0.compressedSize,
                savedPercentage: $0.savedPercentage
            )
        }

        let result: CompressionResult = CompressionResult(
            items: records,
            date: Date(),
            backupLocation: nil,
            originalsDeleted: false
        )

        return result
    }




        func totalSpaceSaved() -> Double {
            let comPhoto = compressedPhotos.reduce(0) { $0 + $1.savedSpaceInMB }
            print("Compressed space saved: \(comPhoto)MB")
            return comPhoto
    }
       func reset() {
           compressedPhotos.removeAll()
       }
   }
