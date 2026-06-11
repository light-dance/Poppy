import Foundation

enum InstallableKind: Equatable {
    case diskImage
    case appBundle
    case zipArchive

    init?(url: URL) {
        switch url.pathExtension.lowercased() {
        case "dmg":
            self = .diskImage
        case "app":
            self = .appBundle
        case "zip":
            self = .zipArchive
        default:
            return nil
        }
    }
}

struct InstallableItem: Identifiable, Equatable {
    enum Status: Equatable {
        case ready
        case installing(String, startedAt: Date?)
        case installed(appURL: URL, installedAt: Date?)
    }

    var id: String { url.path }
    let url: URL
    let kind: InstallableKind
    let status: Status
    let metadataDate: Date?
    let sizeBytes: Int64?

    var displayName: String {
        url.deletingPathExtension().lastPathComponent
    }
}
