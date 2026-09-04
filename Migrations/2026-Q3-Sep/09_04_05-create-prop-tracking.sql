--liquibase formatted sql

--changeset nwpd:PD-048-005-create-prop-tracking
--comment: One row per propeller: everything ProdStagesTracking.xlsx held that is
--comment: NOT a per-stage value. The 15 stage-timestamp columns and the 4
--comment: '<Stage> Weight' columns are normalised out into prop_stage_event.
--comment: Value columns are text on purpose - the app writes sentinels such as
--comment: 'Pending' and '_' into them - with generated numeric/timestamp shadow
--comment: columns alongside for reporting. See db/DATABASE.md, "Column types".
CREATE TABLE ${schema.name}.prop_tracking (
    prop_code             text        NOT NULL,
    -- Preserves the workbook's row order, which several screens rely on when
    -- they render the sheet as a table.
    row_no                integer     NOT NULL,

    date_time             text,
    date_time_ts          timestamp GENERATED ALWAYS AS (${schema.name}.safe_timestamp(date_time)) STORED,
    handler               text,
    -- Free text, not a FK to prod_stage: the app also stores 'Rejected' here and
    -- compares it case-insensitively, so constraining it would change behaviour.
    current_stage         text,

    blade_weight          text,
    blade_weight_num      numeric GENERATED ALWAYS AS (${schema.name}.safe_numeric(blade_weight)) STORED,
    standard_weight       text,
    standard_weight_num   numeric GENERATED ALWAYS AS (${schema.name}.safe_numeric(standard_weight)) STORED,
    static_balanced       text,
    standard_balanced     text,
    aesthetics            text,
    standard_aesthetics   text,
    size                  text,

    pre_balancing         text,
    pre_balancing_num     numeric GENERATED ALWAYS AS (${schema.name}.safe_numeric(pre_balancing)) STORED,
    post_balancing        text,
    post_balancing_num    numeric GENERATED ALWAYS AS (${schema.name}.safe_numeric(post_balancing)) STORED,
    balancing_difference  text,
    balancing_difference_num numeric GENERATED ALWAYS AS (${schema.name}.safe_numeric(balancing_difference)) STORED,

    notes                 text,

    created_at            timestamptz NOT NULL DEFAULT now(),
    updated_at            timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT pk_prop_tracking     PRIMARY KEY (prop_code),
    CONSTRAINT uq_prop_tracking_row UNIQUE (row_no) DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT fk_prop_tracking_propeller FOREIGN KEY (prop_code)
        REFERENCES ${schema.name}.propeller (prop_code) ON DELETE CASCADE
);
--rollback DROP TABLE IF EXISTS ${schema.name}.prop_tracking;

--changeset nwpd:PD-048-005-prop-tracking-indexes
--comment: current_stage drives every stage screen and the live dashboard's stage
--comment: distribution; date_time_ts drives its date-period filters.
CREATE INDEX idx_prop_tracking_current_stage ON ${schema.name}.prop_tracking (current_stage);
CREATE INDEX idx_prop_tracking_date_time_ts  ON ${schema.name}.prop_tracking (date_time_ts);
CREATE INDEX idx_prop_tracking_size          ON ${schema.name}.prop_tracking (size);
--rollback DROP INDEX IF EXISTS ${schema.name}.idx_prop_tracking_current_stage;
--rollback DROP INDEX IF EXISTS ${schema.name}.idx_prop_tracking_date_time_ts;
--rollback DROP INDEX IF EXISTS ${schema.name}.idx_prop_tracking_size;

--changeset nwpd:PD-048-005-prop-tracking-touch
CREATE TRIGGER trg_prop_tracking_touch
    BEFORE UPDATE ON ${schema.name}.prop_tracking
    FOR EACH ROW EXECUTE FUNCTION ${schema.name}.touch_updated_at();
--rollback DROP TRIGGER IF EXISTS trg_prop_tracking_touch ON ${schema.name}.prop_tracking;
