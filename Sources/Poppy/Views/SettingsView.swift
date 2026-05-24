import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: InstallStore
    @Binding var hideInDock: Bool
    @Binding var hideInMenuBar: Bool
    @Binding var notificationPosition: NotificationPosition

    var body: some View {
        Form {
            Section {
                SettingsFolderRow(
                    title: "Downloads",
                    path: store.watchedFolderURL.path(percentEncoded: false)
                ) {
                    store.chooseWatchedFolder()
                }

                SettingsFolderRow(
                    title: "Install To",
                    path: store.installFolderURL.path(percentEncoded: false)
                ) {
                    store.chooseInstallFolder()
                }
            }

            Section("Appearance") {
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
        guard let url = Bundle.module.url(forResource: name, withExtension: "jpg")
            ?? Bundle.module.url(forResource: name, withExtension: "png")
            ?? Bundle.module.url(forResource: name, withExtension: "heic")
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
    let path: String
    let choose: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .frame(width: 100, alignment: .trailing)

            Text(path)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)

            Spacer()

            Button("Choose...") {
                choose()
            }
        }
    }
}
