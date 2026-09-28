--liquibase formatted sql

--changeset nwpd:PD-048-017-seed-auth-app
--comment: The NW Production Dashboard as a login application.
INSERT INTO auth.app (app_code, display_name) VALUES
    ('nw_prod_dashboard', 'NW Production Dashboard');
--rollback DELETE FROM auth.app WHERE app_code = 'nw_prod_dashboard';

--changeset nwpd:PD-048-017-seed-auth-app-role
--comment: The production dashboard's roles. role_code must equal the string in
--comment: common/constants/commonConstants.RoleNames, because common/route.py
--comment: routes on it. No users or password hashes are seeded here - they are
--comment: loaded by the application repo's database/migration/importUsers.py.
INSERT INTO auth.app_role (app_code, role_code, description) VALUES
    ('nw_prod_dashboard', 'admin',                           'Admin dashboard'),
    ('nw_prod_dashboard', 'prod',                            'Production - all stages, bypasses stage prerequisites'),
    ('nw_prod_dashboard', 'stake',                           'Stakeholder - read-only propeller lookup'),
    ('nw_prod_dashboard', 'livewire',                        'Live Dashboard (read-only analytics)'),
    ('nw_prod_dashboard', 'preforming',                      'Preforming stage operator'),
    ('nw_prod_dashboard', 'moulding',                        'Moulding stage operator'),
    ('nw_prod_dashboard', 'cnc_trimming',                    'CNC Trimming stage operator'),
    ('nw_prod_dashboard', 'trimming',                        'Trimming stage operator'),
    ('nw_prod_dashboard', 'drilling_lc_and_cavity_check',    'Drilling LC and Cavity Check stage operator'),
    ('nw_prod_dashboard', 'sanding',                         'Sanding stage operator'),
    ('nw_prod_dashboard', 'balancing',                       'Balancing (Pre/Post) stage operator'),
    ('nw_prod_dashboard', 'testing_performance_and_testing', 'Testing (Performance and Testing) stage operator'),
    ('nw_prod_dashboard', 'final_qc',                        'Final QC stage operator'),
    ('nw_prod_dashboard', 'polishing',                       'Polishing stage operator'),
    ('nw_prod_dashboard', 'packaging',                       'Packaging stage operator'),
    ('nw_prod_dashboard', 'shipping',                        'Shipping stage operator');
--rollback DELETE FROM auth.app_role WHERE app_code = 'nw_prod_dashboard';
