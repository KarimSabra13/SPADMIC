#!/usr/bin/env python3
"""Gate an attributable monolithic MPTDC plus RO_tune6 PVS LVS result."""

from __future__ import annotations

import argparse
import hashlib
import re
from pathlib import Path


SCHEMATIC_RE = re.compile(
    r'^\s*schematic_path\s+"([^"]+)"\s+(verilog|cdl)\b[^;]*;',
    re.IGNORECASE | re.MULTILINE,
)
LAYOUT_RE = re.compile(
    r'^\s*layout_path\s+"([^"]+)"\s*;', re.IGNORECASE | re.MULTILINE
)
FORBIDDEN_CONTROL_RE = re.compile(
    r"^\s*(lvs_black_box|lvs_verilog_bus_map_by_position|"
    r"lvs_global_sigs_are_ports)\b",
    re.IGNORECASE | re.MULTILINE,
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def count_named(root: Path, name: str) -> int:
    return sum(1 for path in root.rglob(name) if path.is_file())


def report_number(text: str, label: str) -> str:
    match = re.search(rf"^{re.escape(label)}\s*\|\s*([0-9]+)\s*$", text, re.MULTILINE)
    return match.group(1) if match else "MISSING"


def exact_path(value: str) -> str:
    return str(Path(value).resolve())


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", required=True, type=Path)
    parser.add_argument("--pvs-rc", required=True, type=int)
    parser.add_argument("--gds", required=True, type=Path)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--dcell-cdl", required=True, type=Path)
    parser.add_argument("--ro-cdl", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()

    required_inputs = (args.gds, args.source, args.dcell_cdl, args.ro_cdl)
    inputs_ready = all(path.is_file() and path.stat().st_size > 0 for path in required_inputs)
    control = args.run_dir / "pvslvsctl"
    run_control = args.run_dir / "run.pvs"
    config_rule = args.run_dir / ".config.rul"
    technology_rule = args.run_dir / ".technology.rul"
    control_text = (
        control.read_text(encoding="utf-8", errors="replace")
        if control.is_file()
        else ""
    )
    run_text = (
        run_control.read_text(encoding="utf-8", errors="replace")
        if run_control.is_file()
        else ""
    )

    schematic_paths = [
        (exact_path(path), kind.lower()) for path, kind in SCHEMATIC_RE.findall(control_text)
    ]
    expected_schematic_paths = [
        (str(args.source.resolve()), "verilog"),
        (str(args.dcell_cdl.resolve()), "cdl"),
        (str(args.ro_cdl.resolve()), "cdl"),
    ]
    layout_paths = [exact_path(path) for path in LAYOUT_RE.findall(control_text)]
    schematic_status = "PASS" if schematic_paths == expected_schematic_paths else "FAIL"
    layout_status = (
        "PASS" if layout_paths == [str(args.gds.resolve())] else "FAIL"
    )
    forbidden_control_count = len(FORBIDDEN_CONTROL_RE.findall(control_text))
    hcell_option_count = len(re.findall(r"(?:^|\s)-hcell(?:\s|$)", run_text))
    top_option_status = (
        "PASS"
        if len(re.findall(r"(?:^|\s)-top_cell\s+mptdc_axis_core(?:\s|\\|$)", run_text))
        == 1
        and len(
            re.findall(
                r"(?:^|\s)-source_top_cell\s+mptdc_axis_core(?:\s|\\|$)",
                run_text,
            )
        )
        == 1
        else "FAIL"
    )
    control_binding_status = (
        "PASS"
        if len(
            re.findall(
                rf'(?:^|\s)-control\s+"{re.escape(str(control.resolve()))}"(?:\s|\\|$)',
                run_text,
            )
        )
        == 1
        else "FAIL"
    )
    config_rule_status = (
        "PASS_EMPTY"
        if config_rule.is_file() and config_rule.stat().st_size == 0
        else "FAIL"
    )
    technology_rule_status = (
        "PASS"
        if technology_rule.is_file() and technology_rule.stat().st_size > 0
        else "FAIL"
    )

    cls_files = [path for path in args.run_dir.rglob("*.cls") if path.is_file()]
    cls_text = ""
    run_result = "MISSING"
    blackboxed = "MISSING"
    cells_mismatch = "MISSING"
    top_pin_status = "FAIL"
    ro_pin_status = "FAIL"
    missing_instance_count = 0
    if len(cls_files) == 1:
        cls_text = cls_files[0].read_text(encoding="utf-8", errors="replace")
        match = re.search(r"Run Result\s*:\s*([A-Za-z_]+)", cls_text)
        if match:
            run_result = match.group(1).upper()
        blackboxed = report_number(cls_text, "Cells that have been blackboxed")
        cells_mismatch = report_number(cls_text, "Cells which mismatch")
        if re.search(
            r"^mptdc_axis_core\s*\|\s*59\s*:\s*59\s*\|\s*59\s*:\s*59"
            r"\s*\|\s*match\b",
            cls_text,
            re.MULTILINE | re.IGNORECASE,
        ):
            top_pin_status = "PASS"
        if re.search(
            r"^RO_tune6\s*\|\s*19\s*:\s*19\s*\|\s*19\s*:\s*19"
            r"\s*\|\s*match\b",
            cls_text,
            re.MULTILINE | re.IGNORECASE,
        ):
            ro_pin_status = "PASS"
        missing_instance_count = cls_text.count("** missing inst **")

    matched_count = count_named(args.run_dir, "matched")
    mismatched_count = count_named(args.run_dir, "mismatched")
    shorts_files = [path for path in args.run_dir.rglob("*.shorts") if path.is_file()]
    nonempty_shorts = sum(1 for path in shorts_files if path.stat().st_size > 0)
    short_open_status = (
        "PASS" if len(shorts_files) == 1 and nonempty_shorts == 0 else "FAIL"
    )

    status = (
        "PASS"
        if inputs_ready
        and args.pvs_rc == 0
        and schematic_status == "PASS"
        and layout_status == "PASS"
        and forbidden_control_count == 0
        and hcell_option_count == 0
        and top_option_status == "PASS"
        and control_binding_status == "PASS"
        and config_rule_status == "PASS_EMPTY"
        and technology_rule_status == "PASS"
        and len(cls_files) == 1
        and run_result == "MATCH"
        and blackboxed == "0"
        and cells_mismatch == "0"
        and top_pin_status == "PASS"
        and ro_pin_status == "PASS"
        and missing_instance_count == 0
        and matched_count >= 1
        and mismatched_count == 0
        and short_open_status == "PASS"
        else "FAIL"
    )
    lvs_status = "MATCH" if status == "PASS" else "NOT_PROVEN"
    lines = [
        "STEP=PVS_RO6_MONOLITHIC_FULL_TOP_LVS",
        f"STATUS={status}",
        f"PVS_LVS_STATUS={lvs_status}",
        f"MONOLITHIC_LVS_STATUS={lvs_status}",
        f"PVS_RC={args.pvs_rc}",
        f"LVS_SCHEMATIC_PATH_COUNT={len(schematic_paths)}",
        f"LVS_SCHEMATIC_PATH_STATUS={schematic_status}",
        f"LVS_LAYOUT_PATH_COUNT={len(layout_paths)}",
        f"LVS_LAYOUT_PATH_STATUS={layout_status}",
        f"LVS_FORBIDDEN_CONTROL_COUNT={forbidden_control_count}",
        f"LVS_HCELL_OPTION_COUNT={hcell_option_count}",
        "LVS_HCELL_STATUS=NOT_USED" if hcell_option_count == 0 else "LVS_HCELL_STATUS=FAIL_USED",
        "LVS_BLACKBOX_STATUS=NOT_USED"
        if forbidden_control_count == 0
        else "LVS_BLACKBOX_STATUS=FAIL_USED",
        f"LVS_TOP_OPTION_STATUS={top_option_status}",
        f"LVS_CONTROL_BINDING_STATUS={control_binding_status}",
        f"LVS_CONFIG_RULE_STATUS={config_rule_status}",
        f"LVS_TECHNOLOGY_RULE_STATUS={technology_rule_status}",
        f"CLS_FILE_COUNT={len(cls_files)}",
        f"CLS_FILE={cls_files[0] if len(cls_files) == 1 else 'MISSING'}",
        f"CLS_RUN_RESULT={run_result}",
        f"LVS_BLACKBOXED_CELL_COUNT={blackboxed}",
        f"CELLS_WHICH_MISMATCH={cells_mismatch}",
        f"TOP_59_PIN_MATCH_STATUS={top_pin_status}",
        f"RO6_19_PIN_MATCH_STATUS={ro_pin_status}",
        f"MISSING_INSTANCE_EVIDENCE_COUNT={missing_instance_count}",
        f"MATCHED_MARKER_COUNT={matched_count}",
        f"MISMATCHED_MARKER_COUNT={mismatched_count}",
        f"SHORTS_FILE_COUNT={len(shorts_files)}",
        f"NONEMPTY_SHORTS_FILE_COUNT={nonempty_shorts}",
        f"SHORT_OPEN_EVIDENCE_STATUS={short_open_status}",
        f"MERGED_GDS={args.gds}",
        f"MERGED_GDS_SHA256={sha256(args.gds) if args.gds.is_file() else 'MISSING'}",
        f"LVS_SOURCE={args.source}",
        f"LVS_SOURCE_SHA256={sha256(args.source) if args.source.is_file() else 'MISSING'}",
        f"DCELL_CDL={args.dcell_cdl}",
        f"DCELL_CDL_SHA256={sha256(args.dcell_cdl) if args.dcell_cdl.is_file() else 'MISSING'}",
        f"RO_CDL={args.ro_cdl}",
        f"RO_CDL_SHA256={sha256(args.ro_cdl) if args.ro_cdl.is_file() else 'MISSING'}",
        "LVS_PROOF_LEVEL=MONOLITHIC_FULL_TOP_SIGNOFF_LEVEL",
        f"LVS_SIGNOFF_ELIGIBLE={'YES' if status == 'PASS' else 'NO'}",
        "FINAL_PHYSICAL_SIGNOFF_READY=NO",
    ]
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n".join(lines))
    return 0 if status == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
