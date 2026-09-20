# ============================================================
# PROJECT: Peloton Churn & Retention Intelligence
# FILE: 03_verified_analytics.py
#
# PURPOSE:
# Retrieve verified churn KPIs and driver evidence
# directly from PostgreSQL.
#
# IMPORTANT:
# The LLM will NOT calculate these numbers.
# PostgreSQL is the source of truth.
# ============================================================


import os
import psycopg2

from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv


# ------------------------------------------------------------
# 1. Load environment variables
# ------------------------------------------------------------

load_dotenv()


# ------------------------------------------------------------
# 2. PostgreSQL connection function
# ------------------------------------------------------------

def get_connection():

    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )


# ============================================================
# FUNCTION 1:
# OVERALL CUSTOMER KPIs
# ============================================================

def get_overall_kpis():

    query = """
        SELECT

            COUNT(*) AS total_customers,

            SUM(
                CASE
                    WHEN churn_flag = 0 THEN 1
                    ELSE 0
                END
            ) AS active_customers,

            SUM(
                CASE
                    WHEN churn_flag = 1 THEN 1
                    ELSE 0
                END
            ) AS churned_customers,

            ROUND(
                (
                    SUM(churn_flag)::NUMERIC
                    /
                    NULLIF(COUNT(*), 0)
                ) * 100,
                2
            ) AS overall_churn_rate_pct,

            ROUND(
                AVG(tenure_months),
                2
            ) AS avg_tenure_months

        FROM analytics.customer_features;
    """

    connection = get_connection()

    try:

        with connection.cursor(
            cursor_factory=RealDictCursor
        ) as cursor:

            cursor.execute(query)

            return dict(cursor.fetchone())

    finally:

        connection.close()


# ============================================================
# FUNCTION 2:
# LATEST MONTH CHURN KPI
# ============================================================

def get_latest_month_churn():

    query = """
        SELECT
            month,
            active_subscribers,
            churned_subscribers,
            monthly_churn_rate_pct

        FROM analytics.monthly_churn_summary

        ORDER BY month DESC

        LIMIT 1;
    """

    connection = get_connection()

    try:

        with connection.cursor(
            cursor_factory=RealDictCursor
        ) as cursor:

            cursor.execute(query)

            result = dict(cursor.fetchone())

            # Convert date to text for easy JSON / LLM usage
            result["month"] = str(result["month"])

            return result

    finally:

        connection.close()


# ============================================================
# FUNCTION 3:
# LOW RECENT ENGAGEMENT VS CHURN
# ============================================================

def get_engagement_driver():

    query = """
        SELECT

            CASE
                WHEN prev_month_workouts <= 1
                    THEN '0-1 workouts'
                ELSE '2+ workouts'
            END AS engagement_group,

            COUNT(*) AS customer_months,

            SUM(churn_month_flag) AS churn_events,

            ROUND(
                (
                    SUM(churn_month_flag)::NUMERIC
                    /
                    NULLIF(COUNT(*), 0)
                ) * 100,
                2
            ) AS churn_rate_pct

        FROM analytics.monthly_usage_features

        WHERE prev_month_workouts IS NOT NULL

        GROUP BY
            CASE
                WHEN prev_month_workouts <= 1
                    THEN '0-1 workouts'
                ELSE '2+ workouts'
            END

        ORDER BY churn_rate_pct DESC;
    """

    connection = get_connection()

    try:

        with connection.cursor(
            cursor_factory=RealDictCursor
        ) as cursor:

            cursor.execute(query)

            return [
                dict(row)
                for row in cursor.fetchall()
            ]

    finally:

        connection.close()


# ============================================================
# FUNCTION 4:
# SUPPORT CONTACT VS CHURN
# ============================================================

def get_support_driver():

    query = """
        SELECT

            CASE
                WHEN support_contact_flag = 1
                    THEN 'Contacted Support'
                ELSE 'No Support Contact'
            END AS support_group,

            COUNT(*) AS customer_months,

            SUM(churn_month_flag) AS churn_events,

            ROUND(
                (
                    SUM(churn_month_flag)::NUMERIC
                    /
                    NULLIF(COUNT(*), 0)
                ) * 100,
                2
            ) AS churn_rate_pct

        FROM analytics.monthly_usage_features

        GROUP BY support_contact_flag

        ORDER BY churn_rate_pct DESC;
    """

    connection = get_connection()

    try:

        with connection.cursor(
            cursor_factory=RealDictCursor
        ) as cursor:

            cursor.execute(query)

            return [
                dict(row)
                for row in cursor.fetchall()
            ]

    finally:

        connection.close()


# ============================================================
# FUNCTION 5:
# ANNUAL RENEWAL RISK
# ============================================================

def get_annual_renewal_driver():

    query = """
        WITH annual_data AS (

            SELECT

                m.customer_id,
                m.churn_month_flag,

                (
                    (
                        EXTRACT(YEAR FROM m.month)
                        -
                        EXTRACT(YEAR FROM m.signup_month)
                    ) * 12

                    +

                    (
                        EXTRACT(MONTH FROM m.month)
                        -
                        EXTRACT(MONTH FROM m.signup_month)
                    )
                ) AS tenure_month

            FROM analytics.monthly_usage_features AS m

            INNER JOIN analytics.customer_features AS c
                ON m.customer_id = c.customer_id

            WHERE c.plan_type = 'annual'
        )

        SELECT

            CASE
                WHEN tenure_month BETWEEN 11 AND 12
                    THEN 'Renewal Period'
                ELSE 'Other Annual Months'
            END AS renewal_group,

            COUNT(*) AS customer_months,

            SUM(churn_month_flag) AS churn_events,

            ROUND(
                (
                    SUM(churn_month_flag)::NUMERIC
                    /
                    NULLIF(COUNT(*), 0)
                ) * 100,
                2
            ) AS churn_rate_pct

        FROM annual_data

        GROUP BY
            CASE
                WHEN tenure_month BETWEEN 11 AND 12
                    THEN 'Renewal Period'
                ELSE 'Other Annual Months'
            END

        ORDER BY churn_rate_pct DESC;
    """

    connection = get_connection()

    try:

        with connection.cursor(
            cursor_factory=RealDictCursor
        ) as cursor:

            cursor.execute(query)

            return [
                dict(row)
                for row in cursor.fetchall()
            ]

    finally:

        connection.close()


# ============================================================
# FUNCTION 6:
# CANCEL REASON SUMMARY
# ============================================================

def get_cancel_reasons():

    query = """
        SELECT

            cancel_reason,

            COUNT(*) AS churned_customers,

            ROUND(
                (
                    COUNT(*)::NUMERIC
                    /
                    NULLIF(
                        SUM(COUNT(*)) OVER (),
                        0
                    )
                ) * 100,
                2
            ) AS cancel_reason_pct

        FROM analytics.customer_features

        WHERE churn_flag = 1

          AND cancel_reason NOT IN (
              'not_applicable',
              'not_provided'
          )

          AND cancel_reason IS NOT NULL

        GROUP BY cancel_reason

        ORDER BY churned_customers DESC;
    """

    connection = get_connection()

    try:

        with connection.cursor(
            cursor_factory=RealDictCursor
        ) as cursor:

            cursor.execute(query)

            return [
                dict(row)
                for row in cursor.fetchall()
            ]

    finally:

        connection.close()


# ============================================================
# FUNCTION 7:
# GET ALL VERIFIED BUSINESS EVIDENCE
# ============================================================

def get_verified_evidence():

    evidence = {

        "overall_kpis":
            get_overall_kpis(),

        "latest_month_churn":
            get_latest_month_churn(),

        "recent_engagement":
            get_engagement_driver(),

        "support_contact":
            get_support_driver(),

        "annual_renewal":
            get_annual_renewal_driver(),

        "cancel_reasons":
            get_cancel_reasons()
    }

    return evidence


# ============================================================
# TEST SCRIPT
# ============================================================

if __name__ == "__main__":

    print(
        "\n=========================================="
    )

    print(
        "PELOTON VERIFIED ANALYTICS TEST"
    )

    print(
        "==========================================\n"
    )

    try:

        evidence = get_verified_evidence()

        print("1. OVERALL KPIs")
        print(evidence["overall_kpis"])

        print("\n2. LATEST MONTH CHURN")
        print(evidence["latest_month_churn"])

        print("\n3. RECENT ENGAGEMENT DRIVER")

        for row in evidence["recent_engagement"]:
            print(row)

        print("\n4. SUPPORT CONTACT DRIVER")

        for row in evidence["support_contact"]:
            print(row)

        print("\n5. ANNUAL RENEWAL DRIVER")

        for row in evidence["annual_renewal"]:
            print(row)

        print("\n6. CANCEL REASONS")

        for row in evidence["cancel_reasons"]:
            print(row)

        print(
            "\n------------------------------------------"
        )

        print(
            "VERIFIED ANALYTICS TEST PASSED"
        )

        print(
            "------------------------------------------"
        )

    except Exception as error:

        print(
            "\n------------------------------------------"
        )

        print(
            "VERIFIED ANALYTICS TEST FAILED"
        )

        print(
            "------------------------------------------"
        )

        print("\nError:")
        print(error)