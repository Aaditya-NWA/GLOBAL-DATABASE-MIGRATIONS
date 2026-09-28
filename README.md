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

Liquibase always runs as the **migrator** login (`nw_migrator`), never as an
application login. See the next section.

## Database accounts

Every database has two kinds of login. Neither is created by a changeset,
because `CREATE ROLE ... PASSWORD` would put a password in git.

| Login | Who uses it | Rights |
|-------|-------------|--------|
| `nw_migrator` | Liquibase (this repo) | Owns the database and every schema, table, view and function in it. The only login that can change schema. |
| `nw_app` | The NW Production Dashboard | Read/write on its data tables, read-only on reference data and views, read-only on `auth` except stamping `last_login_at`. No DDL, no `TRUNCATE`, cannot create users or change roles. |

The grants live in `Migrations/2026-Q3-Sep/09_28_07-grants.sql`. It HALTs if
the application login does not exist yet. The application login's name comes
from the `app.role.name` property in `master_changelog.xml` (default `nw_app`).

One-time setup on a new server, as a superuser (`postgres`), in `psql`:

```sql
CREATE ROLE nw_migrator LOGIN;
\password nw_migrator
CREATE ROLE nw_app LOGIN;
\password nw_app
CREATE DATABASE nw_production OWNER nw_migrator;
```

`\password` prompts for the password instead of taking it on the command line,
so it never lands in shell history. After that no superuser is needed: run
`liquibase update` as `nw_migrator`, which creates everything and grants
`nw_app` its access.

## Shared login schema: `auth`

`auth` holds users and their roles for **every** application in the database,
so a person has one account (one password, one place to deactivate them)
regardless of how many apps they use.

| Table | Holds |
|-------|-------|
| `auth.app` | one row per application (`nw_prod_dashboard`, ...) |
| `auth.app_role` | the roles each application recognises |
| `auth.app_user` | one row per person: username, name, email, bcrypt `password_hash`, `is_active`, `last_login_at` |
| `auth.user_app_role` | which role a person holds in which application |

Rules:

- **One role per person per application.** Enforced by
  `uq_user_app_role_one_role`. To allow several roles later, drop that
  constraint in a new changeset — but the application must first be able to
  handle a user with more than one role.
- **Usernames are case-insensitive**, via a unique index on `lower(username)`.
  Any query that looks a user up must compare `lower(username) = lower(:input)`.
- **No users or password hashes are ever put in a changeset.** Only
  applications and their roles are seeded here. Users are loaded by each
  application's own import tooling (the dashboard's is
  `database/migration/importUsers.py`), running as `nw_migrator`.
- **Applications may only read `auth`**, apart from stamping `last_login_at`.
  Adding users or changing roles is an admin action done as `nw_migrator`.
- Adding a second application: a new changeset inserting its `auth.app` row
  and its `auth.app_role` rows, plus grants for its login.

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
