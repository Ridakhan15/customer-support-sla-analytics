-- File: 14_window_functions.sql
-- Purpose: Window functions on the support database

USE support_sla_db;

-- W1: ROW_NUMBER with PARTITION BY: number each customer's tickets in order
SELECT customer_id, ticket_id, created_at,
       ROW_NUMBER() OVER (PARTITION BY customer_id
                          ORDER BY created_at, ticket_id) AS ticket_seq
FROM tickets
WHERE customer_id IN (1, 2)
ORDER BY customer_id, ticket_seq
LIMIT 15;

-- W2: ROW_NUMBER vs RANK vs DENSE_RANK: agents ranked within their department
WITH agent_stats AS (
    SELECT a.agent_id, a.full_name, d.department_name,
           COUNT(*) AS resolved_tickets,
           ROUND(100 * SUM(t.resolved_at <= t.due_at) / COUNT(*), -1) AS sla_pct_rounded
    FROM agents a
    INNER JOIN departments d ON d.department_id = a.department_id
    INNER JOIN tickets t     ON t.current_agent_id = a.agent_id
    WHERE t.resolved_at IS NOT NULL
    GROUP BY a.agent_id, a.full_name, d.department_name
)
SELECT department_name, full_name, resolved_tickets, sla_pct_rounded,
       ROW_NUMBER() OVER (PARTITION BY department_name ORDER BY sla_pct_rounded DESC) AS row_num,
       RANK()       OVER (PARTITION BY department_name ORDER BY sla_pct_rounded DESC) AS rnk,
       DENSE_RANK() OVER (PARTITION BY department_name ORDER BY sla_pct_rounded DESC) AS dense_rnk
FROM agent_stats
ORDER BY department_name, sla_pct_rounded DESC, full_name;

-- W3: top agent of each department by resolved tickets ("top N per group" pattern)
WITH agent_totals AS (
    SELECT a.agent_id, a.full_name, d.department_name,
           COUNT(*) AS resolved_tickets
    FROM agents a
    INNER JOIN departments d ON d.department_id = a.department_id
    INNER JOIN tickets t     ON t.current_agent_id = a.agent_id
    WHERE t.resolved_at IS NOT NULL
    GROUP BY a.agent_id, a.full_name, d.department_name
),
ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY department_name
                              ORDER BY resolved_tickets DESC) AS rn
    FROM agent_totals
)
SELECT department_name, full_name, resolved_tickets
FROM ranked
WHERE rn = 1
ORDER BY department_name;

-- W4: LAG: month-over-month ticket volume (Business Q9)
WITH monthly AS (
    SELECT DATE_FORMAT(created_at, '%Y-%m') AS ticket_month, COUNT(*) AS tickets
    FROM tickets
    GROUP BY DATE_FORMAT(created_at, '%Y-%m')
)
SELECT ticket_month, tickets,
       LAG(tickets) OVER (ORDER BY ticket_month) AS prev_month,
       tickets - LAG(tickets) OVER (ORDER BY ticket_month) AS diff,
       ROUND(100 * (tickets - LAG(tickets) OVER (ORDER BY ticket_month))
             / LAG(tickets) OVER (ORDER BY ticket_month), 1) AS pct_change
FROM monthly
ORDER BY ticket_month;

-- W5: running total and 3-month moving average
WITH monthly AS (
    SELECT DATE_FORMAT(created_at, '%Y-%m') AS ticket_month, COUNT(*) AS tickets
    FROM tickets
    GROUP BY DATE_FORMAT(created_at, '%Y-%m')
)
SELECT ticket_month, tickets,
       SUM(tickets) OVER (ORDER BY ticket_month) AS running_total,
       ROUND(AVG(tickets) OVER (ORDER BY ticket_month
                                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 1) AS moving_avg_3m
FROM monthly
ORDER BY ticket_month;

-- W6a: LAG and LEAD with a named window: the story of one customer
SELECT ticket_id, created_at,
       LAG(created_at)  OVER w AS prev_ticket_at,
       LEAD(created_at) OVER w AS next_ticket_at,
       TIMESTAMPDIFF(DAY, LAG(created_at) OVER w, created_at) AS days_since_prev
FROM tickets
WHERE customer_id = 1
WINDOW w AS (ORDER BY created_at, ticket_id)
ORDER BY created_at
LIMIT 8;

-- W6b: repeat contacts: tickets raised within 7 days of the same customer's previous ticket
WITH gaps AS (
    SELECT ticket_id, customer_id, created_at,
           LAG(created_at) OVER (PARTITION BY customer_id
                                 ORDER BY created_at, ticket_id) AS prev_ticket_at
    FROM tickets
)
SELECT COUNT(*) AS repeat_within_7_days
FROM gaps
WHERE prev_ticket_at IS NOT NULL
  AND TIMESTAMPDIFF(DAY, prev_ticket_at, created_at) <= 7;

-- W7: percentage of the grand total using SUM(COUNT(*)) OVER ()
SELECT c.category_name, COUNT(*) AS tickets,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_all
FROM tickets t
INNER JOIN ticket_categories c ON c.category_id = t.category_id
GROUP BY c.category_id, c.category_name
ORDER BY tickets DESC;