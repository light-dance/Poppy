import AppKit
import Foundation

nonisolated enum InstallServiceError: LocalizedError {
    case missingFile(URL)
    case cancelled
    case attachFailed(String)
    case archiveReadFailed(String)
    case archiveExtractFailed(String)
    case noMountPoint
    case noAppFound
    case installFolderNotWritable(URL)
    case appRunning(String)
    case replaceFailed(appName: String, message: String)
    case copyFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingFile(let url):
            "The installer is no longer at \(url.path). Leave it in the watched folder until install completes."
        case .cancelled:
            "Install cancelled."
        case .attachFailed(let message):
            "Could not mount the disk image. \(message)"
        case .archiveReadFailed(let message):
            "Could not inspect the ZIP archive. \(message)"
        case .archiveExtractFailed(let message):
            "Could not extract the app from the ZIP archive. \(message)"
        case .noMountPoint:
            "The disk image mounted, but macOS did not report a mount point."
        case .noAppFound:
            "No .app bundle was found."
        case .installFolderNotWritable(let url):
            "Poppy does not have permission to write to \(url.path)."
        case .appRunning(let appName):
            "\(appName) is currently running. Quit it and try again."
        case .replaceFailed(let appName, let message):
            "Could not move the existing \(appName) to the Trash. It may be owned by another user or installed by the system. \(message)"
        case .copyFailed(let message):
            "Could not copy the app into the install folder. \(message)"
        }
    }
}

nonisolated struct InstallResult: Sendable {
    let appURL: URL
    /// Non-fatal problems (unmount or download cleanup) that happened after the app was installed.
    let warnings: [String]
}

nonisolated final class InstallService: Sendable {
    private var fileManager: FileManager { .default }

    @concurrent
    func install(
        sourceURL: URL,
        kind: InstallableKind,
        installDirectory: URL,
        deleteAfterInstall: Bool,
        progress: @MainActor @Sendable @escaping (String) -> Void
    ) async throws -> InstallResult {
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw InstallServiceError.missingFile(sourceURL)
        }
        try ensureWritable(installDirectory)

        switch kind {
        case .diskImage:
            return try await installDiskImage(
                sourceURL,
                installDirectory: installDirectory,
                deleteAfterInstall: deleteAfterInstall,
                progress: progress
            )
        case .appBundle:
            return try await installAppBundle(
                sourceURL,
                installDirectory: installDirectory,
                deleteAfterInstall: deleteAfterInstall,
                progress: progress
            )
        case .zipArchive:
            return try await installZipArchive(
                sourceURL,
                installDirectory: installDirectory,
                deleteAfterInstall: deleteAfterInstall,
                progress: progress
            )
        }
    }

    private func installAppBundle(
        _ appURL: URL,
        installDirectory: URL,
        deleteAfterInstall: Bool,
        progress: @MainActor @Sendable @escaping (String) -> Void
    ) async throws -> InstallResult {
        try checkCancellation()
        await progress("Copying \(appURL.deletingPathExtension().lastPathComponent)")
        let destinationApp = try await placeApp(appURL, in: installDirectory, moveSource: false)

        var warnings: [String] = []
        if deleteAfterInstall, appURL.standardizedFileURL != destinationApp.standardizedFileURL {
            await progress("Cleaning up download")
            if let warning = trashSourceInstaller(appURL) {
                warnings.append(warning)
            }
        }

        return InstallResult(appURL: destinationApp, warnings: warnings)
    }

    private func installDiskImage(
        _ dmgURL: URL,
        installDirectory: URL,
        deleteAfterInstall: Bool,
        progress: @MainActor @Sendable @escaping (String) -> Void
    ) async throws -> InstallResult {
        try checkCancellation()
        await progress("Mounting disk image")
        let mountPoint = try await attach(dmgURL: dmgURL)

        let destinationApp: URL
        do {
            try checkCancellation()
            await progress("Finding app bundle")
            let sourceApp = try findApp(in: mountPoint)

            try checkCancellation()
            await progress("Copying \(sourceApp.deletingPathExtension().lastPathComponent)")
            destinationApp = try await placeApp(sourceApp, in: installDirectory, moveSource: false)
        } catch {
            await detachIgnoringCancellation(mountPoint: mountPoint)
            throw error
        }

        // The app is installed at this point, so cleanup problems are reported as warnings.
        var warnings: [String] = []
        await progress("Unmounting disk image")
        if let warning = await detachIgnoringCancellation(mountPoint: mountPoint) {
            warnings.append(warning)
        }

        if deleteAfterInstall {
            await progress("Cleaning up download")
            if let warning = trashSourceInstaller(dmgURL) {
                warnings.append(warning)
            }
        }

        return InstallResult(appURL: destinationApp, warnings: warnings)
    }

    private func installZipArchive(
        _ zipURL: URL,
        installDirectory: URL,
        deleteAfterInstall: Bool,
        progress: @MainActor @Sendable @escaping (String) -> Void
    ) async throws -> InstallResult {
        try checkCancellation()
        await progress("Inspecting ZIP archive")
        let appEntry: String?
        do {
            appEntry = try await ZipArchiveInspector.findAppEntry(in: zipURL)
        } catch is CancellationError {
            throw InstallServiceError.cancelled
        }
        guard let appEntry else {
            throw InstallServiceError.noAppFound
        }
        try checkCancellation()

        let extractionDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("Poppy-\(UUID().uuidString)", isDirectory: true)
            .standardizedFileURL
        defer {
            try? fileManager.removeItem(at: extractionDirectory)
        }

        await progress("Extracting \(URL(fileURLWithPath: appEntry).deletingPathExtension().lastPathComponent)")
        try fileManager.createDirectory(at: extractionDirectory, withIntermediateDirectories: true)
        try await extractArchive(zipURL, to: extractionDirectory)

        let sourceApp = extractionDirectory.appendingPathComponent(appEntry, isDirectory: true).standardizedFileURL
        guard
            sourceApp.path.hasPrefix(extractionDirectory.path + "/"),
            fileManager.fileExists(atPath: sourceApp.path)
        else {
            throw InstallServiceError.archiveExtractFailed("The ZIP archive did not contain the expected app bundle.")
        }

        try checkCancellation()
        await progress("Copying \(sourceApp.deletingPathExtension().lastPathComponent)")
        let destinationApp = try await placeApp(sourceApp, in: installDirectory, moveSource: true)

        var warnings: [String] = []
        if deleteAfterInstall {
            await progress("Cleaning up download")
            if let warning = trashSourceInstaller(zipURL) {
                warnings.append(warning)
            }
        }

        return InstallResult(appURL: destinationApp, warnings: warnings)
    }

    /// Stages the new app next to its destination, then swaps it in so a failed copy never removes the existing app.
    private func placeApp(_ sourceApp: URL, in installDirectory: URL, moveSource: Bool) async throws -> URL {
        let appName = sourceApp.deletingPathExtension().lastPathComponent
        let destinationApp = installDirectory.appendingPathComponent(sourceApp.lastPathComponent, isDirectory: true)

        removeStaleStagingDirectories(in: installDirectory)
        let stagingDirectory = installDirectory
            .appendingPathComponent(".poppy-staging-\(UUID().uuidString)", isDirectory: true)
        let stagedApp = stagingDirectory.appendingPathComponent(sourceApp.lastPathComponent, isDirectory: true)
        defer {
            try? fileManager.removeItem(at: stagingDirectory)
        }

        do {
            try fileManager.createDirectory(at: stagingDirectory, withIntermediateDirectories: false)
            if moveSource {
                try fileManager.moveItem(at: sourceApp, to: stagedApp)
            } else {
                try fileManager.copyItem(at: sourceApp, to: stagedApp)
            }
        } catch {
            throw InstallServiceError.copyFailed(error.localizedDescription)
        }

        // Checked after the (possibly long) copy so an app launched meanwhile isn't replaced underneath itself.
        if await isRunning(destinationApp) {
            throw InstallServiceError.appRunning(appName)
        }
        try checkCancellation()

        var trashedAppURL: NSURL?
        if fileManager.fileExists(atPath: destinationApp.path) {
            do {
                try fileManager.trashItem(at: destinationApp, resultingItemURL: &trashedAppURL)
            } catch {
                throw InstallServiceError.replaceFailed(appName: appName, message: error.localizedDescription)
            }
        }

        do {
            try fileManager.moveItem(at: stagedApp, to: destinationApp)
        } catch {
            if let trashedAppURL = trashedAppURL as URL? {
                try? fileManager.moveItem(at: trashedAppURL, to: destinationApp)
            }
            throw InstallServiceError.copyFailed(error.localizedDescription)
        }

        return destinationApp
    }

    /// Removes staging folders left behind if Poppy quit mid-install. Installs are serialized, so none are in use.
    private func removeStaleStagingDirectories(in installDirectory: URL) {
        let contents = (try? fileManager.contentsOfDirectory(at: installDirectory, includingPropertiesForKeys: nil)) ?? []
        for url in contents where url.lastPathComponent.hasPrefix(".poppy-staging-") {
            try? fileManager.removeItem(at: url)
        }
    }

    private func ensureWritable(_ installDirectory: URL) throws {
        do {
            try fileManager.createDirectory(at: installDirectory, withIntermediateDirectories: true)
        } catch {
            throw InstallServiceError.installFolderNotWritable(installDirectory)
        }

        guard fileManager.isWritableFile(atPath: installDirectory.path) else {
            throw InstallServiceError.installFolderNotWritable(installDirectory)
        }
    }

    private func isRunning(_ appURL: URL) async -> Bool {
        let appPath = appURL.standardizedFileURL.path
        return await MainActor.run {
            NSWorkspace.shared.runningApplications.contains {
                $0.bundleURL?.standardizedFileURL.path == appPath
            }
        }
    }

    /// Returns a warning message if the installer could not be moved to the Trash.
    private func trashSourceInstaller(_ sourceURL: URL) -> String? {
        do {
            try fileManager.trashItem(at: sourceURL, resultingItemURL: nil)
            return nil
        } catch {
            return "The installer could not be moved to the Trash. \(error.localizedDescription)"
        }
    }

    private func checkCancellation() throws {
        if Task.isCancelled {
            throw InstallServiceError.cancelled
        }
    }

    private func runTool(_ executable: String, arguments: [String]) async throws -> ShellResult {
        do {
            let result = try await Shell.run(executable, arguments: arguments)
            try checkCancellation()
            return result
        } catch is CancellationError {
            throw InstallServiceError.cancelled
        }
    }

    private func attach(dmgURL: URL) async throws -> URL {
        // Not cancellable: killing hdiutil mid-attach can leave an orphaned mount that finishes after it exits.
        // Instead the mount completes and is detached below if the install was cancelled meanwhile.
        let result = try await Task {
            try await Shell.run("/usr/bin/hdiutil", arguments: [
                "attach",
                "-plist",
                "-nobrowse",
                "-noautoopen",
                "-readonly",
                dmgURL.path
            ])
        }.value

        guard result.status == 0 else {
            try checkCancellation()
            throw InstallServiceError.attachFailed(combinedMessage(result))
        }

        guard
            let data = result.output.data(using: .utf8),
            let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
            let entities = plist["system-entities"] as? [[String: Any]]
        else {
            throw InstallServiceError.noMountPoint
        }

        guard let mountPath = entities.lazy.compactMap({ $0["mount-point"] as? String }).first else {
            throw InstallServiceError.noMountPoint
        }

        let mountPoint = URL(fileURLWithPath: mountPath, isDirectory: true)
        // hdiutil can finish mounting before a cancel terminates it; don't leave the volume behind.
        if Task.isCancelled {
            await detachIgnoringCancellation(mountPoint: mountPoint)
            throw InstallServiceError.cancelled
        }
        return mountPoint
    }

    /// Unmounts even if the install task was cancelled, retrying once if the volume is briefly busy.
    /// Never forces: the image may also be mounted and in use by the user. Returns a warning if it stays mounted.
    @discardableResult
    private func detachIgnoringCancellation(mountPoint: URL) async -> String? {
        await Task {
            var lastError = ""
            for _ in 0..<2 {
                do {
                    let result = try await Shell.run("/usr/bin/hdiutil", arguments: ["detach", mountPoint.path])
                    if result.status == 0 {
                        return nil
                    }
                    lastError = combinedMessage(result)
                } catch {
                    lastError = error.localizedDescription
                }
                try? await Task.sleep(for: .seconds(1))
            }
            return "The disk image could not be unmounted. \(lastError)"
        }.value
    }

    private func extractArchive(_ zipURL: URL, to destinationDirectory: URL) async throws {
        // ditto restores AppleDouble metadata (code signature xattrs) and propagates quarantine, unlike unzip.
        let result = try await runTool("/usr/bin/ditto", arguments: [
            "-x",
            "-k",
            zipURL.path,
            destinationDirectory.path
        ])

        guard result.status == 0 else {
            throw InstallServiceError.archiveExtractFailed(combinedMessage(result))
        }
    }

    private func combinedMessage(_ result: ShellResult) -> String {
        [result.error, result.output]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    /// Picks the shallowest app, skipping uninstallers and symlinks unless nothing else is available.
    private func findApp(in mountPoint: URL) throws -> URL {
        guard let enumerator = fileManager.enumerator(
            at: mountPoint,
            includingPropertiesForKeys: [.isSymbolicLinkKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw InstallServiceError.noAppFound
        }

        var apps: [(url: URL, depth: Int)] = []
        for case let url as URL in enumerator
        where url.pathExtension.lowercased() == "app"
            && (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) != true {
            apps.append((url, enumerator.level))
        }

        let installableApps = apps.filter { !$0.url.lastPathComponent.localizedCaseInsensitiveContains("uninstall") }
        let candidates = installableApps.isEmpty ? apps : installableApps
        let app = candidates.min {
            if $0.depth != $1.depth {
                return $0.depth < $1.depth
            }
            return $0.url.lastPathComponent.localizedStandardCompare($1.url.lastPathComponent) == .orderedAscending
        }

        guard let app else {
            throw InstallServiceError.noAppFound
        }
        return app.url
    }
}
