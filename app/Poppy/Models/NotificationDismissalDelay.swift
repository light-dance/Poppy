import Foundation

enum NotificationDismissalDelay: String, CaseIterable, Identifiable {
    static let storageKey = "notificationDismissalDelay"

    case after7Seconds = "7"
    case after10Seconds = "10"
    case after15Seconds = "15"
    case after20Seconds = "20"
    case after30Seconds = "30"
    case never

    var id: String { rawValue }

    var seconds: Int? {
        switch self {
        case .after7Seconds:
            return 7
        case .after10Seconds:
            return 10
        case .after15Seconds:
            return 15
        case .after20Seconds:
            return 20
        case .after30Seconds:
            return 30
        case .never:
            return nil
        }
    }

    var title: String {
        guard let seconds else {
            return "Never"
        }

        return "After \(seconds) Seconds"
    }
}
