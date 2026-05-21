import AppKit
import Foundation

@MainActor
final class InstallStore: ObservableObject {
    private static let watchedFolderPathKey = "watchedFolderPath"

    @Published var currentJob: InstallJob?
    @Published var records: [InstallRecord] = []
    @Published var isWatching = false
    @Published private(set) var watchedFolderURL: URL

    private let installer = DMGInstaller()
    private var queuedJobs: [InstallJob] = []
    private var watcher: DownloadsWatcher?

    init() {
        if let storedPath = UserDefaults.standard.string(forKey: Self.watchedFolderPathKey), !storedPath.isEmpty {
            watchedFolderURL = URL(fileURLWithPath: storedPath, isDirectory: true)
        } else {
            watchedFolderURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads", isDirectory: true)
        }
    }

    func start() {
        guard watcher == nil else { return }
        watcher = DownloadsWatcher(downloadsURL: watchedFolderURL) { [weak self] dmgURL in
            self?.handleDetectedDMG(dmgURL)
        }
        watcher?.start()
        isWatching = true
    }

    func stop() {
        watcher?.stop()
        watcher = nil
        isWatching = false
    }

    func chooseWatchedFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose DMG Watch Folder"
        panel.message = "Mac Installs will watch this folder for new disk images."
        panel.prompt = "Use Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = watchedFolderURL

        guard panel.runModal() == .OK, let folderURL = panel.url else {
            return
        }

        setWatchedFolder(folderURL)
    }

    func setWatchedFolder(_ folderURL: URL) {
        let wasWatching = isWatching
        stop()
        watchedFolderURL = folderURL
        UserDefaults.standard.set(folderURL.path, forKey: Self.watchedFolderPathKey)
        queuedJobs.removeAll()
        currentJob = nil

        if wasWatching {
            start()
        }
    }

    func promptForLatestDMGInWatchedFolder() {
        guard
            let urls = try? FileManager.default.contentsOfDirectory(
                at: watchedFolderURL,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
        else {
            return
        }

        let latestDMG = urls
            .filter { $0.pathExtension.lowercased() == "dmg" }
            .sorted {
                let lhsDate = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let rhsDate = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return lhsDate > rhsDate
            }
            .first

        if let latestDMG {
            handleDetectedDMG(latestDMG)
        }
    }

    func approveCurrentInstall() {
        guard var job = currentJob else { return }
        job.state = .installing("Preparing")
        currentJob = job

        Task {
            do {
                let result = try await installer.install(dmgURL: job.dmgURL) { [weak self] message in
                    self?.updateCurrentJobState(.installing(message))
                }
                let appName = result.appURL.deletingPathExtension().lastPathComponent
                updateCurrentJob(appName: appName, state: .installed(appURL: result.appURL))
                addRecord(
                    appName: appName,
                    dmgName: job.dmgURL.lastPathComponent,
                    result: .success,
                    detail: "Installed into ~/Applications"
                )
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                updateCurrentJobState(.failed(message))
                addRecord(
                    appName: job.displayName,
                    dmgName: job.dmgURL.lastPathComponent,
                    result: .failed,
                    detail: message
                )
            }
        }
    }

    func cancelCurrentInstall() {
        guard let job = currentJob else { return }
        addRecord(
            appName: job.displayName,
            dmgName: job.dmgURL.lastPathComponent,
            result: .cancelled,
            detail: "User declined install"
        )
        advanceToNextJob()
    }

    func dismissCurrentJob() {
        advanceToNextJob()
    }

    func openInstalledApp() {
        guard case .installed(let appURL) = currentJob?.state else { return }
        NSWorkspace.shared.open(appURL)
        advanceToNextJob()
    }

    private func handleDetectedDMG(_ dmgURL: URL) {
        let job = InstallJob(dmgURL: dmgURL, appName: nil, state: .awaitingApproval)
        if currentJob == nil {
            currentJob = job
        } else {
            queuedJobs.append(job)
        }
    }

    private func advanceToNextJob() {
        currentJob = queuedJobs.isEmpty ? nil : queuedJobs.removeFirst()
    }

    private func updateCurrentJobState(_ state: InstallJob.State) {
        guard var job = currentJob else { return }
        job.state = state
        currentJob = job
    }

    private func updateCurrentJob(appName: String, state: InstallJob.State) {
        guard var job = currentJob else { return }
        job.appName = appName
        job.state = state
        currentJob = job
    }

    private func addRecord(appName: String, dmgName: String, result: InstallRecord.Result, detail: String) {
        records.insert(
            InstallRecord(appName: appName, dmgName: dmgName, date: Date(), result: result, detail: detail),
            at: 0
        )
    }
}
