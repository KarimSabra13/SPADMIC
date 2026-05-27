#!/usr/bin/env python3
"""Extract classified timing paths from checked-in Genus path reports."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from parse_genus_summary import parse_paths  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", type=Path, help="Genus timing report to parse")
    parser.add_argument("--group", help="only show this timing group")
    parser.add_argument("--bucket", help="only show this classification bucket")
    parser.add_argument("--contains", help="only show paths containing this substring")
    parser.add_argument("--limit", type=int, default=20)
    args = parser.parse_args()

    paths = parse_paths(args.report)
    shown = 0
    print("| Path | Slack (ps) | Group | Bucket | Startpoint | Endpoint |")
    print("|---:|---:|---|---|---|---|")
    for path in paths:
        haystack = " ".join(str(v) for v in path.values())
        if args.group and path.get("group") != args.group:
            continue
        if args.bucket and path.get("bucket") != args.bucket:
            continue
        if args.contains and args.contains not in haystack:
            continue
        print(
            f"| {path.get('path')} | {path.get('slack_ps')} | `{path.get('group', '')}` | "
            f"`{path.get('bucket', '')}` | `{path.get('startpoint', '')}` | `{path.get('endpoint', '')}` |"
        )
        shown += 1
        if shown >= args.limit:
            break

    if shown == 0:
        print("| | | | | No matching paths | |")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
