import Foundation

struct InstallJob: Identifiable, Equatable {
    enum State: Equatable {
        case awaitingApproval
        case installing(String)
        case installed(appURL: URL)
        case failed(String)
    }

    let id = UUID()
    let sourceURL: URL
    let kind: InstallableKind
    var appName: String?
    var state: State

    init(sourceURL: URL, kind: InstallableKind? = nil, appName: String?, state: State) {
        self.sourceURL = sourceURL
        self.kind = kind ?? InstallableKind(url: sourceURL) ?? .diskImage
        self.appName = appName
        self.state = state
    }

    var displayName: String {
        appName ?? sourceURL.deletingPathExtension().lastPathComponent
    }
}
