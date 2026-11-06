-- File: 13_subqueries_and_ctes.sql
-- Purpose: Subqueries, correlated subqueries and CTEs on the support database

USE support_sla_db;

-- C1 (Business Q8): agents whose average resolution time is above the company average
SELECT a.agent_id, a.full_name,
       COUNT(*) AS resolved_tickets,
       ROUND(AVG(TIMESTAMPDIFF(MINUTE, t.created_at, t.resolved_at)) / 60, 1) AS avg_hours
FROM agents a
INNER JOIN tickets t ON t.current_agent_id = a.agent_id
WHERE t.resolved_at IS NOT NULL
GROUP BY a.agent_id, a.full_name
HAVING AVG(TIMESTAMPDIFF(MINUTE, t.created_at, t.resolved_at)) >
       (SELECT AVG(TIMESTAMPDIFF(MINUTE, created_at, resolved_at))
        FROM tickets
        WHERE resolved_at IS NOT NULL)
ORDER BY avg_hours DESC;

-- C2: how many customers have given at least one 1-star rating? (IN subquery)
SELECT COUNT(*) AS customers_with_1_star
FROM customers
WHERE customer_id IN (SELECT t.customer_id
                      FROM tickets t
                      INNER JOIN customer_feedback f ON f.ticket_id = t.ticket_id
                      WHERE f.rating = 1);

-- C3: each customer's most recent ticket (correlated subquery)
SELECT t.customer_id, t.ticket_id, t.subject, t.created_at
FROM tickets t
WHERE t.created_at = (SELECT MAX(t2.created_at)
                      FROM tickets t2
                      WHERE t2.customer_id = t.customer_id)
ORDER BY t.created_at DESC
LIMIT 10;

-- C3b. CHECK: one row per customer who has any ticket
SELECT COUNT(*) AS latest_ticket_rows
FROM tickets t
WHERE t.created_at = (SELECT MAX(t2.created_at)
                      FROM tickets t2
                      WHERE t2.customer_id = t.customer_id);

-- C4: tickets slower than the average of THEIR OWN priority (correlated subquery)
SELECT t.priority, COUNT(*) AS slower_than_own_priority_avg
FROM tickets t
WHERE t.resolved_at IS NOT NULL
  AND TIMESTAMPDIFF(MINUTE, t.created_at, t.resolved_at) >
      (SELECT AVG(TIMESTAMPDIFF(MINUTE, t2.created_at, t2.resolved_at))
       FROM tickets t2
       WHERE t2.priority = t.priority
         AND t2.resolved_at IS NOT NULL)
GROUP BY t.priority
ORDER BY FIELD(t.priority, 'Critical', 'High', 'Medium', 'Low');

-- C5 (Business Q3 and Q12): agent scorecard using two chained CTEs
WITH agent_tickets AS (
    SELECT current_agent_id AS agent_id,
           COUNT(*) AS total_tickets,
           SUM(resolved_at IS NOT NULL) AS resolved_tickets,
           SUM(CASE WHEN resolved_at IS NOT NULL AND resolved_at <= due_at THEN 1 ELSE 0 END) AS met_sla,
           ROUND(AVG(CASE WHEN resolved_at IS NOT NULL
                          THEN TIMESTAMPDIFF(MINUTE, created_at, resolved_at) END) / 60, 1) AS avg_resolution_hours
    FROM tickets
    GROUP BY current_agent_id
),
agent_ratings AS (
    SELECT t.current_agent_id AS agent_id, ROUND(AVG(f.rating), 2) AS avg_rating
    FROM customer_feedback f
    INNER JOIN tickets t ON t.ticket_id = f.ticket_id
    GROUP BY t.current_agent_id
)
SELECT a.agent_id, a.full_name, d.department_name,
       tk.total_tickets, tk.resolved_tickets,
       ROUND(100 * tk.met_sla / tk.resolved_tickets, 1) AS sla_compliance_pct,
       tk.avg_resolution_hours, rt.avg_rating
FROM agent_tickets tk
INNER JOIN agents a       ON a.agent_id = tk.agent_id
INNER JOIN departments d  ON d.department_id = a.department_id
LEFT JOIN agent_ratings rt ON rt.agent_id = tk.agent_id
ORDER BY sla_compliance_pct DESC, tk.resolved_tickets DESC;

-- C6 (Business Q14): monthly backlog trend (recursive CTE builds the month list)
WITH RECURSIVE months AS (
    SELECT DATE('2025-01-01') AS month_start
    UNION ALL
    SELECT DATE_ADD(month_start, INTERVAL 1 MONTH)
    FROM months
    WHERE month_start < '2026-10-01'
),
bounds AS (
    SELECT month_start, DATE_ADD(month_start, INTERVAL 1 MONTH) AS next_month_start
    FROM months
)
SELECT DATE_FORMAT(b.month_start, '%Y-%m') AS month,
       (SELECT COUNT(*) FROM tickets t
        WHERE t.created_at >= b.month_start AND t.created_at < b.next_month_start) AS received,
       (SELECT COUNT(*) FROM tickets t
        WHERE t.resolved_at >= b.month_start AND t.resolved_at < b.next_month_start) AS resolved,
       (SELECT COUNT(*) FROM tickets t
        WHERE t.created_at < b.next_month_start
          AND (t.resolved_at IS NULL OR t.resolved_at >= b.next_month_start)) AS backlog_at_month_end
FROM bounds b
ORDER BY b.month_start;

-- C7: reporting hierarchy using a recursive CTE
WITH RECURSIVE org AS (
    SELECT agent_id, full_name, manager_id, 1 AS level,
           CAST(full_name AS CHAR(200)) AS reporting_path
    FROM agents
    WHERE manager_id IS NULL
    UNION ALL
    SELECT a.agent_id, a.full_name, a.manager_id, o.level + 1,
           CONCAT(o.reporting_path, ' > ', a.full_name)
    FROM agents a
    INNER JOIN org o ON a.manager_id = o.agent_id
)
SELECT level, agent_id, full_name, reporting_path
FROM org
ORDER BY reporting_path;