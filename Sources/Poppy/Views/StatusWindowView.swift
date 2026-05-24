import AppKit
import SwiftUI

struct StatusWindowView: View {
    @ObservedObject var store: InstallStore
    let openSettings: () -> Void
    @State private var installedDisplayMode: InstalledDisplayMode = .list
    @State private var isHiddenSectionExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                List {
                    if !store.installingItems.isEmpty {
                        Section("In Progress") {
                            ForEach(store.installingItems) { item in
                                InstallableItemRow(item: item) {}
                            }
                        }
                    }

                    if !store.readyItems.isEmpty {
                        Section("Ready To Install") {
                            ForEach(store.readyItems) { item in
                                InstallableItemRow(item: item) {
                                    Button {
                                        store.installNow(item)
                                    } label: {
                                        Label("Install", systemImage: "arrow.down.app")
                                    }

                                    Menu {
                                        itemActions(for: item, hideActionTitle: "Hide")
                                    } label: {
                                        Label("More", systemImage: "ellipsis.circle")
                                            .labelStyle(.iconOnly)
                                    }
                                    .menuStyle(.button)
                                }
                                .contextMenu {
                                    itemActions(for: item, hideActionTitle: "Hide")
                                }
                            }
                        }
                    }
                }
                .frame(height: transientListHeight)
                .listStyle(.inset)
                .scrollContentBackground(.hidden)

                installedSection

                hiddenSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.clear)
    }

    private var transientListHeight: CGFloat {
        if store.installingItems.isEmpty && store.readyItems.isEmpty {
            return 0
        }

        let rowCount = store.installingItems.count + store.readyItems.count
        let sectionCount = (store.installingItems.isEmpty ? 0 : 1) + (store.readyItems.isEmpty ? 0 : 1)
        return CGFloat(min(260, 48 + rowCount * 46 + sectionCount * 24))
    }

    private var header: some View {
        HStack(spacing: 12) {
            watchToggleButton

            LocationRouteButton(
                watchedFolderURL: store.watchedFolderURL,
                installFolderURL: store.installFolderURL,
                chooseDownloads: {
                    store.chooseWatchedFolder()
                },
                resetDownloads: {
                    store.resetWatchedFolder()
                },
                openDownloads: {
                    store.openWatchedFolder()
                },
                chooseInstall: {
                    store.chooseInstallFolder()
                },
                resetInstall: {
                    store.resetInstallFolder()
                },
                openInstall: {
                    store.openInstallFolder()
                }
            )

            settingsButton
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var watchToggleButton: some View {
        Button {
            store.isWatching ? store.stop() : store.start()
        } label: {
            watchToggleButtonLabel
        }
        .buttonStyle(.plain)
        .accessibilityLabel(store.isWatching ? "Pause watching" : "Start watching")
        .help("Pause Watching Downloads")
    }

    @ViewBuilder
    private var watchToggleButtonLabel: some View {
        let iconName = store.isWatching ? "pause.fill" : "play.fill"

        circleGlassIcon(systemImage: iconName)
    }

    private var settingsButton: some View {
        Button {
            openSettings()
        } label: {
            circleGlassIcon(systemImage: "gearshape.fill")
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open Settings")
        .help("Open Settings")
    }

    @ViewBuilder
    private func circleGlassIcon(systemImage: String) -> some View {
        if #available(macOS 26.0, *) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .frame(width: 42, height: 42)
                .glassEffect(.regular.interactive(), in: Circle())
        } else {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .frame(width: 42, height: 42)
                .background(.regularMaterial, in: Circle())
        }
    }

    private var installedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Installed")
                    .font(.title2.weight(.semibold))

                Spacer()

                Picker("Installed View", selection: $installedDisplayMode) {
                    Label("List", systemImage: "list.bullet").tag(InstalledDisplayMode.list)
                    Label("Grid", systemImage: "square.grid.2x2").tag(InstalledDisplayMode.grid)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 150)
            }

            if store.installedItems.isEmpty {
                Label("No installed apps to delete", systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else if installedDisplayMode == .list {
                VStack(spacing: 0) {
                    ForEach(store.installedItems) { item in
                        InstallableItemRow(item: item) {
                            Button(role: .destructive) {
                                store.cleanup(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            itemActions(for: item, hideActionTitle: "Hide")
                        }
                    }
                }
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 18)], alignment: .leading, spacing: 18) {
                    ForEach(store.installedItems) { item in
                        InstalledGridItem(item: item)
                            .contextMenu {
                                itemActions(for: item, hideActionTitle: "Hide")
                            }
                    }
                }
                .padding(.top, 2)
            }
        }
    }

    @ViewBuilder
    private var hiddenSection: some View {
        if !store.hiddenInstallableItems.isEmpty {
            DisclosureGroup(isExpanded: $isHiddenSectionExpanded) {
                VStack(spacing: 0) {
                    ForEach(store.hiddenInstallableItems) { item in
                        InstallableItemRow(item: item) {
                            Menu {
                                itemActions(for: item, hideActionTitle: "Show")
                            } label: {
                                Label("More", systemImage: "ellipsis.circle")
                                    .labelStyle(.iconOnly)
                            }
                            .menuStyle(.button)
                        }
                        .contextMenu {
                            itemActions(for: item, hideActionTitle: "Show")
                        }
                    }
                }
                .padding(.top, 6)
            } label: {
                HStack(spacing: 6) {
                    Text("Hidden")
                        .font(.title3.weight(.semibold))

                    Text("\(store.hiddenInstallableItems.count)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func itemActions(for item: InstallableItem, hideActionTitle: String) -> some View {
        if case .installed = item.status {
            Button {
                store.openApp(item)
            } label: {
                Label("Open App", systemImage: "arrow.up.right.square")
            }
        } else if case .installing = item.status {
            EmptyView()
        } else {
            Button {
                store.installNow(item)
            } label: {
                Label("Install", systemImage: "arrow.down.app")
            }
        }

        Button(role: .destructive) {
            store.cleanup(item)
        } label: {
            Label("Delete", systemImage: "trash")
        }

        Button {
            if hideActionTitle == "Show" {
                store.unhide(item)
            } else {
                store.hide(item)
            }
        } label: {
            Label(hideActionTitle, systemImage: hideActionTitle == "Show" ? "eye" : "eye.slash")
        }
    }
}

private struct LocationRouteButton: View {
    private static let segmentWidth: CGFloat = 178

    let watchedFolderURL: URL
    let installFolderURL: URL
    let chooseDownloads: () -> Void
    let resetDownloads: () -> Void
    let openDownloads: () -> Void
    let chooseInstall: () -> Void
    let resetInstall: () -> Void
    let openInstall: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        label
    }

    @ViewBuilder
    private var label: some View {
        if #available(macOS 26.0, *) {
            content
                .frame(height: 42)
                .glassEffect(.regular.interactive(), in: Capsule())
        } else {
            content
                .frame(height: 42)
                .background(.regularMaterial, in: Capsule())
        }
    }

    private var content: some View {
        HStack(spacing: 0) {
            locationSegment(
                title: "Watching",
                systemImage: "arrow.down.circle.fill",
                defaultName: "Downloads",
                url: watchedFolderURL,
                defaultURL: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads", isDirectory: true),
                iconPlacement: .leading,
                action: chooseDownloads,
                reset: resetDownloads,
                open: openDownloads
            )

            ZStack {
                Rectangle()
                    .fill(.primary.opacity(0.12))
                    .frame(width: 1)

                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 24, height: 24)
                    .background(Color.accentColor, in: Circle())
                    .compositingGroup()
                    .zIndex(1)
            }
            .frame(width: 28, height: 42)

            locationSegment(
                title: "Install To",
                systemImage: "circle.grid.3x3.circle.fill",
                defaultName: "Applications",
                url: installFolderURL,
                defaultURL: URL(fileURLWithPath: "/Applications", isDirectory: true),
                iconPlacement: .trailing,
                action: chooseInstall,
                reset: resetInstall,
                open: openInstall
            )
        }
        .foregroundStyle(.primary)
    }

    private func locationSegment(
        title: String,
        systemImage: String,
        defaultName: String,
        url: URL,
        defaultURL: URL,
        iconPlacement: LocationIconPlacement,
        action: @escaping () -> Void,
        reset: @escaping () -> Void,
        open: @escaping () -> Void
    ) -> some View {
        LocationSegmentButton(
            title: title,
            systemImage: systemImage,
            defaultName: defaultName,
            url: url,
            defaultURL: defaultURL,
            iconPlacement: iconPlacement,
            action: action,
            reset: reset,
            open: open
        )
        .frame(width: Self.segmentWidth, height: 42)
    }

}

private enum LocationIconPlacement {
    case leading
    case trailing
}

private struct LocationSegmentButton: View {
    let title: String
    let systemImage: String
    let defaultName: String
    let url: URL
    let defaultURL: URL
    let iconPlacement: LocationIconPlacement
    let action: () -> Void
    let reset: () -> Void
    let open: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if iconPlacement == .leading {
                    segmentIcon
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .lineLimit(1)

                    if isHovered {
                        Text("Choose...")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        locationDetail
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isHovered {
                    hoverButtons
                }

                if iconPlacement == .trailing {
                    segmentIcon
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.leading, iconPlacement == .leading ? 12 : 14)
            .padding(.trailing, iconPlacement == .trailing ? 12 : 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    private var segmentIcon: some View {
        Image(systemName: systemImage)
            .font(.system(size: 20, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.primary)
            .frame(width: 22)
    }

    private var hoverButtons: some View {
        HStack(spacing: 5) {
            utilityButton(systemImage: "arrow.counterclockwise", action: reset, help: "Reset to Default")
            utilityButton(systemImage: "folder", action: open, help: "Open in Finder")
        }
    }

    private func utilityButton(systemImage: String, action: @escaping () -> Void, help: String) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
        .help(help)
    }

    @ViewBuilder
    private var locationDetail: some View {
        if url.standardizedFileURL == defaultURL.standardizedFileURL {
            (Text("Default ")
                .fontWeight(.semibold)
             + Text(defaultName)
                .fontWeight(.regular))
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        } else {
            Text(shortPath(for: url))
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.head)
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

private enum InstalledDisplayMode {
    case list
    case grid
}

private struct InstallableItemRow<Actions: View>: View {
    let item: InstallableItem
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        HStack(spacing: 12) {
            rowIcon
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            actions()
        }
        .padding(.vertical, 5)
    }

    @ViewBuilder
    private var rowIcon: some View {
        switch item.status {
        case .installed(let appURL):
            Image(nsImage: NSWorkspace.shared.icon(forFile: appURL.path))
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
        case .ready:
            Image(systemName: "arrow.down.circle.fill")
                .foregroundStyle(Color.accentColor)
                .frame(width: 24, height: 24)
        case .installing:
            Image(systemName: "arrow.down.circle")
                .foregroundStyle(.orange)
                .frame(width: 24, height: 24)
        }
    }

    private var detail: String {
        switch item.status {
        case .ready:
            item.url.lastPathComponent
        case .installing(let step):
            step
        case .installed(let appURL):
            "Installed as \(appURL.lastPathComponent)"
        }
    }
}

private struct EmptySectionRow: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .foregroundStyle(.secondary)
            .padding(.vertical, 5)
    }
}

private struct InstalledGridItem: View {
    let item: InstallableItem

    var body: some View {
        VStack(spacing: 6) {
            icon
                .frame(width: 52, height: 52)
        }
        .frame(width: 72, height: 72)
        .contentShape(Rectangle())
    }

    private var icon: some View {
        Group {
            if case .installed(let appURL) = item.status {
                Image(nsImage: NSWorkspace.shared.icon(forFile: appURL.path))
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "app.dashed")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
        }
    }
}
