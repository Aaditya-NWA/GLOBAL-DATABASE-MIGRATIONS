# GLOBAL-DATABASE-MIGRATIONS

Single source of truth for the schema of every hosted database used by our
applications. **This repo is the only place schema changes are made.** No
application repo runs `CREATE`/`ALTER`/`DROP` against a shared database
directly, and no application repo keeps its own copy of the schema.

Schema changes are managed with [Liquibase](https://www.liquibase.org/).
Liquibase was chosen because it's language-neutral (plain SQL + XML), so a
.NET service, a Python service, or anything else can be governed by the same
changelog and the same `databasechangelog` history table, instead of every
stack owning its own migration mechanism (e.g. EF Core code-first, which only
.NET can use).

## How to run it

```
cp liquibase.properties.example liquibase.properties
# edit liquibase.properties with real url/username/password
sh scripts/fetch-jdbc-driver.sh          # or fetch-jdbc-driver.ps1 on Windows
liquibase --defaults-file=liquibase.properties update
```

`liquibase.properties` and `drivers/` are gitignored — never commit real
credentials or the downloaded jar.

## How application repos use this

1. **This repo defines and applies the schema.** Someone with database
   credentials runs `liquibase update` from a checkout of this repo. That is
   the only way tables, columns, functions, or views change on the hosted
   database.
2. **App repos only get connection details** via environment variables
   (host, port, database, schema, app-level user/password) — never DDL
   privileges.
3. **App repos read/write through their own data-access layer**, built
   against whatever shape this repo has published.
4. **Requesting a schema change**: open a PR here with a new dated folder
   under `Migrations/` (or new files in the current one) and a corresponding
   `<include>` in `master_changelog.xml`. **Never edit a changeset that has
   already been applied anywhere** — Liquibase checksums each one and a
   correction is always a new changeset, even a one-line fix.
5. **Rollback** uses Liquibase's own `--rollback` / `--rollback-count`,
   driven off this changelog. Never hand-edit `databasechangelog` /
   `databasechangeloglock`.

## Adding a migration (checklist)

1. Create `Migrations/<YYYY>-Q<N>-<Mon>/` if this batch's folder doesn't
   exist yet.
2. Add numbered `.sql` file(s), one changeset per logical step.
3. Add/extend that folder's `sub_changelog.xml` to `<include>` the new
   file(s) in order.
4. If it's a new folder, add an `<include>` for it in `master_changelog.xml`.
5. `liquibase validate`, then `liquibase update-sql` to review before
   actually running `update`.
6. Get it reviewed, merge, then run `update` against the target database.
7. Never delete or edit a changeset after it has run anywhere real.
