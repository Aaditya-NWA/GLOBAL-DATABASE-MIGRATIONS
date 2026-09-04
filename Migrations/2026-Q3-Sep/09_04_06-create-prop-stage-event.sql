--liquibase formatted sql

--changeset nwpd:PD-048-006-create-prop-stage-event
--comment: The main normalisation win. ProdStagesTracking.xlsx carried the same
--comment: fact - "when did this propeller clear this stage" - across 15 repeated
--comment: columns, plus 4 more '<Stage> Weight' columns for a subset of them.
--comment: Here it is one row per (propeller, stage). Adding a stage becomes a seed
--comment: row in prod_stage instead of a schema change to a wide table.
--comment: stage_value stays text because the app also writes 'Pending'/'Waiting'
--comment: there; stage_ts is the parsed shadow used for reporting.
CREATE TABLE ${schema.name}.prop_stage_event (
    prop_code        text NOT NULL,
    stage_code       text NOT NULL,

    stage_value      text,
    stage_ts         timestamp GENERATED ALWAYS AS (${schema.name}.safe_timestamp(stage_value)) STORED,

    -- Only 4 stages ever had a weight column in the workbook; NULL elsewhere.
    stage_weight     text,
    stage_weight_num numeric GENERATED ALWAYS AS (${schema.name}.safe_numeric(stage_weight)) STORED,

    created_at       timestamptz NOT NULL DEFAULT now(),
    updated_at       timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT pk_prop_stage_event PRIMARY KEY (prop_code, stage_code),
    CONSTRAINT fk_prop_stage_event_propeller FOREIGN KEY (prop_code)
        REFERENCES ${schema.name}.propeller (prop_code) ON DELETE CASCADE,
    CONSTRAINT fk_prop_stage_event_stage FOREIGN KEY (stage_code)
        REFERENCES ${schema.name}.prod_stage (stage_code)
);
--rollback DROP TABLE IF EXISTS ${schema.name}.prop_stage_event;

--changeset nwpd:PD-048-006-prop-stage-event-indexes
--comment: "which props cleared stage X, and when" - the query behind the live
--comment: dashboard's throughput trend and the admin stage counts.
CREATE INDEX idx_prop_stage_event_stage    ON ${schema.name}.prop_stage_event (stage_code);
CREATE INDEX idx_prop_stage_event_stage_ts ON ${schema.name}.prop_stage_event (stage_code, stage_ts);
--rollback DROP INDEX IF EXISTS ${schema.name}.idx_prop_stage_event_stage;
--rollback DROP INDEX IF EXISTS ${schema.name}.idx_prop_stage_event_stage_ts;

--changeset nwpd:PD-048-006-prop-stage-event-touch
CREATE TRIGGER trg_prop_stage_event_touch
    BEFORE UPDATE ON ${schema.name}.prop_stage_event
    FOR EACH ROW EXECUTE FUNCTION ${schema.name}.touch_updated_at();
--rollback DROP TRIGGER IF EXISTS trg_prop_stage_event_touch ON ${schema.name}.prop_stage_event;
