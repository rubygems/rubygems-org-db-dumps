# Upstream parity

The repo's top promise: exporting the same public dump that segiddins/rubygems-org-db-dumps exported yields a `tables/` that is byte-identical to upstream's, file for file. This is the only journey that exercises real data (millions of rows, real jsonb and hstore values, real part counts) end to end through the real restore and export.

## Sub-features

- `parity-files` the same set of `tables/<table>/part_N.csv` names as upstream.
- `parity-bytes` every file has the same git blob hash as upstream's.
- `parity-format` the export passes `bin/check-format`.

## How to get to it (user POV)

- `bin/update <DUMP_KEY>` for a dump that upstream also exported; upstream commits are titled `Update tables for <date>`, where `<date>` is the third path segment of the key.
- The weekly workflow (`.github/workflows/update.yml`) runs the same `bin/update` without a key.

## Driving it with the CLI

Preconditions:

- `eval "$($S/pg up)"` done and `$S/doctor` exits 0 with `dump bucket reachable` and at least 10 GB free.
- Pick a dump upstream exported: `gh api repos/segiddins/rubygems-org-db-dumps/commits?per_page=5 --jq '.[].commit.message'` (or the GitHub web page) and take the newest `Update tables for <date>`. The key is `production/public_postgresql/<date>/public_postgresql.tar`. The newest rubygems.org dump may be newer than upstream's last export; use the one upstream has.

- **Export.** Copy the scripts so the checkout stays clean, then run the real update: `run=$VERIFY_ROOT/run/update; ev=$VERIFY_ROOT/evidence/upstream-parity; mkdir -p $run $ev; cp -r bin FORMAT.md $run/; ( time $run/bin/update $KEY ) > $ev/update.log 2>&1; echo update-exit=$? >> $ev/update.log`. The log ends with `tables: N files match FORMAT.md`, `tables/ is now exported from $KEY`, and `update-exit=0`; `cat $run/DUMP` prints `$KEY`.
- **Compare.** Run `$S/upstream-diff $run/tables $KEY > $ev/upstream-diff.log 2>&1; echo exit=$? >> $ev/upstream-diff.log`. The log shows `identical: N of N upstream files`, no `differ:` / `only local:` / `only upstream:` lines, `tables match upstream byte for byte`, `exit=0`. On a difference it prints the first differing bytes of up to three files.
- **Checksums.** Run `(cd $run && find tables -type f | sort | xargs sha256sum) > $ev/tables.sha256` so a later run can be compared without the network.
- **Negative control.** Show the comparison can fail: `cp $run/tables/rubygems/part_0.csv $ev/part_0.orig; sed -i '2s/,t,/,f,/' $run/tables/rubygems/part_0.csv; $S/upstream-diff $run/tables $KEY > $ev/control.log 2>&1; echo exit=$? >> $ev/control.log`. The log has `differ: rubygems/part_0.csv` and `exit=1`. Restore the file afterwards if you compare again.

## Gotchas

- `bin/update` from the checkout overwrites the checkout's `tables/` and `DUMP`; always run the copy under `$VERIFY_ROOT/run/update`.
- The download is about 700 MB; the whole run took about 3.5 minutes on 4 cores with a fast network, longer on a slow link. Start it in the background and do the fast journeys meanwhile.
- If upstream has not exported a dump, there is nothing to compare with; `upstream-diff` exits with `No upstream commit titled ...`. Older dumps eventually disappear from the bucket.
- Anonymous GitHub API calls are rate-limited (60 per hour). `upstream-diff` uses two or three calls plus one raw download per differing file shown; set `GITHUB_TOKEN` when running it repeatedly.
- `bin/update` removes its downloaded dump on exit but leaves the restored database `rubygems_org_db_dumps` on the scratch server until `$S/pg down`.
