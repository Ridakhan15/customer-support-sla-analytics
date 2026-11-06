-- File: 12_aggregation_reports.sql
-- Purpose: Business reports using GROUP BY, HAVING and CASE WHEN

USE support_sla_db;

-- R1 (Business Q1): tickets received per month
SELECT DATE_FORMAT(created_at, '%Y-%m') AS ticket_month,
       COUNT(*) AS tickets_received
FROM tickets
GROUP BY DATE_FORMAT(created_at, '%Y-%m')
ORDER BY ticket_month;

-- R2 (Business Q4): average resolution time by priority, in hours
SELECT priority,
       COUNT(*) AS resolved_tickets,
       ROUND(AVG(TIMESTAMPDIFF(MINUTE, created_at, resolved_at)) / 60, 1) AS avg_hours,
       ROUND(MIN(TIMESTAMPDIFF(MINUTE, created_at, resolved_at)) / 60, 1) AS fastest_hours,
       ROUND(MAX(TIMESTAMPDIFF(MINUTE, created_at, resolved_at)) / 60, 1) AS slowest_hours
FROM tickets
WHERE resolved_at IS NOT NULL
GROUP BY priority
ORDER BY FIELD(priority, 'Critical', 'High', 'Medium', 'Low');

-- R3 (Business Q5): SLA compliance by priority
SELECT priority,
       COUNT(*) AS total_tickets,
       SUM(CASE WHEN resolved_at IS NOT NULL AND resolved_at <= due_at THEN 1 ELSE 0 END) AS met_sla,
       SUM(CASE WHEN (resolved_at IS NOT NULL AND resolved_at > due_at)
                  OR (resolved_at IS NULL AND '2026-11-06 12:00:00' > due_at)
                THEN 1 ELSE 0 END) AS breached_sla,
       SUM(CASE WHEN resolved_at IS NULL AND '2026-11-06 12:00:00' <= due_at THEN 1 ELSE 0 END) AS still_within_deadline,
       ROUND(100 * SUM(CASE WHEN (resolved_at IS NOT NULL AND resolved_at > due_at)
                              OR (resolved_at IS NULL AND '2026-11-06 12:00:00' > due_at)
                            THEN 1 ELSE 0 END) / COUNT(*), 1) AS breach_pct
FROM tickets
GROUP BY priority
ORDER BY FIELD(priority, 'Critical', 'High', 'Medium', 'Low');

-- R4 (Business Q7): what percentage of tickets are unresolved?
SELECT COUNT(*) AS total_tickets,
       SUM(resolved_at IS NULL) AS unresolved,
       ROUND(100 * SUM(resolved_at IS NULL) / COUNT(*), 1) AS pct_unresolved
FROM tickets;

-- R5 (Business Q6): customers who raise the most complaints (HAVING)
SELECT c.customer_id, c.full_name, c.city, COUNT(*) AS tickets_raised
FROM customers c
INNER JOIN tickets t ON t.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name, c.city
HAVING COUNT(*) >= 20
ORDER BY tickets_raised DESC
LIMIT 10;

-- R6 (Business Q10): complaint volume by category
SELECT cat.category_name, d.department_name,
       COUNT(*) AS tickets,
       ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM tickets), 1) AS pct_of_all
FROM tickets t
INNER JOIN ticket_categories cat ON cat.category_id   = t.category_id
INNER JOIN departments d         ON d.department_id   = cat.department_id
GROUP BY cat.category_id, cat.category_name, d.department_name
ORDER BY tickets DESC;

--