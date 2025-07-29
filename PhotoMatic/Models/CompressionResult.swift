import Foundation

struct CompressionResult: Codable {
    let items: [PhotoCompressionRecord]
    let date: Date
    let backupLocation: BackupLocation?
    let originalsDeleted: Bool

    var totalOriginalSize: Int {
        items.reduce(0) { $0 + $1.originalSize }
    }

    var totalCompressedSize: Int {
        items.reduce(0) { $0 + $1.compressedSize }
    }

    var savedSpaceInMB: Double {
        Double(totalOriginalSize - totalCompressedSize) / 1024.0 / 1024.0
    }

    var averageSavedPercent: Double {
        guard !items.isEmpty else { return 0 }
        return items.map { $0.savedPercentage }.reduce(0, +) / Double(items.count)
    }
}

