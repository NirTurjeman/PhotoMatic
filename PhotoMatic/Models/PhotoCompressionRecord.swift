import Foundation

struct PhotoCompressionRecord: Codable {
    let originalSize: Int
    let compressedSize: Int
    let savedPercentage: Double
}
