USE support_sla_db;

INSERT INTO customers (full_name, email, phone, city, registered_date)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 600
),
names AS (
    SELECT
        n,
        ELT(1 + MOD(n - 1, 30),
            'Aarav','Vivaan','Aditya','Rohan','Arjun','Kabir','Ishaan','Rahul','Karan','Imran',
            'Zoya','Ananya','Diya','Priya','Neha','Sneha','Pooja','Riya','Kavya','Meera',
            'Sana','Ayesha','Fatima','Isha','Tanvi','Nikhil','Sameer','Harsh','Yash','Rehan') AS first_name,
        ELT(1 + MOD(FLOOR((n - 1) / 30), 20),
            'Sharma','Verma','Patil','Kulkarni','Shaikh','Khan','Gupta','Mehta','Joshi','Nair',
            'Reddy','Iyer','Singh','Desai','Pawar','Jain','Kapoor','Bhatt','Ansari','Menon') AS last_name
    FROM seq
)
SELECT
    CONCAT(first_name, ' ', last_name),
    LOWER(CONCAT(first_name, '.', last_name, n, '@example.com')),
    CONCAT('+91 ', ELT(1 + FLOOR(RAND() * 3), '98', '97', '99'), LPAD(FLOOR(RAND() * 100000000), 8, '0')),
    ELT(1 + FLOOR(RAND() * 10), 'Mumbai','Pune','Delhi','Bengaluru','Hyderabad',
                                'Chennai','Kolkata','Ahmedabad','Jaipur','Thane'),
    DATE_ADD('2023-01-01', INTERVAL FLOOR(RAND() * 730) DAY)
FROM names;