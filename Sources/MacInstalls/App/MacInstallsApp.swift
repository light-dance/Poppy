import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let panelController = FloatingInstallPanelController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    @MainActor
    func bind(to store: InstallStore) {
        panelController.bind(to: store)
    }
}

@main
struct MacInstallsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = InstallStore()

    var body: some Scene {
        WindowGroup("Mac Installs") {
            StatusWindowView(store: store)
                .frame(minWidth: 560, minHeight: 420)
                .task {
                    appDelegate.bind(to: store)
                    store.start()
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        MenuBarExtra("Mac Installs", systemImage: "opticaldiscdrive") {
            Button(store.isWatching ? "Watching Folder" : "Start Watching") {
                store.start()
            }
            .disabled(store.isWatching)

            Button("Stop Watching") {
                store.stop()
            }
            .disabled(!store.isWatching)

            Divider()

            Button("Choose Watch Folder...") {
                store.chooseWatchedFolder()
            }

            SettingsLink {
                Text("Settings...")
            }

            Button("Open Mac Installs") {
                NSApp.activate(ignoringOtherApps: true)
            }

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }

        Settings {
            SettingsView(store: store)
        }
    }
}
