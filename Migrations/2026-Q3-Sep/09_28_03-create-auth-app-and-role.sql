--liquibase formatted sql

--changeset nwpd:PD-048-014-create-auth-app
--comment: One row per application that logs people in through auth. A role only
--comment: means something inside one application ("admin" of the production
--comment: dashboard is not "admin" of anything else), so roles hang off this.
CREATE TABLE auth.app (
    app_code      text        NOT NULL,
    display_name  text        NOT NULL,
    created_at    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_app PRIMARY KEY (app_code)
);
--rollback DROP TABLE IF EXISTS auth.app;

--changeset nwpd:PD-048-014-create-auth-app-role
--comment: The roles each application recognises. role_code is the exact string
--comment: the application compares against (for the production dashboard:
--comment: common/constants/commonConstants.RoleNames), so a user can never be
--comment: given a role the application does not know about.
CREATE TABLE auth.app_role (
    app_code      text        NOT NULL,
    role_code     text        NOT NULL,
    description   text,
    created_at    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_app_role     PRIMARY KEY (app_code, role_code),
    CONSTRAINT fk_app_role_app FOREIGN KEY (app_code) REFERENCES auth.app (app_code)
);
--rollback DROP TABLE IF EXISTS auth.app_role;
