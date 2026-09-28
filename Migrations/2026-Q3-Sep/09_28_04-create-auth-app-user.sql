--liquibase formatted sql

--changeset nwpd:PD-048-015-create-auth-app-user
--comment: One row per person, shared by every application. No role column: what a
--comment: person may do is per application, in auth.user_app_role.
--comment: password_hash is a bcrypt hash made by the application (Python bcrypt);
--comment: the database never sees or checks a plain-text password. The CHECK only
--comment: guards the shape, so a truncated or plain-text value cannot be stored.
CREATE TABLE auth.app_user (
    user_id        bigint      GENERATED ALWAYS AS IDENTITY,
    username       text        NOT NULL,
    name           text,
    email          text,
    password_hash  text        NOT NULL,
    is_active      boolean     NOT NULL DEFAULT true,
    created_at     timestamptz NOT NULL DEFAULT now(),
    updated_at     timestamptz NOT NULL DEFAULT now(),
    last_login_at  timestamptz,
    CONSTRAINT pk_app_user PRIMARY KEY (user_id),
    CONSTRAINT ck_app_user_username_trimmed
        CHECK (username <> '' AND username = btrim(username)),
    CONSTRAINT ck_app_user_password_hash_bcrypt
        CHECK (char_length(password_hash) = 60 AND password_hash LIKE '$2%')
);
--rollback DROP TABLE IF EXISTS auth.app_user;

--changeset nwpd:PD-048-015-app-user-username-ci
--comment: Usernames are case-insensitive: 'Alice', 'alice' and 'ALICE' are one
--comment: login. Done with a unique index on lower(username) rather than the citext
--comment: extension, so no extension (and no superuser step) is needed and any
--comment: other stack reading auth gets the same rule. Every lookup must compare
--comment: lower(username) = lower(:input) for this index to be used.
CREATE UNIQUE INDEX uq_app_user_username_ci ON auth.app_user (lower(username));
--rollback DROP INDEX IF EXISTS auth.uq_app_user_username_ci;

--changeset nwpd:PD-048-015-app-user-touch
--comment: Fires only when account details change. Recording a login (an UPDATE of
--comment: last_login_at alone) deliberately leaves updated_at alone, so
--comment: updated_at keeps meaning "when was this account last edited".
CREATE TRIGGER trg_app_user_touch
    BEFORE UPDATE OF username, name, email, password_hash, is_active ON auth.app_user
    FOR EACH ROW EXECUTE FUNCTION auth.touch_updated_at();
--rollback DROP TRIGGER IF EXISTS trg_app_user_touch ON auth.app_user;
