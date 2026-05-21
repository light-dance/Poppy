import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: InstallStore
    @Binding var hideInDock: Bool
    @Binding var hideInMenuBar: Bool

    var body: some View {
        TabView {
            Form {
                Section {
                    SettingsFolderRow(
                        title: "Downloads",
                        path: store.watchedFolderURL.path(percentEncoded: false)
                    ) {
                        store.chooseWatchedFolder()
                    }

                    SettingsFolderRow(
                        title: "Install To",
                        path: store.installFolderURL.path(percentEncoded: false)
                    ) {
                        store.chooseInstallFolder()
                    }
                }

                Section("Appearance") {
                    Toggle("Hide in Dock", isOn: $hideInDock)

                    Toggle("Hide in menu bar", isOn: $hideInMenuBar)

                    if hideInDock && hideInMenuBar {
                        Label(
                            "Opening Poppy from Finder or Spotlight will show this window and restore the Dock icon until the window closes.",
                            systemImage: "info.circle"
                        )
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("General", systemImage: "gearshape")
            }
        }
        .frame(width: 620, height: 340)
        .scenePadding()
    }
}

private struct SettingsFolderRow: View {
    let title: String
    let path: String
    let choose: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .frame(width: 100, alignment: .trailing)

            Text(path)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)

            Spacer()

            Button("Choose...") {
                choose()
            }
        }
    }
}
