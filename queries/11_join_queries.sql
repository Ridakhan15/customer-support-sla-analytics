-- File: 11_join_queries.sql
-- Purpose: JOIN practice on the support database

USE support_sla_db;

-- J1. INNER JOIN across 4 tables: ticket, customer, agent, department
SELECT t.ticket_id, c.full_name AS customer, a.full_name AS agent,
       d.department_name, t.priority, t.status
FROM tickets t
INNER JOIN customers   c ON c.customer_id   = t.customer_id
INNER JOIN agents      a ON a.agent_id      = t.current_agent_id
INNER JOIN departments d ON d.department_id = a.department_id
ORDER BY t.ticket_id
LIMIT 10;

-- J1b. CHECK: the same join with no LIMIT must still return all 5,000 tickets
SELECT COUNT(*) AS joined_rows
FROM tickets t
INNER JOIN customers   c ON c.customer_id   = t.customer_id
INNER JOIN agents      a ON a.agent_id      = t.current_agent_id
INNER JOIN departments d ON d.department_id = a.department_id;

-- J1c. CHECK: an agent's department must match the ticket category's department
SELECT COUNT(*) AS department_mismatches
FROM tickets t
INNER JOIN agents a            ON a.agent_id    = t.current_agent_id
INNER JOIN ticket_categories c ON c.category_id = t.category_id
WHERE a.department_id <> c.department_id;

-- J2. LEFT JOIN: customers who have NEVER raised a ticket
SELECT c.customer_id, c.full_name, c.email
FROM customers c
LEFT JOIN tickets t ON t.customer_id = c.customer_id
WHERE t.ticket_id IS NULL;

-- J3. RIGHT JOIN: agents with no tickets (the same idea, written from the other side)
SELECT a.agent_id, a.full_name, a.manager_id, COUNT(t.ticket_id) AS tickets_handled
FROM tickets t
RIGHT JOIN agents a ON a.agent_id = t.current_agent_id
GROUP BY a.agent_id, a.full_name, a.manager_id
HAVING COUNT(t.ticket_id) = 0;

-- J4. SELF JOIN: each agent next to their manager
SELECT a.agent_id, a.full_name AS agent, m.full_name AS manager
FROM agents a
INNER JOIN agents m ON m.agent_id = a.manager_id
ORDER BY m.agent_id, a.agent_id
LIMIT 10;

-- J5. Business Q2: which department receives the most tickets?
SELECT d.department_name, COUNT(*) AS total_tickets
FROM tickets t
INNER JOIN ticket_categories c ON c.category_id   = t.category_id
INNER JOIN departments d       ON d.department_id = c.department_id
GROUP BY d.department_name
ORDER BY total_tickets DESC;

-- J6. Business Q15: which support channel brings in the most tickets?
SELECT ch.channel_name, COUNT(*) AS total_tickets,
       ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM tickets), 1) AS pct_of_all
FROM tickets t
INNER JOIN support_channels ch ON ch.channel_id = t.channel_id
GROUP BY ch.channel_name
ORDER BY total_tickets DESC;

-- J7. Business Q3: agents ranked by number of resolved tickets
SELECT a.agent_id, a.full_name, d.department_name,
       COUNT(t.ticket_id) AS resolved_tickets
FROM agents a
INNER JOIN departments d ON d.department_id = a.department_id
LEFT JOIN tickets t ON t.current_agent_id = a.agent_id
                   AND t.resolved_at IS NOT NULL
GROUP BY a.agent_id, a.full_name, d.department_name
ORDER BY resolved_tickets DESC, a.agent_id
LIMIT 10;