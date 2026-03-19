import os
from openai import OpenAI

client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])

issue_number = os.environ.get("ISSUE_NUMBER", "")
issue_title = os.environ.get("ISSUE_TITLE", "")
issue_body = os.environ.get("ISSUE_BODY", "")
repo_name = os.environ.get("REPO_NAME", "")

with open("README.md", "r", encoding="utf-8") as f:
    current_readme = f.read()

user_input = f"""
Repository:
{repo_name}

Task:
Update README.md based on the GitHub issue below.

Rules:
- Return the FULL updated README.md content only.
- Do not include explanations outside the README body.
- Keep existing useful sections unless the issue clearly requires changes.
- Make the README practical and accurate for this repository.
- If the issue is too vague, make only minimal safe README improvements.

Issue number:
{issue_number}

Issue title:
{issue_title}

Issue body:
{issue_body}

Current README.md:
{current_readme}
"""

response = client.responses.create(
    prompt={
        "id": os.environ["OPENAI_PROMPT_ID"],
        "version": "1",
        "variables": {
            "input": user_input
        }
    }
)

print(response.output_text)
