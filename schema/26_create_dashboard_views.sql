-- File: 26_create_dashboard_views.sql
-- Purpose: Flat, dashboard-ready views for Power BI

USE support_sla_db;

-- View 1: one row per ticket with 0/1 flags that are easy to sum in Power BI
CREATE OR REPLACE VIEW v_dash_tickets AS
SELECT d.ticket_id, d.priority, d.status,
       d.department_name, d.category_name, d.channel_name,
       d.agent_name, d.customer_city,
       d.created_at,
       DATE(d.created_at)                                AS created_date,
       DATE(DATE_FORMAT(d.created_at, '%Y-%m-01'))       AS created_month,
       d.due_at, d.resolved_at, d.resolution_hours,
       ROUND(TIMESTAMPDIFF(MINUTE, d.created_at, d.first_response_at) / 60, 2) AS first_response_hours,
       d.sla_result,
       CASE WHEN d.sla_result = 'Breached SLA' THEN 1 ELSE 0 END AS is_breached,
       CASE WHEN d.resolved_at IS NULL THEN 0 ELSE 1 END         AS is_resolved,
       CASE WHEN d.reopen_count > 0 THEN 1 ELSE 0 END            AS is_reopened,
       f.rating
FROM v_ticket_details d
LEFT JOIN customer_feedback f ON f.ticket_id = d.ticket_id;

-- View 2: monthly volume and backlog (same logic as query C6, without recursion)
CREATE OR REPLACE VIEW v_dash_monthly_backlog AS
SELECT m.month_start,
       (SELECT COUNT(*) FROM tickets t
        WHERE t.created_at >= m.month_start
          AND t.created_at <  DATE_ADD(m.month_start, INTERVAL 1 MONTH)) AS received,
       (SELECT COUNT(*) FROM tickets t
        WHERE t.resolved_at >= m.month_start
          AND t.resolved_at <  DATE_ADD(m.month_start, INTERVAL 1 MONTH)) AS resolved,
       (SELECT COUNT(*) FROM tickets t
        WHERE t.created_at < DATE_ADD(m.month_start, INTERVAL 1 MONTH)
          AND (t.resolved_at IS NULL
               OR t.resolved_at >= DATE_ADD(m.month_start, INTERVAL 1 MONTH))) AS backlog_at_month_end
FROM (SELECT DISTINCT DATE(DATE_FORMAT(created_at, '%Y-%m-01')) AS month_start
      FROM tickets) m;