#!/usr/bin/env bash

###############################################################################
# P10-R02 - hash-bound Event coordinator Innovus OOC transaction
#
# Usage:
#   bash TOP/ci/server_run_event_coordinator_innovus.sh <expected-repository-head>
###############################################################################

set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
EXPECTED_HEAD="${1:-MISSING}"
EXPECTED_SOURCE_HEAD=b53b1fade963c6c57c6b0629ae9a4b21fdac06db

WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
EVENT_GENUS_RUN=genus_ooc_event_coordinator_20260720_163038
EVENT_GENUS_RUN_ROOT="$WORK_ROOT/genus/$EVENT_GENUS_RUN"
EVENT_GENUS_ROOT="$EVENT_GENUS_RUN_ROOT/event_coordinator"
EVENT_NETLIST="$EVENT_GENUS_ROOT/outputs/event_coordinator.postsyn.v"
EVENT_SDC="$EVENT_GENUS_ROOT/outputs/event_coordinator.postsyn.sdc"
EXPECTED_NETLIST_SHA256=b28454211dc5eeda84f17cc5864adcd1c15cd761a9d825e3f5a78182fe0b0ccb
EXPECTED_SDC_SHA256=c32e0a54b392017256a790ec73352d7161093c73a4360fe933083c88f7d1cb6a

SOURCE_FILES=(
    "$EVENT_NETLIST"
    "$EVENT_SDC"
    "$EVENT_GENUS_ROOT/SUMMARY.md"
    "$EVENT_GENUS_RUN_ROOT/SUMMARY.md"
    "$EVENT_GENUS_RUN_ROOT/run_manifest.txt"
    "$EVENT_GENUS_ROOT/reports/elaboration/check_design_post_elab.rpt"
    "$EVENT_GENUS_ROOT/reports/timing/check_timing_intent.rpt"
    "$EVENT_GENUS_ROOT/reports/timing/report_clocks.rpt"
    "$EVENT_GENUS_ROOT/reports/timing/tc_ooc_gate.rpt"
    "$EVENT_GENUS_ROOT/reports/qor/report_qor.rpt"
    "$EVENT_GENUS_ROOT/reports/messages/warning_classification.rpt"
)

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
EVENT_INNOVUS_RUN="innovus_ooc_harden_event_coordinator_$TIMESTAMP"
EVENT_INNOVUS_RUN_ROOT="$WORK_ROOT/innovus/$EVENT_INNOVUS_RUN"
EVENT_INNOVUS_ROOT="$EVENT_INNOVUS_RUN_ROOT/blocks/event_coordinator"
DIAGNOSTIC_ROOT="$WORK_ROOT/diagnostics/event_innovus_execution_$TIMESTAMP"

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
SOURCE_SHA_MANIFEST_CREATE_RC=NOT_RUN
SOURCE_HASH_GATE_RC=NOT_RUN
SOURCE_STATUS_GATE_RC=NOT_RUN
SOURCE_REVALIDATION_RC=NOT_RUN
EVENT_ENV_GATE_RC=NOT_RUN
EVENT_INNOVUS_RC=NOT_RUN
EVENT_CONSOLE_TEE_RC=NOT_RUN
RUN_FILE_GATE_RC=NOT_RUN
RUN_STATUS_GATE_RC=NOT_RUN
RUN_GDS_GATE_RC=NOT_RUN
RUN_ARTIFACT_HASH_GATE_RC=NOT_RUN
SOURCE_POST_RECHECK_RC=NOT_RUN
DIAGNOSTIC_COPY_GATE_RC=NOT_RUN
DIAGNOSTIC_MANIFEST_CREATE_RC=NOT_RUN
TRANSACTION_STATUS=FAIL
OUTCOME_CLASS=NOT_CLASSIFIED
EVENT_INNOVUS_OOC_STATUS=NOT_RUN
EVENT_INNOVUS_EXECUTED=NO
EVENT_HANDOFF_STAGE_AUTHORIZED=NO
NEXT_GATE=STOP_AND_REVIEW_EVENT_INNOVUS_FAILURE

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
        TOP/syn/scripts/validate_genus_tc_ooc.py \
        TOP/pnr/scripts/validate_digital_subblock_portfolio.py \
        TOP/pnr/scripts/run_innovus_ooc_harden_block.sh
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
    mkdir -p "$DIAGNOSTIC_ROOT/source_genus" "$DIAGNOSTIC_ROOT/run_evidence"
    DIAGNOSTIC_CREATE_RC=$?
    echo "DIAGNOSTIC_ROOT=$DIAGNOSTIC_ROOT"
    echo "EVENT_INNOVUS_RUN=$EVENT_INNOVUS_RUN"
    echo "EVENT_INNOVUS_ROOT=$EVENT_INNOVUS_ROOT"
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
        echo "STOP_HERE_DO_NOT_CONTINUE: accepted Event Genus evidence is incomplete"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ]; then
    SOURCE_SHA_MANIFEST="$DIAGNOSTIC_ROOT/source_genus/SHA256SUMS.pre_execution"
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
        echo "STOP_HERE_DO_NOT_CONTINUE: accepted Event Genus hash manifest failed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ]; then
    ACTUAL_NETLIST_SHA256="$(sha256sum "$EVENT_NETLIST" | awk '{print $1}')"
    ACTUAL_SDC_SHA256="$(sha256sum "$EVENT_SDC" | awk '{print $1}')"
    SOURCE_HASH_GATE_RC=0

    echo "EXPECTED_NETLIST_SHA256=$EXPECTED_NETLIST_SHA256"
    echo "ACTUAL_NETLIST_SHA256=$ACTUAL_NETLIST_SHA256"
    echo "EXPECTED_SDC_SHA256=$EXPECTED_SDC_SHA256"
    echo "ACTUAL_SDC_SHA256=$ACTUAL_SDC_SHA256"

    if [ "$ACTUAL_NETLIST_SHA256" != "$EXPECTED_NETLIST_SHA256" ] || \
       [ "$ACTUAL_SDC_SHA256" != "$EXPECTED_SDC_SHA256" ]; then
        SOURCE_HASH_GATE_RC=1
    fi

    echo "SOURCE_HASH_GATE_RC=$SOURCE_HASH_GATE_RC"

    if [ "$SOURCE_HASH_GATE_RC" != "0" ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: accepted Event Genus artifact hash mismatch"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ]; then
    SOURCE_STATUS_GATE_RC=0
    SOURCE_GATE="$EVENT_GENUS_ROOT/reports/timing/tc_ooc_gate.rpt"
    SOURCE_MANIFEST="$EVENT_GENUS_RUN_ROOT/run_manifest.txt"

    for EXPECTED_LINE in \
        'STATUS=PASS' \
        'TC_TIMING_STATUS=PASS' \
        'RESULT=READY_FOR_ISOLATED_INNOVUS_OOC' \
        'BLOCK=event_coordinator' \
        'TOP_MODULE=spadmic_event_coordinator' \
        'CLOCK_NAME=clk_sys' \
        'CLOCK_PERIOD_PS=6250.0' \
        'CLOCK_REGISTER_COUNT=51' \
        'TOP_PORT_COUNT=63' \
        'BOUNDARY_PORT_STATUS=PASS' \
        'EXPECTED_BASE_PORT_COUNT=30' \
        'ACTUAL_BASE_PORT_COUNT=30' \
        'EXPECTED_BIT_PORT_COUNT=63' \
        'ACTUAL_BIT_PORT_COUNT=63' \
        'UNRESOLVED_REFERENCE_COUNT=0' \
        'WNS_PS=2143.7' \
        'TNS_PS=0.0' \
        'VIOLATING_PATH_COUNT=0' \
        'MMMC_STATUS=NOT_RUN_TYPICAL_ONLY' \
        'SIGNOFF_READY=NO' \
        "POSTSYN_NETLIST_SHA256=$EXPECTED_NETLIST_SHA256" \
        "POSTSYN_SDC_SHA256=$EXPECTED_SDC_SHA256" \
        'ERROR_COUNT=0'
    do
        require_line "$SOURCE_GATE" "$EXPECTED_LINE" SOURCE_GENUS_LINE_RC
        if [ "$LINE_MATCH_RC" != "0" ]; then
            SOURCE_STATUS_GATE_RC=1
        fi
    done

    for EXPECTED_LINE in \
        'BRANCH=SPADMIC_test' \
        "HEAD=$EXPECTED_SOURCE_HEAD" \
        'CUSTOM_BLOCK_LIST=1' \
        'SPADMIC_GENUS_OOC_BLOCKS=event_coordinator:spadmic_event_coordinator'
    do
        require_line "$SOURCE_MANIFEST" "$EXPECTED_LINE" SOURCE_MANIFEST_LINE_RC
        if [ "$LINE_MATCH_RC" != "0" ]; then
            SOURCE_STATUS_GATE_RC=1
        fi
    done

    echo "SOURCE_STATUS_GATE_RC=$SOURCE_STATUS_GATE_RC"

    if [ "$SOURCE_STATUS_GATE_RC" != "0" ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: accepted Event Genus status mismatch"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ]; then
    python3 TOP/syn/scripts/validate_genus_tc_ooc.py \
        --block-root "$EVENT_GENUS_ROOT" \
        --block event_coordinator \
        --top-module spadmic_event_coordinator \
        --clock-name clk_sys \
        --period-ps 6250.0 \
        --status "$DIAGNOSTIC_ROOT/source_genus/tc_ooc_gate.revalidated.rpt"
    SOURCE_REVALIDATION_RC=$?
    echo "SOURCE_REVALIDATION_RC=$SOURCE_REVALIDATION_RC"

    if [ "$SOURCE_REVALIDATION_RC" != "0" ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: Event Genus revalidation failed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ]; then
    command -v innovus >/dev/null 2>&1
    EVENT_ENV_GATE_RC=$?
    echo "EVENT_ENV_GATE_RC=$EVENT_ENV_GATE_RC"

    if [ "$EVENT_ENV_GATE_RC" != "0" ]; then
        echo "STOP_HERE_DO_NOT_START_EVENT_INNOVUS: Innovus is unavailable"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ]; then
    EVENT_INNOVUS_EXECUTED=YES
    bash TOP/pnr/scripts/run_innovus_ooc_harden_block.sh \
        event_coordinator \
        "$EVENT_GENUS_RUN" \
        "$EVENT_INNOVUS_RUN" \
        2>&1 | tee "$DIAGNOSTIC_ROOT/event_innovus.console.log"
    PIPE_RCS=("${PIPESTATUS[@]}")
    EVENT_INNOVUS_RC="${PIPE_RCS[0]}"
    EVENT_CONSOLE_TEE_RC="${PIPE_RCS[1]}"
fi

echo "EVENT_INNOVUS_RC=$EVENT_INNOVUS_RC"
echo "EVENT_CONSOLE_TEE_RC=$EVENT_CONSOLE_TEE_RC"

RUN_STATUS="$EVENT_INNOVUS_ROOT/reports/ooc_harden_status.rpt"
RUN_GDS_AUDIT="$EVENT_INNOVUS_ROOT/reports/gds_export_audit.rpt"

if [ "$EVENT_INNOVUS_EXECUTED" = "YES" ]; then
    RUN_FILE_GATE_RC=0
    for FILE in \
        "$RUN_STATUS" \
        "$RUN_GDS_AUDIT" \
        "$EVENT_INNOVUS_ROOT/reports/floorplan_geometry.rpt" \
        "$EVENT_INNOVUS_ROOT/reports/verify_connectivity_regular.rpt" \
        "$EVENT_INNOVUS_ROOT/reports/verify_connectivity_pg.rpt" \
        "$EVENT_INNOVUS_ROOT/reports/verify_drc_post_route.rpt" \
        "$EVENT_INNOVUS_ROOT/reports/DRC_MARKER_CLASSIFICATION.rpt" \
        "$EVENT_INNOVUS_ROOT/reports/report_timing_post_route.rpt" \
        "$EVENT_INNOVUS_ROOT/generated/ooc_block_harden_config.tcl" \
        "$EVENT_INNOVUS_ROOT/generated/ooc_harden_input_manifest.csv" \
        "$EVENT_INNOVUS_ROOT/generated/ooc_block_pin_plan.csv" \
        "$EVENT_INNOVUS_ROOT/outputs/event_coordinator.gds" \
        "$EVENT_INNOVUS_ROOT/outputs/event_coordinator.abstract.lef" \
        "$EVENT_INNOVUS_ROOT/outputs/event_coordinator.def" \
        "$EVENT_INNOVUS_ROOT/outputs/event_coordinator.routed.pg.v" \
        "$EVENT_INNOVUS_ROOT/logs/innovus.log" \
        "$EVENT_INNOVUS_ROOT/logs/innovus.stdout.log" \
        "$EVENT_INNOVUS_RUN_ROOT/run_manifest.txt" \
        "$EVENT_INNOVUS_RUN_ROOT/reports/ooc_harden_manifest.csv" \
        "$EVENT_INNOVUS_RUN_ROOT/SUMMARY.md"
    do
        if [ ! -s "$FILE" ]; then
            echo "MISSING_OR_EMPTY=$FILE"
            RUN_FILE_GATE_RC=1
        fi
    done

    echo "RUN_FILE_GATE_RC=$RUN_FILE_GATE_RC"

    RUN_STATUS_GATE_RC=0
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
        'SIGNOFF_READY=NO' \
        'PVS_STATUS=DEFERRED' \
        'MMMC_STATUS=DEFERRED_TYPICAL_ONLY'
    do
        require_line "$RUN_STATUS" "$EXPECTED_LINE" RUN_STATUS_LINE_RC
        if [ "$LINE_MATCH_RC" != "0" ]; then
            RUN_STATUS_GATE_RC=1
        fi
    done

    RUN_GDS_GATE_RC=0
    for EXPECTED_LINE in \
        'STATUS=PASS' \
        'GDS_FILE_STATUS=PASS' \
        'GDS_LAYER_MAP_STATUS=PASS' \
        'GDS_MERGE_STATUS=PASS' \
        'ERROR_COUNT=0'
    do
        require_line "$RUN_GDS_AUDIT" "$EXPECTED_LINE" RUN_GDS_LINE_RC
        if [ "$LINE_MATCH_RC" != "0" ]; then
            RUN_GDS_GATE_RC=1
        fi
    done

    RUN_GDS_SHA256="$(sed -n 's/^GDS_SHA256=//p' "$RUN_GDS_AUDIT" | head -n 1)"
    ACTUAL_RUN_GDS_SHA256="$(sha256sum "$EVENT_INNOVUS_ROOT/outputs/event_coordinator.gds" 2>/dev/null | awk '{print $1}')"
    if [ -z "$RUN_GDS_SHA256" ] || [ "$RUN_GDS_SHA256" != "$ACTUAL_RUN_GDS_SHA256" ]; then
        RUN_GDS_GATE_RC=1
    fi

    RUN_ABSTRACT_LEF_SHA256="$(sha256sum "$EVENT_INNOVUS_ROOT/outputs/event_coordinator.abstract.lef" 2>/dev/null | awk '{print $1}')"
    RUN_DEF_SHA256="$(sha256sum "$EVENT_INNOVUS_ROOT/outputs/event_coordinator.def" 2>/dev/null | awk '{print $1}')"
    RUN_PG_NETLIST_SHA256="$(sha256sum "$EVENT_INNOVUS_ROOT/outputs/event_coordinator.routed.pg.v" 2>/dev/null | awk '{print $1}')"
    RUN_ARTIFACT_HASH_GATE_RC=0
    for HASH_VALUE in \
        "$RUN_GDS_SHA256" \
        "$RUN_ABSTRACT_LEF_SHA256" \
        "$RUN_DEF_SHA256" \
        "$RUN_PG_NETLIST_SHA256"
    do
        printf '%s\n' "$HASH_VALUE" | grep -Eq '^[0-9a-f]{64}$'
        HASH_FORMAT_RC=$?
        if [ "$HASH_FORMAT_RC" != "0" ]; then
            RUN_ARTIFACT_HASH_GATE_RC=1
        fi
    done

    sha256sum -c "$SOURCE_SHA_MANIFEST" \
        > "$DIAGNOSTIC_ROOT/source_genus/SHA256SUMS.post_execution_check.rpt" \
        2>&1
    SOURCE_POST_RECHECK_RC=$?

    echo "RUN_STATUS_GATE_RC=$RUN_STATUS_GATE_RC"
    echo "RUN_GDS_GATE_RC=$RUN_GDS_GATE_RC"
    echo "RUN_GDS_SHA256=${RUN_GDS_SHA256:-UNKNOWN}"
    echo "ACTUAL_RUN_GDS_SHA256=${ACTUAL_RUN_GDS_SHA256:-UNKNOWN}"
    echo "RUN_ARTIFACT_HASH_GATE_RC=$RUN_ARTIFACT_HASH_GATE_RC"
    echo "SOURCE_POST_RECHECK_RC=$SOURCE_POST_RECHECK_RC"

    if [ "$EVENT_INNOVUS_RC" = "0" ] && \
       [ "$EVENT_CONSOLE_TEE_RC" = "0" ] && \
       [ "$RUN_FILE_GATE_RC" = "0" ] && \
       [ "$RUN_STATUS_GATE_RC" = "0" ] && \
       [ "$RUN_GDS_GATE_RC" = "0" ] && \
       [ "$RUN_ARTIFACT_HASH_GATE_RC" = "0" ] && \
       [ "$SOURCE_POST_RECHECK_RC" = "0" ]; then

        TRANSACTION_STATUS=PASS
        OUTCOME_CLASS=ATTRIBUTABLE_ABSTRACT_READY
        EVENT_INNOVUS_OOC_STATUS=PASS
        EVENT_HANDOFF_STAGE_AUTHORIZED=YES
        NEXT_GATE=REVIEW_AND_STAGE_IMMUTABLE_EVENT_HANDOFF
    else
        EVENT_INNOVUS_OOC_STATUS=FAIL
    fi
fi

if [ "$DIAGNOSTIC_CREATE_RC" = "0" ]; then
    DIAGNOSTIC_COPY_GATE_RC=0

    copy_if_readable "$EVENT_GENUS_RUN_ROOT/run_manifest.txt" \
        "$DIAGNOSTIC_ROOT/source_genus/run_manifest.txt"
    copy_if_readable "$EVENT_GENUS_RUN_ROOT/SUMMARY.md" \
        "$DIAGNOSTIC_ROOT/source_genus/SUMMARY.md"
    copy_if_readable "$EVENT_GENUS_ROOT/reports/timing/tc_ooc_gate.rpt" \
        "$DIAGNOSTIC_ROOT/source_genus/tc_ooc_gate.rpt"
    copy_if_readable "$EVENT_GENUS_ROOT/reports/timing/check_timing_intent.rpt" \
        "$DIAGNOSTIC_ROOT/source_genus/check_timing_intent.rpt"
    copy_if_readable "$EVENT_GENUS_ROOT/reports/qor/report_qor.rpt" \
        "$DIAGNOSTIC_ROOT/source_genus/report_qor.rpt"
    copy_if_readable "$EVENT_GENUS_ROOT/reports/messages/warning_classification.rpt" \
        "$DIAGNOSTIC_ROOT/source_genus/warning_classification.rpt"

    copy_if_readable "$RUN_STATUS" "$DIAGNOSTIC_ROOT/run_evidence/ooc_harden_status.rpt"
    copy_if_readable "$RUN_GDS_AUDIT" "$DIAGNOSTIC_ROOT/run_evidence/gds_export_audit.rpt"
    copy_if_readable "$EVENT_INNOVUS_ROOT/reports/floorplan_geometry.rpt" \
        "$DIAGNOSTIC_ROOT/run_evidence/floorplan_geometry.rpt"
    copy_if_readable "$EVENT_INNOVUS_ROOT/reports/verify_connectivity_regular.rpt" \
        "$DIAGNOSTIC_ROOT/run_evidence/verify_connectivity_regular.rpt"
    copy_if_readable "$EVENT_INNOVUS_ROOT/reports/verify_connectivity_pg.rpt" \
        "$DIAGNOSTIC_ROOT/run_evidence/verify_connectivity_pg.rpt"
    copy_if_readable "$EVENT_INNOVUS_ROOT/reports/verify_drc_post_route.rpt" \
        "$DIAGNOSTIC_ROOT/run_evidence/verify_drc_post_route.rpt"
    copy_if_readable "$EVENT_INNOVUS_ROOT/reports/DRC_MARKER_CLASSIFICATION.rpt" \
        "$DIAGNOSTIC_ROOT/run_evidence/DRC_MARKER_CLASSIFICATION.rpt"
    copy_if_readable "$EVENT_INNOVUS_ROOT/reports/report_timing_post_route.rpt" \
        "$DIAGNOSTIC_ROOT/run_evidence/report_timing_post_route.rpt"
    copy_if_readable "$EVENT_INNOVUS_ROOT/generated/ooc_block_harden_config.tcl" \
        "$DIAGNOSTIC_ROOT/run_evidence/ooc_block_harden_config.tcl"
    copy_if_readable "$EVENT_INNOVUS_ROOT/generated/ooc_harden_input_manifest.csv" \
        "$DIAGNOSTIC_ROOT/run_evidence/ooc_harden_input_manifest.csv"
    copy_if_readable "$EVENT_INNOVUS_ROOT/generated/ooc_block_pin_plan.csv" \
        "$DIAGNOSTIC_ROOT/run_evidence/ooc_block_pin_plan.csv"
    copy_if_readable "$EVENT_INNOVUS_RUN_ROOT/run_manifest.txt" \
        "$DIAGNOSTIC_ROOT/run_evidence/run_manifest.txt"
    copy_if_readable "$EVENT_INNOVUS_RUN_ROOT/SUMMARY.md" \
        "$DIAGNOSTIC_ROOT/run_evidence/SUMMARY.md"

    if [ "$DIAGNOSTIC_COPY_GATE_RC" != "0" ]; then
        TRANSACTION_STATUS=FAIL
        OUTCOME_CLASS=NOT_CLASSIFIED
        EVENT_INNOVUS_OOC_STATUS=FAIL
        EVENT_HANDOFF_STAGE_AUTHORIZED=NO
        NEXT_GATE=STOP_AND_REVIEW_EVENT_INNOVUS_FAILURE
    fi

    {
        echo "LABEL=SPADMIC_EVENT_INNOVUS_ARTIFACT_HASHES"
        echo "SOURCE_NETLIST=$EVENT_NETLIST"
        echo "SOURCE_NETLIST_SHA256=$EXPECTED_NETLIST_SHA256"
        echo "SOURCE_SDC=$EVENT_SDC"
        echo "SOURCE_SDC_SHA256=$EXPECTED_SDC_SHA256"
        echo "GDS=$EVENT_INNOVUS_ROOT/outputs/event_coordinator.gds"
        echo "GDS_SHA256=${RUN_GDS_SHA256:-UNKNOWN}"
        echo "ABSTRACT_LEF=$EVENT_INNOVUS_ROOT/outputs/event_coordinator.abstract.lef"
        echo "ABSTRACT_LEF_SHA256=${RUN_ABSTRACT_LEF_SHA256:-UNKNOWN}"
        echo "DEF=$EVENT_INNOVUS_ROOT/outputs/event_coordinator.def"
        echo "DEF_SHA256=${RUN_DEF_SHA256:-UNKNOWN}"
        echo "ROUTED_PG_NETLIST=$EVENT_INNOVUS_ROOT/outputs/event_coordinator.routed.pg.v"
        echo "ROUTED_PG_NETLIST_SHA256=${RUN_PG_NETLIST_SHA256:-UNKNOWN}"
    } > "$DIAGNOSTIC_ROOT/run_evidence/artifact_hashes.rpt"

    {
        echo "LABEL=SPADMIC_EVENT_INNOVUS_EXECUTION"
        echo "STATUS=$TRANSACTION_STATUS"
        if [ "$TRANSACTION_STATUS" = "PASS" ]; then
            echo "RESULT=EVENT_INNOVUS_OOC_ABSTRACT_READY_FOR_TOP_REVIEW"
        else
            echo "RESULT=EVENT_INNOVUS_OOC_REVIEW_REQUIRED"
        fi
        echo "OUTCOME_CLASS=$OUTCOME_CLASS"
        echo "EXPECTED_HEAD=$EXPECTED_HEAD"
        echo "ACTUAL_HEAD=$ACTUAL_HEAD"
        echo "CD_RC=$CD_RC"
        echo "CHECKOUT_RC=$CHECKOUT_RC"
        echo "PULL_RC=$PULL_RC"
        echo "TRACKED_DIFF_RC=$TRACKED_DIFF_RC"
        echo "STAGED_DIFF_RC=$STAGED_DIFF_RC"
        echo "SCRIPT_GATE_RC=$SCRIPT_GATE_RC"
        echo "PORTFOLIO_RC=$PORTFOLIO_RC"
        echo "DIAGNOSTIC_CREATE_RC=$DIAGNOSTIC_CREATE_RC"
        echo "SOURCE_GENUS_HEAD=$EXPECTED_SOURCE_HEAD"
        echo "SOURCE_GENUS_RUN=$EVENT_GENUS_RUN"
        echo "SOURCE_GENUS_ROOT=$EVENT_GENUS_ROOT"
        echo "SOURCE_GENUS_MUTATION_AUTHORIZED=NO"
        echo "SOURCE_NETLIST_SHA256=$EXPECTED_NETLIST_SHA256"
        echo "SOURCE_SDC_SHA256=$EXPECTED_SDC_SHA256"
        echo "SOURCE_FILE_GATE_RC=$SOURCE_FILE_GATE_RC"
        echo "SOURCE_SHA_MANIFEST_CREATE_RC=$SOURCE_SHA_MANIFEST_CREATE_RC"
        echo "SOURCE_HASH_GATE_RC=$SOURCE_HASH_GATE_RC"
        echo "SOURCE_STATUS_GATE_RC=$SOURCE_STATUS_GATE_RC"
        echo "SOURCE_REVALIDATION_RC=$SOURCE_REVALIDATION_RC"
        echo "EVENT_ENV_GATE_RC=$EVENT_ENV_GATE_RC"
        echo "EVENT_INNOVUS_RUN=$EVENT_INNOVUS_RUN"
        echo "EVENT_INNOVUS_ROOT=$EVENT_INNOVUS_ROOT"
        echo "EVENT_INNOVUS_RC=$EVENT_INNOVUS_RC"
        echo "EVENT_CONSOLE_TEE_RC=$EVENT_CONSOLE_TEE_RC"
        echo "EVENT_INNOVUS_EXECUTED=$EVENT_INNOVUS_EXECUTED"
        echo "EVENT_INNOVUS_OOC_STATUS=$EVENT_INNOVUS_OOC_STATUS"
        echo "RUN_FILE_GATE_RC=$RUN_FILE_GATE_RC"
        echo "RUN_STATUS_GATE_RC=$RUN_STATUS_GATE_RC"
        echo "RUN_GDS_GATE_RC=$RUN_GDS_GATE_RC"
        echo "RUN_ARTIFACT_HASH_GATE_RC=$RUN_ARTIFACT_HASH_GATE_RC"
        echo "RUN_GDS_SHA256=${RUN_GDS_SHA256:-UNKNOWN}"
        echo "SOURCE_POST_RECHECK_RC=$SOURCE_POST_RECHECK_RC"
        echo "DIAGNOSTIC_COPY_GATE_RC=$DIAGNOSTIC_COPY_GATE_RC"
        echo "EVENT_PVS_BASE_DRC_STATUS=NOT_RUN"
        echo "EVENT_PVS_DENSITY_DRC_STATUS=NOT_RUN"
        echo "EVENT_PVS_LVS_STATUS=NOT_RUN"
        echo "EVENT_HANDOFF_STAGE_AUTHORIZED=$EVENT_HANDOFF_STAGE_AUTHORIZED"
        echo "ASSEMBLY_PHASE=p02_event_control"
        echo "ASSEMBLY_INSERTION_AUTHORIZED=NO"
        echo "ASSEMBLY_BLOCKED_BY=p00_tx,p01_position"
        echo "FULL_TOP_PNR_AUTHORIZED=NO"
        echo "BLOCK_PROMOTION_AUTHORIZED=NO"
        echo "SIGNOFF_READY=NO"
        echo "NEXT_GATE=$NEXT_GATE"
    } > "$DIAGNOSTIC_ROOT/event_innovus_execution_status.rpt"

    (
        if ! cd "$DIAGNOSTIC_ROOT"; then
            exit 1
        fi
        MANIFEST_RC=0
        while IFS= read -r FILE; do
            sha256sum "$FILE" || MANIFEST_RC=1
        done < <(find . -type f ! -name SHA256SUMS -print | LC_ALL=C sort) \
            > SHA256SUMS
        exit "$MANIFEST_RC"
    )
    DIAGNOSTIC_MANIFEST_CREATE_RC=$?
fi

echo
echo "===== EVENT INNOVUS EXECUTION STATUS ====="
cat "$DIAGNOSTIC_ROOT/event_innovus_execution_status.rpt" 2>/dev/null

echo
echo "===== EVENT INNOVUS OOC STATUS ====="
cat "$RUN_STATUS" 2>/dev/null

echo
echo "===== EVENT GDS EXPORT AUDIT ====="
cat "$RUN_GDS_AUDIT" 2>/dev/null

echo "DIAGNOSTIC_ROOT=$DIAGNOSTIC_ROOT"
echo "DIAGNOSTIC_MANIFEST_CREATE_RC=$DIAGNOSTIC_MANIFEST_CREATE_RC"

if [ "$TRANSACTION_STATUS" = "PASS" ] && \
   [ "$DIAGNOSTIC_COPY_GATE_RC" = "0" ] && \
   [ "$DIAGNOSTIC_MANIFEST_CREATE_RC" = "0" ]; then
    exit 0
fi

exit 1
