-- File: 08_insert_status_history.sql
-- Purpose: Build the status timeline for every ticket

USE support_sla_db;

-- H1: every ticket starts as Open
INSERT INTO ticket_status_history (ticket_id, old_status, new_status, changed_at)
SELECT ticket_id, NULL, 'Open', created_at FROM tickets;

-- H2: Open -> In Progress when the first response was made
INSERT INTO ticket_status_history (ticket_id, old_status, new_status, changed_at)
SELECT ticket_id, 'Open', 'In Progress', first_response_at
FROM tickets WHERE first_response_at IS NOT NULL;

-- H3: resolved tickets that were never reopened
INSERT INTO ticket_status_history (ticket_id, old_status, new_status, changed_at)
SELECT ticket_id, 'In Progress', 'Resolved', resolved_at
FROM tickets WHERE resolved_at IS NOT NULL AND reopen_count = 0;

-- H4: resolved tickets that WERE reopened at least once
INSERT INTO ticket_status_history (ticket_id, old_status, new_status, changed_at)
SELECT ticket_id, 'In Progress', 'Resolved',
       DATE_ADD(first_response_at, INTERVAL FLOOR(TIMESTAMPDIFF(SECOND, first_response_at, resolved_at) * 0.2) SECOND)
FROM tickets WHERE resolved_at IS NOT NULL AND reopen_count >= 1;

INSERT INTO ticket_status_history (ticket_id, old_status, new_status, changed_at)
SELECT ticket_id, 'Resolved', 'Reopened',
       DATE_ADD(first_response_at, INTERVAL FLOOR(TIMESTAMPDIFF(SECOND, first_response_at, resolved_at) * 0.4) SECOND)
FROM tickets WHERE resolved_at IS NOT NULL AND reopen_count >= 1;

INSERT INTO ticket_status_history (ticket_id, old_status, new_status, changed_at)
SELECT ticket_id, 'Reopened', 'Resolved',
       DATE_ADD(first_response_at, INTERVAL FLOOR(TIMESTAMPDIFF(SECOND, first_response_at, resolved_at) * 0.6) SECOND)
FROM tickets WHERE resolved_at IS NOT NULL AND reopen_count = 2;

INSERT INTO ticket_status_history (ticket_id, old_status, new_status, changed_at)
SELECT ticket_id, 'Resolved', 'Reopened',
       DATE_ADD(first_response_at, INTERVAL FLOOR(TIMESTAMPDIFF(SECOND, first_response_at, resolved_at) * 0.8) SECOND)
FROM tickets WHERE resolved_at IS NOT NULL AND reopen_count = 2;

INSERT INTO ticket_status_history (ticket_id, old_status, new_status, changed_at)
SELECT ticket_id, 'Reopened', 'Resolved', resolved_at
FROM tickets WHERE resolved_at IS NOT NULL AND reopen_count >= 1;

-- H5: Closed tickets get a final Resolved -> Closed step 1-3 days later
INSERT INTO ticket_status_history (ticket_id, old_status, new_status, changed_at)
SELECT ticket_id, 'Resolved', 'Closed',
       LEAST(DATE_ADD(resolved_at, INTERVAL (24 + MOD(ticket_id, 48)) HOUR),
             CAST('2026-11-06 12:00:00' AS DATETIME))
FROM tickets WHERE status = 'Closed';

-- H6: tickets currently On Hold
INSERT INTO ticket_status_history (ticket_id, old_status, new_status, changed_at)
SELECT ticket_id, 'In Progress', 'On Hold', DATE_ADD(first_response_at, INTERVAL 2 HOUR)
FROM tickets WHERE status = 'On Hold';

-- H7: tickets currently Reopened (resolved earlier, then reopened)
INSERT INTO ticket_status_history (ticket_id, old_status, new_status, changed_at)
SELECT ticket_id, 'In Progress', 'Resolved', DATE_ADD(first_response_at, INTERVAL 12 HOUR)
FROM tickets WHERE status = 'Reopened';

INSERT INTO ticket_status_history (ticket_id, old_status, new_status, changed_at)
SELECT ticket_id, 'Resolved', 'Reopened', DATE_ADD(first_response_at, INTERVAL 36 HOUR)
FROM tickets WHERE status = 'Reopened';

INSERT INTO ticket_status_history (ticket_id, old_status, new_status, changed_at)
SELECT ticket_id, 'Reopened', 'Resolved', DATE_ADD(first_response_at, INTERVAL 48 HOUR)
FROM tickets WHERE status = 'Reopened' AND reopen_count = 2;

INSERT INTO ticket_status_history (ticket_id, old_status, new_status, changed_at)
SELECT ticket_id, 'Resolved', 'Reopened', DATE_ADD(first_response_at, INTERVAL 72 HOUR)
FROM tickets WHERE status = 'Reopened' AND reopen_count = 2;