Patch the installed SvelteKit package in `node_modules`, not a repo-local `packages/kit` copy.

File:
`node_modules/@sveltejs/kit/src/core/sync/create_manifest_data/index.js`

Required edit:

```diff
- const files = fs.readdirSync(dir).map((name) => ({
+ const files = fs.readdirSync(dir).sort().map((name) => ({
```

Purpose:
Make route manifest generation deterministic by sorting directory entries before mapping them.
