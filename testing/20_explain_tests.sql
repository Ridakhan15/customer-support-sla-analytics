-- File: 20_explain_tests.sql
USE support_sla_db;

-- E1: tickets created in October 2026 (date range)
EXPLAIN SELECT ticket_id, subject, created_at
FROM tickets
WHERE created_at >= '2026-10-01' AND created_at < '2026-11-01';

-- E2: next 10 in-progress tickets due soonest (filter + sort)
EXPLAIN SELECT ticket_id, subject, due_at
FROM tickets
WHERE status = 'In Progress'
ORDER BY due_at
LIMIT 10;

-- E3: function wrapped around the column (a classic mistake)
EXPLAIN SELECT ticket_id, subject
FROM tickets
WHERE DATE(created_at) = '2026-10-15';

-- E3b: the same question written so an index can be used
EXPLAIN SELECT ticket_id, subject
FROM tickets
WHERE created_at >= '2026-10-15' AND created_at < '2026-10-16';

-- E4: unresolved tickets
EXPLAIN SELECT ticket_id, subject, status
FROM tickets
WHERE resolved_at IS NULL;

-- E5: a join on a foreign key column
EXPLAIN SELECT a.full_name, COUNT(*) AS tickets
FROM agents a
INNER JOIN tickets t ON t.current_agent_id = a.agent_id
WHERE a.agent_id = 7
GROUP BY a.full_name;