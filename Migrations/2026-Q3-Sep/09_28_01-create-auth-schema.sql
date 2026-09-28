--liquibase formatted sql

--changeset nwpd:PD-048-012-create-auth-schema
--comment: Shared login schema for every application in this database. Users and
--comment: their per-application roles live here instead of in each app's own
--comment: schema (or in a Secrets Manager blob), so one person has one account
--comment: and one place to be deactivated. The name is fixed on purpose - unlike
--comment: the per-app schema it does not come from the schema.name property -
--comment: because every app looks for its users in the same place.
CREATE SCHEMA IF NOT EXISTS auth;
--rollback DROP SCHEMA IF EXISTS auth CASCADE;
