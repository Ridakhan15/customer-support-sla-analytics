-- File: 19_procedure_tests.sql
USE support_sla_db;

-- ===== TEST A: create a ticket (Billing category 1, High priority, customer 1) =====
CALL sp_create_ticket(1, 3, 1, 'High', 'TEST - procedure check', @new_tid);
SELECT @new_tid AS new_ticket_id;
SELECT ticket_id, current_agent_id, status, priority, created_at, due_at,
       TIMESTAMPDIFF(HOUR, created_at, due_at) AS sla_hours
FROM tickets WHERE ticket_id = @new_tid;
SELECT old_status, new_status FROM ticket_status_history WHERE ticket_id = @new_tid;
SELECT agent_id, reason, unassigned_at FROM ticket_assignments WHERE ticket_id = @new_tid;

-- ===== TEST B: reassign it to another Billing agent =====
SET @cur   = (SELECT current_agent_id FROM tickets WHERE ticket_id = @new_tid);
SET @other = IF(@cur = 6, 7, 6);
CALL sp_reassign_ticket(@new_tid, @other);
SELECT ticket_id, current_agent_id FROM tickets WHERE ticket_id = @new_tid;
SELECT assignment_id, agent_id, unassigned_at, reason
FROM ticket_assignments WHERE ticket_id = @new_tid ORDER BY assignment_id;

-- ===== TEST C1 (must FAIL): agent 11 is in Technical Support, not Billing =====
CALL sp_reassign_ticket(@new_tid, 11);

-- ===== TEST C2 (must FAIL): already assigned to this agent =====
CALL sp_reassign_ticket(@new_tid, @other);

-- ===== TEST C3 (must FAIL): invalid priority =====
CALL sp_create_ticket(1, 3, 1, 'Urgent', 'TEST - bad priority', @x);

-- ===== TEST C4 (must FAIL): customer 99999 does not exist, so nothing may be saved =====
CALL sp_create_ticket(99999, 3, 1, 'Low', 'TEST - bad customer', @x);
SELECT COUNT(*) AS bad_tickets_saved FROM tickets WHERE subject LIKE 'TEST - bad%';

-- ===== TEST D: department SLA report for Q1 2026 =====
CALL sp_sla_report_by_department('2026-01-01', '2026-03-31');
SELECT COUNT(*) AS q1_2026_tickets FROM tickets
WHERE created_at >= '2026-01-01' AND created_at < '2026-04-01';

-- ===== TEST E (must FAIL): start date after end date =====
CALL sp_sla_report_by_department('2026-05-01', '2026-01-01');

-- ===== CLEANUP: remove the test ticket (children first) =====
SET @new_tid = (SELECT MAX(ticket_id) FROM tickets WHERE subject LIKE 'TEST - procedure%');
DELETE FROM ticket_status_history WHERE ticket_id = @new_tid;
DELETE FROM ticket_assignments    WHERE ticket_id = @new_tid;
DELETE FROM tickets               WHERE ticket_id = @new_tid;

SELECT COUNT(*) AS tickets FROM tickets;
SELECT COUNT(*) AS assignments, SUM(unassigned_at IS NULL) AS open_assignments FROM ticket_assignments;