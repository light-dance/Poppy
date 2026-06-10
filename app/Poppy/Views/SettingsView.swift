import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: InstallStore
    @Binding var hideInDock: Bool
    @Binding var hideInMenuBar: Bool
    @Binding var launchAtLogin: Bool
    @Binding var deleteAfterInstall: Bool
    @Binding var automaticallyInstallDetectedApplications: Bool
    @Binding var notificationPosition: NotificationPosition
    @Binding var notificationDismissalDelay: NotificationDismissalDelay
    @Binding var automaticallyChecksForUpdates: Bool

    var body: some View {
        Form {
            Section("Locations") {
                SettingsFolderRow(
                    title: "Watching",
                    url: store.watchedFolderURL,
                    defaultName: "Downloads",
                    defaultURL: store.defaultWatchedFolderURL
                ) {
                    store.chooseWatchedFolder()
                } reset: {
                    store.resetWatchedFolder()
                } open: {
                    store.openWatchedFolder()
                }

                SettingsFolderRow(
                    title: "Install To",
                    url: store.installFolderURL,
                    defaultName: "Applications",
                    defaultURL: store.defaultInstallFolderURL
                ) {
                    store.chooseInstallFolder()
                } reset: {
                    store.resetInstallFolder()
                } open: {
                    store.openInstallFolder()
                }
            }

            Section("General") {
                Toggle("Launch at Login", isOn: $launchAtLogin)

                Toggle("Delete after Install", isOn: $deleteAfterInstall)

                Toggle("Install Automatically", isOn: autoInstallBinding)

                if automaticallyInstallDetectedApplications {
                    Label(
                        "Poppy will install newly detected apps after \(AutoInstallDetectedApplications.delaySeconds) seconds unless you cancel.",
                        systemImage: "exclamationmark.triangle"
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
            }

            Section("Updates") {
                Toggle("Check for Updates Automatically", isOn: $automaticallyChecksForUpdates)
            }

            Section("Appearance") {
                Picker("Dismiss Notification", selection: $notificationDismissalDelay) {
                    ForEach(NotificationDismissalDelay.allCases) { delay in
                        Text(delay.title)
                            .tag(delay)
                    }
                }
                .pickerStyle(.menu)

                NotificationPositionPicker(selection: $notificationPosition)

                Toggle("Hide in Dock", isOn: $hideInDock)

                Toggle("Hide in menu bar", isOn: $hideInMenuBar)

                if hideInDock && hideInMenuBar {
                    Label(
                        "Opening Poppy from Finder or Spotlight will show this window and restore the Dock icon until the window closes.",
                        systemImage: "info.circle"
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 8, for: .scrollContent)
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .contentMargins(.bottom, 16, for: .scrollContent)
        .frame(width: 570, height: 720)
    }

    private var autoInstallBinding: Binding<Bool> {
        Binding(
            get: { automaticallyInstallDetectedApplications },
            set: { newValue in
                guard newValue else {
                    automaticallyInstallDetectedApplications = false
                    return
                }

                if confirmAutoInstall() {
                    automaticallyInstallDetectedApplications = true
                }
            }
        )
    }

    private func confirmAutoInstall() -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Automatically Install Downloaded Applications?"
        alert.informativeText = "Apps will be moved to your Applications folder without needing your confirmation. This could be dangerous."
        alert.addButton(withTitle: "Turn On Auto Install")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }
}

private struct NotificationPositionPicker: View {
    private static let previewSize = CGSize(width: 298, height: 132)
    private static let previewCornerRadius: CGFloat = 20

    @Binding var selection: NotificationPosition
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Notification Position")

                Text(selection.title)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            ZStack(alignment: .top) {
                wallpaperPreview
                    .allowsHitTesting(false)

                radioButton(for: .topLeft)
                    .position(x: 22, y: 21)

                radioButton(for: .topCenter)
                    .position(x: Self.previewSize.width / 2, y: 21)

                radioButton(for: .topRight)
                    .position(x: Self.previewSize.width - 22, y: 21)
            }
            .frame(width: Self.previewSize.width, height: Self.previewSize.height)
            .accessibilityElement(children: .contain)
        }
    }

    @ViewBuilder
    private var wallpaperPreview: some View {
        if let image = wallpaperImage {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: Self.previewSize.width, height: Self.previewSize.height)
                .clipped()
                .blur(radius: 2)
                .mask(bottomFadeMask)
                .clipShape(TopRoundedRectangle(radius: Self.previewCornerRadius))
        } else {
            Rectangle()
                .fill(fallbackWallpaperGradient)
                .blur(radius: 2)
                .mask(bottomFadeMask)
                .clipShape(TopRoundedRectangle(radius: Self.previewCornerRadius))
        }
    }

    private var wallpaperImage: NSImage? {
        let name = colorScheme == .dark ? "desktop-wallpaper-tahoe-dark" : "desktop-wallpaper-tahoe-light"
        guard let url = Bundle.main.url(forResource: name, withExtension: "jpg")
            ?? Bundle.main.url(forResource: name, withExtension: "png")
            ?? Bundle.main.url(forResource: name, withExtension: "heic")
        else {
            return nil
        }

        return NSImage(contentsOf: url)
    }

    private var bottomFadeMask: some View {
        LinearGradient(
            stops: [
                .init(color: .black, location: 0),
                .init(color: .black, location: 0.33),
                .init(color: .black.opacity(0.55), location: 0.58),
                .init(color: .black.opacity(0.12), location: 0.82),
                .init(color: .clear, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var fallbackWallpaperGradient: some ShapeStyle {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.08, green: 0.18, blue: 0.25),
                    Color(red: 0.13, green: 0.32, blue: 0.44),
                    Color(red: 0.06, green: 0.17, blue: 0.13)
                ]
                : [
                    Color(red: 0.42, green: 0.66, blue: 0.88),
                    Color(red: 0.30, green: 0.55, blue: 0.76),
                    Color(red: 0.58, green: 0.70, blue: 0.56)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func radioButton(for position: NotificationPosition) -> some View {
        NativeRadioButton(
            isSelected: selection == position,
            select: {
                selection = position
            }
        )
        .accessibilityLabel(position.title)
        .frame(width: 58, height: 58)
        .contentShape(Rectangle())
    }
}

private struct TopRoundedRectangle: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let radius = min(radius, rect.width / 2, rect.height / 2)
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

private struct NativeRadioButton: NSViewRepresentable {
    let isSelected: Bool
    let select: () -> Void

    func makeNSView(context: Context) -> RadioHitTargetView {
        let view = RadioHitTargetView()
        view.button.target = context.coordinator
        view.button.action = #selector(Coordinator.didSelect)
        view.onSelect = {
            context.coordinator.didSelect()
        }
        return view
    }

    func updateNSView(_ view: RadioHitTargetView, context: Context) {
        context.coordinator.onSelect = select
        view.onSelect = {
            context.coordinator.didSelect()
        }
        view.button.state = isSelected ? .on : .off
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: select)
    }

    final class Coordinator: NSObject {
        var onSelect: () -> Void

        init(onSelect: @escaping () -> Void) {
            self.onSelect = onSelect
        }

        @objc func didSelect() {
            onSelect()
        }
    }
}

private final class RadioHitTargetView: NSView {
    let button = NSButton(radioButtonWithTitle: "", target: nil, action: nil)
    var onSelect: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        button.setButtonType(.radio)
        button.isBordered = false
        addSubview(button)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 58, height: 58)
    }

    override func layout() {
        super.layout()
        button.frame = NSRect(
            x: (bounds.width - 18) / 2,
            y: (bounds.height - 18) / 2,
            width: 18,
            height: 18
        )
    }

    override func mouseDown(with event: NSEvent) {
        onSelect?()
    }
}

private struct SettingsFolderRow: View {
    let title: String
    let url: URL
    let defaultName: String
    let defaultURL: URL
    let choose: () -> Void
    let reset: () -> Void
    let open: () -> Void

    @State private var isHoveringLocation = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Text(title)
                    .frame(width: 100, alignment: .trailing)

                locationText
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onHover { isHoveringLocation = $0 }

            Button {
                reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .bold))
            }
            .buttonStyle(.plain)
            .help("Reset to Default Location")

            Button {
                open()
            } label: {
                Image(systemName: "finder")
                    .font(.system(size: 13, weight: .bold))
            }
            .buttonStyle(.plain)
            .help("Open in Finder")

            Button("Choose...") {
                choose()
            }
        }
    }

    @ViewBuilder
    private var locationText: some View {
        if url.standardizedFileURL == defaultURL.standardizedFileURL {
            (Text("Default ")
                .fontWeight(.semibold)
             + Text(defaultName)
                .fontWeight(.regular))
                .foregroundStyle(.secondary)
        } else {
            HoverMarqueeText(
                text: shortPath(for: url),
                isHovering: isHoveringLocation,
                font: .body,
                nsFont: .preferredFont(forTextStyle: .body)
            )
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
        }
    }

    private func shortPath(for url: URL) -> String {
        let path = url.path(percentEncoded: false)
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false)

        if path.hasPrefix(homePath) {
            return "~" + path.dropFirst(homePath.count)
        }

        return path
    }
}

private struct HoverMarqueeText: View {
    let text: String
    let isHovering: Bool
    let font: Font
    let nsFont: NSFont

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var animationStartDate = Date()

    private let speed: CGFloat = 34
    private let startPause: TimeInterval = 0.55
    private let fadeWidth: CGFloat = 14
    private let height: CGFloat = 20
    private let repeatGap: CGFloat = 28

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = max(1, proxy.size.width)
            let contentWidth = measuredWidth(for: text)
            let shouldScroll = isHovering && contentWidth > availableWidth + 1 && !reduceMotion

            ZStack(alignment: .leading) {
                staticText(width: availableWidth)
                    .opacity(isHovering ? 0 : 1)

                if isHovering {
                    marqueeText(width: availableWidth, contentWidth: contentWidth, shouldScroll: shouldScroll)
                        .opacity(1)
                }
            }
            .frame(width: availableWidth, height: height, alignment: .leading)
            .animation(.easeInOut(duration: 0.16), value: isHovering)
            .animation(.easeInOut(duration: 0.16), value: shouldScroll)
        }
        .frame(maxWidth: .infinity, minHeight: height, idealHeight: height, maxHeight: height, alignment: .leading)
        .onChange(of: isHovering) {
            animationStartDate = Date()
        }
        .onChange(of: text) {
            animationStartDate = Date()
        }
    }

    private func staticText(width: CGFloat) -> some View {
        Text(verbatim: text)
            .font(font)
            .lineLimit(1)
            .truncationMode(.head)
            .frame(width: width, height: height, alignment: .leading)
    }

    private func marqueeText(width: CGFloat, contentWidth: CGFloat, shouldScroll: Bool) -> some View {
        TimelineView(.animation) { context in
            let offset = shouldScroll ? offset(at: context.date, contentWidth: contentWidth) : 0

            Group {
                if shouldScroll {
                    HStack(spacing: repeatGap) {
                        singleLineText
                        singleLineText
                    }
                    .offset(x: -offset)
                } else {
                    singleLineText
                }
            }
            .frame(width: width, height: height, alignment: .leading)
            .mask(alignment: .leading) {
                fadeMask(showLeadingFade: offset > 0.5)
                    .frame(width: width, height: height)
            }
        }
    }

    private var singleLineText: some View {
        Text(verbatim: text)
            .font(font)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }

    private func fadeMask(showLeadingFade: Bool) -> some View {
        HStack(spacing: 0) {
            if showLeadingFade {
                LinearGradient(
                    colors: [.clear, .black],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: fadeWidth)
            } else {
                Rectangle()
                    .fill(.black)
                    .frame(width: fadeWidth)
            }

            Rectangle()
                .fill(.black)

            LinearGradient(
                colors: [.black, .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: fadeWidth)
        }
    }

    private func measuredWidth(for text: String) -> CGFloat {
        (text as NSString).size(withAttributes: [.font: nsFont]).width
    }

    private func offset(at date: Date, contentWidth: CGFloat) -> CGFloat {
        let elapsed = date.timeIntervalSince(animationStartDate)
        guard elapsed >= 0 else {
            return 0
        }

        let animationDistance = contentWidth + repeatGap
        let animationDuration = max(0.1, TimeInterval(animationDistance / speed))
        let cycleDuration = startPause + animationDuration
        let cycleElapsed = elapsed.truncatingRemainder(dividingBy: cycleDuration)

        guard cycleElapsed > startPause else {
            return 0
        }

        let movingElapsed = cycleElapsed - startPause
        return animationDistance * CGFloat(movingElapsed / animationDuration)
    }
}
