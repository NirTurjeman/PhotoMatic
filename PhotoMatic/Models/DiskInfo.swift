import Foundation

struct DiskInfo {
    let total: Int64              // Total disk size in bytes
    let used: Int64               // Used space in bytes
    let free: Int64               // Free space in bytes
    let mediaSizeBytes: Int64     // Size of photos + videos in bytes

    // MARK: - Raw (bytes → GB)
    var totalGB: Double {
        return Double(total) / pow(1024, 3)
    }

    var usedGB: Double {
        return Double(used) / pow(1024, 3)
    }

    var freeGB: Double {
        return Double(free) / pow(1024, 3)
    }

    var mediaSizeGB: Double {
        return Double(mediaSizeBytes) / pow(1024, 3)
    }

    // MARK: - Percentages
    var percentUsed: Double {
        return total > 0 ? Double(used) / Double(total) : 0
    }

    var percentFree: Double {
        return total > 0 ? Double(free) / Double(total) : 0
    }

    var mediaPercentUsed: Double {
        return total > 0 ? Double(mediaSizeBytes) / Double(total) : 0
    }

    // MARK: - Formatted Strings
    var formattedUsed: String {
        return String(format: "%.1f GB", usedGB)
    }

    var formattedFree: String {
        return String(format: "%.1f GB", freeGB)
    }

    var formattedTotal: String {
        return String(format: "%.0f GB", totalGB)
    }

    var formattedMediaSize: String {
        return String(format: "%.1f GB", mediaSizeGB)
    }

    var formattedPercentUsed: String {
        return String(format: "%.0f%%", percentUsed * 100)
    }

    var formattedMediaPercent: String {
        return String(format: "%.0f%%", mediaPercentUsed * 100)
    }

    var formattedUsedOutOfTotal: String {
        return String(format: "%.1f / %.0f GB", usedGB, totalGB)
    }

    var formattedCleanable: String {
        return String(format: "Free up %.1f GB from photos", mediaSizeGB)
    }
}
