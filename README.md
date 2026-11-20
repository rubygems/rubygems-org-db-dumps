# rubygems-org-db-dumps

This repository turns the public RubyGems.org database into CSV files. Each week it restores the latest database dump into PostgreSQL, exports seven tables as CSV into [`tables/`](tables), and commits the result. A GitHub Actions workflow handles the weekly run.

## Where does the data come from?

RubyGems.org publishes a sanitized PostgreSQL dump of its database every week, with all user information removed. See [rubygems.org/pages/data](https://rubygems.org/pages/data). This repository uses the newest dump and records its name in [`DUMP`](DUMP).

## What is in `tables/`?

There is one folder for each table, and each folder is split into parts that cover a fixed range of ids:

| Folder | Rows per part |
| --- | --- |
| `attestations` | 2,500 |
| `deletions` | 100,000 |
| `dependencies` | 250,000 |
| `gem_downloads` | 1,000,000 |
| `linksets` | 100,000 |
| `rubygems` | 100,000 |
| `versions` | 50,000 |

For example, `tables/versions/part_3.csv` holds the versions with ids from 150000 to 199999. A part that would be empty isn't written, so there can be gaps in the numbering.

* Every file starts with a header row.
* NULL is an empty field, and an empty string is `""`.
* Timestamps are UTC and look like `2015-04-20 21:24:46.2566`.
* Booleans are `t` or `f`.
* Exporting the same dump twice gives the same bytes.

[FORMAT.md](FORMAT.md) is the full specification and lists every column with its type.

## How does ClickGems use it?

[ClickGems](https://clickgems.clickhouse.com), the RubyGems analytics site run by ClickHouse, reads tables in this format. A refreshable materialized view loads each table straight from GitHub once a week with ClickHouse's `url` table function, for example:

```sql
SELECT *
FROM url('https://raw.githubusercontent.com/rubygems/rubygems-org-db-dumps/refs/heads/main/tables/rubygems/part_{0..100}.csv', 'CSVWithNames')
```

The view appends rows to `ReplacingMergeTree` tables, which remove the rows that repeat from week to week. [Announcing Ruby Gem analytics](https://clickhouse.com/blog/announcing-ruby-gem-analytics-powered-by-clickhouse) describes the setup. You can load the tables into your own ClickHouse the same way.

Readers depend on the file names, the columns, and the CSV details. Changing any of them is a breaking change, so update FORMAT.md, `test/expected/`, and the readers together.

## Running it locally

You need:

* PostgreSQL 18, both the server and the client tools, with the `hstore` extension. On Debian and Ubuntu, `hstore` comes with the `postgresql-18` package.
* `bash`, `curl`, and Python 3.
* A server where your user can create databases. Point the usual libpq environment variables (`PGHOST`, `PGUSER`, `PGPASSWORD`, and so on) at it.

If you have [mise](https://mise.jdx.dev) and Docker, they can set up PostgreSQL and Python for you:

```sh
mise install
docker compose up --detach --wait
```

`mise install` installs the PostgreSQL 18 client tools and Python 3 listed in `mise.toml`. `docker compose up` starts the PostgreSQL 18 server from `compose.yml`, which only listens on localhost. Inside the checkout, mise points libpq at that server by setting `PGHOST`, `PGUSER` and `PGPASSWORD`, but keeps any of them you've already set. Run `docker compose down` to stop it.

Then run:

```sh
bin/update
```

`bin/update` finds the newest dump and downloads it (about 700 MB). It restores the dump into the `rubygems_org_db_dumps` database, then writes `tables/`, checks it against FORMAT.md, and writes the dump's name to `DUMP`. It drops and recreates that database each time, so set `PGDATABASE` if you want a different name. A run takes a few minutes and needs about 10 GB of free disk space.

If `DUMP` already names the newest dump, `bin/update` does nothing. To export again anyway, use `--force`. To export an older dump, pass its key:

```sh
bin/update --force production/public_postgresql/2026.10.19.21.21.38/public_postgresql.tar
```

You can also run each step on its own:

* `bin/export [DIR]` exports the restored database into `DIR` (default `tables`).
* `bin/check-format [DIR]` checks `DIR` (default `tables`) against FORMAT.md. It also warns about any file of 45 MiB or more, without failing. GitHub warns about files over 50 MiB and rejects files over 100 MiB, so a table that gets this warning needs smaller parts.

## Tests

```sh
test/run
```

`test/run` loads [test/fixture.sql](test/fixture.sql), a small database full of awkward cases: quotes, commas, line breaks, NULL next to empty strings, and ids on both sides of a part boundary. It exports the fixture and compares the result byte for byte with [test/expected/](test/expected). It needs the same PostgreSQL setup as `bin/update`, but doesn't download anything.

If you change the format on purpose, run `test/run --update` and commit the new `test/expected/` together with the change to FORMAT.md.

CI runs `test/run` on every push and pull request, and you can start it by hand from the **CI** workflow in the Actions tab. It also checks the committed `tables/` against FORMAT.md.

## The weekly update

[`.github/workflows/update.yml`](.github/workflows/update.yml) runs `bin/update` every Tuesday at 06:17 UTC, after RubyGems.org publishes its Monday dump. When `tables/` or `DUMP` change, it commits them. To run it by hand, open the **Update tables** workflow in the Actions tab and choose **Run workflow**. Tick the option to export again to rerun it on a dump that's already exported.

## License

The code is released under the [MIT License](LICENSE). The data in `tables/` comes from the public RubyGems.org dumps.
