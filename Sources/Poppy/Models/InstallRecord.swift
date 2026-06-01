import Foundation
import SwiftData

@Model
final class InstallRecord {
    enum Result: String {
        case success
        case cancelled
        case failed
    }

    var id: UUID
    var appName: String
    var sourceName: String
    var appURLString: String?
    var date: Date
    var resultRawValue: String
    var detail: String

    var appURL: URL? {
        guard let appURLString else { return nil }
        return URL(fileURLWithPath: appURLString)
    }

    var result: Result {
        Result(rawValue: resultRawValue) ?? .failed
    }

    init(
        id: UUID = UUID(),
        appName: String,
        sourceName: String,
        appURL: URL?,
        date: Date,
        result: Result,
        detail: String
    ) {
        self.id = id
        self.appName = appName
        self.sourceName = sourceName
        self.appURLString = appURL?.path
        self.date = date
        self.resultRawValue = result.rawValue
        self.detail = detail
    }
}
