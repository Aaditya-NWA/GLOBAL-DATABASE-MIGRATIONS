--liquibase formatted sql

--changeset nwpd:PD-048-010-seed-prod-stage
--comment: The production pipeline, in order. display_name is the exact string the
--comment: application uses (common/constants/prodDashboardConstants.ProdStages)
--comment: and the exact header the legacy workbook used, so the compatibility
--comment: views can pivot on it without a second mapping.
INSERT INTO ${schema.name}.prod_stage (stage_code, display_name, sequence_no, is_stage_column) VALUES
    ('preforming_yet_to_start',   'Preforming (Yet-to-Start)',         1,  true),
    ('preforming_in_progress',    'Preforming (In-Progress)',          2,  true),
    ('moulding_yet_to_start',     'Moulding (Yet-to-Start)',           3,  true),
    ('moulding_in_progress',      'Moulding (In-Progress)',            4,  true),
    ('cnc_trimming',              'CNC Trimming',                      5,  true),
    ('trimming',                  'Trimming',                          6,  true),
    ('drilling_lc_cavity_check',  'Drilling LC and Cavity Check',      7,  true),
    ('sanding',                   'Sanding',                           8,  true),
    ('balancing_pre',             'Balancing (Pre)',                   9,  true),
    ('balancing_post',            'Balancing (Post)',                  10, true),
    ('testing',                   'Testing (Performance and Testing)', 11, true),
    ('final_qc',                  'Final QC',                          12, true),
    ('polishing',                 'Polishing',                         13, true),
    ('packaging',                 'Packaging',                         14, true),
    ('shipping',                  'Shipping',                          15, true),
    -- Terminal states. They never had a timestamp column of their own; they only
    -- ever appear as prop_tracking.current_stage values.
    ('completed',                 'Completed',                         16, false),
    ('rejected',                  'Rejected',                          17, false);
--rollback DELETE FROM ${schema.name}.prod_stage;
