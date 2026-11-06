-- File: 21_create_indexes.sql
-- Purpose: Indexes for the columns we filter and sort by

USE support_sla_db;

CREATE INDEX idx_tickets_created_at    ON tickets (created_at);
CREATE INDEX idx_tickets_status_due_at ON tickets (status, due_at);
CREATE INDEX idx_tickets_resolved_at   ON tickets (resolved_at);

ANALYZE TABLE tickets;
ANALYZE TABLE tickets;