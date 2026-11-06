# Customer Support & SLA Analytics Dashboard

An end-to-end data analytics project that analyzes customer support ticket performance, monitors Service Level Agreement (SLA) compliance, evaluates agent performance, and tracks customer satisfaction using **MySQL and Power BI**.

## Project Overview

Customer support teams handle large volumes of customer requests every day. Monitoring ticket resolution time, SLA compliance, agent productivity, and customer satisfaction is essential for maintaining service quality.

This project uses a synthetic dataset of **5,000 customer support tickets** spanning January 2025 to October 2026 to analyze support operations and identify performance trends.

The project combines SQL-based data analysis with an interactive Power BI dashboard to transform raw ticket data into meaningful business insights.

## Objectives

- Analyze overall customer support ticket volume.
- Monitor open and resolved tickets.
- Measure SLA compliance and breach rates.
- Calculate average first response and resolution times.
- Evaluate customer satisfaction (CSAT).
- Compare agent performance across departments.
- Identify trends in ticket volume and unresolved backlog.

## Tech Stack

| Technology            | Purpose                                                 |
| --------------------- | ------------------------------------------------------- |
| MySQL                 | Database management and SQL analysis                    |
| SQL                   | Data extraction, cleaning, transformation, and analysis |
| Power BI              | Interactive dashboard and data visualization            |
| Microsoft Excel / CSV | Dataset handling                                        |
| Git & GitHub          | Version control and project documentation               |

## Dataset Information

- **Total Records:** 5,000 customer support tickets
- **Data Type:** Synthetic data
- **Time Period:** January 2025 – October 2026
- **Database:** MySQL
- **Database Name:** `support_sla_db`

The dataset includes information related to:

- Ticket ID
- Priority
- Ticket status
- Department
- Category
- Support channel
- Agent name
- Customer city
- Ticket creation date
- Due date
- First response time
- Resolution time
- SLA result
- Reopen count
- Customer feedback rating

## SQL Analysis

MySQL was used to create and analyze the customer support database.

Key SQL concepts implemented include:

- Database and table creation
- Data insertion and management
- SELECT, WHERE, ORDER BY and DISTINCT
- Aggregate functions (COUNT, SUM, AVG)
- GROUP BY and HAVING
- INNER JOIN and LEFT JOIN
- Subqueries and Common Table Expressions (CTEs)
- Date and time calculations
- CASE statements and conditional aggregation
- SQL views for dashboard-ready data

Two dashboard-ready SQL views were created:

**1. `v_dash_tickets`**

Combines ticket details and customer feedback, including calculated response times and performance indicators.

**2. `v_dash_monthly_backlog`**

Calculates monthly ticket volume, resolved tickets, and unresolved backlog at the end of each month.

## Power BI Dashboard

The Power BI dashboard provides an overview of customer support operations through KPI cards, charts, and interactive filters.

### Key Performance Indicators (KPIs)

1. Total Tickets
2. Open Tickets
3. SLA Breach Percentage
4. Average First Response Time (Hours)
5. Average Resolution Time (Hours)
6. Customer Satisfaction (CSAT) Rating

### Dashboard Visualizations

- Monthly ticket volume analysis
- Monthly backlog trend
- SLA breach percentage by priority
- Tickets by category
- Agent performance scorecard

### Interactive Filters

- Department
- Year (2025 and 2026)

The dashboard uses Power BI measures to calculate KPIs dynamically based on the selected filters.

## Project Structure

```text
Customer_Support_SLA_Analytics/
│
├── database/
│   ├── SQL scripts
│   ├── Table creation
│   ├── Data insertion
│   ├── Analysis queries
│   └── Dashboard views
│
├── data/
│   └── Synthetic datasets
│
├── dashboard/
│   ├── Support_SLA_Dashboard.pbix
│   ├── Support_SLA_Dashboard.pdf
│   └── dashboard_preview.png
│
├── documentation/
│   └── ER diagram and project screenshots
│
├── README.md
└── .gitignore
```

## Key Business Insights

This project helps analyze:

- The relationship between ticket priority and SLA breaches.
- Monthly changes in incoming support ticket volume.
- Trends in unresolved customer support tickets.
- Differences in agent resolution efficiency.
- Customer satisfaction across support operations.
- Departments and categories contributing to support workload.

The dashboard makes it easier to identify operational bottlenecks and monitor customer support performance.

## How to Run the Project

### Step 1: Clone the Repository

```bash
git clone https://github.com/Ridakhan15/customer-support-sla-analytics.git
```

### Step 2: Open the Project

Navigate to the downloaded project folder.

### Step 3: Set Up MySQL

- Open MySQL Workbench.
- Execute the database creation and table creation scripts.
- Import or insert the synthetic dataset.
- Execute the SQL analysis scripts.
- Create the dashboard views.

### Step 4: Open Power BI

- Open `Support_SLA_Dashboard.pbix`.
- Connect to your MySQL database if required.
- Refresh the dataset.
- Explore the dashboard and its interactive filters.

## Project Limitations

- The dataset is synthetic and does not represent actual company or customer records.
- The backlog trend is calculated separately at the company level and does not respond to the department and year slicers.
- The dashboard is designed for analytical and demonstration purposes.

## Author

**Rida Khan**

B.Sc. Computer Science | Data Analytics | SQL | Power BI | Python

- GitHub: [@Ridakhan15](https://github.com/Ridakhan15)
- LinkedIn: [Connect with me](https://linkedin.com/in/khrida15)

---

_If you find this project interesting, feel free to explore the repository and share your feedback!_
