# Update runs

`bin/update` is what the weekly workflow runs: with no key it finds the newest dump in the public bucket; it does nothing when `DUMP` already names that dump; `--force` exports again and writes the same bytes; any restore error other than the known missing-role and missing-relation ones stops it before `tables/` or `DUMP` changes.

## Sub-features

- `update-latest` with no key, it picks the newest `public_postgresql.tar` key.
- `update-skip` it prints `tables/ is already exported from <key>` and exits 0 when `DUMP` matches.
- `update-force` `--force` re-exports, and the bytes match the previous export.
- `update-restore-errors` an unexpected `ERROR:` during restore exits 1 with `Restoring the dump failed:`.

## How to get to it (user POV)

- `bin/update`, `bin/update --force`, `bin/update [--force] <DUMP_KEY>` locally, as the README says.
- The **Update tables** workflow on its Tuesday schedule or by **Run workflow** (with the `force` input), which then commits `tables/` and `DUMP` if they changed.

## Driving it with the CLI

Preconditions:

- `eval "$($S/pg up)"` done and `$S/doctor` exits 0 with `dump bucket reachable`.
- A copy at `$VERIFY_ROOT/run/update` (`mkdir -p $VERIFY_ROOT/run/update; cp -r bin FORMAT.md $VERIFY_ROOT/run/update/`). Reuse the one from `upstream-parity` when it already holds an export.
- `ev=$VERIFY_ROOT/evidence/update-runs; mkdir -p $ev`.

- **Latest key.** Run `curl -s 'https://s3-us-west-2.amazonaws.com/rubygems-dumps/?prefix=production/public_postgresql/' | grep -o '<Key>[^<]*/public_postgresql\.tar</Key>' | sed 's/<[^>]*>//g' | sort | tail -n 1 > $ev/expected-latest`. A no-key run must print `Downloading $(cat $ev/expected-latest)` as its first line.
- **Skip.** With `DUMP` naming the key you will pass, run `$VERIFY_ROOT/run/update/bin/update $KEY > $ev/skip.log 2>&1; echo exit=$? >> $ev/skip.log`. The log is `tables/ is already exported from $KEY` and `exit=0`, and it returns in seconds (nothing downloaded).
- **Force reproduces bytes.** Save `(cd $VERIFY_ROOT/run/update && find tables -type f | sort | xargs sha256sum) > $ev/before.sha256`, run `$VERIFY_ROOT/run/update/bin/update --force $KEY > $ev/force.log 2>&1; echo exit=$? >> $ev/force.log`, save `after.sha256` the same way, then `diff $ev/before.sha256 $ev/after.sha256 > $ev/force-diff.log; echo exit=$? >> $ev/force-diff.log`. Both exits are 0 and the diff is empty.
- **Restore errors stop it.** In a separate copy, inject one statement whose error the filter does not allow: `c=$VERIFY_ROOT/run/control-restore; mkdir -p $c; cp -r bin FORMAT.md $c/; echo old > $c/DUMP; sed -i 's#^  | psql -X -q -o /dev/null#  | { echo "SELECT no_such_function();"; cat; } | psql -X -q -o /dev/null#' $c/bin/update; $c/bin/update --force $KEY > $ev/restore-error.log 2>&1; echo exit=$? >> $ev/restore-error.log; cat $c/DUMP >> $ev/restore-error.log`. The log has `Restoring the dump failed:`, `ERROR:  function no_such_function() does not exist`, `exit=1`, and `old` (DUMP unchanged), and `$c/tables` does not exist. This downloads the dump again.
- **Workflow.** The workflow cannot run locally. After a change to `.github/workflows/update.yml`, verify on GitHub with **Run workflow** on a fork or branch and record the run URL and its log lines `tables/ is now exported from ...` and either `No changes to commit` or the commit it pushed.

## Gotchas

- The no-key path depends on the bucket listing fitting one page; `bin/update` refuses with `The dump listing is longer than one page` if it ever does not.
- The skip check is a string compare of `DUMP` with the key, and also needs a `tables/` folder next to it.
- `--force` must come before the key: `bin/update KEY --force` silently ignores `--force` and may just skip.
- Each forced run downloads the dump again; it takes as long as the first run (about 3.5 minutes on 4 cores with a fast network).
