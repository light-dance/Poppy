import Foundation
import ServiceManagement

@MainActor
final class LoginItemController {
    static let launchAtLoginKey = "launchAtLogin"

    var isRegistered: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func configureLaunchAtLogin(_ isEnabled: Bool) throws {
        if isEnabled {
            try registerIfNeeded()
        } else {
            try unregisterIfNeeded()
        }
    }

    private func registerIfNeeded() throws {
        guard SMAppService.mainApp.status != .enabled else { return }
        try SMAppService.mainApp.register()
    }

    private func unregisterIfNeeded() throws {
        guard SMAppService.mainApp.status != .notRegistered else { return }
        try SMAppService.mainApp.unregister()
    }
}
