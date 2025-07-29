import Photos
import UIKit
// MARK: - PhotoAlbumManager
class PhotoAlbumManager {
    static let albumName = "PhotoMatic"
    private var assetCollection: PHAssetCollection?

    init() {
        fetchOrCreateAlbum()
    }

    private func fetchOrCreateAlbum() {
        if let collection = Self.fetchAlbum() {
            assetCollection = collection
        } else {
            createAlbum()
        }
    }

    private static func fetchAlbum() -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        return collections.firstObject
    }

    private func createAlbum() {
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: Self.albumName)
        }) { success, error in
            if success {
                self.assetCollection = Self.fetchAlbum()
            }
        }
    }

    func saveImage(_ image: UIImage) {
        guard let album = assetCollection else {
            return
        }

        PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            if let albumChangeRequest = PHAssetCollectionChangeRequest(for: album),
               let placeholder = request.placeholderForCreatedAsset {
                albumChangeRequest.addAssets([placeholder] as NSArray)
            }
        } 
    }
} 
