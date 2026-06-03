SvelteKit project runs alongside SQLite, Redis and an S3-compatible bucket

Running locally:

- Requires bun, docker, and node.
- SQLite uses `DB_URL`, defaulting to `./db/data.sqlite` locally.
- Docker is only used for Redis in local development.
- You'll want to install the railway cli to pull env vars.
- If you have `fzf` installed you can run `bun f` to run scripts more easily (browse package scripts with fuzzy search)

Agents Rules:

Project uses `.agents/rules/*.md` files to contruct AGENTS.md file rather than editing directly. You can just ask AI to edit agents rules and it will do so.
