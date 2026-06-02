import Foundation

@MainActor
final class DownloadsWatcher {
    private let downloadsURL: URL
    private let onDetected: @MainActor (URL) -> Void
    private let onChanged: @MainActor () -> Void
    private let onLog: @MainActor (String) -> Void
    private let maxZipInspectionStableFailures = 5
    private var knownInstallables = Set<URL>()
    private var zipInspectionTasks = Set<URL>()
    private var zipRetryStates = [URL: ZipRetryState]()
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: CInt = -1

    init(
        downloadsURL: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads"),
        onDetected: @escaping @MainActor (URL) -> Void,
        onChanged: @escaping @MainActor () -> Void = {},
        onLog: @escaping @MainActor (String) -> Void = { _ in }
    ) {
        self.downloadsURL = downloadsURL
        self.onDetected = onDetected
        self.onChanged = onChanged
        self.onLog = onLog
    }

    func start() {
        stop()
        onLog("Starting watcher for \(downloadsURL.path)")
        seedKnownInstallables()
        startDirectoryEvents()
    }

    func stop() {
        source?.cancel()
        source = nil
        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    }

    private func seedKnownInstallables() {
        knownInstallables = Set(currentInstallables())
        onLog("Seeded \(knownInstallables.count) existing installable file(s)")
    }

    private func startDirectoryEvents() {
        fileDescriptor = open(downloadsURL.path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            onLog("Failed to open watcher folder: \(downloadsURL.path)")
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend, .rename, .attrib],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            self?.onLog("Filesystem event received")
            self?.scanForReadyInstallables()
        }
        source.setCancelHandler { [weak self] in
            guard let self, self.fileDescriptor >= 0 else { return }
            close(self.fileDescriptor)
            self.fileDescriptor = -1
        }
        self.source = source
        source.resume()
    }

    private func scanForReadyInstallables() {
        let currentInstallables = currentInstallables()
        let currentInstallableSet = Set(currentInstallables)
        onLog("Scanned \(currentInstallables.count) installable-looking file(s)")

        knownInstallables.formIntersection(currentInstallableSet)
        zipInspectionTasks.formIntersection(currentInstallableSet)
        zipRetryStates = zipRetryStates.filter { currentInstallableSet.contains($0.key) }

        onChanged()

        for url in currentInstallables where !knownInstallables.contains(url) {
            if InstallableKind(url: url) == .zipArchive {
                onLog("Inspecting zip before detection: \(url.lastPathComponent)")
                inspectZipInstallable(url)
                continue
            }
            knownInstallables.insert(url)
            onLog("Detected installer: \(url.lastPathComponent)")
            onDetected(url)
        }
    }

    private func inspectZipInstallable(_ url: URL) {
        guard !zipInspectionTasks.contains(url) else { return }
        zipInspectionTasks.insert(url)

        Task { [weak self] in
            let result: Result<String?, Error>
            do {
                result = .success(try await ZipArchiveInspector.findAppEntry(in: url))
            } catch {
                result = .failure(error)
            }

            await MainActor.run {
                guard let self else { return }
                self.zipInspectionTasks.remove(url)

                switch result {
                case .success(.some):
                    self.zipRetryStates.removeValue(forKey: url)
                    self.knownInstallables.insert(url)
                    self.onLog("Zip contains an app: \(url.lastPathComponent)")
                    self.onDetected(url)
                case .success(.none):
                    self.zipRetryStates.removeValue(forKey: url)
                    self.knownInstallables.insert(url)
                    self.onLog("Zip ignored because no app was found: \(url.lastPathComponent)")
                    self.onChanged()
                case .failure(let error):
                    self.onLog("Zip inspection failed for \(url.lastPathComponent): \(error.localizedDescription)")
                    self.scheduleZipInspectionRetry(for: url)
                }
            }
        }
    }

    private func scheduleZipInspectionRetry(for url: URL) {
        let currentSize = fileSize(for: url)
        let state = zipRetryStates[url] ?? ZipRetryState(lastObservedSize: currentSize, stableFailureCount: 0)
        let nextStableFailureCount = state.lastObservedSize == currentSize ? state.stableFailureCount + 1 : 0

        guard nextStableFailureCount <= maxZipInspectionStableFailures else {
            zipRetryStates.removeValue(forKey: url)
            knownInstallables.insert(url)
            onLog("Stopped retrying zip inspection after stable failures: \(url.lastPathComponent)")
            onChanged()
            return
        }

        zipRetryStates[url] = ZipRetryState(
            lastObservedSize: currentSize,
            stableFailureCount: nextStableFailureCount
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            self.onLog("Retrying zip inspection: \(url.lastPathComponent)")
            self.inspectZipInstallable(url)
        }
    }

    private func currentInstallables() -> [URL] {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: downloadsURL,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return urls.filter { url in
            InstallableKind(url: url) != nil
                && !url.lastPathComponent.hasSuffix(".download")
                && !url.lastPathComponent.hasSuffix(".crdownload")
        }
    }

    private func fileSize(for url: URL) -> Int? {
        (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize)
    }
}

private struct ZipRetryState {
    let lastObservedSize: Int?
    let stableFailureCount: Int
}
