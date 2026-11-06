-- File: 07_insert_assignments.sql
-- Purpose: Create assignment history, including reassignments

USE support_sla_db;

-- Part 1: tickets handled by one agent from the start
INSERT INTO ticket_assignments (ticket_id, agent_id, assigned_at, unassigned_at, reason)
SELECT t.ticket_id, t.current_agent_id,
       DATE_ADD(t.created_at, INTERVAL (5 + MOD(t.ticket_id * 7, 25)) MINUTE),
       NULL,
       'Initial assignment'
FROM tickets t
WHERE MOD(t.ticket_id, 8) <> 0;

-- Part 2: reassigned tickets, the FIRST (previous) agent, now unassigned
INSERT INTO ticket_assignments (ticket_id, agent_id, assigned_at, unassigned_at, reason)
SELECT t.ticket_id,
       6 + 5 * ((t.category_id - 1) DIV 3)
         + MOD(t.current_agent_id - (6 + 5 * ((t.category_id - 1) DIV 3)) + 1 + MOD(t.ticket_id, 4), 5),
       DATE_ADD(t.created_at, INTERVAL (5 + MOD(t.ticket_id * 7, 25)) MINUTE),
       DATE_ADD(t.created_at, INTERVAL FLOOR(TIMESTAMPDIFF(SECOND, t.created_at,
            COALESCE(t.resolved_at, CAST('2026-11-06 12:00:00' AS DATETIME))) * 0.4) SECOND),
       'Initial assignment'
FROM tickets t
WHERE MOD(t.ticket_id, 8) = 0;

-- Part 3: reassigned tickets, the SECOND (current) agent
INSERT INTO ticket_assignments (ticket_id, agent_id, assigned_at, unassigned_at, reason)
SELECT t.ticket_id, t.current_agent_id,
       DATE_ADD(t.created_at, INTERVAL FLOOR(TIMESTAMPDIFF(SECOND, t.created_at,
            COALESCE(t.resolved_at, CAST('2026-11-06 12:00:00' AS DATETIME))) * 0.4) SECOND),
       NULL,
       ELT(1 + MOD(t.ticket_id, 3), 'Workload balancing', 'Escalated to senior agent', 'Agent unavailable')
FROM tickets t
WHERE MOD(t.ticket_id, 8) = 0;