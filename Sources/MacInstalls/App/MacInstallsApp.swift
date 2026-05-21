import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let panelController = FloatingInstallPanelController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
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
    @Environment(\.openWindow) private var openWindow
    @StateObject private var store = InstallStore()

    var body: some Scene {
        WindowGroup("Mac Installs", id: "main") {
            StatusWindowView(store: store)
                .frame(minWidth: 560, minHeight: 420)
                .toolbar(removing: .title)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                .containerBackground(.thinMaterial, for: .window)
                .task {
                    appDelegate.bind(to: store)
                    store.start()
                }
        }
        .defaultSize(width: 770, height: 605)
        .restorationBehavior(.disabled)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .windowArrangement) {}

            CommandMenu("Debug") {
                Button("Notification: Approval") {
                    store.simulateNotification(.awaitingApproval)
                }

                Button("Notification: Installing") {
                    store.simulateNotification(.installing("Copying ExampleApp"))
                }

                Button("Notification: Installed") {
                    store.simulateNotification(
                        .installed(appURL: store.installFolderURL.appendingPathComponent("ExampleApp.app", isDirectory: true))
                    )
                }

                Button("Notification: Failed") {
                    store.simulateNotification(
                        .failed("Could not copy ExampleApp into the install folder. Permission denied.")
                    )
                }

                Divider()

                Button("Dismiss Notification") {
                    store.dismissSimulatedNotification()
                }
            }
        }

        MenuBarExtra("Mac Installs", systemImage: "opticaldiscdrive") {
            Button {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("Open Mac Installs", systemImage: "sidebar.left")
            }
            .keyboardShortcut("o")

            if !store.readyItems.isEmpty {
                Divider()

                ForEach(store.readyItems) { item in
                    Menu {
                        Button {
                            store.installNow(item)
                        } label: {
                            Label("Install Now", systemImage: "arrow.down.app")
                        }
                    } label: {
                        Label(item.displayName, systemImage: "opticaldiscdrive")
                    }
                }
            }

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
