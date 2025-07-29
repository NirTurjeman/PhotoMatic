import Foundation
import FirebaseFirestore

class CompressionHistoryManager {
    static let shared = CompressionHistoryManager()
    private let key = "compressionHistory"

    func load() -> [CompressionResult] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let history = try? JSONDecoder().decode([CompressionResult].self, from: data) else {
            return []
        }
        return history
    }
    func loadFromFirestore(completion: @escaping ([CompressionResult]) -> Void) {
        let db = Firestore.firestore()
        let userId = UserManager.shared.userId

        print("👤 Fetching history for userId: \(userId)")

        db.collection("users/\(userId)/compressionHistory")
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in

                if let error = error {
                    print("❌ Firestore fetch error:", error)
                    completion([])
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ No documents found.")
                    completion([])
                    return
                }

                print("📦 Firestore: found \(documents.count) documents")

                var history: [CompressionResult] = []

                for doc in documents {
                    print("📄 Raw data: \(doc.data())")

                    let data = doc.data()

                    guard let timestamp = data["date"] as? Timestamp,
                          let originalsDeleted = data["originalsDeleted"] as? Bool,
                          let backupLocationRaw = data["backupLocation"] as? String,
                          let itemsArray = data["items"] as? [[String: Any]]
                    else {
                        print("⚠️ Skipping invalid document: \(doc.documentID)")
                        continue
                    }

                    let items: [PhotoCompressionRecord] = itemsArray.compactMap { item -> PhotoCompressionRecord? in
                        guard let original = item["originalSize"] as? Double,
                              let compressed = item["compressedSize"] as? Double,
                              let percent = item["savedPercentage"] as? Double
                        else {
                            print("⚠️ Invalid item in session: \(item)")
                            return nil
                        }

                        return PhotoCompressionRecord(
                            originalSize: Int(original),
                            compressedSize: Int(compressed),
                            savedPercentage: percent
                        )
                    }

                    guard let backupLocation = BackupLocation(rawValue: backupLocationRaw) else {
                        print("⚠️ Invalid backupLocation value:", backupLocationRaw)
                        continue
                    }

                    let result = CompressionResult(
                        items: items,
                        date: timestamp.dateValue(),
                        backupLocation: backupLocation,
                        originalsDeleted: originalsDeleted
                    )

                    history.append(result)
                }

                print("✅ Parsed \(history.count) sessions.")
                completion(history)
            }
    }


    func append(_ newResult: CompressionResult) {
        var history = load()
        history.insert(newResult, at: 0)
        save(history)
    }

    private func save(_ history: [CompressionResult]) {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    func saveToFirestore(_ result: CompressionResult) {
        let db = Firestore.firestore()
        let userId = UserManager.shared.userId

        let sessionData: [String: Any] = [
            "date": Timestamp(date: result.date),
            "originalsDeleted": result.originalsDeleted,
            "backupLocation": result.backupLocation?.rawValue,
            "items": result.items.map { item in
                return [
                    "originalSize": item.originalSize,
                    "compressedSize": item.compressedSize,
                    "savedPercentage": item.savedPercentage
                ]
            }
        ]

        db.collection("users")
            .document(userId)
            .collection("compressionHistory")
            .addDocument(data: sessionData) { error in
                if let error = error {
                    print("❌ Firestore save failed:", error)
                } else {
                    print("✅ Saved to Firestore under user \(userId)")
                }
            }
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
