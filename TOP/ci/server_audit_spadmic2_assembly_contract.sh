#!/usr/bin/env bash

###############################################################################
# Immutable, read-only SPADMIC2/matrice5 assembly audit.
# Usage: bash TOP/ci/server_audit_spadmic2_assembly_contract.sh <expected-head>
###############################################################################

set +e

REPO="${SPADMIC_REPO:-/home/validmgr/ksabra/2026_SPAD/SPADMIC}"
EXPECTED_HEAD="${1:-MISSING}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
CADENCE_LAUNCH_DIR="${SPADMIC_CADENCE_LAUNCH_DIR:-/group/validmgr/PROJET/Prj_xh018/ksabra/cds_V0}"
CADENCE_CDS_LIB="$CADENCE_LAUNCH_DIR/cds.lib"
TOP_OA_PATH=/group/validmgr/PROJET/Prj_xh018/ksabra/cds/design/SPADMIC2/layout
MATRIX_OA_LIBRARY_PATH=/group/validmgr/PROJET/Prj_xh018/spadmic/TOPLEVEL
MATRIX_OA_PATH="$MATRIX_OA_LIBRARY_PATH/matrice5"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
DIAGNOSTIC_ROOT="$WORK_ROOT/diagnostics/spadmic2_matrice5_assembly_audit_$TIMESTAMP"
RAW_ROOT="$DIAGNOSTIC_ROOT/raw_oa_export"
PROCESSED_ROOT="$DIAGNOSTIC_ROOT/processed_contract"
SESSION_CDS_LIB="$DIAGNOSTIC_ROOT/audit_session.cds.lib"

RUN_OK=1
CD_RC=NOT_RUN
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ENTRY_HEAD=UNKNOWN
ACTUAL_HEAD=UNKNOWN
REEXECUTED="${SPADMIC_AUDIT_REEXECUTED:-0}"
REEXEC_EXEC_RC=NOT_RUN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
SOURCE_FILE_GATE_RC=NOT_RUN
CADENCE_LAUNCH_GATE_RC=NOT_RUN
DIAGNOSTIC_CREATE_RC=NOT_RUN
SESSION_CDS_LIB_CREATE_RC=NOT_RUN
VIRTUOSO_RC=NOT_RUN
OA_EXPORT_GATE_RC=NOT_RUN
PROCESS_RC=NOT_RUN
SOURCE_STABILITY_RC=NOT_RUN
MANIFEST_RC=NOT_RUN

inventory_tree() {
    local source_root="$1"
    local output_file="$2"
    if [ ! -d "$source_root" ]; then
        return 1
    fi
    # Process locks and NFS silly-renames are not persistent OA source content.
    find "$source_root" \
        -type f \
        ! -name '.nfs*' \
        ! -name '*.cdslck' \
        ! -name '*.cdslck.*' \
        -print0 2>/dev/null |
        sort -z |
        xargs -0 -r sha256sum > "$output_file"
}

if [ "$EXPECTED_HEAD" = "MISSING" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: expected repository HEAD argument missing"
    RUN_OK=0
fi

if [ -d "$REPO/.git" ]; then
    cd "$REPO"
    CD_RC=$?
    if [ "$CD_RC" = "0" ]; then
        ENTRY_HEAD="$(git rev-parse HEAD 2>/dev/null)"
    fi
else
    echo "STOP_HERE_DO_NOT_CONTINUE: repository missing: $REPO"
    CD_RC=1
    RUN_OK=0
fi

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
    if [ "$CHECKOUT_RC" != "0" ] || [ "$PULL_RC" != "0" ] || \
       [ "$ACTUAL_HEAD" != "$EXPECTED_HEAD" ] || \
       [ "$TRACKED_DIFF_RC" != "0" ] || [ "$STAGED_DIFF_RC" != "0" ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: checkout is not attributable"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ] && [ "$ENTRY_HEAD" != "$ACTUAL_HEAD" ]; then
    if [ "$REEXECUTED" = "0" ]; then
        echo "WRAPPER_FAST_FORWARD_DETECTED=$ENTRY_HEAD:$ACTUAL_HEAD"
        echo "WRAPPER_REEXECUTION_STATUS=STARTING_FRESH_CHECKOUT"
        export SPADMIC_AUDIT_REEXECUTED=1
        exec bash "$REPO/TOP/ci/server_audit_spadmic2_assembly_contract.sh" \
            "$EXPECTED_HEAD"
        REEXEC_EXEC_RC=$?
        echo "WRAPPER_REEXECUTION_STATUS=EXEC_FAILED"
        RUN_OK=0
    else
        echo "STOP_HERE_DO_NOT_CONTINUE: repository changed during wrapper re-execution"
        RUN_OK=0
    fi
fi

SOURCE_FILE_GATE_RC=0
for REQUIRED in \
    "$TOP_OA_PATH" \
    "$MATRIX_OA_LIBRARY_PATH" \
    "$MATRIX_OA_PATH" \
    "$REPO/TOP/pnr/scripts/audit_spadmic2_assembly_contract.il" \
    "$REPO/TOP/pnr/scripts/process_spadmic2_assembly_audit.py" \
    "$REPO/TOP/pnr/assembly/spadmic_digital_assembly_contract.json" \
    "$REPO/TOP/pnr/assembly/matrice5_unknown_family_policy.csv"
do
    if [ ! -e "$REQUIRED" ]; then
        echo "MISSING_REQUIRED_SOURCE=$REQUIRED"
        SOURCE_FILE_GATE_RC=1
    fi
done
if [ "$SOURCE_FILE_GATE_RC" != "0" ]; then
    RUN_OK=0
fi

CADENCE_LAUNCH_GATE_RC=0
if [ ! -d "$CADENCE_LAUNCH_DIR" ]; then
    echo "MISSING_CADENCE_LAUNCH_DIR=$CADENCE_LAUNCH_DIR"
    CADENCE_LAUNCH_GATE_RC=1
fi
for REQUIRED_CADENCE_FILE in \
    "$CADENCE_CDS_LIB" \
    "$CADENCE_LAUNCH_DIR/.cdsinit"
do
    if [ ! -r "$REQUIRED_CADENCE_FILE" ]; then
        echo "MISSING_CADENCE_LAUNCH_FILE=$REQUIRED_CADENCE_FILE"
        CADENCE_LAUNCH_GATE_RC=1
    fi
done
VIRTUOSO_BIN="$(command -v virtuoso 2>/dev/null)"
if [ -z "$VIRTUOSO_BIN" ]; then
    echo "MISSING_CADENCE_EXECUTABLE=virtuoso"
    CADENCE_LAUNCH_GATE_RC=1
fi
if [ "$CADENCE_LAUNCH_GATE_RC" != "0" ]; then
    RUN_OK=0
fi

if [ "$RUN_OK" = "1" ]; then
    mkdir -p "$RAW_ROOT" "$PROCESSED_ROOT"
    DIAGNOSTIC_CREATE_RC=$?
    if [ "$DIAGNOSTIC_CREATE_RC" = "0" ]; then
        {
            echo "INCLUDE $CADENCE_CDS_LIB"
            echo "DEFINE TOPLEVEL $MATRIX_OA_LIBRARY_PATH"
        } > "$SESSION_CDS_LIB"
        SESSION_CDS_LIB_CREATE_RC=$?
    fi
    if [ "$DIAGNOSTIC_CREATE_RC" != "0" ] || \
       [ "$SESSION_CDS_LIB_CREATE_RC" != "0" ]; then
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ]; then
    {
        echo "LABEL=SPADMIC_XFAB_CADENCE_LAUNCH_CONTRACT"
        echo "STATUS=PASS"
        echo "CADENCE_LAUNCH_DIR=$CADENCE_LAUNCH_DIR"
        echo "CADENCE_CDS_LIB=$CADENCE_CDS_LIB"
        echo "CADENCE_CDS_LIB_SHA256=$(sha256sum "$CADENCE_CDS_LIB" | awk '{print $1}')"
        echo "CADENCE_SESSION_CDS_LIB=$SESSION_CDS_LIB"
        echo "CADENCE_SESSION_CDS_LIB_SHA256=$(sha256sum "$SESSION_CDS_LIB" | awk '{print $1}')"
        echo "CADENCE_SESSION_CDS_LIB_MODE=RUN_LOCAL_OVERLAY"
        echo "MATRIX_LIBRARY_BINDING=TOPLEVEL:$MATRIX_OA_LIBRARY_PATH"
        echo "SOURCE_CDS_LIB_MUTATION_AUTHORIZED=NO"
        echo "VIRTUOSO_BIN=$VIRTUOSO_BIN"
        echo "EXPECTED_XFAB_COMMAND=xfab -p Prj_xh018 -t xh018 -m 1131 -y 2023 -v"
    } > "$DIAGNOSTIC_ROOT/cadence_launch_contract.rpt"
    {
        echo "LABEL=SPADMIC_OA_CANONICAL_SOURCE_INVENTORY_POLICY"
        echo "STATUS=PASS"
        echo "POLICY=CANONICAL_OA_CONTENT_V1"
        echo "SOURCE_MUTATION_AUTHORIZED=NO"
        echo "EXCLUDED_BASENAME_PATTERN=.nfs*"
        echo "EXCLUDED_BASENAME_PATTERN=*.cdslck"
        echo "EXCLUDED_BASENAME_PATTERN=*.cdslck.*"
    } > "$DIAGNOSTIC_ROOT/source_inventory_policy.rpt"
    inventory_tree "$TOP_OA_PATH" "$DIAGNOSTIC_ROOT/spadmic2_source.pre.sha256"
    TOP_PRE_RC=$?
    inventory_tree "$MATRIX_OA_PATH" "$DIAGNOSTIC_ROOT/matrice5_source.pre.sha256"
    MATRIX_PRE_RC=$?
    if [ "$TOP_PRE_RC" != "0" ] || [ "$MATRIX_PRE_RC" != "0" ]; then
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ]; then
    export SPADMIC_OA_ASSEMBLY_AUDIT_ROOT="$RAW_ROOT"
    export SPADMIC_OA_TOP_LIBRARY=SPADMIC
    export SPADMIC_OA_TOP_CELL=SPADMIC2
    export SPADMIC_OA_TOP_VIEW=layout
    export SPADMIC_OA_TOP_PATH="$TOP_OA_PATH"
    export SPADMIC_OA_MATRIX_LIBRARY=TOPLEVEL
    export SPADMIC_OA_MATRIX_CELL=matrice5
    export SPADMIC_OA_MATRIX_VIEW=layout
    export SPADMIC_OA_MATRIX_PATH="$MATRIX_OA_PATH"

    (
        cd "$CADENCE_LAUNCH_DIR"
        CADENCE_CD_RC=$?
        if [ "$CADENCE_CD_RC" = "0" ]; then
            "$VIRTUOSO_BIN" -nograph \
                -cdslib "$SESSION_CDS_LIB" \
                -restore "$REPO/TOP/pnr/scripts/audit_spadmic2_assembly_contract.il" \
                -log "$DIAGNOSTIC_ROOT/virtuoso_assembly_audit.log" \
                </dev/null
        else
            false
        fi
    )
    VIRTUOSO_RC=$?

    OA_EXPORT_GATE_RC=0
    for REQUIRED_EXPORT in \
        "$RAW_ROOT/virtuoso_export_status.rpt" \
        "$RAW_ROOT/source_identity.tsv" \
        "$RAW_ROOT/spadmic2_instances.tsv" \
        "$RAW_ROOT/spadmic2_instance_pins.tsv" \
        "$RAW_ROOT/spadmic2_top_shapes.tsv" \
        "$RAW_ROOT/matrice5_top_terminals.tsv"
    do
        if [ ! -s "$REQUIRED_EXPORT" ]; then
            echo "MISSING_OA_AUDIT_EXPORT=$REQUIRED_EXPORT"
            OA_EXPORT_GATE_RC=1
        fi
    done
    grep -Fxq 'STATUS=PASS' "$RAW_ROOT/virtuoso_export_status.rpt" 2>/dev/null
    if [ "$?" != "0" ]; then
        echo "OA_AUDIT_EXPORT_STATUS_NOT_PASS=$RAW_ROOT/virtuoso_export_status.rpt"
        OA_EXPORT_GATE_RC=1
    fi
    if [ "$VIRTUOSO_RC" != "0" ] || [ "$OA_EXPORT_GATE_RC" != "0" ]; then
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ]; then
    python3 "$REPO/TOP/pnr/scripts/process_spadmic2_assembly_audit.py" \
        --audit-root "$RAW_ROOT" \
        --out "$PROCESSED_ROOT" \
        --contract "$REPO/TOP/pnr/assembly/spadmic_digital_assembly_contract.json" \
        --unknown-family-policy "$REPO/TOP/pnr/assembly/matrice5_unknown_family_policy.csv"
    PROCESS_RC=$?
    if [ "$PROCESS_RC" != "0" ]; then
        RUN_OK=0
    fi
fi

if [ -d "$DIAGNOSTIC_ROOT" ]; then
    inventory_tree "$TOP_OA_PATH" "$DIAGNOSTIC_ROOT/spadmic2_source.post.sha256"
    TOP_POST_RC=$?
    inventory_tree "$MATRIX_OA_PATH" "$DIAGNOSTIC_ROOT/matrice5_source.post.sha256"
    MATRIX_POST_RC=$?
    diff -u \
        "$DIAGNOSTIC_ROOT/spadmic2_source.pre.sha256" \
        "$DIAGNOSTIC_ROOT/spadmic2_source.post.sha256" \
        > "$DIAGNOSTIC_ROOT/spadmic2_source_delta.rpt"
    TOP_STABLE_RC=$?
    diff -u \
        "$DIAGNOSTIC_ROOT/matrice5_source.pre.sha256" \
        "$DIAGNOSTIC_ROOT/matrice5_source.post.sha256" \
        > "$DIAGNOSTIC_ROOT/matrice5_source_delta.rpt"
    MATRIX_STABLE_RC=$?
    if [ "$TOP_POST_RC" = "0" ] && [ "$MATRIX_POST_RC" = "0" ] && \
       [ "$TOP_STABLE_RC" = "0" ] && [ "$MATRIX_STABLE_RC" = "0" ]; then
        SOURCE_STABILITY_RC=0
    else
        SOURCE_STABILITY_RC=1
        RUN_OK=0
    fi

    {
        echo "LABEL=SPADMIC2_MATRICE5_SOURCE_STABILITY"
        echo "STATUS=$([ "$SOURCE_STABILITY_RC" = "0" ] && echo PASS || echo FAIL)"
        echo "SOURCE_MUTATION_AUTHORIZED=NO"
        echo "SOURCE_INVENTORY_POLICY=CANONICAL_OA_CONTENT_V1"
        echo "SOURCE_INVENTORY_POLICY_REPORT=$DIAGNOSTIC_ROOT/source_inventory_policy.rpt"
        echo "SPADMIC2_PRE_POST_IDENTITY_RC=$TOP_STABLE_RC"
        echo "MATRICE5_PRE_POST_IDENTITY_RC=$MATRIX_STABLE_RC"
        echo "SPADMIC2_SOURCE_DELTA_REPORT=$DIAGNOSTIC_ROOT/spadmic2_source_delta.rpt"
        echo "MATRICE5_SOURCE_DELTA_REPORT=$DIAGNOSTIC_ROOT/matrice5_source_delta.rpt"
    } > "$DIAGNOSTIC_ROOT/source_stability_status.rpt"

    (
        cd "$DIAGNOSTIC_ROOT"
        MANIFEST_CD_RC=$?
        if [ "$MANIFEST_CD_RC" = "0" ]; then
            find . -type f ! -name SHA256SUMS -print0 |
                sort -z |
                xargs -0 -r sha256sum > SHA256SUMS
        else
            false
        fi
    )
    MANIFEST_RC=$?
fi

echo "CD_RC=$CD_RC"
echo "CHECKOUT_RC=$CHECKOUT_RC"
echo "PULL_RC=$PULL_RC"
echo "ENTRY_HEAD=$ENTRY_HEAD"
echo "EXPECTED_HEAD=$EXPECTED_HEAD"
echo "ACTUAL_HEAD=$ACTUAL_HEAD"
echo "SPADMIC_AUDIT_REEXECUTED=$REEXECUTED"
echo "REEXEC_EXEC_RC=$REEXEC_EXEC_RC"
echo "SOURCE_FILE_GATE_RC=$SOURCE_FILE_GATE_RC"
echo "CADENCE_LAUNCH_DIR=$CADENCE_LAUNCH_DIR"
echo "CADENCE_CDS_LIB=$CADENCE_CDS_LIB"
echo "CADENCE_LAUNCH_GATE_RC=$CADENCE_LAUNCH_GATE_RC"
echo "DIAGNOSTIC_CREATE_RC=$DIAGNOSTIC_CREATE_RC"
echo "SESSION_CDS_LIB=$SESSION_CDS_LIB"
echo "SESSION_CDS_LIB_CREATE_RC=$SESSION_CDS_LIB_CREATE_RC"
echo "VIRTUOSO_RC=$VIRTUOSO_RC"
echo "OA_EXPORT_GATE_RC=$OA_EXPORT_GATE_RC"
echo "PROCESS_RC=$PROCESS_RC"
echo "SOURCE_STABILITY_RC=$SOURCE_STABILITY_RC"
echo "MANIFEST_RC=$MANIFEST_RC"
echo "DIAGNOSTIC_ROOT=$DIAGNOSTIC_ROOT"

if [ "$RUN_OK" = "1" ] && [ "$MANIFEST_RC" = "0" ]; then
    echo "SPADMIC2_MATRICE5_ASSEMBLY_AUDIT_TRANSACTION_STATUS=PASS"
    echo "RETURN_OUTPUT_FOR_P00_IMPLEMENTATION_REVIEW"
    true
else
    echo "SPADMIC2_MATRICE5_ASSEMBLY_AUDIT_TRANSACTION_STATUS=FAIL"
    echo "STOP_HERE_DO_NOT_START_GENUS_OR_EDIT_OA"
    false
fi
