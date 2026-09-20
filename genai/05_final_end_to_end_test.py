# ============================================================
# PROJECT: Peloton Churn & Retention Intelligence
# FILE: 05_final_end_to_end_test.py
#
# PURPOSE:
#
# PostgreSQL Verified Evidence
#          ↓
# Gemini Business Answer
#          ↓
# Numeric Validation Guard
#
# The validator checks meaningful numeric business claims
# made by Gemini against verified PostgreSQL evidence.
# ============================================================

import re
from decimal import Decimal
from importlib import import_module


# ------------------------------------------------------------
# 1. Import verified analytics
# ------------------------------------------------------------

analytics_module = import_module(
    "03_verified_analytics"
)

get_verified_evidence = (
    analytics_module.get_verified_evidence
)


# ------------------------------------------------------------
# 2. Import AI analyst
# ------------------------------------------------------------

ai_module = import_module(
    "04_ai_retention_analyst"
)

ask_retention_analyst = (
    ai_module.ask_retention_analyst
)


# ============================================================
# FUNCTION 1:
# COLLECT VERIFIED NUMERIC VALUES
# ============================================================

def collect_verified_numbers(data):

    """
    Recursively collect real numeric values from
    PostgreSQL evidence.
    """

    numbers = set()


    if isinstance(data, dict):

        for value in data.values():

            numbers.update(
                collect_verified_numbers(value)
            )


    elif isinstance(data, (list, tuple)):

        for value in data:

            numbers.update(
                collect_verified_numbers(value)
            )


    elif isinstance(
        data,
        (int, float, Decimal)
    ):

        value = float(data)

        numbers.add(
            round(value, 4)
        )

        # Also allow common display rounding.
        numbers.add(
            round(value, 2)
        )

        numbers.add(
            round(value, 1)
        )


    return numbers


# ============================================================
# FUNCTION 2:
# EXTRACT BUSINESS NUMBERS FROM GEMINI ANSWER
# ============================================================

def extract_business_numbers(answer):

    """
    Extract only meaningful business numbers.

    Captures:
    - percentages
    - decimal metrics with business units
    - customer/subscriber/member counts

    Ignores:
    - headings like 1, 2, 3
    - years
    - random standalone integers
    """

    results = []


    # --------------------------------------------------------
    # A. Percentage values
    # Example:
    # 9.87%
    # --------------------------------------------------------

    percentage_pattern = (
        r"(?<![\d.-])"
        r"(\d+(?:\.\d+)?)"
        r"\s*%"
    )

    for match in re.finditer(
        percentage_pattern,
        answer
    ):

        results.append({
            "value": float(match.group(1)),
            "text": match.group(0),
            "type": "percentage"
        })


    # --------------------------------------------------------
    # B. Numeric values followed by business units
    #
    # Examples:
    # 6.48 months
    # 4.81 workouts
    # 4200 customers
    # --------------------------------------------------------

    business_unit_pattern = (
        r"(?<![\d.-])"
        r"(\d+(?:\.\d+)?)"
        r"\s+"
        r"(customers?|subscribers?|members?|"
        r"customer-months?|months?|workouts?|"
        r"tickets?|events?|classes?)\b"
    )

    for match in re.finditer(
        business_unit_pattern,
        answer,
        flags=re.IGNORECASE
    ):

        value = float(
            match.group(1)
        )

        # Ignore year-like values if Gemini somehow
        # writes something such as 2025 customers.
        if 1900 <= value <= 2100:
            continue

        results.append({
            "value": value,
            "text": match.group(0),
            "type": "business_metric"
        })


    # --------------------------------------------------------
    # Remove duplicate claims
    # --------------------------------------------------------

    unique_results = []

    seen = set()

    for item in results:

        key = (
            round(item["value"], 4),
            item["type"]
        )

        if key not in seen:

            seen.add(key)
            unique_results.append(item)


    return unique_results


# ============================================================
# FUNCTION 3:
# VERIFY ONE NUMBER
# ============================================================

def number_is_verified(
    number,
    verified_numbers
):

    """
    Exact or normal display-rounded values are accepted.
    """

    candidates = {
        round(number, 4),
        round(number, 2),
        round(number, 1)
    }


    for candidate in candidates:

        if candidate in verified_numbers:
            return True


    return False


# ============================================================
# FUNCTION 4:
# VALIDATE GEMINI ANSWER
# ============================================================

def validate_answer(
    answer,
    evidence
):

    verified_numbers = (
        collect_verified_numbers(
            evidence
        )
    )


    business_numbers = (
        extract_business_numbers(
            answer
        )
    )


    unsupported_numbers = []


    for item in business_numbers:

        if not number_is_verified(
            item["value"],
            verified_numbers
        ):

            unsupported_numbers.append(
                item
            )


    status = (
        "PASS"
        if not unsupported_numbers
        else "WARNING"
    )


    return {
        "status": status,
        "numbers_checked": business_numbers,
        "unsupported_numbers": unsupported_numbers
    }


# ============================================================
# FINAL END-TO-END TEST
# ============================================================

if __name__ == "__main__":

    print()
    print("=" * 70)
    print("PELOTON AI RETENTION ANALYST")
    print("FINAL END-TO-END TEST")
    print("=" * 70)


    # --------------------------------------------------------
    # Business question
    # --------------------------------------------------------

    question = (
        "Why are subscribers churning, "
        "and what should the business do?"
    )


    print("\nBUSINESS QUESTION:")
    print(question)


    try:

        # ----------------------------------------------------
        # STEP 1:
        # Retrieve verified PostgreSQL evidence
        # ----------------------------------------------------

        print()
        print(
            "[1/3] Retrieving verified PostgreSQL evidence..."
        )

        evidence = get_verified_evidence()

        print(
            "Verified evidence retrieved successfully."
        )


        # ----------------------------------------------------
        # STEP 2:
        # Ask Gemini
        # ----------------------------------------------------

        print()
        print(
            "[2/3] Asking Gemini Retention Analyst..."
        )

        answer = ask_retention_analyst(
            question
        )


        print()
        print("=" * 70)
        print("AI RETENTION ANALYST ANSWER")
        print("=" * 70)
        print()

        print(answer)


        # ----------------------------------------------------
        # STEP 3:
        # Validate Gemini numeric claims
        # ----------------------------------------------------

        print()
        print(
            "[3/3] Validating numeric claims..."
        )


        validation = validate_answer(
            answer,
            evidence
        )


        print()
        print("=" * 70)
        print("VALIDATION RESULT")
        print("=" * 70)


        print(
            "\nStatus:",
            validation["status"]
        )


        print(
            "\nBusiness numbers checked:"
        )


        if validation["numbers_checked"]:

            for item in validation[
                "numbers_checked"
            ]:

                print(
                    f"- {item['text']}"
                )

        else:

            print(
                "No numeric business claims detected."
            )


        # ----------------------------------------------------
        # Unsupported claims
        # ----------------------------------------------------

        if validation[
            "unsupported_numbers"
        ]:

            print()
            print(
                "Unsupported numeric claims:"
            )

            for item in validation[
                "unsupported_numbers"
            ]:

                print(
                    f"- {item['text']}"
                )


            print()
            print(
                "WARNING: Gemini introduced one or more "
                "numbers that are not directly supported "
                "by the verified PostgreSQL evidence."
            )


        else:

            print()
            print(
                "No unsupported numeric claims detected."
            )


        # ----------------------------------------------------
        # Final result
        # ----------------------------------------------------

        print()
        print("-" * 70)


        if validation["status"] == "PASS":

            print(
                "FINAL END-TO-END TEST PASSED"
            )

            print(
                "PostgreSQL → Gemini → Validation working."
            )

        else:

            print(
                "FINAL TEST COMPLETED WITH WARNING"
            )

            print(
                "Review unsupported claims before using "
                "the AI response."
            )


        print("-" * 70)


    except Exception as error:

        print()
        print("=" * 70)
        print("FINAL END-TO-END TEST FAILED")
        print("=" * 70)

        print("\nError:")
        print(error)