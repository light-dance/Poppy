import Foundation

struct InstallJob: Identifiable, Equatable {
    enum State: Equatable {
        case awaitingApproval
        case installing(String)
        case installed(appURL: URL)
        case failed(String)
    }

    let id = UUID()
    let dmgURL: URL
    var appName: String?
    var state: State

    var displayName: String {
        appName ?? dmgURL.deletingPathExtension().lastPathComponent
    }
}
