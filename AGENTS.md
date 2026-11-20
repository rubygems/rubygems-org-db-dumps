# AGENTS.md

See [README.md](README.md) for how the repo works, [FORMAT.md](FORMAT.md) for the `tables/` spec, and the [verify skill](.agents/skills/verify-rubygems-org-db-dumps/SKILL.md) for proving changes.

- ClickGems reads `tables/` from raw GitHub URLs, so any change to its shape breaks readers and needs a maintainer's OK.
- Keep `tables/` out of Git LFS; if a part nears 50 MiB, shrink that table's parts in FORMAT.md.
- Only the weekly Update tables workflow writes `tables/` and `DUMP`, so leave them out of your commits.
- Bot pushes skip CI, and pushing to `main` during an Update tables run can get the bot's push rejected.
- The repo is open source, so keep secrets, internal hostnames and private paths out of code and commit messages.
