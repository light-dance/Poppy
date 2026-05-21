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
    private weak var mainWindow: NSWindow?
    private var shouldBringMainWindowForward = false
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

        if let mainWindow {
            bringMainWindowForward(mainWindow)
            return
        }

        shouldBringMainWindowForward = true
        openMainWindow?()
        NSApp.activate(ignoringOtherApps: true)
    }

    func showSettings(openSettings: () -> Void) {
        let windowsBeforeOpeningSettings = Set(NSApp.windows.map { ObjectIdentifier($0) })

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        openSettings()

        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            self.bringSettingsWindowForward(excluding: windowsBeforeOpeningSettings)
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
        mainWindow = window

        guard !observedMainWindows.contains(id) else {
            if shouldBringMainWindowForward {
                bringMainWindowForward(window)
            }
            return
        }

        observedMainWindows.insert(id)
        updateActivationPolicy()

        if shouldBringMainWindowForward {
            bringMainWindowForward(window)
        }

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
                if self.mainWindow === window {
                    self.mainWindow = nil
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

    private func bringMainWindowForward(_ window: NSWindow) {
        shouldBringMainWindowForward = false
        NSApp.setActivationPolicy(.regular)
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func bringSettingsWindowForward(excluding previousWindowIDs: Set<ObjectIdentifier>) {
        let settingsWindow = newlyPresentedSettingsWindow(excluding: previousWindowIDs) ?? existingPresentedSettingsWindow()

        if let settingsWindow {
            observePresentedWindow(settingsWindow)
            settingsWindow.makeKeyAndOrderFront(nil)
        }
    }

    private func newlyPresentedSettingsWindow(excluding previousWindowIDs: Set<ObjectIdentifier>) -> NSWindow? {
        NSApp.windows.first { window in
            isSettingsWindowCandidate(window) && !previousWindowIDs.contains(ObjectIdentifier(window))
        }
    }

    private func existingPresentedSettingsWindow() -> NSWindow? {
        NSApp.windows.first { window in
            isSettingsWindowCandidate(window)
                && !observedMainWindows.contains(ObjectIdentifier(window))
                && !(window is NSPanel)
        }
    }

    private func isSettingsWindowCandidate(_ window: NSWindow) -> Bool {
        window.isVisible && window.canBecomeKey
    }
}
