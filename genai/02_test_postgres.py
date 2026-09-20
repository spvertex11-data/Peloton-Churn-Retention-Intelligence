# ============================================================
# PROJECT: Peloton Churn & Retention Intelligence
# FILE: 02_test_postgres.py
#
# PURPOSE:
# Test Python connection to PostgreSQL and confirm
# that the churn project tables are accessible.
# ============================================================

import os
import psycopg2

from dotenv import load_dotenv


# ------------------------------------------------------------
# 1. Load environment variables from .env
# ------------------------------------------------------------

load_dotenv()


# ------------------------------------------------------------
# 2. Read PostgreSQL connection details
# ------------------------------------------------------------

db_host = os.getenv("DB_HOST")
db_port = os.getenv("DB_PORT")
db_name = os.getenv("DB_NAME")
db_user = os.getenv("DB_USER")
db_password = os.getenv("DB_PASSWORD")


# ------------------------------------------------------------
# 3. Validate required settings
# ------------------------------------------------------------

required_values = {
    "DB_HOST": db_host,
    "DB_PORT": db_port,
    "DB_NAME": db_name,
    "DB_USER": db_user,
    "DB_PASSWORD": db_password
}

for key, value in required_values.items():

    if not value:
        raise ValueError(
            f"{key} was not found in the .env file."
        )


# ------------------------------------------------------------
# 4. Connect to PostgreSQL
# ------------------------------------------------------------

try:

    connection = psycopg2.connect(
        host=db_host,
        port=db_port,
        dbname=db_name,
        user=db_user,
        password=db_password
    )

    print("PostgreSQL connection successful.")


    # --------------------------------------------------------
    # 5. Create cursor
    # --------------------------------------------------------

    cursor = connection.cursor()


    # --------------------------------------------------------
    # 6. Check customer_features table
    # --------------------------------------------------------

    cursor.execute(
        """
        SELECT COUNT(*)
        FROM analytics.customer_features;
        """
    )

    customer_count = cursor.fetchone()[0]

    print(
        "customer_features rows:",
        customer_count
    )


    # --------------------------------------------------------
    # 7. Check monthly_usage_features table
    # --------------------------------------------------------

    cursor.execute(
        """
        SELECT COUNT(*)
        FROM analytics.monthly_usage_features;
        """
    )

    usage_count = cursor.fetchone()[0]

    print(
        "monthly_usage_features rows:",
        usage_count
    )


    # --------------------------------------------------------
    # 8. Check monthly churn view
    # --------------------------------------------------------

    cursor.execute(
        """
        SELECT COUNT(*)
        FROM analytics.monthly_churn_summary;
        """
    )

    month_count = cursor.fetchone()[0]

    print(
        "monthly_churn_summary rows:",
        month_count
    )


    print("\n----------------------------------------")
    print("POSTGRESQL CONNECTION TEST PASSED")
    print("----------------------------------------")


# ------------------------------------------------------------
# 9. Show error clearly if connection fails
# ------------------------------------------------------------

except Exception as error:

    print("\n----------------------------------------")
    print("POSTGRESQL CONNECTION TEST FAILED")
    print("----------------------------------------")

    print("\nError:")
    print(error)


# ------------------------------------------------------------
# 10. Close connection safely
# ------------------------------------------------------------

finally:

    try:
        cursor.close()
        connection.close()

        print("\nDatabase connection closed.")

    except:
        pass