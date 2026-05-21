# Mac Installs

Prototype macOS helper that watches `~/Downloads` for new `.dmg` files. When a new DMG is stable on disk, it presents a custom floating confirmation panel. If approved, it mounts the disk image, finds the first `.app` bundle, copies it into `~/Applications`, unmounts the DMG, deletes the downloaded DMG, and offers to open the installed app.

Run locally:

```bash
./script/build_and_run.sh
```

This is intentionally unsandboxed for the prototype because it needs access to Downloads, `~/Applications`, `hdiutil`, and deletion of the source DMG.
