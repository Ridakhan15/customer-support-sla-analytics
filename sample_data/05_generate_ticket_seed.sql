-- File: 05_generate_ticket_seed.sql
-- Purpose: Generate 5,000 rows of random ticket "raw material" in a helper table

USE support_sla_db;

DROP TABLE IF EXISTS stg_ticket_seed;

CREATE TABLE stg_ticket_seed (
    seq          INT UNSIGNED PRIMARY KEY,
    customer_id  INT UNSIGNED NOT NULL,
    channel_id   INT UNSIGNED NOT NULL,
    category_id  INT UNSIGNED NOT NULL,
    priority     VARCHAR(10)  NOT NULL,
    created_at   DATETIME     NOT NULL,
    r_agent      DOUBLE NOT NULL,
    r_resp       DOUBLE NOT NULL,
    r_res        DOUBLE NOT NULL,
    r_state      DOUBLE NOT NULL,
    r_close      DOUBLE NOT NULL,
    r_reopen     DOUBLE NOT NULL
) ENGINE=InnoDB;

SET SESSION cte_max_recursion_depth = 6000;

INSERT INTO stg_ticket_seed
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 5000
)
SELECT
    n,
    1 + FLOOR(600 * POW(RAND(), 1.5)),
    ELT(1 + FLOOR(RAND() * 20), 1,1,1,1,1,2,2,2,2,3,3,3,3,3,4,4,5,6,6,6),
    ELT(1 + FLOOR(RAND() * 20), 1,1,2,2,3,4,4,5,5,6,7,8,9,10,10,11,12,13,14,15),
    ELT(1 + FLOOR(RAND() * 20),
        'Low','Low','Low','Low','Low','Low',
        'Medium','Medium','Medium','Medium','Medium','Medium','Medium','Medium',
        'High','High','High','High',
        'Critical','Critical'),
    DATE_ADD('2025-01-01 00:00:00', INTERVAL FLOOR(57801600 * POW(RAND(), 0.8)) SECOND),
    POW(RAND(), 1.4),
    RAND(), RAND(), RAND(), RAND(), RAND()
FROM seq;
