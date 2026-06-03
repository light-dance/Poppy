SvelteKit project runs alongside Postgres, Redis and S3 bucket

Running locally:

- Requires bun, docker, and node.
- You'll want to install the railway cli to pull env vars.
- If you have `fzf` installed you can run `bun f` to run scripts more easily (browse package scripts with fuzzy search)

Agents Rules:

Project uses `.agents/rules/*.md` files to contruct AGENTS.md file rather than editing directly. You can just ask AI to edit agents rules and it will do so.
