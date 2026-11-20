# Format check

`bin/check-format [DIR]` reads the table sections of FORMAT.md (tables, columns, types, rows per part) and checks every file under a tables folder against them: folder and file names, header, UTF-8 without BOM, LF endings, quoting rules, NULL vs `""`, value formats, ids in the right part and ascending, no empty parts. CI and `bin/update` both rely on it to stop a broken `tables/` from being committed.

## Sub-features

- `format-accept` a valid folder passes with `<dir>: N files match FORMAT.md`.
- `format-reject` each kind of break is reported with a file-and-row message and exit 1.
- `format-spec` edits to FORMAT.md's table sections change what is accepted.

## How to get to it (user POV)

- Run `bin/check-format tables` (or any folder) locally.
- `test/run` runs it on `test/expected/`; `bin/update` runs it on the fresh `tables/`.
- CI runs it on the committed `tables/` when that folder exists.

## Driving it with the CLI

Preconditions:

- Python 3.8+. No database needed.

- **Accept.** Run `bin/check-format test/expected`. Output `test/expected: 15 files match FORMAT.md`, exit 0. On a real export, run it on that folder too (see `upstream-parity`).
- **Reject, all controls.** Run `mkdir -p $VERIFY_ROOT/evidence/format-check; $S/format-controls > $VERIFY_ROOT/evidence/format-check/controls.log 2>&1; echo exit=$? >> $VERIFY_ROOT/evidence/format-check/controls.log`. Every line starts with `ok`, the last line is `all 18 controls behaved as expected`, then `exit=0`. A `MISS` line names the break the checker no longer catches.
- **New rule.** When you add a rule to FORMAT.md or `bin/check-format`, add a control for it to the `CONTROLS` list in `scripts/format-controls` (name, file, change, expected message) and show it reported `ok`; then revert your checker change in a scratch copy and show the new control reports `MISS`.
- **Spec edit.** After editing a table section of FORMAT.md, run `bin/check-format test/expected` and `test/run`. A renamed or added column must fail until `bin/export`'s output and `test/expected/` agree with it.

## Gotchas

- `bin/check-format` returns a bad header as the only problem for that file, so a BOM is reported as `header is not ...`, not `starts with a byte order mark`.
- It only parses sections shaped exactly like `### table`, `Rows per part: N`, and `| column | type |` rows. Reformatting those (extra spaces, a new type name) silently drops or breaks rules; FORMAT.md says to keep that form.
- It validates shape, not values: a wrong-but-well-formed timestamp, a different jsonb key order, or different hstore spacing passes. Only `fixture-export` and `upstream-parity` catch those.
- It stops listing problems after 20 per file.
- A file of 45 MiB or more prints `warning: <path> is N MiB, near GitHub's 50 MiB warning` (`::warning::` under GitHub Actions) but does not fail the check. To see it, write a valid part over 45 MiB into a copy of `test/expected/` (for example 100000 `rubygems` rows with 450-character names) and run `bin/check-format` on the copy: it must print the warning and exit 0.
