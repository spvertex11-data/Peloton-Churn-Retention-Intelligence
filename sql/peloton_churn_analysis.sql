-- =========================================================
-- STEP 2: CREATE PROJECT SCHEMA
-- DATABASE: peloton_churn_ai_db
-- =========================================================

CREATE SCHEMA analytics;

-- =========================================================
-- CHECK: Confirm analytics schema exists
-- =========================================================

SELECT schema_name
FROM information_schema.schemata
WHERE schema_name = 'analytics';



-- =========================================================
-- STEP 3: CREATE CUSTOMER FEATURES TABLE
-- DATABASE: peloton_churn_ai_db
-- SCHEMA: analytics
-- =========================================================

DROP TABLE IF EXISTS analytics.customer_features;

CREATE TABLE analytics.customer_features (

    -- Unique customer identifier
    customer_id INTEGER PRIMARY KEY,

    -- Subscription start date
    signup_date DATE,

    -- monthly / annual
    plan_type VARCHAR(20),

    -- basic / plus / premium
    plan_tier VARCHAR(20),

    -- Monthly equivalent subscription price
    monthly_price NUMERIC(10,2),

    -- How customer was acquired
    acquisition_channel VARCHAR(50),

    -- Customer's primary device
    primary_device VARCHAR(50),

    -- Customer age group
    age_group VARCHAR(30),

    -- yes / no
    churned VARCHAR(10),

    -- Date customer cancelled
    churn_date DATE,

    -- Customer-selected cancel reason
    cancel_reason VARCHAR(100),

    -- 1 = churned
    -- 0 = active
    churn_flag SMALLINT,

    -- Date used to calculate tenure
    tenure_end_date DATE,

    -- Tenure in days
    tenure_days INTEGER,

    -- Tenure in months
    tenure_months NUMERIC(10,2),

    -- Tenure category
    tenure_band VARCHAR(30),

    -- Signup month
    signup_month DATE,

    -- First-month workouts
    first_month_workouts INTEGER,

    -- First-month active minutes
    first_month_minutes NUMERIC(12,2),

    -- First-month classes booked
    first_month_classes INTEGER,

    -- First-month support tickets
    first_month_support_tickets INTEGER,

    -- Very Low / Low / Medium / High
    first_month_engagement_band VARCHAR(30)
);


-- =========================================================
-- CHECK: Confirm table structure
-- =========================================================

SELECT COUNT(*) AS total_columns
FROM information_schema.columns
WHERE table_schema = 'analytics'
  AND table_name = 'customer_features';







-- =========================================================
-- STEP 4 CHECK:
-- Validate customer_features import
-- =========================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM analytics.customer_features;  


-- Preview first 10 customers

SELECT *
FROM analytics.customer_features
LIMIT 10;



-- =========================================================
-- STEP 5: CREATE MONTHLY USAGE FEATURES TABLE
-- DATABASE: peloton_churn_ai_db
-- SCHEMA: analytics
-- =========================================================

DROP TABLE IF EXISTS analytics.monthly_usage_features;

CREATE TABLE analytics.monthly_usage_features (

    -- Customer identifier
    customer_id INTEGER NOT NULL,

    -- Calendar month of activity
    month DATE NOT NULL,

    -- Current-month workouts
    workouts_completed INTEGER,

    -- Current-month active minutes
    minutes_active NUMERIC(12,2),

    -- Current-month classes booked
    classes_booked INTEGER,

    -- Current-month support tickets
    support_tickets INTEGER,

    -- 1 = minutes_active was originally missing
    -- 0 = original value was present
    minutes_active_missing_flag SMALLINT,

    -- Customer signup month
    signup_month DATE,

    -- 1 = customer's first subscription month
    -- 0 = later month
    is_first_month SMALLINT,

    -- Previous-month workouts
    prev_month_workouts INTEGER,

    -- Previous-month active minutes
    prev_month_minutes NUMERIC(12,2),

    -- Previous-month classes booked
    prev_month_classes INTEGER,

    -- Previous-month support tickets
    prev_month_support_tickets INTEGER,

    -- Very Low / Low / Medium / High
    prev_month_engagement_band VARCHAR(30),

    -- 1 = customer contacted support this month
    -- 0 = no support contact
    support_contact_flag SMALLINT,

    -- 1 = support contact in previous month
    -- 0 = no previous-month support contact
    prev_month_support_flag SMALLINT,

    -- 1 = customer eventually churned
    -- 0 = active at analysis end
    churn_flag SMALLINT,

    -- Month in which customer cancelled
    churn_month DATE,

    -- 1 = this specific month was the churn month
    -- 0 = customer did not churn in this month
    churn_month_flag SMALLINT,

    -- One row per customer per month
    PRIMARY KEY (customer_id, month)
);



-- =========================================================
-- CHECK: Confirm all 19 columns were created
-- =========================================================

SELECT
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'analytics'
  AND table_name = 'monthly_usage_features'
ORDER BY ordinal_position;



-- =========================================================
-- STEP 6 CHECK 1:
-- Validate total imported rows
-- =========================================================

SELECT COUNT(*) AS total_rows
FROM analytics.monthly_usage_features;



-- =========================================================
-- CHECK: What columns are actually in the PRIMARY KEY?
-- =========================================================

SELECT
    tc.constraint_name,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.table_schema = kcu.table_schema
WHERE tc.table_schema = 'analytics'
  AND tc.table_name = 'monthly_usage_features'
  AND tc.constraint_type = 'PRIMARY KEY'
ORDER BY kcu.ordinal_position;




-- Check what was actually imported

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT month) AS unique_months
FROM analytics.monthly_usage_features;





-- =========================================================
-- CHECK: Which columns are in the PRIMARY KEY?
-- =========================================================

SELECT
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
WHERE tc.table_schema = 'analytics'
  AND tc.table_name = 'monthly_usage_features'
  AND tc.constraint_type = 'PRIMARY KEY'
ORDER BY kcu.ordinal_position;







-- =========================================================
-- FIX: Recreate monthly usage table with correct data types
-- =========================================================

DROP TABLE IF EXISTS analytics.monthly_usage_features;

CREATE TABLE analytics.monthly_usage_features (

    customer_id INTEGER NOT NULL,

    month DATE NOT NULL,

    workouts_completed INTEGER,

    minutes_active NUMERIC(12,2),

    classes_booked INTEGER,

    support_tickets INTEGER,

    minutes_active_missing_flag SMALLINT,

    signup_month DATE,

    is_first_month SMALLINT,

    -- These pandas lag columns can contain values like 5.0
    prev_month_workouts NUMERIC(12,2),

    prev_month_minutes NUMERIC(12,2),

    prev_month_classes NUMERIC(12,2),

    prev_month_support_tickets NUMERIC(12,2),

    prev_month_engagement_band VARCHAR(30),

    support_contact_flag SMALLINT,

    prev_month_support_flag SMALLINT,

    churn_flag SMALLINT,

    churn_month DATE,

    churn_month_flag SMALLINT,

    PRIMARY KEY (customer_id, month)
);


-- Confirm table has 19 columns

SELECT COUNT(*) AS total_columns
FROM information_schema.columns
WHERE table_schema = 'analytics'
  AND table_name = 'monthly_usage_features';



-- =========================================================
-- FINAL VALIDATION
-- =========================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT month) AS unique_months
FROM analytics.monthly_usage_features;





-- =========================================================
-- STEP 7: CREATE MONTHLY CHURN SUMMARY
-- DATABASE: peloton_churn_ai_db
-- SCHEMA: analytics
--
-- PURPOSE:
-- Create a monthly KPI dataset for Power BI.
-- =========================================================


-- Delete the old view if it already exists
DROP VIEW IF EXISTS analytics.monthly_churn_summary;


-- =========================================================
-- CREATE MONTHLY CHURN SUMMARY VIEW
-- =========================================================

CREATE VIEW analytics.monthly_churn_summary AS

SELECT

    -- Calendar month
    month,

    -- Customers subscribed/active during the month
    COUNT(DISTINCT customer_id) AS active_subscribers,

    -- Customers who cancelled during this month
    SUM(churn_month_flag) AS churned_subscribers,

    -- Monthly churn rate %
    ROUND(
        (
            SUM(churn_month_flag)::NUMERIC
            /
            NULLIF(COUNT(DISTINCT customer_id), 0)
        ) * 100,
        2
    ) AS monthly_churn_rate_pct

FROM analytics.monthly_usage_features

GROUP BY month;





-- =========================================================
-- CHECK: Monthly churn KPI table
-- =========================================================

SELECT *
FROM analytics.monthly_churn_summary
ORDER BY month;  



-- Count reporting months

SELECT COUNT(*) AS total_months
FROM analytics.monthly_churn_summary;



-- =========================================================
-- SQL QUERY 1 OF 15
-- OVERALL CUSTOMER CHURN KPIs
-- =========================================================

SELECT

    -- Total number of customers
    COUNT(*) AS total_customers,

    -- Customers still active
    SUM(
        CASE
            WHEN churn_flag = 0 THEN 1
            ELSE 0
        END
    ) AS active_customers,

    -- Customers who cancelled
    SUM(
        CASE
            WHEN churn_flag = 1 THEN 1
            ELSE 0
        END
    ) AS churned_customers,

    -- Overall churn rate
    ROUND(
        (
            SUM(
                CASE
                    WHEN churn_flag = 1 THEN 1
                    ELSE 0
                END
            )::NUMERIC
            /
            NULLIF(COUNT(*), 0)
        ) * 100,
        2
    ) AS overall_churn_rate_pct,

    -- Average customer tenure
    ROUND(
        AVG(tenure_months),
        2
    ) AS avg_tenure_months

FROM analytics.customer_features;


-- =========================================================
-- SQL QUERY 2 OF 15
-- CHURN BY PLAN TYPE
-- PURPOSE:
-- Compare churn between monthly and annual subscribers.
-- =========================================================

SELECT

    -- Subscription billing type
    plan_type,

    -- Total customers in each plan type
    COUNT(*) AS total_customers,

    -- Number of churned customers
    SUM(
        CASE
            WHEN churn_flag = 1 THEN 1
            ELSE 0
        END
    ) AS churned_customers,

    -- Number of active customers
    SUM(
        CASE
            WHEN churn_flag = 0 THEN 1
            ELSE 0
        END
    ) AS active_customers,

    -- Churn rate percentage
    ROUND(
        (
            SUM(
                CASE
                    WHEN churn_flag = 1 THEN 1
                    ELSE 0
                END
            )::NUMERIC
            /
            NULLIF(COUNT(*), 0)
        ) * 100,
        2
    ) AS churn_rate_pct

FROM analytics.customer_features

GROUP BY plan_type

ORDER BY churn_rate_pct DESC;


-- =========================================================
-- SQL QUERY 3 OF 15
-- CHURN BY PLAN TIER
-- PURPOSE:
-- Compare churn across Basic, Plus and Premium plans.
-- =========================================================

SELECT

    -- Subscription tier
    plan_tier,

    -- Total customers in each tier
    COUNT(*) AS total_customers,

    -- Churned customers in each tier
    SUM(
        CASE
            WHEN churn_flag = 1 THEN 1
            ELSE 0
        END
    ) AS churned_customers,

    -- Active customers in each tier
    SUM(
        CASE
            WHEN churn_flag = 0 THEN 1
            ELSE 0
        END
    ) AS active_customers,

    -- Churn rate percentage
    ROUND(
        (
            SUM(
                CASE
                    WHEN churn_flag = 1 THEN 1
                    ELSE 0
                END
            )::NUMERIC
            /
            NULLIF(COUNT(*), 0)
        ) * 100,
        2
    ) AS churn_rate_pct

FROM analytics.customer_features

GROUP BY plan_tier

ORDER BY churn_rate_pct DESC;




-- =========================================================
-- SQL QUERY 4 OF 15
-- CHURN BY ACQUISITION CHANNEL
-- PURPOSE:
-- Compare churn across customer acquisition sources.
-- =========================================================

SELECT

    -- Channel through which customer was acquired
    acquisition_channel,

    -- Total customers acquired from each channel
    COUNT(*) AS total_customers,

    -- Customers who churned
    SUM(
        CASE
            WHEN churn_flag = 1 THEN 1
            ELSE 0
        END
    ) AS churned_customers,

    -- Customers still active
    SUM(
        CASE
            WHEN churn_flag = 0 THEN 1
            ELSE 0
        END
    ) AS active_customers,

    -- Churn rate percentage
    ROUND(
        (
            SUM(
                CASE
                    WHEN churn_flag = 1 THEN 1
                    ELSE 0
                END
            )::NUMERIC
            /
            NULLIF(COUNT(*), 0)
        ) * 100,
        2
    ) AS churn_rate_pct

FROM analytics.customer_features

GROUP BY acquisition_channel

ORDER BY churn_rate_pct DESC;




-- =========================================================
-- SQL QUERY 5 OF 15
-- CHURN BY PRIMARY DEVICE AND AGE GROUP
-- PURPOSE:
-- Compare churn across device type and customer age group.
-- =========================================================

SELECT

    -- Customer's main device
    primary_device,

    -- Customer age category
    age_group,

    -- Total customers in the segment
    COUNT(*) AS total_customers,

    -- Churned customers in the segment
    SUM(
        CASE
            WHEN churn_flag = 1 THEN 1
            ELSE 0
        END
    ) AS churned_customers,

    -- Churn rate percentage
    ROUND(
        (
            SUM(
                CASE
                    WHEN churn_flag = 1 THEN 1
                    ELSE 0
                END
            )::NUMERIC
            /
            NULLIF(COUNT(*), 0)
        ) * 100,
        2
    ) AS churn_rate_pct

FROM analytics.customer_features

GROUP BY
    primary_device,
    age_group

ORDER BY churn_rate_pct DESC;



-- =========================================================
-- SQL QUERY 6 OF 15
-- MONTHLY CHURN TREND
-- PURPOSE:
-- Track active subscribers, churned subscribers
-- and monthly churn rate over time.
-- =========================================================

SELECT

    -- Reporting month
    month,

    -- Customers subscribed during the month
    active_subscribers,

    -- Customers who cancelled during the month
    churned_subscribers,

    -- Monthly churn rate %
    monthly_churn_rate_pct

FROM analytics.monthly_churn_summary

ORDER BY month;



-- =========================================================
-- SQL QUERY 7 OF 15
-- CHURN BY TENURE BAND
-- PURPOSE:
-- Understand how churn changes as customers stay longer.
-- =========================================================

SELECT

    -- Customer tenure category
    tenure_band,

    -- Total customers in each tenure group
    COUNT(*) AS total_customers,

    -- Number of churned customers
    SUM(
        CASE
            WHEN churn_flag = 1 THEN 1
            ELSE 0
        END
    ) AS churned_customers,

    -- Number of active customers
    SUM(
        CASE
            WHEN churn_flag = 0 THEN 1
            ELSE 0
        END
    ) AS active_customers,

    -- Churn rate percentage
    ROUND(
        (
            SUM(
                CASE
                    WHEN churn_flag = 1 THEN 1
                    ELSE 0
                END
            )::NUMERIC
            /
            NULLIF(COUNT(*), 0)
        ) * 100,
        2
    ) AS churn_rate_pct

FROM analytics.customer_features

GROUP BY tenure_band

ORDER BY
    MIN(tenure_months);


-- =========================================================
-- SQL QUERY 8 OF 15
-- FIRST-MONTH ENGAGEMENT VS CHURN
-- PURPOSE:
-- Check whether weak early engagement is associated
-- with higher customer churn.
-- =========================================================

SELECT

    -- First-month engagement category
    first_month_engagement_band,

    -- Total customers in each engagement group
    COUNT(*) AS total_customers,

    -- Number of churned customers
    SUM(
        CASE
            WHEN churn_flag = 1 THEN 1
            ELSE 0
        END
    ) AS churned_customers,

    -- Average first-month workouts
    ROUND(
        AVG(first_month_workouts),
        2
    ) AS avg_first_month_workouts,

    -- Average first-month active minutes
    ROUND(
        AVG(first_month_minutes),
        2
    ) AS avg_first_month_minutes,

    -- Churn rate %
    ROUND(
        (
            SUM(
                CASE
                    WHEN churn_flag = 1 THEN 1
                    ELSE 0
                END
            )::NUMERIC
            /
            NULLIF(COUNT(*), 0)
        ) * 100,
        2
    ) AS churn_rate_pct

FROM analytics.customer_features

GROUP BY first_month_engagement_band

ORDER BY churn_rate_pct DESC;




-- =========================================================
-- SQL QUERY 9 OF 15
-- PREVIOUS-MONTH ENGAGEMENT VS MONTHLY CHURN
-- PURPOSE:
-- Check whether low recent engagement is associated
-- with higher churn in the following month.
-- =========================================================

SELECT

    -- Previous-month engagement category
    prev_month_engagement_band,

    -- Total customer-month observations
    COUNT(*) AS customer_months,

    -- Number of churn events
    SUM(churn_month_flag) AS churn_events,

    -- Monthly churn rate %
    ROUND(
        (
            SUM(churn_month_flag)::NUMERIC
            /
            NULLIF(COUNT(*), 0)
        ) * 100,
        2
    ) AS monthly_churn_rate_pct

FROM analytics.monthly_usage_features

-- First month has no previous-month behavior,
-- so remove those rows from this analysis.
WHERE prev_month_engagement_band IS NOT NULL

GROUP BY prev_month_engagement_band

ORDER BY monthly_churn_rate_pct DESC;



-- =========================================================
-- SQL QUERY 10 OF 15
-- SUPPORT CONTACT VS MONTHLY CHURN
-- PURPOSE:
-- Compare churn for customers who contacted support
-- versus customers who did not.
-- =========================================================

SELECT

    -- 1 = customer contacted support this month
    -- 0 = no support contact
    support_contact_flag,

    -- Total customer-month observations
    COUNT(*) AS customer_months,

    -- Number of churn events
    SUM(churn_month_flag) AS churn_events,

    -- Monthly churn rate %
    ROUND(
        (
            SUM(churn_month_flag)::NUMERIC
            /
            NULLIF(COUNT(*), 0)
        ) * 100,
        2
    ) AS monthly_churn_rate_pct,

    -- Average number of support tickets
    ROUND(
        AVG(support_tickets),
        2
    ) AS avg_support_tickets

FROM analytics.monthly_usage_features

GROUP BY support_contact_flag

ORDER BY monthly_churn_rate_pct DESC;



-- =========================================================
-- SQL QUERY 11 OF 15
-- TENURE-ADJUSTED ENGAGEMENT VS CHURN
-- PURPOSE:
-- Check whether low recent engagement still shows
-- higher churn within similar tenure groups.
-- =========================================================


WITH tenure_data AS (

    SELECT

        customer_id,
        month,
        signup_month,

        prev_month_engagement_band,
        churn_month_flag,

        -- -------------------------------------------------
        -- Calculate customer tenure in months
        -- for each monthly usage record
        -- -------------------------------------------------

        (
            (EXTRACT(YEAR FROM month)
             - EXTRACT(YEAR FROM signup_month)) * 12

            +

            (EXTRACT(MONTH FROM month)
             - EXTRACT(MONTH FROM signup_month))
        ) AS tenure_months

    FROM analytics.monthly_usage_features

    -- First subscription month has no previous-month behavior
    WHERE prev_month_engagement_band IS NOT NULL
),


tenure_bands AS (

    SELECT

        customer_id,
        month,
        prev_month_engagement_band,
        churn_month_flag,

        -- -------------------------------------------------
        -- Convert tenure months into business-friendly bands
        -- -------------------------------------------------

        CASE

            WHEN tenure_months <= 1
                THEN '0-1 months'

            WHEN tenure_months <= 3
                THEN '2-3 months'

            WHEN tenure_months <= 6
                THEN '4-6 months'

            WHEN tenure_months <= 12
                THEN '7-12 months'

            WHEN tenure_months <= 18
                THEN '13-18 months'

            ELSE '18+ months'

        END AS tenure_band

    FROM tenure_data
)


SELECT

    -- Customer lifecycle stage
    tenure_band,

    -- Previous-month engagement level
    prev_month_engagement_band,

    -- Number of customer-month observations
    COUNT(*) AS customer_months,

    -- Number of churn events
    SUM(churn_month_flag) AS churn_events,

    -- Monthly churn rate %
    ROUND(
        (
            SUM(churn_month_flag)::NUMERIC
            /
            NULLIF(COUNT(*), 0)
        ) * 100,
        2
    ) AS monthly_churn_rate_pct

FROM tenure_bands

GROUP BY
    tenure_band,
    prev_month_engagement_band

ORDER BY

    -- Keep tenure groups in logical order
    CASE tenure_band

        WHEN '0-1 months' THEN 1
        WHEN '2-3 months' THEN 2
        WHEN '4-6 months' THEN 3
        WHEN '7-12 months' THEN 4
        WHEN '13-18 months' THEN 5
        ELSE 6

    END,

    monthly_churn_rate_pct DESC;



-- =========================================================
-- SQL QUERY 12 OF 15
-- TENURE-ADJUSTED SUPPORT CONTACT VS CHURN
-- PURPOSE:
-- Check whether support contact is still associated
-- with higher churn after accounting for tenure.
-- =========================================================


WITH tenure_data AS (

    SELECT

        customer_id,
        month,
        signup_month,
        support_contact_flag,
        churn_month_flag,

        -- Calculate tenure in months for each customer-month
        (
            (EXTRACT(YEAR FROM month)
             - EXTRACT(YEAR FROM signup_month)) * 12

            +

            (EXTRACT(MONTH FROM month)
             - EXTRACT(MONTH FROM signup_month))
        ) AS tenure_months

    FROM analytics.monthly_usage_features
),


tenure_bands AS (

    SELECT

        customer_id,
        month,
        support_contact_flag,
        churn_month_flag,

        -- Convert tenure into business-friendly groups
        CASE

            WHEN tenure_months <= 1
                THEN '0-1 months'

            WHEN tenure_months <= 3
                THEN '2-3 months'

            WHEN tenure_months <= 6
                THEN '4-6 months'

            WHEN tenure_months <= 12
                THEN '7-12 months'

            WHEN tenure_months <= 18
                THEN '13-18 months'

            ELSE '18+ months'

        END AS tenure_band

    FROM tenure_data
)


SELECT

    -- Customer lifecycle stage
    tenure_band,

    -- 0 = no support contact
    -- 1 = contacted support
    support_contact_flag,

    -- Number of customer-month observations
    COUNT(*) AS customer_months,

    -- Number of churn events
    SUM(churn_month_flag) AS churn_events,

    -- Monthly churn rate %
    ROUND(
        (
            SUM(churn_month_flag)::NUMERIC
            /
            NULLIF(COUNT(*), 0)
        ) * 100,
        2
    ) AS monthly_churn_rate_pct

FROM tenure_bands

GROUP BY
    tenure_band,
    support_contact_flag

ORDER BY

    CASE tenure_band
        WHEN '0-1 months' THEN 1
        WHEN '2-3 months' THEN 2
        WHEN '4-6 months' THEN 3
        WHEN '7-12 months' THEN 4
        WHEN '13-18 months' THEN 5
        ELSE 6
    END,

    support_contact_flag;	


-- =========================================================
-- SQL QUERY 13 OF 15
-- ANNUAL RENEWAL CHURN BY TENURE MONTH
-- PURPOSE:
-- Identify whether annual subscribers show a churn spike
-- around their renewal period.
-- =========================================================


WITH annual_customer_months AS (

    SELECT

        m.customer_id,
        m.month,
        m.signup_month,
        m.churn_month_flag,

        -- Calculate tenure month number
        (
            (EXTRACT(YEAR FROM m.month)
             - EXTRACT(YEAR FROM m.signup_month)) * 12

            +

            (EXTRACT(MONTH FROM m.month)
             - EXTRACT(MONTH FROM m.signup_month))
        ) AS tenure_month_number

    FROM analytics.monthly_usage_features AS m

    INNER JOIN analytics.customer_features AS c
        ON m.customer_id = c.customer_id

    -- Keep annual-plan customers only
    WHERE c.plan_type = 'annual'
)


SELECT

    -- Subscription lifecycle month
    tenure_month_number,

    -- Number of annual customer-month observations
    COUNT(*) AS customer_months,

    -- Number of churn events
    SUM(churn_month_flag) AS churn_events,

    -- Churn rate at each tenure month
    ROUND(
        (
            SUM(churn_month_flag)::NUMERIC
            /
            NULLIF(COUNT(*), 0)
        ) * 100,
        2
    ) AS churn_rate_pct

FROM annual_customer_months

GROUP BY tenure_month_number

ORDER BY tenure_month_number;	



-- =========================================================
-- SQL QUERY 14 OF 15
-- CANCEL REASONS VS ACTUAL CUSTOMER BEHAVIOR
-- PURPOSE:
-- Compare self-reported cancellation reasons with
-- recent engagement and support activity.
-- =========================================================


WITH churn_behavior AS (

    SELECT

        -- Customer identifier
        c.customer_id,

        -- Customer-reported cancel reason
        c.cancel_reason,

        -- Previous-month engagement
        m.prev_month_workouts,
        m.prev_month_minutes,
        m.prev_month_classes,

        -- Support activity in churn month
        m.support_tickets,
        m.support_contact_flag

    FROM analytics.customer_features AS c

    INNER JOIN analytics.monthly_usage_features AS m
        ON c.customer_id = m.customer_id

    -- Keep only the actual churn month
    WHERE c.churn_flag = 1
      AND m.churn_month_flag = 1
)


SELECT

    -- Cancellation reason selected by customer
    cancel_reason,

    -- Number of customers with this reason
    COUNT(DISTINCT customer_id) AS churned_customers,

    -- Average workouts in previous month
    ROUND(
        AVG(prev_month_workouts),
        2
    ) AS avg_prev_month_workouts,

    -- Average active minutes in previous month
    ROUND(
        AVG(prev_month_minutes),
        2
    ) AS avg_prev_month_minutes,

    -- Average classes booked in previous month
    ROUND(
        AVG(prev_month_classes),
        2
    ) AS avg_prev_month_classes,

    -- Average support tickets in churn month
    ROUND(
        AVG(support_tickets),
        2
    ) AS avg_support_tickets,

    -- Percentage who contacted support
    ROUND(
        AVG(support_contact_flag::NUMERIC) * 100,
        2
    ) AS support_contact_rate_pct

FROM churn_behavior

GROUP BY cancel_reason

ORDER BY churned_customers DESC;


-- =========================================================
-- SQL QUERY 15 OF 15
-- RANK THE STRONGEST CHURN SIGNALS
-- PURPOSE:
-- Compare three important churn signals and rank them
-- by the size of the churn-rate difference.
--
-- IMPORTANT:
-- These are associations, not proof of causation.
-- =========================================================


WITH engagement_signal AS (

    -- =====================================================
    -- SIGNAL 1: LOW RECENT ENGAGEMENT
    -- Compare 0-1 previous-month workouts vs 2+ workouts
    -- =====================================================

    SELECT

        'Low Recent Engagement' AS churn_signal,

        '0-1 previous-month workouts' AS high_risk_group,

        '2+ previous-month workouts' AS comparison_group,

        -- Churn rate for low-engagement customer-months
        (
            SUM(churn_month_flag)
                FILTER (
                    WHERE prev_month_workouts <= 1
                )::NUMERIC
            /
            NULLIF(
                COUNT(*)
                    FILTER (
                        WHERE prev_month_workouts <= 1
                    ),
                0
            )
        ) * 100 AS high_risk_churn_rate,

        -- Churn rate for customers with 2+ workouts
        (
            SUM(churn_month_flag)
                FILTER (
                    WHERE prev_month_workouts > 1
                )::NUMERIC
            /
            NULLIF(
                COUNT(*)
                    FILTER (
                        WHERE prev_month_workouts > 1
                    ),
                0
            )
        ) * 100 AS comparison_churn_rate

    FROM analytics.monthly_usage_features

    -- Remove first-month records because
    -- previous-month behavior does not exist yet
    WHERE prev_month_workouts IS NOT NULL
),


support_signal AS (

    -- =====================================================
    -- SIGNAL 2: SUPPORT CONTACT
    -- Compare customers with vs without support contact
    -- =====================================================

    SELECT

        'Support Contact' AS churn_signal,

        'Contacted support' AS high_risk_group,

        'No support contact' AS comparison_group,

        -- Churn rate when support was contacted
        (
            SUM(churn_month_flag)
                FILTER (
                    WHERE support_contact_flag = 1
                )::NUMERIC
            /
            NULLIF(
                COUNT(*)
                    FILTER (
                        WHERE support_contact_flag = 1
                    ),
                0
            )
        ) * 100 AS high_risk_churn_rate,

        -- Churn rate without support contact
        (
            SUM(churn_month_flag)
                FILTER (
                    WHERE support_contact_flag = 0
                )::NUMERIC
            /
            NULLIF(
                COUNT(*)
                    FILTER (
                        WHERE support_contact_flag = 0
                    ),
                0
            )
        ) * 100 AS comparison_churn_rate

    FROM analytics.monthly_usage_features
),


annual_tenure AS (

    -- =====================================================
    -- Prepare annual-plan tenure information
    -- =====================================================

    SELECT

        m.customer_id,
        m.churn_month_flag,

        (
            (EXTRACT(YEAR FROM m.month)
             - EXTRACT(YEAR FROM m.signup_month)) * 12

            +

            (EXTRACT(MONTH FROM m.month)
             - EXTRACT(MONTH FROM m.signup_month))
        ) AS tenure_month

    FROM analytics.monthly_usage_features AS m

    INNER JOIN analytics.customer_features AS c
        ON m.customer_id = c.customer_id

    WHERE c.plan_type = 'annual'
),


renewal_signal AS (

    -- =====================================================
    -- SIGNAL 3: ANNUAL RENEWAL PERIOD
    -- Compare tenure months 11-12 vs other annual months
    -- =====================================================

    SELECT

        'Annual Renewal Period' AS churn_signal,

        'Tenure months 11-12' AS high_risk_group,

        'Other annual-plan months' AS comparison_group,

        -- Renewal-period churn rate
        (
            SUM(churn_month_flag)
                FILTER (
                    WHERE tenure_month BETWEEN 11 AND 12
                )::NUMERIC
            /
            NULLIF(
                COUNT(*)
                    FILTER (
                        WHERE tenure_month BETWEEN 11 AND 12
                    ),
                0
            )
        ) * 100 AS high_risk_churn_rate,

        -- Churn rate outside renewal period
        (
            SUM(churn_month_flag)
                FILTER (
                    WHERE tenure_month NOT BETWEEN 11 AND 12
                )::NUMERIC
            /
            NULLIF(
                COUNT(*)
                    FILTER (
                        WHERE tenure_month NOT BETWEEN 11 AND 12
                    ),
                0
            )
        ) * 100 AS comparison_churn_rate

    FROM annual_tenure
),


combined_signals AS (

    -- Combine all three churn signals

    SELECT * FROM engagement_signal

    UNION ALL

    SELECT * FROM support_signal

    UNION ALL

    SELECT * FROM renewal_signal
),


signal_gaps AS (

    -- Calculate percentage-point difference

    SELECT

        churn_signal,
        high_risk_group,
        comparison_group,

        ROUND(
            high_risk_churn_rate,
            2
        ) AS high_risk_churn_rate_pct,

        ROUND(
            comparison_churn_rate,
            2
        ) AS comparison_churn_rate_pct,

        ROUND(
            high_risk_churn_rate
            - comparison_churn_rate,
            2
        ) AS churn_rate_gap_pct_points

    FROM combined_signals
)


SELECT

    -- Window function ranks signals by churn-rate gap
    RANK() OVER (
        ORDER BY churn_rate_gap_pct_points DESC
    ) AS signal_rank,

    churn_signal,

    high_risk_group,

    high_risk_churn_rate_pct,

    comparison_group,

    comparison_churn_rate_pct,

    churn_rate_gap_pct_points

FROM signal_gaps

ORDER BY signal_rank;