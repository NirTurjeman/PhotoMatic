import UIKit
import Photos

class StorageService {
    
    enum StorageError: Error {
        case permissionDenied
    }
    
    // MARK: - Permissions
    
    func requestPhotoPermissionIfNeeded(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        default:
            completion(false)
        }
    }
    
    // MARK: - Save to Photos
    
    func saveToPhotoLibrary(image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        requestPhotoPermissionIfNeeded { granted in
            guard granted else {
                completion(.failure(StorageError.permissionDenied))
                return
            }
            
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            completion(.success(()))
        }
    }

    // MARK: - Disk Info (only disk)
    
    func getDiskSpaceInfo() -> DiskInfo {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory())
        if let values = try? fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey]),
           let free = values.volumeAvailableCapacityForImportantUsage,
           let total = values.volumeTotalCapacity {
            
            let used = Int64(total) - Int64(free)
            return DiskInfo(total: Int64(total), used: used, free: Int64(free), mediaSizeBytes: 0)
        } else {
            return DiskInfo(total: 0, used: 0, free: 0, mediaSizeBytes: 0)
        }
    }

    // MARK: - Photo & Video Size (only media size)

    func calculateTotalPhotoAndVideoSize(completion: @escaping (_ mediaSizeBytes: Int64) -> Void) {
        var totalSize: Int64 = 0

        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d || mediaType == %d",
                                             PHAssetMediaType.image.rawValue,
                                             PHAssetMediaType.video.rawValue)

        let assets = PHAsset.fetchAssets(with: fetchOptions)
        let group = DispatchGroup()

        for i in 0..<assets.count {
            let asset = assets[i]
            group.enter()

            DispatchQueue.global(qos: .background).async {
                let resources = PHAssetResource.assetResources(for: asset)
                var assetSize: Int64 = 0
                for resource in resources {
                    if let size = resource.value(forKey: "fileSize") as? Int64 {
                        assetSize += size
                    }
                }

                DispatchQueue.main.async {
                    totalSize += assetSize
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion(totalSize)
        }
    }

    // MARK: - Disk Info (combined)

    func getCompleteDiskInfo(completion: @escaping (DiskInfo) -> Void) {
        let baseDiskInfo = getDiskSpaceInfo()
        
        calculateTotalPhotoAndVideoSize { mediaSizeBytes in
            let fullInfo = DiskInfo(
                total: baseDiskInfo.total,
                used: baseDiskInfo.used,
                free: baseDiskInfo.free,
                mediaSizeBytes: mediaSizeBytes
            )
            completion(fullInfo)
        }
    }

    // MARK: - Media Count

    public func fetchPhotoAndVideoCounts(completion: @escaping (_ images: Int, _ videos: Int, _ total: Int) -> Void) {
        let images = PHAsset.fetchAssets(with: .image, options: nil).count
        let videos = PHAsset.fetchAssets(with: .video, options: nil).count
        let total = images + videos
        completion(images, videos, total)
    }
}
