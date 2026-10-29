--liquibase formatted sql

--changeset nwpd:PD-048-014-seed-app-role
--comment: The production dashboard's roles. role_code must equal the string in
--comment: common/constants/commonConstants.RoleNames, because common/route.py
--comment: routes on it. No users or password hashes are seeded here - they are
--comment: loaded by the application repo's database/migration/importUsers.py.
INSERT INTO ${schema.name}.app_role (role_code, description) VALUES
    ('admin',                           'Admin dashboard'),
    ('prod',                            'Production - all stages, bypasses stage prerequisites'),
    ('stake',                           'Stakeholder - read-only propeller lookup'),
    ('livewire',                        'Live Dashboard (read-only analytics)'),
    ('preforming',                      'Preforming stage operator'),
    ('moulding',                        'Moulding stage operator'),
    ('cnc_trimming',                    'CNC Trimming stage operator'),
    ('trimming',                        'Trimming stage operator'),
    ('drilling_lc_and_cavity_check',    'Drilling LC and Cavity Check stage operator'),
    ('sanding',                         'Sanding stage operator'),
    ('balancing',                       'Balancing (Pre/Post) stage operator'),
    ('testing_performance_and_testing', 'Testing (Performance and Testing) stage operator'),
    ('final_qc',                        'Final QC stage operator'),
    ('polishing',                       'Polishing stage operator'),
    ('packaging',                       'Packaging stage operator'),
    ('shipping',                        'Shipping stage operator');
--rollback DELETE FROM ${schema.name}.app_role;
