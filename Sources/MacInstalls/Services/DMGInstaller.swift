import Foundation

enum DMGInstallerError: LocalizedError {
    case missingFile(URL)
    case attachFailed(String)
    case noMountPoint
    case noAppFound
    case copyFailed(String)
    case detachFailed(String)
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingFile(let url):
            "The DMG is no longer at \(url.path). Download it again and leave it in Downloads until install completes."
        case .attachFailed(let message):
            "Could not mount the DMG. \(message)"
        case .noMountPoint:
            "The DMG mounted, but macOS did not report a mount point."
        case .noAppFound:
            "No .app bundle was found inside the mounted DMG."
        case .copyFailed(let message):
            "Could not copy the app into ~/Applications. \(message)"
        case .detachFailed(let message):
            "The app was copied, but the DMG could not be unmounted. \(message)"
        case .deleteFailed(let message):
            "The app was copied, but the DMG could not be deleted. \(message)"
        }
    }
}

struct DMGInstallResult {
    let appURL: URL
}

final class DMGInstaller {
    private let fileManager = FileManager.default

    func install(dmgURL: URL, progress: @MainActor @escaping (String) -> Void) async throws -> DMGInstallResult {
        guard fileManager.fileExists(atPath: dmgURL.path) else {
            throw DMGInstallerError.missingFile(dmgURL)
        }

        await progress("Mounting disk image")
        let mountPoint = try await attach(dmgURL: dmgURL)

        do {
            await progress("Finding app bundle")
            let sourceApp = try findApp(in: mountPoint)
            let destinationDirectory = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true)
            let destinationApp = destinationDirectory.appendingPathComponent(sourceApp.lastPathComponent, isDirectory: true)

            await progress("Copying \(sourceApp.deletingPathExtension().lastPathComponent)")
            try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
            if fileManager.fileExists(atPath: destinationApp.path) {
                try fileManager.removeItem(at: destinationApp)
            }
            try fileManager.copyItem(at: sourceApp, to: destinationApp)

            await progress("Unmounting disk image")
            try await detach(mountPoint: mountPoint)

            await progress("Cleaning up download")
            do {
                try fileManager.removeItem(at: dmgURL)
            } catch {
                throw DMGInstallerError.deleteFailed(error.localizedDescription)
            }

            return DMGInstallResult(appURL: destinationApp)
        } catch {
            try? await detach(mountPoint: mountPoint)
            throw error
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
            throw DMGInstallerError.attachFailed(message)
        }

        guard
            let data = result.output.data(using: .utf8),
            let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
            let entities = plist["system-entities"] as? [[String: Any]]
        else {
            throw DMGInstallerError.noMountPoint
        }

        for entity in entities {
            if let mountPoint = entity["mount-point"] as? String {
                return URL(fileURLWithPath: mountPoint, isDirectory: true)
            }
        }

        throw DMGInstallerError.noMountPoint
    }

    private func detach(mountPoint: URL) async throws {
        let result = try await Shell.run("/usr/bin/hdiutil", arguments: ["detach", mountPoint.path])
        guard result.status == 0 else {
            throw DMGInstallerError.detachFailed(result.error.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private func findApp(in mountPoint: URL) throws -> URL {
        guard let enumerator = fileManager.enumerator(
            at: mountPoint,
            includingPropertiesForKeys: [.isDirectoryKey, .isApplicationKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw DMGInstallerError.noAppFound
        }

        for case let url as URL in enumerator {
            if url.pathExtension == "app" {
                return url
            }
        }

        throw DMGInstallerError.noAppFound
    }
}
