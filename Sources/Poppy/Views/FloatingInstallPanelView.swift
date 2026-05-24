import SwiftUI

struct FloatingInstallPanelView: View {
    let job: InstallJob
    @ObservedObject var store: InstallStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            switch job.state {
            case .awaitingApproval:
                approvalView
            case .installing:
                installingView
            case .installed:
                installedView
            default:
                statusView
            }
        }
        .frame(height: 62)
    }

    private var approvalView: some View {
        HStack(spacing: 12) {
            Button {
                store.cancelCurrentInstall()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 40)
                    .background(leftButtonBackground, in: Circle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)

            VStack(alignment: .leading, spacing: 2) {
                Text("Install Downloaded App?")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .lineLimit(1)

                Text(job.sourceURL.lastPathComponent)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(minWidth: 90, maxWidth: 270, alignment: .leading)
            .layoutPriority(1)

            Button {
                store.approveCurrentInstall()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                    Text("Install")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.leading, 12)
                .padding(.trailing, 15)
                .frame(height: 40)
                .background(Color.accentColor, in: Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 11)
        .frame(minHeight: 62)
        .background(capsuleBackground)
        .fixedSize(horizontal: true, vertical: true)
    }

    private var statusView: some View {
        HStack(spacing: 12) {
            if isFailed {
                Button {
                    store.dismissCurrentJob()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.red, in: Circle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            } else {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: iconWeight))
                    .foregroundStyle(iconColor)
                    .frame(width: 40, height: 40)
                    .background(passiveIconBackground, in: Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .lineLimit(1)

                Text(message)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(minWidth: 90, maxWidth: 270, alignment: .leading)
            .layoutPriority(1)

            Spacer(minLength: 10)

            statusAction
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 11)
        .frame(minHeight: 62)
        .background(capsuleBackground)
        .fixedSize(horizontal: true, vertical: true)
    }

    private var installingView: some View {
        HStack(spacing: 12) {
            Button {
                store.cancelCurrentInstall()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 40)
                    .background(leftButtonBackground, in: Circle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .lineLimit(1)

                Text(message)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(minWidth: 90, maxWidth: 270, alignment: .leading)
            .layoutPriority(1)

            ProgressView()
                .controlSize(.small)
                .frame(width: 40, height: 40)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 11)
        .frame(minHeight: 62)
        .background(capsuleBackground)
        .fixedSize(horizontal: true, vertical: true)
    }

    private var installedView: some View {
        HStack(spacing: 12) {
            Button {
                store.dismissCurrentJob()
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 40, height: 40)
                    .background(leftButtonBackground, in: Circle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .lineLimit(1)

                Text(message)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(minWidth: 90, maxWidth: 270, alignment: .leading)
            .layoutPriority(1)

            Button {
                store.openInstalledApp()
            } label: {
                Text("Open")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 82, height: 40)
                    .background(Color.accentColor, in: Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 11)
        .frame(minHeight: 62)
        .background(capsuleBackground)
        .fixedSize(horizontal: true, vertical: true)
    }


    private var capsuleBackground: some View {
        Capsule(style: .continuous)
            .fill(.regularMaterial)
            .overlay {
                Capsule(style: .continuous)
                    .stroke(capsuleStrokeColor, lineWidth: 1)
            }
    }

    @ViewBuilder
    private var statusAction: some View {
        switch job.state {
        case .awaitingApproval:
            EmptyView()
        case .installing:
            ProgressView()
                .controlSize(.small)
                .frame(width: 40, height: 40)
        case .installed:
            Button {
                store.openInstalledApp()
            } label: {
                Text("Open")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 82, height: 40)
                    .background(Color.accentColor, in: Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
        case .failed:
            Button {
                store.dismissCurrentJob()
            } label: {
                Text("Dismiss")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 94, height: 40)
                    .background(dismissButtonBackground, in: Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
        }
    }

    private var title: String {
        switch job.state {
        case .awaitingApproval:
            "Install Downloaded App?"
        case .installing:
            "Installing \(job.displayName)"
        case .installed:
            "\(job.displayName) Installed"
        case .failed:
            "Install failed"
        }
    }

    private var message: String {
        switch job.state {
        case .awaitingApproval:
            job.sourceURL.lastPathComponent
        case .installing(let step):
            step
        case .installed:
            "Downloads Cleaned Up"
        case .failed(let message):
            message
        }
    }

    private var iconName: String {
        switch job.state {
        case .awaitingApproval:
            "questionmark.app"
        case .installing:
            "arrow.down.circle"
        case .installed:
            "checkmark"
        case .failed:
            "exclamationmark.triangle"
        }
    }

    private var iconColor: Color {
        switch job.state {
        case .awaitingApproval:
            .accentColor
        case .installing:
            .orange
        case .installed:
            .green
        case .failed:
            .red
        }
    }

    private var iconWeight: Font.Weight {
        if case .installed = job.state {
            return .heavy
        }

        return .semibold
    }

    private var isFailed: Bool {
        if case .failed = job.state {
            return true
        }

        return false
    }

    private var passiveIconBackground: Color {
        if colorScheme == .dark {
            Color.black.opacity(0.22)
        } else {
            Color.white.opacity(0.38)
        }
    }

    private var leftButtonBackground: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.14)
        }

        return Color.white.opacity(0.5)
    }

    private var dismissButtonBackground: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.14)
        }

        return Color.black.opacity(0.12)
    }

    private var capsuleStrokeColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.16)
        }

        return Color.white.opacity(0.72)
    }
}
