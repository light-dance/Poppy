import AppKit
import SwiftUI

struct WindowLifecycleReporter: NSViewRepresentable {
    let onWindowAvailable: (NSWindow) -> Void

    func makeNSView(context: Context) -> WindowReportingView {
        WindowReportingView(onWindowAvailable: onWindowAvailable)
    }

    func updateNSView(_ nsView: WindowReportingView, context: Context) {
        nsView.onWindowAvailable = onWindowAvailable
        nsView.reportWindowIfAvailable()
    }
}

final class WindowReportingView: NSView {
    var onWindowAvailable: (NSWindow) -> Void

    init(onWindowAvailable: @escaping (NSWindow) -> Void) {
        self.onWindowAvailable = onWindowAvailable
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        reportWindowIfAvailable()
    }

    func reportWindowIfAvailable() {
        guard let window else { return }
        onWindowAvailable(window)
    }
}
