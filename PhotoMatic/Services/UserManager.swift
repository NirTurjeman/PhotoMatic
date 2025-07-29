import Foundation
class UserManager {
    static let shared = UserManager()

    private let userDefaults = UserDefaults.standard
    private let key = "user_id"

    var userId: String {
        if let existing = userDefaults.string(forKey: key) {
            return existing
        } else {
            let newId = UUID().uuidString
            userDefaults.set(newId, forKey: key)
            return newId
        }
    }
}
