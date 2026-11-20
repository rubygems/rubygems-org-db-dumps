# rubygems-org-db-dumps

The public rubygems.org database, as CSV files.

Every week rubygems.org publishes a sanitized PostgreSQL dump of its database
(see [rubygems.org/pages/data](https://rubygems.org/pages/data)). This
repository restores the newest dump into PostgreSQL, exports its tables as CSV
into [`tables/`](tables), and commits the result. A GitHub Actions workflow does
this once a week.

[ClickGems](https://clickgems.clickhouse.com), the RubyGems analytics site run
by ClickHouse, loads `tables/` from this repository.

## What is in `tables/`

One folder per table of the public dump, each split into files of a fixed range
of ids:

| Folder | Rows per part |
| --- | --- |
| `attestations` | 2,500 |
| `deletions` | 100,000 |
| `dependencies` | 250,000 |
| `gem_downloads` | 1,000,000 |
| `linksets` | 100,000 |
| `rubygems` | 100,000 |
| `versions` | 50,000 |

`tables/versions/part_3.csv` holds the versions with ids from 150000 to 199999.
Every file starts with a header row. NULL is an empty field and an empty string
is `""`. Timestamps are UTC, written like `2015-04-20 21:24:46.2566`, and
booleans are `t` or `f`.

[FORMAT.md](FORMAT.md) is the full specification, with every column and its
type. The format is the one that
[segiddins/rubygems-org-db-dumps](https://github.com/segiddins/rubygems-org-db-dumps)
used, so programs that read that repository can read this one.

[`DUMP`](DUMP) names the dump that `tables/` was exported from.

## How ClickGems uses it

ClickGems reads each table straight from GitHub with ClickHouse's `url` table
function, in a materialized view that refreshes once a week, for example:

```sql
SELECT *
FROM url('https://raw.githubusercontent.com/<owner>/rubygems-org-db-dumps/refs/heads/main/tables/rubygems/part_{0..100}.csv', 'CSVWithNames')
```

The rows go into `ReplacingMergeTree` tables, which drop the rows that repeat
from one week to the next. The ClickHouse blog post
[Announcing Ruby Gem analytics](https://clickhouse.com/blog/announcing-ruby-gem-analytics-powered-by-clickhouse)
describes the setup. You can load the tables into your own ClickHouse the same
way.

Because readers depend on the file names, the columns, and the CSV details, a
change to any of them is a breaking change: update FORMAT.md, `test/expected/`,
and the readers together.

## Running it locally

You need PostgreSQL 17 (server and client tools), with the `hstore` extension
(in Debian and Ubuntu it is part of the `postgresql` package), plus `bash`,
`curl`, and Python 3. Point the usual libpq environment variables (`PGHOST`,
`PGUSER`, `PGPASSWORD`, ...) at a server where your user can create databases.

With [mise](https://mise.jdx.dev) and Docker, `mise install` installs the tools
in `mise.toml` and `docker compose up --detach --wait` starts the server in
`compose.yml`; inside the checkout, mise points libpq at that server.

```sh
bin/update
```

This finds the newest dump, downloads it (about 700 MB), restores it into the
database `rubygems_org_db_dumps` (set `PGDATABASE` to use another name; it is
dropped and created again), writes `tables/`, checks it against FORMAT.md, and
writes the dump's name to `DUMP`. It takes a few minutes and needs about 10 GB
of free disk space.

Running it again does nothing when `DUMP` already names the newest dump. Use
`bin/update --force` to export again anyway, or pass a dump's key to export an
older one:

```sh
bin/update --force production/public_postgresql/2026.10.19.21.21.38/public_postgresql.tar
```

Exporting the same dump always writes the same bytes.

The steps are also available on their own:

- `bin/export [DIR]` exports the restored database into `DIR` (default `tables`).
- `bin/check-format [DIR]` checks `DIR` (default `tables`) against FORMAT.md.

## Tests

```sh
test/run
```

loads [test/fixture.sql](test/fixture.sql), a small database with the awkward
cases (quotes, commas, line breaks, NULL next to empty strings, ids on both
sides of a part boundary), exports it, and compares the result byte for byte
with [test/expected/](test/expected). It needs the same PostgreSQL setup as
`bin/update`. CI runs it on every push and pull request, and also checks the
committed `tables/` against FORMAT.md.

If you change the format on purpose, run `test/run --update` and commit the new
`test/expected/` together with the change to FORMAT.md.

## The weekly update

[`.github/workflows/update.yml`](.github/workflows/update.yml) runs `bin/update`
every Tuesday morning (UTC), after rubygems.org publishes its Monday dump, and
commits `tables/` and `DUMP` when they changed. To run it by hand, open the
**Update tables** workflow in the Actions tab and choose **Run workflow**.

## License

See [LICENSE](LICENSE). The data in `tables/` comes from rubygems.org's public
dumps.
