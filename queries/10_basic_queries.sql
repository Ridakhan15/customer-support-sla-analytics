-- File: 10_basic_queries.sql
-- Purpose: Basic SQL on the support database

USE support_sla_db;

-- Q1. SELECT + ORDER BY + LIMIT: the 10 most recent tickets
SELECT ticket_id, subject, priority, status, created_at
FROM tickets
ORDER BY created_at DESC
LIMIT 10;

-- Q2. WHERE with AND + IS NULL: Critical tickets still unresolved
SELECT ticket_id, subject, status, created_at, due_at
FROM tickets
WHERE priority = 'Critical'
  AND resolved_at IS NULL
ORDER BY created_at;

-- Q3. DISTINCT: which cities do our customers live in?
SELECT DISTINCT city
FROM customers
ORDER BY city;

-- Q4. BETWEEN: tickets received in the first quarter of 2025
SELECT COUNT(*) AS q1_2025_tickets
FROM tickets
WHERE created_at BETWEEN '2025-01-01 00:00:00' AND '2025-03-31 23:59:59';

-- Q5. LIKE: customers whose name starts with 'Aarav'
SELECT customer_id, full_name, email
FROM customers
WHERE full_name LIKE 'Aarav%';

-- Q5b. LIKE with wildcards on both sides: tickets about refunds
SELECT COUNT(*) AS refund_tickets
FROM tickets
WHERE subject LIKE '%Refund%';

-- Q6. IN: tickets that are still active (the support backlog)
SELECT COUNT(*) AS active_tickets
FROM tickets
WHERE status IN ('Open', 'In Progress', 'On Hold', 'Reopened');

-- Q7. IS NULL: tickets nobody has responded to yet
SELECT COUNT(*) AS no_response_yet
FROM tickets
WHERE first_response_at IS NULL;

-- Q8. Calculated column + ORDER BY + LIMIT: 5 slowest resolved tickets
SELECT ticket_id, priority,
       TIMESTAMPDIFF(HOUR, created_at, resolved_at) AS hours_to_resolve
FROM tickets
WHERE resolved_at IS NOT NULL
ORDER BY hours_to_resolve DESC
LIMIT 5;

-- Q9. UPDATE: correct one customer's city (look first, change, look again)
SELECT customer_id, full_name, city FROM customers WHERE customer_id = 1;

UPDATE customers
SET city = 'Mumbai'
WHERE customer_id = 1;

SELECT customer_id, full_name, city FROM customers WHERE customer_id = 1;

-- Q10. INSERT then DELETE: add a test customer and remove them
INSERT INTO customers (full_name, email, phone, city, registered_date)
VALUES ('Test User', 'test.user@example.com', '+91 9800000000', 'Pune', '2026-11-06');

DELETE FROM customers
WHERE email = 'test.user@example.com';

-- Q11. Constraint test: deleting a customer who has tickets must FAIL
DELETE FROM customers
WHERE customer_id = 1;