--liquibase formatted sql

--changeset nwpd:PD-048-003-create-prod-stage
--comment: Lookup table for the production stages. In the workbook every stage was
--comment: a hard-coded column header; here the stage list is data, so the pipeline
--comment: order lives in one place and prop_stage_event can carry a real FK.
CREATE TABLE ${schema.name}.prod_stage (
    stage_code        text        NOT NULL,
    display_name      text        NOT NULL,
    sequence_no       integer     NOT NULL,
    -- true for the 15 stages that had their own timestamp column in
    -- ProdStagesTracking.xlsx; false for terminal states such as Completed,
    -- which only ever appeared as a current_stage value.
    is_stage_column   boolean     NOT NULL DEFAULT true,
    CONSTRAINT pk_prod_stage             PRIMARY KEY (stage_code),
    CONSTRAINT uq_prod_stage_display     UNIQUE (display_name),
    CONSTRAINT uq_prod_stage_sequence    UNIQUE (sequence_no)
);
--rollback DROP TABLE IF EXISTS ${schema.name}.prod_stage;
