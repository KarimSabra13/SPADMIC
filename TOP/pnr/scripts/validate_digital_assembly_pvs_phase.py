#!/usr/bin/env python3
"""Classify one exact-GDS PVS action for a cumulative assembly phase."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
DEFAULT_CONTRACT = ROOT / "TOP/pnr/assembly/spadmic_digital_assembly_contract.json"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify_sha256_manifest(root: Path, manifest: Path, errors: list[str], label: str) -> None:
    if not manifest.is_file() or manifest.stat().st_size == 0:
        errors.append(f"missing_or_empty_{label}_manifest={manifest}")
        return
    for line_number, line in enumerate(
        manifest.read_text(encoding="utf-8", errors="replace").splitlines(), start=1
    ):
        if not line.strip():
            continue
        parts = line.split(None, 1)
        if len(parts) != 2 or len(parts[0]) != 64:
            errors.append(f"{label}_manifest_malformed_line={line_number}")
            continue
        expected, raw_path = parts
        raw_path = raw_path.lstrip("*")
        candidate = Path(raw_path)
        path = candidate if candidate.is_absolute() else root / candidate
        try:
            path.resolve().relative_to(root.resolve())
        except ValueError:
            errors.append(f"{label}_manifest_path_outside_root={raw_path}")
            continue
        if not path.is_file():
            errors.append(f"{label}_manifest_file_missing={raw_path}")
        elif digest(path) != expected:
            errors.append(f"{label}_manifest_hash_mismatch={raw_path}")


def read_kv(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            values[key] = value
    return values


def read_tsv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def uint(values: dict[str, str], key: str, errors: list[str]) -> int | None:
    raw = values.get(key, "")
    if not raw.isdigit():
        errors.append(f"{key.lower()}={raw or 'MISSING'} expected_unsigned_integer")
        return None
    return int(raw)


def boxes_equal(left: str, right: str, tolerance: float = 0.002) -> bool:
    try:
        lhs = [float(value) for value in left.split()]
        rhs = [float(value) for value in right.split()]
    except ValueError:
        return False
    return len(lhs) == len(rhs) == 4 and all(
        abs(a - b) <= tolerance for a, b in zip(lhs, rhs)
    )


def require(values: dict[str, str], expected: dict[str, str], errors: list[str], prefix: str) -> None:
    for key, value in expected.items():
        actual = values.get(key, "MISSING")
        if actual != value:
            errors.append(f"{prefix}_{key.lower()}={actual} expected={value}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--phase", required=True)
    parser.add_argument("--mode", required=True, choices=("base", "density", "lvs"))
    parser.add_argument("--package", required=True, type=Path)
    parser.add_argument("--run-dir", required=True, type=Path)
    parser.add_argument("--status", required=True, type=Path)
    parser.add_argument("--prior-status", type=Path)
    parser.add_argument("--analysis-root", type=Path)
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    parser.add_argument("--expected-head", default="UNKNOWN")
    parser.add_argument("--actual-head", default="UNKNOWN")
    args = parser.parse_args()

    contract = json.loads(args.contract.read_text(encoding="utf-8"))
    if args.phase not in contract["phases"]:
        raise SystemExit(f"unknown assembly phase: {args.phase}")
    phase_data = contract["phases"][args.phase]
    top = str(phase_data["top"])
    package = args.package.resolve()
    run_dir = args.run_dir.resolve()
    package_manifest_path = package / "manifests/package.json"
    errors: list[str] = []
    if args.expected_head != "UNKNOWN" and args.actual_head != args.expected_head:
        errors.append(
            f"actual_head={args.actual_head} expected_head={args.expected_head}"
        )
    package_manifest = (
        json.loads(package_manifest_path.read_text(encoding="utf-8"))
        if package_manifest_path.is_file()
        else {}
    )
    for key in ("name", "layout_top", "source_top"):
        if package_manifest.get(key) != top:
            errors.append(
                f"package_{key}={package_manifest.get(key, 'MISSING')} expected={top}"
            )
    if package_manifest.get("kind") != "assembly":
        errors.append(f"package_kind={package_manifest.get('kind', 'MISSING')} expected=assembly")
    if package_manifest.get("qualification_profile") != "digital_assembly_tc":
        errors.append(
            "package_qualification_profile="
            f"{package_manifest.get('qualification_profile', 'MISSING')} expected=digital_assembly_tc"
        )
    gate_manifest = package_manifest.get("digital_assembly_tc_gate", {})
    if not isinstance(gate_manifest, dict) or gate_manifest.get("phase") != args.phase:
        errors.append(
            "package_phase="
            f"{gate_manifest.get('phase', 'MISSING') if isinstance(gate_manifest, dict) else 'MISSING'} "
            f"expected={args.phase}"
        )
    verify_sha256_manifest(
        package, package / "manifests/SHA256SUMS", errors, "package"
    )

    gds = package / f"gds/{top}.gds"
    source = package / f"netlist/{top}.lvs.pg.v"
    cdl = package / "pdk/xh018_D_CELLS_JIHD.cdl"
    for label, path in (("gds", gds), ("source", source), ("cdl", cdl)):
        if not path.is_file() or path.stat().st_size == 0:
            errors.append(f"missing_or_empty_package_{label}={path}")
    gds_sha = digest(gds) if gds.is_file() else "MISSING"
    source_sha = digest(source) if source.is_file() else "MISSING"
    cdl_sha = digest(cdl) if cdl.is_file() else "MISSING"
    if source.is_file() and package_manifest.get("lvs_source_sha256") != source_sha:
        errors.append("package_lvs_source_hash_mismatch")
    if cdl.is_file() and package_manifest.get("stdcell_cdl_sha256") != cdl_sha:
        errors.append("package_stdcell_cdl_hash_mismatch")

    replay_path = run_dir / "replay_contract_status.rpt"
    isolation_path = run_dir / "output_isolation.rpt"
    raw_status_path = run_dir / ("pvs_lvs_status.rpt" if args.mode == "lvs" else "pvs_drc_status.rpt")
    expected_run_parent = package / "pvs" / ("lvs" if args.mode == "lvs" else "drc")
    try:
        run_dir.relative_to(expected_run_parent.resolve())
    except ValueError:
        errors.append(f"run_dir_outside_package_mode_root={run_dir}")
    for label, path in (
        ("raw_status", raw_status_path),
        ("replay_contract", replay_path),
        ("output_isolation", isolation_path),
        ("run_manifest", run_dir / "SHA256SUMS"),
    ):
        if not path.is_file() or path.stat().st_size == 0:
            errors.append(f"missing_or_empty_{label}={path}")
    raw = read_kv(raw_status_path) if raw_status_path.is_file() else {}
    replay = read_kv(replay_path) if replay_path.is_file() else {}
    isolation = read_kv(isolation_path) if isolation_path.is_file() else {}
    require(
        replay,
        {
            "STATUS": "PASS",
            "LAYOUT_TOP": top,
            "GDS": str(gds),
            "OUTPUT_ISOLATION_STATUS": "PASS",
        },
        errors,
        "replay",
    )
    require(isolation, {"STATUS": "PASS"}, errors, "isolation")
    require(
        isolation,
        {
            "RUN_DIR": str(run_dir),
            "LAYOUT_GDS_INPUT": str(gds),
        },
        errors,
        "isolation",
    )
    verify_sha256_manifest(run_dir, run_dir / "SHA256SUMS", errors, "run")

    prior: dict[str, str] = {}
    if args.mode in {"density", "lvs"}:
        if args.prior_status is None or not args.prior_status.is_file():
            errors.append("prior_status_missing")
        else:
            prior = read_kv(args.prior_status)
            require(
                prior,
                {
                    "STATUS": "PASS",
                    "PHASE": args.phase,
                    "TOP_MODULE": top,
                    "GDS_SHA256": gds_sha,
                },
                errors,
                "prior",
            )

    outcome = "NOT_CLASSIFIED"
    base_status = "NOT_RUN"
    density_status = "NOT_RUN"
    lvs_status = "NOT_RUN"
    density_disposition = "NOT_APPLICABLE"
    total_primary: int | None = None
    total_expanded: int | None = None
    analysis_status = "NOT_APPLICABLE"

    if args.mode in {"base", "density"}:
        variant = args.mode.upper()
        require(
            raw,
            {
                "MODE": "DRC",
                "PVS_RC": "0",
                "PVS_DRC_VARIANT": variant,
                "PACKAGE": str(package),
                "GDS": str(gds),
                "GDS_SHA256": gds_sha,
            },
            errors,
            "raw_drc",
        )
        defines = read_kv(run_dir / "preprocessor_defines.rpt") if (run_dir / "preprocessor_defines.rpt").is_file() else {}
        expected_define = (
            {"DEFINE": "DENSITY|OCCURRENCES=1"}
            if args.mode == "density"
            else {"UNDEFINE": "DENSITY|OCCURRENCES=1"}
        )
        require(defines, expected_define, errors, "preprocessor")
        total_primary = uint(raw, "DRC_TOTAL_PRIMARY", errors)
        total_expanded = uint(raw, "DRC_TOTAL_EXPANDED", errors)
        if args.mode == "base":
            if raw.get("PVS_DRC_STATUS") != "PASS":
                errors.append(
                    f"base_pvs_drc_status={raw.get('PVS_DRC_STATUS', 'MISSING')} expected=PASS"
                )
            if total_primary != 0 or total_expanded != 0:
                errors.append(
                    f"base_drc_results={total_primary},{total_expanded} expected=0,0"
                )
            if not errors:
                outcome = "ATTRIBUTABLE_ZERO_RESULTS"
                base_status = "PASS"
        else:
            if args.phase != "p03_matrix_interface":
                errors.append(f"density_not_authorized_for_phase={args.phase}")
            if prior.get("MODE") != "BASE" or prior.get("PVS_BASE_DRC_STATUS") != "PASS":
                errors.append("density_prior_base_gate_not_pass")
            if total_primary == 0 and total_expanded == 0:
                if raw.get("PVS_DRC_STATUS") != "PASS":
                    errors.append(
                        f"density_pvs_drc_status={raw.get('PVS_DRC_STATUS', 'MISSING')} expected=PASS"
                    )
                if not errors:
                    outcome = "ATTRIBUTABLE_ZERO_RESULTS"
                    base_status = "PASS"
                    density_status = "PASS"
                    density_disposition = "ZERO_RESULTS"
            elif total_primary is not None and total_expanded is not None:
                if raw.get("PVS_DRC_STATUS") != "FAIL":
                    errors.append(
                        f"density_pvs_drc_status={raw.get('PVS_DRC_STATUS', 'MISSING')} expected=FAIL"
                    )
                if args.analysis_root is None:
                    errors.append("density_rule_analysis_root_missing")
                else:
                    analysis_report = args.analysis_root / "pvs_drc_analysis_status.rpt"
                    inventory = args.analysis_root / "pvs_drc_rule_inventory.tsv"
                    if not analysis_report.is_file() or not inventory.is_file():
                        errors.append("density_rule_analysis_evidence_missing")
                    else:
                        analysis = read_kv(analysis_report)
                        require(
                            analysis,
                            {
                                "STATUS": "PASS",
                                "RESULT": "PVS_DRC_RULE_DEBT_CLASSIFIED",
                                "PVS_DRC_VARIANT": "DENSITY",
                                "LAYOUT_TOP": top,
                                "DENSITY_STATE": "DEFINED",
                            },
                            errors,
                            "density_analysis",
                        )
                        rows = read_tsv(inventory)
                        allowed = set(phase_data.get("allowed_density_rules", []))
                        observed = {row.get("rule", "") for row in rows}
                        if not rows or not observed <= allowed:
                            errors.append(
                                "density_rule_set="
                                f"{','.join(sorted(observed)) or 'EMPTY'} allowed={','.join(sorted(allowed))}"
                            )
                        gate_report = package / "reports/digital_assembly_innovus_gate.rpt"
                        if not gate_report.is_file():
                            errors.append("digital_assembly_innovus_gate_missing")
                            die = "MISSING"
                        else:
                            die = read_kv(gate_report).get(
                                "ACTUAL_DIE_BBOX_UM", "MISSING"
                            )
                        for row in rows:
                            if row.get("category") != "DENSITY":
                                errors.append(
                                    f"density_rule_category={row.get('rule')}:{row.get('category', 'MISSING')}"
                                )
                            if not boxes_equal(row.get("aggregate_bbox_um", ""), die):
                                errors.append(
                                    f"density_rule_bbox={row.get('rule')}:{row.get('aggregate_bbox_um', 'MISSING')} expected={die}"
                                )
                        analysis_status = "PASS" if not errors else "FAIL"
                if not errors:
                    outcome = "ATTRIBUTABLE_WHOLE_EXTENT_DENSITY_DEBT"
                    base_status = "PASS"
                    density_status = "CLASSIFIED_RULE_DEBT"
                    density_disposition = "ASSEMBLED_FILL_OR_FORMAL_WAIVER_REQUIRED"
    else:
        require(
            raw,
            {
                "MODE": "LVS",
                "PVS_RC": "0",
                "PVS_LVS_STATUS": "MATCH",
                "PACKAGE": str(package),
                "LAYOUT_TOP": top,
                "SOURCE_TOP": top,
                "GDS": str(gds),
                "GDS_SHA256": gds_sha,
                "LVS_SOURCE": str(source),
                "LVS_SOURCE_SHA256": source_sha,
                "STDCELL_CDL": str(cdl),
                "STDCELL_CDL_SHA256": cdl_sha,
            },
            errors,
            "raw_lvs",
        )
        require(
            replay,
            {
                "SOURCE_TOP": top,
                "SOURCE": str(source),
                "CDL": str(cdl),
            },
            errors,
            "replay_lvs",
        )
        require(
            isolation,
            {
                "SCHEMATIC_VERILOG_INPUT": str(source),
                "SCHEMATIC_CDL_INPUT": str(cdl),
            },
            errors,
            "isolation_lvs",
        )
        negative = uint(raw, "LVS_NEGATIVE_MATCH_COUNT", errors)
        positive = uint(raw, "LVS_POSITIVE_MATCH_COUNT", errors)
        if negative != 0 or positive is None or positive < 1:
            errors.append(f"lvs_match_evidence=negative:{negative},positive:{positive}")
        expected_prior_mode = "DENSITY" if args.phase == "p03_matrix_interface" else "BASE"
        if prior.get("MODE") != expected_prior_mode:
            errors.append(
                f"lvs_prior_mode={prior.get('MODE', 'MISSING')} expected={expected_prior_mode}"
            )
        if prior.get("PVS_BASE_DRC_STATUS") != "PASS":
            errors.append("lvs_prior_base_drc_status_not_pass")
        if args.phase == "p03_matrix_interface" and prior.get("PVS_DENSITY_DRC_STATUS") not in {
            "PASS",
            "CLASSIFIED_RULE_DEBT",
        }:
            errors.append("lvs_prior_density_status_not_accepted")
        if not errors:
            outcome = "ATTRIBUTABLE_MATCH"
            base_status = "PASS"
            density_status = (
                prior.get("PVS_DENSITY_DRC_STATUS", "NOT_RUN")
                if args.phase == "p03_matrix_interface"
                else "NOT_RUN_BY_POLICY"
            )
            density_disposition = prior.get("DENSITY_DISPOSITION_STATUS", "NOT_APPLICABLE")
            lvs_status = "MATCH"

    status_value = "PASS" if not errors else "FAIL"
    phase_acceptance = "NO"
    promotion = "NO"
    if args.mode == "lvs" and not errors:
        if args.phase != "p03_matrix_interface" or density_status == "PASS":
            phase_acceptance = "YES"
        if args.phase == "p03_matrix_interface" and density_status == "PASS":
            promotion = "YES"
    values: dict[str, object] = {
        "LABEL": "SPADMIC_DIGITAL_ASSEMBLY_PVS_GATE",
        "STATUS": status_value,
        "RESULT": outcome if not errors else "REVIEW_REQUIRED",
        "EXPECTED_HEAD": args.expected_head,
        "ACTUAL_HEAD": args.actual_head,
        "PHASE": args.phase,
        "MODE": args.mode.upper(),
        "TOP_MODULE": top,
        "SOURCE_TOP": top,
        "LAYOUT_TOP": top,
        "PACKAGE": package,
        "RUN_DIR": run_dir,
        "GDS_SHA256": gds_sha,
        "LVS_SOURCE_SHA256": source_sha,
        "STDCELL_CDL_SHA256": cdl_sha,
        "PVS_BASE_DRC_STATUS": base_status,
        "PVS_DENSITY_DRC_STATUS": density_status,
        "PVS_LVS_STATUS": lvs_status,
        "DRC_TOTAL_PRIMARY": "NOT_APPLICABLE" if total_primary is None else total_primary,
        "DRC_TOTAL_EXPANDED": "NOT_APPLICABLE" if total_expanded is None else total_expanded,
        "DENSITY_RULE_ANALYSIS_STATUS": analysis_status,
        "DENSITY_DISPOSITION_STATUS": density_disposition,
        "PVS_EXECUTED": "YES",
        "ASSEMBLY_PHASE_ACCEPTED": phase_acceptance,
        "OA_INSERTION_AUTHORIZED": promotion,
        "BLOCK_PROMOTION_AUTHORIZED": promotion,
        "SIGNOFF_READY": "NO",
        "ERROR_COUNT": len(errors),
        "NEXT_GATE": (
            "REVIEW_BASE_DRC_THEN_RUN_LVS"
            if args.mode == "base" and args.phase != "p03_matrix_interface" and not errors
            else "REVIEW_BASE_DRC_THEN_RUN_P03_DENSITY"
            if args.mode == "base" and not errors
            else "REVIEW_DENSITY_THEN_RUN_LVS"
            if args.mode == "density" and not errors
            else "REVIEW_LVS_AND_PHASE_ACCEPTANCE"
            if args.mode == "lvs" and not errors
            else "STOP_AND_REVIEW_PVS_EVIDENCE"
        ),
    }
    args.status.parent.mkdir(parents=True, exist_ok=True)
    args.status.write_text(
        "".join(
            [
                *(f"{key}={value}\n" for key, value in values.items()),
                *(f"ERROR={error}\n" for error in errors),
            ]
        ),
        encoding="utf-8",
    )
    print(args.status.read_text(), end="")
    return 0 if not errors else 8


if __name__ == "__main__":
    raise SystemExit(main())
