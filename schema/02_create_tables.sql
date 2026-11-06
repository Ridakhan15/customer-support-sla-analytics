-- File: 02_create_tables.sql
-- Purpose: Create all tables for the Customer Support & SLA Analytics project

USE support_sla_db;

-- 1. Departments
CREATE TABLE departments (
    department_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    department_name  VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- 2. Agents (manager_id points back to agents: self-reference)
CREATE TABLE agents (
    agent_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name      VARCHAR(100) NOT NULL,
    email          VARCHAR(100) NOT NULL UNIQUE,
    department_id  INT UNSIGNED NOT NULL,
    manager_id     INT UNSIGNED NULL,
    hire_date      DATE NOT NULL,
    is_active      TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT fk_agents_department
        FOREIGN KEY (department_id) REFERENCES departments(department_id),
    CONSTRAINT fk_agents_manager
        FOREIGN KEY (manager_id) REFERENCES agents(agent_id)
        ON DELETE SET NULL
) ENGINE=InnoDB;

-- 3. Customers
CREATE TABLE customers (
    customer_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name        VARCHAR(100) NOT NULL,
    email            VARCHAR(100) NOT NULL UNIQUE,
    phone            VARCHAR(20) NULL,
    city             VARCHAR(50) NULL,
    registered_date  DATE NOT NULL
) ENGINE=InnoDB;

-- 4. Support channels
CREATE TABLE support_channels (
    channel_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    channel_name  VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- 5. Ticket categories (each category is handled by one department)
CREATE TABLE ticket_categories (
    category_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_name  VARCHAR(60) NOT NULL UNIQUE,
    department_id  INT UNSIGNED NOT NULL,
    CONSTRAINT fk_categories_department
        FOREIGN KEY (department_id) REFERENCES departments(department_id)
) ENGINE=InnoDB;

-- 6. SLA policies (one row per priority level)
CREATE TABLE sla_policies (
    sla_id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    priority          ENUM('Low','Medium','High','Critical') NOT NULL UNIQUE,
    response_hours    SMALLINT UNSIGNED NOT NULL,
    resolution_hours  SMALLINT UNSIGNED NOT NULL,
    CONSTRAINT chk_sla_hours CHECK (resolution_hours >= response_hours)
) ENGINE=InnoDB;

-- 7. Tickets (core table)
CREATE TABLE tickets (
    ticket_id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id        INT UNSIGNED NOT NULL,
    channel_id         INT UNSIGNED NOT NULL,
    category_id        INT UNSIGNED NOT NULL,
    sla_id             INT UNSIGNED NOT NULL,
    current_agent_id   INT UNSIGNED NULL,
    subject            VARCHAR(200) NOT NULL,
    priority           ENUM('Low','Medium','High','Critical') NOT NULL,
    status             ENUM('Open','In Progress','On Hold','Resolved','Closed','Reopened')
                       NOT NULL DEFAULT 'Open',
    created_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    first_response_at  DATETIME NULL,
    due_at             DATETIME NOT NULL,
    resolved_at        DATETIME NULL,
    reopen_count       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    CONSTRAINT fk_tickets_customer FOREIGN KEY (customer_id)      REFERENCES customers(customer_id),
    CONSTRAINT fk_tickets_channel  FOREIGN KEY (channel_id)       REFERENCES support_channels(channel_id),
    CONSTRAINT fk_tickets_category FOREIGN KEY (category_id)      REFERENCES ticket_categories(category_id),
    CONSTRAINT fk_tickets_sla      FOREIGN KEY (sla_id)           REFERENCES sla_policies(sla_id),
    CONSTRAINT fk_tickets_agent    FOREIGN KEY (current_agent_id) REFERENCES agents(agent_id)
        ON DELETE SET NULL,
    CONSTRAINT chk_tickets_due      CHECK (due_at > created_at),
    CONSTRAINT chk_tickets_resolved CHECK (resolved_at IS NULL OR resolved_at >= created_at)
) ENGINE=InnoDB;

-- 8. Ticket assignments (junction table: tickets <-> agents, with history)
CREATE TABLE ticket_assignments (
    assignment_id  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ticket_id      INT UNSIGNED NOT NULL,
    agent_id       INT UNSIGNED NOT NULL,
    assigned_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    unassigned_at  DATETIME NULL,
    reason         VARCHAR(100) NULL,
    CONSTRAINT fk_assign_ticket FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id),
    CONSTRAINT fk_assign_agent  FOREIGN KEY (agent_id)  REFERENCES agents(agent_id),
    CONSTRAINT chk_assign_dates CHECK (unassigned_at IS NULL OR unassigned_at >= assigned_at)
) ENGINE=InnoDB;

-- 9. Ticket status history (filled automatically by a trigger later)
CREATE TABLE ticket_status_history (
    history_id  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ticket_id   INT UNSIGNED NOT NULL,
    old_status  VARCHAR(20) NULL,
    new_status  VARCHAR(20) NOT NULL,
    changed_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_history_ticket FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id)
) ENGINE=InnoDB;

-- 10. Customer feedback (one-to-one with tickets via UNIQUE)
CREATE TABLE customer_feedback (
    feedback_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ticket_id     INT UNSIGNED NOT NULL UNIQUE,
    rating        TINYINT UNSIGNED NOT NULL,
    comments      VARCHAR(500) NULL,
    submitted_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_feedback_ticket FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id),
    CONSTRAINT chk_feedback_rating CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB;