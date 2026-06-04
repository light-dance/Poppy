Use bun instead of npm or pnpm
When adding packages, use `bun add <package-name>` command instead of trying to add the package in package.json
Prefer bun's built in tooling over package dependencies (postgres, redis, sql, s3, etc.)

**Checks**
When validating changes, prefer per-file checks on the files changed in the task instead of project-wide checks:
```sh
bunx prettier --write <changed-files>
bunx eslint <changed-files>
```
Only run project-wide checks such as `bun run check` or `bun run build` when the user explicitly asks for full validation or the change is broad enough that targeted file checks would miss likely breakage.

**Dev Server**
When running the web dev server, use `bun run dev`. This will use [portless](https://portless.sh/) and will either start the server or report that the portless route is already running along with the URL to use. Do not run `bun run dev:app` or `dev:host`.
