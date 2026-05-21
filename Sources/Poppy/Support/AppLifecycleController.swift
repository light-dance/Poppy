import AppKit

@MainActor
final class AppLifecycleController: ObservableObject {
    static let hideInDockKey = "hideInDock"
    static let hideInMenuBarKey = "hideInMenuBar"

    @Published private(set) var hideInDock: Bool
    @Published private(set) var hideInMenuBar: Bool

    private var observedMainWindows: Set<ObjectIdentifier> = []
    private var observedPresentedWindows: Set<ObjectIdentifier> = []
    private var notificationObserversByWindow: [ObjectIdentifier: NSObjectProtocol] = [:]
    private var openMainWindow: (() -> Void)?

    init(userDefaults: UserDefaults = .standard) {
        hideInDock = userDefaults.bool(forKey: Self.hideInDockKey)
        hideInMenuBar = userDefaults.bool(forKey: Self.hideInMenuBarKey)
    }

    func applicationDidFinishLaunching() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func configure(openMainWindow: @escaping () -> Void) {
        self.openMainWindow = openMainWindow
    }

    func setHideInDock(_ isHidden: Bool) {
        hideInDock = isHidden
        updateActivationPolicy()
    }

    func setHideInMenuBar(_ isHidden: Bool) {
        hideInMenuBar = isHidden
    }

    func showMainWindow() {
        NSApp.setActivationPolicy(.regular)
        openMainWindow?()
        NSApp.activate(ignoringOtherApps: true)
    }

    func showSettings(openSettings: () -> Void) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        openSettings()

        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            self.bringSettingsWindowForward()
        }
    }

    func applicationShouldHandleReopen(hasVisibleWindows: Bool) -> Bool {
        guard observedMainWindows.isEmpty else {
            NSApp.activate(ignoringOtherApps: true)
            return false
        }

        showMainWindow()
        return false
    }

    func observeMainWindow(_ window: NSWindow) {
        let id = ObjectIdentifier(window)
        guard !observedMainWindows.contains(id) else { return }

        observedMainWindows.insert(id)
        updateActivationPolicy()

        let observer = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self, weak window] _ in
            guard let self, let window else { return }
            Task { @MainActor in
                let id = ObjectIdentifier(window)
                self.observedMainWindows.remove(id)
                if let observer = self.notificationObserversByWindow.removeValue(forKey: id) {
                    NotificationCenter.default.removeObserver(observer)
                }
                self.updateActivationPolicy()
            }
        }

        notificationObserversByWindow[id] = observer
    }

    private func observePresentedWindow(_ window: NSWindow) {
        let id = ObjectIdentifier(window)
        guard !observedMainWindows.contains(id), !observedPresentedWindows.contains(id) else { return }

        observedPresentedWindows.insert(id)

        let observer = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self, weak window] _ in
            guard let self, let window else { return }
            Task { @MainActor in
                let id = ObjectIdentifier(window)
                self.observedPresentedWindows.remove(id)
                if let observer = self.notificationObserversByWindow.removeValue(forKey: id) {
                    NotificationCenter.default.removeObserver(observer)
                }
                self.updateActivationPolicy()
            }
        }

        notificationObserversByWindow[id] = observer
    }

    private func updateActivationPolicy() {
        if hideInDock && observedMainWindows.isEmpty && observedPresentedWindows.isEmpty {
            NSApp.setActivationPolicy(.accessory)
        } else {
            NSApp.setActivationPolicy(.regular)
        }
    }

    private func bringSettingsWindowForward() {
        let settingsWindow = NSApp.windows.first { window in
            window.isVisible && window.title.localizedCaseInsensitiveContains("settings")
        }

        if let settingsWindow {
            observePresentedWindow(settingsWindow)
            settingsWindow.makeKeyAndOrderFront(nil)
        }
    }
}
