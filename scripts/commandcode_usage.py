#!/usr/bin/env python3
# ╭──────────────────────────────────────────────────────────────────────────╮
# │                                                                          │
# │   C O M M A N D   C O D E   U S A G E                                    │
# │   the Command Code Go plan's limits from its own API                      │
# │                                                                          │
# │   github.com/andreumassanet/impasto                                      │
# │                                                                          │
# ╰──────────────────────────────────────────────────────────────────────────╯

"""Print, as JSON, the Command Code plan limits and credits.

Uses the authenticated user's API key from ~/.commandcode/auth.json, the same
token the CLI uses, so nothing extra has to be installed. Nothing is written
anywhere on this machine except the report on stdout.
"""

import json
import os
import sys
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

HOME = Path(os.path.expanduser("~"))
AUTH = HOME / ".commandcode" / "auth.json"
API = "https://api.commandcode.ai"


def fail(message=""):
    print(json.dumps({"available": False, "error": message}))
    sys.exit(0)


def auth_key():
    try:
        return json.loads(AUTH.read_text()).get("apiKey") or None
    except (OSError, ValueError, TypeError):
        return None


def get(path, key):
    request = Request(
        f"{API}{path}",
        headers={
            "Authorization": f"Bearer {key}",
            "User-Agent": "commandcode/1.82.1 (Command Code CLI)",
        },
    )
    with urlopen(request, timeout=15) as response:
        return json.load(response)


def window(item, observed):
    if not isinstance(item, dict):
        return None
    used = item.get("used")
    cap = item.get("cap")
    if not isinstance(used, (int, float)) or not isinstance(cap, (int, float)) or cap <= 0:
        return None
    resets = item.get("resetAt")
    if isinstance(resets, str):
        try:
            import calendar, time
            resets = int(calendar.timegm(time.strptime(resets[:19], "%Y-%m-%dT%H:%M:%S")))
        except (ValueError, TypeError):
            resets = observed
    return {
        "name": item.get("label") or "window",
        "minutes": int(cap),
        "used": max(0.0, min(1.0, used / cap)),
        "resets": resets if isinstance(resets, int) else observed,
    }


def main():
    key = auth_key()
    if not key:
        fail("missing apiKey")

    try:
        whoami = get("/alpha/whoami", key)
        credits = get("/alpha/billing/credits", key)
        subscription = get("/alpha/billing/subscriptions", key)
        if not whoami.get("success") and "user" not in whoami:
            fail("not authenticated")
        plan = (subscription.get("data") or {}).get("planId") or "Go"
        name = plan.replace("individual-", "").replace("-v1", "").title()

        period_start = (subscription.get("data") or {}).get("currentPeriodStart") or ""
        summary = get(f"/alpha/usage/summary?since={period_start}", key)
        try:
            import calendar, time
            observed = calendar.timegm(time.strptime(period_start[:19], "%Y-%m-%dT%H:%M:%S"))
        except (ValueError, TypeError):
            observed = int(time.time())

        credit_block = credits.get("credits") or {}
        limits_block = credits.get("windowLimits") or {}

        windows = []
        for key_name in ("fiveHour", "weekly"):
            item = limits_block.get(key_name)
            if not isinstance(item, dict):
                continue
            limit = window(item, observed)
            if limit:
                limit["name"] = "5 hours" if key_name == "fiveHour" else "Week"
                limit["minutes"] = item.get("resetAt") and 300 if key_name == "fiveHour" else 10080
                windows.append(limit)

        print(json.dumps({
            "available": True,
            "plan": name,
            "monthlyCredits": credit_block.get("monthlyCredits"),
            "purchasedCredits": credit_block.get("purchasedCredits"),
            "freeCredits": credit_block.get("freeCredits"),
            "creditsUsed": summary.get("totalMonthlyCredits"),
            "tokens": summary.get("totalTokens"),
            "requests": summary.get("totalCount"),
            "successRate": summary.get("successRate"),
            "periodStart": period_start,
            "periodEnd": (subscription.get("data") or {}).get("currentPeriodEnd"),
            "fiveHour": item if False else (windows[0] if len(windows) > 0 else None),
            "weekly": item if False else (windows[1] if len(windows) > 1 else None),
            "limits": windows,
            "observed": observed,
        }))
    except HTTPError as error:
        try:
            body = error.read().decode("utf-8")
        except (OSError, ValueError):
            body = ""
        fail(f"http {error.code}: {body}")
    except (URLError, OSError, ValueError, TypeError) as error:
        fail(str(error))


if __name__ == "__main__":
    main()
