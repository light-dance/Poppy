import AppKit
import Foundation

@MainActor
final class InstallStore: ObservableObject {
    private static let watchedFolderPathKey = "watchedFolderPath"
    private static let installFolderPathKey = "installFolderPath"

    @Published var currentJob: InstallJob?
    @Published private(set) var installableItems: [InstallableItem] = []
    @Published var records: [InstallRecord] = []
    @Published var isWatching = false
    @Published private(set) var watchedFolderURL: URL
    @Published private(set) var installFolderURL: URL

    private var queuedJobs: [InstallJob] = []
    private var activeInstallTask: Task<Void, Never>?
    private var watcher: DownloadsWatcher?

    init() {
        if let storedPath = UserDefaults.standard.string(forKey: Self.watchedFolderPathKey), !storedPath.isEmpty {
            watchedFolderURL = URL(fileURLWithPath: storedPath, isDirectory: true)
        } else {
            watchedFolderURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads", isDirectory: true)
        }

        if let storedPath = UserDefaults.standard.string(forKey: Self.installFolderPathKey), !storedPath.isEmpty {
            installFolderURL = URL(fileURLWithPath: storedPath, isDirectory: true)
        } else {
            installFolderURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        }
    }

    func start() {
        guard watcher == nil else { return }
        scanWatchedFolder()
        watcher = DownloadsWatcher(
            downloadsURL: watchedFolderURL,
            onDetected: { [weak self] sourceURL in
                self?.handleDetectedInstallable(sourceURL)
            },
            onChanged: { [weak self] in
                self?.scanWatchedFolder()
            }
        )
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
        panel.title = "Choose Watch Folder"
        panel.message = "Poppy will watch this folder for app installers."
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
        activeInstallTask?.cancel()
        activeInstallTask = nil
        scanWatchedFolder()

        if wasWatching {
            start()
        }
    }

    func chooseInstallFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose Install Folder"
        panel.message = "Installed apps will be copied into this folder."
        panel.prompt = "Use Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = installFolderURL

        guard panel.runModal() == .OK, let folderURL = panel.url else {
            return
        }

        setInstallFolder(folderURL)
    }

    func setInstallFolder(_ folderURL: URL) {
        installFolderURL = folderURL
        UserDefaults.standard.set(folderURL.path, forKey: Self.installFolderPathKey)
        scanWatchedFolder()
    }

    func promptForLatestInstallableInWatchedFolder() {
        guard
            let urls = try? FileManager.default.contentsOfDirectory(
                at: watchedFolderURL,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
        else {
            return
        }

        let latestInstallable = urls
            .filter { InstallableKind(url: $0) != nil }
            .sorted {
                let lhsDate = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let rhsDate = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return lhsDate > rhsDate
            }
            .first

        if let latestInstallable {
            handleDetectedInstallable(latestInstallable)
        }
    }

    func approveCurrentInstall() {
        guard let job = currentJob else { return }
        install(job: job)
    }

    func installNow(_ item: InstallableItem) {
        installNow(sourceURL: item.url)
    }

    func installNow(sourceURL: URL) {
        guard !isInstalling(sourceURL) else { return }
        install(job: InstallJob(sourceURL: sourceURL, appName: nil, state: .installing("Preparing")))
    }

    func cleanup(_ item: InstallableItem) {
        do {
            try FileManager.default.removeItem(at: item.url)
            addRecord(
                appName: item.displayName,
                sourceName: item.url.lastPathComponent,
                result: .success,
                detail: "Deleted installer from watched folder"
            )
            scanWatchedFolder()
        } catch {
            addRecord(
                appName: item.displayName,
                sourceName: item.url.lastPathComponent,
                result: .failed,
                detail: error.localizedDescription
            )
        }
    }

    func openApp(_ item: InstallableItem) {
        guard case .installed(let appURL) = item.status else { return }
        NSWorkspace.shared.open(appURL)
    }

    func simulateNotification(_ state: InstallJob.State) {
        currentJob = InstallJob(
            sourceURL: watchedFolderURL.appendingPathComponent("ExampleApp-2.4.1.dmg"),
            appName: simulatedAppName(for: state),
            state: state
        )
    }

    func dismissSimulatedNotification() {
        currentJob = nil
    }

    var installingItems: [InstallableItem] {
        installableItems.filter {
            if case .installing = $0.status { return true }
            return false
        }
    }

    var readyItems: [InstallableItem] {
        installableItems.filter { $0.status == .ready }
    }

    var installedItems: [InstallableItem] {
        installableItems.filter {
            if case .installed = $0.status { return true }
            return false
        }
    }

    private func install(job: InstallJob) {
        var installingJob = job
        installingJob.state = .installing("Preparing")
        currentJob = installingJob
        let installDirectory = installFolderURL
        scanWatchedFolder()

        activeInstallTask?.cancel()
        activeInstallTask = Task {
            do {
                let installer = InstallService()
                let result = try await installer.install(
                    sourceURL: installingJob.sourceURL,
                    kind: installingJob.kind,
                    installDirectory: installDirectory
                ) { [weak self] message in
                    self?.updateCurrentJobState(.installing(message))
                }
                let appName = result.appURL.deletingPathExtension().lastPathComponent
                updateCurrentJob(appName: appName, state: .installed(appURL: result.appURL))
                addRecord(
                    appName: appName,
                    sourceName: job.sourceURL.lastPathComponent,
                    result: .success,
                    detail: "Installed into \(installDirectory.path)"
                )
                scanWatchedFolder()
            } catch InstallServiceError.cancelled {
                addRecord(
                    appName: job.displayName,
                    sourceName: job.sourceURL.lastPathComponent,
                    result: .cancelled,
                    detail: "Install cancelled"
                )
                advanceToNextJob()
                scanWatchedFolder()
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                updateCurrentJobState(.failed(message))
                addRecord(
                    appName: job.displayName,
                    sourceName: job.sourceURL.lastPathComponent,
                    result: .failed,
                    detail: message
                )
                scanWatchedFolder()
            }

            activeInstallTask = nil
        }
    }

    func cancelCurrentInstall() {
        guard let job = currentJob else { return }
        if case .installing = job.state {
            activeInstallTask?.cancel()
            updateCurrentJobState(.installing("Cancelling"))
            return
        }

        addRecord(
            appName: job.displayName,
            sourceName: job.sourceURL.lastPathComponent,
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

    private func handleDetectedInstallable(_ sourceURL: URL) {
        let job = InstallJob(sourceURL: sourceURL, appName: nil, state: .awaitingApproval)
        scanWatchedFolder()
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
        scanWatchedFolder()
    }

    private func updateCurrentJob(appName: String, state: InstallJob.State) {
        guard var job = currentJob else { return }
        job.appName = appName
        job.state = state
        currentJob = job
        scanWatchedFolder()
    }

    private func addRecord(appName: String, sourceName: String, result: InstallRecord.Result, detail: String) {
        records.insert(
            InstallRecord(appName: appName, sourceName: sourceName, date: Date(), result: result, detail: detail),
            at: 0
        )
    }

    private func scanWatchedFolder() {
        guard
            let urls = try? FileManager.default.contentsOfDirectory(
                at: watchedFolderURL,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
        else {
            installableItems = []
            return
        }

        installableItems = urls
            .filter { InstallableKind(url: $0) != nil }
            .sorted {
                let lhsDate = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let rhsDate = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return lhsDate > rhsDate
            }
            .compactMap { url in
                guard let kind = InstallableKind(url: url) else { return nil }
                return InstallableItem(url: url, kind: kind, status: status(for: url, kind: kind))
            }
    }

    private func status(for sourceURL: URL, kind: InstallableKind) -> InstallableItem.Status {
        if let installingStatus = installingStatus(for: sourceURL) {
            return installingStatus
        }

        if let installedAppURL = installedAppURL(for: sourceURL, kind: kind) {
            return .installed(appURL: installedAppURL)
        }

        return .ready
    }

    private func installingStatus(for sourceURL: URL) -> InstallableItem.Status? {
        guard currentJob?.sourceURL == sourceURL else { return nil }

        switch currentJob?.state {
        case .installing(let step):
            return .installing(step)
        case .some(.installed(let appURL)):
            return .installed(appURL: appURL)
        default:
            return nil
        }
    }

    private func isInstalling(_ sourceURL: URL) -> Bool {
        guard currentJob?.sourceURL == sourceURL else { return false }
        if case .installing = currentJob?.state {
            return true
        }
        return false
    }

    private func installedAppURL(for sourceURL: URL, kind: InstallableKind) -> URL? {
        for name in appNameCandidates(for: sourceURL, kind: kind) {
            let appURL = installFolderURL.appendingPathComponent(name).appendingPathExtension("app")
            if FileManager.default.fileExists(atPath: appURL.path) {
                return appURL
            }
        }
        return nil
    }

    private func appNameCandidates(for sourceURL: URL, kind: InstallableKind) -> [String] {
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        var candidates = [baseName]

        if kind == .appBundle {
            return candidates
        }

        if let range = baseName.range(of: #"[-_ ]\d"#, options: .regularExpression) {
            let prefix = String(baseName[..<range.lowerBound])
            if !prefix.isEmpty {
                candidates.append(prefix)
            }
        }

        return Array(Set(candidates))
    }

    private func simulatedAppName(for state: InstallJob.State) -> String? {
        switch state {
        case .installed:
            "ExampleApp"
        default:
            nil
        }
    }
}
