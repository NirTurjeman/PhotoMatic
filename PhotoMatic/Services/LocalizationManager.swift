import Foundation

class LocalizationManager {
    static let shared = LocalizationManager()
    private init() {}

    var currentLanguage: String {
        get {
            UserDefaults.standard.string(forKey: "profile_Language") ?? "English"
        }
    }

    func setLanguage(_ language: String) {
        UserDefaults.standard.set(language, forKey: "profile_Language")

        let languageCode = (language == "Hebrew") ? "he" : "en"
        Bundle.setLanguage(languageCode)
    }
}
extension Bundle {
    private static var bundleKey: UInt8 = 0

    static func setLanguage(_ language: String) {
        defer {
            object_setClass(Bundle.main, PrivateBundle.self)
        }
        objc_setAssociatedObject(Bundle.main, &bundleKey, Bundle(path: Bundle.main.path(forResource: language, ofType: "lproj")!), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private class PrivateBundle: Bundle {
        override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
            guard let bundle = objc_getAssociatedObject(self, &Bundle.bundleKey) as? Bundle else {
                return super.localizedString(forKey: key, value: value, table: tableName)
            }
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
    }
}
