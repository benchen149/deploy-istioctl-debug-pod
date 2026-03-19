import os
from openai import OpenAI

client = OpenAI(api_key=os.environ["OPENAI_API_KEY"])

issue_title = os.environ.get("ISSUE_TITLE", "")
issue_body = os.environ.get("ISSUE_BODY", "")
repo_name = os.environ.get("REPO_NAME", "")

user_input = f"""
Repository:
{repo_name}

Task:
Analyze this GitHub issue and provide an implementation plan.

Issue title:
{issue_title}

Issue body:
{issue_body}

Output:
1. Summary
2. Implementation plan
3. Files to modify
4. Validation steps
5. README update suggestions
6. Risks and rollback notes
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
