-- File: 15_create_views.sql
-- Purpose: Reusable views for common business reports

USE support_sla_db;

-- View 1: one row per ticket with all the readable details and the SLA result
CREATE OR REPLACE VIEW v_ticket_details AS
SELECT t.ticket_id, t.subject, t.priority, t.status,
       t.created_at, t.first_response_at, t.due_at, t.resolved_at, t.reopen_count,
       cu.full_name  AS customer_name,
       cu.city       AS customer_city,
       cat.category_name,
       d.department_name,
       ch.channel_name,
       ag.full_name  AS agent_name,
       CASE WHEN t.resolved_at IS NOT NULL
            THEN ROUND(TIMESTAMPDIFF(MINUTE, t.created_at, t.resolved_at) / 60, 1)
       END AS resolution_hours,
       CASE WHEN t.resolved_at IS NOT NULL AND t.resolved_at <= t.due_at THEN 'Met SLA'
            WHEN t.resolved_at IS NOT NULL THEN 'Breached SLA'
            WHEN NOW() > t.due_at THEN 'Breached SLA'
            ELSE 'Open - within deadline'
       END AS sla_result
FROM tickets t
INNER JOIN customers cu         ON cu.customer_id   = t.customer_id
INNER JOIN ticket_categories cat ON cat.category_id = t.category_id
INNER JOIN departments d        ON d.department_id  = cat.department_id
INNER JOIN support_channels ch  ON ch.channel_id    = t.channel_id
LEFT JOIN agents ag             ON ag.agent_id      = t.current_agent_id;

-- View 2: the open backlog with ticket age and overdue time
CREATE OR REPLACE VIEW v_open_backlog AS
SELECT ticket_id, subject, priority, status, department_name, agent_name,
       created_at, due_at,
       TIMESTAMPDIFF(HOUR, created_at, NOW())          AS age_hours,
       GREATEST(0, TIMESTAMPDIFF(HOUR, due_at, NOW())) AS hours_overdue
FROM v_ticket_details
WHERE resolved_at IS NULL;

-- View 3: agent scorecard
CREATE OR REPLACE VIEW v_agent_performance AS
SELECT a.agent_id, a.full_name AS agent_name, d.department_name,
       COUNT(t.ticket_id)                    AS total_tickets,
       COALESCE(SUM(t.resolved_at IS NOT NULL), 0) AS resolved_tickets,
       ROUND(100 * SUM(t.resolved_at IS NOT NULL AND t.resolved_at <= t.due_at)
             / NULLIF(SUM(t.resolved_at IS NOT NULL), 0), 1) AS sla_compliance_pct,
       ROUND(AVG(CASE WHEN t.resolved_at IS NOT NULL
                      THEN TIMESTAMPDIFF(MINUTE, t.created_at, t.resolved_at) END) / 60, 1) AS avg_resolution_hours,
       ROUND(AVG(f.rating), 2)               AS avg_rating
FROM agents a
INNER JOIN departments d        ON d.department_id = a.department_id
LEFT JOIN tickets t             ON t.current_agent_id = a.agent_id
LEFT JOIN customer_feedback f   ON f.ticket_id = t.ticket_id
GROUP BY a.agent_id, a.full_name, d.department_name;