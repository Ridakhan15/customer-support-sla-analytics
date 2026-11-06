-- File: 09_insert_feedback.sql
-- Purpose: Generate customer feedback linked to SLA performance

USE support_sla_db;

-- Resolved ON TIME: ratings lean high
INSERT INTO customer_feedback (ticket_id, rating, comments, submitted_at)
SELECT t.ticket_id,
       ELT(1 + FLOOR(RAND() * 10), 5,5,5,5,4,4,4,3,3,2),
       NULL,
       LEAST(DATE_ADD(t.resolved_at, INTERVAL (1 + FLOOR(RAND() * 48)) HOUR),
             CAST('2026-11-06 12:00:00' AS DATETIME))
FROM tickets t
WHERE t.resolved_at IS NOT NULL AND t.resolved_at <= t.due_at AND RAND() < 0.6;

-- Resolved AFTER the deadline (SLA breached): ratings lean low
INSERT INTO customer_feedback (ticket_id, rating, comments, submitted_at)
SELECT t.ticket_id,
       ELT(1 + FLOOR(RAND() * 10), 1,1,2,2,2,3,3,3,4,5),
       NULL,
       LEAST(DATE_ADD(t.resolved_at, INTERVAL (1 + FLOOR(RAND() * 48)) HOUR),
             CAST('2026-11-06 12:00:00' AS DATETIME))
FROM tickets t
WHERE t.resolved_at IS NOT NULL AND t.resolved_at > t.due_at AND RAND() < 0.6;

-- Add a comment matching each rating
UPDATE customer_feedback
SET comments = CASE rating
        WHEN 5 THEN 'Excellent support, issue resolved quickly'
        WHEN 4 THEN 'Good service, minor delays'
        WHEN 3 THEN 'Average experience, took longer than expected'
        WHEN 2 THEN 'Poor experience, slow resolution'
        ELSE 'Very dissatisfied, issue handled badly'
    END
WHERE feedback_id > 0;