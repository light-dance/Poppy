import Foundation

enum InstallServiceError: LocalizedError {
    case missingFile(URL)
    case cancelled
    case attachFailed(String)
    case noMountPoint
    case noAppFound
    case copyFailed(String)
    case detachFailed(String)
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingFile(let url):
            "The installer is no longer at \(url.path). Leave it in the watched folder until install completes."
        case .cancelled:
            "Install cancelled."
        case .attachFailed(let message):
            "Could not mount the disk image. \(message)"
        case .noMountPoint:
            "The disk image mounted, but macOS did not report a mount point."
        case .noAppFound:
            "No .app bundle was found."
        case .copyFailed(let message):
            "Could not copy the app into the install folder. \(message)"
        case .detachFailed(let message):
            "The app was copied, but the disk image could not be unmounted. \(message)"
        case .deleteFailed(let message):
            "The app was copied, but the source installer could not be deleted. \(message)"
        }
    }
}

struct InstallResult {
    let appURL: URL
}

final class InstallService {
    private let fileManager = FileManager.default

    func install(
        sourceURL: URL,
        kind: InstallableKind,
        installDirectory: URL,
        progress: @MainActor @escaping (String) -> Void
    ) async throws -> InstallResult {
        switch kind {
        case .diskImage:
            return try await installDiskImage(sourceURL, installDirectory: installDirectory, progress: progress)
        case .appBundle:
            return try await installAppBundle(sourceURL, installDirectory: installDirectory, progress: progress)
        }
    }

    private func installAppBundle(
        _ appURL: URL,
        installDirectory: URL,
        progress: @MainActor @escaping (String) -> Void
    ) async throws -> InstallResult {
        guard fileManager.fileExists(atPath: appURL.path) else {
            throw InstallServiceError.missingFile(appURL)
        }

        try checkCancellation()
        await progress("Copying \(appURL.deletingPathExtension().lastPathComponent)")
        let destinationApp = installDirectory.appendingPathComponent(appURL.lastPathComponent, isDirectory: true)

        do {
            try fileManager.createDirectory(at: installDirectory, withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: destinationApp.path) {
                try fileManager.removeItem(at: destinationApp)
            }
            try fileManager.copyItem(at: appURL, to: destinationApp)
        } catch {
            throw InstallServiceError.copyFailed(error.localizedDescription)
        }

        try checkCancellation()
        await progress("Cleaning up download")
        do {
            try fileManager.removeItem(at: appURL)
        } catch {
            throw InstallServiceError.deleteFailed(error.localizedDescription)
        }

        return InstallResult(appURL: destinationApp)
    }

    private func installDiskImage(
        _ dmgURL: URL,
        installDirectory: URL,
        progress: @MainActor @escaping (String) -> Void
    ) async throws -> InstallResult {
        guard fileManager.fileExists(atPath: dmgURL.path) else {
            throw InstallServiceError.missingFile(dmgURL)
        }

        try checkCancellation()
        await progress("Mounting disk image")
        let mountPoint = try await attach(dmgURL: dmgURL)

        do {
            try checkCancellation()
            await progress("Finding app bundle")
            let sourceApp = try findApp(in: mountPoint)
            let destinationApp = installDirectory.appendingPathComponent(sourceApp.lastPathComponent, isDirectory: true)

            try checkCancellation()
            await progress("Copying \(sourceApp.deletingPathExtension().lastPathComponent)")
            do {
                try fileManager.createDirectory(at: installDirectory, withIntermediateDirectories: true)
                if fileManager.fileExists(atPath: destinationApp.path) {
                    try fileManager.removeItem(at: destinationApp)
                }
                try fileManager.copyItem(at: sourceApp, to: destinationApp)
            } catch {
                throw InstallServiceError.copyFailed(error.localizedDescription)
            }

            try checkCancellation()
            await progress("Unmounting disk image")
            try await detach(mountPoint: mountPoint)

            try checkCancellation()
            await progress("Cleaning up download")
            do {
                try fileManager.removeItem(at: dmgURL)
            } catch {
                throw InstallServiceError.deleteFailed(error.localizedDescription)
            }

            return InstallResult(appURL: destinationApp)
        } catch {
            try? await detach(mountPoint: mountPoint)
            throw error
        }
    }

    private func checkCancellation() throws {
        if Task.isCancelled {
            throw InstallServiceError.cancelled
        }
    }

    private func attach(dmgURL: URL) async throws -> URL {
        let result = try await Shell.run("/usr/bin/hdiutil", arguments: [
            "attach",
            "-plist",
            "-nobrowse",
            "-readonly",
            dmgURL.path
        ])

        guard result.status == 0 else {
            let message = [result.error, result.output]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            throw InstallServiceError.attachFailed(message)
        }

        guard
            let data = result.output.data(using: .utf8),
            let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
            let entities = plist["system-entities"] as? [[String: Any]]
        else {
            throw InstallServiceError.noMountPoint
        }

        for entity in entities {
            if let mountPoint = entity["mount-point"] as? String {
                return URL(fileURLWithPath: mountPoint, isDirectory: true)
            }
        }

        throw InstallServiceError.noMountPoint
    }

    private func detach(mountPoint: URL) async throws {
        let result = try await Shell.run("/usr/bin/hdiutil", arguments: ["detach", mountPoint.path])
        guard result.status == 0 else {
            throw InstallServiceError.detachFailed(result.error.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private func findApp(in mountPoint: URL) throws -> URL {
        guard let enumerator = fileManager.enumerator(
            at: mountPoint,
            includingPropertiesForKeys: [.isDirectoryKey, .isApplicationKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw InstallServiceError.noAppFound
        }

        for case let url as URL in enumerator where url.pathExtension == "app" {
            return url
        }

        throw InstallServiceError.noAppFound
    }
}
