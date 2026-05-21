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
            Button {
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("Open Mac Installs", systemImage: "sidebar.left")
            }
            .keyboardShortcut("o")

            Divider()

            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }
            .keyboardShortcut(",")

            Button {
                NSApp.terminate(nil)
            } label: {
                Label("Quit", systemImage: "xmark.rectangle")
            }
            .keyboardShortcut("q")
        }

        Settings {
            SettingsView(store: store)
        }
    }
}
