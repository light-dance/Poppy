# Release Metadata

Tag-triggered releases must commit a JSON file named after the tag version:

```json
{
  "version": "0.1.0",
  "build_number": 1,
  "title": "Version 0.1.0",
  "changelog": "Release notes to publish on the web changelog."
}
```

For tag `v0.1.0`, commit `app/releases/0.1.0.json` before creating or moving the tag.
