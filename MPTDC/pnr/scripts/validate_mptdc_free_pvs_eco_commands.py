#!/usr/bin/env python3
"""Validate one reviewed, routing-only command for the MPTDC free PnR ECO."""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
from pathlib import Path
from typing import Optional


ROUTE_PATTERN = re.compile(
    r"^(mptdc_ckpt_route_selected_nets(?:_route_design|_detail_only|_legacy)?)"
    r"\s+\{([^{}]+)\}$"
)
NET_PATTERN = re.compile(r"^[A-Za-z0-9_./:<>\[\]-]+$")


class CommandContractError(RuntimeError):
    pass


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate(path: Path) -> tuple[str, list[str]]:
    commands = []
    for number, raw_line in enumerate(path.read_text(errors="strict").splitlines(), start=1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        commands.append((number, line))

    if len(commands) != 1:
        raise CommandContractError(
            f"expected exactly one routing helper command, found {len(commands)}"
        )

    number, command = commands[0]
    match = ROUTE_PATTERN.fullmatch(command)
    if not match:
        raise CommandContractError(
            f"line {number} is not an allowed selected-net routing helper: {command}"
        )

    nets = match.group(2).split()
    if not nets:
        raise CommandContractError(f"line {number} has an empty net set")
    if len(nets) != len(set(nets)):
        raise CommandContractError(f"line {number} contains duplicate net names")
    invalid = [net for net in nets if not NET_PATTERN.fullmatch(net)]
    if invalid:
        raise CommandContractError(
            f"line {number} contains invalid net names: {','.join(invalid)}"
        )

    return match.group(1), nets


def write_report(
    report: Path,
    source: Path,
    expected_sha: str,
    status: str,
    helper: str = "MISSING",
    nets: Optional[list[str]] = None,
    error: Optional[str] = None,
) -> None:
    actual_sha = sha256(source)
    rows = [
        "STEP=MPTDC_FREE_TRIAL_PVS_ECO_COMMAND_VALIDATION",
        f"COMMAND_FILE={source}",
        f"COMMAND_FILE_SHA256={actual_sha}",
        f"EXPECTED_COMMAND_FILE_SHA256={expected_sha}",
        f"ROUTING_HELPER={helper}",
        f"ROUTING_COMMAND_COUNT={1 if status == 'PASS' else 0}",
        f"TARGET_NET_COUNT={len(nets or [])}",
        f"TARGET_NET_SET={','.join(nets or []) if nets else 'NONE'}",
    ]
    if error:
        rows.append(f"ERROR={error}")
    rows.append(f"COMMAND_CONTRACT_STATUS={status}")
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text("\n".join(rows) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--commands-file", required=True, type=Path)
    parser.add_argument("--expected-sha256", required=True)
    parser.add_argument("--normalized-out", required=True, type=Path)
    parser.add_argument("--report", required=True, type=Path)
    args = parser.parse_args()

    source = args.commands_file.expanduser().resolve()
    report = args.report.expanduser().resolve()
    normalized = args.normalized_out.expanduser().resolve()
    expected_sha = args.expected_sha256.lower()

    if not source.is_file() or source.stat().st_size == 0:
        print(f"ERROR: commands file missing or empty: {source}", file=sys.stderr)
        return 2
    if not re.fullmatch(r"[0-9a-f]{64}", expected_sha):
        print("ERROR: --expected-sha256 must be a lowercase SHA256", file=sys.stderr)
        return 2

    try:
        actual_sha = sha256(source)
        if actual_sha != expected_sha:
            raise CommandContractError(
                f"command hash mismatch: expected={expected_sha} actual={actual_sha}"
            )
        helper, nets = validate(source)
        normalized.parent.mkdir(parents=True, exist_ok=True)
        normalized.write_text(f"{helper} {{{' '.join(nets)}}}\n")
        write_report(report, source, expected_sha, "PASS", helper, nets)
        print(report.read_text(), end="")
        return 0
    except (CommandContractError, UnicodeError) as exc:
        write_report(report, source, expected_sha, "FAIL", error=str(exc))
        print(report.read_text(), end="")
        return 1


if __name__ == "__main__":
    sys.exit(main())
