import Foundation

enum ZipArchiveInspector {
    static func findAppEntry(in zipURL: URL) async throws -> String? {
        let result = try await Shell.run("/usr/bin/zipinfo", arguments: ["-1", zipURL.path])
        guard result.status == 0 else {
            let message = [result.error, result.output]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            throw InstallServiceError.archiveReadFailed(message)
        }

        for line in result.output.split(separator: "\n") {
            let entry = String(line)
            guard !entry.hasPrefix("__MACOSX/") else { continue }

            let components = entry.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
            guard isSafeZipPath(entry, components: components) else { continue }

            if let appIndex = components.firstIndex(where: {
                URL(fileURLWithPath: $0).pathExtension.lowercased() == "app"
            }) {
                return components[...appIndex].joined(separator: "/")
            }
        }

        return nil
    }

    static func containsAppBundle(_ zipURL: URL) async -> Bool {
        (try? await findAppEntry(in: zipURL)) != nil
    }

    private static func isSafeZipPath(_ entry: String, components: [String]) -> Bool {
        !entry.hasPrefix("/") && !components.isEmpty && !components.contains("..")
    }
}
