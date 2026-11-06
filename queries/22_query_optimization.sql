USE support_sla_db;

-- Original: correlated subquery
SELECT t.priority, COUNT(*) AS slower_than_own_priority_avg
FROM tickets t
WHERE t.resolved_at IS NOT NULL
  AND TIMESTAMPDIFF(MINUTE, t.created_at, t.resolved_at) >
      (SELECT AVG(TIMESTAMPDIFF(MINUTE, t2.created_at, t2.resolved_at))
       FROM tickets t2
       WHERE t2.priority = t.priority AND t2.resolved_at IS NOT NULL)
GROUP BY t.priority
ORDER BY FIELD(t.priority, 'Critical', 'High', 'Medium', 'Low');

-- Rewrite: compute each priority's average ONCE, then join
SELECT t.priority, COUNT(*) AS slower_than_own_priority_avg
FROM tickets t
INNER JOIN (
    SELECT priority, AVG(TIMESTAMPDIFF(MINUTE, created_at, resolved_at)) AS avg_minutes
    FROM tickets
    WHERE resolved_at IS NOT NULL
    GROUP BY priority
) a ON a.priority = t.priority
WHERE t.resolved_at IS NOT NULL
  AND TIMESTAMPDIFF(MINUTE, t.created_at, t.resolved_at) > a.avg_minutes
GROUP BY t.priority
ORDER BY FIELD(t.priority, 'Critical', 'High', 'Medium', 'Low');

-- Compare the plans
EXPLAIN SELECT t.priority, COUNT(*)
FROM tickets t
WHERE t.resolved_at IS NOT NULL
  AND TIMESTAMPDIFF(MINUTE, t.created_at, t.resolved_at) >
      (SELECT AVG(TIMESTAMPDIFF(MINUTE, t2.created_at, t2.resolved_at))
       FROM tickets t2
       WHERE t2.priority = t.priority AND t2.resolved_at IS NOT NULL)
GROUP BY t.priority;

EXPLAIN SELECT t.priority, COUNT(*)
FROM tickets t
INNER JOIN (
    SELECT priority, AVG(TIMESTAMPDIFF(MINUTE, created_at, resolved_at)) AS avg_minutes
    FROM tickets WHERE resolved_at IS NOT NULL GROUP BY priority
) a ON a.priority = t.priority
WHERE t.resolved_at IS NOT NULL
  AND TIMESTAMPDIFF(MINUTE, t.created_at, t.resolved_at) > a.avg_minutes
GROUP BY t.priority;