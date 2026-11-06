-- File: 23_validation_checks.sql
-- Purpose: 32 automated checks. Every row should show PASS.

USE support_sla_db;

SELECT check_name, actual_value, lo AS expected_min, hi AS expected_max,
       IF(actual_value BETWEEN lo AND hi, 'PASS', 'FAIL') AS result
FROM (
    -- ---- Row counts ----
    SELECT 'V01 departments' AS check_name, (SELECT COUNT(*) FROM departments) AS actual_value, 5 AS lo, 5 AS hi
    UNION ALL SELECT 'V02 support_channels', (SELECT COUNT(*) FROM support_channels), 6, 6
    UNION ALL SELECT 'V03 ticket_categories', (SELECT COUNT(*) FROM ticket_categories), 15, 15
    UNION ALL SELECT 'V04 sla_policies', (SELECT COUNT(*) FROM sla_policies), 4, 4
    UNION ALL SELECT 'V05 agents', (SELECT COUNT(*) FROM agents), 30, 30
    UNION ALL SELECT 'V06 managers (no manager_id)', (SELECT COUNT(*) FROM agents WHERE manager_id IS NULL), 5, 5
    UNION ALL SELECT 'V07 customers', (SELECT COUNT(*) FROM customers), 600, 600
    UNION ALL SELECT 'V08 tickets', (SELECT COUNT(*) FROM tickets), 5000, 5000
    UNION ALL SELECT 'V09 ticket_assignments', (SELECT COUNT(*) FROM ticket_assignments), 5625, 5625

    -- ---- Ticket data rules ----
    UNION ALL SELECT 'V10 due_at or priority disagrees with SLA policy',
        (SELECT COUNT(*) FROM tickets t
         INNER JOIN sla_policies p ON p.sla_id = t.sla_id
         WHERE t.priority <> p.priority
            OR t.due_at <> DATE_ADD(t.created_at, INTERVAL p.resolution_hours HOUR)), 0, 0
    UNION ALL SELECT 'V11 resolved before created',
        (SELECT COUNT(*) FROM tickets WHERE resolved_at < created_at), 0, 0
    UNION ALL SELECT 'V12 status disagrees with resolved_at',
        (SELECT COUNT(*) FROM tickets
         WHERE (resolved_at IS NOT NULL AND status NOT IN ('Resolved', 'Closed'))
            OR (resolved_at IS NULL AND status IN ('Resolved', 'Closed'))), 0, 0
    UNION ALL SELECT 'V13 first response out of order',
        (SELECT COUNT(*) FROM tickets
         WHERE first_response_at < created_at
            OR (resolved_at IS NOT NULL AND first_response_at > resolved_at)), 0, 0
    UNION ALL SELECT 'V14 first response vs Open status',
        (SELECT COUNT(*) FROM tickets
         WHERE (status = 'Open' AND first_response_at IS NOT NULL)
            OR (status <> 'Open' AND first_response_at IS NULL)), 0, 0
    UNION ALL SELECT 'V15 agent department <> category department',
        (SELECT COUNT(*) FROM tickets t
         INNER JOIN agents a            ON a.agent_id    = t.current_agent_id
         INNER JOIN ticket_categories c ON c.category_id = t.category_id
         WHERE a.department_id <> c.department_id), 0, 0
    UNION ALL SELECT 'V16 ticket created before customer registered',
        (SELECT COUNT(*) FROM tickets t
         INNER JOIN customers c ON c.customer_id = t.customer_id
         WHERE t.created_at < c.registered_date), 0, 0
    UNION ALL SELECT 'V17 ticket created before agent was hired',
        (SELECT COUNT(*) FROM tickets t
         INNER JOIN agents a ON a.agent_id = t.current_agent_id
         WHERE t.created_at < a.hire_date), 0, 0

    -- ---- Assignment and history integrity ----
    UNION ALL SELECT 'V18 tickets without exactly one open assignment',
        (SELECT COUNT(*) FROM (
            SELECT t.ticket_id
            FROM tickets t
            LEFT JOIN ticket_assignments a ON a.ticket_id = t.ticket_id AND a.unassigned_at IS NULL
            GROUP BY t.ticket_id
            HAVING COUNT(a.assignment_id) <> 1) x), 0, 0
    UNION ALL SELECT 'V19 open assignment agent <> current agent',
        (SELECT COUNT(*) FROM tickets t
         INNER JOIN ticket_assignments a ON a.ticket_id = t.ticket_id AND a.unassigned_at IS NULL
         WHERE a.agent_id <> t.current_agent_id), 0, 0
    UNION ALL SELECT 'V20 latest history status <> ticket status',
        (SELECT COUNT(*) FROM tickets t
         INNER JOIN (SELECT ticket_id, new_status,
                            ROW_NUMBER() OVER (PARTITION BY ticket_id
                                               ORDER BY changed_at DESC, history_id DESC) AS rn
                     FROM ticket_status_history) l
                 ON l.ticket_id = t.ticket_id AND l.rn = 1
         WHERE l.new_status <> t.status), 0, 0
    UNION ALL SELECT 'V21 history dated in the future',
        (SELECT COUNT(*) FROM ticket_status_history WHERE changed_at > NOW()), 0, 0

    -- ---- Feedback ----
    UNION ALL SELECT 'V22 feedback on unresolved ticket or before resolution',
        (SELECT COUNT(*) FROM customer_feedback f
         INNER JOIN tickets t ON t.ticket_id = f.ticket_id
         WHERE t.resolved_at IS NULL OR f.submitted_at < t.resolved_at), 0, 0
    UNION ALL SELECT 'V23 feedback rows (plausible range)',
        (SELECT COUNT(*) FROM customer_feedback), 2400, 3200
    UNION ALL SELECT 'V24 reopened tickets (plausible range)',
        (SELECT COUNT(*) FROM tickets WHERE reopen_count > 0), 300, 450

    -- ---- Views must agree with the base tables ----
    UNION ALL SELECT 'V25 v_ticket_details rows',
        (SELECT COUNT(*) FROM v_ticket_details), 5000, 5000
    UNION ALL SELECT 'V26 view shows tickets "within deadline"',
        (SELECT COUNT(*) FROM v_ticket_details WHERE sla_result = 'Open - within deadline'), 0, 0
    UNION ALL SELECT 'V27 breached: view minus direct count',
        ABS((SELECT COUNT(*) FROM v_ticket_details WHERE sla_result = 'Breached SLA')
          - (SELECT COUNT(*) FROM tickets
             WHERE resolved_at > due_at OR (resolved_at IS NULL AND NOW() > due_at))), 0, 0
    UNION ALL SELECT 'V28 v_agent_performance total tickets',
        (SELECT SUM(total_tickets) FROM v_agent_performance), 5000, 5000

    -- ---- Database objects ----
    UNION ALL SELECT 'V29 triggers',
        (SELECT COUNT(*) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA = 'support_sla_db'), 3, 3
    UNION ALL SELECT 'V30 stored procedures',
        (SELECT COUNT(*) FROM information_schema.ROUTINES
         WHERE ROUTINE_SCHEMA = 'support_sla_db' AND ROUTINE_TYPE = 'PROCEDURE'), 3, 3
    UNION ALL SELECT 'V31 views',
        (SELECT COUNT(*) FROM information_schema.VIEWS WHERE TABLE_SCHEMA = 'support_sla_db'), 3, 3
    UNION ALL SELECT 'V32 custom indexes on tickets',
        (SELECT COUNT(DISTINCT INDEX_NAME) FROM information_schema.STATISTICS
         WHERE TABLE_SCHEMA = 'support_sla_db' AND TABLE_NAME = 'tickets'
           AND INDEX_NAME LIKE 'idx%'), 3, 3
) checks
ORDER BY check_name;