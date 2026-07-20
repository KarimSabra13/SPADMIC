#!/usr/bin/env bash
# Accept the existing immutable Position exact-GDS LVS MATCH without rerunning PVS.

set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
EXPECTED_HEAD="${1:-MISSING}"
SOURCE_LVS_ROOT="${2:-MISSING}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"

PACKAGE="$WORK_ROOT/handoff/innovus/blocks/spadmic_position_core/innovus_ooc_harden_position_core_gridfit_20260717_114810"
PACKAGE_GDS="$PACKAGE/gds/spadmic_position_core.gds"
PACKAGE_SOURCE="$PACKAGE/netlist/spadmic_position_core.lvs.pg.v"
PACKAGE_CDL="$PACKAGE/pdk/xh018_D_CELLS_JIHD.cdl"
POSITION_TOP=spadmic_position_core
EXPECTED_GDS_SHA=ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1
EXPECTED_SOURCE_SHA=a5e81c21e633ae1b55d8da5c8e971997f890d9cee42dff2f6cf9f9f43cad9ffb
EXPECTED_CDL_SHA=5ff10b0b31003da9bb6db59eba7d52c82435e3ab68b2ba0a1956e4d9fbaef8cf

EXPECTED_SOURCE_LVS_ROOT="$WORK_ROOT/diagnostics/position_pvs_lvs_execution_20260720_155406"
RUN_DIR="$PACKAGE/pvs/lvs/position_exact_gds_lvs_20260720_155406"
PVS_EVIDENCE="$RUN_DIR/svdb/matched"

EXPECTED_SOURCE_STATUS_SHA=529c30731f77d464da5fff07f8570dfa53fe637fd8ec257ac751ec325a2a4544
EXPECTED_RUN_STATUS_SHA=7756b045218d54aba74e85c600268ddcf78829f400412993d39d1e7986187a1a
EXPECTED_REPLAY_SHA=3dab32d283b9b20e949496ee36f783f4f0a18ec149a4bce3004d1f6927bf1460
EXPECTED_ISOLATION_SHA=441678b170db01abbd1befc5f3d8efca7a102a7dabdc62bf483526bd16ce1c6f
EXPECTED_REFERENCES_SHA=7ffe3059f34f7fed735ed33726a146aacbb346de5f246d7761809ffb91616ac5
EXPECTED_REPLACEMENTS_SHA=9406f7eb5900188000b54da345b0b3de3d0542616add9554c972903e4ac3bbba

SOURCE_STATUS="$SOURCE_LVS_ROOT/position_pvs_lvs_execution_status.rpt"
SOURCE_RUN_STATUS="$SOURCE_LVS_ROOT/run_evidence/pvs_lvs_status.rpt"
SOURCE_REPLAY="$SOURCE_LVS_ROOT/run_evidence/replay_contract_status.rpt"
SOURCE_ISOLATION="$SOURCE_LVS_ROOT/run_evidence/output_isolation.rpt"
SOURCE_REFERENCES="$SOURCE_LVS_ROOT/run_evidence/external_references.rpt"
SOURCE_DEFINES="$SOURCE_LVS_ROOT/run_evidence/preprocessor_defines.rpt"
SOURCE_INVENTORY="$SOURCE_LVS_ROOT/run_evidence/pvs_result_evidence_inventory.rpt"
SOURCE_TEMPLATE_AUDIT="$SOURCE_LVS_ROOT/template_scaffold_audit.rpt"

RUN_STATUS="$RUN_DIR/pvs_lvs_status.rpt"
RUN_REPLAY="$RUN_DIR/replay_contract_status.rpt"
RUN_ISOLATION="$RUN_DIR/output_isolation.rpt"
RUN_REFERENCES="$RUN_DIR/external_references.rpt"
RUN_DEFINES="$RUN_DIR/preprocessor_defines.rpt"
RUN_INVENTORY="$RUN_DIR/pvs_result_evidence_inventory.rpt"
RUN_REPLACEMENTS="$RUN_DIR/template_replacements.rpt"

RUN_OK=1
CD_RC=NOT_RUN
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
DIAGNOSTIC_ROOT=UNKNOWN
DIAGNOSTIC_CREATE_RC=NOT_RUN
SOURCE_FILE_GATE_RC=NOT_RUN
SOURCE_HASH_GATE_RC=NOT_RUN
SOURCE_DIAGNOSTIC_MANIFEST_RC=NOT_RUN
SOURCE_STATUS_GATE_RC=NOT_RUN
RUN_COPY_IDENTITY_GATE_RC=NOT_RUN
RUN_MANIFEST_RC=NOT_RUN
RUN_MATCH_GATE_RC=NOT_RUN
RUN_REPLAY_GATE_RC=NOT_RUN
RUN_ISOLATION_GATE_RC=NOT_RUN
RUN_REFERENCE_GATE_RC=NOT_RUN
RUN_CONTROL_GATE_RC=NOT_RUN
PACKAGE_GATE_RC=NOT_RUN
PACKAGE_SHA_MANIFEST_RC=NOT_RUN
DIAGNOSTIC_COPY_GATE_RC=NOT_RUN
SOURCE_POST_RECHECK_RC=NOT_RUN
PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=NOT_RUN
REVIEW_RUN_AUDIT_GATE_RC=NOT_RUN
PVS_WRAPPER_RC=UNKNOWN
PVS_TOOL_RC=UNKNOWN
PVS_LVS_STATUS=UNKNOWN
LVS_NEGATIVE_MATCH_COUNT=UNKNOWN
LVS_POSITIVE_MATCH_COUNT=UNKNOWN
VERIFIED_PVS_EVIDENCE=UNKNOWN
REPLAY_CONTRACT_STATUS=UNKNOWN
OUTPUT_ISOLATION_STATUS=UNKNOWN
TRANSACTION_STATUS=FAIL
TRANSACTION_RESULT=EXISTING_EXACT_GDS_PVS_LVS_MATCH_NOT_ACCEPTED
OUTCOME_CLASS=NOT_CLASSIFIED
NEXT_GATE=STOP_AND_REVIEW_POSITION_LVS_MATCH_ACCEPTANCE_FAILURE

if [ "$EXPECTED_HEAD" = "MISSING" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: expected repository HEAD argument missing"
    RUN_OK=0
fi

if [ "$SOURCE_LVS_ROOT" = "MISSING" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: source LVS diagnostic root missing"
    RUN_OK=0
elif [ "$SOURCE_LVS_ROOT" != "$EXPECTED_SOURCE_LVS_ROOT" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: source LVS diagnostic root is not the accepted run"
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
    REVIEW_STAMP="$(date +%Y%m%d_%H%M%S)"
    DIAGNOSTIC_ROOT="$WORK_ROOT/diagnostics/position_pvs_lvs_match_review_$REVIEW_STAMP"
    if [ -e "$DIAGNOSTIC_ROOT" ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: fresh review path already exists"
        DIAGNOSTIC_CREATE_RC=1
        RUN_OK=0
    else
        mkdir -p "$DIAGNOSTIC_ROOT/source_lvs_execution" "$DIAGNOSTIC_ROOT/run_evidence"
        DIAGNOSTIC_CREATE_RC=$?
        [ "$DIAGNOSTIC_CREATE_RC" -eq 0 ] || RUN_OK=0
    fi
    echo "DIAGNOSTIC_ROOT=$DIAGNOSTIC_ROOT"
    echo "SOURCE_LVS_ROOT=$SOURCE_LVS_ROOT"
    echo "RUN_DIR=$RUN_DIR"
    echo "DIAGNOSTIC_CREATE_RC=$DIAGNOSTIC_CREATE_RC"
fi

if [ "$RUN_OK" -eq 1 ]; then
    SOURCE_FILE_GATE_RC=0
    for FILE in \
        "$SOURCE_STATUS" \
        "$SOURCE_RUN_STATUS" \
        "$SOURCE_REPLAY" \
        "$SOURCE_ISOLATION" \
        "$SOURCE_REFERENCES" \
        "$SOURCE_DEFINES" \
        "$SOURCE_INVENTORY" \
        "$SOURCE_TEMPLATE_AUDIT" \
        "$SOURCE_LVS_ROOT/SHA256SUMS" \
        "$RUN_STATUS" \
        "$RUN_REPLAY" \
        "$RUN_ISOLATION" \
        "$RUN_REFERENCES" \
        "$RUN_DEFINES" \
        "$RUN_INVENTORY" \
        "$RUN_REPLACEMENTS" \
        "$RUN_DIR/pvslvsctl" \
        "$RUN_DIR/run.pvs" \
        "$RUN_DIR/pvs.stdout.log" \
        "$RUN_DIR/SHA256SUMS" \
        "$PVS_EVIDENCE" \
        "$PACKAGE_GDS" \
        "$PACKAGE_SOURCE" \
        "$PACKAGE_CDL" \
        "$PACKAGE/manifests/SHA256SUMS"
    do
        if [ ! -s "$FILE" ]; then
            echo "MISSING_OR_EMPTY=$FILE"
            SOURCE_FILE_GATE_RC=1
        fi
    done
    echo "SOURCE_FILE_GATE_RC=$SOURCE_FILE_GATE_RC"
    [ "$SOURCE_FILE_GATE_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    SOURCE_HASH_GATE_RC=0
    for SPEC in \
        "$SOURCE_STATUS|$EXPECTED_SOURCE_STATUS_SHA" \
        "$SOURCE_RUN_STATUS|$EXPECTED_RUN_STATUS_SHA" \
        "$SOURCE_REPLAY|$EXPECTED_REPLAY_SHA" \
        "$SOURCE_ISOLATION|$EXPECTED_ISOLATION_SHA" \
        "$SOURCE_REFERENCES|$EXPECTED_REFERENCES_SHA" \
        "$RUN_STATUS|$EXPECTED_RUN_STATUS_SHA" \
        "$RUN_REPLAY|$EXPECTED_REPLAY_SHA" \
        "$RUN_ISOLATION|$EXPECTED_ISOLATION_SHA" \
        "$RUN_REFERENCES|$EXPECTED_REFERENCES_SHA" \
        "$RUN_REPLACEMENTS|$EXPECTED_REPLACEMENTS_SHA" \
        "$PACKAGE_GDS|$EXPECTED_GDS_SHA" \
        "$PACKAGE_SOURCE|$EXPECTED_SOURCE_SHA" \
        "$PACKAGE_CDL|$EXPECTED_CDL_SHA"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_SHA="${SPEC#*|}"
        ACTUAL_SHA="$(sha256sum "$FILE" 2>/dev/null | awk '{print $1}')"
        echo "SOURCE_FILE=$FILE"
        echo "SOURCE_EXPECTED_SHA256=$EXPECTED_SHA"
        echo "SOURCE_ACTUAL_SHA256=$ACTUAL_SHA"
        [ "$ACTUAL_SHA" = "$EXPECTED_SHA" ] || SOURCE_HASH_GATE_RC=1
    done
    echo "SOURCE_HASH_GATE_RC=$SOURCE_HASH_GATE_RC"
    [ "$SOURCE_HASH_GATE_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    (
        if cd "$SOURCE_LVS_ROOT"; then
            sha256sum -c SHA256SUMS
        else
            false
        fi
    ) >"$DIAGNOSTIC_ROOT/source_lvs_execution/SHA256SUMS.check.rpt" 2>&1
    SOURCE_DIAGNOSTIC_MANIFEST_RC=$?

    (
        if cd "$RUN_DIR"; then
            sha256sum -c SHA256SUMS
        else
            false
        fi
    ) >"$DIAGNOSTIC_ROOT/run_evidence/SHA256SUMS.check.rpt" 2>&1
    RUN_MANIFEST_RC=$?

    (
        if cd "$PACKAGE"; then
            sha256sum -c manifests/SHA256SUMS
        else
            false
        fi
    ) >"$DIAGNOSTIC_ROOT/package_sha256_check.rpt" 2>&1
    PACKAGE_SHA_MANIFEST_RC=$?

    echo "SOURCE_DIAGNOSTIC_MANIFEST_RC=$SOURCE_DIAGNOSTIC_MANIFEST_RC"
    echo "RUN_MANIFEST_RC=$RUN_MANIFEST_RC"
    echo "PACKAGE_SHA_MANIFEST_RC=$PACKAGE_SHA_MANIFEST_RC"
    if [ "$SOURCE_DIAGNOSTIC_MANIFEST_RC" -ne 0 ] || \
       [ "$RUN_MANIFEST_RC" -ne 0 ] || \
       [ "$PACKAGE_SHA_MANIFEST_RC" -ne 0 ]; then
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    SOURCE_STATUS_GATE_RC=0
    for EXPECTED_LINE in \
        "STATUS=FAIL" \
        "RESULT=PVS_EXACT_GDS_LVS_INFRASTRUCTURE_OR_RESULT_CLASSIFICATION_FAILED" \
        "PACKAGE=$PACKAGE" \
        "PACKAGE_GDS=$PACKAGE_GDS" \
        "PACKAGE_GDS_SHA256=$EXPECTED_GDS_SHA" \
        "CANONICAL_LVS_SOURCE=$PACKAGE_SOURCE" \
        "CANONICAL_LVS_SOURCE_SHA256=$EXPECTED_SOURCE_SHA" \
        "STDCELL_CDL=$PACKAGE_CDL" \
        "STDCELL_CDL_SHA256=$EXPECTED_CDL_SHA" \
        "LAYOUT_TOP=$POSITION_TOP" \
        "SOURCE_TOP=$POSITION_TOP" \
        "RUN_DIR=$RUN_DIR" \
        "PVS_WRAPPER_RC=0" \
        "PVS_TOOL_RC=0" \
        "PVS_LVS_STATUS=MATCH" \
        "LVS_NEGATIVE_MATCH_COUNT=0" \
        "LVS_POSITIVE_MATCH_COUNT=3" \
        "PVS_RESULT_EVIDENCE=$PVS_EVIDENCE" \
        "REPLAY_CONTRACT_STATUS=PASS" \
        "OUTPUT_ISOLATION_STATUS=PASS" \
        "RUN_FILE_GATE_RC=0" \
        "RUN_AUDIT_GATE_RC=1" \
        "RUN_MANIFEST_RC=0" \
        "DIAGNOSTIC_COPY_GATE_RC=0" \
        "SOURCE_POST_RECHECK_RC=0" \
        "PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC=0" \
        "PVS_EXECUTED=YES"
    do
        grep -Fxq -- "$EXPECTED_LINE" "$SOURCE_STATUS"
        [ "$?" -eq 0 ] || SOURCE_STATUS_GATE_RC=1
    done
    echo "SOURCE_STATUS_GATE_RC=$SOURCE_STATUS_GATE_RC"
    [ "$SOURCE_STATUS_GATE_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    RUN_COPY_IDENTITY_GATE_RC=0
    for SPEC in \
        "$SOURCE_RUN_STATUS|$RUN_STATUS" \
        "$SOURCE_REPLAY|$RUN_REPLAY" \
        "$SOURCE_ISOLATION|$RUN_ISOLATION" \
        "$SOURCE_REFERENCES|$RUN_REFERENCES" \
        "$SOURCE_DEFINES|$RUN_DEFINES" \
        "$SOURCE_INVENTORY|$RUN_INVENTORY"
    do
        LEFT="${SPEC%%|*}"
        RIGHT="${SPEC#*|}"
        cmp -s "$LEFT" "$RIGHT"
        [ "$?" -eq 0 ] || RUN_COPY_IDENTITY_GATE_RC=1
    done
    echo "RUN_COPY_IDENTITY_GATE_RC=$RUN_COPY_IDENTITY_GATE_RC"
    [ "$RUN_COPY_IDENTITY_GATE_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    RUN_MATCH_GATE_RC=0
    for EXPECTED_LINE in \
        "LABEL=SPADMIC_PVS_HANDOFF_RESULT" \
        "MODE=LVS" \
        "PVS_RC=0" \
        "PVS_LVS_STATUS=MATCH" \
        "EVIDENCE=$PVS_EVIDENCE" \
        "LVS_NEGATIVE_MATCH_COUNT=0" \
        "LVS_POSITIVE_MATCH_COUNT=3" \
        "PACKAGE=$PACKAGE" \
        "CROSS_BLOCK_CONTROL_SCAFFOLD_AUTHORIZED=YES" \
        "LAYOUT_TOP=$POSITION_TOP" \
        "SOURCE_TOP=$POSITION_TOP" \
        "GDS=$PACKAGE_GDS" \
        "GDS_SHA256=$EXPECTED_GDS_SHA" \
        "LVS_SOURCE=$PACKAGE_SOURCE" \
        "LVS_SOURCE_SHA256=$EXPECTED_SOURCE_SHA" \
        "STDCELL_CDL=$PACKAGE_CDL" \
        "STDCELL_CDL_SHA256=$EXPECTED_CDL_SHA"
    do
        grep -Fxq -- "$EXPECTED_LINE" "$RUN_STATUS"
        [ "$?" -eq 0 ] || RUN_MATCH_GATE_RC=1
    done
    grep -Eq '^LVS_POSITIVE_MATCH_COUNT=[1-9][0-9]*$' "$RUN_STATUS"
    [ "$?" -eq 0 ] || RUN_MATCH_GATE_RC=1
    echo "RUN_MATCH_GATE_RC=$RUN_MATCH_GATE_RC"
    [ "$RUN_MATCH_GATE_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    RUN_REPLAY_GATE_RC=0
    for EXPECTED_LINE in \
        "STATUS=PASS" \
        "MODE=LVS" \
        "EXECUTION_DIRECTORY_STATUS=PASS" \
        "OUTPUT_ISOLATION_STATUS=PASS" \
        "LAYOUT_TOP=$POSITION_TOP" \
        "SOURCE_TOP=$POSITION_TOP" \
        "GDS=$PACKAGE_GDS" \
        "SOURCE=$PACKAGE_SOURCE" \
        "CDL=$PACKAGE_CDL"
    do
        grep -Fxq -- "$EXPECTED_LINE" "$RUN_REPLAY"
        [ "$?" -eq 0 ] || RUN_REPLAY_GATE_RC=1
    done
    echo "RUN_REPLAY_GATE_RC=$RUN_REPLAY_GATE_RC"
    [ "$RUN_REPLAY_GATE_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    RUN_ISOLATION_GATE_RC=0
    for EXPECTED_LINE in \
        "STATUS=PASS" \
        "MODE=LVS" \
        "RUN_DIR=$RUN_DIR" \
        "CONTROL=$RUN_DIR/pvslvsctl" \
        "SPICE_OUTPUT_REWRITE_COUNT=1" \
        "LAYOUT_GDS_INPUT=$PACKAGE_GDS" \
        "LAYOUT_GDS_REWRITE_COUNT=1" \
        "SCHEMATIC_VERILOG_INPUT=$PACKAGE_SOURCE" \
        "SCHEMATIC_VERILOG_ACTION=REPLACED_EXISTING" \
        "SCHEMATIC_CDL_INPUT=$PACKAGE_CDL" \
        "SCHEMATIC_CDL_ACTION=ADDED_MISSING" \
        "LVS_REPORT_REWRITE_COUNT=1" \
        "ERC_SUMMARY_REWRITE_COUNT=1" \
        "ERC_RESULTS_DB_REWRITE_COUNT=1" \
        "SVDB_DIRECTORY=$RUN_DIR/svdb" \
        "SVDB_ACTION=ADDED_MISSING" \
        "SVDB_REWRITE_COUNT=0"
    do
        grep -Fxq -- "$EXPECTED_LINE" "$RUN_ISOLATION"
        [ "$?" -eq 0 ] || RUN_ISOLATION_GATE_RC=1
    done
    echo "RUN_ISOLATION_GATE_RC=$RUN_ISOLATION_GATE_RC"
    [ "$RUN_ISOLATION_GATE_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    RUN_REFERENCE_GATE_RC=0
    grep -q '^MISSING=' "$RUN_REFERENCES"
    [ "$?" -ne 0 ] || RUN_REFERENCE_GATE_RC=1
    for EXPECTED_LINE in \
        "FILE=$PACKAGE_GDS|11523506|$EXPECTED_GDS_SHA" \
        "FILE=$PACKAGE_SOURCE|1471851|$EXPECTED_SOURCE_SHA" \
        "FILE=$PACKAGE_CDL|2306599|$EXPECTED_CDL_SHA"
    do
        grep -Fxq -- "$EXPECTED_LINE" "$RUN_REFERENCES"
        [ "$?" -eq 0 ] || RUN_REFERENCE_GATE_RC=1
    done
    echo "RUN_REFERENCE_GATE_RC=$RUN_REFERENCE_GATE_RC"
    [ "$RUN_REFERENCE_GATE_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    RUN_CONTROL_GATE_RC=0
    [ "$(grep -Foc "$PACKAGE_GDS" "$RUN_DIR/pvslvsctl")" -eq 1 ] || RUN_CONTROL_GATE_RC=1
    [ "$(grep -Foc "$PACKAGE_SOURCE" "$RUN_DIR/pvslvsctl")" -eq 1 ] || RUN_CONTROL_GATE_RC=1
    [ "$(grep -Foc "$PACKAGE_CDL" "$RUN_DIR/pvslvsctl")" -eq 1 ] || RUN_CONTROL_GATE_RC=1
    [ "$(grep -Foc "$RUN_DIR/svdb" "$RUN_DIR/pvslvsctl")" -eq 1 ] || RUN_CONTROL_GATE_RC=1
    echo "RUN_CONTROL_GATE_RC=$RUN_CONTROL_GATE_RC"
    [ "$RUN_CONTROL_GATE_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    PACKAGE_GATE_RC=0
    for SPEC in \
        "$PACKAGE_GDS|$EXPECTED_GDS_SHA" \
        "$PACKAGE_SOURCE|$EXPECTED_SOURCE_SHA" \
        "$PACKAGE_CDL|$EXPECTED_CDL_SHA"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_SHA="${SPEC#*|}"
        ACTUAL_SHA="$(sha256sum "$FILE" 2>/dev/null | awk '{print $1}')"
        [ "$ACTUAL_SHA" = "$EXPECTED_SHA" ] || PACKAGE_GATE_RC=1
    done
    echo "PACKAGE_GATE_RC=$PACKAGE_GATE_RC"
    [ "$PACKAGE_GATE_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$DIAGNOSTIC_ROOT" != "UNKNOWN" ]; then
    DIAGNOSTIC_COPY_GATE_RC=0
    for SPEC in \
        "$SOURCE_STATUS|$DIAGNOSTIC_ROOT/source_lvs_execution/position_pvs_lvs_execution_status.rpt" \
        "$SOURCE_TEMPLATE_AUDIT|$DIAGNOSTIC_ROOT/source_lvs_execution/template_scaffold_audit.rpt" \
        "$SOURCE_LVS_ROOT/SHA256SUMS|$DIAGNOSTIC_ROOT/source_lvs_execution/SHA256SUMS" \
        "$RUN_STATUS|$DIAGNOSTIC_ROOT/run_evidence/pvs_lvs_status.rpt" \
        "$RUN_REPLAY|$DIAGNOSTIC_ROOT/run_evidence/replay_contract_status.rpt" \
        "$RUN_ISOLATION|$DIAGNOSTIC_ROOT/run_evidence/output_isolation.rpt" \
        "$RUN_REFERENCES|$DIAGNOSTIC_ROOT/run_evidence/external_references.rpt" \
        "$RUN_DEFINES|$DIAGNOSTIC_ROOT/run_evidence/preprocessor_defines.rpt" \
        "$RUN_INVENTORY|$DIAGNOSTIC_ROOT/run_evidence/pvs_result_evidence_inventory.rpt" \
        "$RUN_REPLACEMENTS|$DIAGNOSTIC_ROOT/run_evidence/template_replacements.rpt" \
        "$RUN_DIR/SHA256SUMS|$DIAGNOSTIC_ROOT/run_evidence/SHA256SUMS"
    do
        SOURCE_FILE="${SPEC%%|*}"
        DESTINATION_FILE="${SPEC#*|}"
        cp -p "$SOURCE_FILE" "$DESTINATION_FILE"
        [ "$?" -eq 0 ] || DIAGNOSTIC_COPY_GATE_RC=1
    done
    echo "DIAGNOSTIC_COPY_GATE_RC=$DIAGNOSTIC_COPY_GATE_RC"
    [ "$DIAGNOSTIC_COPY_GATE_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$DIAGNOSTIC_ROOT" != "UNKNOWN" ]; then
    SOURCE_POST_RECHECK_RC=0
    for SPEC in \
        "$SOURCE_STATUS|$EXPECTED_SOURCE_STATUS_SHA" \
        "$RUN_STATUS|$EXPECTED_RUN_STATUS_SHA" \
        "$RUN_REPLAY|$EXPECTED_REPLAY_SHA" \
        "$RUN_ISOLATION|$EXPECTED_ISOLATION_SHA" \
        "$RUN_REFERENCES|$EXPECTED_REFERENCES_SHA" \
        "$RUN_REPLACEMENTS|$EXPECTED_REPLACEMENTS_SHA"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_SHA="${SPEC#*|}"
        ACTUAL_SHA="$(sha256sum "$FILE" 2>/dev/null | awk '{print $1}')"
        [ "$ACTUAL_SHA" = "$EXPECTED_SHA" ] || SOURCE_POST_RECHECK_RC=1
    done

    (
        if cd "$PACKAGE"; then
            sha256sum -c manifests/SHA256SUMS
        else
            false
        fi
    ) >"$DIAGNOSTIC_ROOT/package_sha256_post_review.rpt" 2>&1
    PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=$?

    echo "SOURCE_POST_RECHECK_RC=$SOURCE_POST_RECHECK_RC"
    echo "PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=$PACKAGE_POST_REVIEW_SHA_MANIFEST_RC"
    if [ "$SOURCE_POST_RECHECK_RC" -ne 0 ] || \
       [ "$PACKAGE_POST_REVIEW_SHA_MANIFEST_RC" -ne 0 ]; then
        RUN_OK=0
    fi
fi

REVIEW_RUN_AUDIT_GATE_RC=1
if [ "$RUN_MATCH_GATE_RC" = "0" ] && \
   [ "$RUN_REPLAY_GATE_RC" = "0" ] && \
   [ "$RUN_ISOLATION_GATE_RC" = "0" ] && \
   [ "$RUN_REFERENCE_GATE_RC" = "0" ] && \
   [ "$RUN_CONTROL_GATE_RC" = "0" ] && \
   [ "$RUN_MANIFEST_RC" = "0" ]; then
    REVIEW_RUN_AUDIT_GATE_RC=0
fi

if [ "$RUN_OK" -eq 1 ] && [ "$REVIEW_RUN_AUDIT_GATE_RC" -eq 0 ]; then
    TRANSACTION_STATUS=PASS
    TRANSACTION_RESULT=EXISTING_EXACT_GDS_PVS_LVS_MATCH_ACCEPTED
    OUTCOME_CLASS=ATTRIBUTABLE_MATCH
    PVS_WRAPPER_RC=0
    PVS_TOOL_RC=0
    PVS_LVS_STATUS=MATCH
    LVS_NEGATIVE_MATCH_COUNT=0
    LVS_POSITIVE_MATCH_COUNT=3
    VERIFIED_PVS_EVIDENCE="$PVS_EVIDENCE"
    REPLAY_CONTRACT_STATUS=PASS
    OUTPUT_ISOLATION_STATUS=PASS
    NEXT_GATE=START_EVENT_OOC_AND_REVIEW_POSITION_DENSITY_DISPOSITION
fi

if [ "$DIAGNOSTIC_ROOT" != "UNKNOWN" ]; then
    STATUS_REPORT="$DIAGNOSTIC_ROOT/position_pvs_lvs_match_review_status.rpt"
    {
        echo "LABEL=SPADMIC_POSITION_PVS_LVS_MATCH_REVIEW"
        echo "STATUS=$TRANSACTION_STATUS"
        echo "RESULT=$TRANSACTION_RESULT"
        echo "SOURCE_LVS_EXECUTION_ROOT=$SOURCE_LVS_ROOT"
        echo "SOURCE_LVS_EXECUTION_STATUS_SHA256=$EXPECTED_SOURCE_STATUS_SHA"
        echo "SOURCE_RUN_DIR=$RUN_DIR"
        echo "SOURCE_TRANSACTION_STATUS=FAIL"
        echo "SOURCE_RUN_AUDIT_GATE_RC=1"
        echo "SOURCE_RUN_AUDIT_FAILURE=STALE_SVDB_REWRITE_COUNT_EXPECTATION"
        echo "SOURCE_RECORDED_PVS_WRAPPER_RC=0"
        echo "SOURCE_RECORDED_PVS_TOOL_RC=0"
        echo "SOURCE_RECORDED_PVS_LVS_STATUS=MATCH"
        echo "SOURCE_RECORDED_LVS_NEGATIVE_MATCH_COUNT=0"
        echo "SOURCE_RECORDED_LVS_POSITIVE_MATCH_COUNT=3"
        echo "REVIEW_RUN_AUDIT_GATE_RC=$REVIEW_RUN_AUDIT_GATE_RC"
        echo "RUN_AUDIT_CORRECTION=SVDB_ADDED_MISSING_IS_VALID_NORMALIZATION"
        echo "PACKAGE=$PACKAGE"
        echo "PACKAGE_GDS=$PACKAGE_GDS"
        echo "PACKAGE_GDS_SHA256=$EXPECTED_GDS_SHA"
        echo "CANONICAL_LVS_SOURCE=$PACKAGE_SOURCE"
        echo "CANONICAL_LVS_SOURCE_SHA256=$EXPECTED_SOURCE_SHA"
        echo "STDCELL_CDL=$PACKAGE_CDL"
        echo "STDCELL_CDL_SHA256=$EXPECTED_CDL_SHA"
        echo "LAYOUT_TOP=$POSITION_TOP"
        echo "SOURCE_TOP=$POSITION_TOP"
        echo "OUTCOME_CLASS=$OUTCOME_CLASS"
        echo "PVS_WRAPPER_RC=$PVS_WRAPPER_RC"
        echo "PVS_TOOL_RC=$PVS_TOOL_RC"
        echo "PVS_LVS_STATUS=$PVS_LVS_STATUS"
        echo "LVS_NEGATIVE_MATCH_COUNT=$LVS_NEGATIVE_MATCH_COUNT"
        echo "LVS_POSITIVE_MATCH_COUNT=$LVS_POSITIVE_MATCH_COUNT"
        echo "PVS_RESULT_EVIDENCE=$VERIFIED_PVS_EVIDENCE"
        echo "REPLAY_CONTRACT_STATUS=$REPLAY_CONTRACT_STATUS"
        echo "OUTPUT_ISOLATION_STATUS=$OUTPUT_ISOLATION_STATUS"
        echo "SOURCE_FILE_GATE_RC=$SOURCE_FILE_GATE_RC"
        echo "SOURCE_HASH_GATE_RC=$SOURCE_HASH_GATE_RC"
        echo "SOURCE_DIAGNOSTIC_MANIFEST_RC=$SOURCE_DIAGNOSTIC_MANIFEST_RC"
        echo "SOURCE_STATUS_GATE_RC=$SOURCE_STATUS_GATE_RC"
        echo "RUN_COPY_IDENTITY_GATE_RC=$RUN_COPY_IDENTITY_GATE_RC"
        echo "RUN_MANIFEST_RC=$RUN_MANIFEST_RC"
        echo "PACKAGE_SHA_MANIFEST_RC=$PACKAGE_SHA_MANIFEST_RC"
        echo "RUN_MATCH_GATE_RC=$RUN_MATCH_GATE_RC"
        echo "RUN_REPLAY_GATE_RC=$RUN_REPLAY_GATE_RC"
        echo "RUN_ISOLATION_GATE_RC=$RUN_ISOLATION_GATE_RC"
        echo "RUN_REFERENCE_GATE_RC=$RUN_REFERENCE_GATE_RC"
        echo "RUN_CONTROL_GATE_RC=$RUN_CONTROL_GATE_RC"
        echo "PACKAGE_GATE_RC=$PACKAGE_GATE_RC"
        echo "DIAGNOSTIC_COPY_GATE_RC=$DIAGNOSTIC_COPY_GATE_RC"
        echo "SOURCE_POST_RECHECK_RC=$SOURCE_POST_RECHECK_RC"
        echo "PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=$PACKAGE_POST_REVIEW_SHA_MANIFEST_RC"
        echo "SOURCE_PVS_EXECUTED=YES"
        echo "PVS_EXECUTED=NO"
        echo "PVS_RERUN_AUTHORIZED=NO"
        echo "PVS_BASE_DRC_STATUS=PASS"
        echo "PVS_DENSITY_DRC_STATUS=FAIL"
        echo "PVS_DENSITY_DRC_PRIMARY_RESULTS=4"
        echo "DENSITY_DEBT_CLASS=OOC_WHOLE_EXTENT_MINIMUM_COVERAGE"
        echo "DENSITY_DISPOSITION_STATUS=REVIEW_REQUIRED_FOR_ASSEMBLED_FILL_OR_FORMAL_WAIVER"
        echo "BLOCK_PROMOTION_AUTHORIZED=NO"
        echo "SIGNOFF_READY=NO"
        echo "EVENT_OOC_START_AUTHORIZED=$([ "$TRANSACTION_STATUS" = "PASS" ] && echo YES || echo NO)"
        echo "NEXT_GATE=$NEXT_GATE"
    } | tee "$STATUS_REPORT"

    (
        if cd "$DIAGNOSTIC_ROOT"; then
            find . -type f ! -name SHA256SUMS -print0 \
                | sort -z | xargs -0 sha256sum
        else
            false
        fi
    ) >"$DIAGNOSTIC_ROOT/SHA256SUMS"
    DIAGNOSTIC_MANIFEST_CREATE_RC=$?
    echo "DIAGNOSTIC_MANIFEST_CREATE_RC=$DIAGNOSTIC_MANIFEST_CREATE_RC"

    echo
    echo "===== POSITION EXACT-GDS PVS LVS MATCH REVIEW STATUS ====="
    cat "$STATUS_REPORT"
fi

if [ "$TRANSACTION_STATUS" = "PASS" ] && \
   [ "${DIAGNOSTIC_MANIFEST_CREATE_RC:-1}" = "0" ]; then
    true
else
    false
fi
