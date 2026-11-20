# Fixture export

`test/run` restores `test/fixture.sql` (quotes, commas, CR and LF inside fields, NULL next to `""`, UTF-8, jsonb, hstore, fractional timestamps, ids on both sides of every part boundary, gaps in part numbers) into a scratch database, exports it with `bin/export`, and requires the result to equal `test/expected/` byte for byte. It is the fastest proof that an exporter change kept the format.

## Sub-features

- `fixture-match` the export of the fixture equals `test/expected/`.
- `fixture-format` `test/expected/` itself passes `bin/check-format`.
- `fixture-update` `test/run --update` rewrites `test/expected/` for an intended format change.

## How to get to it (user POV)

- Run `test/run` locally, as the README says.
- CI runs `test/run` on every push and pull request (`.github/workflows/ci.yml`, job `format`).

## Driving it with the CLI

Preconditions:

- `eval "$($S/pg up)"` done and `$S/doctor` exits 0.
- `git status test/` is clean, or you know exactly which changes are intended.

- **Match.** Run `mkdir -p $VERIFY_ROOT/evidence/fixture-export; test/run > $VERIFY_ROOT/evidence/fixture-export/test-run.log 2>&1; echo exit=$? >> $VERIFY_ROOT/evidence/fixture-export/test-run.log`. The log ends with `test/expected: 15 files match FORMAT.md`, `test/run: export matches test/expected`, and `exit=0`.
- **Negative control.** Break a copy, not the checkout: `c=$VERIFY_ROOT/run/control-fixture; mkdir -p $c; cp -r bin test FORMAT.md $c/; sed -i 's/DateStyle=ISO,MDY/DateStyle=SQL,DMY/' $c/bin/export; $c/test/run > $VERIFY_ROOT/evidence/fixture-export/control-datestyle.log 2>&1; echo exit=$?`. It prints `exit=1` and the log shows `diff -r` lines such as `> ...,14/11/2024 21:15:00,...` against `< ...,2024-11-14 21:15:00,...`. Pick a control that breaks the area you changed (for example a different part size in the `tables=(...)` list, or dropping `ORDER BY id`).
- **Intended format change.** Change FORMAT.md and the exporter together, run `test/run --update`, then save `git diff --stat test/expected` and `git diff test/expected` to evidence and check that every changed line is explained by the FORMAT.md change. Rerun `test/run` without `--update`; it must pass.

## Gotchas

- `test/run --update` always "passes"; it is not proof. Only the plain `test/run` is.
- `test/run` hard-codes database `rubygems_org_db_dumps_test`; it drops it first, so never point `PGHOST` at a server holding a database with that name you care about.
- `.gitattributes` marks `test/expected/**` as `-text`. An editor or tool that converts line endings in those files breaks the test for the wrong reason.
- A new edge case belongs in `test/fixture.sql` plus a regenerated `test/expected/`; the fixture passing does not prove real-dump parity (see `upstream-parity`).
