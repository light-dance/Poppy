import SwiftUI

struct DiagnosticLogView: View {
    @ObservedObject var store: InstallStore

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            if store.diagnosticLogEntries.isEmpty {
                ContentUnavailableView(
                    "No Logs Yet",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Watcher and installer diagnostics will appear here.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(store.diagnosticLogEntries) { entry in
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text(Self.timeFormatter.string(from: entry.date))
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 92, alignment: .leading)

                                Text(entry.message)
                                    .font(.system(.callout, design: .monospaced))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 14)
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
        }
        .frame(minWidth: 680, minHeight: 420)
    }

    private var header: some View {
        HStack {
            Text("Logs")
                .font(.headline)

            Spacer()

            Button {
                store.clearDiagnosticLog()
            } label: {
                Label("Clear", systemImage: "trash")
            }
            .disabled(store.diagnosticLogEntries.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
