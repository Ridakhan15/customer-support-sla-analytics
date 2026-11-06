-- File: 03_insert_lookup_data.sql
-- Purpose: Fill reference tables (departments, channels, categories, SLA policies)

USE support_sla_db;

INSERT INTO departments (department_id, department_name) VALUES
(1, 'Billing & Payments'),
(2, 'Technical Support'),
(3, 'Account Services'),
(4, 'Delivery & Logistics'),
(5, 'Product Support');

INSERT INTO support_channels (channel_id, channel_name) VALUES
(1, 'Email'),
(2, 'Phone'),
(3, 'Live Chat'),
(4, 'Web Form'),
(5, 'Social Media'),
(6, 'Mobile App');

INSERT INTO ticket_categories (category_id, category_name, department_id) VALUES
(1,  'Refund Request',        1),
(2,  'Payment Failure',       1),
(3,  'Invoice Dispute',       1),
(4,  'Login Issue',           2),
(5,  'App Crash',             2),
(6,  'Slow Performance',      2),
(7,  'Password Reset',        3),
(8,  'Profile Update',        3),
(9,  'Account Closure',       3),
(10, 'Delivery Delay',        4),
(11, 'Wrong Item Delivered',  4),
(12, 'Damaged Package',       4),
(13, 'Product Defect',        5),
(14, 'Warranty Claim',        5),
(15, 'Usage Guidance',        5);

INSERT INTO sla_policies (sla_id, priority, response_hours, resolution_hours) VALUES
(1, 'Low',      8, 72),
(2, 'Medium',   4, 48),
(3, 'High',     2, 24),
(4, 'Critical', 1,  8);