# rubygems-org-db-dumps verification map

This directory is the maintained source for verifying what readers of `tables/` rely on. Read this index, then use the matching feature file as the recipe.

## Baseline preconditions

- Run from the repo root with `S=.agents/skills/verify-rubygems-org-db-dumps/scripts`.
- Start the scratch server with `eval "$($S/pg up)"` and require `$S/doctor` to exit 0.
- `VERIFY_ROOT` (default `/tmp/verify-rubygems-org-db-dumps`) belongs to this run only.
- Network access to the rubygems.org dump bucket and the GitHub API is needed only for `upstream-parity` and `update-runs`.

## Driving conventions

- Drive the repo's own commands: `test/run`, `bin/check-format`, `bin/export`, `bin/update`. Never stand in for them with hand-written SQL or CSV.
- Run `bin/update` only from a copy under `$VERIFY_ROOT/run/`, never from the checkout, so `tables/` and `DUMP` in the checkout stay untouched.
- Keep every command literal; dump keys are full S3 keys such as `production/public_postgresql/2026.10.19.21.21.38/public_postgresql.tar`.

## Proof and skip reporting

- Save each journey's command, stdout, stderr, and exit status to `$VERIFY_ROOT/evidence/<feature-id>/`.
- Read the resulting state back separately (`diff -r`, `bin/check-format`, `upstream-diff`, `cat DUMP`, checksums).
- Pair each passing check with a negative control that makes the same check fail.
- Report a skipped journey with its reason. A lighter journey does not stand in for a skipped one.

## Feature entry contract

Each feature file starts with an H1 title and one paragraph describing the behavior readers rely on, then exactly four H2 sections: `Sub-features`, `How to get to it (user POV)`, `Driving it with the CLI`, `Gotchas`.

## Features

- [Fixture export](./fixture-export.md): `test/run` exports the awkward-case fixture byte for byte as `test/expected/`.
- [Format check](./format-check.md): `bin/check-format` accepts valid folders and rejects every kind of FORMAT.md break.
- [Upstream parity](./upstream-parity.md): a real dump exported through `bin/update` is byte-identical to segiddins/rubygems-org-db-dumps.
- [Update runs](./update-runs.md): `bin/update` picks the newest dump, skips when `DUMP` is current, re-exports the same bytes with `--force`, and fails on restore errors.
