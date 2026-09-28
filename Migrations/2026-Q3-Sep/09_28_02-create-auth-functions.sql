--liquibase formatted sql

--changeset nwpd:PD-048-013-auth-touch-updated-at splitStatements:false
--comment: auth's own copy of the updated_at trigger function. nw_prod already has
--comment: one, but auth is shared by every application and must not depend on
--comment: any single application's schema existing.
CREATE OR REPLACE FUNCTION auth.touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;
--rollback DROP FUNCTION IF EXISTS auth.touch_updated_at();
