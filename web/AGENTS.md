`CLAUDE.md` -> symlinks `AGENTS.md` -> built from `.agents-rules/`. To edit, use `/agent-rules` skill.

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

**Code Comments:**
1. Keep comments local and concise: place short comments right next to the line or branch they clarify.
2. Comment immediate intent, not broad theory: explain what this code is doing here and why it exists here.
3. Use comments as signposts: add small section markers where they help code scanning and navigation.
4. Comment non-obvious code paths: if logic, invariants, or tradeoffs are not self-evident from code alone, add a clarifying comment.
5. Dont put `.`'s at end of simple comments.
(these are defaults, not rigid rules; choose when to follow them strictly and when to add a higher-level comment for multi-branch or tricky logic)

**Documentation:**
When creating code that is meant to be used outside the file it is defined in (shared utilities, helpers, exported modules), use JSDoc.

For exported utility functions, JSDoc should include:
1. A short description.
2. `@param` for arguments, including expected shape/constraints when helpful.
3. `@returns` describing the return value and notable behavior.
4. `@example` blocks showing common usage when relevant/useful.

Prefer clear, practical JSDoc over verbose descriptions. Keep implementation details in code comments, not in JSDoc.

**Imports Order:**
Order imports from most foundational to most file-specific. Top of file should read like: platform -> app architecture -> shared helpers -> local feature details -> content/styling.

Use these groups in order (separate groups with one blank line):
1. Runtime/framework/core libraries
2. App/domain imports and shared project utilities/types/components
3. Feature-local imports (`../`, `./`) and presentational/style/content-only imports

Organize by scope and importance, not by strict taxonomy. Imports that define platform behavior or are broadly reusable should appear higher; imports tightly coupled to this file's implementation should appear lower. Optimize for a top-to-bottom flow that explains the file from core behavior to local details.

**Import Paths:**
Generally avoid relative import paths (`../../`). Prefer using paths from project root or using project aliases (`$lib`, `$utils`, `$ui`, `$remotes`).
You may use relative imports for imports that are sibling or one level up/down when it would be better to do so.

**Avoid TypeScript Return Types:**
Do not add explicit return type annotations on TypeScript functions. Prefer inferred return types.

## Attribution
Never include any mention of AI coding agents in commits, PRs, or anywhere else
