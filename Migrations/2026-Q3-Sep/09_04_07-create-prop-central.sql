--liquibase formatted sql

--changeset nwpd:PD-048-007-create-prop-central
--comment: The QC / commercial record - CentralDB.xlsx, one row per sheet row.
--comment: prop_code is indexed but NOT unique: the live workbook already contains
--comment: two propellers twice, and the app's updateCentralData() updates every
--comment: matching row. A unique constraint here would reject the existing data
--comment: and change that behaviour, so the surrogate central_id is the key.
CREATE TABLE ${schema.name}.prop_central (
    central_id            bigint GENERATED ALWAYS AS IDENTITY,
    -- Preserves the workbook's row order for the screens that list the sheet.
    row_no                integer NOT NULL,
    prop_code             text    NOT NULL,

    client                text,
    shipping_date         text,
    box_id                text,
    remark                text,
    shipment_incharge     text,
    prod_incharge         text,
    testing_incharge      text,
    shipping_id           text,
    shipping_status       text,
    prod_status           text,
    testing_status        text,

    blade_weight          text,
    blade_weight_num      numeric GENERATED ALWAYS AS (${schema.name}.safe_numeric(blade_weight)) STORED,
    standard_weight       text,
    standard_weight_num   numeric GENERATED ALWAYS AS (${schema.name}.safe_numeric(standard_weight)) STORED,
    static_balanced       text,
    standard_balanced     text,
    aesthetics            text,
    standard_aesthetics   text,

    thrust                       text,
    thrust_num                   numeric GENERATED ALWAYS AS (${schema.name}.safe_numeric(thrust)) STORED,
    standard_thrust              text,
    standard_thrust_num          numeric GENERATED ALWAYS AS (${schema.name}.safe_numeric(standard_thrust)) STORED,
    overall_efficiency           text,
    overall_efficiency_num       numeric GENERATED ALWAYS AS (${schema.name}.safe_numeric(overall_efficiency)) STORED,
    standard_overall_efficiency  text,
    standard_overall_efficiency_num numeric GENERATED ALWAYS AS (${schema.name}.safe_numeric(standard_overall_efficiency)) STORED,
    max_vibrations               text,
    max_vibrations_num           numeric GENERATED ALWAYS AS (${schema.name}.safe_numeric(max_vibrations)) STORED,
    standard_max_vibrations      text,
    standard_max_vibrations_num  numeric GENERATED ALWAYS AS (${schema.name}.safe_numeric(standard_max_vibrations)) STORED,

    thrust_client_feedback           text,
    efficiency_client_feedback       text,
    max_vibration_client_feedback    text,
    blade_weight_client_feedback     text,
    static_balanced_client_feedback  text,
    aesthetic_client_feedback        text,

    testing_date          text,
    testing_date_ts       timestamp GENERATED ALWAYS AS (${schema.name}.safe_timestamp(testing_date)) STORED,
    size                  text,

    -- Kept as plain columns rather than folded into prop_stage_event: CentralDB
    -- may hold two rows for the same propeller, so these cannot be keyed on
    -- (prop_code, stage) without losing a row's values.
    preforming_yet_to_start_weight  text,
    preforming_in_progress_weight   text,
    moulding_yet_to_start_weight    text,
    moulding_in_progress_weight     text,

    pre_balancing         text,
    pre_balancing_num     numeric GENERATED ALWAYS AS (${schema.name}.safe_numeric(pre_balancing)) STORED,
    post_balancing        text,
    post_balancing_num    numeric GENERATED ALWAYS AS (${schema.name}.safe_numeric(post_balancing)) STORED,
    balancing_difference  text,
    balancing_difference_num numeric GENERATED ALWAYS AS (${schema.name}.safe_numeric(balancing_difference)) STORED,

    created_at            timestamptz NOT NULL DEFAULT now(),
    updated_at            timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT pk_prop_central     PRIMARY KEY (central_id),
    CONSTRAINT uq_prop_central_row UNIQUE (row_no) DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT fk_prop_central_propeller FOREIGN KEY (prop_code)
        REFERENCES ${schema.name}.propeller (prop_code) ON DELETE CASCADE
);
--rollback DROP TABLE IF EXISTS ${schema.name}.prop_central;

--changeset nwpd:PD-048-007-prop-central-indexes
--comment: prop_code is the lookup for every QC write; box_id and shipping_id back
--comment: the packaging and shipping validation queries.
CREATE INDEX idx_prop_central_prop_code   ON ${schema.name}.prop_central (prop_code);
CREATE INDEX idx_prop_central_box_id      ON ${schema.name}.prop_central (lower(box_id));
CREATE INDEX idx_prop_central_shipping_id ON ${schema.name}.prop_central (shipping_id);
CREATE INDEX idx_prop_central_client      ON ${schema.name}.prop_central (client);
CREATE INDEX idx_prop_central_prod_status ON ${schema.name}.prop_central (prod_status);
--rollback DROP INDEX IF EXISTS ${schema.name}.idx_prop_central_prop_code;
--rollback DROP INDEX IF EXISTS ${schema.name}.idx_prop_central_box_id;
--rollback DROP INDEX IF EXISTS ${schema.name}.idx_prop_central_shipping_id;
--rollback DROP INDEX IF EXISTS ${schema.name}.idx_prop_central_client;
--rollback DROP INDEX IF EXISTS ${schema.name}.idx_prop_central_prod_status;

--changeset nwpd:PD-048-007-prop-central-touch
CREATE TRIGGER trg_prop_central_touch
    BEFORE UPDATE ON ${schema.name}.prop_central
    FOR EACH ROW EXECUTE FUNCTION ${schema.name}.touch_updated_at();
--rollback DROP TRIGGER IF EXISTS trg_prop_central_touch ON ${schema.name}.prop_central;
