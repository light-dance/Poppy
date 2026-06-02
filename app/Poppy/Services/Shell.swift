import Foundation

struct ShellResult {
    let status: Int32
    let output: String
    let error: String
}

enum Shell {
    static func run(_ executable: String, arguments: [String]) async throws -> ShellResult {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            try process.run()

            async let outputData = outputPipe.fileHandleForReading.readToEnd() ?? Data()
            async let errorData = errorPipe.fileHandleForReading.readToEnd() ?? Data()
            process.waitUntilExit()

            let output = String(data: try await outputData, encoding: .utf8) ?? ""
            let error = String(data: try await errorData, encoding: .utf8) ?? ""
            return ShellResult(status: process.terminationStatus, output: output, error: error)
        }.value
    }
}
