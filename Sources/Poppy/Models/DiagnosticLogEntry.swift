import Foundation

struct DiagnosticLogEntry: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let message: String
}
