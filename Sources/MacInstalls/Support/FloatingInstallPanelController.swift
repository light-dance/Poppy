import AppKit
import Combine
import SwiftUI

@MainActor
final class FloatingInstallPanelController {
    private var panel: NSPanel?
    private var cancellable: AnyCancellable?

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

    private func show(job: InstallJob, store: InstallStore) {
        if panel == nil {
            panel = makePanel()
        }

        panel?.contentViewController = NSHostingController(
            rootView: FloatingInstallPanelView(job: job, store: store)
        )
        positionPanel()
        panel?.orderFrontRegardless()
    }

    private func close() {
        panel?.orderOut(nil)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 190),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
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
        let size = NSSize(width: 420, height: 190)
        panel.setFrame(
            NSRect(
                x: screen.maxX - size.width - 24,
                y: screen.maxY - size.height - 24,
                width: size.width,
                height: size.height
            ),
            display: true
        )
    }
}
