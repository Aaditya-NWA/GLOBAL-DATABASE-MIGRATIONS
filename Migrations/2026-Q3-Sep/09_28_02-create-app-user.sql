--liquibase formatted sql

--changeset nwpd:PD-048-013-create-app-user
--comment: One row per person who can log in to this application.
--comment: role_code is a single NOT NULL column: every user has exactly ONE role,
--comment: which the application's routing relies on (each login lands on exactly
--comment: one screen).
--comment: password_hash is a bcrypt hash made by the application (Python bcrypt);
--comment: the database never sees or checks a plain-text password. The CHECK only
--comment: guards the shape, so a truncated or plain-text value cannot be stored.
CREATE TABLE ${schema.name}.app_user (
    user_id        bigint      GENERATED ALWAYS AS IDENTITY,
    username       text        NOT NULL,
    name           text,
    email          text,
    password_hash  text        NOT NULL,
    role_code      text        NOT NULL,
    is_active      boolean     NOT NULL DEFAULT true,
    created_at     timestamptz NOT NULL DEFAULT now(),
    updated_at     timestamptz NOT NULL DEFAULT now(),
    last_login_at  timestamptz,
    CONSTRAINT pk_app_user PRIMARY KEY (user_id),
    CONSTRAINT fk_app_user_role FOREIGN KEY (role_code)
        REFERENCES ${schema.name}.app_role (role_code),
    CONSTRAINT ck_app_user_username_trimmed
        CHECK (username <> '' AND username = btrim(username)),
    CONSTRAINT ck_app_user_password_hash_bcrypt
        CHECK (char_length(password_hash) = 60 AND password_hash LIKE '$2%')
);
--rollback DROP TABLE IF EXISTS ${schema.name}.app_user;

--changeset nwpd:PD-048-013-app-user-username-ci
--comment: Usernames are case-insensitive: 'Alice', 'alice' and 'ALICE' are one
--comment: login. Done with a unique index on lower(username) rather than the citext
--comment: extension, so no extension (and no superuser step) is needed. Every
--comment: lookup must compare lower(username) = lower(:input) for this index to
--comment: be used.
CREATE UNIQUE INDEX uq_app_user_username_ci ON ${schema.name}.app_user (lower(username));
--rollback DROP INDEX IF EXISTS ${schema.name}.uq_app_user_username_ci;

--changeset nwpd:PD-048-013-app-user-touch
--comment: Fires only when account details change (a role change included).
--comment: Recording a login (an UPDATE of last_login_at alone) deliberately leaves
--comment: updated_at alone, so updated_at keeps meaning "when was this account
--comment: last edited".
CREATE TRIGGER trg_app_user_touch
    BEFORE UPDATE OF username, name, email, password_hash, role_code, is_active
    ON ${schema.name}.app_user
    FOR EACH ROW EXECUTE FUNCTION ${schema.name}.touch_updated_at();
--rollback DROP TRIGGER IF EXISTS trg_app_user_touch ON ${schema.name}.app_user;
