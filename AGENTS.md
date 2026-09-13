# Repository Guide

Poppy has two independently developed parts:

- `app/`: native macOS Swift/SwiftUI application
- `web/`: SvelteKit marketing, download, and release site

Read the nearest nested `AGENTS.md` before editing. In particular, `web/AGENTS.md` contains generated web conventions and takes precedence for files under `web/`.

# Project Conventions

- Keep changes scoped to the relevant app or web subtree.
- Never commit secrets or local environment files. Start web configuration from `web/.env.example`.
- Preserve the existing formatting and architecture; do not introduce a new package manager or build system.
- The web project uses Bun, not npm or pnpm. Add dependencies with `bun add` from `web/`.
- Prefer targeted formatting and lint checks for web changes; use full checks for broad changes.
- macOS UI behavior must be verified manually by the user. Do not use AppleScript, `osascript`, or GUI automation hacks.
- This Linux devbox can build and run the web project, but it cannot build the native macOS app because Xcode is only available on macOS.

# Setup

The repository is cloned at `~/workspace/Poppy`. From a fresh checkout:

```bash
cd web
cp .env.example .env
# Set RAILWAY_PROJECT_NAME (for example, Poppy) and any required local values.
bun install --frozen-lockfile
```

Docker is required for the local Redis service. `bun run docker:start` writes the actual Redis port and local SQLite path to ignored `web/.env.local`.

# Build, Run, And Test

## Web

Run commands from `web/`:

```bash
bun install --frozen-lockfile # install dependencies
bun run docker:start          # start/check local Redis
bun run dev                   # start the development server through portless
bun run build                 # production build
bun run check                 # full formatting, lint, and Svelte checks
```

For focused validation, follow `web/AGENTS.md` and run Prettier/ESLint only on changed files.

## macOS App

Run app commands on a macOS machine with Xcode installed:

```bash
dinggy run --platform macos --project app/Poppy.xcodeproj --scheme Poppy
```

Use `dinggy` for normal build/run validation; do not run direct `xcodebuild` commands for that workflow. The GitHub Actions build job performs a non-signing Release compile on macOS. There is currently no separate automated app test suite.

Release and packaging instructions are in `app/README.md`; they require macOS signing and notarization credentials.

# Git History

- Never amend, rebase, squash, or otherwise rewrite a commit that has been pushed or otherwise left the machine. Once a commit is published, make a new follow-up commit for any fixes.
- It is acceptable to amend small mistakes only while the commit is still purely local and has not been pushed, shared, or used as the basis for a pull request.
