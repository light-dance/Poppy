import Foundation

nonisolated struct ShellResult: Sendable {
    let status: Int32
    let output: String
    let error: String
}

nonisolated enum Shell {
    /// Runs a command off the main actor. Cancelling the calling task terminates the process.
    static func run(_ executable: String, arguments: [String]) async throws -> ShellResult {
        let process = ShellProcess(executable: executable, arguments: arguments)
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                // Blocking pipe reads and waits run on GCD so they can't starve Swift's small cooperative pool.
                DispatchQueue.global(qos: .userInitiated).async {
                    continuation.resume(with: Result { try process.runToCompletion() })
                }
            }
        } onCancel: {
            process.terminate()
        }
    }
}

private nonisolated final class ShellProcess: @unchecked Sendable {
    private let process = Process()
    private let lock = NSLock()
    private var isTerminated = false
    private var errorData = Data()

    init(executable: String, arguments: [String]) {
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        // Never let a tool (e.g. hdiutil license prompts) block waiting on input.
        process.standardInput = FileHandle.nullDevice
    }

    func runToCompletion() throws -> ShellResult {
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try lock.withLock {
            guard !isTerminated else { throw CancellationError() }
            try process.run()
        }

        // Drain both pipes concurrently so neither fills up and blocks the process.
        let errorGroup = DispatchGroup()
        DispatchQueue.global(qos: .userInitiated).async(group: errorGroup) {
            self.errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        }
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        errorGroup.wait()
        process.waitUntilExit()

        let output = String(data: outputData, encoding: .utf8) ?? ""
        let error = String(data: errorData, encoding: .utf8) ?? ""
        return ShellResult(status: process.terminationStatus, output: output, error: error)
    }

    func terminate() {
        lock.withLock {
            isTerminated = true
            if process.isRunning {
                process.terminate()
            }
        }
    }
}
