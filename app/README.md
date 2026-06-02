# Poppy macOS App

This directory contains the macOS app.

Build the Xcode app target:

```bash
xcodebuild -project Poppy.xcodeproj -scheme Poppy -configuration Debug build
```

Open `Poppy.xcodeproj` in Xcode to run, archive, and manage signing.

## DMG

After exporting a notarized app to `dist/Poppy.app`, create a DMG:

```bash
./scripts/create_dmg.sh --force
```

The script uses Apple system tools (`hdiutil`, Finder AppleScript, and `SetFile`) to create a drag-to-Applications DMG. Customize the Finder window background by adding:

```text
assets/dmg/background.png
```
