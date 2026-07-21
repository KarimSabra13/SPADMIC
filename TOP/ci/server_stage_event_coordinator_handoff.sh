#!/usr/bin/env bash

###############################################################################
# P10-R04 - immutable Event coordinator handoff staging and audit only
#
# Usage:
#   bash TOP/ci/server_stage_event_coordinator_handoff.sh <expected-repository-head>
###############################################################################

set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
EXPECTED_HEAD="${1:-MISSING}"
EXPECTED_SOURCE_HEAD=1b922f0723112e5916107775069c767388ec500e
EXPECTED_GENUS_HEAD=b53b1fade963c6c57c6b0629ae9a4b21fdac06db

WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
SOURCE_DIAGNOSTIC_ROOT="$WORK_ROOT/diagnostics/event_innovus_execution_20260720_173527"
EVENT_GENUS_RUN=genus_ooc_event_coordinator_20260720_163038
EVENT_INNOVUS_RUN=innovus_ooc_harden_event_coordinator_20260720_173527
EVENT_PACKAGE_VERSION="$EVENT_INNOVUS_RUN"

EVENT_GENUS_ROOT="$WORK_ROOT/genus/$EVENT_GENUS_RUN/event_coordinator"
EVENT_INNOVUS_RUN_ROOT="$WORK_ROOT/innovus/$EVENT_INNOVUS_RUN"
EVENT_INNOVUS_ROOT="$EVENT_INNOVUS_RUN_ROOT/blocks/event_coordinator"
HANDOFF_ROOT="$WORK_ROOT/handoff/innovus"
PACKAGE="$HANDOFF_ROOT/blocks/spadmic_event_coordinator/$EVENT_PACKAGE_VERSION"

EVENT_GDS="$EVENT_INNOVUS_ROOT/outputs/event_coordinator.gds"
EVENT_LEF="$EVENT_INNOVUS_ROOT/outputs/event_coordinator.abstract.lef"
EVENT_DEF="$EVENT_INNOVUS_ROOT/outputs/event_coordinator.def"
EVENT_PG_NETLIST="$EVENT_INNOVUS_ROOT/outputs/event_coordinator.routed.pg.v"
EVENT_GENUS_NETLIST="$EVENT_GENUS_ROOT/outputs/event_coordinator.postsyn.v"
EVENT_GENUS_SDC="$EVENT_GENUS_ROOT/outputs/event_coordinator.postsyn.sdc"
STDCELL_CDL=/data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/cdl/xh018_D_CELLS_JIHD.cdl

EXPECTED_GDS_SHA256=837538f219dacc9521f02bc58b3e2e5e587f859b4e70b69a1ca4a3e5fe7b6857
EXPECTED_LEF_SHA256=56345986a887317f0374984b1ea8b3442ea482aeec0572614e9fd2c0b6732a14
EXPECTED_DEF_SHA256=f9d6a927c7cecad40916cac67b8142f6fb6c6b013e3d57ab779889fd0ab21a68
EXPECTED_PG_NETLIST_SHA256=0ecc571317f6beaa13c7f006ac3ecc4f1ff2a72b9655a176c0fa21e3c0a07398
EXPECTED_GENUS_NETLIST_SHA256=b28454211dc5eeda84f17cc5864adcd1c15cd761a9d825e3f5a78182fe0b0ccb
EXPECTED_GENUS_SDC_SHA256=c32e0a54b392017256a790ec73352d7161093c73a4360fe933083c88f7d1cb6a
EXPECTED_STDCELL_CDL_SHA256=5ff10b0b31003da9bb6db59eba7d52c82435e3ab68b2ba0a1956e4d9fbaef8cf

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
DIAGNOSTIC_ROOT="$WORK_ROOT/diagnostics/event_handoff_staging_$TIMESTAMP"

RUN_OK=1
CD_RC=NOT_RUN
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
SCRIPT_GATE_RC=NOT_RUN
PORTFOLIO_RC=NOT_RUN
DIAGNOSTIC_CREATE_RC=NOT_RUN
SOURCE_FILE_GATE_RC=NOT_RUN
SOURCE_DIAGNOSTIC_MANIFEST_RC=NOT_RUN
SOURCE_STATUS_GATE_RC=NOT_RUN
SOURCE_COPY_IDENTITY_GATE_RC=NOT_RUN
SOURCE_HASH_GATE_RC=NOT_RUN
SOURCE_SHA_MANIFEST_CREATE_RC=NOT_RUN
PACKAGE_ABSENCE_RC=NOT_RUN
HANDOFF_STAGE_RC=NOT_RUN
HANDOFF_AUDIT_RC=NOT_RUN
PACKAGE_HASH_GATE_RC=NOT_RUN
PACKAGE_MANIFEST_GATE_RC=NOT_RUN
PACKAGE_SHA_MANIFEST_RC=NOT_RUN
QUALIFICATION_GATE_RC=NOT_RUN
AUDIT_REPORT_GATE_RC=NOT_RUN
SOURCE_PREP_GATE_RC=NOT_RUN
PACKAGE_EVIDENCE_GATE_RC=NOT_RUN
SOURCE_POST_RECHECK_RC=NOT_RUN
DIAGNOSTIC_COPY_GATE_RC=NOT_RUN
DIAGNOSTIC_MANIFEST_CREATE_RC=NOT_RUN
TRANSACTION_STATUS=FAIL
OUTCOME_CLASS=NOT_CLASSIFIED
EVENT_IMMUTABLE_HANDOFF_STAGING_STATUS=NOT_RUN
EVENT_PVS_PREFLIGHT_AUTHORIZED=NO
NEXT_GATE=STOP_AND_REVIEW_EVENT_HANDOFF_STAGING_FAILURE

require_line() {
    local file="$1"
    local expected_line="$2"
    local label="$3"

    grep -Fqx "$expected_line" "$file" 2>/dev/null
    LINE_MATCH_RC=$?
    echo "$label=$LINE_MATCH_RC FILE=$file EXPECTED=$expected_line"
}

copy_if_readable() {
    local source_file="$1"
    local destination_file="$2"
    local copy_rc

    if [ -r "$source_file" ]; then
        mkdir -p "$(dirname "$destination_file")"
        cp -p "$source_file" "$destination_file"
        copy_rc=$?
        if [ "$copy_rc" != "0" ]; then
            DIAGNOSTIC_COPY_GATE_RC=1
        fi
    else
        echo "MISSING_OR_UNREADABLE_COPY_SOURCE=$source_file"
        DIAGNOSTIC_COPY_GATE_RC=1
    fi
}

if [ "$EXPECTED_HEAD" = "MISSING" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: expected repository HEAD argument missing"
    RUN_OK=0
fi

if [ -d "$REPO/.git" ]; then
    cd "$REPO"
    CD_RC=$?
else
    echo "STOP_HERE_DO_NOT_CONTINUE: repository missing: $REPO"
    CD_RC=1
    RUN_OK=0
fi

echo "CD_RC=$CD_RC"

if [ "$RUN_OK" = "1" ]; then
    git checkout SPADMIC_test
    CHECKOUT_RC=$?

    if [ "$CHECKOUT_RC" = "0" ]; then
        git pull --ff-only origin SPADMIC_test
        PULL_RC=$?
    fi

    ACTUAL_HEAD="$(git rev-parse HEAD 2>/dev/null)"
    git diff --quiet
    TRACKED_DIFF_RC=$?
    git diff --cached --quiet
    STAGED_DIFF_RC=$?

    SCRIPT_GATE_RC=0
    for SCRIPT in \
        TOP/pnr/scripts/validate_digital_subblock_portfolio.py \
        TOP/pnr/scripts/stage_innovus_handoff.py \
        TOP/pnr/scripts/audit_innovus_handoff.py
    do
        if [ ! -f "$SCRIPT" ]; then
            echo "MISSING_SCRIPT=$SCRIPT"
            SCRIPT_GATE_RC=1
        fi
    done

    echo "CHECKOUT_RC=$CHECKOUT_RC"
    echo "PULL_RC=$PULL_RC"
    echo "EXPECTED_HEAD=$EXPECTED_HEAD"
    echo "ACTUAL_HEAD=$ACTUAL_HEAD"
    echo "TRACKED_DIFF_RC=$TRACKED_DIFF_RC"
    echo "STAGED_DIFF_RC=$STAGED_DIFF_RC"
    echo "SCRIPT_GATE_RC=$SCRIPT_GATE_RC"
    git status --short --branch --untracked-files=no

    if [ "$CHECKOUT_RC" != "0" ] || \
       [ "$PULL_RC" != "0" ] || \
       [ "$ACTUAL_HEAD" != "$EXPECTED_HEAD" ] || \
       [ "$TRACKED_DIFF_RC" != "0" ] || \
       [ "$STAGED_DIFF_RC" != "0" ] || \
       [ "$SCRIPT_GATE_RC" != "0" ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: checkout is not attributable"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ]; then
    mkdir -p "$DIAGNOSTIC_ROOT/source_innovus" \
        "$DIAGNOSTIC_ROOT/package_evidence"
    DIAGNOSTIC_CREATE_RC=$?
    echo "DIAGNOSTIC_ROOT=$DIAGNOSTIC_ROOT"
    echo "SOURCE_DIAGNOSTIC_ROOT=$SOURCE_DIAGNOSTIC_ROOT"
    echo "PACKAGE=$PACKAGE"
    echo "DIAGNOSTIC_CREATE_RC=$DIAGNOSTIC_CREATE_RC"

    if [ "$DIAGNOSTIC_CREATE_RC" != "0" ]; then
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ]; then
    python3 TOP/pnr/scripts/validate_digital_subblock_portfolio.py \
        --status "$DIAGNOSTIC_ROOT/portfolio_status.rpt"
    PORTFOLIO_RC=$?
    echo "PORTFOLIO_RC=$PORTFOLIO_RC"

    if [ "$PORTFOLIO_RC" != "0" ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: digital subblock portfolio failed"
        RUN_OK=0
    fi
fi

SOURCE_STATUS="$SOURCE_DIAGNOSTIC_ROOT/event_innovus_execution_status.rpt"
SOURCE_RUN_STATUS="$EVENT_INNOVUS_ROOT/reports/ooc_harden_status.rpt"
SOURCE_FLOORPLAN="$EVENT_INNOVUS_ROOT/reports/floorplan_geometry.rpt"
SOURCE_GDS_AUDIT="$EVENT_INNOVUS_ROOT/reports/gds_export_audit.rpt"
SOURCE_ARTIFACT_HASHES="$SOURCE_DIAGNOSTIC_ROOT/run_evidence/artifact_hashes.rpt"
SOURCE_RUN_MANIFEST="$EVENT_INNOVUS_RUN_ROOT/run_manifest.txt"

SOURCE_FILES=(
    "$SOURCE_DIAGNOSTIC_ROOT/SHA256SUMS"
    "$SOURCE_STATUS"
    "$SOURCE_DIAGNOSTIC_ROOT/portfolio_status.rpt"
    "$SOURCE_DIAGNOSTIC_ROOT/source_genus/tc_ooc_gate.revalidated.rpt"
    "$SOURCE_DIAGNOSTIC_ROOT/source_genus/SHA256SUMS.post_execution_check.rpt"
    "$SOURCE_DIAGNOSTIC_ROOT/run_evidence/ooc_harden_status.rpt"
    "$SOURCE_DIAGNOSTIC_ROOT/run_evidence/floorplan_geometry.rpt"
    "$SOURCE_DIAGNOSTIC_ROOT/run_evidence/verify_connectivity_regular.rpt"
    "$SOURCE_DIAGNOSTIC_ROOT/run_evidence/verify_connectivity_pg.rpt"
    "$SOURCE_DIAGNOSTIC_ROOT/run_evidence/verify_drc_post_route.rpt"
    "$SOURCE_DIAGNOSTIC_ROOT/run_evidence/DRC_MARKER_CLASSIFICATION.rpt"
    "$SOURCE_DIAGNOSTIC_ROOT/run_evidence/report_timing_post_route.rpt"
    "$SOURCE_DIAGNOSTIC_ROOT/run_evidence/gds_export_audit.rpt"
    "$SOURCE_ARTIFACT_HASHES"
    "$EVENT_GDS"
    "$EVENT_LEF"
    "$EVENT_DEF"
    "$EVENT_PG_NETLIST"
    "$EVENT_GENUS_NETLIST"
    "$EVENT_GENUS_SDC"
    "$EVENT_GENUS_ROOT/reports/timing/tc_ooc_gate.rpt"
    "$SOURCE_RUN_STATUS"
    "$SOURCE_FLOORPLAN"
    "$EVENT_INNOVUS_ROOT/reports/verify_connectivity_regular.rpt"
    "$EVENT_INNOVUS_ROOT/reports/verify_connectivity_pg.rpt"
    "$EVENT_INNOVUS_ROOT/reports/verify_drc_post_route.rpt"
    "$EVENT_INNOVUS_ROOT/reports/DRC_MARKER_CLASSIFICATION.rpt"
    "$EVENT_INNOVUS_ROOT/reports/report_timing_post_route.rpt"
    "$SOURCE_GDS_AUDIT"
    "$EVENT_INNOVUS_ROOT/generated/ooc_block_harden_config.tcl"
    "$EVENT_INNOVUS_ROOT/generated/ooc_harden_input_manifest.csv"
    "$EVENT_INNOVUS_ROOT/generated/ooc_block_pin_plan.csv"
    "$SOURCE_RUN_MANIFEST"
    "$EVENT_INNOVUS_RUN_ROOT/reports/ooc_harden_manifest.csv"
    "$EVENT_INNOVUS_RUN_ROOT/SUMMARY.md"
    "$EVENT_INNOVUS_ROOT/logs/innovus.log"
    "$EVENT_INNOVUS_ROOT/logs/innovus.stdout.log"
    "$STDCELL_CDL"
)

if [ "$RUN_OK" = "1" ]; then
    SOURCE_FILE_GATE_RC=0
    for FILE in "${SOURCE_FILES[@]}"
    do
        if [ ! -s "$FILE" ]; then
            echo "MISSING_OR_EMPTY=$FILE"
            SOURCE_FILE_GATE_RC=1
        fi
    done
    echo "SOURCE_FILE_GATE_RC=$SOURCE_FILE_GATE_RC"

    if [ "$SOURCE_FILE_GATE_RC" != "0" ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: Event source evidence is incomplete"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ]; then
    SOURCE_DIAGNOSTIC_MANIFEST_RC=1
    cd "$SOURCE_DIAGNOSTIC_ROOT"
    SOURCE_DIAGNOSTIC_CD_RC=$?
    if [ "$SOURCE_DIAGNOSTIC_CD_RC" = "0" ]; then
        sha256sum -c SHA256SUMS \
            > "$DIAGNOSTIC_ROOT/source_innovus/source_diagnostic_manifest_check.rpt" \
            2>&1
        SOURCE_DIAGNOSTIC_MANIFEST_RC=$?
    fi
    cd "$REPO"
    SOURCE_DIAGNOSTIC_RETURN_RC=$?

    echo "SOURCE_DIAGNOSTIC_CD_RC=$SOURCE_DIAGNOSTIC_CD_RC"
    echo "SOURCE_DIAGNOSTIC_MANIFEST_RC=$SOURCE_DIAGNOSTIC_MANIFEST_RC"
    echo "SOURCE_DIAGNOSTIC_RETURN_RC=$SOURCE_DIAGNOSTIC_RETURN_RC"

    if [ "$SOURCE_DIAGNOSTIC_MANIFEST_RC" != "0" ] || \
       [ "$SOURCE_DIAGNOSTIC_RETURN_RC" != "0" ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: Event diagnostic manifest failed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ]; then
    SOURCE_STATUS_GATE_RC=0
    for EXPECTED_LINE in \
        'STATUS=PASS' \
        'RESULT=EVENT_INNOVUS_OOC_ABSTRACT_READY_FOR_TOP_REVIEW' \
        'OUTCOME_CLASS=ATTRIBUTABLE_ABSTRACT_READY' \
        "EXPECTED_HEAD=$EXPECTED_SOURCE_HEAD" \
        "ACTUAL_HEAD=$EXPECTED_SOURCE_HEAD" \
        "SOURCE_GENUS_HEAD=$EXPECTED_GENUS_HEAD" \
        "SOURCE_GENUS_RUN=$EVENT_GENUS_RUN" \
        "SOURCE_NETLIST_SHA256=$EXPECTED_GENUS_NETLIST_SHA256" \
        "SOURCE_SDC_SHA256=$EXPECTED_GENUS_SDC_SHA256" \
        "EVENT_INNOVUS_RUN=$EVENT_INNOVUS_RUN" \
        'EVENT_INNOVUS_RC=0' \
        'EVENT_INNOVUS_OOC_STATUS=PASS' \
        'RUN_FILE_GATE_RC=0' \
        'RUN_STATUS_GATE_RC=0' \
        'RUN_GDS_GATE_RC=0' \
        'RUN_ARTIFACT_HASH_GATE_RC=0' \
        "RUN_GDS_SHA256=$EXPECTED_GDS_SHA256" \
        'SOURCE_POST_RECHECK_RC=0' \
        'DIAGNOSTIC_COPY_GATE_RC=0' \
        'EVENT_PVS_BASE_DRC_STATUS=NOT_RUN' \
        'EVENT_PVS_DENSITY_DRC_STATUS=NOT_RUN' \
        'EVENT_PVS_LVS_STATUS=NOT_RUN' \
        'EVENT_HANDOFF_STAGE_AUTHORIZED=YES' \
        'ASSEMBLY_PHASE=p02_event_control' \
        'ASSEMBLY_INSERTION_AUTHORIZED=NO' \
        'ASSEMBLY_BLOCKED_BY=p00_tx,p01_position' \
        'FULL_TOP_PNR_AUTHORIZED=NO' \
        'BLOCK_PROMOTION_AUTHORIZED=NO' \
        'SIGNOFF_READY=NO' \
        'NEXT_GATE=REVIEW_AND_STAGE_IMMUTABLE_EVENT_HANDOFF'
    do
        require_line "$SOURCE_STATUS" "$EXPECTED_LINE" SOURCE_STATUS_LINE_RC
        if [ "$LINE_MATCH_RC" != "0" ]; then
            SOURCE_STATUS_GATE_RC=1
        fi
    done

    for EXPECTED_LINE in \
        'BRANCH=SPADMIC_test' \
        "HEAD=$EXPECTED_SOURCE_HEAD" \
        'BLOCK=event_coordinator'
    do
        require_line "$SOURCE_RUN_MANIFEST" "$EXPECTED_LINE" SOURCE_RUN_MANIFEST_LINE_RC
        if [ "$LINE_MATCH_RC" != "0" ]; then
            SOURCE_STATUS_GATE_RC=1
        fi
    done

    for EXPECTED_LINE in \
        'RESULT=ABSTRACT_READY_FOR_TOP_REVIEW' \
        'TOP_RESERVATION_FIT_STATUS=PASS' \
        'ACTUAL_DIE_WIDTH_UM=237.440' \
        'ACTUAL_DIE_HEIGHT_UM=219.520' \
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
        'PG_ROUTE_STRATEGY=EXPLICIT_EXACT' \
        'PVS_STATUS=DEFERRED' \
        'MMMC_STATUS=DEFERRED_TYPICAL_ONLY' \
        'SIGNOFF_READY=NO'
    do
        require_line "$SOURCE_RUN_STATUS" "$EXPECTED_LINE" SOURCE_RUN_STATUS_LINE_RC
        if [ "$LINE_MATCH_RC" != "0" ]; then
            SOURCE_STATUS_GATE_RC=1
        fi
    done

    for EXPECTED_LINE in \
        'STATUS=PASS' \
        'ACTUAL_DIE_WIDTH_UM=237.440' \
        'ACTUAL_DIE_HEIGHT_UM=219.520' \
        'TOP_RESERVATION_WIDTH_MARGIN_UM=0.020' \
        'TOP_RESERVATION_HEIGHT_MARGIN_UM=0.480'
    do
        require_line "$SOURCE_FLOORPLAN" "$EXPECTED_LINE" SOURCE_FLOORPLAN_LINE_RC
        if [ "$LINE_MATCH_RC" != "0" ]; then
            SOURCE_STATUS_GATE_RC=1
        fi
    done

    for EXPECTED_LINE in \
        'STATUS=PASS' \
        'GDS_FILE_STATUS=PASS' \
        'GDS_LAYER_MAP_STATUS=PASS' \
        'GDS_MERGE_STATUS=PASS' \
        'GDS_BYTES=549128' \
        "GDS_SHA256=$EXPECTED_GDS_SHA256" \
        'ERROR_COUNT=0'
    do
        require_line "$SOURCE_GDS_AUDIT" "$EXPECTED_LINE" SOURCE_GDS_LINE_RC
        if [ "$LINE_MATCH_RC" != "0" ]; then
            SOURCE_STATUS_GATE_RC=1
        fi
    done

    echo "SOURCE_STATUS_GATE_RC=$SOURCE_STATUS_GATE_RC"
    if [ "$SOURCE_STATUS_GATE_RC" != "0" ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: accepted Event status mismatch"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ]; then
    SOURCE_COPY_IDENTITY_GATE_RC=0
    for PAIR in \
        "$SOURCE_DIAGNOSTIC_ROOT/run_evidence/ooc_harden_status.rpt|$SOURCE_RUN_STATUS" \
        "$SOURCE_DIAGNOSTIC_ROOT/run_evidence/floorplan_geometry.rpt|$SOURCE_FLOORPLAN" \
        "$SOURCE_DIAGNOSTIC_ROOT/run_evidence/verify_connectivity_regular.rpt|$EVENT_INNOVUS_ROOT/reports/verify_connectivity_regular.rpt" \
        "$SOURCE_DIAGNOSTIC_ROOT/run_evidence/verify_connectivity_pg.rpt|$EVENT_INNOVUS_ROOT/reports/verify_connectivity_pg.rpt" \
        "$SOURCE_DIAGNOSTIC_ROOT/run_evidence/verify_drc_post_route.rpt|$EVENT_INNOVUS_ROOT/reports/verify_drc_post_route.rpt" \
        "$SOURCE_DIAGNOSTIC_ROOT/run_evidence/DRC_MARKER_CLASSIFICATION.rpt|$EVENT_INNOVUS_ROOT/reports/DRC_MARKER_CLASSIFICATION.rpt" \
        "$SOURCE_DIAGNOSTIC_ROOT/run_evidence/report_timing_post_route.rpt|$EVENT_INNOVUS_ROOT/reports/report_timing_post_route.rpt" \
        "$SOURCE_DIAGNOSTIC_ROOT/run_evidence/gds_export_audit.rpt|$SOURCE_GDS_AUDIT" \
        "$SOURCE_DIAGNOSTIC_ROOT/run_evidence/run_manifest.txt|$SOURCE_RUN_MANIFEST"
    do
        LEFT="${PAIR%%|*}"
        RIGHT="${PAIR#*|}"
        cmp -s "$LEFT" "$RIGHT"
        CMP_RC=$?
        echo "SOURCE_COPY_IDENTITY_RC=$CMP_RC LEFT=$LEFT RIGHT=$RIGHT"
        if [ "$CMP_RC" != "0" ]; then
            SOURCE_COPY_IDENTITY_GATE_RC=1
        fi
    done
    echo "SOURCE_COPY_IDENTITY_GATE_RC=$SOURCE_COPY_IDENTITY_GATE_RC"

    if [ "$SOURCE_COPY_IDENTITY_GATE_RC" != "0" ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: diagnostic and run evidence differ"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ]; then
    ACTUAL_GDS_SHA256="$(sha256sum "$EVENT_GDS" | awk '{print $1}')"
    ACTUAL_LEF_SHA256="$(sha256sum "$EVENT_LEF" | awk '{print $1}')"
    ACTUAL_DEF_SHA256="$(sha256sum "$EVENT_DEF" | awk '{print $1}')"
    ACTUAL_PG_NETLIST_SHA256="$(sha256sum "$EVENT_PG_NETLIST" | awk '{print $1}')"
    ACTUAL_GENUS_NETLIST_SHA256="$(sha256sum "$EVENT_GENUS_NETLIST" | awk '{print $1}')"
    ACTUAL_GENUS_SDC_SHA256="$(sha256sum "$EVENT_GENUS_SDC" | awk '{print $1}')"
    ACTUAL_STDCELL_CDL_SHA256="$(sha256sum "$STDCELL_CDL" | awk '{print $1}')"

    SOURCE_HASH_GATE_RC=0
    for HASH_PAIR in \
        "GDS|$EXPECTED_GDS_SHA256|$ACTUAL_GDS_SHA256" \
        "LEF|$EXPECTED_LEF_SHA256|$ACTUAL_LEF_SHA256" \
        "DEF|$EXPECTED_DEF_SHA256|$ACTUAL_DEF_SHA256" \
        "PG_NETLIST|$EXPECTED_PG_NETLIST_SHA256|$ACTUAL_PG_NETLIST_SHA256" \
        "GENUS_NETLIST|$EXPECTED_GENUS_NETLIST_SHA256|$ACTUAL_GENUS_NETLIST_SHA256" \
        "GENUS_SDC|$EXPECTED_GENUS_SDC_SHA256|$ACTUAL_GENUS_SDC_SHA256" \
        "STDCELL_CDL|$EXPECTED_STDCELL_CDL_SHA256|$ACTUAL_STDCELL_CDL_SHA256"
    do
        HASH_LABEL="${HASH_PAIR%%|*}"
        HASH_REST="${HASH_PAIR#*|}"
        HASH_EXPECTED="${HASH_REST%%|*}"
        HASH_ACTUAL="${HASH_REST#*|}"
        echo "EXPECTED_${HASH_LABEL}_SHA256=$HASH_EXPECTED"
        echo "ACTUAL_${HASH_LABEL}_SHA256=$HASH_ACTUAL"
        if [ "$HASH_ACTUAL" != "$HASH_EXPECTED" ]; then
            SOURCE_HASH_GATE_RC=1
        fi
    done
    echo "SOURCE_HASH_GATE_RC=$SOURCE_HASH_GATE_RC"

    if [ "$SOURCE_HASH_GATE_RC" != "0" ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: Event source artifact hash mismatch"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ]; then
    SOURCE_SHA_MANIFEST="$DIAGNOSTIC_ROOT/source_innovus/SHA256SUMS.pre_staging"
    : > "$SOURCE_SHA_MANIFEST"
    SOURCE_SHA_MANIFEST_CREATE_RC=$?
    if [ "$SOURCE_SHA_MANIFEST_CREATE_RC" = "0" ]; then
        for FILE in "${SOURCE_FILES[@]}"
        do
            sha256sum "$FILE" >> "$SOURCE_SHA_MANIFEST"
            SOURCE_FILE_SHA_RC=$?
            if [ "$SOURCE_FILE_SHA_RC" != "0" ]; then
                SOURCE_SHA_MANIFEST_CREATE_RC=1
            fi
        done
    fi
    echo "SOURCE_SHA_MANIFEST_CREATE_RC=$SOURCE_SHA_MANIFEST_CREATE_RC"

    if [ "$SOURCE_SHA_MANIFEST_CREATE_RC" != "0" ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: source hash manifest creation failed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ]; then
    if [ -e "$PACKAGE" ]; then
        PACKAGE_ABSENCE_RC=1
        echo "IMMUTABLE_PACKAGE_EXISTS=$PACKAGE"
        echo "STOP_HERE_DO_NOT_OVERWRITE: package version already exists"
        RUN_OK=0
    else
        PACKAGE_ABSENCE_RC=0
    fi
    echo "PACKAGE_ABSENCE_RC=$PACKAGE_ABSENCE_RC"
fi

if [ "$RUN_OK" = "1" ]; then
    python3 TOP/pnr/scripts/stage_innovus_handoff.py \
        --kind block \
        --name spadmic_event_coordinator \
        --version "$EVENT_PACKAGE_VERSION" \
        --source-root "$EVENT_INNOVUS_ROOT" \
        --gds "$EVENT_GDS" \
        --layout-top spadmic_event_coordinator \
        --netlist "$EVENT_PG_NETLIST" \
        --source-top spadmic_event_coordinator \
        --lef "$EVENT_LEF" \
        --def-file "$EVENT_DEF" \
        --report "$SOURCE_RUN_STATUS" \
        --report "$SOURCE_FLOORPLAN" \
        --report "$EVENT_INNOVUS_ROOT/reports/verify_connectivity_regular.rpt" \
        --report "$EVENT_INNOVUS_ROOT/reports/verify_connectivity_pg.rpt" \
        --report "$EVENT_INNOVUS_ROOT/reports/verify_drc_post_route.rpt" \
        --report "$EVENT_INNOVUS_ROOT/reports/DRC_MARKER_CLASSIFICATION.rpt" \
        --report "$EVENT_INNOVUS_ROOT/reports/report_timing_post_route.rpt" \
        --report "$SOURCE_GDS_AUDIT" \
        --report "$EVENT_INNOVUS_ROOT/generated/ooc_block_harden_config.tcl" \
        --report "$EVENT_INNOVUS_ROOT/generated/ooc_harden_input_manifest.csv" \
        --report "$EVENT_INNOVUS_ROOT/generated/ooc_block_pin_plan.csv" \
        --report "$SOURCE_RUN_MANIFEST" \
        --report "$EVENT_INNOVUS_RUN_ROOT/reports/ooc_harden_manifest.csv" \
        --report "$EVENT_INNOVUS_RUN_ROOT/SUMMARY.md" \
        --report "$EVENT_GENUS_ROOT/reports/timing/tc_ooc_gate.rpt" \
        --report "$SOURCE_STATUS" \
        --report "$SOURCE_ARTIFACT_HASHES" \
        --log "$EVENT_INNOVUS_ROOT/logs/innovus.log" \
        --log "$EVENT_INNOVUS_ROOT/logs/innovus.stdout.log" \
        --handoff-root "$HANDOFF_ROOT" \
        --repo-root "$REPO" \
        --state candidate \
        --stdcell-cdl "$STDCELL_CDL" \
        --qualification-profile basic
    HANDOFF_STAGE_RC=$?
    echo "HANDOFF_STAGE_RC=$HANDOFF_STAGE_RC"

    if [ "$HANDOFF_STAGE_RC" != "0" ]; then
        echo "STOP_HERE_DO_NOT_RUN_PVS: immutable Event staging failed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ]; then
    python3 TOP/pnr/scripts/audit_innovus_handoff.py "$PACKAGE"
    HANDOFF_AUDIT_RC=$?
    echo "HANDOFF_AUDIT_RC=$HANDOFF_AUDIT_RC"

    if [ "$HANDOFF_AUDIT_RC" != "0" ]; then
        echo "STOP_HERE_DO_NOT_RUN_PVS: Event package audit failed"
        RUN_OK=0
    fi
fi

PACKAGE_GDS="$PACKAGE/gds/spadmic_event_coordinator.gds"
PACKAGE_LEF="$PACKAGE/lef/event_coordinator.abstract.lef"
PACKAGE_DEF="$PACKAGE/def/spadmic_event_coordinator.def"
PACKAGE_RAW_NETLIST="$PACKAGE/netlist/spadmic_event_coordinator.innovus.pg.v"
PACKAGE_LVS_NETLIST="$PACKAGE/netlist/spadmic_event_coordinator.lvs.pg.v"
PACKAGE_CDL="$PACKAGE/pdk/xh018_D_CELLS_JIHD.cdl"
PACKAGE_JSON="$PACKAGE/manifests/package.json"
PACKAGE_QUALIFICATION="$PACKAGE/status/qualification.rpt"
PACKAGE_AUDIT="$PACKAGE/status/handoff_audit.rpt"
PACKAGE_SOURCE_PREP="$PACKAGE/reports/lvs_source_preparation.rpt"

if [ "$RUN_OK" = "1" ]; then
    ACTUAL_PACKAGE_GDS_SHA256="$(sha256sum "$PACKAGE_GDS" | awk '{print $1}')"
    ACTUAL_PACKAGE_LEF_SHA256="$(sha256sum "$PACKAGE_LEF" | awk '{print $1}')"
    ACTUAL_PACKAGE_DEF_SHA256="$(sha256sum "$PACKAGE_DEF" | awk '{print $1}')"
    ACTUAL_PACKAGE_RAW_NETLIST_SHA256="$(sha256sum "$PACKAGE_RAW_NETLIST" | awk '{print $1}')"
    ACTUAL_PACKAGE_LVS_NETLIST_SHA256="$(sha256sum "$PACKAGE_LVS_NETLIST" | awk '{print $1}')"
    ACTUAL_PACKAGE_CDL_SHA256="$(sha256sum "$PACKAGE_CDL" | awk '{print $1}')"

    PACKAGE_HASH_GATE_RC=0
    if [ "$ACTUAL_PACKAGE_GDS_SHA256" != "$EXPECTED_GDS_SHA256" ] || \
       [ "$ACTUAL_PACKAGE_LEF_SHA256" != "$EXPECTED_LEF_SHA256" ] || \
       [ "$ACTUAL_PACKAGE_DEF_SHA256" != "$EXPECTED_DEF_SHA256" ] || \
       [ "$ACTUAL_PACKAGE_RAW_NETLIST_SHA256" != "$EXPECTED_PG_NETLIST_SHA256" ] || \
       [ "$ACTUAL_PACKAGE_CDL_SHA256" != "$EXPECTED_STDCELL_CDL_SHA256" ] || \
       [ -z "$ACTUAL_PACKAGE_LVS_NETLIST_SHA256" ]; then
        PACKAGE_HASH_GATE_RC=1
    fi
    echo "PACKAGE_HASH_GATE_RC=$PACKAGE_HASH_GATE_RC"
    echo "ACTUAL_PACKAGE_LVS_NETLIST_SHA256=$ACTUAL_PACKAGE_LVS_NETLIST_SHA256"

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
    "name": "spadmic_event_coordinator",
    "version": expected_version,
    "state": "candidate",
    "qualification_profile": "basic",
    "source_root": expected_source_root,
    "layout_top": "spadmic_event_coordinator",
    "source_top": "spadmic_event_coordinator",
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
    if manifest_lvs_sha != actual_lvs_sha:
        errors.append("lvs_source_sha256_mismatch")

for error in errors:
    print(f"MANIFEST_ERROR={error}")
sys.exit(1 if errors else 0)
' "$PACKAGE_JSON" "$EXPECTED_HEAD" "$EVENT_INNOVUS_ROOT" "$EVENT_PACKAGE_VERSION"
    PACKAGE_MANIFEST_GATE_RC=$?

    PACKAGE_SHA_MANIFEST_RC=1
    cd "$PACKAGE"
    PACKAGE_CD_RC=$?
    if [ "$PACKAGE_CD_RC" = "0" ]; then
        sha256sum -c manifests/SHA256SUMS \
            > "$DIAGNOSTIC_ROOT/package_evidence/package_sha256_check.rpt" \
            2>&1
        PACKAGE_SHA_MANIFEST_RC=$?
    fi
    cd "$REPO"
    PACKAGE_RETURN_RC=$?
    echo "PACKAGE_SHA_MANIFEST_RC=$PACKAGE_SHA_MANIFEST_RC"

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
        require_line "$PACKAGE_QUALIFICATION" "$EXPECTED_LINE" QUALIFICATION_LINE_RC
        if [ "$LINE_MATCH_RC" != "0" ]; then
            QUALIFICATION_GATE_RC=1
        fi
    done

    AUDIT_REPORT_GATE_RC=0
    for EXPECTED_LINE in \
        'STATUS=PASS' \
        'CANONICAL_NAME=spadmic_event_coordinator' \
        'LAYOUT_TOP=spadmic_event_coordinator' \
        'SOURCE_TOP=spadmic_event_coordinator' \
        'LVS_SOURCE_PREPARATION_STATUS=PASS' \
        'PIN_PARITY_STATUS=PASS' \
        'STDCELL_CDL_STATUS=PASS' \
        'QUALIFICATION_PROFILE=basic' \
        'TEMPORARY_DRC_WAIVER_STATUS=NOT_APPLICABLE' \
        'PVS_DRC_WAIVER=NOT_APPLICABLE' \
        'LVS_DIAGNOSTIC_ONLY=NO' \
        'FINAL_SIGNOFF_READY=NO' \
        'ERROR_COUNT=0'
    do
        require_line "$PACKAGE_AUDIT" "$EXPECTED_LINE" AUDIT_REPORT_LINE_RC
        if [ "$LINE_MATCH_RC" != "0" ]; then
            AUDIT_REPORT_GATE_RC=1
        fi
    done

    SOURCE_PREP_GATE_RC=0
    for EXPECTED_LINE in \
        'STATUS=PASS' \
        'SOURCE_TOP=spadmic_event_coordinator' \
        "INPUT_SHA256=$EXPECTED_PG_NETLIST_SHA256" \
        'PIN_PARITY_STATUS=PASS' \
        'ERROR_COUNT=0'
    do
        require_line "$PACKAGE_SOURCE_PREP" "$EXPECTED_LINE" SOURCE_PREP_LINE_RC
        if [ "$LINE_MATCH_RC" != "0" ]; then
            SOURCE_PREP_GATE_RC=1
        fi
    done

    PACKAGE_EVIDENCE_GATE_RC=0
    for EXPECTED_LINE in \
        'RESULT=ABSTRACT_READY_FOR_TOP_REVIEW' \
        'TOP_RESERVATION_FIT_STATUS=PASS' \
        'ACTUAL_DIE_WIDTH_UM=237.440' \
        'ACTUAL_DIE_HEIGHT_UM=219.520' \
        'INNOVUS_DRC_STATUS=PASS' \
        'DRC_MARKER_TOTAL=0' \
        'REGULAR_CONNECTIVITY_STATUS=PASS' \
        'PG_CONNECTIVITY_STATUS=PASS' \
        'POSTROUTE_SETUP_TIMING=PASS' \
        'POSTROUTE_HOLD_TIMING=PASS' \
        'SIGNOFF_READY=NO'
    do
        require_line "$PACKAGE/reports/ooc_harden_status.rpt" "$EXPECTED_LINE" PACKAGE_STATUS_LINE_RC
        if [ "$LINE_MATCH_RC" != "0" ]; then
            PACKAGE_EVIDENCE_GATE_RC=1
        fi
    done

    for EXPECTED_LINE in \
        'STATUS=PASS' \
        'ACTUAL_DIE_WIDTH_UM=237.440' \
        'ACTUAL_DIE_HEIGHT_UM=219.520' \
        'TOP_RESERVATION_WIDTH_MARGIN_UM=0.020' \
        'TOP_RESERVATION_HEIGHT_MARGIN_UM=0.480'
    do
        require_line "$PACKAGE/reports/floorplan_geometry.rpt" "$EXPECTED_LINE" PACKAGE_FLOORPLAN_LINE_RC
        if [ "$LINE_MATCH_RC" != "0" ]; then
            PACKAGE_EVIDENCE_GATE_RC=1
        fi
    done

    for EXPECTED_LINE in \
        'STATUS=PASS' \
        'GDS_FILE_STATUS=PASS' \
        'GDS_LAYER_MAP_STATUS=PASS' \
        'GDS_MERGE_STATUS=PASS' \
        "GDS_SHA256=$EXPECTED_GDS_SHA256" \
        'ERROR_COUNT=0'
    do
        require_line "$PACKAGE/reports/gds_export_audit.rpt" "$EXPECTED_LINE" PACKAGE_GDS_LINE_RC
        if [ "$LINE_MATCH_RC" != "0" ]; then
            PACKAGE_EVIDENCE_GATE_RC=1
        fi
    done

    sha256sum -c "$SOURCE_SHA_MANIFEST" \
        > "$DIAGNOSTIC_ROOT/source_innovus/SHA256SUMS.post_staging_check.rpt" \
        2>&1
    SOURCE_POST_RECHECK_RC=$?

    echo "PACKAGE_MANIFEST_GATE_RC=$PACKAGE_MANIFEST_GATE_RC"
    echo "QUALIFICATION_GATE_RC=$QUALIFICATION_GATE_RC"
    echo "AUDIT_REPORT_GATE_RC=$AUDIT_REPORT_GATE_RC"
    echo "SOURCE_PREP_GATE_RC=$SOURCE_PREP_GATE_RC"
    echo "PACKAGE_EVIDENCE_GATE_RC=$PACKAGE_EVIDENCE_GATE_RC"
    echo "SOURCE_POST_RECHECK_RC=$SOURCE_POST_RECHECK_RC"

    if [ "$PACKAGE_HASH_GATE_RC" = "0" ] && \
       [ "$PACKAGE_MANIFEST_GATE_RC" = "0" ] && \
       [ "$PACKAGE_SHA_MANIFEST_RC" = "0" ] && \
       [ "$QUALIFICATION_GATE_RC" = "0" ] && \
       [ "$AUDIT_REPORT_GATE_RC" = "0" ] && \
       [ "$SOURCE_PREP_GATE_RC" = "0" ] && \
       [ "$PACKAGE_EVIDENCE_GATE_RC" = "0" ] && \
       [ "$SOURCE_POST_RECHECK_RC" = "0" ]; then
        TRANSACTION_STATUS=PASS
        OUTCOME_CLASS=ATTRIBUTABLE_CANDIDATE_PACKAGE
        EVENT_IMMUTABLE_HANDOFF_STAGING_STATUS=PASS
        EVENT_PVS_PREFLIGHT_AUTHORIZED=YES
        NEXT_GATE=PREPARE_EVENT_PVS_BASE_DRC_STRICT_PREFLIGHT
    fi
fi

if [ "$DIAGNOSTIC_CREATE_RC" = "0" ]; then
    DIAGNOSTIC_COPY_GATE_RC=0
    copy_if_readable "$SOURCE_STATUS" \
        "$DIAGNOSTIC_ROOT/source_innovus/event_innovus_execution_status.rpt"
    copy_if_readable "$SOURCE_ARTIFACT_HASHES" \
        "$DIAGNOSTIC_ROOT/source_innovus/artifact_hashes.rpt"
    copy_if_readable "$SOURCE_RUN_STATUS" \
        "$DIAGNOSTIC_ROOT/source_innovus/ooc_harden_status.rpt"
    copy_if_readable "$SOURCE_FLOORPLAN" \
        "$DIAGNOSTIC_ROOT/source_innovus/floorplan_geometry.rpt"
    copy_if_readable "$SOURCE_GDS_AUDIT" \
        "$DIAGNOSTIC_ROOT/source_innovus/gds_export_audit.rpt"

    if [ -d "$PACKAGE" ]; then
        copy_if_readable "$PACKAGE_JSON" \
            "$DIAGNOSTIC_ROOT/package_evidence/package.json"
        copy_if_readable "$PACKAGE/manifests/SHA256SUMS" \
            "$DIAGNOSTIC_ROOT/package_evidence/SHA256SUMS.package"
        copy_if_readable "$PACKAGE_QUALIFICATION" \
            "$DIAGNOSTIC_ROOT/package_evidence/qualification.rpt"
        copy_if_readable "$PACKAGE_AUDIT" \
            "$DIAGNOSTIC_ROOT/package_evidence/handoff_audit.rpt"
        copy_if_readable "$PACKAGE_SOURCE_PREP" \
            "$DIAGNOSTIC_ROOT/package_evidence/lvs_source_preparation.rpt"
    fi

    if [ "$DIAGNOSTIC_COPY_GATE_RC" != "0" ]; then
        TRANSACTION_STATUS=FAIL
        OUTCOME_CLASS=NOT_CLASSIFIED
        EVENT_IMMUTABLE_HANDOFF_STAGING_STATUS=FAIL
        EVENT_PVS_PREFLIGHT_AUTHORIZED=NO
        NEXT_GATE=STOP_AND_REVIEW_EVENT_HANDOFF_STAGING_FAILURE
    fi

    {
        echo "LABEL=SPADMIC_EVENT_IMMUTABLE_HANDOFF_STAGING"
        echo "STATUS=$TRANSACTION_STATUS"
        if [ "$TRANSACTION_STATUS" = "PASS" ]; then
            echo "RESULT=EVENT_IMMUTABLE_HANDOFF_STAGED"
        else
            echo "RESULT=EVENT_IMMUTABLE_HANDOFF_STAGING_REVIEW_REQUIRED"
        fi
        echo "OUTCOME_CLASS=$OUTCOME_CLASS"
        echo "EXPECTED_HEAD=$EXPECTED_HEAD"
        echo "ACTUAL_HEAD=$ACTUAL_HEAD"
        echo "SOURCE_INNOVUS_HEAD=$EXPECTED_SOURCE_HEAD"
        echo "SOURCE_DIAGNOSTIC_ROOT=$SOURCE_DIAGNOSTIC_ROOT"
        echo "SOURCE_INNOVUS_RUN=$EVENT_INNOVUS_RUN"
        echo "SOURCE_INNOVUS_ROOT=$EVENT_INNOVUS_ROOT"
        echo "SOURCE_MUTATION_AUTHORIZED=NO"
        echo "SOURCE_FILE_GATE_RC=$SOURCE_FILE_GATE_RC"
        echo "SOURCE_DIAGNOSTIC_MANIFEST_RC=$SOURCE_DIAGNOSTIC_MANIFEST_RC"
        echo "SOURCE_STATUS_GATE_RC=$SOURCE_STATUS_GATE_RC"
        echo "SOURCE_COPY_IDENTITY_GATE_RC=$SOURCE_COPY_IDENTITY_GATE_RC"
        echo "SOURCE_HASH_GATE_RC=$SOURCE_HASH_GATE_RC"
        echo "SOURCE_SHA_MANIFEST_CREATE_RC=$SOURCE_SHA_MANIFEST_CREATE_RC"
        echo "PACKAGE_ABSENCE_RC=$PACKAGE_ABSENCE_RC"
        echo "HANDOFF_STAGE_RC=$HANDOFF_STAGE_RC"
        echo "HANDOFF_AUDIT_RC=$HANDOFF_AUDIT_RC"
        echo "PACKAGE=$PACKAGE"
        echo "PACKAGE_GDS_SHA256=${ACTUAL_PACKAGE_GDS_SHA256:-UNKNOWN}"
        echo "PACKAGE_LEF_SHA256=${ACTUAL_PACKAGE_LEF_SHA256:-UNKNOWN}"
        echo "PACKAGE_DEF_SHA256=${ACTUAL_PACKAGE_DEF_SHA256:-UNKNOWN}"
        echo "PACKAGE_RAW_PG_NETLIST_SHA256=${ACTUAL_PACKAGE_RAW_NETLIST_SHA256:-UNKNOWN}"
        echo "PACKAGE_LVS_SOURCE_SHA256=${ACTUAL_PACKAGE_LVS_NETLIST_SHA256:-UNKNOWN}"
        echo "PACKAGE_STDCELL_CDL_SHA256=${ACTUAL_PACKAGE_CDL_SHA256:-UNKNOWN}"
        echo "PACKAGE_HASH_GATE_RC=$PACKAGE_HASH_GATE_RC"
        echo "PACKAGE_MANIFEST_GATE_RC=$PACKAGE_MANIFEST_GATE_RC"
        echo "PACKAGE_SHA_MANIFEST_RC=$PACKAGE_SHA_MANIFEST_RC"
        echo "QUALIFICATION_GATE_RC=$QUALIFICATION_GATE_RC"
        echo "AUDIT_REPORT_GATE_RC=$AUDIT_REPORT_GATE_RC"
        echo "SOURCE_PREP_GATE_RC=$SOURCE_PREP_GATE_RC"
        echo "PACKAGE_EVIDENCE_GATE_RC=$PACKAGE_EVIDENCE_GATE_RC"
        echo "SOURCE_POST_RECHECK_RC=$SOURCE_POST_RECHECK_RC"
        echo "DIAGNOSTIC_COPY_GATE_RC=$DIAGNOSTIC_COPY_GATE_RC"
        echo "EVENT_IMMUTABLE_HANDOFF_STAGING_STATUS=$EVENT_IMMUTABLE_HANDOFF_STAGING_STATUS"
        echo "EVENT_PVS_BASE_DRC_STATUS=NOT_RUN"
        echo "EVENT_PVS_DENSITY_DRC_STATUS=NOT_RUN"
        echo "EVENT_PVS_LVS_STATUS=NOT_RUN"
        echo "PVS_EXECUTED=NO"
        echo "EVENT_PVS_PREFLIGHT_AUTHORIZED=$EVENT_PVS_PREFLIGHT_AUTHORIZED"
        echo "ASSEMBLY_PHASE=p02_event_control"
        echo "ASSEMBLY_INSERTION_AUTHORIZED=NO"
        echo "ASSEMBLY_BLOCKED_BY=p00_tx,p01_position"
        echo "FULL_TOP_PNR_AUTHORIZED=NO"
        echo "BLOCK_PROMOTION_AUTHORIZED=NO"
        echo "SIGNOFF_READY=NO"
        echo "NEXT_GATE=$NEXT_GATE"
    } > "$DIAGNOSTIC_ROOT/event_handoff_staging_status.rpt"

    cd "$DIAGNOSTIC_ROOT"
    DIAGNOSTIC_MANIFEST_CD_RC=$?
    DIAGNOSTIC_MANIFEST_CREATE_RC=1
    if [ "$DIAGNOSTIC_MANIFEST_CD_RC" = "0" ]; then
        : > SHA256SUMS
        DIAGNOSTIC_MANIFEST_CREATE_RC=$?
        while IFS= read -r FILE
        do
            sha256sum "$FILE" >> SHA256SUMS
            DIAGNOSTIC_FILE_SHA_RC=$?
            if [ "$DIAGNOSTIC_FILE_SHA_RC" != "0" ]; then
                DIAGNOSTIC_MANIFEST_CREATE_RC=1
            fi
        done < <(find . -type f ! -name SHA256SUMS -print | LC_ALL=C sort)
    fi
    cd "$REPO"
    DIAGNOSTIC_MANIFEST_RETURN_RC=$?
    if [ "$DIAGNOSTIC_MANIFEST_RETURN_RC" != "0" ]; then
        DIAGNOSTIC_MANIFEST_CREATE_RC=1
    fi
fi

echo
echo "===== EVENT IMMUTABLE HANDOFF STAGING STATUS ====="
cat "$DIAGNOSTIC_ROOT/event_handoff_staging_status.rpt" 2>/dev/null

if [ -d "$PACKAGE" ]; then
    echo
    echo "===== PACKAGE QUALIFICATION ====="
    cat "$PACKAGE_QUALIFICATION" 2>/dev/null
    echo
    echo "===== PACKAGE AUDIT ====="
    cat "$PACKAGE_AUDIT" 2>/dev/null
    echo
    echo "===== PACKAGE LVS SOURCE PREPARATION ====="
    cat "$PACKAGE_SOURCE_PREP" 2>/dev/null
    echo
    echo "===== PACKAGE MANIFEST ====="
    cat "$PACKAGE_JSON" 2>/dev/null
fi

echo "DIAGNOSTIC_ROOT=$DIAGNOSTIC_ROOT"
echo "PACKAGE=$PACKAGE"
echo "DIAGNOSTIC_MANIFEST_CREATE_RC=$DIAGNOSTIC_MANIFEST_CREATE_RC"

if [ "$TRANSACTION_STATUS" = "PASS" ] && \
   [ "$DIAGNOSTIC_COPY_GATE_RC" = "0" ] && \
   [ "$DIAGNOSTIC_MANIFEST_CREATE_RC" = "0" ]; then
    exit 0
fi

exit 1
