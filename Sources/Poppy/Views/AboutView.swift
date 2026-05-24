import AppKit
import SwiftUI

struct AboutView: View {
    private let appInfo = AppInfo.current

    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)

            VStack(spacing: 5) {
                Text(appInfo.name)
                    .font(.title2.weight(.semibold))

                Text("Version \(appInfo.version)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Text("Copyright Light Dance LLC \(appInfo.copyrightYear)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .padding(.horizontal, 42)
        .padding(.vertical, 34)
        .frame(width: 320)
    }
}

private struct AppInfo {
    let name: String
    let version: String
    let copyrightYear: String

    static var current: AppInfo {
        let info = Bundle.main.infoDictionary ?? [:]
        let name = info["CFBundleDisplayName"] as? String
            ?? info["CFBundleName"] as? String
            ?? "Poppy"
        let shortVersion = info["CFBundleShortVersionString"] as? String
        let buildVersion = info["CFBundleVersion"] as? String
        let version = [shortVersion, buildVersion]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: " (")

        return AppInfo(
            name: name,
            version: version.isEmpty ? "0.1.0" : version.closingBuildVersionIfNeeded,
            copyrightYear: String(Calendar.current.component(.year, from: Date()))
        )
    }
}

private extension String {
    var closingBuildVersionIfNeeded: String {
        contains("(") ? self + ")" : self
    }
}
