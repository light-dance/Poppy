import Foundation

struct InstallRecord: Identifiable {
    enum Result {
        case success
        case cancelled
        case failed
    }

    let id = UUID()
    let appName: String
    let sourceName: String
    let date: Date
    let result: Result
    let detail: String
}
