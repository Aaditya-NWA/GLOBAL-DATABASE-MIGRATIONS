--liquibase formatted sql

-- Least-privilege grants for the application's runtime login.
--
-- Account model (see README.md):
--   nw_migrator  runs Liquibase and owns every object. Only it may change schema.
--   nw_app       the application. Reads/writes data, never DDL, never TRUNCATE,
--                and may not create or change users or roles.
--
-- The logins themselves are NOT created here: a CREATE ROLE ... PASSWORD would put
-- a password in git. A superuser creates them once (README.md, "Database
-- accounts"). If the application login does not exist, these changesets HALT
-- instead of failing half-way.

--changeset nwpd:PD-048-015-grants-app-schema
--preconditions onFail:HALT onError:HALT
--precondition-sql-check expectedResult:1 SELECT count(*) FROM pg_roles WHERE rolname = '${app.role.name}'
--comment: Application data. prod_stage is Liquibase-owned reference data, so the
--comment: app may only read it. The two views are listed explicitly: a view runs
--comment: with its owner's rights, but the caller still needs SELECT on the view.
--comment: The login tables (app_user, app_role) are granted separately below.
GRANT USAGE ON SCHEMA ${schema.name} TO ${app.role.name};
GRANT SELECT, INSERT, UPDATE, DELETE ON
    ${schema.name}.propeller,
    ${schema.name}.prop_tracking,
    ${schema.name}.prop_stage_event,
    ${schema.name}.prop_central,
    ${schema.name}.prod_batch_entry,
    ${schema.name}.shipping_batch_entry
    TO ${app.role.name};
GRANT SELECT ON ${schema.name}.prod_stage TO ${app.role.name};
GRANT SELECT ON
    ${schema.name}.v_prod_stage_tracking,
    ${schema.name}.v_central_db
    TO ${app.role.name};
--rollback REVOKE ALL ON ALL TABLES IN SCHEMA ${schema.name} FROM ${app.role.name};
--rollback REVOKE USAGE ON SCHEMA ${schema.name} FROM ${app.role.name};

--changeset nwpd:PD-048-015-grants-app-schema-defaults
--comment: Tables created later in the app schema by the migrator are readable and
--comment: writable by the app without a separate GRANT changeset. Tighten a
--comment: specific table afterwards (REVOKE ALL, then GRANT what it needs) if it is
--comment: reference data or holds logins - see PD-048-015-grants-app-user.
--comment: No sequence grants are needed: every key is GENERATED ALWAYS AS IDENTITY.
ALTER DEFAULT PRIVILEGES IN SCHEMA ${schema.name}
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${app.role.name};
--rollback ALTER DEFAULT PRIVILEGES IN SCHEMA ${schema.name} REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM ${app.role.name};

--changeset nwpd:PD-048-015-grants-app-user
--preconditions onFail:HALT onError:HALT
--precondition-sql-check expectedResult:1 SELECT count(*) FROM pg_roles WHERE rolname = '${app.role.name}'
--comment: Logins. The app can look users up and stamp last_login_at - nothing
--comment: else. It cannot add users, change passwords or roles, or edit the role
--comment: list; those are admin actions done as the migrator.
--comment: REVOKE ALL comes first on purpose. If these tables were ever created
--comment: after the default privileges above (a different changeset order, or a
--comment: database where they already existed), the app would have inherited
--comment: INSERT/UPDATE/DELETE on them. And a column-level UPDATE grant restricts
--comment: nothing while a table-wide UPDATE grant exists. Revoking first makes the
--comment: result the same whatever order the database was built in.
REVOKE ALL ON ${schema.name}.app_role, ${schema.name}.app_user FROM ${app.role.name};
GRANT SELECT ON ${schema.name}.app_role, ${schema.name}.app_user TO ${app.role.name};
GRANT UPDATE (last_login_at) ON ${schema.name}.app_user TO ${app.role.name};
--rollback REVOKE ALL ON ${schema.name}.app_role, ${schema.name}.app_user FROM ${app.role.name};
