# Poppy macOS App

This directory contains the macOS app.

Build the Xcode app target:

```bash
xcodebuild -project Poppy.xcodeproj -scheme Poppy -configuration Debug build
```

Open `Poppy.xcodeproj` in Xcode to run and debug locally.

## Release

The release pipeline archives the Release build, exports a Developer ID signed
app with the hardened runtime enabled, notarizes and staples the `.app`, creates
a distributable `.zip`, creates the drag-to-Applications `.dmg`, then signs,
notarizes, and staples the `.dmg`.

Run the same release path locally after storing notary credentials with
`xcrun notarytool store-credentials`:

```bash
NOTARY_PROFILE=poppy-release \
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
./scripts/release.sh --version 1.0.0 --build-number 1
```

In GitHub Actions, run the `Release` workflow manually. It expects these
repository secrets:

```text
MACOS_CERTIFICATE_P12_BASE64
MACOS_CERTIFICATE_PASSWORD
MACOS_KEYCHAIN_PASSWORD
MACOS_CODESIGN_IDENTITY
APP_STORE_CONNECT_API_KEY_P8_BASE64
APP_STORE_CONNECT_KEY_ID
APP_STORE_CONNECT_ISSUER_ID
RAILWAY_BUCKET_ENDPOINT
RAILWAY_BUCKET_NAME
RAILWAY_BUCKET_ACCESS_KEY_ID
RAILWAY_BUCKET_SECRET_ACCESS_KEY
```

Optionally set `RAILWAY_BUCKET_REGION` as a repository variable. It defaults to
`auto`, which matches Railway's bucket credentials.

## DMG

After exporting a notarized app to `dist/Poppy.app`, create a DMG:

```bash
./scripts/create_dmg.sh --force
```

The script uses Apple system tools (`hdiutil`, Finder AppleScript, and `SetFile`) to create a drag-to-Applications DMG. Customize the Finder window background by adding:

```text
assets/dmg/background.png
```
