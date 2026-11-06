-- File: 16_create_triggers.sql
-- Purpose: Automatic status history, assignment tracking and ticket rules

USE support_sla_db;

DROP TRIGGER IF EXISTS trg_tickets_before_update;
DROP TRIGGER IF EXISTS trg_tickets_after_update;
DROP TRIGGER IF EXISTS trg_tickets_after_insert;

DELIMITER $$

-- BEFORE UPDATE: validate the change and fill in dates automatically
CREATE TRIGGER trg_tickets_before_update
BEFORE UPDATE ON tickets
FOR EACH ROW
BEGIN
    IF NOT (OLD.status <=> NEW.status) THEN

        IF OLD.status = 'Closed' AND NEW.status NOT IN ('Closed', 'Reopened') THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'A closed ticket can only be reopened';
        END IF;

        IF NEW.status IN ('In Progress', 'Resolved', 'Closed')
           AND NEW.first_response_at IS NULL THEN
            SET NEW.first_response_at = NOW();
        END IF;

        IF NEW.status IN ('Resolved', 'Closed') AND NEW.resolved_at IS NULL THEN
            SET NEW.resolved_at = NOW();
        END IF;

        IF NEW.status = 'Reopened' AND OLD.status IN ('Resolved', 'Closed') THEN
            SET NEW.reopen_count = OLD.reopen_count + 1;
            SET NEW.resolved_at = NULL;
        END IF;

    END IF;
END$$

-- AFTER UPDATE: write the audit rows
CREATE TRIGGER trg_tickets_after_update
AFTER UPDATE ON tickets
FOR EACH ROW
BEGIN
    IF NOT (OLD.status <=> NEW.status) THEN
        INSERT INTO ticket_status_history (ticket_id, old_status, new_status, changed_at)
        VALUES (NEW.ticket_id, OLD.status, NEW.status, NOW());
    END IF;

    IF NOT (OLD.current_agent_id <=> NEW.current_agent_id) THEN
        UPDATE ticket_assignments
        SET unassigned_at = NOW()
        WHERE ticket_id = NEW.ticket_id AND unassigned_at IS NULL;

        IF NEW.current_agent_id IS NOT NULL THEN
            INSERT INTO ticket_assignments (ticket_id, agent_id, assigned_at, unassigned_at, reason)
            VALUES (NEW.ticket_id, NEW.current_agent_id, NOW(), NULL, 'Reassigned');
        END IF;
    END IF;
END$$

-- AFTER INSERT: first history row and first assignment for a new ticket
CREATE TRIGGER trg_tickets_after_insert
AFTER INSERT ON tickets
FOR EACH ROW
BEGIN
    INSERT INTO ticket_status_history (ticket_id, old_status, new_status, changed_at)
    VALUES (NEW.ticket_id, NULL, NEW.status, NEW.created_at);

    IF NEW.current_agent_id IS NOT NULL THEN
        INSERT INTO ticket_assignments (ticket_id, agent_id, assigned_at, unassigned_at, reason)
        VALUES (NEW.ticket_id, NEW.current_agent_id, NEW.created_at, NULL, 'Initial assignment');
    END IF;
END$$

DELIMITER ;