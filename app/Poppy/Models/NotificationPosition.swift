import Foundation

enum NotificationPosition: String, CaseIterable, Identifiable {
    static let storageKey = "notificationPosition"

    case topLeft
    case topCenter
    case topRight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .topLeft:
            return "Top Left"
        case .topCenter:
            return "Top Center"
        case .topRight:
            return "Top Right"
        }
    }
}
