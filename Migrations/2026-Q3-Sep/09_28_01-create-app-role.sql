--liquibase formatted sql

--changeset nwpd:PD-048-012-create-app-role
--comment: The roles this application recognises. Login users live in the app's
--comment: own schema (not in a schema shared with other applications), so a role
--comment: here only ever means something to this application. role_code is the
--comment: exact string the application compares against (for the production
--comment: dashboard: common/constants/commonConstants.RoleNames), so a user can
--comment: never be given a role the application does not know about.
CREATE TABLE ${schema.name}.app_role (
    role_code     text        NOT NULL,
    description   text,
    created_at    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_app_role PRIMARY KEY (role_code)
);
--rollback DROP TABLE IF EXISTS ${schema.name}.app_role;
