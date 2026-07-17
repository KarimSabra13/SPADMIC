#!/usr/bin/env bash

###############################################################################
# P09-R04 - immutable Position handoff staging and audit only
#
# Usage:
#   bash TOP/ci/server_stage_position_core_handoff.sh <expected-repository-head>
###############################################################################

set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
EXPECTED_HEAD="${1:-MISSING}"
EXPECTED_SOURCE_HEAD=179baaf3fc35c931d95d47d70f84c760ccfd17ed

SPADMIC_WORK_ROOT=/sim/ksabra/SPADMIC_work
POSITION_GENUS_RUN=genus_ooc_position_core_20260717_101642
POSITION_PNR_RUN=innovus_ooc_harden_position_core_gridfit_20260717_114810
POSITION_PACKAGE_VERSION="$POSITION_PNR_RUN"
HANDOFF_ROOT="$SPADMIC_WORK_ROOT/handoff/innovus"

POSITION_GENUS_ROOT="$SPADMIC_WORK_ROOT/genus/$POSITION_GENUS_RUN/position_core"
POSITION_RUN_ROOT="$SPADMIC_WORK_ROOT/innovus/$POSITION_PNR_RUN"
POSITION_PNR_ROOT="$POSITION_RUN_ROOT/blocks/position_core"
PACKAGE="$HANDOFF_ROOT/blocks/spadmic_position_core/$POSITION_PACKAGE_VERSION"

POSITION_GDS="$POSITION_PNR_ROOT/outputs/position_core.gds"
POSITION_LEF="$POSITION_PNR_ROOT/outputs/position_core.abstract.lef"
POSITION_DEF="$POSITION_PNR_ROOT/outputs/position_core.def"
POSITION_PG_NETLIST="$POSITION_PNR_ROOT/outputs/position_core.routed.pg.v"
STDCELL_CDL=/data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/cdl/xh018_D_CELLS_JIHD.cdl

EXPECTED_GDS_SHA=ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1
EXPECTED_LEF_SHA=1eb91d021edccd4806a5516ef1f2aa0a2718607ee84c248d2d0e12cd8e698683
EXPECTED_PG_NETLIST_SHA=4078d8b5f277923948371898663ea2b0093fae205bad09e2f91c5f502f251cfd
EXPECTED_GENUS_NETLIST_SHA=53bc725784e78fba8c2188f8ef9e31965abc84ffa02c195be1bf8e6e916518c6
EXPECTED_GENUS_SDC_SHA=69929a339cb2b2951bee4f7b2b6b558277e13bfac504951c57b38cf497d4f21f

RUN_OK=1
CD_RC=NOT_RUN
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
PORTFOLIO_RC=NOT_RUN
SOURCE_FILE_GATE_RC=NOT_RUN
SOURCE_HASH_GATE_RC=NOT_RUN
SOURCE_STATUS_GATE_RC=NOT_RUN
PACKAGE_ABSENCE_RC=NOT_RUN
HANDOFF_STAGE_RC=NOT_RUN
HANDOFF_AUDIT_RC=NOT_RUN
PACKAGE_HASH_GATE_RC=NOT_RUN
MANIFEST_GATE_RC=NOT_RUN
QUALIFICATION_GATE_RC=NOT_RUN
AUDIT_REPORT_GATE_RC=NOT_RUN
SOURCE_PREP_GATE_RC=NOT_RUN
PACKAGE_EVIDENCE_GATE_RC=NOT_RUN

if [ "$EXPECTED_HEAD" = "MISSING" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: expected repository HEAD argument missing"
    RUN_OK=0
fi

if [ -d "$REPO/.git" ]; then
    cd "$REPO"
    CD_RC=$?
else
    echo "STOP_HERE_DO_NOT_CONTINUE: repository missing: $REPO"
    RUN_OK=0
fi

echo "CD_RC=$CD_RC"

if [ "$RUN_OK" -eq 1 ]; then
    git checkout SPADMIC_test
    CHECKOUT_RC=$?

    if [ "$CHECKOUT_RC" -eq 0 ]; then
        git pull --ff-only origin SPADMIC_test
        PULL_RC=$?
    fi

    ACTUAL_HEAD="$(git rev-parse HEAD 2>/dev/null)"

    git diff --quiet -- TOP/rtl TOP/syn TOP/pnr TOP/ci TOP/docs
    TRACKED_DIFF_RC=$?

    git diff --cached --quiet -- TOP/rtl TOP/syn TOP/pnr TOP/ci TOP/docs
    STAGED_DIFF_RC=$?

    echo "CHECKOUT_RC=$CHECKOUT_RC"
    echo "PULL_RC=$PULL_RC"
    echo "EXPECTED_HEAD=$EXPECTED_HEAD"
    echo "ACTUAL_HEAD=$ACTUAL_HEAD"
    echo "TRACKED_DIFF_RC=$TRACKED_DIFF_RC"
    echo "STAGED_DIFF_RC=$STAGED_DIFF_RC"

    git status --short --branch --untracked-files=no

    if [ "$CHECKOUT_RC" -ne 0 ] || \
       [ "$PULL_RC" != "0" ] || \
       [ "$ACTUAL_HEAD" != "$EXPECTED_HEAD" ] || \
       [ "$TRACKED_DIFF_RC" -ne 0 ] || \
       [ "$STAGED_DIFF_RC" -ne 0 ]; then

        echo "STOP_HERE_DO_NOT_CONTINUE: checkout is not attributable"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    python3 TOP/pnr/scripts/validate_digital_subblock_portfolio.py
    PORTFOLIO_RC=$?

    echo "PORTFOLIO_RC=$PORTFOLIO_RC"

    if [ "$PORTFOLIO_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: portfolio gate failed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    SOURCE_FILE_GATE_RC=0

    for FILE in \
        "$POSITION_GDS" \
        "$POSITION_LEF" \
        "$POSITION_DEF" \
        "$POSITION_PG_NETLIST" \
        "$POSITION_GENUS_ROOT/outputs/position_core.postsyn.v" \
        "$POSITION_GENUS_ROOT/outputs/position_core.postsyn.sdc" \
        "$POSITION_GENUS_ROOT/reports/timing/tc_ooc_gate.rpt" \
        "$POSITION_PNR_ROOT/reports/floorplan_geometry.rpt" \
        "$POSITION_PNR_ROOT/reports/ooc_harden_status.rpt" \
        "$POSITION_PNR_ROOT/reports/verify_connectivity_regular.rpt" \
        "$POSITION_PNR_ROOT/reports/verify_connectivity_pg.rpt" \
        "$POSITION_PNR_ROOT/reports/verify_drc_post_route.rpt" \
        "$POSITION_PNR_ROOT/reports/DRC_MARKER_CLASSIFICATION.rpt" \
        "$POSITION_PNR_ROOT/reports/report_timing_post_route.rpt" \
        "$POSITION_PNR_ROOT/reports/gds_export_audit.rpt" \
        "$POSITION_PNR_ROOT/generated/ooc_block_harden_config.tcl" \
        "$POSITION_PNR_ROOT/generated/ooc_harden_input_manifest.csv" \
        "$POSITION_PNR_ROOT/generated/ooc_block_pin_plan.csv" \
        "$POSITION_RUN_ROOT/run_manifest.txt" \
        "$POSITION_RUN_ROOT/reports/ooc_harden_manifest.csv" \
        "$POSITION_RUN_ROOT/SUMMARY.md" \
        "$POSITION_PNR_ROOT/logs/innovus.log" \
        "$POSITION_PNR_ROOT/logs/innovus.stdout.log" \
        "$STDCELL_CDL"
    do
        if [ ! -s "$FILE" ]; then
            echo "MISSING_OR_EMPTY=$FILE"
            SOURCE_FILE_GATE_RC=1
        fi
    done

    echo "SOURCE_FILE_GATE_RC=$SOURCE_FILE_GATE_RC"

    if [ "$SOURCE_FILE_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: source package evidence is incomplete"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    ACTUAL_GDS_SHA="$(sha256sum "$POSITION_GDS" | awk '{print $1}')"
    ACTUAL_LEF_SHA="$(sha256sum "$POSITION_LEF" | awk '{print $1}')"
    ACTUAL_PG_NETLIST_SHA="$(sha256sum "$POSITION_PG_NETLIST" | awk '{print $1}')"
    ACTUAL_GENUS_NETLIST_SHA="$(sha256sum "$POSITION_GENUS_ROOT/outputs/position_core.postsyn.v" | awk '{print $1}')"
    ACTUAL_GENUS_SDC_SHA="$(sha256sum "$POSITION_GENUS_ROOT/outputs/position_core.postsyn.sdc" | awk '{print $1}')"

    echo "EXPECTED_GDS_SHA=$EXPECTED_GDS_SHA"
    echo "ACTUAL_GDS_SHA=$ACTUAL_GDS_SHA"
    echo "EXPECTED_LEF_SHA=$EXPECTED_LEF_SHA"
    echo "ACTUAL_LEF_SHA=$ACTUAL_LEF_SHA"
    echo "EXPECTED_PG_NETLIST_SHA=$EXPECTED_PG_NETLIST_SHA"
    echo "ACTUAL_PG_NETLIST_SHA=$ACTUAL_PG_NETLIST_SHA"
    echo "EXPECTED_GENUS_NETLIST_SHA=$EXPECTED_GENUS_NETLIST_SHA"
    echo "ACTUAL_GENUS_NETLIST_SHA=$ACTUAL_GENUS_NETLIST_SHA"
    echo "EXPECTED_GENUS_SDC_SHA=$EXPECTED_GENUS_SDC_SHA"
    echo "ACTUAL_GENUS_SDC_SHA=$ACTUAL_GENUS_SDC_SHA"

    SOURCE_HASH_GATE_RC=0

    if [ "$ACTUAL_GDS_SHA" != "$EXPECTED_GDS_SHA" ] || \
       [ "$ACTUAL_LEF_SHA" != "$EXPECTED_LEF_SHA" ] || \
       [ "$ACTUAL_PG_NETLIST_SHA" != "$EXPECTED_PG_NETLIST_SHA" ] || \
       [ "$ACTUAL_GENUS_NETLIST_SHA" != "$EXPECTED_GENUS_NETLIST_SHA" ] || \
       [ "$ACTUAL_GENUS_SDC_SHA" != "$EXPECTED_GENUS_SDC_SHA" ]; then

        SOURCE_HASH_GATE_RC=1
    fi

    echo "SOURCE_HASH_GATE_RC=$SOURCE_HASH_GATE_RC"

    if [ "$SOURCE_HASH_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: source artifact hash mismatch"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    SOURCE_STATUS_GATE_RC=0

    for EXPECTED_LINE in \
        'RESULT=ABSTRACT_READY_FOR_TOP_REVIEW' \
        'TOP_RESERVATION_FIT_STATUS=PASS' \
        'ACTUAL_DIE_WIDTH_UM=951.440' \
        'ACTUAL_DIE_HEIGHT_UM=659.680' \
        'INNOVUS_DRC_STATUS=PASS' \
        'DRC_MARKER_TOTAL=0' \
        'MET1_MIN_AREA_MARKER_COUNT=0' \
        'ANTENNA_MARKER_COUNT=0' \
        'OTHER_MARKER_COUNT=0' \
        'REGULAR_CONNECTIVITY_STATUS=PASS' \
        'PG_CONNECTIVITY_STATUS=PASS' \
        'POSTROUTE_SETUP_TIMING=PASS' \
        'POSTROUTE_HOLD_TIMING=PASS' \
        'ROUTE_PROFILE=met1_effort' \
        'SIGNAL_ROUTE_LAYERS=MET1-MET3' \
        'PG_LOCAL_ROUTE_MODE=EXPLICIT_EXACT' \
        'PG_ROUTE_STRATEGY=EXPLICIT_EXACT'
    do
        grep -Fqx "$EXPECTED_LINE" "$POSITION_PNR_ROOT/reports/ooc_harden_status.rpt"
        LINE_RC=$?
        echo "SOURCE_STATUS_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"

        if [ "$LINE_RC" -ne 0 ]; then
            SOURCE_STATUS_GATE_RC=1
        fi
    done

    for EXPECTED_LINE in \
        'STATUS=PASS' \
        'ACTUAL_DIE_WIDTH_UM=951.440' \
        'ACTUAL_DIE_HEIGHT_UM=659.680' \
        'TOP_RESERVATION_WIDTH_MARGIN_UM=0.255' \
        'TOP_RESERVATION_HEIGHT_MARGIN_UM=0.320'
    do
        grep -Fqx "$EXPECTED_LINE" "$POSITION_PNR_ROOT/reports/floorplan_geometry.rpt"
        LINE_RC=$?
        echo "SOURCE_FIT_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"

        if [ "$LINE_RC" -ne 0 ]; then
            SOURCE_STATUS_GATE_RC=1
        fi
    done

    for EXPECTED_LINE in \
        'STATUS=PASS' \
        'GDS_FILE_STATUS=PASS' \
        'GDS_LAYER_MAP_STATUS=PASS' \
        'GDS_MERGE_STATUS=PASS' \
        "GDS_SHA256=$EXPECTED_GDS_SHA" \
        'ERROR_COUNT=0'
    do
        grep -Fqx "$EXPECTED_LINE" "$POSITION_PNR_ROOT/reports/gds_export_audit.rpt"
        LINE_RC=$?
        echo "SOURCE_GDS_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"

        if [ "$LINE_RC" -ne 0 ]; then
            SOURCE_STATUS_GATE_RC=1
        fi
    done

    for EXPECTED_LINE in \
        'STATUS=PASS' \
        'RESULT=READY_FOR_ISOLATED_INNOVUS_OOC'
    do
        grep -Fqx "$EXPECTED_LINE" "$POSITION_GENUS_ROOT/reports/timing/tc_ooc_gate.rpt"
        LINE_RC=$?
        echo "SOURCE_GENUS_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"

        if [ "$LINE_RC" -ne 0 ]; then
            SOURCE_STATUS_GATE_RC=1
        fi
    done

    for EXPECTED_LINE in \
        'BRANCH=SPADMIC_test' \
        "HEAD=$EXPECTED_SOURCE_HEAD"
    do
        grep -Fqx "$EXPECTED_LINE" "$POSITION_RUN_ROOT/run_manifest.txt"
        LINE_RC=$?
        echo "SOURCE_RUN_MANIFEST_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"

        if [ "$LINE_RC" -ne 0 ]; then
            SOURCE_STATUS_GATE_RC=1
        fi
    done

    echo "SOURCE_STATUS_GATE_RC=$SOURCE_STATUS_GATE_RC"

    if [ "$SOURCE_STATUS_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: accepted source status mismatch"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    if [ -e "$PACKAGE" ]; then
        PACKAGE_ABSENCE_RC=1
        echo "IMMUTABLE_PACKAGE_EXISTS=$PACKAGE"
        echo "STOP_HERE_DO_NOT_OVERWRITE: choose no replacement until reviewed"
        RUN_OK=0
    else
        PACKAGE_ABSENCE_RC=0
    fi

    echo "PACKAGE_ABSENCE_RC=$PACKAGE_ABSENCE_RC"
    echo "PACKAGE=$PACKAGE"
fi

if [ "$RUN_OK" -eq 1 ]; then
    python3 TOP/pnr/scripts/stage_innovus_handoff.py \
        --kind block \
        --name spadmic_position_core \
        --version "$POSITION_PACKAGE_VERSION" \
        --source-root "$POSITION_PNR_ROOT" \
        --gds "$POSITION_GDS" \
        --layout-top spadmic_position_core \
        --netlist "$POSITION_PG_NETLIST" \
        --source-top spadmic_position_core \
        --lef "$POSITION_LEF" \
        --def-file "$POSITION_DEF" \
        --report "$POSITION_PNR_ROOT/reports/floorplan_geometry.rpt" \
        --report "$POSITION_PNR_ROOT/reports/ooc_harden_status.rpt" \
        --report "$POSITION_PNR_ROOT/reports/verify_connectivity_regular.rpt" \
        --report "$POSITION_PNR_ROOT/reports/verify_connectivity_pg.rpt" \
        --report "$POSITION_PNR_ROOT/reports/verify_drc_post_route.rpt" \
        --report "$POSITION_PNR_ROOT/reports/DRC_MARKER_CLASSIFICATION.rpt" \
        --report "$POSITION_PNR_ROOT/reports/report_timing_post_route.rpt" \
        --report "$POSITION_PNR_ROOT/reports/gds_export_audit.rpt" \
        --report "$POSITION_PNR_ROOT/generated/ooc_block_harden_config.tcl" \
        --report "$POSITION_PNR_ROOT/generated/ooc_harden_input_manifest.csv" \
        --report "$POSITION_PNR_ROOT/generated/ooc_block_pin_plan.csv" \
        --report "$POSITION_RUN_ROOT/run_manifest.txt" \
        --report "$POSITION_RUN_ROOT/reports/ooc_harden_manifest.csv" \
        --report "$POSITION_RUN_ROOT/SUMMARY.md" \
        --report "$POSITION_GENUS_ROOT/reports/timing/tc_ooc_gate.rpt" \
        --log "$POSITION_PNR_ROOT/logs/innovus.log" \
        --log "$POSITION_PNR_ROOT/logs/innovus.stdout.log" \
        --handoff-root "$HANDOFF_ROOT" \
        --repo-root "$REPO" \
        --state candidate \
        --stdcell-cdl "$STDCELL_CDL" \
        --qualification-profile basic

    HANDOFF_STAGE_RC=$?
    echo "HANDOFF_STAGE_RC=$HANDOFF_STAGE_RC"

    if [ "$HANDOFF_STAGE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_RUN_PVS: immutable staging failed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    python3 TOP/pnr/scripts/audit_innovus_handoff.py "$PACKAGE"
    HANDOFF_AUDIT_RC=$?

    echo "HANDOFF_AUDIT_RC=$HANDOFF_AUDIT_RC"

    if [ "$HANDOFF_AUDIT_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_RUN_PVS: package audit failed"
        RUN_OK=0
    fi
fi

if [ -d "$PACKAGE" ]; then
    echo
    echo "===== PACKAGE QUALIFICATION ====="
    cat "$PACKAGE/status/qualification.rpt" 2>/dev/null

    echo
    echo "===== PACKAGE AUDIT ====="
    cat "$PACKAGE/status/handoff_audit.rpt" 2>/dev/null

    echo
    echo "===== PACKAGE LVS SOURCE PREPARATION ====="
    cat "$PACKAGE/reports/lvs_source_preparation.rpt" 2>/dev/null

    echo
    echo "===== PACKAGE FLOORPLAN GEOMETRY ====="
    cat "$PACKAGE/reports/floorplan_geometry.rpt" 2>/dev/null

    echo
    echo "===== PACKAGE GDS EXPORT AUDIT ====="
    cat "$PACKAGE/reports/gds_export_audit.rpt" 2>/dev/null

    echo
    echo "===== PACKAGE MANIFEST ====="
    cat "$PACKAGE/manifests/package.json" 2>/dev/null

    echo
    echo "===== PACKAGE SHA256SUMS ====="
    cat "$PACKAGE/manifests/SHA256SUMS" 2>/dev/null

    echo
    echo "===== PACKAGE FILES ====="
    find "$PACKAGE" -type f -printf '%P %s bytes\n' 2>/dev/null | sort
fi

if [ "$RUN_OK" -eq 1 ]; then
    PACKAGE_GDS="$PACKAGE/gds/spadmic_position_core.gds"
    PACKAGE_LEF="$PACKAGE/lef/position_core.abstract.lef"
    PACKAGE_RAW_NETLIST="$PACKAGE/netlist/spadmic_position_core.innovus.pg.v"
    PACKAGE_LVS_NETLIST="$PACKAGE/netlist/spadmic_position_core.lvs.pg.v"
    PACKAGE_MANIFEST="$PACKAGE/manifests/package.json"
    PACKAGE_QUALIFICATION="$PACKAGE/status/qualification.rpt"
    PACKAGE_AUDIT="$PACKAGE/status/handoff_audit.rpt"
    PACKAGE_SOURCE_PREP="$PACKAGE/reports/lvs_source_preparation.rpt"

    ACTUAL_PACKAGE_GDS_SHA="$(sha256sum "$PACKAGE_GDS" | awk '{print $1}')"
    ACTUAL_PACKAGE_LEF_SHA="$(sha256sum "$PACKAGE_LEF" | awk '{print $1}')"
    ACTUAL_PACKAGE_RAW_NETLIST_SHA="$(sha256sum "$PACKAGE_RAW_NETLIST" | awk '{print $1}')"
    ACTUAL_PACKAGE_LVS_NETLIST_SHA="$(sha256sum "$PACKAGE_LVS_NETLIST" | awk '{print $1}')"

    echo "ACTUAL_PACKAGE_GDS_SHA=$ACTUAL_PACKAGE_GDS_SHA"
    echo "ACTUAL_PACKAGE_LEF_SHA=$ACTUAL_PACKAGE_LEF_SHA"
    echo "ACTUAL_PACKAGE_RAW_NETLIST_SHA=$ACTUAL_PACKAGE_RAW_NETLIST_SHA"
    echo "ACTUAL_PACKAGE_LVS_NETLIST_SHA=$ACTUAL_PACKAGE_LVS_NETLIST_SHA"

    PACKAGE_HASH_GATE_RC=0

    if [ "$ACTUAL_PACKAGE_GDS_SHA" != "$EXPECTED_GDS_SHA" ] || \
       [ "$ACTUAL_PACKAGE_LEF_SHA" != "$EXPECTED_LEF_SHA" ] || \
       [ "$ACTUAL_PACKAGE_RAW_NETLIST_SHA" != "$EXPECTED_PG_NETLIST_SHA" ] || \
       [ -z "$ACTUAL_PACKAGE_LVS_NETLIST_SHA" ]; then

        PACKAGE_HASH_GATE_RC=1
    fi

    echo "PACKAGE_HASH_GATE_RC=$PACKAGE_HASH_GATE_RC"

    python3 -c '
import hashlib
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
expected_head = sys.argv[2]
expected_source_root = str(Path(sys.argv[3]).resolve())
expected_version = sys.argv[4]
data = json.loads(manifest_path.read_text())

expected = {
    "schema": "spadmic.innovus_handoff.v1",
    "kind": "block",
    "name": "spadmic_position_core",
    "version": expected_version,
    "state": "candidate",
    "qualification_profile": "basic",
    "source_root": expected_source_root,
    "layout_top": "spadmic_position_core",
    "source_top": "spadmic_position_core",
    "repo_branch": "SPADMIC_test",
    "repo_head": expected_head,
}
errors = []
for key, value in expected.items():
    actual = data.get(key, "MISSING")
    print(f"MANIFEST_{key.upper()}={actual}")
    if actual != value:
        errors.append(f"{key}={actual} expected={value}")

lvs_source = Path(data.get("lvs_source", ""))
if not lvs_source.is_file():
    errors.append("lvs_source_missing")
else:
    actual_lvs_sha = hashlib.sha256(lvs_source.read_bytes()).hexdigest()
    manifest_lvs_sha = data.get("lvs_source_sha256", "MISSING")
    print(f"MANIFEST_LVS_SOURCE_SHA256={manifest_lvs_sha}")
    print(f"ACTUAL_LVS_SOURCE_SHA256={actual_lvs_sha}")
    if data.get("lvs_source_sha256") != actual_lvs_sha:
        errors.append("lvs_source_sha256_mismatch")

for error in errors:
    print(f"MANIFEST_ERROR={error}")
sys.exit(1 if errors else 0)
' "$PACKAGE_MANIFEST" "$EXPECTED_HEAD" "$POSITION_PNR_ROOT" "$POSITION_PACKAGE_VERSION"
    MANIFEST_GATE_RC=$?

    QUALIFICATION_GATE_RC=0
    for EXPECTED_LINE in \
        'PACKAGE_STATUS=CANDIDATE' \
        'CANONICAL_NAME_STATUS=PASS' \
        'BLOCK_PROMOTION_AUTHORIZED=NO' \
        'LVS_SOURCE_PREPARATION_STATUS=PASS' \
        'PIN_PARITY_STATUS=PASS' \
        'STDCELL_CDL_STATUS=PASS' \
        'BBOX_PARITY_STATUS=UNKNOWN' \
        'PVS_BASE_DRC_STATUS=NOT_RUN' \
        'PVS_DENSITY_DRC_STATUS=NOT_RUN' \
        'PVS_LVS_STATUS=NOT_RUN' \
        'SIGNOFF_READY=NO'
    do
        grep -Fqx "$EXPECTED_LINE" "$PACKAGE_QUALIFICATION"
        LINE_RC=$?
        echo "QUALIFICATION_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"

        if [ "$LINE_RC" -ne 0 ]; then
            QUALIFICATION_GATE_RC=1
        fi
    done

    AUDIT_REPORT_GATE_RC=0
    for EXPECTED_LINE in \
        'STATUS=PASS' \
        'CANONICAL_NAME=spadmic_position_core' \
        'LAYOUT_TOP=spadmic_position_core' \
        'SOURCE_TOP=spadmic_position_core' \
        'LVS_SOURCE_PREPARATION_STATUS=PASS' \
        'PIN_PARITY_STATUS=PASS' \
        'STDCELL_CDL_STATUS=PASS' \
        'QUALIFICATION_PROFILE=basic' \
        'TEMPORARY_DRC_WAIVER_STATUS=NOT_APPLICABLE' \
        'FINAL_SIGNOFF_READY=NO' \
        'ERROR_COUNT=0'
    do
        grep -Fqx "$EXPECTED_LINE" "$PACKAGE_AUDIT"
        LINE_RC=$?
        echo "AUDIT_REPORT_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"

        if [ "$LINE_RC" -ne 0 ]; then
            AUDIT_REPORT_GATE_RC=1
        fi
    done

    SOURCE_PREP_GATE_RC=0
    for EXPECTED_LINE in \
        'STATUS=PASS' \
        'SOURCE_TOP=spadmic_position_core' \
        "INPUT_SHA256=$EXPECTED_PG_NETLIST_SHA" \
        'PIN_PARITY_STATUS=PASS' \
        'ERROR_COUNT=0'
    do
        grep -Fqx "$EXPECTED_LINE" "$PACKAGE_SOURCE_PREP"
        LINE_RC=$?
        echo "SOURCE_PREP_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"

        if [ "$LINE_RC" -ne 0 ]; then
            SOURCE_PREP_GATE_RC=1
        fi
    done

    PACKAGE_EVIDENCE_GATE_RC=0
    for EXPECTED_LINE in \
        'STATUS=PASS' \
        'ACTUAL_DIE_WIDTH_UM=951.440' \
        'ACTUAL_DIE_HEIGHT_UM=659.680' \
        'TOP_RESERVATION_WIDTH_MARGIN_UM=0.255' \
        'TOP_RESERVATION_HEIGHT_MARGIN_UM=0.320'
    do
        grep -Fqx "$EXPECTED_LINE" "$PACKAGE/reports/floorplan_geometry.rpt"
        LINE_RC=$?
        echo "PACKAGE_FIT_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"

        if [ "$LINE_RC" -ne 0 ]; then
            PACKAGE_EVIDENCE_GATE_RC=1
        fi
    done

    for EXPECTED_LINE in \
        'STATUS=PASS' \
        'GDS_FILE_STATUS=PASS' \
        'GDS_LAYER_MAP_STATUS=PASS' \
        'GDS_MERGE_STATUS=PASS' \
        "GDS_SHA256=$EXPECTED_GDS_SHA" \
        'ERROR_COUNT=0'
    do
        grep -Fqx "$EXPECTED_LINE" "$PACKAGE/reports/gds_export_audit.rpt"
        LINE_RC=$?
        echo "PACKAGE_GDS_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"

        if [ "$LINE_RC" -ne 0 ]; then
            PACKAGE_EVIDENCE_GATE_RC=1
        fi
    done

    echo "MANIFEST_GATE_RC=$MANIFEST_GATE_RC"
    echo "QUALIFICATION_GATE_RC=$QUALIFICATION_GATE_RC"
    echo "AUDIT_REPORT_GATE_RC=$AUDIT_REPORT_GATE_RC"
    echo "SOURCE_PREP_GATE_RC=$SOURCE_PREP_GATE_RC"
    echo "PACKAGE_EVIDENCE_GATE_RC=$PACKAGE_EVIDENCE_GATE_RC"
fi

echo
echo "===== FINAL IMMUTABLE STAGING GATE ====="
echo "RUN_OK=$RUN_OK"
echo "HANDOFF_STAGE_RC=$HANDOFF_STAGE_RC"
echo "HANDOFF_AUDIT_RC=$HANDOFF_AUDIT_RC"
echo "PACKAGE_HASH_GATE_RC=$PACKAGE_HASH_GATE_RC"
echo "MANIFEST_GATE_RC=$MANIFEST_GATE_RC"
echo "QUALIFICATION_GATE_RC=$QUALIFICATION_GATE_RC"
echo "AUDIT_REPORT_GATE_RC=$AUDIT_REPORT_GATE_RC"
echo "SOURCE_PREP_GATE_RC=$SOURCE_PREP_GATE_RC"
echo "PACKAGE_EVIDENCE_GATE_RC=$PACKAGE_EVIDENCE_GATE_RC"
echo "PACKAGE=$PACKAGE"

if [ "$RUN_OK" -eq 1 ] && \
   [ "$HANDOFF_STAGE_RC" = "0" ] && \
   [ "$HANDOFF_AUDIT_RC" = "0" ] && \
   [ "$PACKAGE_HASH_GATE_RC" = "0" ] && \
   [ "$MANIFEST_GATE_RC" = "0" ] && \
   [ "$QUALIFICATION_GATE_RC" = "0" ] && \
   [ "$AUDIT_REPORT_GATE_RC" = "0" ] && \
   [ "$SOURCE_PREP_GATE_RC" = "0" ] && \
   [ "$PACKAGE_EVIDENCE_GATE_RC" = "0" ]; then

    echo "POSITION_IMMUTABLE_HANDOFF_STAGING_STATUS=PASS"
    echo "BLOCK_PROMOTION_AUTHORIZED=NO"
    echo "SIGNOFF_READY=NO"
    echo "NEXT_GATE=POSITION_PVS_BASE_DRC_AFTER_REVIEW"
    true
else
    echo "POSITION_IMMUTABLE_HANDOFF_STAGING_STATUS=FAIL"
    echo "STOP_HERE_DO_NOT_RUN_PVS"
    false
fi
