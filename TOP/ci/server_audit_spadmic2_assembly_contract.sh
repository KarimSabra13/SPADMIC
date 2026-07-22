#!/usr/bin/env bash

###############################################################################
# Immutable, read-only SPADMIC2/matrice5 assembly audit.
# Usage: bash TOP/ci/server_audit_spadmic2_assembly_contract.sh <expected-head>
###############################################################################

set +e

REPO="${SPADMIC_REPO:-/home/validmgr/ksabra/2026_SPAD/SPADMIC}"
EXPECTED_HEAD="${1:-MISSING}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
TOP_OA_PATH=/group/validmgr/PROJET/Prj_xh018/ksabra/cds/design/SPADMIC2/layout
MATRIX_OA_PATH=/group/validmgr/PROJET/Prj_xh018/spadmic/TOPLEVEL/matrice5
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
DIAGNOSTIC_ROOT="$WORK_ROOT/diagnostics/spadmic2_matrice5_assembly_audit_$TIMESTAMP"
RAW_ROOT="$DIAGNOSTIC_ROOT/raw_oa_export"
PROCESSED_ROOT="$DIAGNOSTIC_ROOT/processed_contract"

RUN_OK=1
CD_RC=NOT_RUN
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
SOURCE_FILE_GATE_RC=NOT_RUN
VIRTUOSO_RC=NOT_RUN
PROCESS_RC=NOT_RUN
SOURCE_STABILITY_RC=NOT_RUN
MANIFEST_RC=NOT_RUN

inventory_tree() {
    local source_root="$1"
    local output_file="$2"
    if [ ! -d "$source_root" ]; then
        return 1
    fi
    find "$source_root" -type f -print0 2>/dev/null |
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

SOURCE_FILE_GATE_RC=0
for REQUIRED in \
    "$TOP_OA_PATH" \
    "$MATRIX_OA_PATH" \
    TOP/pnr/scripts/audit_spadmic2_assembly_contract.il \
    TOP/pnr/scripts/process_spadmic2_assembly_audit.py \
    TOP/pnr/assembly/spadmic_digital_assembly_contract.json \
    TOP/pnr/assembly/matrice5_unknown_family_policy.csv
do
    if [ ! -e "$REQUIRED" ]; then
        echo "MISSING_REQUIRED_SOURCE=$REQUIRED"
        SOURCE_FILE_GATE_RC=1
    fi
done
if [ "$SOURCE_FILE_GATE_RC" != "0" ]; then
    RUN_OK=0
fi

if [ "$RUN_OK" = "1" ]; then
    mkdir -p "$RAW_ROOT" "$PROCESSED_ROOT"
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

    virtuoso -nograph \
        -restore TOP/pnr/scripts/audit_spadmic2_assembly_contract.il \
        -log "$DIAGNOSTIC_ROOT/virtuoso_assembly_audit.log"
    VIRTUOSO_RC=$?
    if [ "$VIRTUOSO_RC" != "0" ]; then
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ]; then
    python3 TOP/pnr/scripts/process_spadmic2_assembly_audit.py \
        --audit-root "$RAW_ROOT" \
        --out "$PROCESSED_ROOT"
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
    cmp -s "$DIAGNOSTIC_ROOT/spadmic2_source.pre.sha256" "$DIAGNOSTIC_ROOT/spadmic2_source.post.sha256"
    TOP_STABLE_RC=$?
    cmp -s "$DIAGNOSTIC_ROOT/matrice5_source.pre.sha256" "$DIAGNOSTIC_ROOT/matrice5_source.post.sha256"
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
        echo "SPADMIC2_PRE_POST_IDENTITY_RC=$TOP_STABLE_RC"
        echo "MATRICE5_PRE_POST_IDENTITY_RC=$MATRIX_STABLE_RC"
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
echo "EXPECTED_HEAD=$EXPECTED_HEAD"
echo "ACTUAL_HEAD=$ACTUAL_HEAD"
echo "SOURCE_FILE_GATE_RC=$SOURCE_FILE_GATE_RC"
echo "VIRTUOSO_RC=$VIRTUOSO_RC"
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
