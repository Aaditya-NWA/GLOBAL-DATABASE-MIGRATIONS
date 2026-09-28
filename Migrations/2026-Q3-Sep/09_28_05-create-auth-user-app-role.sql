--liquibase formatted sql

--changeset nwpd:PD-048-016-create-auth-user-app-role
--comment: Which role a person holds in which application.
--comment: The primary key includes role_code so that allowing several roles per
--comment: application later is a one-line change: drop uq_user_app_role_one_role.
--comment: That UNIQUE constraint is what enforces the current rule - ONE role per
--comment: person per application - which the applications' routing relies on
--comment: (each login lands on exactly one screen).
--comment: A person can still hold different roles in different applications.
CREATE TABLE auth.user_app_role (
    user_id     bigint      NOT NULL,
    app_code    text        NOT NULL,
    role_code   text        NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_user_app_role          PRIMARY KEY (user_id, app_code, role_code),
    CONSTRAINT uq_user_app_role_one_role UNIQUE (user_id, app_code),
    CONSTRAINT fk_user_app_role_user     FOREIGN KEY (user_id)
        REFERENCES auth.app_user (user_id) ON DELETE CASCADE,
    CONSTRAINT fk_user_app_role_role     FOREIGN KEY (app_code, role_code)
        REFERENCES auth.app_role (app_code, role_code)
);
--rollback DROP TABLE IF EXISTS auth.user_app_role;
