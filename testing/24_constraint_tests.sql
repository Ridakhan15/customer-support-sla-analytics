-- File: 24_constraint_tests.sql
-- Purpose: Every statement here MUST fail. Failure proves the rule is enforced.

USE support_sla_db;

-- C1: duplicate primary key
INSERT INTO departments (department_id, department_name) VALUES (1, 'Duplicate Dept');

-- C2: duplicate unique value (same email as customer 1)
SET @em = (SELECT email FROM customers WHERE customer_id = 1);
INSERT INTO customers (full_name, email, registered_date)
VALUES ('Duplicate Test', @em, '2026-01-01');

-- C3: foreign key violation (customer 99999 does not exist)
INSERT INTO tickets (customer_id, channel_id, category_id, sla_id, subject, priority, created_at, due_at)
VALUES (99999, 1, 1, 1, 'FK test', 'Low', NOW(), DATE_ADD(NOW(), INTERVAL 72 HOUR));

-- C4: CHECK constraint (deadline before creation time)
INSERT INTO tickets (customer_id, channel_id, category_id, sla_id, subject, priority, created_at, due_at)
VALUES (1, 1, 1, 1, 'CHECK test', 'Low', NOW(), DATE_SUB(NOW(), INTERVAL 1 HOUR));

-- C5: CHECK constraint (rating outside 1 to 5)
SET @t = (SELECT MIN(ticket_id) FROM tickets
          WHERE resolved_at IS NOT NULL
            AND ticket_id NOT IN (SELECT ticket_id FROM customer_feedback));
INSERT INTO customer_feedback (ticket_id, rating) VALUES (@t, 6);

-- C6: one-to-one rule (a second feedback row for the same ticket)
SET @fb = (SELECT MIN(ticket_id) FROM customer_feedback);
INSERT INTO customer_feedback (ticket_id, rating) VALUES (@fb, 3);

-- C7: invalid value for an ENUM column
INSERT INTO tickets (customer_id, channel_id, category_id, sla_id, subject, priority, created_at, due_at)
VALUES (1, 1, 1, 1, 'ENUM test', 'Urgent', NOW(), DATE_ADD(NOW(), INTERVAL 72 HOUR));