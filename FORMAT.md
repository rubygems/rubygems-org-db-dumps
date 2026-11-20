# Output format of `tables/`

This is the contract between this repository and the programs that read
`tables/`, such as ClickGems. The format matches, byte for byte, the output that
[segiddins/rubygems-org-db-dumps](https://github.com/segiddins/rubygems-org-db-dumps)
produced, so readers of that repository can switch without changes.

`bin/check-format` reads this file and fails when a `tables/` folder does not
match it, so keep the table sections below in the form they have now.

## Files

- `tables/` holds one folder per table, named after the table, and nothing else.
  The tables are: attestations, deletions, dependencies, gem_downloads,
  linksets, rubygems, versions.
- Each folder holds only files named `part_N.csv`, where `N` is a decimal
  number without leading zeros, starting at `part_0.csv`.
- Part `N` of a table holds exactly the rows whose `id` satisfies
  `N * size <= id < (N + 1) * size`, where `size` is the table's rows per part,
  listed below. A part is written only when it has at least one row, so the
  numbers can have gaps (for example, `versions` has no `part_0.csv` because no
  version has an id below 50000).
- Every export replaces each table folder completely: no part from an earlier
  dump is left behind.

## CSV encoding

This is the CSV that PostgreSQL's `COPY ... TO ... WITH (FORMAT csv, HEADER)`
writes.

- Encoding is UTF-8, without a byte order mark.
- Every row, including the last, ends with a single line feed (`\n`).
- The first row of every part is the header: the column names below, in the
  order below, separated by commas.
- Fields are separated by commas.
- A field is enclosed in double quotes when, and only when, it is an empty
  string or it contains a comma, a double quote, a carriage return, or a line
  feed. Inside a quoted field, a double quote is written as two double quotes.
  Line breaks inside a quoted field are written as they are.
- NULL is an empty, unquoted field. An empty string is `""`.
- Rows are sorted by `id`, ascending, within a part and across parts.

## Value formats

Values are written as PostgreSQL prints them with `DateStyle=ISO, MDY` and
`TimeZone=UTC`. The types used in the table sections are:

- `integer`: a decimal integer, such as `12` or `271693712619`.
- `boolean`: `t` or `f`.
- `timestamp`: `YYYY-MM-DD HH:MM:SS` followed by the fractional seconds, when
  they are not zero, with trailing zeros removed, such as `2009-07-25 17:46:22`
  or `2015-04-20 21:24:46.2566`. There is no time zone; the values are UTC.
- `text`: any text. JSON columns (`attestations.body`) are written as
  PostgreSQL prints `jsonb`, and `versions.metadata` as it prints `hstore`,
  such as `"source_code_uri"=>"https://example.org"`.

Any field may be NULL.

## Tables

### attestations

Rows per part: 2500

| Column | Type |
| --- | --- |
| id | integer |
| version_id | integer |
| body | text |
| media_type | text |
| created_at | timestamp |
| updated_at | timestamp |

### deletions

Rows per part: 100000

| Column | Type |
| --- | --- |
| id | integer |
| user_id | integer |
| rubygem | text |
| number | text |
| platform | text |
| created_at | timestamp |
| updated_at | timestamp |
| version_id | integer |
| ruby_abi | text |

### dependencies

Rows per part: 250000

| Column | Type |
| --- | --- |
| id | integer |
| requirements | text |
| created_at | timestamp |
| updated_at | timestamp |
| rubygem_id | integer |
| version_id | integer |
| scope | text |
| unresolved_name | text |

### gem_downloads

Rows per part: 1000000

| Column | Type |
| --- | --- |
| id | integer |
| rubygem_id | integer |
| version_id | integer |
| count | integer |

### linksets

Rows per part: 100000

| Column | Type |
| --- | --- |
| id | integer |
| rubygem_id | integer |
| home | text |
| wiki | text |
| docs | text |
| mail | text |
| code | text |
| bugs | text |
| created_at | timestamp |
| updated_at | timestamp |

### rubygems

Rows per part: 100000

| Column | Type |
| --- | --- |
| id | integer |
| name | text |
| created_at | timestamp |
| updated_at | timestamp |
| indexed | boolean |
| organization_id | integer |

### versions

Rows per part: 50000

| Column | Type |
| --- | --- |
| id | integer |
| authors | text |
| description | text |
| number | text |
| rubygem_id | integer |
| built_at | timestamp |
| updated_at | timestamp |
| summary | text |
| platform | text |
| created_at | timestamp |
| indexed | boolean |
| prerelease | boolean |
| position | integer |
| latest | boolean |
| full_name | text |
| licenses | text |
| size | integer |
| requirements | text |
| required_ruby_version | text |
| sha256 | text |
| metadata | text |
| required_rubygems_version | text |
| yanked_at | timestamp |
| pusher_id | integer |
| canonical_number | text |
| cert_chain | text |
| pusher_api_key_id | integer |
| gem_platform | text |
| gem_full_name | text |
| spec_sha256 | text |
| info_checksum_v2 | text |
| yanked_info_checksum_v2 | text |
| ruby_abi | text |
| content_address | text |
