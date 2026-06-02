# Poppy

Poppy App Installer

Prototype macOS helper that watches a configured downloads folder for new `.dmg` files, `.zip` archives, and `.app` bundles. When a new installer is stable on disk, it presents a custom floating confirmation panel. If approved, it installs the app into the configured install folder, cleans up the source installer, and offers to open the installed app.

## Layout

- `app/` contains the macOS app.
- `web/` will contain the marketing/download site.

Run locally:

```bash
xcodebuild -project app/Poppy.xcodeproj -scheme Poppy -configuration Debug build
```

This is intentionally unsandboxed for the prototype because it needs access to the watched folder, the install folder, `hdiutil`, and deletion of source installers.
