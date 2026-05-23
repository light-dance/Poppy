import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let lifecycle = AppLifecycleController()
    private let panelController = FloatingInstallPanelController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        lifecycle.applicationDidFinishLaunching()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        lifecycle.applicationShouldHandleReopen(hasVisibleWindows: flag)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @MainActor
    func bind(to store: InstallStore) {
        panelController.bind(to: store)
    }

    @MainActor
    func setNotificationPosition(_ position: NotificationPosition) {
        panelController.setNotificationPosition(position)
    }
}

@main
struct PoppyApp: App {
    private static let menuItemNameLimit = 22

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @AppStorage(AppLifecycleController.hideInDockKey) private var hideInDock = false
    @AppStorage(AppLifecycleController.hideInMenuBarKey) private var hideInMenuBar = false
    @AppStorage(NotificationPosition.storageKey) private var notificationPositionValue = NotificationPosition.topRight.rawValue
    @StateObject private var store = InstallStore()

    var body: some Scene {
        WindowGroup("Poppy", id: "main") {
            StatusWindowView(store: store)
                .frame(minWidth: 560, minHeight: 420)
                .toolbar(removing: .title)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                .containerBackground(.thinMaterial, for: .window)
                .task {
                    appDelegate.lifecycle.configure {
                        openWindow(id: "main")
                    }
                    appDelegate.lifecycle.setHideInDock(hideInDock)
                    appDelegate.lifecycle.setHideInMenuBar(hideInMenuBar)
                    appDelegate.setNotificationPosition(notificationPosition)
                    appDelegate.bind(to: store)
                    store.start()
                }
                .background {
                    WindowLifecycleReporter { window in
                        appDelegate.lifecycle.observeMainWindow(window)
                    }
                    .frame(width: 0, height: 0)
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
                        .failed("Check install folder permissions.")
                    )
                }

                Divider()

                Button("Dismiss Notification") {
                    store.dismissSimulatedNotification()
                }
            }
        }

        MenuBarExtra(
            "Poppy",
            systemImage: menuBarSystemImage,
            isInserted: Binding(
                get: { !hideInMenuBar },
                set: { hideInMenuBar = !$0 }
            )
        ) {
            Button {
                appDelegate.lifecycle.showMainWindow()
            } label: {
                Label("Open Poppy", systemImage: "sidebar.left")
            }
            .keyboardShortcut("o")

            if !store.readyItems.isEmpty {
                Divider()

                ForEach(store.readyItems) { item in
                    Menu {
                        Button {
                            store.installNow(item)
                        } label: {
                            Label("Install", systemImage: "arrow.down.app")
                        }

                        Button(role: .destructive) {
                            store.cleanup(item)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            store.hide(item)
                        } label: {
                            Label("Hide", systemImage: "eye.slash")
                        }
                    } label: {
                        Label(menuItemTitle(for: item), systemImage: "plus.app")
                    }
                }
            }

            Divider()

            Button {
                appDelegate.lifecycle.showSettings {
                    openSettings()
                }
            } label: {
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
            SettingsView(
                store: store,
                hideInDock: Binding(
                    get: { hideInDock },
                    set: { newValue in
                        hideInDock = newValue
                        appDelegate.lifecycle.setHideInDock(newValue)
                    }
                ),
                hideInMenuBar: Binding(
                    get: { hideInMenuBar },
                    set: { newValue in
                        hideInMenuBar = newValue
                        appDelegate.lifecycle.setHideInMenuBar(newValue)
                    }
                ),
                notificationPosition: Binding(
                    get: { notificationPosition },
                    set: { newValue in
                        notificationPositionValue = newValue.rawValue
                        appDelegate.setNotificationPosition(newValue)
                    }
                )
            )
            .background {
                WindowLifecycleReporter { window in
                    appDelegate.lifecycle.observeSettingsWindow(window)
                }
                .frame(width: 0, height: 0)
            }
        }
    }

    private func menuItemTitle(for item: InstallableItem) -> String {
        item.displayName.truncated(to: Self.menuItemNameLimit)
    }

    private var menuBarSystemImage: String {
        if !store.readyItems.isEmpty || store.currentJob != nil {
            return "arrow.down.circle.fill"
        }

        return "arrow.down.circle.dotted"
    }

    private var notificationPosition: NotificationPosition {
        NotificationPosition(rawValue: notificationPositionValue) ?? .topRight
    }
}

private extension String {
    func truncated(to maxLength: Int) -> String {
        guard count > maxLength else { return self }
        guard maxLength > 3 else { return String(prefix(maxLength)) }
        return String(prefix(maxLength - 3)) + "..."
    }
}
