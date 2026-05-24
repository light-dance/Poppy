import AppKit
import Foundation

@MainActor
final class InstallStore: ObservableObject {
    private static let watchedFolderPathKey = "watchedFolderPath"
    private static let installFolderPathKey = "installFolderPath"

    @Published var currentJob: InstallJob?
    @Published private(set) var installableItems: [InstallableItem] = []
    @Published private(set) var hiddenInstallableItems: [InstallableItem] = []
    @Published private(set) var debugAppItems: [AppItem] = []
    @Published var records: [InstallRecord] = []
    @Published var isWatching = false
    @Published private(set) var watchedFolderURL: URL
    @Published private(set) var installFolderURL: URL

    private var queuedJobs: [InstallJob] = []
    private var activeInstallTask: Task<Void, Never>?
    private var watcher: DownloadsWatcher?
    private var hiddenInstallableURLs = Set<URL>()
    private var zipInstallableCache = [URL: ZipInstallableCacheEntry]()
    private var zipInspectionTasks = Set<URL>()

    static var defaultWatchedFolderURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads", isDirectory: true)
    }

    static var defaultInstallFolderURL: URL {
        URL(fileURLWithPath: "/Applications", isDirectory: true)
    }

    var defaultWatchedFolderURL: URL { Self.defaultWatchedFolderURL }
    var defaultInstallFolderURL: URL { Self.defaultInstallFolderURL }

    init() {
        if let storedPath = UserDefaults.standard.string(forKey: Self.watchedFolderPathKey), !storedPath.isEmpty {
            watchedFolderURL = URL(fileURLWithPath: storedPath, isDirectory: true)
        } else {
            watchedFolderURL = Self.defaultWatchedFolderURL
        }

        if let storedPath = UserDefaults.standard.string(forKey: Self.installFolderPathKey), !storedPath.isEmpty {
            installFolderURL = URL(fileURLWithPath: storedPath, isDirectory: true)
        } else {
            installFolderURL = Self.defaultInstallFolderURL
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

    func resetWatchedFolder() {
        setWatchedFolder(defaultWatchedFolderURL)
    }

    func resetInstallFolder() {
        setInstallFolder(defaultInstallFolderURL)
    }

    func openWatchedFolder() {
        NSWorkspace.shared.open(watchedFolderURL)
    }

    func openInstallFolder() {
        NSWorkspace.shared.open(installFolderURL)
    }

    func promptForLatestInstallableInWatchedFolder() {
        guard
            let urls = try? FileManager.default.contentsOfDirectory(
                at: watchedFolderURL,
                includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )
        else {
            return
        }

        let latestInstallable = urls
            .filter { shouldShowInstallable($0) && !hiddenInstallableURLs.contains($0) }
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
        hiddenInstallableURLs.remove(sourceURL)
        install(job: InstallJob(sourceURL: sourceURL, appName: nil, state: .installing("Preparing")))
    }

    func cleanup(_ item: InstallableItem) {
        do {
            try FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
            hiddenInstallableURLs.remove(item.url)
            removePendingJobs(for: item.url)
            addRecord(
                appName: item.displayName,
                sourceName: item.url.lastPathComponent,
                result: .success,
                detail: "Moved installer to Trash"
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

    func hide(_ item: InstallableItem) {
        guard !isInstalling(item.url) else { return }
        hiddenInstallableURLs.insert(item.url)
        removePendingJobs(for: item.url)
        scanWatchedFolder()
    }

    func unhide(_ item: InstallableItem) {
        hiddenInstallableURLs.remove(item.url)
        scanWatchedFolder()
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

    func populateDebugAppItems() {
        debugAppItems = AppItem.debugSamples(
            watchedFolderURL: watchedFolderURL,
            installFolderURL: installFolderURL
        )
    }

    func clearDebugAppItems() {
        debugAppItems = []
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
                updateCurrentJobState(.failed(notificationFailureDescription(for: error)))
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
        guard !hiddenInstallableURLs.contains(sourceURL) else { return }
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

    private func removePendingJobs(for sourceURL: URL) {
        queuedJobs.removeAll { $0.sourceURL == sourceURL }

        guard currentJob?.sourceURL == sourceURL else { return }
        if case .installing = currentJob?.state {
            return
        }

        advanceToNextJob()
    }

    private func updateCurrentJobState(_ state: InstallJob.State) {
        guard var job = currentJob else { return }
        job.state = state
        currentJob = job
        scanWatchedFolder()
    }

    private func notificationFailureDescription(for error: Error) -> String {
        guard let installError = error as? InstallServiceError else {
            return "Install could not finish."
        }

        switch installError {
        case .missingFile:
            return "Installer moved or deleted."
        case .cancelled:
            return "Install cancelled."
        case .attachFailed, .archiveReadFailed, .archiveExtractFailed:
            return "Could not read the installer."
        case .noMountPoint:
            return "Could not open the disk image."
        case .noAppFound:
            return "No app was found."
        case .copyFailed:
            return "Check install folder permissions."
        case .detachFailed, .deleteFailed:
            return "Installed, but cleanup failed."
        }
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
            hiddenInstallableItems = []
            return
        }

        let currentURLSet = Set(urls)
        hiddenInstallableURLs.formIntersection(currentURLSet)
        zipInstallableCache = zipInstallableCache.filter { currentURLSet.contains($0.key) }
        zipInspectionTasks.formIntersection(currentURLSet)

        let items: [InstallableItem] = urls
            .filter { shouldShowInstallable($0) }
            .sorted {
                let lhsDate = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let rhsDate = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return lhsDate > rhsDate
            }
            .compactMap { url in
                guard let kind = InstallableKind(url: url) else { return nil }
                return InstallableItem(url: url, kind: kind, status: status(for: url, kind: kind))
            }

        installableItems = items.filter { !hiddenInstallableURLs.contains($0.url) }
        hiddenInstallableItems = items.filter { hiddenInstallableURLs.contains($0.url) }
    }

    private func shouldShowInstallable(_ url: URL) -> Bool {
        guard let kind = InstallableKind(url: url) else { return false }
        guard kind == .zipArchive else { return true }

        guard let fingerprint = zipFingerprint(for: url) else {
            return false
        }

        if let cachedEntry = zipInstallableCache[url], cachedEntry.fingerprint == fingerprint {
            return cachedEntry.containsApp
        }

        inspectZipForList(url, fingerprint: fingerprint)
        return false
    }

    private func inspectZipForList(_ url: URL, fingerprint: ZipFileFingerprint) {
        guard !zipInspectionTasks.contains(url) else { return }
        zipInspectionTasks.insert(url)

        Task { [weak self] in
            let containsApp = await ZipArchiveInspector.containsAppBundle(url)
            await MainActor.run {
                guard let self else { return }
                self.zipInspectionTasks.remove(url)
                if self.zipFingerprint(for: url) == fingerprint {
                    self.zipInstallableCache[url] = ZipInstallableCacheEntry(
                        fingerprint: fingerprint,
                        containsApp: containsApp
                    )
                } else {
                    self.zipInstallableCache.removeValue(forKey: url)
                }
                self.scanWatchedFolder()
            }
        }
    }

    private func zipFingerprint(for url: URL) -> ZipFileFingerprint? {
        guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]) else {
            return nil
        }
        return ZipFileFingerprint(
            contentModificationDate: values.contentModificationDate,
            fileSize: values.fileSize
        )
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

private struct ZipFileFingerprint: Equatable {
    let contentModificationDate: Date?
    let fileSize: Int?
}

private struct ZipInstallableCacheEntry {
    let fingerprint: ZipFileFingerprint
    let containsApp: Bool
}
