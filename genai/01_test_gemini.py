# ============================================================
# PROJECT: Peloton Churn & Retention Intelligence
# FILE: 01_test_gemini.py
#
# PURPOSE:
# Test Gemini connection using the current Interactions API.
# ============================================================

import os

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


# ------------------------------------------------------------
# 3. Validate API key
# ------------------------------------------------------------

if not api_key:
    raise ValueError(
        "GEMINI_API_KEY was not found in the .env file."
    )

print("Gemini API key loaded successfully.")


# ------------------------------------------------------------
# 4. Create Gemini client
# ------------------------------------------------------------

client = genai.Client(
    api_key=api_key
)


# ------------------------------------------------------------
# 5. Test Gemini using Interactions API
# ------------------------------------------------------------

try:

    interaction = client.interactions.create(
        model="gemini-3.6-flash",
        input=(
            "Reply with only this sentence: "
            "Peloton AI Retention Analyst connection successful."
        )
    )

    print("\nGemini Response:")
    print(interaction.output_text)

    print("\n----------------------------------------")
    print("GEMINI CONNECTION TEST PASSED")
    print("----------------------------------------")


# ------------------------------------------------------------
# 6. Print clear error if test fails
# ------------------------------------------------------------

except Exception as error:

    print("\n----------------------------------------")
    print("GEMINI CONNECTION TEST FAILED")
    print("----------------------------------------")

    print("\nError:")
    print(error)