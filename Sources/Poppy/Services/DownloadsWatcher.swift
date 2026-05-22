import Foundation

@MainActor
final class DownloadsWatcher {
    private let downloadsURL: URL
    private let onDetected: @MainActor (URL) -> Void
    private let onChanged: @MainActor () -> Void
    private var knownInstallables = Set<URL>()
    private var zipInspectionTasks = [URL: ZipInspectionFingerprint]()
    private var sizeCache = [URL: Int64]()
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: CInt = -1

    init(
        downloadsURL: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads"),
        onDetected: @escaping @MainActor (URL) -> Void,
        onChanged: @escaping @MainActor () -> Void = {}
    ) {
        self.downloadsURL = downloadsURL
        self.onDetected = onDetected
        self.onChanged = onChanged
    }

    func start() {
        stop()
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
    }

    private func startDirectoryEvents() {
        fileDescriptor = open(downloadsURL.path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend, .rename, .attrib],
            queue: .main
        )
        source.setEventHandler { [weak self] in
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

        knownInstallables.formIntersection(currentInstallableSet)
        zipInspectionTasks = zipInspectionTasks.filter { currentInstallableSet.contains($0.key) }
        sizeCache = sizeCache.filter { currentInstallableSet.contains($0.key) }

        onChanged()

        for url in currentInstallables where !knownInstallables.contains(url) {
            guard isStableFile(at: url) else {
                continue
            }
            if InstallableKind(url: url) == .zipArchive {
                inspectZipInstallable(url, fingerprint: zipFingerprint(for: url))
                continue
            }
            knownInstallables.insert(url)
            onDetected(url)
        }
    }

    private func inspectZipInstallable(_ url: URL, fingerprint: ZipInspectionFingerprint?) {
        guard let fingerprint else { return }
        guard zipInspectionTasks[url] != fingerprint else { return }
        zipInspectionTasks[url] = fingerprint

        Task { [weak self] in
            let containsApp = await ZipArchiveInspector.containsAppBundle(url)
            await MainActor.run {
                guard let self else { return }
                if self.zipInspectionTasks[url] == fingerprint {
                    self.zipInspectionTasks.removeValue(forKey: url)
                }
                guard self.zipFingerprint(for: url) == fingerprint else {
                    self.scanForReadyInstallables()
                    return
                }
                if containsApp {
                    self.knownInstallables.insert(url)
                    self.onDetected(url)
                } else {
                    self.onChanged()
                }
            }
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

    private func isStableFile(at url: URL) -> Bool {
        if InstallableKind(url: url) == .appBundle {
            return true
        }

        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? -1
        let previousSize = sizeCache[url]
        sizeCache[url] = size
        return size > 0 && previousSize == size
    }

    private func zipFingerprint(for url: URL) -> ZipInspectionFingerprint? {
        guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]) else {
            return nil
        }
        return ZipInspectionFingerprint(
            fileSize: values.fileSize,
            contentModificationDate: values.contentModificationDate
        )
    }
}

private struct ZipInspectionFingerprint: Equatable {
    let fileSize: Int?
    let contentModificationDate: Date?
}
