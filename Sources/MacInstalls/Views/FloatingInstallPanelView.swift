import SwiftUI

struct FloatingInstallPanelView: View {
    let job: InstallJob
    @ObservedObject var store: InstallStore

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.96))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.regularMaterial)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.quaternary, lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 16) {
                header(for: job)

                Text(message(for: job))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                controls(for: job)
            }
            .padding(20)
        }
        .frame(width: 420, height: 190)
    }

    private func header(for job: InstallJob) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconName(for: job))
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(iconColor(for: job))
                .frame(width: 36, height: 36)
                .background(.tertiary, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title(for: job))
                    .font(.headline)
                    .lineLimit(1)

                Text(subtitle(for: job))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func controls(for job: InstallJob) -> some View {
        switch job.state {
        case .awaitingApproval:
            HStack {
                Button("Not Now") {
                    store.cancelCurrentInstall()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    store.approveCurrentInstall()
                } label: {
                    Label("Install", systemImage: "arrow.down.app")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        case .installing:
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)
                Text("Working")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        case .installed:
            HStack {
                Button("Done") {
                    store.dismissCurrentJob()
                }

                Spacer()

                Button {
                    store.openInstalledApp()
                } label: {
                    Label("Open App", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        case .failed:
            HStack {
                Spacer()
                Button("Dismiss") {
                    store.dismissCurrentJob()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private func title(for job: InstallJob) -> String {
        switch job.state {
        case .awaitingApproval:
            "Install \(job.displayName)?"
        case .installing:
            "Installing \(job.displayName)"
        case .installed:
            "\(job.displayName) installed"
        case .failed:
            "Install failed"
        }
    }

    private func message(for job: InstallJob) -> String {
        switch job.state {
        case .awaitingApproval:
            "A new disk image appeared in Downloads. Approve this to mount it, copy the app to ~/Applications, unmount, and remove the DMG."
        case .installing(let step):
            step
        case .installed(let appURL):
            "\(appURL.lastPathComponent) was copied to ~/Applications and the disk image was cleaned up."
        case .failed(let message):
            message
        }
    }

    private func subtitle(for job: InstallJob) -> String {
        if case .failed = job.state {
            return job.dmgURL.path
        }

        return job.dmgURL.lastPathComponent
    }

    private func iconName(for job: InstallJob) -> String {
        switch job.state {
        case .awaitingApproval:
            "questionmark.app"
        case .installing:
            "opticaldiscdrive"
        case .installed:
            "checkmark.circle"
        case .failed:
            "exclamationmark.triangle"
        }
    }

    private func iconColor(for job: InstallJob) -> Color {
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
}
