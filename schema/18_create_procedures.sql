-- File: 18_create_procedures.sql
-- Purpose: Stored procedures for ticket creation, reassignment and SLA reporting

USE support_sla_db;

DROP PROCEDURE IF EXISTS sp_create_ticket;
DROP PROCEDURE IF EXISTS sp_reassign_ticket;
DROP PROCEDURE IF EXISTS sp_sla_report_by_department;

DELIMITER $$

-- 1. Create a ticket: SLA lookup, least-busy agent, due date, all in one transaction
CREATE PROCEDURE sp_create_ticket(
    IN  p_customer_id INT UNSIGNED,
    IN  p_channel_id  INT UNSIGNED,
    IN  p_category_id INT UNSIGNED,
    IN  p_priority    VARCHAR(10),
    IN  p_subject     VARCHAR(200),
    OUT p_ticket_id   INT UNSIGNED
)
BEGIN
    DECLARE v_sla_id INT UNSIGNED DEFAULT NULL;
    DECLARE v_hours  SMALLINT UNSIGNED DEFAULT NULL;
    DECLARE v_agent  INT UNSIGNED DEFAULT NULL;
    DECLARE v_now    DATETIME;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT sla_id, resolution_hours INTO v_sla_id, v_hours
    FROM sla_policies
    WHERE priority = p_priority;

    IF v_sla_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid priority. Use Low, Medium, High or Critical';
    END IF;

    SELECT a.agent_id INTO v_agent
    FROM agents a
    INNER JOIN ticket_categories c ON c.department_id = a.department_id
                                  AND c.category_id   = p_category_id
    LEFT JOIN tickets t ON t.current_agent_id = a.agent_id
                       AND t.status IN ('Open', 'In Progress', 'On Hold', 'Reopened')
    WHERE a.is_active = 1
      AND a.manager_id IS NOT NULL
    GROUP BY a.agent_id
    ORDER BY COUNT(t.ticket_id), a.agent_id
    LIMIT 1;

    IF v_agent IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No active agent found for this category';
    END IF;

    SET v_now = NOW();

    START TRANSACTION;

    INSERT INTO tickets (customer_id, channel_id, category_id, sla_id, current_agent_id,
                         subject, priority, status, created_at, due_at)
    VALUES (p_customer_id, p_channel_id, p_category_id, v_sla_id, v_agent,
            p_subject, p_priority, 'Open', v_now, DATE_ADD(v_now, INTERVAL v_hours HOUR));

    SET p_ticket_id = LAST_INSERT_ID();

    COMMIT;
END$$

-- 2. Reassign a ticket with validation (the trigger logs the assignment change)
CREATE PROCEDURE sp_reassign_ticket(
    IN p_ticket_id    INT UNSIGNED,
    IN p_new_agent_id INT UNSIGNED
)
BEGIN
    DECLARE v_status        VARCHAR(20)  DEFAULT NULL;
    DECLARE v_current_agent INT UNSIGNED DEFAULT NULL;
    DECLARE v_ticket_dept   INT UNSIGNED DEFAULT NULL;
    DECLARE v_new_dept      INT UNSIGNED DEFAULT NULL;
    DECLARE v_new_active    TINYINT      DEFAULT NULL;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT t.status, t.current_agent_id, c.department_id
    INTO v_status, v_current_agent, v_ticket_dept
    FROM tickets t
    INNER JOIN ticket_categories c ON c.category_id = t.category_id
    WHERE t.ticket_id = p_ticket_id;

    SELECT department_id, is_active INTO v_new_dept, v_new_active
    FROM agents
    WHERE agent_id = p_new_agent_id;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket not found';
    ELSEIF v_status IN ('Resolved', 'Closed') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot reassign a resolved or closed ticket';
    ELSEIF v_new_dept IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'New agent not found';
    ELSEIF v_new_active = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'New agent is not active';
    ELSEIF v_new_dept <> v_ticket_dept THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'New agent belongs to a different department';
    ELSEIF v_current_agent <=> p_new_agent_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ticket is already assigned to this agent';
    END IF;

    START TRANSACTION;

    UPDATE tickets
    SET current_agent_id = p_new_agent_id
    WHERE ticket_id = p_ticket_id;

    COMMIT;
END$$

-- 3. SLA report by department for tickets created between two dates (inclusive)
CREATE PROCEDURE sp_sla_report_by_department(
    IN p_start DATE,
    IN p_end   DATE
)
BEGIN
    IF p_start > p_end THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Start date must not be after end date';
    END IF;

    SELECT d.department_name,
           COUNT(*)                          AS tickets_received,
           SUM(t.resolved_at IS NOT NULL)    AS resolved,
           SUM(t.resolved_at IS NULL)        AS unresolved,
           ROUND(100 * SUM(t.resolved_at IS NOT NULL AND t.resolved_at <= t.due_at)
                 / NULLIF(SUM(t.resolved_at IS NOT NULL), 0), 1) AS pct_resolved_on_time,
           ROUND(AVG(CASE WHEN t.resolved_at IS NOT NULL
                          THEN TIMESTAMPDIFF(MINUTE, t.created_at, t.resolved_at) END) / 60, 1) AS avg_resolution_hours,
           ROUND(AVG(f.rating), 2)           AS avg_rating
    FROM tickets t
    INNER JOIN ticket_categories c ON c.category_id   = t.category_id
    INNER JOIN departments d       ON d.department_id = c.department_id
    LEFT JOIN customer_feedback f  ON f.ticket_id     = t.ticket_id
    WHERE t.created_at >= p_start
      AND t.created_at <  DATE_ADD(p_end, INTERVAL 1 DAY)
    GROUP BY d.department_id, d.department_name
    ORDER BY tickets_received DESC;
END$$

DELIMITER ;