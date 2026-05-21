import Foundation

final class DownloadsWatcher {
    private let downloadsURL: URL
    private let onDetected: @MainActor (URL) -> Void
    private var knownDMGs = Set<URL>()
    private var sizeCache = [URL: Int64]()
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: CInt = -1

    init(
        downloadsURL: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads"),
        onDetected: @escaping @MainActor (URL) -> Void
    ) {
        self.downloadsURL = downloadsURL
        self.onDetected = onDetected
    }

    func start() {
        stop()
        seedKnownDMGs()
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

    private func seedKnownDMGs() {
        knownDMGs = Set(currentDMGs())
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
            self?.scanForReadyDMGs()
        }
        source.setCancelHandler { [weak self] in
            guard let self, self.fileDescriptor >= 0 else { return }
            close(self.fileDescriptor)
            self.fileDescriptor = -1
        }
        self.source = source
        source.resume()
    }

    private func scanForReadyDMGs() {
        let currentDMGs = currentDMGs()
        let currentDMGSet = Set(currentDMGs)

        knownDMGs.formIntersection(currentDMGSet)
        sizeCache = sizeCache.filter { currentDMGSet.contains($0.key) }

        for dmgURL in currentDMGs where !knownDMGs.contains(dmgURL) {
            guard isStableFile(at: dmgURL) else {
                continue
            }
            knownDMGs.insert(dmgURL)
            Task { @MainActor in
                onDetected(dmgURL)
            }
        }
    }

    private func currentDMGs() -> [URL] {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: downloadsURL,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return urls.filter { url in
            url.pathExtension.lowercased() == "dmg"
                && !url.lastPathComponent.hasSuffix(".download")
                && !url.lastPathComponent.hasSuffix(".crdownload")
        }
    }

    private func isStableFile(at url: URL) -> Bool {
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? -1
        let previousSize = sizeCache[url]
        sizeCache[url] = size
        return size > 0 && previousSize == size
    }
}
