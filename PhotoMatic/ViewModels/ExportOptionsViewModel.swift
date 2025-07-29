import UIKit
import ZIPFoundation

class ExportOptionsViewModel {

    func generateTempImageURLs(from images: [SelectedImage]) -> [URL] {
        var urls: [URL] = []
        
        for (index, selected) in images.enumerated() {
            let filename = "Photo_\(index + 1).jpg"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            
            if let data = selected.image.jpegData(compressionQuality: 1.0) {
                do {
                    try data.write(to: tempURL)
                    urls.append(tempURL)
                } catch {
                    print("❌ Error saving temp file: \(error)")
                }
            }
        }
        return urls
    }
    
    func generateZip(from images: [SelectedImage]) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let archiveURL = tempDir.appendingPathComponent("PhotoMatic_Images.zip")
        
        do {
            if FileManager.default.fileExists(atPath: archiveURL.path) {
                try FileManager.default.removeItem(at: archiveURL)
            }
            
            let archive = try Archive(url: archiveURL, accessMode: .create)
            
            for (index, selected) in images.enumerated() {
                let fileName = "Image_\(index + 1).jpg"
                let fileURL = tempDir.appendingPathComponent(fileName)
                
                if let data = selected.image.jpegData(compressionQuality: 1.0) {
                    try data.write(to: fileURL)
                    try archive.addEntry(with: fileName, fileURL: fileURL)
                    try FileManager.default.removeItem(at: fileURL)
                }
            }
            return archiveURL
        } catch {
            print("❌ Error creating archive: \(error)")
            return nil
        }
    }
}
