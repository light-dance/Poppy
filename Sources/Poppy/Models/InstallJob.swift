import Foundation

struct InstallJob: Identifiable, Equatable {
    enum State: Equatable {
        case awaitingApproval
        case installing(String)
        case installed(appURL: URL)
        case failed(String)
    }

    enum ApprovalBehavior: Equatable {
        case manual
        case autoInstall(afterSeconds: Int)
    }

    let id = UUID()
    let sourceURL: URL
    let kind: InstallableKind
    var appName: String?
    var state: State
    var approvalBehavior: ApprovalBehavior

    init(
        sourceURL: URL,
        kind: InstallableKind? = nil,
        appName: String?,
        state: State,
        approvalBehavior: ApprovalBehavior = .manual
    ) {
        self.sourceURL = sourceURL
        self.kind = kind ?? InstallableKind(url: sourceURL) ?? .diskImage
        self.appName = appName
        self.state = state
        self.approvalBehavior = approvalBehavior
    }

    var displayName: String {
        appName ?? sourceURL.deletingPathExtension().lastPathComponent
    }
}
