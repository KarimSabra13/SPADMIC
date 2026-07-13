#!/usr/bin/env python3
"""Classify the fresh pre-CTS PG packet-core Innovus candidate."""

from __future__ import annotations

import argparse
import hashlib
import re
from pathlib import Path


EXPECTED_AREAS = (
    "515.200 126.160 518.560 126.960",
    "515.200 135.120 518.560 135.920",
    "515.200 278.480 518.560 279.280",
)
EXPECTED_PRE_CTS_DANGLING_COUNT = 156


def read_kv(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.is_file():
        return values
    for raw in path.read_text(errors="replace").splitlines():
        if "=" not in raw:
            continue
        key, value = raw.split("=", 1)
        values[key.strip()] = value.strip()
    return values


def integer(values: dict[str, str], key: str, errors: list[str]) -> int | None:
    raw = values.get(key)
    try:
        return int(raw) if raw is not None else None
    except ValueError:
        errors.append(f"{key}={raw} is not an integer")
        return None


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def report_value(value: object) -> str:
    return str(value).replace("\n", " ").replace("\r", " ")


def verification_count(path: Path, *, connectivity: bool) -> int | None:
    if not path.is_file():
        return None
    text = path.read_text(errors="replace")
    patterns = [
        r"Verification\s+Complete\s*:\s*(\d+)\s+Viols?",
        r"Total\s+number\s+of\s+DRC\s+violations\s*=\s*(\d+)",
    ]
    if connectivity:
        patterns.insert(0, r"(\d+)\s+Problem\(s\)\s+\(IMPVFC-")
    counts: list[int] = []
    for pattern in patterns:
        counts.extend(int(match) for match in re.findall(pattern, text, flags=re.IGNORECASE))
    if counts:
        return counts[-1]
    if re.search(r"Found\s+no\s+problems\s+or\s+warnings", text, flags=re.IGNORECASE):
        return 0
    if not connectivity and re.search(r"No\s+(?:DRC\s+)?violations?\s+found", text, flags=re.IGNORECASE):
        return 0
    return None


def connectivity_problem_counts(path: Path) -> tuple[int, int]:
    if not path.is_file():
        return 0, 0
    dangling = 0
    other = 0
    pattern = re.compile(
        r"(\d+)\s+Problem\(s\)\s+\(IMPVFC-(\d+)\):",
        flags=re.IGNORECASE,
    )
    for count_text, code in pattern.findall(path.read_text(errors="replace")):
        count = int(count_text)
        if code == "94":
            dangling += count
        else:
            other += count
    return dangling, other


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--block-root", type=Path, required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()

    reports = args.block_root / "reports"
    run_root = args.block_root.parents[1]
    manifest_path = run_root / "run_manifest.txt"
    ooc_path = reports / "ooc_harden_status.rpt"
    stack_path = reports / "PG_DIRECT_VIA_STACKS.rpt"
    pre_conn_path = reports / "PG_DIRECT_VIA_PRE_CTS_CONNECTIVITY.rpt"
    pre_drc_path = reports / "PG_DIRECT_VIA_PRE_CTS_DRC.rpt"
    pre_milestone_path = reports / "PG_DIRECT_VIA_PRE_CTS_MILESTONE.rpt"
    post_filler_conn_path = reports / "PG_POST_FILLER_CONNECTIVITY.rpt"
    post_filler_drc_path = reports / "PG_POST_FILLER_DRC.rpt"
    marker_path = reports / "DRC_MARKER_CLASSIFICATION.rpt"
    gate_path = reports / "canonical_tx_ooc_gate.rpt"
    final_drc_path = reports / "verify_drc_post_route.rpt"
    final_regular_path = reports / "verify_connectivity_regular.rpt"
    final_pg_path = reports / "verify_connectivity_pg.rpt"
    args.report.parent.mkdir(parents=True, exist_ok=True)

    required = (manifest_path, ooc_path, stack_path)
    missing = [path for path in required if not path.is_file()]
    if missing:
        args.report.write_text(
            "LABEL=SPADMIC_TX_PACKET_PREROUTE_PG_CANDIDATE_ANALYSIS\n"
            "POLICY=FRESH_FULL_FLOW_CANDIDATE_NO_AUTOMATIC_PVS_STAGING_OR_PVS\n"
            "STATUS=FAIL\n"
            "RESULT=MISSING_REQUIRED_INPUTS\n"
            f"MISSING_INPUTS={' '.join(str(path) for path in missing)}\n"
        )
        return 8

    errors: list[str] = []
    manifest = read_kv(manifest_path)
    ooc = read_kv(ooc_path)
    stack = read_kv(stack_path)
    pre_milestone = read_kv(pre_milestone_path)
    marker = read_kv(marker_path)
    gate = read_kv(gate_path)
    post_filler_restitch = manifest.get("SPADMIC_OOC_ENABLE_POST_FILLER_PG_RESTITCH") == "1"

    expected_manifest = {
        "SPADMIC_OOC_ENABLE_PRE_CTS_PG_DIRECT_VIAS": "1",
        "SPADMIC_OOC_PG_DIRECT_VIA_AREAS": " ".join(f"{{{area}}}" for area in EXPECTED_AREAS),
        "SPADMIC_OOC_ENABLE_PG_SROUTE": "1",
        "SPADMIC_OOC_SIGNAL_BOTTOM_LAYER": "MET1",
        "SPADMIC_OOC_SIGNAL_TOP_LAYER": "MET3",
    }
    for key, expected in expected_manifest.items():
        if manifest.get(key) != expected:
            errors.append(f"manifest_{key}={manifest.get(key, 'MISSING')} expected={expected}")
    if post_filler_restitch:
        expected_restitch_manifest = {
            "SPADMIC_OOC_PRE_CTS_EXPECTED_DANGLING_COUNT": str(
                EXPECTED_PRE_CTS_DANGLING_COUNT
            ),
            "SPADMIC_OOC_ENABLE_POST_FILLER_PG_RESTITCH": "1",
        }
        for key, expected in expected_restitch_manifest.items():
            if manifest.get(key) != expected:
                errors.append(
                    f"manifest_{key}={manifest.get(key, 'MISSING')} expected={expected}"
                )
        if not pre_milestone_path.is_file():
            errors.append(f"missing pre-CTS milestone report {pre_milestone_path}")

    expected_stack = {
        "LABEL": "SPADMIC_OOC_PRE_CTS_PG_DIRECT_VIAS",
        "POLICY": "AFTER_PLACE_BEFORE_CTS_BOUNDED_1X1_STACKS",
        "TARGET_AREA_COUNT": "3",
        "BOTTOM_LAYER": "MET1",
        "TOP_LAYER": "METTP",
        "VIA_ROWS": "1",
        "VIA_COLUMNS": "1",
    }
    for key, expected in expected_stack.items():
        if stack.get(key) != expected:
            errors.append(f"stack_{key}={stack.get(key, 'MISSING')} expected={expected}")
    for row, expected in enumerate(EXPECTED_AREAS, start=1):
        if stack.get(f"ROW_{row}_AREA") != expected:
            errors.append(
                f"stack_ROW_{row}_AREA={stack.get(f'ROW_{row}_AREA', 'MISSING')} expected={expected}"
            )
        command = stack.get(f"TRY_ROW_{row}_MET1_TO_METTP_STACK", "")
        for token in (
            "editPowerVia -add_vias 1",
            "-bottom_layer MET1 -top_layer METTP",
            "-exclude_stack_vias 0",
            "-via_rows 1 -via_columns 1",
        ):
            if token not in command:
                errors.append(f"stack_ROW_{row}_COMMAND missing {token}")

    command_pass = integer(stack, "COMMAND_PASS_COUNT", errors)
    command_fail = integer(stack, "COMMAND_FAIL_COUNT", errors)
    command_clean = (
        stack.get("STATUS") == "PASS"
        and stack.get("VIA_GEN_AREA_ONLY_STATUS") == "PASS"
        and stack.get("VIA_GEN_AREA_ONLY_RESET_STATUS") == "PASS"
        and command_pass == 5
        and command_fail == 0
    )
    if command_pass is not None and command_fail is not None and command_pass + command_fail != 5:
        errors.append(f"stack command accounting {command_pass}+{command_fail} expected=5")

    if ooc.get("PG_ROUTE_STAGE") != "PRE_CTS":
        errors.append(f"ooc_PG_ROUTE_STAGE={ooc.get('PG_ROUTE_STAGE', 'MISSING')} expected=PRE_CTS")
    if ooc.get("PG_DIRECT_VIA_STACKS") != stack.get("STATUS"):
        errors.append("ooc PG_DIRECT_VIA_STACKS disagrees with command report")

    pre_conn_count = verification_count(pre_conn_path, connectivity=True)
    pre_drc_count = verification_count(pre_drc_path, connectivity=False)
    pre_dangling_count, pre_other_problem_count = connectivity_problem_counts(pre_conn_path)
    pre_conn_status = ooc.get("PG_DIRECT_VIA_PRE_CTS_CONNECTIVITY_STATUS", "MISSING")
    pre_drc_status = ooc.get("PG_DIRECT_VIA_PRE_CTS_DRC_STATUS", "MISSING")
    pre_milestone_status = ooc.get("PG_DIRECT_VIA_PRE_CTS_MILESTONE_STATUS", "MISSING")
    if pre_conn_status == "PASS" and pre_conn_count != 0:
        errors.append(f"pre-CTS connectivity status PASS but count={pre_conn_count}")
    if pre_drc_status == "PASS" and pre_drc_count != 0:
        errors.append(f"pre-CTS DRC status PASS but count={pre_drc_count}")

    pre_zero_clean = (
        command_clean
        and pre_conn_status == "PASS"
        and pre_drc_status == "PASS"
        and pre_conn_count == 0
        and pre_drc_count == 0
    )
    pre_expected_dangling_only = (
        post_filler_restitch
        and command_clean
        and pre_conn_status == "EXPECTED_DANGLING_ONLY"
        and pre_milestone_status == "PASS"
        and pre_drc_status == "PASS"
        and pre_conn_count == EXPECTED_PRE_CTS_DANGLING_COUNT
        and pre_dangling_count == EXPECTED_PRE_CTS_DANGLING_COUNT
        and pre_other_problem_count == 0
        and pre_drc_count == 0
        and ooc.get("PG_DIRECT_VIA_PRE_CTS_EXPECTED_DANGLING_COUNT")
        == str(EXPECTED_PRE_CTS_DANGLING_COUNT)
        and pre_milestone.get("STATUS") == "PASS"
        and pre_milestone.get("CONNECTIVITY_STATUS") == "EXPECTED_DANGLING_ONLY"
        and pre_milestone.get("IMPVFC_94_DANGLING_COUNT")
        == str(EXPECTED_PRE_CTS_DANGLING_COUNT)
        and pre_milestone.get("OTHER_PROBLEM_COUNT") == "0"
    )
    pre_milestone_accepted = pre_zero_clean or pre_expected_dangling_only

    post_filler_conn_count = verification_count(post_filler_conn_path, connectivity=True)
    post_filler_drc_count = verification_count(post_filler_drc_path, connectivity=False)
    post_filler_conn_status = ooc.get("PG_POST_FILLER_CONNECTIVITY_STATUS", "MISSING")
    post_filler_drc_status = ooc.get("PG_POST_FILLER_DRC_STATUS", "MISSING")
    post_filler_clean = (
        not post_filler_restitch
        or (
            ooc.get("PG_RESTITCH_STAGE") == "POST_FILLER_PRE_ROUTE"
            and ooc.get("SROUTE_PG_POST_FILLER") == "PASS"
            and post_filler_conn_status == "PASS"
            and post_filler_conn_count == 0
            and post_filler_drc_status == "PASS"
            and post_filler_drc_count == 0
        )
    )
    final_fields_present = all(
        key in ooc
        for key in (
            "INNOVUS_DRC_STATUS",
            "REGULAR_CONNECTIVITY_STATUS",
            "PG_CONNECTIVITY_STATUS",
        )
    )

    met1_min_area = integer(marker, "MET1_MIN_AREA_MARKER_COUNT", errors) if marker else None
    antenna_count = integer(marker, "ANTENNA_MARKER_COUNT", errors) if marker else None
    other_count = integer(marker, "OTHER_MARKER_COUNT", errors) if marker else None
    expected_pg_markers = (
        integer(marker, "EXPECTED_PG_CONNECTIVITY_MARKER_COUNT", errors) if marker else None
    )

    if not command_clean:
        physical_status = "REJECTED_PRE_CTS_COMMAND"
    elif not pre_milestone_accepted:
        physical_status = "REJECTED_PRE_CTS_MILESTONE"
    elif post_filler_restitch and not post_filler_clean:
        physical_status = "REJECTED_POST_FILLER_RESTITCH_MILESTONE"
    elif not final_fields_present:
        physical_status = "REVIEW_REQUIRED_TOOL_FLOW_INCOMPLETE"
    elif ooc.get("PG_CONNECTIVITY_STATUS") != "PASS":
        physical_status = "REJECTED_FINAL_PG_CONNECTIVITY"
    elif ooc.get("REGULAR_CONNECTIVITY_STATUS") != "PASS":
        physical_status = "REJECTED_FINAL_REGULAR_CONNECTIVITY"
    elif ooc.get("INNOVUS_DRC_STATUS") == "FAIL" and (
        met1_min_area == 7
        and other_count == 0
        and expected_pg_markers == 0
    ):
        physical_status = "PG_CLOSED_MIN_AREA_REMAINS"
    elif (
        ooc.get("INNOVUS_DRC_STATUS") == "PASS"
        and gate.get("STATUS") == "PASS"
        and gate.get("RESULT") == "READY_FOR_PVS_CANDIDATE"
    ):
        physical_status = "READY_FOR_PVS_PREFLIGHT"
    elif ooc.get("INNOVUS_DRC_STATUS") == "PASS":
        physical_status = "REVIEW_REQUIRED_CANONICAL_GATE"
    else:
        physical_status = "REVIEW_REQUIRED_OTHER"

    if pre_milestone_accepted and post_filler_clean:
        for path in (marker_path, gate_path, final_drc_path, final_regular_path, final_pg_path):
            if not path.is_file():
                errors.append(f"missing final candidate artifact {path}")

    if physical_status == "READY_FOR_PVS_PREFLIGHT":
        next_decision = "REVIEW_THEN_RUN_SEPARATE_PVS_PREFLIGHT_GATE"
    elif physical_status == "PG_CLOSED_MIN_AREA_REMAINS":
        next_decision = "STOP_PG_EXPERIMENTS_REPAIR_SEVEN_MET1_MIN_AREA_MARKERS"
    else:
        next_decision = "STOP_AND_REVIEW_CANDIDATE_CLASSIFICATION"

    status = "PASS" if not errors else "FAIL"
    result = (
        "PREROUTE_PG_CANDIDATE_CLASSIFIED"
        if not errors
        else "PREROUTE_PG_CANDIDATE_CLASSIFICATION_INCOMPLETE"
    )
    lines = [
        "LABEL=SPADMIC_TX_PACKET_PREROUTE_PG_CANDIDATE_ANALYSIS",
        "POLICY=FRESH_FULL_FLOW_CANDIDATE_NO_AUTOMATIC_PVS_STAGING_OR_PVS",
        f"STATUS={status}",
        f"RESULT={result}",
        f"BLOCK_ROOT={args.block_root}",
        f"RUN_ROOT={run_root}",
        f"RUN_HEAD={manifest.get('HEAD', 'MISSING')}",
        f"CANDIDATE_PHYSICAL_STATUS={physical_status}",
        f"PG_ROUTE_STAGE={ooc.get('PG_ROUTE_STAGE', 'MISSING')}",
        f"DIRECT_VIA_COMMAND_STATUS={stack.get('STATUS', 'MISSING')}",
        f"DIRECT_VIA_COMMAND_PASS_COUNT={command_pass if command_pass is not None else 'UNKNOWN'}",
        f"DIRECT_VIA_COMMAND_FAIL_COUNT={command_fail if command_fail is not None else 'UNKNOWN'}",
        f"PRE_CTS_SPECIAL_CONNECTIVITY_STATUS={pre_conn_status}",
        f"PRE_CTS_SPECIAL_CONNECTIVITY_VIOLATION_COUNT={pre_conn_count if pre_conn_count is not None else 'UNKNOWN'}",
        f"PRE_CTS_IMPVFC_94_DANGLING_COUNT={pre_dangling_count}",
        f"PRE_CTS_OTHER_PROBLEM_COUNT={pre_other_problem_count}",
        f"PRE_CTS_MILESTONE_STATUS={pre_milestone_status}",
        f"PRE_CTS_DRC_STATUS={pre_drc_status}",
        f"PRE_CTS_DRC_VIOLATION_COUNT={pre_drc_count if pre_drc_count is not None else 'UNKNOWN'}",
        f"POST_FILLER_RESTITCH_ENABLED={'YES' if post_filler_restitch else 'NO'}",
        f"POST_FILLER_RESTITCH_STAGE={ooc.get('PG_RESTITCH_STAGE', 'NOT_RUN')}",
        f"POST_FILLER_SROUTE_STATUS={ooc.get('SROUTE_PG_POST_FILLER', 'NOT_RUN')}",
        f"POST_FILLER_SPECIAL_CONNECTIVITY_STATUS={post_filler_conn_status}",
        f"POST_FILLER_SPECIAL_CONNECTIVITY_VIOLATION_COUNT={post_filler_conn_count if post_filler_conn_count is not None else 'UNKNOWN'}",
        f"POST_FILLER_DRC_STATUS={post_filler_drc_status}",
        f"POST_FILLER_DRC_VIOLATION_COUNT={post_filler_drc_count if post_filler_drc_count is not None else 'UNKNOWN'}",
        f"FINAL_PG_CONNECTIVITY_STATUS={ooc.get('PG_CONNECTIVITY_STATUS', 'MISSING')}",
        f"FINAL_REGULAR_CONNECTIVITY_STATUS={ooc.get('REGULAR_CONNECTIVITY_STATUS', 'MISSING')}",
        f"FINAL_DRC_STATUS={ooc.get('INNOVUS_DRC_STATUS', 'MISSING')}",
        f"FINAL_MET1_MIN_AREA_MARKER_COUNT={met1_min_area if met1_min_area is not None else 'UNKNOWN'}",
        f"FINAL_ANTENNA_MARKER_COUNT={antenna_count if antenna_count is not None else 'UNKNOWN'}",
        f"FINAL_OTHER_MARKER_COUNT={other_count if other_count is not None else 'UNKNOWN'}",
        f"OOC_RESULT={ooc.get('RESULT', 'MISSING')}",
        f"CANONICAL_GATE_STATUS={gate.get('STATUS', 'MISSING')}",
        f"CANONICAL_GATE_RESULT={gate.get('RESULT', 'MISSING')}",
        f"CANONICAL_GATE_ERROR_COUNT={gate.get('ERROR_COUNT', 'MISSING')}",
        f"SETUP_WNS_NS={gate.get('SETUP_WNS_NS', 'MISSING')}",
        f"HOLD_WNS_NS={gate.get('HOLD_WNS_NS', 'MISSING')}",
        "CANDIDATE_EXPORT_SCOPE=RUN_LOCAL_AND_RUN_ID_HANDOFF_ONLY",
        "IMMUTABLE_PVS_STAGING_DECISION=BLOCKED_PENDING_OPERATOR_REVIEW",
        "PVS_DECISION=DO_NOT_RUN_FROM_THIS_STEP",
        f"NEXT_METHOD_DECISION={next_decision}",
    ]
    for label, path in (
        ("RUN_MANIFEST", manifest_path),
        ("OOC_STATUS", ooc_path),
        ("DIRECT_VIA_COMMAND_REPORT", stack_path),
        ("PRE_CTS_CONNECTIVITY_REPORT", pre_conn_path),
        ("PRE_CTS_DRC_REPORT", pre_drc_path),
        ("PRE_CTS_MILESTONE_REPORT", pre_milestone_path),
        ("POST_FILLER_CONNECTIVITY_REPORT", post_filler_conn_path),
        ("POST_FILLER_DRC_REPORT", post_filler_drc_path),
        ("FINAL_MARKER_CLASSIFICATION", marker_path),
        ("CANONICAL_GATE", gate_path),
    ):
        if path.is_file():
            lines.append(f"{label}_SHA256={sha256(path)}")
    lines.append(f"ERROR_COUNT={len(errors)}")
    lines.extend(f"ERROR={report_value(error)}" for error in errors)
    args.report.write_text("\n".join(lines) + "\n")
    return 0 if not errors else 8


if __name__ == "__main__":
    raise SystemExit(main())
