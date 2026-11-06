-- File: 06_insert_tickets.sql
-- Purpose: Build 5,000 tickets from the helper table and compute status, SLA and resolution data

USE support_sla_db;

SET SQL_SAFE_UPDATES = 0;

-- Phase A: create the tickets with their basic fields
INSERT INTO tickets
    (ticket_id, customer_id, channel_id, category_id, sla_id, current_agent_id,
     subject, priority, status, created_at, due_at)
SELECT
    s.seq, s.customer_id, s.channel_id, s.category_id, p.sla_id,
    6 + 5 * ((s.category_id - 1) DIV 3) + FLOOR(s.r_agent * 5),
    CONCAT(c.category_name, ' - case #', s.seq),
    s.priority, 'Open', s.created_at,
    DATE_ADD(s.created_at, INTERVAL p.resolution_hours HOUR)
FROM stg_ticket_seed s
JOIN sla_policies p      ON p.priority = s.priority
JOIN ticket_categories c ON c.category_id = s.category_id;

-- Phase B1: work out when each ticket was resolved (agents differ in speed)
UPDATE tickets t
JOIN stg_ticket_seed s ON s.seq = t.ticket_id
JOIN sla_policies p    ON p.sla_id = t.sla_id
SET t.resolved_at = DATE_ADD(t.created_at, INTERVAL ROUND(
        p.resolution_hours * 3600 * (0.2 + 1.1 * s.r_res)
        * (0.8 + 0.05 * MOD(t.current_agent_id, 7))) SECOND)
WHERE s.r_state < IF(TIMESTAMPDIFF(DAY, t.created_at, '2026-11-06 12:00:00') > 30, 0.96, 0.55);

-- A ticket cannot be resolved in the future (our "today" is 6 Nov 2026, 12:00)
UPDATE tickets SET resolved_at = NULL WHERE resolved_at > '2026-11-06 12:00:00';

-- Phase B2: status and reopen count for resolved tickets
UPDATE tickets t
JOIN stg_ticket_seed s ON s.seq = t.ticket_id
SET t.status = IF(s.r_close < 0.7, 'Closed', 'Resolved'),
    t.reopen_count = IF(s.r_reopen < 0.01, 2, IF(s.r_reopen < 0.07, 1, 0))
WHERE t.resolved_at IS NOT NULL;

-- Phase B3: status and reopen count for unresolved tickets
UPDATE tickets t
JOIN stg_ticket_seed s ON s.seq = t.ticket_id
SET t.status = CASE
        WHEN s.r_close < 0.25 THEN 'Open'
        WHEN s.r_close < 0.65 THEN 'In Progress'
        WHEN s.r_close < 0.85 THEN 'On Hold'
        ELSE 'Reopened' END,
    t.reopen_count = IF(s.r_close >= 0.85, IF(s.r_reopen < 0.2, 2, 1), 0)
WHERE t.resolved_at IS NULL;

-- Phase B4: first response time (only for tickets someone has started working on)
UPDATE tickets t
JOIN stg_ticket_seed s ON s.seq = t.ticket_id
JOIN sla_policies p    ON p.sla_id = t.sla_id
SET t.first_response_at = DATE_ADD(t.created_at, INTERVAL
        IF(t.resolved_at IS NULL,
           ROUND(p.response_hours * 3600 * (0.1 + 1.1 * s.r_resp)),
           LEAST(ROUND(p.response_hours * 3600 * (0.1 + 1.1 * s.r_resp)),
                 FLOOR(TIMESTAMPDIFF(SECOND, t.created_at, t.resolved_at) / 2))) SECOND)
WHERE t.status <> 'Open';

SET SQL_SAFE_UPDATES = 1;