import SwiftUI

struct FloatingInstallPanelView: View {
    let job: InstallJob
    @ObservedObject var store: InstallStore
    @AppStorage(NotificationDismissalDelay.storageKey) private var notificationDismissalDelayValue = NotificationDismissalDelay.after15Seconds.rawValue
    @Environment(\.colorScheme) private var colorScheme
    @State private var notificationCountdownStart = Date()

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
                approvalDismissButtonLabel
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
                .background {
                    installButtonBackground
                        .clipShape(Capsule(style: .continuous))
                }
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 11)
        .frame(minHeight: 62)
        .background(capsuleBackground)
        .fixedSize(horizontal: true, vertical: true)
        .onAppear {
            notificationCountdownStart = Date()
        }
        .onChange(of: job.id) {
            notificationCountdownStart = Date()
        }
        .onChange(of: notificationDismissalDelayValue) {
            notificationCountdownStart = Date()
        }
        .task(id: approvalDismissalTaskID) {
            if let seconds = approvalAutoInstallSeconds {
                try? await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
                guard !Task.isCancelled else { return }
                store.approveCurrentInstall()
                return
            }

            guard let seconds = notificationDismissalDelay.seconds else { return }

            try? await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
            guard !Task.isCancelled else { return }
            store.cancelCurrentInstall()
        }
    }

    private var approvalDismissButtonLabel: some View {
        ZStack {
            Circle()
                .fill(leftButtonBackground)

            if notificationDismissalDelay.seconds != nil && approvalAutoInstallSeconds == nil {
                notificationCountdownRing
            }

            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(width: 40, height: 40)
    }

    private var notificationCountdownRing: some View {
        TimelineView(.animation) { context in
            Circle()
                .trim(from: 0, to: notificationCountdownProgress(at: context.date))
                .stroke(
                    notificationCountdownRingColor,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(1.25)
        }
    }

    @ViewBuilder
    private var installButtonBackground: some View {
        if approvalAutoInstallSeconds != nil {
            TimelineView(.animation) { context in
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Color.blue.opacity(0.42)

                        Color.accentColor
                            .frame(width: proxy.size.width * approvalAutoInstallProgress(at: context.date))
                    }
                }
            }
        } else {
            Color.accentColor
        }
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

            InstallingSpinner(size: 40)
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
                installedDismissButtonLabel
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
        .onAppear {
            notificationCountdownStart = Date()
        }
        .onChange(of: job.id) {
            notificationCountdownStart = Date()
        }
        .onChange(of: notificationDismissalDelayValue) {
            notificationCountdownStart = Date()
        }
        .task(id: installedDismissalTaskID) {
            guard let seconds = notificationDismissalDelay.seconds else { return }

            try? await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
            guard !Task.isCancelled else { return }
            store.dismissCurrentJob()
        }
    }

    private var installedDismissButtonLabel: some View {
        ZStack {
            Circle()
                .fill(leftButtonBackground)

            if notificationDismissalDelay.seconds != nil {
                notificationCountdownRing
            }

            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(width: 40, height: 40)
    }


    private var capsuleBackground: some View {
        Capsule(style: .continuous)
            .fill(.regularMaterial)
            .overlay {
                Capsule(style: .continuous)
                    .stroke(capsuleStrokeColor, lineWidth: 1)
            }
    }

    private var notificationDismissalDelay: NotificationDismissalDelay {
        NotificationDismissalDelay(rawValue: notificationDismissalDelayValue) ?? .after15Seconds
    }

    private var approvalDismissalTaskID: String {
        "\(job.id.uuidString)-\(notificationDismissalDelayValue)-\(approvalAutoInstallSeconds ?? 0)"
    }

    private var installedDismissalTaskID: String {
        "\(job.id.uuidString)-\(notificationDismissalDelayValue)-installed"
    }

    private var approvalAutoInstallSeconds: Int? {
        guard case .autoInstall(let seconds) = job.approvalBehavior else {
            return nil
        }

        return seconds
    }

    private func notificationCountdownProgress(at date: Date) -> CGFloat {
        guard let seconds = notificationDismissalDelay.seconds else {
            return 0
        }

        let elapsed = date.timeIntervalSince(notificationCountdownStart)
        let remaining = max(0, TimeInterval(seconds) - elapsed)
        return CGFloat(remaining / TimeInterval(seconds))
    }

    private func approvalAutoInstallProgress(at date: Date) -> CGFloat {
        guard let seconds = approvalAutoInstallSeconds else {
            return 0
        }

        let elapsed = date.timeIntervalSince(notificationCountdownStart)
        return min(1, max(0, CGFloat(elapsed / TimeInterval(seconds))))
    }

    @ViewBuilder
    private var statusAction: some View {
        switch job.state {
        case .awaitingApproval:
            EmptyView()
        case .installing:
            InstallingSpinner(size: 40)
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

    private var notificationCountdownRingColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.46)
        }

        return Color.white
    }

    private var capsuleStrokeColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.16)
        }

        return Color.white.opacity(0.72)
    }
}

private struct InstallingSpinner: View {
    let size: CGFloat
    @State private var rotation = Angle.degrees(0)

    var body: some View {
        Circle()
            .trim(from: 0.08, to: 0.88)
            .stroke(
                Color.secondary,
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
            )
            .frame(width: size * 0.6, height: size * 0.6)
            .rotationEffect(rotation)
            .frame(width: size, height: size)
            .onAppear {
                withAnimation(.linear(duration: 1.25).repeatForever(autoreverses: false)) {
                    rotation = .degrees(360)
                }
            }
    }
}
