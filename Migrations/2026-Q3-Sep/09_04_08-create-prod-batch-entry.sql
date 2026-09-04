--liquibase formatted sql

--changeset nwpd:PD-048-008-create-prod-batch-entry
--comment: Replaces the one-workbook-per-shipment files under
--comment: data/ProdDB/2024/NW/<batch_code>_<batch_date>.xlsx. What used to be
--comment: encoded in a filename is now two ordinary columns, so a batch can be
--comment: queried without globbing a directory.
--comment: No FK to propeller: these are historical shipment records whose prop
--comment: identifiers (e.g. 'NW-eDH26-1520') predate the current prop_code
--comment: convention and do not all exist in the tracking data.
CREATE TABLE ${schema.name}.prod_batch_entry (
    batch_entry_id      bigint GENERATED ALWAYS AS IDENTITY,
    batch_code          text    NOT NULL,
    batch_date          date    NOT NULL,
    row_no              integer NOT NULL,

    prop_code           text,
    client              text,
    shipping_date       text,
    box_id              text,
    shipping_id         text,
    shipping_status     text,
    prod_incharge       text,
    prod_status         text,
    blade_weight        text,
    standard_weight     text,
    static_balanced     text,
    standard_balanced   text,
    aesthetics          text,
    standard_aesthetics text,

    created_at          timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT pk_prod_batch_entry     PRIMARY KEY (batch_entry_id),
    CONSTRAINT uq_prod_batch_entry_row UNIQUE (batch_code, batch_date, row_no)
);
--rollback DROP TABLE IF EXISTS ${schema.name}.prod_batch_entry;

--changeset nwpd:PD-048-008-prod-batch-entry-indexes
CREATE INDEX idx_prod_batch_entry_batch     ON ${schema.name}.prod_batch_entry (batch_code, batch_date);
CREATE INDEX idx_prod_batch_entry_prop_code ON ${schema.name}.prod_batch_entry (lower(prop_code));
--rollback DROP INDEX IF EXISTS ${schema.name}.idx_prod_batch_entry_batch;
--rollback DROP INDEX IF EXISTS ${schema.name}.idx_prod_batch_entry_prop_code;
