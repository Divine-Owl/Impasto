#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path
from urllib.request import urlopen

ROOT = Path("/proc")
MATCH = " qs "

def ps_rss():
    for pid in sorted(ROOT.iterdir()):
        try:
            name = pid.name
            if not name.isdigit():
                continue
            cmdline = (pid / "cmdline").read_bytes().replace(b"\0", b" ").decode("utf-8", "ignore").strip()
            if cmdline.endswith("qs -d") or cmdline.endswith("/qs -d") or " qs -d " in cmdline or cmdline == "qs -d":
                statm = (pid / "statm").read_text().split()
                pages = int(statm[1])  # RSS pages
                return pid.name, pages * os.sysconf("SC_PAGE_SIZE")
        except (OSError, IndexError, ValueError):
            continue
    return None, 0

def cgroup_max(pid):
    try:
        cg = (Path("/proc") / pid / "cgroup").read_text().strip()
        for line in cg.splitlines():
            if "::" not in line:
                continue
            path = line.split("::", 1)[1].strip().lstrip("/")
            maxp = Path("/sys/fs/cgroup") / path / "memory.max"
            value = maxp.read_text().strip()
            if value == "max":
                return 0
            return int(value)
    except (OSError, ValueError, IndexError):
        return 0

pid, rss = ps_rss()
if rss <= 0:
    print(json.dumps({"available": False, "error": "qs not running"}))
    sys.exit(0)
max_bytes = cgroup_max(pid)
print(json.dumps({
    "available": True,
    "pid": int(pid) if pid else 0,
    "rssKB": round(rss / 1024),
    "rssMB": round(rss / (1024 * 1024), 1),
    "maxKB": round(max_bytes / 1024),
    "maxMB": round(max_bytes / (1024 * 1024), 1),
}))
