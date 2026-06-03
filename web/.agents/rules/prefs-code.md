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
