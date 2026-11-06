-- File: 17_trigger_tests.sql
USE support_sla_db;

-- ===== TEST 1: status change is logged and resolved_at is filled =====
SET @tid = (SELECT MIN(ticket_id) FROM tickets WHERE status = 'In Progress');

SELECT ticket_id, status, resolved_at, reopen_count FROM tickets WHERE ticket_id = @tid;
SELECT COUNT(*) AS history_before FROM ticket_status_history WHERE ticket_id = @tid;

START TRANSACTION;
UPDATE tickets SET status = 'Resolved' WHERE ticket_id = @tid;
SELECT ticket_id, status, resolved_at, reopen_count FROM tickets WHERE ticket_id = @tid;
SELECT history_id, old_status, new_status, changed_at
FROM ticket_status_history WHERE ticket_id = @tid ORDER BY history_id DESC LIMIT 1;
ROLLBACK;

SELECT ticket_id, status, resolved_at FROM tickets WHERE ticket_id = @tid;
SELECT COUNT(*) AS history_after_rollback FROM ticket_status_history WHERE ticket_id = @tid;

-- ===== TEST 2: reopening clears resolved_at and adds to reopen_count =====
SET @tid = (SELECT MIN(ticket_id) FROM tickets WHERE status = 'Resolved' AND reopen_count = 0);

SELECT ticket_id, status, resolved_at, reopen_count FROM tickets WHERE ticket_id = @tid;

START TRANSACTION;
UPDATE tickets SET status = 'Reopened' WHERE ticket_id = @tid;
SELECT ticket_id, status, resolved_at, reopen_count FROM tickets WHERE ticket_id = @tid;
SELECT old_status, new_status FROM ticket_status_history
WHERE ticket_id = @tid ORDER BY history_id DESC LIMIT 1;
ROLLBACK;

SELECT ticket_id, status, resolved_at, reopen_count FROM tickets WHERE ticket_id = @tid;

-- ===== TEST 3: reassignment closes the old assignment and opens a new one =====
SET @tid = (SELECT MIN(ticket_id) FROM tickets WHERE status = 'In Progress' AND category_id = 1);
SET @old_agent = (SELECT current_agent_id FROM tickets WHERE ticket_id = @tid);
SET @new_agent = IF(@old_agent = 6, 7, 6);

SELECT @tid AS ticket, @old_agent AS old_agent, @new_agent AS new_agent;
SELECT assignment_id, agent_id, unassigned_at, reason
FROM ticket_assignments WHERE ticket_id = @tid ORDER BY assignment_id;

START TRANSACTION;
UPDATE tickets SET current_agent_id = @new_agent WHERE ticket_id = @tid;
SELECT assignment_id, agent_id, unassigned_at, reason
FROM ticket_assignments WHERE ticket_id = @tid ORDER BY assignment_id;
ROLLBACK;

SELECT assignment_id, agent_id, unassigned_at, reason
FROM ticket_assignments WHERE ticket_id = @tid ORDER BY assignment_id;

-- ===== TEST 4: a brand-new ticket gets its first history row and assignment =====
START TRANSACTION;
INSERT INTO tickets (customer_id, channel_id, category_id, sla_id, current_agent_id,
                     subject, priority, status, created_at, due_at)
VALUES (1, 3, 1, 3, 6, 'TEST - trigger check', 'High', 'Open',
        NOW(), DATE_ADD(NOW(), INTERVAL 24 HOUR));
SET @new_tid = LAST_INSERT_ID();
SELECT old_status, new_status FROM ticket_status_history WHERE ticket_id = @new_tid;
SELECT agent_id, reason, unassigned_at FROM ticket_assignments WHERE ticket_id = @new_tid;
ROLLBACK;

SELECT COUNT(*) AS test_ticket_rows_left FROM tickets WHERE ticket_id = @new_tid;

-- ===== TEST 5: a closed ticket cannot go back to In Progress (this MUST fail) =====
SET @tid = (SELECT MIN(ticket_id) FROM tickets WHERE status = 'Closed');
UPDATE tickets SET status = 'In Progress' WHERE ticket_id = @tid;

-- ===== TEST 6: nothing was changed by the tests =====
SELECT COUNT(*) AS tickets FROM tickets;
SELECT COUNT(*) AS assignments, SUM(unassigned_at IS NULL) AS open_assignments FROM ticket_assignments;