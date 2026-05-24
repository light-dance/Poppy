import Foundation

struct AppItem: Identifiable, Equatable {
    enum State: Equatable {
        case hidden
        case ready
        case installing(String)
        case installedCleanedUp(appURL: URL?)
        case installedNeedsCleanup(appURL: URL)
    }

    let id: String
    let name: String
    let fileName: String
    let fileURL: URL?
    let appURL: URL?
    let kind: InstallableKind
    let state: State
    let createdDate: Date?
    let sizeBytes: Int64?
    let isDebugSample: Bool

    init(
        id: String,
        name: String,
        fileName: String,
        fileURL: URL?,
        appURL: URL?,
        kind: InstallableKind,
        state: State,
        createdDate: Date?,
        sizeBytes: Int64?,
        isDebugSample: Bool = false
    ) {
        self.id = id
        self.name = name
        self.fileName = fileName
        self.fileURL = fileURL
        self.appURL = appURL
        self.kind = kind
        self.state = state
        self.createdDate = createdDate
        self.sizeBytes = sizeBytes
        self.isDebugSample = isDebugSample
    }

    init(installableItem item: InstallableItem, isHidden: Bool = false) {
        let values = try? item.url.resourceValues(forKeys: [
            .creationDateKey,
            .contentModificationDateKey,
            .fileSizeKey
        ])
        let state: State
        let appURL: URL?

        if isHidden {
            state = .hidden
            appURL = nil
        } else {
            switch item.status {
            case .ready:
                state = .ready
                appURL = nil
            case .installing(let step):
                state = .installing(step)
                appURL = nil
            case .installed(let installedAppURL):
                state = .installedNeedsCleanup(appURL: installedAppURL)
                appURL = installedAppURL
            }
        }

        self.init(
            id: item.id,
            name: item.displayName,
            fileName: item.url.lastPathComponent,
            fileURL: item.url,
            appURL: appURL,
            kind: item.kind,
            state: state,
            createdDate: values?.creationDate ?? values?.contentModificationDate,
            sizeBytes: values?.fileSize.map(Int64.init),
            isDebugSample: false
        )
    }

    static func debugSamples(watchedFolderURL: URL, installFolderURL: URL) -> [AppItem] {
        let now = Date()
        let readyURL = watchedFolderURL.appendingPathComponent("ReadySample-1.0.dmg")
        let hiddenURL = watchedFolderURL.appendingPathComponent("HiddenSample-1.0.zip")
        let installingURL = watchedFolderURL.appendingPathComponent("InstallingSample-2.0.dmg")
        let cleanupURL = watchedFolderURL.appendingPathComponent("NeedsCleanupSample-3.0.dmg")
        let cleanedAppURL = installFolderURL.appendingPathComponent("CleanedUpSample.app", isDirectory: true)
        let cleanupAppURL = installFolderURL.appendingPathComponent("NeedsCleanupSample.app", isDirectory: true)

        return [
            AppItem(
                id: "debug-hidden",
                name: "Hidden Sample",
                fileName: hiddenURL.lastPathComponent,
                fileURL: hiddenURL,
                appURL: nil,
                kind: .zipArchive,
                state: .hidden,
                createdDate: now.addingTimeInterval(-86_400 * 4),
                sizeBytes: 42_500_000,
                isDebugSample: true
            ),
            AppItem(
                id: "debug-ready",
                name: "Ready Sample",
                fileName: readyURL.lastPathComponent,
                fileURL: readyURL,
                appURL: nil,
                kind: .diskImage,
                state: .ready,
                createdDate: now.addingTimeInterval(-86_400 * 3),
                sizeBytes: 128_000_000,
                isDebugSample: true
            ),
            AppItem(
                id: "debug-installing",
                name: "Installing Sample",
                fileName: installingURL.lastPathComponent,
                fileURL: installingURL,
                appURL: nil,
                kind: .diskImage,
                state: .installing("Copying app bundle"),
                createdDate: now.addingTimeInterval(-86_400 * 2),
                sizeBytes: 215_000_000,
                isDebugSample: true
            ),
            AppItem(
                id: "debug-installed-cleaned",
                name: "Cleaned Up Sample",
                fileName: "CleanedUpSample-1.0.dmg",
                fileURL: nil,
                appURL: cleanedAppURL,
                kind: .diskImage,
                state: .installedCleanedUp(appURL: cleanedAppURL),
                createdDate: now.addingTimeInterval(-86_400),
                sizeBytes: nil,
                isDebugSample: true
            ),
            AppItem(
                id: "debug-installed-needs-cleanup",
                name: "Needs Cleanup Sample",
                fileName: cleanupURL.lastPathComponent,
                fileURL: cleanupURL,
                appURL: cleanupAppURL,
                kind: .diskImage,
                state: .installedNeedsCleanup(appURL: cleanupAppURL),
                createdDate: now.addingTimeInterval(-3_600),
                sizeBytes: 188_000_000,
                isDebugSample: true
            )
        ]
    }
}
