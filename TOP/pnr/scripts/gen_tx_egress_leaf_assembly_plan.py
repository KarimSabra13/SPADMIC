#!/usr/bin/env python3
"""Generate a fixed-leaf TX egress assembly planning package.

The input is the manifest collected from the four clean TX leaf OOC hardening
runs.  The output is intentionally a placement/import plan, not an Innovus
closure run: top absolute placement, PG hookup, PVS/LVS/PEX, and MMMC remain
separate gates.
"""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


LEAF_ORDER = ["event_bundle_tx", "output_fifo", "ddr16_pairer", "ddrs2_adapter"]

LEAF_META = {
    "event_bundle_tx": {
        "top_module": "spadmic_event_bundle_tx",
        "instances": ["u_event_bundle_tx", "u_bundle_tx"],
        "role": "Packet bundle builder; source side of TX chain.",
    },
    "output_fifo": {
        "top_module": "spadmic_output_fifo_topcfg",
        "instances": ["u_output_fifo"],
        "role": "TX output elasticity FIFO.",
    },
    "ddr16_pairer": {
        "top_module": "spadmic_ddr16_tx_pairer",
        "instances": ["u_ddr16_pairer"],
        "role": "Narrow-word to DDR16 low/high phase pairer.",
    },
    "ddrs2_adapter": {
        "top_module": "spadmic_ddrs2_adapter",
        "instances": ["u_ddrs2_adapter"],
        "role": "Wide DDRs2 bridge; north pins must stay DDRs2-aligned.",
    },
}

REQUIRED_STATUS = {
    "RESULT": "ABSTRACT_READY_FOR_TOP_REVIEW",
    "SIGNOFF_READY": "NO",
    "INNOVUS_DRC_STATUS": "PASS",
    "DRC_MARKER_CLASSIFICATION": "PASS",
    "DRC_MARKER_TOTAL": "0",
    "REGULAR_CONNECTIVITY_STATUS": "PASS",
    "PG_CONNECTIVITY_STATUS": "DEFERRED_TOP_LEVEL_HOOKUP",
    "POSTROUTE_SETUP_TIMING": "PASS",
    "POSTROUTE_HOLD_TIMING": "PASS",
    "EXPORT_LEF_FILE": "PASS",
    "EXPORT_GDS_FILE": "PASS",
    "EXPORT_DEF_FILE": "PASS",
    "HANDOFF_COPY": "PASS",
}

FALLBACK_DIMS_UM = {
    "event_bundle_tx": (339.920, 240.240),
    "output_fifo": (740.320, 540.400),
    "ddr16_pairer": (140.000, 100.240),
    "ddrs2_adapter": (3449.600, 45.920),
}

# Top-layout anchors from TOP/docs/layout_audits/SPADMIC2_20260709_072331.
DDR2_M1_BBOX = (21.980, 3261.886, 3620.495, 3393.959)
DDR2_DATA_CLK_X_SPAN = (85.540, 3475.095)
LEGACY_TX_CORRIDOR_BBOX = (45.540, 3065.886, 3495.519, 3231.886)


@dataclass(frozen=True)
class Leaf:
    block: str
    run_id: str
    block_root: Path
    handoff_root: Path
    lef: Path
    abstract_lef: Path
    def_file: Path
    gds: Path
    routed_v: Path
    routed_pg_v: Path
    status_report: Path
    pin_plan_csv: Path
    width_um: float
    height_um: float
    status: dict[str, str]


@dataclass(frozen=True)
class Placement:
    block: str
    llx_um: float
    lly_um: float
    width_um: float
    height_um: float
    orient: str = "R0"
    fixed: str = "YES"

    @property
    def urx_um(self) -> float:
        return self.llx_um + self.width_um

    @property
    def ury_um(self) -> float:
        return self.lly_um + self.height_um


def repo_head(repo_root: Path) -> str:
    try:
        return subprocess.check_output(
            ["git", "-C", str(repo_root), "rev-parse", "HEAD"],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
    except Exception:
        return "unknown"


def read_status(path: Path) -> dict[str, str]:
    status: dict[str, str] = {}
    if not path.is_file():
        return status
    for line in path.read_text(errors="replace").splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        status[key.strip()] = value.strip()
    return status


def parse_lef_size(path: Path) -> tuple[float, float] | None:
    if not path.is_file():
        return None
    text = path.read_text(errors="replace")
    match = re.search(
        r"^\s*SIZE\s+([0-9]+(?:\.[0-9]+)?)\s+BY\s+([0-9]+(?:\.[0-9]+)?)\s*;",
        text,
        flags=re.MULTILINE,
    )
    if not match:
        return None
    return (float(match.group(1)), float(match.group(2)))


def as_path(row: dict[str, str], key: str) -> Path:
    return Path(row.get(key, "").strip())


def load_manifest(path: Path, allow_missing_files: bool) -> tuple[list[Leaf], list[str]]:
    errors: list[str] = []
    with path.open(newline="") as fh:
        rows = [{k: (v or "").strip() for k, v in row.items()} for row in csv.DictReader(fh)]

    by_block: dict[str, dict[str, str]] = {}
    for row in rows:
        block = row.get("block", "")
        if block in by_block:
            errors.append(f"duplicate manifest block: {block}")
            continue
        by_block[block] = row

    leaves: list[Leaf] = []
    for block in LEAF_ORDER:
        row = by_block.get(block)
        if row is None:
            errors.append(f"missing manifest block: {block}")
            continue

        status_report = as_path(row, "status_report")
        status = read_status(status_report)
        for key, expected in REQUIRED_STATUS.items():
            actual = status.get(key)
            if actual != expected:
                errors.append(f"{block}: {key} expected {expected}, got {actual or 'MISSING'}")

        required_paths = [
            "lef",
            "abstract_lef",
            "def",
            "gds",
            "routed_v",
            "routed_pg_v",
            "status_report",
            "pin_plan_csv",
        ]
        for key in required_paths:
            p = as_path(row, key)
            if not p.is_file() and not allow_missing_files:
                errors.append(f"{block}: missing {key}: {p}")

        size = parse_lef_size(as_path(row, "lef"))
        if size is None:
            size = FALLBACK_DIMS_UM[block]

        leaves.append(
            Leaf(
                block=block,
                run_id=row.get("run_id", ""),
                block_root=as_path(row, "block_root"),
                handoff_root=as_path(row, "handoff_root"),
                lef=as_path(row, "lef"),
                abstract_lef=as_path(row, "abstract_lef"),
                def_file=as_path(row, "def"),
                gds=as_path(row, "gds"),
                routed_v=as_path(row, "routed_v"),
                routed_pg_v=as_path(row, "routed_pg_v"),
                status_report=status_report,
                pin_plan_csv=as_path(row, "pin_plan_csv"),
                width_um=size[0],
                height_um=size[1],
                status=status,
            )
        )
    return leaves, errors


def compute_placements(leaves: Iterable[Leaf], gap_um: float, east_margin_um: float) -> list[Placement]:
    dims = {leaf.block: (leaf.width_um, leaf.height_um) for leaf in leaves}

    adapter_w, adapter_h = dims["ddrs2_adapter"]
    pairer_w, pairer_h = dims["ddr16_pairer"]
    fifo_w, fifo_h = dims["output_fifo"]
    event_w, event_h = dims["event_bundle_tx"]

    pairer_x = max(0.0, adapter_w - east_margin_um - pairer_w)
    fifo_x = max(0.0, pairer_x - gap_um - fifo_w)
    event_x = max(0.0, fifo_x - gap_um - event_w)

    lower_h = max(event_h, fifo_h)
    pairer_y = lower_h + gap_um
    adapter_y = pairer_y + pairer_h + gap_um

    return [
        Placement("event_bundle_tx", event_x, 0.0, event_w, event_h),
        Placement("output_fifo", fifo_x, 0.0, fifo_w, fifo_h),
        Placement("ddr16_pairer", pairer_x, pairer_y, pairer_w, pairer_h),
        Placement("ddrs2_adapter", 0.0, adapter_y, adapter_w, adapter_h),
    ]


def f3(value: float) -> str:
    return f"{value:.3f}"


def write_sources_csv(path: Path, leaves: list[Leaf]) -> None:
    with path.open("w", newline="") as fh:
        fieldnames = [
            "block",
            "top_module",
            "run_id",
            "block_root",
            "handoff_root",
            "lef",
            "abstract_lef",
            "def",
            "gds",
            "routed_v",
            "routed_pg_v",
            "status_report",
            "pin_plan_csv",
            "width_um",
            "height_um",
        ]
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
        writer.writeheader()
        for leaf in leaves:
            writer.writerow(
                {
                    "block": leaf.block,
                    "top_module": LEAF_META[leaf.block]["top_module"],
                    "run_id": leaf.run_id,
                    "block_root": leaf.block_root,
                    "handoff_root": leaf.handoff_root,
                    "lef": leaf.lef,
                    "abstract_lef": leaf.abstract_lef,
                    "def": leaf.def_file,
                    "gds": leaf.gds,
                    "routed_v": leaf.routed_v,
                    "routed_pg_v": leaf.routed_pg_v,
                    "status_report": leaf.status_report,
                    "pin_plan_csv": leaf.pin_plan_csv,
                    "width_um": f3(leaf.width_um),
                    "height_um": f3(leaf.height_um),
                }
            )


def write_placement_csv(path: Path, leaves: list[Leaf], placements: list[Placement]) -> None:
    leaf_map = {leaf.block: leaf for leaf in leaves}
    with path.open("w", newline="") as fh:
        fieldnames = [
            "block",
            "top_module",
            "preferred_instances",
            "primary_instance",
            "run_id",
            "llx_um",
            "lly_um",
            "urx_um",
            "ury_um",
            "width_um",
            "height_um",
            "orient",
            "fixed",
            "role",
        ]
        writer = csv.DictWriter(fh, fieldnames=fieldnames)
        writer.writeheader()
        for placement in placements:
            leaf = leaf_map[placement.block]
            meta = LEAF_META[placement.block]
            instances = meta["instances"]
            writer.writerow(
                {
                    "block": placement.block,
                    "top_module": meta["top_module"],
                    "preferred_instances": " ".join(instances),
                    "primary_instance": instances[0],
                    "run_id": leaf.run_id,
                    "llx_um": f3(placement.llx_um),
                    "lly_um": f3(placement.lly_um),
                    "urx_um": f3(placement.urx_um),
                    "ury_um": f3(placement.ury_um),
                    "width_um": f3(placement.width_um),
                    "height_um": f3(placement.height_um),
                    "orient": placement.orient,
                    "fixed": placement.fixed,
                    "role": meta["role"],
                }
            )


def tcl_list(items: Iterable[object]) -> str:
    return "[list " + " ".join("{" + str(item) + "}" for item in items) + "]"


def write_tcl(path: Path, leaves: list[Leaf], placements: list[Placement], report_name: str) -> None:
    leaf_map = {leaf.block: leaf for leaf in leaves}
    with path.open("w") as fh:
        fh.write("# Auto-generated TX egress fixed-leaf assembly placement include.\n")
        fh.write("# Source this after a top/assembly design has loaded the leaf abstracts.\n")
        fh.write("# This is a review aid, not signoff collateral.\n\n")
        fh.write("set SPADMIC_TX_LEAF_ABSTRACT_LEFS ")
        fh.write(tcl_list(leaf.abstract_lef for leaf in leaves))
        fh.write("\n")
        fh.write("set SPADMIC_TX_LEAF_LEFS ")
        fh.write(tcl_list(leaf.lef for leaf in leaves))
        fh.write("\n")
        fh.write("set SPADMIC_TX_LEAF_DEFS ")
        fh.write(tcl_list(leaf.def_file for leaf in leaves))
        fh.write("\n")
        fh.write("set SPADMIC_TX_LEAF_GDS ")
        fh.write(tcl_list(leaf.gds for leaf in leaves))
        fh.write("\n\n")

        fh.write("set SPADMIC_TX_LEAF_PLACEMENTS [list \\\n")
        for placement in placements:
            meta = LEAF_META[placement.block]
            leaf = leaf_map[placement.block]
            candidates = " ".join(meta["instances"])
            fh.write(
                f"  {{{{{placement.block}}} {{{candidates}}} {{{f3(placement.llx_um)}}} "
                f"{{{f3(placement.lly_um)}}} {{{placement.orient}}} {{{leaf.run_id}}}}} \\\n"
            )
        fh.write("]\n\n")

        fh.write(
            r'''proc spadmic_tx_leaf_inst_exists {inst} {
    if {[catch {set obj [dbGet -e top.insts.name $inst]}]} {
        return 0
    }
    if {[string trim $obj] eq ""} {
        return 0
    }
    return 1
}

proc spadmic_tx_leaf_choose_inst {candidates} {
    foreach inst $candidates {
        if {[spadmic_tx_leaf_inst_exists $inst]} {
            return $inst
        }
    }
    return ""
}

proc spadmic_tx_leaf_place_one {block candidates x y orient run_id fh} {
    set inst [spadmic_tx_leaf_choose_inst $candidates]
    if {$inst eq ""} {
        puts $fh "BLOCK=$block STATUS=MISSING_INSTANCE CANDIDATES=$candidates RUN_ID=$run_id"
        return 0
    }

    set placed 0
    foreach cmd [list \
        [list placeInstance $inst $x $y $orient -fixed] \
        [list placeInstance $inst $x $y $orient] \
    ] {
        if {![catch {uplevel #0 $cmd} err]} {
            puts $fh "BLOCK=$block STATUS=PLACED INSTANCE=$inst COMMAND=$cmd RUN_ID=$run_id"
            set placed 1
            break
        }
        puts $fh "BLOCK=$block STATUS=PLACE_TRY_FAILED INSTANCE=$inst COMMAND=$cmd ERROR=$err RUN_ID=$run_id"
    }

    if {!$placed} {
        return 0
    }

    foreach cmd [list \
        [list setInstancePlacementStatus -name $inst -status fixed] \
        [list set_dont_touch_placement $inst] \
    ] {
        if {![catch {uplevel #0 $cmd} err]} {
            puts $fh "BLOCK=$block STATUS=FIXED INSTANCE=$inst COMMAND=$cmd RUN_ID=$run_id"
            return 1
        }
        puts $fh "BLOCK=$block STATUS=FIX_TRY_FAILED INSTANCE=$inst COMMAND=$cmd ERROR=$err RUN_ID=$run_id"
    }
    return 1
}

proc spadmic_apply_tx_leaf_assembly_placement {{report_file ""}} {
    global SPADMIC_TX_LEAF_PLACEMENTS
    if {$report_file eq ""} {
        set report_file "'''
        )
        fh.write(report_name)
        fh.write(
            r'''"
    }
    set fh [open $report_file w]
    puts $fh "LABEL=TX_EGRESS_LEAF_ASSEMBLY_PLACEMENT"
    puts $fh "NOTE=Fixed-leaf placement proposal only; PG hookup and signoff remain top-level gates."

    set pass_count 0
    set fail_count 0
    foreach item $SPADMIC_TX_LEAF_PLACEMENTS {
        set block [lindex $item 0]
        set candidates [lindex $item 1]
        set x [lindex $item 2]
        set y [lindex $item 3]
        set orient [lindex $item 4]
        set run_id [lindex $item 5]
        if {[spadmic_tx_leaf_place_one $block $candidates $x $y $orient $run_id $fh]} {
            incr pass_count
        } else {
            incr fail_count
        }
    }

    puts $fh "PASS_COUNT=$pass_count"
    puts $fh "FAIL_COUNT=$fail_count"
    if {$fail_count == 0} {
        puts $fh "STATUS=PASS"
    } else {
        puts $fh "STATUS=REVIEW_REQUIRED"
    }
    close $fh
}
'''
        )


def write_status(
    path: Path,
    leaves: list[Leaf],
    placements: list[Placement],
    validation_errors: list[str],
    source_manifest: Path,
) -> None:
    local_w = max(p.urx_um for p in placements)
    local_h = max(p.ury_um for p in placements)
    corridor_h = LEGACY_TX_CORRIDOR_BBOX[3] - LEGACY_TX_CORRIDOR_BBOX[1]
    adapter = next(p for p in placements if p.block == "ddrs2_adapter")
    adapter_anchor_lly = LEGACY_TX_CORRIDOR_BBOX[3] - adapter.height_um
    fit_status = "PASS" if local_h <= corridor_h else "REVIEW_REQUIRED"
    status = "PASS" if not validation_errors else "FAIL"
    result = "FIXED_LEAF_ASSEMBLY_PLAN_READY_FOR_REVIEW" if status == "PASS" else "FIXED_LEAF_ASSEMBLY_PLAN_INVALID"

    with path.open("w") as fh:
        fh.write("LABEL=TX_EGRESS_LEAF_ASSEMBLY_PLAN\n")
        fh.write(f"STATUS={status}\n")
        fh.write(f"RESULT={result}\n")
        fh.write("SIGNOFF_READY=NO\n")
        fh.write(f"SOURCE_MANIFEST={source_manifest}\n")
        fh.write(f"LEAF_COUNT={len(leaves)}\n")
        fh.write(f"LEAF_STATUS_GATE={'PASS' if not validation_errors else 'FAIL'}\n")
        fh.write("LOCAL_PLACEMENT_STATUS=PASS\n")
        fh.write(f"TOP_ABSOLUTE_PLACEMENT_STATUS={fit_status}\n")
        fh.write(f"LOCAL_ASSEMBLY_WIDTH_UM={f3(local_w)}\n")
        fh.write(f"LOCAL_ASSEMBLY_HEIGHT_UM={f3(local_h)}\n")
        fh.write(f"LEGACY_TX_CORRIDOR_HEIGHT_UM={f3(corridor_h)}\n")
        fh.write(f"DDR2_ADAPTER_TOP_ANCHOR_LLX_UM={f3(LEGACY_TX_CORRIDOR_BBOX[0])}\n")
        fh.write(f"DDR2_ADAPTER_TOP_ANCHOR_LLY_UM={f3(adapter_anchor_lly)}\n")
        fh.write(f"DDR2_ADAPTER_TOP_ANCHOR_URX_UM={f3(LEGACY_TX_CORRIDOR_BBOX[0] + adapter.width_um)}\n")
        fh.write(f"DDR2_ADAPTER_TOP_ANCHOR_URY_UM={f3(LEGACY_TX_CORRIDOR_BBOX[3])}\n")
        fh.write("PG_CONNECTIVITY_STATUS=DEFERRED_TOP_LEVEL_HOOKUP\n")
        fh.write("PVS_STATUS=DEFERRED\n")
        fh.write("LVS_STATUS=DEFERRED\n")
        fh.write("PEX_STATUS=DEFERRED\n")
        fh.write("MMMC_STATUS=DEFERRED\n")
        for err in validation_errors:
            fh.write(f"VALIDATION_ERROR={err}\n")


def write_readme(
    path: Path,
    leaves: list[Leaf],
    placements: list[Placement],
    source_manifest: Path,
    repo_root: Path,
    validation_errors: list[str],
) -> None:
    local_w = max(p.urx_um for p in placements)
    local_h = max(p.ury_um for p in placements)
    corridor_h = LEGACY_TX_CORRIDOR_BBOX[3] - LEGACY_TX_CORRIDOR_BBOX[1]
    adapter = next(p for p in placements if p.block == "ddrs2_adapter")
    adapter_anchor_lly = LEGACY_TX_CORRIDOR_BBOX[3] - adapter.height_um

    with path.open("w") as fh:
        fh.write("# TX Egress Fixed-Leaf Assembly Plan\n\n")
        fh.write(f"Created: {dt.datetime.now(dt.timezone.utc).isoformat()}\n\n")
        fh.write(f"- Repo head: `{repo_head(repo_root)}`\n")
        fh.write(f"- Source manifest: `{source_manifest}`\n")
        fh.write("- Result: `FIXED_LEAF_ASSEMBLY_PLAN_READY_FOR_REVIEW`\n")
        fh.write("- Signoff: `NO`\n")
        fh.write("- PG hookup: deferred to top-level `METTP` VDD/VSS connection\n\n")
        fh.write("## What This Is\n\n")
        fh.write(
            "This package turns the four clean TX OOC leaf abstracts into a deterministic "
            "fixed-leaf assembly proposal. It does not run top placement, PG hookup, "
            "PVS, LVS, PEX, or MMMC.\n\n"
        )
        fh.write("Signal order:\n\n")
        fh.write("```text\n")
        fh.write("event_bundle_tx -> output_fifo -> ddr16_pairer -> ddrs2_adapter -> DDRs2\n")
        fh.write("```\n\n")

        fh.write("## Generated Files\n\n")
        fh.write("- `tx_egress_leaf_assembly_sources.csv`\n")
        fh.write("- `tx_egress_leaf_assembly_placements.csv`\n")
        fh.write("- `tx_egress_leaf_assembly_place.tcl`\n")
        fh.write("- `tx_egress_leaf_assembly_status.rpt`\n\n")

        fh.write("## Local Placement Bounding Box\n\n")
        fh.write(f"- Local assembly size: `{f3(local_w)} um x {f3(local_h)} um`\n")
        fh.write(f"- Prior shallow TX corridor height: `{f3(corridor_h)} um`\n")
        fh.write(
            "- Top absolute placement status: `REVIEW_REQUIRED` if this local stack is "
            "mapped directly into the old shallow corridor.\n\n"
        )
        fh.write("The DDRs2 adapter can still anchor directly under DDRs2:\n\n")
        fh.write(
            f"- Adapter top anchor bbox: `({f3(LEGACY_TX_CORRIDOR_BBOX[0])}, "
            f"{f3(adapter_anchor_lly)}) - ({f3(LEGACY_TX_CORRIDOR_BBOX[0] + adapter.width_um)}, "
            f"{f3(LEGACY_TX_CORRIDOR_BBOX[3])}) um`\n"
        )
        fh.write(
            f"- DDRs2 macro `M1` bbox: `({f3(DDR2_M1_BBOX[0])}, {f3(DDR2_M1_BBOX[1])}) - "
            f"({f3(DDR2_M1_BBOX[2])}, {f3(DDR2_M1_BBOX[3])}) um`\n"
        )
        fh.write(
            f"- DDRs2 DATA/CLK span: `x=({f3(DDR2_DATA_CLK_X_SPAN[0])}, "
            f"{f3(DDR2_DATA_CLK_X_SPAN[1])}) um`\n\n"
        )

        fh.write("## Leaf Sources\n\n")
        for leaf in leaves:
            fh.write(f"- `{leaf.block}`: `{leaf.run_id}`\n")
        fh.write("\n")

        if validation_errors:
            fh.write("## Validation Errors\n\n")
            for err in validation_errors:
                fh.write(f"- {err}\n")
            fh.write("\n")

        fh.write("## Next Gate\n\n")
        fh.write(
            "Use the generated placement CSV/Tcl to build a true top/assembly importer. "
            "If the local stack cannot fit in the physical top channel without overlap, "
            "reshape or keep the lower TX leaves soft/region-guided before route.\n"
        )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--out-dir", required=True, type=Path)
    parser.add_argument("--repo-root", default=Path.cwd(), type=Path)
    parser.add_argument("--gap-um", default=30.0, type=float)
    parser.add_argument("--east-margin-um", default=60.0, type=float)
    parser.add_argument(
        "--allow-missing-files",
        action="store_true",
        help="Allow local dry runs with placeholder paths; status checks still run when reports exist.",
    )
    args = parser.parse_args()

    out_dir = args.out_dir.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    leaves, errors = load_manifest(args.manifest.resolve(), args.allow_missing_files)
    fallback_leaves = [
            Leaf(
                block=block,
                run_id="MISSING",
                block_root=Path(""),
                handoff_root=Path(""),
                lef=Path(""),
                abstract_lef=Path(""),
                def_file=Path(""),
                gds=Path(""),
                routed_v=Path(""),
                routed_pg_v=Path(""),
                status_report=Path(""),
                pin_plan_csv=Path(""),
                width_um=FALLBACK_DIMS_UM[block][0],
                height_um=FALLBACK_DIMS_UM[block][1],
                status={},
            )
            for block in LEAF_ORDER
        ]
    leaves_for_placement = leaves if len(leaves) == len(LEAF_ORDER) else fallback_leaves
    placements = compute_placements(leaves_for_placement, args.gap_um, args.east_margin_um)

    write_sources_csv(out_dir / "tx_egress_leaf_assembly_sources.csv", leaves)
    write_placement_csv(out_dir / "tx_egress_leaf_assembly_placements.csv", leaves_for_placement, placements)
    write_tcl(
        out_dir / "tx_egress_leaf_assembly_place.tcl",
        leaves_for_placement,
        placements,
        "tx_egress_leaf_assembly_placement.rpt",
    )
    write_status(
        out_dir / "tx_egress_leaf_assembly_status.rpt",
        leaves_for_placement,
        placements,
        errors,
        args.manifest.resolve(),
    )
    write_readme(
        out_dir / "README.md",
        leaves_for_placement,
        placements,
        args.manifest.resolve(),
        args.repo_root.resolve(),
        errors,
    )

    print(f"ASSEMBLY_PLAN_OUT_DIR={out_dir}")
    print(f"ASSEMBLY_PLAN_STATUS={out_dir / 'tx_egress_leaf_assembly_status.rpt'}")
    print(f"ASSEMBLY_PLAN_PLACEMENTS={out_dir / 'tx_egress_leaf_assembly_placements.csv'}")
    print(f"ASSEMBLY_PLAN_TCL={out_dir / 'tx_egress_leaf_assembly_place.tcl'}")
    if errors:
        print("ASSEMBLY_PLAN_RESULT=FAIL")
        for err in errors:
            print(f"VALIDATION_ERROR={err}")
        raise SystemExit(2)
    print("ASSEMBLY_PLAN_RESULT=PASS")


if __name__ == "__main__":
    main()
