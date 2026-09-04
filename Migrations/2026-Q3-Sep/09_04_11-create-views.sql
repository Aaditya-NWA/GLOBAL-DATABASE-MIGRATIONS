--liquibase formatted sql

--changeset nwpd:PD-048-011-create-view-prod-stage-tracking splitStatements:false
--comment: Compatibility view: reproduces ProdStagesTracking.xlsx exactly - same
--comment: columns, same headers, same order - on top of the normalised tables.
--comment: The application's read path is a single SELECT from this view, which is
--comment: why the ~45 call sites that used to do pd.read_excel() needed no rewrite
--comment: beyond swapping the read. The pivot lives here, in version control,
--comment: rather than in Python.
CREATE VIEW ${schema.name}.v_prod_stage_tracking AS
SELECT
    t.prop_code                                     AS "Propeller",
    t.date_time                                     AS "Date Time",
    t.handler                                       AS "Handler",
    e.preforming_yet_to_start                       AS "Preforming (Yet-to-Start)",
    e.preforming_in_progress                        AS "Preforming (In-Progress)",
    e.moulding_yet_to_start                         AS "Moulding (Yet-to-Start)",
    e.moulding_in_progress                          AS "Moulding (In-Progress)",
    e.cnc_trimming                                  AS "CNC Trimming",
    e.trimming                                      AS "Trimming",
    e.drilling_lc_cavity_check                      AS "Drilling LC and Cavity Check",
    e.sanding                                       AS "Sanding",
    e.balancing_pre                                 AS "Balancing (Pre)",
    e.balancing_post                                AS "Balancing (Post)",
    e.testing                                       AS "Testing (Performance and Testing)",
    e.final_qc                                      AS "Final QC",
    e.polishing                                     AS "Polishing",
    e.packaging                                     AS "Packaging",
    e.shipping                                      AS "Shipping",
    t.current_stage                                 AS "current_stage",
    t.blade_weight                                  AS "Blade Weight",
    t.standard_weight                               AS "Standard Weight",
    t.static_balanced                               AS "Static Balanced",
    t.standard_balanced                             AS "Standard Balanced",
    t.aesthetics                                    AS "Aesthetics",
    t.standard_aesthetics                           AS "Standard Aesthetics",
    t.size                                          AS "Size",
    e.preforming_yet_to_start_weight                AS "Preforming (Yet-to-Start) Weight",
    e.preforming_in_progress_weight                 AS "Preforming (In-Progress) Weight",
    e.moulding_yet_to_start_weight                  AS "Moulding (Yet-to-Start) Weight",
    e.moulding_in_progress_weight                   AS "Moulding (In-Progress) Weight",
    t.pre_balancing                                 AS "Pre-balancing",
    t.post_balancing                                AS "Post-balancing",
    t.balancing_difference                          AS "Balancing Difference",
    t.notes                                         AS "Notes",
    t.row_no                                        AS "__row_no"
FROM ${schema.name}.prop_tracking t
LEFT JOIN (
    SELECT
        prop_code,
        max(stage_value)  FILTER (WHERE stage_code = 'preforming_yet_to_start')  AS preforming_yet_to_start,
        max(stage_value)  FILTER (WHERE stage_code = 'preforming_in_progress')   AS preforming_in_progress,
        max(stage_value)  FILTER (WHERE stage_code = 'moulding_yet_to_start')    AS moulding_yet_to_start,
        max(stage_value)  FILTER (WHERE stage_code = 'moulding_in_progress')     AS moulding_in_progress,
        max(stage_value)  FILTER (WHERE stage_code = 'cnc_trimming')             AS cnc_trimming,
        max(stage_value)  FILTER (WHERE stage_code = 'trimming')                 AS trimming,
        max(stage_value)  FILTER (WHERE stage_code = 'drilling_lc_cavity_check') AS drilling_lc_cavity_check,
        max(stage_value)  FILTER (WHERE stage_code = 'sanding')                  AS sanding,
        max(stage_value)  FILTER (WHERE stage_code = 'balancing_pre')            AS balancing_pre,
        max(stage_value)  FILTER (WHERE stage_code = 'balancing_post')           AS balancing_post,
        max(stage_value)  FILTER (WHERE stage_code = 'testing')                  AS testing,
        max(stage_value)  FILTER (WHERE stage_code = 'final_qc')                 AS final_qc,
        max(stage_value)  FILTER (WHERE stage_code = 'polishing')                AS polishing,
        max(stage_value)  FILTER (WHERE stage_code = 'packaging')                AS packaging,
        max(stage_value)  FILTER (WHERE stage_code = 'shipping')                 AS shipping,
        max(stage_weight) FILTER (WHERE stage_code = 'preforming_yet_to_start')  AS preforming_yet_to_start_weight,
        max(stage_weight) FILTER (WHERE stage_code = 'preforming_in_progress')   AS preforming_in_progress_weight,
        max(stage_weight) FILTER (WHERE stage_code = 'moulding_yet_to_start')    AS moulding_yet_to_start_weight,
        max(stage_weight) FILTER (WHERE stage_code = 'moulding_in_progress')     AS moulding_in_progress_weight
    FROM ${schema.name}.prop_stage_event
    GROUP BY prop_code
) e ON e.prop_code = t.prop_code;
--rollback DROP VIEW IF EXISTS ${schema.name}.v_prod_stage_tracking;

--changeset nwpd:PD-048-011-create-view-central-db splitStatements:false
--comment: Compatibility view for CentralDB.xlsx, same contract as
--comment: v_prod_stage_tracking above.
CREATE VIEW ${schema.name}.v_central_db AS
SELECT
    c.prop_code                        AS "Propeller",
    c.client                           AS "Client",
    c.shipping_date                    AS "Shipping Date",
    c.box_id                           AS "Box ID",
    c.remark                           AS "Remark",
    c.shipment_incharge                AS "Shipment Incharge",
    c.prod_incharge                    AS "Prod Incharge",
    c.testing_incharge                 AS "Testing Incharge",
    c.shipping_id                      AS "Shipping ID",
    c.shipping_status                  AS "Shipping status",
    c.prod_status                      AS "Prod Status",
    c.testing_status                   AS "Testing Status",
    c.blade_weight                     AS "Blade Weight",
    c.standard_weight                  AS "Standard Weight",
    c.static_balanced                  AS "Static Balanced",
    c.standard_balanced                AS "Standard Balanced",
    c.aesthetics                       AS "Aesthetics",
    c.standard_aesthetics              AS "Standard Aesthetics",
    c.thrust                           AS "Thrust",
    c.standard_thrust                  AS "Standard Thrust",
    c.overall_efficiency               AS "Overall Efficiency",
    c.standard_overall_efficiency      AS "Standard Overall Efficiency",
    c.max_vibrations                   AS "Max Vibrations",
    c.standard_max_vibrations          AS "Standard Max Vibrations",
    c.thrust_client_feedback           AS "Thrust ClientFeedback",
    c.efficiency_client_feedback       AS "Efficiency ClientFeedback",
    c.max_vibration_client_feedback    AS "Max Vibration ClientFeedback",
    c.blade_weight_client_feedback     AS "Blade Weight ClientFeedback",
    c.static_balanced_client_feedback  AS "Static Balanced ClientFeedback",
    c.aesthetic_client_feedback        AS "Aesthetic ClientFeedback",
    c.testing_date                     AS "Testing Date",
    c.size                             AS "Size",
    c.preforming_yet_to_start_weight   AS "Preforming (Yet-to-Start) Weight",
    c.preforming_in_progress_weight    AS "Preforming (In-Progress) Weight",
    c.moulding_yet_to_start_weight     AS "Moulding (Yet-to-Start) Weight",
    c.moulding_in_progress_weight      AS "Moulding (In-Progress) Weight",
    c.pre_balancing                    AS "Pre-balancing",
    c.post_balancing                   AS "Post-balancing",
    c.balancing_difference             AS "Balancing Difference",
    c.row_no                           AS "__row_no"
FROM ${schema.name}.prop_central c;
--rollback DROP VIEW IF EXISTS ${schema.name}.v_central_db;
