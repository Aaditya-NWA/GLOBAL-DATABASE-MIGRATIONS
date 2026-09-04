--liquibase formatted sql

--changeset nwpd:PD-048-004-create-propeller
--comment: The propeller entity. Both workbooks were keyed on a 'Propeller' string
--comment: that was repeated in every sheet; this table makes that key real so the
--comment: tracking record, the central QC/commercial record and the per-stage
--comment: events can all reference it.
--comment: Note it deliberately carries NO 'Size': ProdStagesTracking and CentralDB
--comment: disagree on Size for 288 of the 1605 propellers, so unifying it here
--comment: would silently rewrite data. Size stays on each record, as it is today.
CREATE TABLE ${schema.name}.propeller (
    prop_code   text        NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_propeller PRIMARY KEY (prop_code)
);
--rollback DROP TABLE IF EXISTS ${schema.name}.propeller;

--changeset nwpd:PD-048-004-propeller-touch
CREATE TRIGGER trg_propeller_touch
    BEFORE UPDATE ON ${schema.name}.propeller
    FOR EACH ROW EXECUTE FUNCTION ${schema.name}.touch_updated_at();
--rollback DROP TRIGGER IF EXISTS trg_propeller_touch ON ${schema.name}.propeller;
