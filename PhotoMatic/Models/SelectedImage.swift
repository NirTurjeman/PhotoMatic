// MARK: - SelectedImage (Model)
import UIKit
import Photos

struct SelectedImage {
    let image: UIImage
    let asset: PHAsset?
}

struct PhotoData {
    let originalImage: UIImage
    let compressedImage: UIImage?
    let originalSize: Int // in bytes
    let compressedSize: Int // in bytes
    let asset: PHAsset?

    var savedSpaceInMB: Double {
        let delta = Double(originalSize - compressedSize) / 1024.0 / 1024.0
        print("Delta: \(delta) MB")
        return delta
    }
    var savedPercentage: Double {
        guard originalSize > 0 else { return 0 }
        return 1.0 - (Double(compressedSize) / Double(originalSize))
    }
    var originalSizeInBytes: Int? {
        guard let asset = asset else { return nil }
        return Int(asset.value(forKey: "fileSize") as? Int64 ?? 0)
    }

    var compressedSizeInBytes: Int? {
        return compressedImage?.jpegData(compressionQuality: 1.0)?.count
    }
}

