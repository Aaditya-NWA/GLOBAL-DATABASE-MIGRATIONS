--liquibase formatted sql

--changeset nwpd:PD-048-009-create-shipping-batch-entry
--comment: Replaces data/ShippingDB/2024/<batch_code>_<batch_date>.xlsx, on the
--comment: same shape as prod_batch_entry. See 008 for why there is no FK to
--comment: propeller.
CREATE TABLE ${schema.name}.shipping_batch_entry (
    batch_entry_id     bigint GENERATED ALWAYS AS IDENTITY,
    batch_code         text    NOT NULL,
    batch_date         date    NOT NULL,
    row_no             integer NOT NULL,

    prop_code          text,
    client             text,
    shipping_date      text,
    box_id             text,
    shipping_id        text,
    shipping_status    text,
    remark             text,
    shipment_incharge  text,

    created_at         timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT pk_shipping_batch_entry     PRIMARY KEY (batch_entry_id),
    CONSTRAINT uq_shipping_batch_entry_row UNIQUE (batch_code, batch_date, row_no)
);
--rollback DROP TABLE IF EXISTS ${schema.name}.shipping_batch_entry;

--changeset nwpd:PD-048-009-shipping-batch-entry-indexes
CREATE INDEX idx_shipping_batch_entry_batch     ON ${schema.name}.shipping_batch_entry (batch_code, batch_date);
CREATE INDEX idx_shipping_batch_entry_prop_code ON ${schema.name}.shipping_batch_entry (lower(prop_code));
CREATE INDEX idx_shipping_batch_entry_box_id    ON ${schema.name}.shipping_batch_entry (lower(box_id));
--rollback DROP INDEX IF EXISTS ${schema.name}.idx_shipping_batch_entry_batch;
--rollback DROP INDEX IF EXISTS ${schema.name}.idx_shipping_batch_entry_prop_code;
--rollback DROP INDEX IF EXISTS ${schema.name}.idx_shipping_batch_entry_box_id;
