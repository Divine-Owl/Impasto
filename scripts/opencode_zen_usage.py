#!/usr/bin/env python3
# ╭──────────────────────────────────────────────────────────────────────────╮
# │                                                                          │
# │   O P E N C O D E   Z E N   U S A G E                                    │
# │   today's free-model requests, from OpenCode's own local statistics      │
# │                                                                          │
# │   github.com/andreumassanet/impasto                                      │
# │                                                                          │
# ╰──────────────────────────────────────────────────────────────────────────╯

"""Print, as JSON, today's OpenCode Zen free-model request counts.

OpenCode Zen's free models are served through the OpenCode client itself and
there is no public usage endpoint to read them from. What is local and exact
is what the client recorded: `opencode stats` reads its own session database.
Only requests that went to provider `opencode` on a free model are counted, so
paid Console models and other providers do not show up here.

The result is cached under `~/.local/state/impasto/` so a failing or slow
`opencode stats` leaves the last known count on screen instead of a blank.
"""

import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

HOME = Path(os.path.expanduser("~"))
CACHE = HOME / ".local" / "state" / "impasto" / "opencode-zen-usage.json"

# Free models whose id does not end in `-free`: OpenCode's stealth models.
STEALTH_FREE = {"big-pickle", "space-bunny"}


def fail(message=""):
    print(json.dumps({"available": False, "error": message}))
    sys.exit(0)


def is_free(model_id):
    return model_id.endswith("-free") or model_id in STEALTH_FREE


def read_cache():
    try:
        cached = json.loads(CACHE.read_text())
    except (OSError, ValueError, TypeError):
        return None
    if not isinstance(cached, dict) or cached.get("available") is not True:
        return None
    cached["stale"] = True
    return cached


def write_cache(report):
    try:
        CACHE.parent.mkdir(parents=True, exist_ok=True)
        CACHE.write_text(json.dumps(report))
    except OSError:
        pass


def stats_json(binary):
    result = subprocess.run(
        [binary, "stats", "--json", "--days", "0", "--models", "--limit", "200"],
        capture_output=True,
        text=True,
        timeout=30,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "opencode stats failed")
    return json.loads(result.stdout)


def main():
    binary = shutil.which("opencode") or str(HOME / ".local" / "bin" / "opencode")
    if not os.path.exists(binary):
        cached = read_cache()
        if cached:
            print(json.dumps(cached))
            return
        fail("opencode not found")

    try:
        report = stats_json(binary)
    except Exception as error:  # noqa: BLE001 - any failure falls back to cache
        cached = read_cache()
        if cached:
            print(json.dumps(cached))
            return
        fail(str(error))

    models = {}
    for entry in report.get("models") or []:
        model = entry.get("model") or {}
        if model.get("providerID") != "opencode":
            continue
        model_id = model.get("id") or ""
        if not is_free(model_id):
            continue
        steps = int(entry.get("steps") or 0)
        if steps <= 0:
            continue
        models[model_id] = models.get(model_id, 0) + steps

    ranked = sorted(models.items(), key=lambda item: (-item[1], item[0]))
    result = {
        "available": True,
        "requests": sum(models.values()),
        "models": [{"id": model_id, "steps": steps} for model_id, steps in ranked],
        "updated": int(time.time()),
    }
    write_cache(result)
    print(json.dumps(result))


if __name__ == "__main__":
    main()
