import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: InstallStore

    var body: some View {
        TabView {
            Form {
                Section {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("Watch Folder")
                            .frame(width: 100, alignment: .trailing)

                        Text(store.watchedFolderURL.path(percentEncoded: false))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .textSelection(.enabled)

                        Spacer()

                        Button("Choose...") {
                            store.chooseWatchedFolder()
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("General", systemImage: "gearshape")
            }
        }
        .frame(width: 560, height: 180)
        .scenePadding()
    }
}
