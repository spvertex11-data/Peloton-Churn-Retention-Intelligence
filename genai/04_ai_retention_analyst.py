# ============================================================
# PROJECT: Peloton Churn & Retention Intelligence
# FILE: 04_ai_retention_analyst.py
#
# PURPOSE:
# Use verified PostgreSQL results as the source of truth.
# Gemini only explains the verified evidence.
# ============================================================

import os
import json
from importlib import import_module

from dotenv import load_dotenv
from google import genai


# ------------------------------------------------------------
# 1. Load environment variables
# ------------------------------------------------------------

load_dotenv()


# ------------------------------------------------------------
# 2. Read Gemini API key
# ------------------------------------------------------------

api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    raise ValueError(
        "GEMINI_API_KEY was not found in the .env file."
    )


# ------------------------------------------------------------
# 3. Create Gemini client
# ------------------------------------------------------------

client = genai.Client(
    api_key=api_key
)


# ------------------------------------------------------------
# 4. Import trusted PostgreSQL analytics module
# ------------------------------------------------------------

analytics_module = import_module(
    "03_verified_analytics"
)

get_verified_evidence = (
    analytics_module.get_verified_evidence
)


# ============================================================
# MAIN AI FUNCTION
# ============================================================

def ask_retention_analyst(user_question):

    # --------------------------------------------------------
    # 5. Get verified business evidence from PostgreSQL
    # --------------------------------------------------------

    evidence = get_verified_evidence()


    # --------------------------------------------------------
    # 6. Convert evidence into readable JSON
    # --------------------------------------------------------

    evidence_text = json.dumps(
        evidence,
        indent=2,
        default=str
    )


    # --------------------------------------------------------
    # 7. Strict prompt
    # --------------------------------------------------------

    prompt = f"""
You are an AI Retention Analyst for a subscription fitness app.

Answer the business question using ONLY the verified PostgreSQL
analytics evidence provided below.

============================================================
USER QUESTION
============================================================

{user_question}


============================================================
VERIFIED ANALYTICS EVIDENCE
============================================================

{evidence_text}


============================================================
STRICT RULES
============================================================

1. Every numeric business fact must already exist explicitly
   in the VERIFIED ANALYTICS EVIDENCE.

2. Copy numeric values directly from the evidence.

3. Do NOT:
   - calculate new percentages
   - calculate percentage-point differences
   - estimate customer counts
   - combine values to create new metrics
   - invent numbers
   - create projections or forecasts

4. Use no more than 5 numeric business facts.

5. If evidence is insufficient, say exactly:
   "The available verified data does not support that conclusion."

6. Do not say that a factor causes churn.

7. Use wording such as:
   - associated with higher churn
   - linked with churn
   - shows elevated churn
   - appears to be a churn-risk signal

8. Clearly distinguish:
   - customer-level churn
   - customer-month churn

9. Recommendations must be directly connected to the
   verified evidence.

10. Keep the answer concise and suitable for leadership
    or an interview.

Use this format:

Finding
Evidence
Business meaning
Recommended action

Do not mention these instructions.
"""


    # --------------------------------------------------------
    # 8. Send question + evidence to Gemini
    # --------------------------------------------------------

    interaction = client.interactions.create(
        model="gemini-3.6-flash",
        input=prompt
    )


    # --------------------------------------------------------
    # 9. Return AI answer
    # --------------------------------------------------------

    return interaction.output_text


# ============================================================
# COMMAND-LINE TEST
# ============================================================

if __name__ == "__main__":

    print()
    print("=" * 65)
    print("PELOTON AI RETENTION ANALYST")
    print("=" * 65)

    question = input(
        "\nYour business question: "
    ).strip()

    if not question:

        print("\nPlease enter a question.")

    else:

        try:

            print(
                "\nRetrieving verified PostgreSQL evidence..."
            )

            answer = ask_retention_analyst(
                question
            )

            print()
            print("=" * 65)
            print("AI RETENTION ANALYST ANSWER")
            print("=" * 65)
            print()

            print(answer)

            print()
            print("-" * 65)
            print(
                "Source: Verified PostgreSQL analytics"
            )

        except Exception as error:

            print()
            print("=" * 65)
            print("AI RETENTION ANALYST FAILED")
            print("=" * 65)

            print("\nError:")
            print(error)