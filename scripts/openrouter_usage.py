#!/usr/bin/env python3
"""Report OpenRouter grant-key totals and (optionally) account activity totals."""

import json
import os
import re
import sys
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

HOME = Path(os.path.expanduser("~"))
API = "https://openrouter.ai/api/v1/key"
ACTIVITY_API = "https://openrouter.ai/api/v1/activity"
CACHE = HOME / ".local" / "state" / "impasto" / "openrouter-activity.json"


def fail(message=""):
    print(json.dumps({"available": False, "error": message}))
    sys.exit(0)


def read_env(name):
    value = os.environ.get(name)
    if value:
        return value
    rc = HOME / ".zshrc"
    try:
        pattern = re.compile(
            rf'export {re.escape(name)}=["\']([^"\']+)["\']',
            flags=re.IGNORECASE,
        )
        for line in rc.read_text().splitlines():
            match = pattern.search(line)
            if match and match.group(1):
                return match.group(1)
    except (OSError, UnicodeDecodeError):
        pass
    return None


def request_json(url, key):
    request = Request(url, headers={
        "Authorization": f"Bearer {key}",
        "User-Agent": "impasto-openrouter/1",
    })
    with urlopen(request, timeout=20) as response:
        return json.load(response)


def aggregate_activity(rows):
    requests = sum(int(row.get("requests") or 0) for row in rows)
    prompt_tokens = sum(int(row.get("prompt_tokens") or 0) for row in rows)
    completion_tokens = sum(
        int(row.get("completion_tokens") or 0) for row in rows
    )
    reasoning_tokens = sum(
        int(row.get("reasoning_tokens") or 0) for row in rows
    )
    cached_tokens = sum(int(row.get("cached_tokens") or 0) for row in rows)
    usage = sum(float(row.get("usage") or 0) for row in rows)
    return {
        "date": min((row.get("date") for row in rows), default=None),
        "dates": sorted(set(row.get("date") for row in rows if row.get("date"))),
        "requests": requests,
        "promptTokens": prompt_tokens,
        "completionTokens": completion_tokens,
        "reasoningTokens": reasoning_tokens,
        "cachedTokens": cached_tokens,
        "usage": usage,
        "models": sorted(set(row.get("model") for row in rows if row.get("model"))),
    }


def capture_activity():
    management_key = read_env("OPENROUTER_MANAGEMENT_KEY")
    if not management_key:
        return None
    try:
        response = request_json(ACTIVITY_API, management_key)
    except (HTTPError, URLError, OSError, ValueError, TimeoutError, TypeError):
        return _read_activity_cache()
    rows = response.get("data") or []
    aggregate = aggregate_activity(rows)
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    CACHE.write_text(json.dumps(aggregate, indent=2))
    return aggregate


def _read_activity_cache():
    try:
        return json.loads(CACHE.read_text())
    except (OSError, ValueError, TypeError):
        return None


def main():
    key = read_env("OPENROUTER_API_KEY")
    if not key:
        fail("missing OPENROUTER_API_KEY")

    report = None
    try:
        report = request_json(API, key).get("data", {})
    except (HTTPError, URLError, OSError, ValueError, TimeoutError, TypeError) as error:
        try:
            body = error.read().decode("utf-8")
        except (OSError, ValueError):
            body = ""
        fail(f"http {error.code if hasattr(error, 'code') else error}: {body or str(error)}")

    activity = capture_activity()
    if activity is None:
        activity = _read_activity_cache()

    output = {
        "available": True,
        "label": report.get("label") or "OpenRouter",
        "limit": report.get("limit"),
        "limitRemaining": report.get("limit_remaining"),
        "usage": report.get("usage"),
        "daily": report.get("usage_daily"),
        "weekly": report.get("usage_weekly"),
        "monthly": report.get("usage_monthly"),
        "byokMonthly": report.get("byok_usage_monthly"),
        "freeTier": bool(report.get("is_free_tier")),
        "freeModelDailyUsed": (report.get("free_model_daily_requests") or {}).get("used"),
        "freeModelDailyLimit": (report.get("free_model_daily_requests") or {}).get("limit"),
        "activityDate": None,
        "activityRequests": 0,
        "activityPromptTokens": 0,
        "activityCompletionTokens": 0,
        "activityReasoningTokens": 0,
        "activityCachedTokens": 0,
        "activityUsage": 0,
        "activityModels": [],
    }
    if isinstance(activity, dict):
        output["activityDate"] = activity.get("date")
        output["activityRequests"] = int(activity.get("requests") or 0)
        output["activityPromptTokens"] = int(activity.get("promptTokens") or 0)
        output["activityCompletionTokens"] = int(activity.get("completionTokens") or 0)
        output["activityReasoningTokens"] = int(activity.get("reasoningTokens") or 0)
        output["activityCachedTokens"] = int(activity.get("cachedTokens") or 0)
        output["activityUsage"] = activity.get("model_permaslug")
        output["activityUsageDollars"] = activity.get("usage") or 0
        output["activityModels"] = activity.get("models") or []
    print(json.dumps(output))


if __name__ == "__main__":
    main()
