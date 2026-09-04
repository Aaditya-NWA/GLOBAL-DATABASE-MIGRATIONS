--liquibase formatted sql

--changeset nwpd:PD-048-001-create-schema
--comment: Dedicated schema for the NW Production Dashboard. Keeping the app out
--comment: of `public` means a dump/restore or a shared cluster cannot collide
--comment: with anything else living in the same database.
CREATE SCHEMA IF NOT EXISTS ${schema.name};
--rollback DROP SCHEMA IF EXISTS ${schema.name} CASCADE;
