#!/usr/bin/env bash

###############################################################################
# Processor-only replay of one sealed SPADMIC2/matrice5 OA evidence payload.
# Usage:
#   bash TOP/ci/server_replay_spadmic2_mettp_context.sh \
#     <expected-head> <sealed-audit-root> <expected-archive-sha256>
###############################################################################

set +e

REPO="${SPADMIC_REPO:-/home/validmgr/ksabra/2026_SPAD/SPADMIC}"
EXPECTED_HEAD="${1:-MISSING}"
SOURCE_ROOT="${2:-MISSING}"
SOURCE_ROOT="${SOURCE_ROOT%/}"
EXPECTED_ARCHIVE_SHA256="${3:-MISSING}"
RAW_ROOT="$SOURCE_ROOT/raw_oa_export"
SOURCE_CONTRACT_REPORT="$SOURCE_ROOT/processed_contract/assembly_audit_status.rpt"
PROCESSOR="$REPO/TOP/pnr/scripts/process_spadmic2_assembly_audit.py"
CONTRACT="$REPO/TOP/pnr/assembly/spadmic_digital_assembly_contract.json"
POLICY="$REPO/TOP/pnr/assembly/matrice5_unknown_family_policy.csv"
REPLAY_PARENT="${SOURCE_ROOT%/*}"
RUN_ID="$(date +%Y%m%d_%H%M%S)_pid$$"
REPLAY_ROOT="$REPLAY_PARENT/spadmic2_matrice5_mettp_context_replay_$RUN_ID"
STATUS_REPORT="$REPLAY_ROOT/assembly_audit_status.rpt"

CD_RC=1
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
SHA256SUM_BIN=UNKNOWN
TAR_BIN=UNKNOWN
CHMOD_BIN=UNKNOWN
SCRIPT_SHA256=UNKNOWN
PROCESSOR_SHA256=UNKNOWN
CONTRACT_SHA256=UNKNOWN
POLICY_SHA256=UNKNOWN
ACTIVE_PROCESSOR=UNKNOWN
SOURCE_FILE_GATE_RC=1
SOURCE_SEAL_STATUS_RC=1
SOURCE_STABILITY_STATUS_RC=1
SOURCE_ROLE_EXPORT_STATUS_RC=1
SOURCE_CONTRACT_STATUS_RC=1
SOURCE_MANIFEST_PRE_RC=NOT_RUN
RAW_MANIFEST_PRE_RC=NOT_RUN
ARCHIVE_DETACHED_HASH_RC=NOT_RUN
ARCHIVE_EXPECTED_HASH_RC=NOT_RUN
ARCHIVE_TAR_RC=NOT_RUN
SOURCE_READ_ONLY_RC=1
PREFLIGHT_RC=1
REPLAY_MKDIR_RC=NOT_RUN
PROCESS_RC=NOT_RUN
REPLAY_MANIFEST_PRE_SEAL_RC=NOT_RUN
STATUS_GATE_RC=1
REPLAY_SEAL_RC=NOT_RUN
REPLAY_READ_ONLY_RC=1
REPLAY_MANIFEST_POST_SEAL_RC=NOT_RUN
SOURCE_MANIFEST_POST_RC=NOT_RUN
RAW_MANIFEST_POST_RC=NOT_RUN
SOURCE_READ_ONLY_POST_RC=1
REPLAY_STATUS=FAIL

verify_manifest() {
    local root="$1"
    local manifest="$2"
    if [ ! -d "$root" ] || [ ! -r "$manifest" ]; then
        return 1
    fi
    (
        cd "$root"
        VERIFY_CD_RC=$?
        if [ "$VERIFY_CD_RC" = "0" ]; then
            "$SHA256SUM_BIN" -c "$(basename "$manifest")"
        else
            false
        fi
    )
}

require_status_lines() {
    local report="$1"
    shift
    if [ ! -r "$report" ]; then
        return 1
    fi
    local expected
    for expected in "$@"; do
        if ! grep -Fxq "$expected" "$report"; then
            echo "MISSING_STATUS_LINE=$expected"
            return 1
        fi
    done
    return 0
}

if [ -d "$REPO/.git" ]; then
    cd "$REPO"
    CD_RC=$?
else
    echo "MISSING_REPOSITORY=$REPO"
fi

if [ "$CD_RC" = "0" ]; then
    ACTUAL_HEAD="$(git rev-parse HEAD 2>/dev/null)"
    git diff --quiet
    TRACKED_DIFF_RC=$?
    git diff --cached --quiet
    STAGED_DIFF_RC=$?
    SHA256SUM_BIN="$(type -P sha256sum 2>/dev/null)"
    TAR_BIN="$(type -P tar 2>/dev/null)"
    CHMOD_BIN="$(type -P chmod 2>/dev/null)"
    if [ -n "$SHA256SUM_BIN" ] && [ -x "$SHA256SUM_BIN" ]; then
        SCRIPT_SHA256="$(
            "$SHA256SUM_BIN" \
                "$REPO/TOP/ci/server_replay_spadmic2_mettp_context.sh" |
                awk '{print $1}'
        )"
        PROCESSOR_SHA256="$(
            "$SHA256SUM_BIN" "$PROCESSOR" |
                awk '{print $1}'
        )"
        CONTRACT_SHA256="$(
            "$SHA256SUM_BIN" "$CONTRACT" |
                awk '{print $1}'
        )"
        POLICY_SHA256="$(
            "$SHA256SUM_BIN" "$POLICY" |
                awk '{print $1}'
        )"
    fi
    ACTIVE_PROCESSOR="$(
        pgrep -af '[p]rocess_spadmic2_assembly_audit\.py' 2>/dev/null
    )"
    git status --short --branch --untracked-files=no
fi

SOURCE_FILE_GATE_RC=0
for REQUIRED in \
    "$SOURCE_ROOT/SHA256SUMS" \
    "$SOURCE_ROOT/evidence_seal_status.rpt" \
    "$SOURCE_ROOT/evidence_payload.tar.gz" \
    "$SOURCE_ROOT/evidence_payload.tar.gz.sha256" \
    "$SOURCE_ROOT/source_stability_status.rpt" \
    "$SOURCE_CONTRACT_REPORT" \
    "$RAW_ROOT/SHA256SUMS" \
    "$RAW_ROOT/matrice5_virtuoso_export_status.rpt" \
    "$RAW_ROOT/spadmic2_virtuoso_export_status.rpt" \
    "$RAW_ROOT/source_identity.tsv" \
    "$RAW_ROOT/spadmic2_instances.tsv" \
    "$RAW_ROOT/spadmic2_instance_pins.tsv" \
    "$RAW_ROOT/spadmic2_top_shapes.tsv" \
    "$RAW_ROOT/matrice5_top_terminals.tsv" \
    "$PROCESSOR" \
    "$CONTRACT" \
    "$POLICY"
do
    if [ ! -r "$REQUIRED" ]; then
        echo "MISSING_REQUIRED_FILE=$REQUIRED"
        SOURCE_FILE_GATE_RC=1
    fi
done

require_status_lines "$SOURCE_ROOT/evidence_seal_status.rpt" \
    'STATUS=PASS' \
    'RAW_AND_PROCESSED_MUTATION_AUTHORIZED=NO' \
    'EVIDENCE_ROOT_REUSE_AUTHORIZED=NO'
SOURCE_SEAL_STATUS_RC=$?
require_status_lines "$SOURCE_ROOT/source_stability_status.rpt" \
    'STATUS=PASS' \
    'SOURCE_MUTATION_AUTHORIZED=NO' \
    'SPADMIC2_PRE_POST_IDENTITY_RC=0' \
    'MATRICE5_PRE_POST_IDENTITY_RC=0'
SOURCE_STABILITY_STATUS_RC=$?
MATRICE5_ROLE_STATUS_RC=1
SPADMIC2_ROLE_STATUS_RC=1
require_status_lines "$RAW_ROOT/matrice5_virtuoso_export_status.rpt" \
    'ROLE=matrice5' \
    'STATUS=PASS'
MATRICE5_ROLE_STATUS_RC=$?
require_status_lines "$RAW_ROOT/spadmic2_virtuoso_export_status.rpt" \
    'ROLE=spadmic2' \
    'STATUS=PASS'
SPADMIC2_ROLE_STATUS_RC=$?
if [ "$MATRICE5_ROLE_STATUS_RC" = "0" ] && \
   [ "$SPADMIC2_ROLE_STATUS_RC" = "0" ]; then
    SOURCE_ROLE_EXPORT_STATUS_RC=0
fi
require_status_lines "$SOURCE_CONTRACT_REPORT" \
    'STATUS=FAIL' \
    'P03_INTERFACE_CONTRACT_STATUS=PASS' \
    'PG_ANCHOR_GATE_STATUS=FAIL' \
    'P00_P02_IMPLEMENTATION_AUTHORIZED=NO' \
    'P03_IMPLEMENTATION_AUTHORIZED=NO'
SOURCE_CONTRACT_STATUS_RC=$?

if [ "$SOURCE_FILE_GATE_RC" = "0" ] && \
   [ -n "$SHA256SUM_BIN" ] && \
   [ -x "$SHA256SUM_BIN" ]; then
    verify_manifest "$SOURCE_ROOT" "$SOURCE_ROOT/SHA256SUMS" >/dev/null
    SOURCE_MANIFEST_PRE_RC=$?
    verify_manifest "$RAW_ROOT" "$RAW_ROOT/SHA256SUMS" >/dev/null
    RAW_MANIFEST_PRE_RC=$?
    (
        cd "$SOURCE_ROOT"
        ARCHIVE_CD_RC=$?
        if [ "$ARCHIVE_CD_RC" = "0" ]; then
            "$SHA256SUM_BIN" -c evidence_payload.tar.gz.sha256
        else
            false
        fi
    ) >/dev/null
    ARCHIVE_DETACHED_HASH_RC=$?
    ACTUAL_ARCHIVE_SHA256="$(
        "$SHA256SUM_BIN" "$SOURCE_ROOT/evidence_payload.tar.gz" |
            awk '{print $1}'
    )"
    if [ "$ACTUAL_ARCHIVE_SHA256" = "$EXPECTED_ARCHIVE_SHA256" ]; then
        ARCHIVE_EXPECTED_HASH_RC=0
    else
        ARCHIVE_EXPECTED_HASH_RC=1
    fi
else
    SOURCE_MANIFEST_PRE_RC=1
    RAW_MANIFEST_PRE_RC=1
    ARCHIVE_DETACHED_HASH_RC=1
    ARCHIVE_EXPECTED_HASH_RC=1
    ACTUAL_ARCHIVE_SHA256=UNKNOWN
fi

if [ -n "$TAR_BIN" ] && \
   [ -x "$TAR_BIN" ] && \
   [ -r "$SOURCE_ROOT/evidence_payload.tar.gz" ]; then
    "$TAR_BIN" -tzf "$SOURCE_ROOT/evidence_payload.tar.gz" >/dev/null
    ARCHIVE_TAR_RC=$?
else
    ARCHIVE_TAR_RC=1
fi

SOURCE_WRITABLE_PATH="$(
    find "$SOURCE_ROOT" -perm /222 -print -quit 2>/dev/null
)"
SOURCE_READ_ONLY_FIND_RC=$?
if [ "$SOURCE_READ_ONLY_FIND_RC" = "0" ] && \
   [ -z "$SOURCE_WRITABLE_PATH" ]; then
    SOURCE_READ_ONLY_RC=0
fi

if [ "$CD_RC" = "0" ] && \
   [ "$ACTUAL_HEAD" = "$EXPECTED_HEAD" ] && \
   [ "$TRACKED_DIFF_RC" = "0" ] && \
   [ "$STAGED_DIFF_RC" = "0" ] && \
   [ "$SOURCE_FILE_GATE_RC" = "0" ] && \
   [ "$SOURCE_SEAL_STATUS_RC" = "0" ] && \
   [ "$SOURCE_STABILITY_STATUS_RC" = "0" ] && \
   [ "$SOURCE_ROLE_EXPORT_STATUS_RC" = "0" ] && \
   [ "$SOURCE_CONTRACT_STATUS_RC" = "0" ] && \
   [ "$SOURCE_MANIFEST_PRE_RC" = "0" ] && \
   [ "$RAW_MANIFEST_PRE_RC" = "0" ] && \
   [ "$ARCHIVE_DETACHED_HASH_RC" = "0" ] && \
   [ "$ARCHIVE_EXPECTED_HASH_RC" = "0" ] && \
   [ "$ARCHIVE_TAR_RC" = "0" ] && \
   [ "$SOURCE_READ_ONLY_RC" = "0" ] && \
   [ -n "$CHMOD_BIN" ] && \
   [ -x "$CHMOD_BIN" ] && \
   [ -z "$ACTIVE_PROCESSOR" ]; then
    PREFLIGHT_RC=0
fi

echo
echo "EXPECTED_HEAD=$EXPECTED_HEAD"
echo "ACTUAL_HEAD=$ACTUAL_HEAD"
echo "TRACKED_DIFF_RC=$TRACKED_DIFF_RC"
echo "STAGED_DIFF_RC=$STAGED_DIFF_RC"
echo "SCRIPT_SHA256=$SCRIPT_SHA256"
echo "PROCESSOR_SHA256=$PROCESSOR_SHA256"
echo "CONTRACT_SHA256=$CONTRACT_SHA256"
echo "POLICY_SHA256=$POLICY_SHA256"
echo "ACTIVE_PROCESSOR=${ACTIVE_PROCESSOR:-NONE}"
echo "SOURCE_ROOT=$SOURCE_ROOT"
echo "SOURCE_SEAL_STATUS_RC=$SOURCE_SEAL_STATUS_RC"
echo "SOURCE_STABILITY_STATUS_RC=$SOURCE_STABILITY_STATUS_RC"
echo "SOURCE_ROLE_EXPORT_STATUS_RC=$SOURCE_ROLE_EXPORT_STATUS_RC"
echo "SOURCE_CONTRACT_STATUS_RC=$SOURCE_CONTRACT_STATUS_RC"
echo "SOURCE_MANIFEST_PRE_RC=$SOURCE_MANIFEST_PRE_RC"
echo "RAW_MANIFEST_PRE_RC=$RAW_MANIFEST_PRE_RC"
echo "EXPECTED_ARCHIVE_SHA256=$EXPECTED_ARCHIVE_SHA256"
echo "ACTUAL_ARCHIVE_SHA256=$ACTUAL_ARCHIVE_SHA256"
echo "ARCHIVE_DETACHED_HASH_RC=$ARCHIVE_DETACHED_HASH_RC"
echo "ARCHIVE_EXPECTED_HASH_RC=$ARCHIVE_EXPECTED_HASH_RC"
echo "ARCHIVE_TAR_RC=$ARCHIVE_TAR_RC"
echo "SOURCE_WRITABLE_PATH=${SOURCE_WRITABLE_PATH:-NONE}"
echo "PREFLIGHT_RC=$PREFLIGHT_RC"

if [ "$PREFLIGHT_RC" = "0" ]; then
    mkdir "$REPLAY_ROOT"
    REPLAY_MKDIR_RC=$?
    if [ "$REPLAY_MKDIR_RC" = "0" ]; then
        python3 "$PROCESSOR" \
            --audit-root "$RAW_ROOT" \
            --out "$REPLAY_ROOT" \
            --contract "$CONTRACT" \
            --unknown-family-policy "$POLICY"
        PROCESS_RC=$?
    fi
else
    echo "STOP_HERE_PROCESSOR_REPLAY_NOT_RUN=PREFLIGHT_FAILED"
fi

if [ "$PROCESS_RC" = "2" ] && \
   [ -r "$REPLAY_ROOT/SHA256SUMS" ]; then
    verify_manifest "$REPLAY_ROOT" "$REPLAY_ROOT/SHA256SUMS" >/dev/null
    REPLAY_MANIFEST_PRE_SEAL_RC=$?
else
    REPLAY_MANIFEST_PRE_SEAL_RC=1
fi

require_status_lines "$STATUS_REPORT" \
    'STATUS=FAIL' \
    'RESULT=AUDIT_CONTRACT_REJECTED' \
    'SOURCE_IDENTITY_GATE_STATUS=PASS' \
    'EXACT_MATRICE5_INSTANCE_GATE_STATUS=PASS' \
    'MATRIX_TERMINAL_PARITY_STATUS=PASS' \
    'UNKNOWN_FAMILY_GATE_STATUS=PASS' \
    'MATRIX_PROXY_PIN_ACCESS_STATUS=PASS' \
    'P03_INTERFACE_CONTRACT_STATUS=PASS' \
    'PG_ANCHOR_GATE_STATUS=FAIL' \
    'METTP_TOP_SHAPE_COUNT=3' \
    'UNATTRIBUTED_METTP_SHAPE_COUNT=3' \
    'DIRECT_METTP_ATTRIBUTION_STATUS=FAIL' \
    'METTP_CONTEXT_REPORT_STATUS=PASS' \
    'METTP_CONTEXT_AUTHORIZATION=REVIEW_ONLY_NOT_A_PG_ANCHOR' \
    'P00_P02_CONTRACT_STATUS=FAIL' \
    'P00_P02_IMPLEMENTATION_AUTHORIZED=NO' \
    'P03_IMPLEMENTATION_AUTHORIZED=NO' \
    'NEXT_GATE=STOP_AND_RECONCILE_PG_ANCHORS'
STATUS_GATE_RC=$?

if [ "$REPLAY_MANIFEST_PRE_SEAL_RC" = "0" ] && \
   [ "$STATUS_GATE_RC" = "0" ] && \
   [ -s "$REPLAY_ROOT/mettp_anchor_context_summary.tsv" ] && \
   [ -s "$REPLAY_ROOT/mettp_netted_shape_context.tsv" ]; then
    "$CHMOD_BIN" -R a-w "$REPLAY_ROOT"
    REPLAY_SEAL_RC=$?
else
    REPLAY_SEAL_RC=1
fi

REPLAY_WRITABLE_PATH="$(
    find "$REPLAY_ROOT" -perm /222 -print -quit 2>/dev/null
)"
REPLAY_READ_ONLY_FIND_RC=$?
if [ "$REPLAY_READ_ONLY_FIND_RC" = "0" ] && \
   [ -z "$REPLAY_WRITABLE_PATH" ]; then
    REPLAY_READ_ONLY_RC=0
fi

if [ "$REPLAY_SEAL_RC" = "0" ]; then
    verify_manifest "$REPLAY_ROOT" "$REPLAY_ROOT/SHA256SUMS" >/dev/null
    REPLAY_MANIFEST_POST_SEAL_RC=$?
else
    REPLAY_MANIFEST_POST_SEAL_RC=1
fi

verify_manifest "$SOURCE_ROOT" "$SOURCE_ROOT/SHA256SUMS" >/dev/null
SOURCE_MANIFEST_POST_RC=$?
verify_manifest "$RAW_ROOT" "$RAW_ROOT/SHA256SUMS" >/dev/null
RAW_MANIFEST_POST_RC=$?
SOURCE_WRITABLE_PATH_POST="$(
    find "$SOURCE_ROOT" -perm /222 -print -quit 2>/dev/null
)"
SOURCE_READ_ONLY_POST_FIND_RC=$?
if [ "$SOURCE_READ_ONLY_POST_FIND_RC" = "0" ] && \
   [ -z "$SOURCE_WRITABLE_PATH_POST" ]; then
    SOURCE_READ_ONLY_POST_RC=0
fi

echo
echo "REPLAY_ROOT=$REPLAY_ROOT"
echo "REPLAY_MKDIR_RC=$REPLAY_MKDIR_RC"
echo "PROCESS_RC=$PROCESS_RC"
echo "REPLAY_MANIFEST_PRE_SEAL_RC=$REPLAY_MANIFEST_PRE_SEAL_RC"
echo "STATUS_GATE_RC=$STATUS_GATE_RC"
echo "REPLAY_SEAL_RC=$REPLAY_SEAL_RC"
echo "REPLAY_WRITABLE_PATH=${REPLAY_WRITABLE_PATH:-NONE}"
echo "REPLAY_MANIFEST_POST_SEAL_RC=$REPLAY_MANIFEST_POST_SEAL_RC"
echo "SOURCE_MANIFEST_POST_RC=$SOURCE_MANIFEST_POST_RC"
echo "RAW_MANIFEST_POST_RC=$RAW_MANIFEST_POST_RC"
echo "SOURCE_WRITABLE_PATH_POST=${SOURCE_WRITABLE_PATH_POST:-NONE}"

for REPORT in \
    "$STATUS_REPORT" \
    "$REPLAY_ROOT/mettp_top_shape_attribution.tsv" \
    "$REPLAY_ROOT/mettp_overlap_candidates.tsv" \
    "$REPLAY_ROOT/mettp_anchor_context_summary.tsv"
do
    echo
    echo "===== $REPORT ====="
    if [ -r "$REPORT" ]; then
        cat "$REPORT"
    else
        echo "MISSING=$REPORT"
    fi
done

echo
echo "===== METTP CONTACT CANDIDATES ====="
if [ -r "$REPLAY_ROOT/mettp_netted_shape_context.tsv" ]; then
    awk -F $'\t' \
        'NR == 1 || $22 != "SEPARATED"' \
        "$REPLAY_ROOT/mettp_netted_shape_context.tsv"
else
    echo "MISSING=$REPLAY_ROOT/mettp_netted_shape_context.tsv"
fi

echo
echo "===== FIVE NEAREST CANDIDATES PER SCOPE ====="
if [ -r "$REPLAY_ROOT/mettp_netted_shape_context.tsv" ]; then
    awk -F $'\t' \
        'NR == 1 || ($3 + 0) <= 5' \
        "$REPLAY_ROOT/mettp_netted_shape_context.tsv"
else
    echo "MISSING=$REPLAY_ROOT/mettp_netted_shape_context.tsv"
fi

if [ "$PREFLIGHT_RC" = "0" ] && \
   [ "$PROCESS_RC" = "2" ] && \
   [ "$REPLAY_MANIFEST_PRE_SEAL_RC" = "0" ] && \
   [ "$STATUS_GATE_RC" = "0" ] && \
   [ "$REPLAY_SEAL_RC" = "0" ] && \
   [ "$REPLAY_READ_ONLY_RC" = "0" ] && \
   [ "$REPLAY_MANIFEST_POST_SEAL_RC" = "0" ] && \
   [ "$SOURCE_MANIFEST_POST_RC" = "0" ] && \
   [ "$RAW_MANIFEST_POST_RC" = "0" ] && \
   [ "$SOURCE_READ_ONLY_POST_RC" = "0" ]; then
    REPLAY_STATUS=PASS_EVIDENCE_READY
fi

echo
echo "PROCESSOR_ONLY_METTP_CONTEXT_STATUS=$REPLAY_STATUS"
if [ "$REPLAY_STATUS" = "PASS_EVIDENCE_READY" ]; then
    echo "NEXT_GATE=RETURN_OUTPUT_FOR_PG_CONTEXT_CLASSIFICATION"
    echo "DO_NOT_START_CADENCE_GENUS_OR_EDIT_OA"
    true
else
    echo "STOP_HERE_DO_NOT_START_CADENCE_GENUS_OR_EDIT_OA"
    false
fi
