import SwiftUI

struct StatusWindowView: View {
    @ObservedObject var store: InstallStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            List {
                Section("Recent Activity") {
                    if store.records.isEmpty {
                        ContentUnavailableView(
                            "No installs yet",
                            systemImage: "opticaldiscdrive",
                            description: Text("New DMGs added to the watched folder after this app starts will appear here.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 220)
                    } else {
                        ForEach(store.records) { record in
                            RecordRow(record: record)
                        }
                    }
                }
            }
            .listStyle(.inset)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "arrow.down.app")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Mac Installs")
                    .font(.title2.weight(.semibold))
                Text(statusText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                store.promptForLatestDMGInWatchedFolder()
            } label: {
                Label("Check Folder", systemImage: "magnifyingglass")
            }
            .buttonStyle(.bordered)

            Button {
                store.chooseWatchedFolder()
            } label: {
                Label("Folder", systemImage: "folder")
            }
            .buttonStyle(.bordered)

            Button {
                store.isWatching ? store.stop() : store.start()
            } label: {
                Label(store.isWatching ? "Pause" : "Watch", systemImage: store.isWatching ? "pause.fill" : "play.fill")
            }
            .buttonStyle(.bordered)
        }
        .padding(20)
    }

    private var statusText: String {
        let folder = store.watchedFolderURL.path(percentEncoded: false)
        if store.isWatching {
            return "Watching \(folder) for new DMGs"
        }

        return "Watching is paused for \(folder)"
    }
}

private struct RecordRow: View {
    let record: InstallRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.appName)
                    .font(.headline)
                Text(record.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(record.date, style: .time)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 5)
    }

    private var iconName: String {
        switch record.result {
        case .success:
            "checkmark.circle"
        case .cancelled:
            "minus.circle"
        case .failed:
            "exclamationmark.triangle"
        }
    }

    private var iconColor: Color {
        switch record.result {
        case .success:
            .green
        case .cancelled:
            .secondary
        case .failed:
            .red
        }
    }
}
