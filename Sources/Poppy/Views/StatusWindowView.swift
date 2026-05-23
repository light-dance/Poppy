import AppKit
import SwiftUI

struct StatusWindowView: View {
    @ObservedObject var store: InstallStore
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
        HStack(spacing: 10) {
            Button {
                store.isWatching ? store.stop() : store.start()
            } label: {
                Label(store.isWatching ? "Pause" : "Watch", systemImage: store.isWatching ? "pause.fill" : "play.fill")
            }
            .buttonStyle(.bordered)

            Button {
                store.chooseWatchedFolder()
            } label: {
                Label("Downloads Location", systemImage: "folder")
            }
            .buttonStyle(.bordered)

            Button {
                store.chooseInstallFolder()
            } label: {
                Label("Install Location", systemImage: "folder.badge.plus")
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
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
