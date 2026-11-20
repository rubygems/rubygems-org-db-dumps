---
name: verify-rubygems-org-db-dumps
description: Proves changes to rubygems-org-db-dumps work by driving its real CLI surface (bin/export, bin/check-format, bin/update, test/run) against a throwaway PostgreSQL 18 server, including byte-for-byte parity of tables/ with segiddins/rubygems-org-db-dumps. Use before claiming any change to the exporter, FORMAT.md, the format checker, the update script, the fixture, or the workflows is done.
---

# Verify rubygems-org-db-dumps

The product is `tables/`: CSV files that ClickGems and other readers load straight from GitHub. The contract is [FORMAT.md](../../../FORMAT.md), and the top priority is that `tables/` stays byte-identical in format to [segiddins/rubygems-org-db-dumps](https://github.com/segiddins/rubygems-org-db-dumps). A change is verified when the export it produces is checked byte for byte, not when a script exits 0.

The user surface is four commands. Drive them; do not reimplement them:

| Command | What it does |
| --- | --- |
| `test/run [--update]` | Loads `test/fixture.sql`, exports it, diffs it byte for byte with `test/expected/`, then runs `bin/check-format` on it. |
| `bin/check-format [DIR]` | Checks a tables folder against FORMAT.md. Reads the table sections of FORMAT.md, so edits there change what it accepts. |
| `bin/export [DIR]` | Exports the restored database `$PGDATABASE` into `DIR`. |
| `bin/update [--force] [DUMP_KEY]` | Downloads a dump (~700 MB), restores it, exports `tables/`, checks it, writes `DUMP`. |

Helpers live in `scripts/` next to this file. All paths below are relative to the repo root; `S=.agents/skills/verify-rubygems-org-db-dumps/scripts`.

## Launch

Needs PostgreSQL 18 server and client with `hstore` (Debian/Ubuntu `postgresql-18`, macOS `brew install postgresql@18`), Python 3.8+, `curl`, `tar`, `gunzip`. The helper never uses a server you already run: it creates its own cluster under `$VERIFY_ROOT` (default `/tmp/verify-rubygems-org-db-dumps`), listening only on a Unix socket on port 54329, trust auth, user `postgres`.

```sh
S=.agents/skills/verify-rubygems-org-db-dumps/scripts
eval "$($S/pg up)"     # creates or starts the server, prints PGHOST/PGPORT/PGUSER/PATH
```

Ready means `pg up` returned 0: it waits for the server, runs a query, and confirms `hstore` is available. It also unsets `PGDATABASE`, `PGOPTIONS`, `PGPASSWORD` and service files so nothing from your shell leaks into the export. In a new shell, reattach with `eval "$($S/pg env)"`. Set `PGBIN` if PostgreSQL 18 is somewhere unusual.

## Doctor

```sh
$S/doctor
```

Read-only. Prints `ok`/`FAIL`/`info` per check and exits 1 on any `FAIL`: repo checkout, tools on `PATH`, `psql` is 18, Python ≥ 3.8, `PGHOST` points at the scratch server (not some other server), server is 18 with `hstore`, role can create databases, free disk (info only; `bin/update` needs ~10 GB), dump bucket reachable (info only; without it only the fixture and format journeys work). Run it first, and again whenever anything looks off.

## Drive

Pick the journeys that cover your change from [features/README.md](features/README.md). Each feature file has exact commands and the end state that proves it. In short:

- Any change at all: [fixture export](features/fixture-export.md) (`test/run`) and [format check](features/format-check.md) (`$S/format-controls`). Both take seconds.
- Exporter, `PGOPTIONS`, part sizes, table list, restore filtering, or anything that could change bytes on real data: [upstream parity](features/upstream-parity.md), a real dump through `bin/update` compared with upstream by `$S/upstream-diff`. Takes a few minutes (3.5 on 4 cores with a fast network) plus a 700 MB download.
- `bin/update` argument handling, `DUMP`, or the weekly workflow: [update runs](features/update-runs.md).

Never run `bin/update` from the checkout during verification: it `cd`s to its own repo root and rewrites `tables/` and `DUMP` there. Copy `bin/` and `FORMAT.md` into `$VERIFY_ROOT/run/update` and run that copy, as the feature files show.

`test/run` uses database `rubygems_org_db_dumps_test` and `bin/update` uses `rubygems_org_db_dumps`, both on the scratch server, so they can run at the same time. The server listens on no TCP port, only on a socket inside `$VERIFY_ROOT/pg`, so a second, independent run just needs its own `VERIFY_ROOT` (for example `VERIFY_ROOT=/tmp/verify-rgdd-2 $S/pg up`). Never drive or stop a `VERIFY_ROOT` another run created.

## Evidence

Write every proof under `$VERIFY_ROOT/evidence/<feature-id>/`; cleanup keeps that directory. For each journey keep:

- the exact command, its full stdout and stderr, and its exit status (`cmd > log 2>&1; echo exit=$? >> log`);
- the resulting state, read back separately: `diff -r` output, `bin/check-format` output on the produced folder, `$S/upstream-diff` output, `cat DUMP`, `sha256sum` lists of produced files;
- a negative control showing the check you relied on fails when the behavior is broken (for example a copy of `bin/export` with a wrong `DateStyle` must make `test/run` exit 1). A check that cannot fail proves nothing.

Proof standards:

- Exercise the real commands. Do not call `psql \copy` yourself to stand in for `bin/export`, and do not hand-edit `test/expected/` to match.
- `test/run --update` rewrites the expectation from the current output. It is never proof of anything; only use it for an intended format change, and then review the `git diff test/expected` line by line against the FORMAT.md change.
- "Matches FORMAT.md" is weaker than "identical to upstream". FORMAT.md cannot express every byte (for example how `jsonb` and `hstore` print). For anything that could change real output, upstream parity is the proof.
- Report what you did not run (for example "upstream parity skipped: no network") rather than letting a lighter journey stand in for it.

## Cleanup

```sh
$S/pg down
```

Stops only the server under `$VERIFY_ROOT/pg` (by its data directory, never by process name), deletes its data and `$VERIFY_ROOT/run`, and keeps `$VERIFY_ROOT/evidence`. Run it after every attempt, failed ones included. `test/run` and `bin/update` delete their own temp dirs. Check `git status` in the checkout: verification should leave no changes in `tables/`, `DUMP`, or `test/expected/` unless you meant them.

## Helpers

| Helper | Invocation | Notes |
| --- | --- | --- |
| `scripts/pg` | `eval "$($S/pg up)"`, `eval "$($S/pg env)"`, `$S/pg down` | Throwaway PostgreSQL 18 on a Unix socket. |
| `scripts/doctor` | `$S/doctor` | Read-only health check, exit 1 on failure. |
| `scripts/format-controls` | `$S/format-controls` | Breaks a copy of `test/expected/` 17 ways and requires `bin/check-format` to reject each one, plus pass the untouched copy. No database needed. |
| `scripts/upstream-diff` | `$S/upstream-diff TABLES_DIR DUMP_KEY` | Compares every file's git blob hash with the upstream commit "Update tables for <date>" via the GitHub API; downloads only differing files to show the first differing bytes. Set `GITHUB_TOKEN` if rate-limited. |
