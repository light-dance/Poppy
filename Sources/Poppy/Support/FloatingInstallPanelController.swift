import AppKit
import Combine
import SwiftUI

@MainActor
final class FloatingInstallPanelController {
    private static let minimumPanelSize = NSSize(width: 300, height: 62)
    private static let maximumPanelSize = NSSize(width: 500, height: 62)
    private static let screenPadding: CGFloat = 24
    private var panel: NSPanel?
    private var cancellable: AnyCancellable?
    private var notificationPosition: NotificationPosition

    init(
        notificationPosition: NotificationPosition = NotificationPosition(
            rawValue: UserDefaults.standard.string(forKey: NotificationPosition.storageKey) ?? ""
        ) ?? .topRight
    ) {
        self.notificationPosition = notificationPosition
    }

    func bind(to store: InstallStore) {
        cancellable = store.$currentJob.sink { [weak self, weak store] job in
            guard let self, let store else { return }
            if let job {
                self.show(job: job, store: store)
            } else {
                self.close()
            }
        }
    }

    func setNotificationPosition(_ position: NotificationPosition) {
        notificationPosition = position
        positionPanel()
    }

    private func show(job: InstallJob, store: InstallStore) {
        if panel == nil {
            panel = makePanel()
        }

        let hostingController = NSHostingController(
            rootView: FloatingInstallPanelView(job: job, store: store)
        )
        panel?.contentViewController = hostingController
        updatePanelSize(for: hostingController)
        positionPanel()
        panel?.orderFrontRegardless()
    }

    private func close() {
        panel?.orderOut(nil)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: Self.maximumPanelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        return panel
    }

    private func positionPanel() {
        guard let panel else { return }
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let size = panel.frame.size
        let origin = panelOrigin(in: screen, size: size)
        panel.setFrame(
            NSRect(
                x: origin.x,
                y: origin.y,
                width: size.width,
                height: size.height
            ),
            display: true
        )
    }

    private func panelOrigin(in screen: NSRect, size: NSSize) -> NSPoint {
        switch notificationPosition {
        case .topLeft:
            return NSPoint(
                x: screen.minX + Self.screenPadding,
                y: screen.maxY - size.height - Self.screenPadding
            )
        case .topCenter:
            return NSPoint(
                x: screen.midX - (size.width / 2),
                y: screen.maxY - size.height - Self.screenPadding
            )
        case .topRight:
            return NSPoint(
                x: screen.maxX - size.width - Self.screenPadding,
                y: screen.maxY - size.height - Self.screenPadding
            )
        }
    }

    private func updatePanelSize(for hostingController: NSHostingController<FloatingInstallPanelView>) {
        guard let panel else { return }
        hostingController.view.layoutSubtreeIfNeeded()
        let fittingSize = hostingController.view.fittingSize
        let width = min(Self.maximumPanelSize.width, max(Self.minimumPanelSize.width, fittingSize.width))
        panel.setFrame(
            NSRect(origin: panel.frame.origin, size: NSSize(width: width, height: Self.maximumPanelSize.height)),
            display: false
        )
    }
}
