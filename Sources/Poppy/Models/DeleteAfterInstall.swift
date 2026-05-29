import Foundation

enum DeleteAfterInstall {
    static let storageKey = "deleteAfterInstall"

    static var isEnabled: Bool {
        guard UserDefaults.standard.object(forKey: storageKey) != nil else {
            return true
        }

        return UserDefaults.standard.bool(forKey: storageKey)
    }
}
