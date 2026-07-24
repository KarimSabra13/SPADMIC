#!/usr/bin/env bash

###############################################################################
# One foreground, read-only hierarchical METTP corridor probe for selected I6.
# Usage:
#   bash TOP/ci/server_probe_spadmic2_selected_pg_corridor.sh \
#     <expected-head> \
#     <sealed-assembly-audit-root> <expected-assembly-archive-sha256> \
#     <sealed-pg-probe-root> <expected-pg-archive-sha256> \
#     <sealed-floorplan-replay-root>
###############################################################################

set +e

REPO="${SPADMIC_REPO:-/home/validmgr/ksabra/2026_SPAD/SPADMIC}"
EXPECTED_HEAD="${1:-MISSING}"
SOURCE_ROOT="${2:-MISSING}"
SOURCE_ROOT="${SOURCE_ROOT%/}"
EXPECTED_SOURCE_ARCHIVE_SHA256="${3:-MISSING}"
PG_ROOT="${4:-MISSING}"
PG_ROOT="${PG_ROOT%/}"
EXPECTED_PG_ARCHIVE_SHA256="${5:-MISSING}"
FLOORPLAN_ROOT="${6:-MISSING}"
FLOORPLAN_ROOT="${FLOORPLAN_ROOT%/}"

WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
CADENCE_LAUNCH_DIR="${SPADMIC_CADENCE_LAUNCH_DIR:-/group/validmgr/PROJET/Prj_xh018/ksabra/cds_V0}"
CADENCE_CDS_LIB="$CADENCE_LAUNCH_DIR/cds.lib"
TOP_OA_PATH=/group/validmgr/PROJET/Prj_xh018/ksabra/cds/design/SPADMIC2/layout
SOURCE_RAW="$SOURCE_ROOT/raw_oa_export"
SOURCE_STATUS="$SOURCE_ROOT/processed_contract/assembly_audit_status.rpt"
PG_RAW="$PG_ROOT/raw_oa_probe"
PG_PROCESSED="$PG_ROOT/processed_classification"
PG_EVIDENCE_STATUS="$PG_ROOT/pg_access_probe_evidence_status.rpt"
FLOORPLAN_STATUS="$FLOORPLAN_ROOT/digital_pg_access_status.rpt"
FLOORPLAN_PAIR="$FLOORPLAN_ROOT/digital_pg_review_pair.tsv"

WRAPPER="$REPO/TOP/ci/server_probe_spadmic2_selected_pg_corridor.sh"
CONTRACT="$REPO/TOP/pnr/assembly/spadmic_digital_assembly_contract.json"
PROBE_SKILL="$REPO/TOP/pnr/scripts/probe_spadmic2_selected_pg_corridor.il"
CLASSIFIER="$REPO/TOP/pnr/scripts/classify_spadmic2_selected_pg_corridor.py"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RUN_ID="${TIMESTAMP}_pid$$"
DIAGNOSTIC_PARENT="$WORK_ROOT/diagnostics"
DIAGNOSTIC_ROOT="$DIAGNOSTIC_PARENT/spadmic2_i6_mettp_corridor_probe_$RUN_ID"
RAW_ROOT="$DIAGNOSTIC_ROOT/raw_oa_corridor"
PROCESSED_ROOT="$DIAGNOSTIC_ROOT/processed_corridor"
SESSION_CDS_LIB="$DIAGNOSTIC_ROOT/spadmic2_session.cds.lib"
PROBE_LOG="$DIAGNOSTIC_ROOT/virtuoso_spadmic2_i6_corridor.log"
CHECKSUM_SELFTEST_ROOT="$DIAGNOSTIC_ROOT/checksum_selftest"
RECOVERY_ARCHIVE="$DIAGNOSTIC_ROOT/evidence_payload.tar.gz"
RECOVERY_ARCHIVE_SHA256_FILE="$RECOVERY_ARCHIVE.sha256"
RECOVERY_ARCHIVE_FILELIST="$DIAGNOSTIC_ROOT/evidence_payload_filelist.txt"
EVIDENCE_STATUS="$DIAGNOSTIC_ROOT/i6_corridor_probe_evidence_status.rpt"
EXPECTED_CHECKSUM_SELFTEST_SHA256=8f07d5176d42a4f11c17a591edc7e38026d0b4e4a31366b9e5a807b5e70cecd5
ACCEPTED_FLOORPLAN_PROCESSOR_SHA256=4e569eb6508d36494930d19a0e850f31c02b96a29d6b7718617491c61a9b2335
ACCEPTED_FLOORPLAN_CONTRACT_SHA256=1bbadead6b026e120ab060298cae19e26004e5820eaecc1214b48b4afe306599
REEXECUTED="${SPADMIC_CORRIDOR_PROBE_REEXECUTED:-0}"

RUN_OK=1
CD_RC=1
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ENTRY_HEAD=UNKNOWN
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
REEXEC_EXEC_RC=NOT_RUN
UPSTREAM_FILE_GATE_RC=1
SOURCE_STATUS_GATE_RC=1
PG_STATUS_GATE_RC=1
FLOORPLAN_STATUS_GATE_RC=1
SOURCE_MANIFEST_PRE_RC=NOT_RUN
SOURCE_RAW_MANIFEST_PRE_RC=NOT_RUN
PG_MANIFEST_PRE_RC=NOT_RUN
PG_RAW_MANIFEST_PRE_RC=NOT_RUN
PG_PROCESSED_MANIFEST_PRE_RC=NOT_RUN
FLOORPLAN_MANIFEST_PRE_RC=NOT_RUN
SOURCE_ARCHIVE_HASH_RC=NOT_RUN
SOURCE_ARCHIVE_EXPECTED_RC=NOT_RUN
SOURCE_ARCHIVE_TAR_RC=NOT_RUN
PG_ARCHIVE_HASH_RC=NOT_RUN
PG_ARCHIVE_EXPECTED_RC=NOT_RUN
PG_ARCHIVE_TAR_RC=NOT_RUN
ACTUAL_SOURCE_ARCHIVE_SHA256=UNKNOWN
ACTUAL_PG_ARCHIVE_SHA256=UNKNOWN
SOURCE_READ_ONLY_RC=1
PG_READ_ONLY_RC=1
FLOORPLAN_READ_ONLY_RC=1
TOOL_GATE_RC=1
ACTIVE_PROBE=UNKNOWN
DIAGNOSTIC_CREATE_RC=NOT_RUN
CHECKSUM_SELFTEST_RC=NOT_RUN
SESSION_CDS_LIB_CREATE_RC=NOT_RUN
SOURCE_INVENTORY_PRE_RC=NOT_RUN
VIRTUOSO_RC=NOT_RUN
RAW_EXPORT_GATE_RC=NOT_RUN
RAW_MANIFEST_CREATE_RC=NOT_RUN
RAW_MANIFEST_PRE_SEAL_RC=NOT_RUN
RAW_SEAL_RC=NOT_RUN
RAW_READ_ONLY_RC=1
CLASSIFIER_RC=NOT_RUN
CLASSIFICATION_GATE_RC=NOT_RUN
PROCESSED_MANIFEST_RC=NOT_RUN
PROCESSED_SEAL_RC=NOT_RUN
PROCESSED_READ_ONLY_RC=1
SOURCE_INVENTORY_POST_RC=NOT_RUN
SOURCE_STABILITY_RC=NOT_RUN
SOURCE_MANIFEST_POST_RC=NOT_RUN
SOURCE_RAW_MANIFEST_POST_RC=NOT_RUN
PG_MANIFEST_POST_RC=NOT_RUN
PG_RAW_MANIFEST_POST_RC=NOT_RUN
PG_PROCESSED_MANIFEST_POST_RC=NOT_RUN
FLOORPLAN_MANIFEST_POST_RC=NOT_RUN
UPSTREAM_READ_ONLY_POST_RC=1
RAW_MANIFEST_POST_ARCHIVE_RC=NOT_RUN
PROCESSED_MANIFEST_POST_ARCHIVE_RC=NOT_RUN
RECOVERY_ARCHIVE_FILELIST_RC=NOT_RUN
RECOVERY_ARCHIVE_CREATE_RC=NOT_RUN
RECOVERY_ARCHIVE_TAR_VERIFY_RC=NOT_RUN
RECOVERY_ARCHIVE_HASH_CREATE_RC=NOT_RUN
RECOVERY_ARCHIVE_HASH_VERIFY_RC=NOT_RUN
RECOVERY_ARCHIVE_SHA256=UNKNOWN
PRESEAL_GATE_RC=1
OUTER_MANIFEST_CREATE_RC=NOT_RUN
ROOT_SEAL_RC=NOT_RUN
ROOT_READ_ONLY_RC=1
OUTER_MANIFEST_POST_SEAL_RC=NOT_RUN
PROBE_STATUS=FAIL
SHA256SUM_BIN_SHA256=UNKNOWN
WRAPPER_SHA256=UNKNOWN
PROBE_SKILL_SHA256=UNKNOWN
CLASSIFIER_SHA256=UNKNOWN
CONTRACT_SHA256=UNKNOWN

SHA256SUM_BIN="$(type -P sha256sum 2>/dev/null)"
TAR_BIN="$(type -P tar 2>/dev/null)"
CHMOD_BIN="$(type -P chmod 2>/dev/null)"
VIRTUOSO_BIN="$(command -v virtuoso 2>/dev/null)"

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

create_manifest() {
    local root="$1"
    (
        cd "$root"
        MANIFEST_CD_RC=$?
        if [ "$MANIFEST_CD_RC" = "0" ]; then
            find . -type f ! -path './SHA256SUMS' -print0 |
                sort -z |
                xargs -0 -r "$SHA256SUM_BIN" > SHA256SUMS
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
    local rc=0
    for expected in "$@"; do
        grep -Fxq "$expected" "$report" 2>/dev/null
        if [ "$?" != "0" ]; then
            echo "MISSING_STATUS_LINE=$report|$expected"
            rc=1
        fi
    done
    return "$rc"
}

inventory_tree() {
    local source_root="$1"
    local output_file="$2"
    if [ ! -d "$source_root" ]; then
        return 1
    fi
    find "$source_root" \
        -type f \
        ! -name '.nfs*' \
        ! -name '*.cdslck' \
        ! -name '*.cdslck.*' \
        ! -name '*.oa.*.oacache' \
        -print0 2>/dev/null |
        sort -z |
        xargs -0 -r "$SHA256SUM_BIN" > "$output_file"
}

run_checksum_selftest() {
    local payload="$CHECKSUM_SELFTEST_ROOT/payload.txt"
    local verification="$CHECKSUM_SELFTEST_ROOT/verification.rpt"
    local status_report="$CHECKSUM_SELFTEST_ROOT/status.rpt"
    local observed_before=UNKNOWN
    local observed_after=UNKNOWN
    local size_before=UNKNOWN
    local size_after=UNKNOWN
    local manifest_create_rc=1
    local manifest_verify_rc=1
    local result=1

    mkdir -p "$CHECKSUM_SELFTEST_ROOT"
    SELFTEST_MKDIR_RC=$?
    if [ "$SELFTEST_MKDIR_RC" = "0" ]; then
        printf 'SPADMIC_SHA256_SELFTEST_V1\n' > "$payload"
        SELFTEST_PAYLOAD_CREATE_RC=$?
    else
        SELFTEST_PAYLOAD_CREATE_RC=1
    fi
    if [ "$SELFTEST_PAYLOAD_CREATE_RC" = "0" ]; then
        observed_before="$("$SHA256SUM_BIN" "$payload" 2>/dev/null | awk '{print $1}')"
        size_before="$(wc -c < "$payload" 2>/dev/null)"
        (
            cd "$CHECKSUM_SELFTEST_ROOT"
            SELFTEST_CD_RC=$?
            if [ "$SELFTEST_CD_RC" = "0" ]; then
                "$SHA256SUM_BIN" payload.txt > SHA256SUMS
            else
                false
            fi
        )
        manifest_create_rc=$?
        if [ "$manifest_create_rc" = "0" ]; then
            (
                cd "$CHECKSUM_SELFTEST_ROOT"
                SELFTEST_CD_RC=$?
                if [ "$SELFTEST_CD_RC" = "0" ]; then
                    "$SHA256SUM_BIN" -c SHA256SUMS
                else
                    false
                fi
            ) > "$verification" 2>&1
            manifest_verify_rc=$?
        fi
        observed_after="$("$SHA256SUM_BIN" "$payload" 2>/dev/null | awk '{print $1}')"
        size_after="$(wc -c < "$payload" 2>/dev/null)"
    fi
    if [ "$manifest_create_rc" = "0" ] && \
       [ "$manifest_verify_rc" = "0" ] && \
       [ "$observed_before" = "$EXPECTED_CHECKSUM_SELFTEST_SHA256" ] && \
       [ "$observed_after" = "$EXPECTED_CHECKSUM_SELFTEST_SHA256" ] && \
       [ "$size_before" = "27" ] && \
       [ "$size_after" = "27" ]; then
        result=0
    fi
    {
        echo "LABEL=SPADMIC_SHA256_EXECUTABLE_SELFTEST"
        echo "STATUS=$([ "$result" = "0" ] && echo PASS || echo FAIL)"
        echo "SHA256SUM_BIN=$SHA256SUM_BIN"
        echo "SHA256SUM_BIN_SHA256=$SHA256SUM_BIN_SHA256"
        echo "EXPECTED_PAYLOAD_SHA256=$EXPECTED_CHECKSUM_SELFTEST_SHA256"
        echo "OBSERVED_PAYLOAD_SHA256_BEFORE=$observed_before"
        echo "OBSERVED_PAYLOAD_SHA256_AFTER=$observed_after"
        echo "PAYLOAD_SIZE_BEFORE=$size_before"
        echo "PAYLOAD_SIZE_AFTER=$size_after"
        echo "MANIFEST_CREATE_RC=$manifest_create_rc"
        echo "MANIFEST_VERIFY_RC=$manifest_verify_rc"
        echo "PAYLOAD_MUTATION_AUTHORIZED=NO"
    } > "$status_report"
    return "$result"
}

if [ "$EXPECTED_HEAD" = "MISSING" ] || \
   [ "$SOURCE_ROOT" = "MISSING" ] || \
   [ "$EXPECTED_SOURCE_ARCHIVE_SHA256" = "MISSING" ] || \
   [ "$PG_ROOT" = "MISSING" ] || \
   [ "$EXPECTED_PG_ARCHIVE_SHA256" = "MISSING" ] || \
   [ "$FLOORPLAN_ROOT" = "MISSING" ]; then
    echo "STOP_HERE_I6_CORRIDOR_PROBE_NOT_RUN=REQUIRED_ARGUMENT_MISSING"
    RUN_OK=0
fi

if [ -d "$REPO/.git" ]; then
    cd "$REPO"
    CD_RC=$?
    if [ "$CD_RC" = "0" ]; then
        ENTRY_HEAD="$(git rev-parse HEAD 2>/dev/null)"
    fi
else
    echo "MISSING_REPOSITORY=$REPO"
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
    git status --short --branch --untracked-files=no
    if [ "$CHECKOUT_RC" != "0" ] || \
       [ "$PULL_RC" != "0" ] || \
       [ "$ACTUAL_HEAD" != "$EXPECTED_HEAD" ] || \
       [ "$TRACKED_DIFF_RC" != "0" ] || \
       [ "$STAGED_DIFF_RC" != "0" ]; then
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ] && [ "$ENTRY_HEAD" != "$ACTUAL_HEAD" ]; then
    if [ "$REEXECUTED" = "0" ]; then
        echo "WRAPPER_FAST_FORWARD_DETECTED=$ENTRY_HEAD:$ACTUAL_HEAD"
        export SPADMIC_CORRIDOR_PROBE_REEXECUTED=1
        exec bash "$WRAPPER" \
            "$EXPECTED_HEAD" \
            "$SOURCE_ROOT" \
            "$EXPECTED_SOURCE_ARCHIVE_SHA256" \
            "$PG_ROOT" \
            "$EXPECTED_PG_ARCHIVE_SHA256" \
            "$FLOORPLAN_ROOT"
        REEXEC_EXEC_RC=$?
        RUN_OK=0
    else
        echo "STOP_HERE_I6_CORRIDOR_PROBE_NOT_RUN=CHECKOUT_CHANGED_TWICE"
        RUN_OK=0
    fi
fi

UPSTREAM_FILE_GATE_RC=0
for REQUIRED in \
    "$SOURCE_ROOT/SHA256SUMS" \
    "$SOURCE_ROOT/evidence_payload.tar.gz" \
    "$SOURCE_ROOT/evidence_payload.tar.gz.sha256" \
    "$SOURCE_ROOT/evidence_seal_status.rpt" \
    "$SOURCE_ROOT/source_stability_status.rpt" \
    "$SOURCE_STATUS" \
    "$SOURCE_RAW/SHA256SUMS" \
    "$PG_ROOT/SHA256SUMS" \
    "$PG_ROOT/evidence_payload.tar.gz" \
    "$PG_ROOT/evidence_payload.tar.gz.sha256" \
    "$PG_EVIDENCE_STATUS" \
    "$PG_RAW/SHA256SUMS" \
    "$PG_PROCESSED/SHA256SUMS" \
    "$PG_PROCESSED/digital_pg_access_status.rpt" \
    "$FLOORPLAN_ROOT/SHA256SUMS" \
    "$FLOORPLAN_STATUS" \
    "$FLOORPLAN_PAIR" \
    "$CADENCE_CDS_LIB" \
    "$CADENCE_LAUNCH_DIR/.cdsinit" \
    "$TOP_OA_PATH" \
    "$WRAPPER" \
    "$CONTRACT" \
    "$PROBE_SKILL" \
    "$CLASSIFIER"
do
    if [ ! -r "$REQUIRED" ]; then
        echo "MISSING_REQUIRED_FILE=$REQUIRED"
        UPSTREAM_FILE_GATE_RC=1
    fi
done

require_status_lines "$SOURCE_ROOT/evidence_seal_status.rpt" \
    'STATUS=PASS' \
    'RAW_AND_PROCESSED_MUTATION_AUTHORIZED=NO' \
    'EVIDENCE_ROOT_REUSE_AUTHORIZED=NO'
SOURCE_SEAL_STATUS_RC=$?
require_status_lines "$SOURCE_ROOT/source_stability_status.rpt" \
    'STATUS=PASS' \
    'SOURCE_MUTATION_AUTHORIZED=NO'
SOURCE_STABILITY_STATUS_RC=$?
require_status_lines "$SOURCE_STATUS" \
    'SOURCE_IDENTITY_GATE_STATUS=PASS' \
    'P03_INTERFACE_CONTRACT_STATUS=PASS' \
    'PG_ANCHOR_GATE_STATUS=FAIL' \
    'P00_P02_IMPLEMENTATION_AUTHORIZED=NO' \
    'P03_IMPLEMENTATION_AUTHORIZED=NO'
SOURCE_CONTRACT_STATUS_RC=$?
if [ "$SOURCE_SEAL_STATUS_RC" = "0" ] && \
   [ "$SOURCE_STABILITY_STATUS_RC" = "0" ] && \
   [ "$SOURCE_CONTRACT_STATUS_RC" = "0" ]; then
    SOURCE_STATUS_GATE_RC=0
fi

require_status_lines "$PG_EVIDENCE_STATUS" \
    'STATUS=PASS' \
    "SOURCE_ROOT=$SOURCE_ROOT" \
    'SOURCE_MUTATION_AUTHORIZED=NO' \
    'OA_EDIT_AUTHORIZED=NO' \
    'GENUS_EXECUTED=NO' \
    'INNOVUS_EXECUTED=NO'
PG_EVIDENCE_STATUS_RC=$?
require_status_lines "$PG_PROCESSED/digital_pg_access_status.rpt" \
    'STATUS=PASS' \
    'SOURCE_TO_LOCAL_PG_MAPPING_STATUS=PASS' \
    'INSTANCE_PIN_CHIP_PG_METTP_CANDIDATE_STATUS=PASS' \
    'REVIEW_CANDIDATE_PAIR_STATUS=PASS' \
    'P00_P02_IMPLEMENTATION_AUTHORIZED=NO' \
    'P03_IMPLEMENTATION_AUTHORIZED=NO'
PG_CLASSIFICATION_STATUS_RC=$?
if [ "$PG_EVIDENCE_STATUS_RC" = "0" ] && \
   [ "$PG_CLASSIFICATION_STATUS_RC" = "0" ]; then
    PG_STATUS_GATE_RC=0
fi

require_status_lines "$FLOORPLAN_STATUS" \
    'STATUS=PASS' \
    'RESULT=PG_ACCESS_EVIDENCE_READY_FOR_REVIEW' \
    "PROCESSOR_SHA256=$ACCEPTED_FLOORPLAN_PROCESSOR_SHA256" \
    "CONTRACT_SHA256=$ACCEPTED_FLOORPLAN_CONTRACT_SHA256" \
    "SOURCE_AUDIT_ROOT=$SOURCE_ROOT" \
    "PROBE_ROOT=$PG_RAW" \
    'ASSEMBLY_FLOORPLAN_MODEL_STATUS=PASS' \
    'ASSEMBLY_BOUNDARY_INSTANCE=I5' \
    'ASSEMBLY_FIXED_OBSTACLE_COUNT=13' \
    'ASSEMBLY_VERIFIED_INTERIOR_WHITESPACE_RECT_COUNT=62' \
    'ASSEMBLY_PRIMARY_WHITESPACE_SOURCE_BBOX_UM=3662.535000 -123.715000 3951.791000 3289.077000' \
    'COMPLETE_SAME_INSTANCE_PG_PAIR_STATUS=PASS' \
    'REVIEW_CANDIDATE_PAIR_INSTANCE=I6' \
    'REVIEW_CANDIDATE_PAIR_OWNER_SCOPE=INSTANCE' \
    'TARGET_INSTANCE_METTP_CONTEXT_STATUS=NOT_PROBED' \
    'BRIDGE_GEOMETRY_STATUS=NOT_AUTHORIZED' \
    'P00_P02_IMPLEMENTATION_AUTHORIZED=NO' \
    'P03_IMPLEMENTATION_AUTHORIZED=NO' \
    'NEXT_GATE=RUN_READ_ONLY_SELECTED_INSTANCE_METTP_CORRIDOR_PROBE'
FLOORPLAN_STATUS_GATE_RC=$?

if [ -n "$SHA256SUM_BIN" ] && [ -x "$SHA256SUM_BIN" ]; then
    verify_manifest "$SOURCE_ROOT" "$SOURCE_ROOT/SHA256SUMS" >/dev/null
    SOURCE_MANIFEST_PRE_RC=$?
    verify_manifest "$SOURCE_RAW" "$SOURCE_RAW/SHA256SUMS" >/dev/null
    SOURCE_RAW_MANIFEST_PRE_RC=$?
    verify_manifest "$PG_ROOT" "$PG_ROOT/SHA256SUMS" >/dev/null
    PG_MANIFEST_PRE_RC=$?
    verify_manifest "$PG_RAW" "$PG_RAW/SHA256SUMS" >/dev/null
    PG_RAW_MANIFEST_PRE_RC=$?
    verify_manifest "$PG_PROCESSED" "$PG_PROCESSED/SHA256SUMS" >/dev/null
    PG_PROCESSED_MANIFEST_PRE_RC=$?
    verify_manifest "$FLOORPLAN_ROOT" "$FLOORPLAN_ROOT/SHA256SUMS" >/dev/null
    FLOORPLAN_MANIFEST_PRE_RC=$?

    (
        cd "$SOURCE_ROOT"
        ARCHIVE_CD_RC=$?
        if [ "$ARCHIVE_CD_RC" = "0" ]; then
            "$SHA256SUM_BIN" -c evidence_payload.tar.gz.sha256
        else
            false
        fi
    ) >/dev/null
    SOURCE_ARCHIVE_HASH_RC=$?
    ACTUAL_SOURCE_ARCHIVE_SHA256="$(
        "$SHA256SUM_BIN" "$SOURCE_ROOT/evidence_payload.tar.gz" 2>/dev/null |
            awk '{print $1}'
    )"
    if [ -z "$ACTUAL_SOURCE_ARCHIVE_SHA256" ]; then
        ACTUAL_SOURCE_ARCHIVE_SHA256=UNKNOWN
    fi
    if [ "$ACTUAL_SOURCE_ARCHIVE_SHA256" = \
         "$EXPECTED_SOURCE_ARCHIVE_SHA256" ]; then
        SOURCE_ARCHIVE_EXPECTED_RC=0
    else
        SOURCE_ARCHIVE_EXPECTED_RC=1
    fi

    (
        cd "$PG_ROOT"
        ARCHIVE_CD_RC=$?
        if [ "$ARCHIVE_CD_RC" = "0" ]; then
            "$SHA256SUM_BIN" -c evidence_payload.tar.gz.sha256
        else
            false
        fi
    ) >/dev/null
    PG_ARCHIVE_HASH_RC=$?
    ACTUAL_PG_ARCHIVE_SHA256="$(
        "$SHA256SUM_BIN" "$PG_ROOT/evidence_payload.tar.gz" 2>/dev/null |
            awk '{print $1}'
    )"
    if [ -z "$ACTUAL_PG_ARCHIVE_SHA256" ]; then
        ACTUAL_PG_ARCHIVE_SHA256=UNKNOWN
    fi
    if [ "$ACTUAL_PG_ARCHIVE_SHA256" = "$EXPECTED_PG_ARCHIVE_SHA256" ]; then
        PG_ARCHIVE_EXPECTED_RC=0
    else
        PG_ARCHIVE_EXPECTED_RC=1
    fi
else
    ACTUAL_SOURCE_ARCHIVE_SHA256=UNKNOWN
    ACTUAL_PG_ARCHIVE_SHA256=UNKNOWN
fi

if [ -n "$TAR_BIN" ] && [ -x "$TAR_BIN" ]; then
    "$TAR_BIN" -tzf "$SOURCE_ROOT/evidence_payload.tar.gz" >/dev/null 2>&1
    SOURCE_ARCHIVE_TAR_RC=$?
    "$TAR_BIN" -tzf "$PG_ROOT/evidence_payload.tar.gz" >/dev/null 2>&1
    PG_ARCHIVE_TAR_RC=$?
fi

SOURCE_WRITABLE_PATH="$(
    find "$SOURCE_ROOT" -perm /222 -print -quit 2>/dev/null
)"
SOURCE_READ_ONLY_FIND_RC=$?
PG_WRITABLE_PATH="$(
    find "$PG_ROOT" -perm /222 -print -quit 2>/dev/null
)"
PG_READ_ONLY_FIND_RC=$?
FLOORPLAN_WRITABLE_PATH="$(
    find "$FLOORPLAN_ROOT" -perm /222 -print -quit 2>/dev/null
)"
FLOORPLAN_READ_ONLY_FIND_RC=$?
if [ "$SOURCE_READ_ONLY_FIND_RC" = "0" ] && \
   [ -z "$SOURCE_WRITABLE_PATH" ]; then
    SOURCE_READ_ONLY_RC=0
fi
if [ "$PG_READ_ONLY_FIND_RC" = "0" ] && \
   [ -z "$PG_WRITABLE_PATH" ]; then
    PG_READ_ONLY_RC=0
fi
if [ "$FLOORPLAN_READ_ONLY_FIND_RC" = "0" ] && \
   [ -z "$FLOORPLAN_WRITABLE_PATH" ]; then
    FLOORPLAN_READ_ONLY_RC=0
fi

TOOL_GATE_RC=0
for TOOL in "$SHA256SUM_BIN" "$TAR_BIN" "$CHMOD_BIN" "$VIRTUOSO_BIN"; do
    if [ -z "$TOOL" ] || [ ! -x "$TOOL" ]; then
        TOOL_GATE_RC=1
    fi
done
if [ "$TOOL_GATE_RC" = "0" ]; then
    SHA256SUM_BIN_SHA256="$(
        "$SHA256SUM_BIN" "$SHA256SUM_BIN" 2>/dev/null |
            awk '{print $1}'
    )"
    WRAPPER_SHA256="$("$SHA256SUM_BIN" "$WRAPPER" | awk '{print $1}')"
    PROBE_SKILL_SHA256="$("$SHA256SUM_BIN" "$PROBE_SKILL" | awk '{print $1}')"
    CLASSIFIER_SHA256="$("$SHA256SUM_BIN" "$CLASSIFIER" | awk '{print $1}')"
    CONTRACT_SHA256="$("$SHA256SUM_BIN" "$CONTRACT" | awk '{print $1}')"
fi
ACTIVE_PROBE="$(
    pgrep -af \
        '[v]irtuoso.*probe_spadmic2_selected_pg_corridor\.il|[c]lassify_spadmic2_selected_pg_corridor\.py' \
        2>/dev/null
)"

if [ "$RUN_OK" = "1" ] && \
   [ "$UPSTREAM_FILE_GATE_RC" = "0" ] && \
   [ "$SOURCE_STATUS_GATE_RC" = "0" ] && \
   [ "$PG_STATUS_GATE_RC" = "0" ] && \
   [ "$FLOORPLAN_STATUS_GATE_RC" = "0" ] && \
   [ "$SOURCE_MANIFEST_PRE_RC" = "0" ] && \
   [ "$SOURCE_RAW_MANIFEST_PRE_RC" = "0" ] && \
   [ "$PG_MANIFEST_PRE_RC" = "0" ] && \
   [ "$PG_RAW_MANIFEST_PRE_RC" = "0" ] && \
   [ "$PG_PROCESSED_MANIFEST_PRE_RC" = "0" ] && \
   [ "$FLOORPLAN_MANIFEST_PRE_RC" = "0" ] && \
   [ "$SOURCE_ARCHIVE_HASH_RC" = "0" ] && \
   [ "$SOURCE_ARCHIVE_EXPECTED_RC" = "0" ] && \
   [ "$SOURCE_ARCHIVE_TAR_RC" = "0" ] && \
   [ "$PG_ARCHIVE_HASH_RC" = "0" ] && \
   [ "$PG_ARCHIVE_EXPECTED_RC" = "0" ] && \
   [ "$PG_ARCHIVE_TAR_RC" = "0" ] && \
   [ "$SOURCE_READ_ONLY_RC" = "0" ] && \
   [ "$PG_READ_ONLY_RC" = "0" ] && \
   [ "$FLOORPLAN_READ_ONLY_RC" = "0" ] && \
   [ "$TOOL_GATE_RC" = "0" ] && \
   [ -z "$ACTIVE_PROBE" ]; then
    mkdir "$DIAGNOSTIC_ROOT"
    ROOT_CREATE_RC=$?
    if [ "$ROOT_CREATE_RC" = "0" ]; then
        mkdir "$RAW_ROOT" "$PROCESSED_ROOT"
        PAYLOAD_CREATE_RC=$?
    else
        PAYLOAD_CREATE_RC=1
    fi
    if [ "$ROOT_CREATE_RC" = "0" ] && [ "$PAYLOAD_CREATE_RC" = "0" ]; then
        DIAGNOSTIC_CREATE_RC=0
        run_checksum_selftest
        CHECKSUM_SELFTEST_RC=$?
    else
        DIAGNOSTIC_CREATE_RC=1
    fi
else
    echo "STOP_HERE_I6_CORRIDOR_PROBE_NOT_RUN=PREFLIGHT_FAILED"
    RUN_OK=0
fi
if [ "$DIAGNOSTIC_CREATE_RC" != "0" ] || \
   [ "$CHECKSUM_SELFTEST_RC" != "0" ]; then
    RUN_OK=0
fi

if [ "$RUN_OK" = "1" ]; then
    echo "INCLUDE $CADENCE_CDS_LIB" > "$SESSION_CDS_LIB"
    SESSION_CDS_LIB_CREATE_RC=$?
    inventory_tree "$TOP_OA_PATH" "$DIAGNOSTIC_ROOT/spadmic2_source.pre.sha256"
    SOURCE_INVENTORY_PRE_RC=$?
    if [ "$SESSION_CDS_LIB_CREATE_RC" != "0" ] || \
       [ "$SOURCE_INVENTORY_PRE_RC" != "0" ]; then
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ]; then
    export SPADMIC_CORRIDOR_PROBE_ROOT="$RAW_ROOT"
    export SPADMIC_CORRIDOR_LIBRARY=SPADMIC
    export SPADMIC_CORRIDOR_CELL=SPADMIC2
    export SPADMIC_CORRIDOR_VIEW=layout
    export SPADMIC_CORRIDOR_SOURCE_PATH="$TOP_OA_PATH"
    export SPADMIC_CORRIDOR_TARGET_INSTANCE=I6
    export SPADMIC_CORRIDOR_TARGET_MASTER=TXRX4TDC2_HV
    export SPADMIC_CORRIDOR_WINDOW_LLX=3415.960000
    export SPADMIC_CORRIDOR_WINDOW_LLY=2141.710000
    export SPADMIC_CORRIDOR_WINDOW_URX=3762.535000
    export SPADMIC_CORRIDOR_WINDOW_URY=2343.845000
    (
        cd "$CADENCE_LAUNCH_DIR"
        CADENCE_CD_RC=$?
        if [ "$CADENCE_CD_RC" = "0" ]; then
            "$VIRTUOSO_BIN" -nograph \
                -cdslib "$SESSION_CDS_LIB" \
                -restore "$PROBE_SKILL" \
                -log "$PROBE_LOG" \
                </dev/null
        else
            false
        fi
    )
    VIRTUOSO_RC=$?
fi

RAW_EXPORT_GATE_RC=0
for EXPORT in \
    "$RAW_ROOT/virtuoso_export_status.rpt" \
    "$RAW_ROOT/corridor_query_status.rpt" \
    "$RAW_ROOT/source_identity.tsv" \
    "$RAW_ROOT/target_instance.tsv" \
    "$RAW_ROOT/target_pg_pins.tsv" \
    "$RAW_ROOT/corridor_hierarchical_shapes.tsv"
do
    if [ ! -s "$EXPORT" ]; then
        echo "MISSING_OR_EMPTY_CORRIDOR_EXPORT=$EXPORT"
        RAW_EXPORT_GATE_RC=1
    fi
done
require_status_lines "$RAW_ROOT/virtuoso_export_status.rpt" \
    'STATUS=PASS' \
    'SOURCE_MUTATION_AUTHORIZED=NO' \
    'OA_EDIT_AUTHORIZED=NO' \
    'HIERARCHICAL_QUERY_POLICY=DB_GET_TRUE_OVERLAPS_DEPTH_0_32_WITH_ROW_COLUMN_ENUMERATION' \
    'HIERARCHICAL_TRANSFORM_POLICY=DB_GET_HIER_PATH_TRANSFORM' \
    'CORRIDOR_AUTHORIZATION=REVIEW_ONLY_NO_GEOMETRY_CREATION'
if [ "$?" != "0" ]; then RAW_EXPORT_GATE_RC=1; fi
require_status_lines "$RAW_ROOT/corridor_query_status.rpt" \
    'STATUS=PASS' \
    'TARGET_INSTANCE=I6' \
    'TARGET_MASTER=SPADMIC/TXRX4TDC2_HV/layout' \
    'TARGET_ORIENT=R0' \
    'QUERY_WINDOW_UM=3415.960000 2141.710000 3762.535000 2343.845000' \
    'HIERARCHICAL_TRANSFORM_FAILURE_COUNT=0' \
    'HIERARCHY_DEPTH=0:32' \
    'MOSAIC_ROW_COLUMN_ENUMERATION=YES' \
    'CORRIDOR_AUTHORIZATION=REVIEW_ONLY_NO_GEOMETRY_CREATION'
if [ "$?" != "0" ]; then RAW_EXPORT_GATE_RC=1; fi
if [ "$VIRTUOSO_RC" != "0" ] || [ "$RAW_EXPORT_GATE_RC" != "0" ]; then
    RUN_OK=0
fi

if [ "$RUN_OK" = "1" ]; then
    create_manifest "$RAW_ROOT"
    RAW_MANIFEST_CREATE_RC=$?
    verify_manifest "$RAW_ROOT" "$RAW_ROOT/SHA256SUMS" >/dev/null
    RAW_MANIFEST_PRE_SEAL_RC=$?
    if [ "$RAW_MANIFEST_CREATE_RC" = "0" ] && \
       [ "$RAW_MANIFEST_PRE_SEAL_RC" = "0" ]; then
        "$CHMOD_BIN" -R a-w "$RAW_ROOT"
        RAW_SEAL_RC=$?
    else
        RAW_SEAL_RC=1
    fi
    RAW_WRITABLE_PATH="$(
        find "$RAW_ROOT" -perm /222 -print -quit 2>/dev/null
    )"
    RAW_READ_ONLY_FIND_RC=$?
    if [ "$RAW_READ_ONLY_FIND_RC" = "0" ] && \
       [ -z "$RAW_WRITABLE_PATH" ]; then
        RAW_READ_ONLY_RC=0
    fi
    if [ "$RAW_SEAL_RC" != "0" ] || [ "$RAW_READ_ONLY_RC" != "0" ]; then
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" = "1" ]; then
    python3 "$CLASSIFIER" \
        --probe-root "$RAW_ROOT" \
        --floorplan-root "$FLOORPLAN_ROOT" \
        --out "$PROCESSED_ROOT" \
        --contract "$CONTRACT"
    CLASSIFIER_RC=$?
fi

require_status_lines "$PROCESSED_ROOT/selected_i6_corridor_status.rpt" \
    'STATUS=PASS' \
    'RESULT=SELECTED_I6_METTP_CORRIDOR_EVIDENCE_READY' \
    "PROCESSOR_SHA256=$CLASSIFIER_SHA256" \
    "CONTRACT_SHA256=$CONTRACT_SHA256" \
    'SOURCE_IDENTITY_GATE_STATUS=PASS' \
    'ACCEPTED_FLOORPLAN_GATE_STATUS=PASS' \
    'TARGET_INSTANCE_GATE_STATUS=PASS' \
    'TARGET_INSTANCE=I6' \
    'TARGET_MASTER=SPADMIC/TXRX4TDC2_HV/layout' \
    'TARGET_ORIENT=R0' \
    'TARGET_PIN_PAIR_STATUS=PASS' \
    'LOCAL_VDD_NET=VDD' \
    'CHIP_VDD_NET=DVDD' \
    'LOCAL_VSS_NET=VSS' \
    'CHIP_VSS_NET=DVSS' \
    'TARGET_VDD_SOURCE_BBOX_UM=3515.960000 2241.710000 3550.960000 2243.845000' \
    'TARGET_VSS_SOURCE_BBOX_UM=3555.960000 2241.985000 3590.960000 2243.845000' \
    'PRIMARY_WHITESPACE_ENTRY_X_UM=3662.535000' \
    'CORRIDOR_QUERY_WINDOW_UM=3415.960000 2141.710000 3762.535000 2343.845000' \
    'HIERARCHICAL_QUERY_STATUS=PASS' \
    'HIERARCHICAL_TRANSFORM_FAILURE_COUNT=0' \
    'TARGET_PIN_HIERARCHICAL_COVERAGE_STATUS=PASS' \
    'DVDD_DIRECT_EAST_TO_WHITESPACE_STATUS=REJECT_TARGET_DVSS_INTERSECTION' \
    'CORRIDOR_SEARCH_REGION_STATUS=PASS_EVIDENCE_READY' \
    'CANDIDATE_AUTHORIZATION=REVIEW_ONLY_NO_GEOMETRY_CREATION' \
    'BRIDGE_GEOMETRY_STATUS=NOT_AUTHORIZED' \
    'BRIDGE_CANDIDATE_DEFINITION_STATUS=DEFERRED_UNTIL_CORRIDOR_REVIEW' \
    'P00_P02_IMPLEMENTATION_AUTHORIZED=NO' \
    'P03_IMPLEMENTATION_AUTHORIZED=NO' \
    'NEXT_GATE=RETURN_I6_CORRIDOR_EVIDENCE_FOR_BRIDGE_CANDIDATE_DEFINITION'
CLASSIFICATION_GATE_RC=$?
if [ "$CLASSIFIER_RC" = "0" ] && [ "$CLASSIFICATION_GATE_RC" = "0" ]; then
    verify_manifest "$PROCESSED_ROOT" "$PROCESSED_ROOT/SHA256SUMS" >/dev/null
    PROCESSED_MANIFEST_RC=$?
    if [ "$PROCESSED_MANIFEST_RC" = "0" ]; then
        "$CHMOD_BIN" -R a-w "$PROCESSED_ROOT"
        PROCESSED_SEAL_RC=$?
    else
        PROCESSED_SEAL_RC=1
    fi
    PROCESSED_WRITABLE_PATH="$(
        find "$PROCESSED_ROOT" -perm /222 -print -quit 2>/dev/null
    )"
    PROCESSED_READ_ONLY_FIND_RC=$?
    if [ "$PROCESSED_READ_ONLY_FIND_RC" = "0" ] && \
       [ -z "$PROCESSED_WRITABLE_PATH" ]; then
        PROCESSED_READ_ONLY_RC=0
    fi
else
    RUN_OK=0
fi

inventory_tree "$TOP_OA_PATH" "$DIAGNOSTIC_ROOT/spadmic2_source.post.sha256"
SOURCE_INVENTORY_POST_RC=$?
if [ "$SOURCE_INVENTORY_PRE_RC" = "0" ] && \
   [ "$SOURCE_INVENTORY_POST_RC" = "0" ]; then
    diff -u \
        "$DIAGNOSTIC_ROOT/spadmic2_source.pre.sha256" \
        "$DIAGNOSTIC_ROOT/spadmic2_source.post.sha256" \
        > "$DIAGNOSTIC_ROOT/spadmic2_source_delta.rpt"
    SOURCE_STABILITY_RC=$?
fi

verify_manifest "$SOURCE_ROOT" "$SOURCE_ROOT/SHA256SUMS" >/dev/null
SOURCE_MANIFEST_POST_RC=$?
verify_manifest "$SOURCE_RAW" "$SOURCE_RAW/SHA256SUMS" >/dev/null
SOURCE_RAW_MANIFEST_POST_RC=$?
verify_manifest "$PG_ROOT" "$PG_ROOT/SHA256SUMS" >/dev/null
PG_MANIFEST_POST_RC=$?
verify_manifest "$PG_RAW" "$PG_RAW/SHA256SUMS" >/dev/null
PG_RAW_MANIFEST_POST_RC=$?
verify_manifest "$PG_PROCESSED" "$PG_PROCESSED/SHA256SUMS" >/dev/null
PG_PROCESSED_MANIFEST_POST_RC=$?
verify_manifest "$FLOORPLAN_ROOT" "$FLOORPLAN_ROOT/SHA256SUMS" >/dev/null
FLOORPLAN_MANIFEST_POST_RC=$?

SOURCE_WRITABLE_PATH_POST="$(
    find "$SOURCE_ROOT" -perm /222 -print -quit 2>/dev/null
)"
SOURCE_READ_ONLY_POST_FIND_RC=$?
PG_WRITABLE_PATH_POST="$(
    find "$PG_ROOT" -perm /222 -print -quit 2>/dev/null
)"
PG_READ_ONLY_POST_FIND_RC=$?
FLOORPLAN_WRITABLE_PATH_POST="$(
    find "$FLOORPLAN_ROOT" -perm /222 -print -quit 2>/dev/null
)"
FLOORPLAN_READ_ONLY_POST_FIND_RC=$?
if [ "$SOURCE_READ_ONLY_POST_FIND_RC" = "0" ] && \
   [ "$PG_READ_ONLY_POST_FIND_RC" = "0" ] && \
   [ "$FLOORPLAN_READ_ONLY_POST_FIND_RC" = "0" ] && \
   [ -z "$SOURCE_WRITABLE_PATH_POST" ] && \
   [ -z "$PG_WRITABLE_PATH_POST" ] && \
   [ -z "$FLOORPLAN_WRITABLE_PATH_POST" ]; then
    UPSTREAM_READ_ONLY_POST_RC=0
fi

if [ "$RUN_OK" = "1" ] && \
   [ "$PROCESSED_SEAL_RC" = "0" ] && \
   [ "$PROCESSED_READ_ONLY_RC" = "0" ]; then
    (
        cd "$DIAGNOSTIC_ROOT"
        ARCHIVE_LIST_CD_RC=$?
        if [ "$ARCHIVE_LIST_CD_RC" = "0" ]; then
            find . -type f \
                ! -path './evidence_payload.tar.gz' \
                ! -path './evidence_payload.tar.gz.sha256' \
                ! -path './i6_corridor_probe_evidence_status.rpt' \
                ! -path './SHA256SUMS' \
                -print |
                LC_ALL=C sort > evidence_payload_filelist.txt
        else
            false
        fi
    )
    RECOVERY_ARCHIVE_FILELIST_RC=$?
    if [ "$RECOVERY_ARCHIVE_FILELIST_RC" = "0" ]; then
        (
            cd "$DIAGNOSTIC_ROOT"
            "$TAR_BIN" -czf evidence_payload.tar.gz \
                -T evidence_payload_filelist.txt
        )
        RECOVERY_ARCHIVE_CREATE_RC=$?
    fi
    if [ "$RECOVERY_ARCHIVE_CREATE_RC" = "0" ]; then
        "$TAR_BIN" -tzf "$RECOVERY_ARCHIVE" >/dev/null 2>&1
        RECOVERY_ARCHIVE_TAR_VERIFY_RC=$?
        (
            cd "$DIAGNOSTIC_ROOT"
            "$SHA256SUM_BIN" evidence_payload.tar.gz \
                > evidence_payload.tar.gz.sha256
        )
        RECOVERY_ARCHIVE_HASH_CREATE_RC=$?
    fi
    if [ "$RECOVERY_ARCHIVE_HASH_CREATE_RC" = "0" ]; then
        (
            cd "$DIAGNOSTIC_ROOT"
            "$SHA256SUM_BIN" -c evidence_payload.tar.gz.sha256
        ) >/dev/null 2>&1
        RECOVERY_ARCHIVE_HASH_VERIFY_RC=$?
        RECOVERY_ARCHIVE_SHA256="$(
            "$SHA256SUM_BIN" "$RECOVERY_ARCHIVE" 2>/dev/null |
                awk '{print $1}'
        )"
    fi
    verify_manifest "$RAW_ROOT" "$RAW_ROOT/SHA256SUMS" >/dev/null
    RAW_MANIFEST_POST_ARCHIVE_RC=$?
    verify_manifest "$PROCESSED_ROOT" "$PROCESSED_ROOT/SHA256SUMS" >/dev/null
    PROCESSED_MANIFEST_POST_ARCHIVE_RC=$?
fi

if [ "$RUN_OK" = "1" ] && \
   [ "$DIAGNOSTIC_CREATE_RC" = "0" ] && \
   [ "$CHECKSUM_SELFTEST_RC" = "0" ] && \
   [ "$VIRTUOSO_RC" = "0" ] && \
   [ "$RAW_EXPORT_GATE_RC" = "0" ] && \
   [ "$RAW_SEAL_RC" = "0" ] && \
   [ "$RAW_READ_ONLY_RC" = "0" ] && \
   [ "$CLASSIFIER_RC" = "0" ] && \
   [ "$CLASSIFICATION_GATE_RC" = "0" ] && \
   [ "$PROCESSED_MANIFEST_RC" = "0" ] && \
   [ "$PROCESSED_SEAL_RC" = "0" ] && \
   [ "$PROCESSED_READ_ONLY_RC" = "0" ] && \
   [ "$SOURCE_STABILITY_RC" = "0" ] && \
   [ "$SOURCE_MANIFEST_POST_RC" = "0" ] && \
   [ "$SOURCE_RAW_MANIFEST_POST_RC" = "0" ] && \
   [ "$PG_MANIFEST_POST_RC" = "0" ] && \
   [ "$PG_RAW_MANIFEST_POST_RC" = "0" ] && \
   [ "$PG_PROCESSED_MANIFEST_POST_RC" = "0" ] && \
   [ "$FLOORPLAN_MANIFEST_POST_RC" = "0" ] && \
   [ "$UPSTREAM_READ_ONLY_POST_RC" = "0" ] && \
   [ "$RAW_MANIFEST_POST_ARCHIVE_RC" = "0" ] && \
   [ "$PROCESSED_MANIFEST_POST_ARCHIVE_RC" = "0" ] && \
   [ "$RECOVERY_ARCHIVE_FILELIST_RC" = "0" ] && \
   [ "$RECOVERY_ARCHIVE_CREATE_RC" = "0" ] && \
   [ "$RECOVERY_ARCHIVE_TAR_VERIFY_RC" = "0" ] && \
   [ "$RECOVERY_ARCHIVE_HASH_CREATE_RC" = "0" ] && \
   [ "$RECOVERY_ARCHIVE_HASH_VERIFY_RC" = "0" ]; then
    PRESEAL_GATE_RC=0
fi

if [ "$DIAGNOSTIC_CREATE_RC" = "0" ]; then
    {
        echo "LABEL=SPADMIC2_SELECTED_I6_METTP_CORRIDOR_PROBE_EVIDENCE"
        echo "STATUS=$([ "$PRESEAL_GATE_RC" = "0" ] && echo PASS || echo FAIL)"
        echo "EXPECTED_HEAD=$EXPECTED_HEAD"
        echo "ACTUAL_HEAD=$ACTUAL_HEAD"
        echo "WRAPPER_SHA256=$WRAPPER_SHA256"
        echo "PROBE_SKILL_SHA256=$PROBE_SKILL_SHA256"
        echo "CLASSIFIER_SHA256=$CLASSIFIER_SHA256"
        echo "CONTRACT_SHA256=$CONTRACT_SHA256"
        echo "SOURCE_ROOT=$SOURCE_ROOT"
        echo "EXPECTED_SOURCE_ARCHIVE_SHA256=$EXPECTED_SOURCE_ARCHIVE_SHA256"
        echo "ACTUAL_SOURCE_ARCHIVE_SHA256=$ACTUAL_SOURCE_ARCHIVE_SHA256"
        echo "PG_ROOT=$PG_ROOT"
        echo "EXPECTED_PG_ARCHIVE_SHA256=$EXPECTED_PG_ARCHIVE_SHA256"
        echo "ACTUAL_PG_ARCHIVE_SHA256=$ACTUAL_PG_ARCHIVE_SHA256"
        echo "FLOORPLAN_ROOT=$FLOORPLAN_ROOT"
        echo "SOURCE_STABILITY_RC=$SOURCE_STABILITY_RC"
        echo "SOURCE_MANIFEST_POST_RC=$SOURCE_MANIFEST_POST_RC"
        echo "PG_MANIFEST_POST_RC=$PG_MANIFEST_POST_RC"
        echo "FLOORPLAN_MANIFEST_POST_RC=$FLOORPLAN_MANIFEST_POST_RC"
        echo "VIRTUOSO_RC=$VIRTUOSO_RC"
        echo "RAW_EXPORT_GATE_RC=$RAW_EXPORT_GATE_RC"
        echo "CLASSIFIER_RC=$CLASSIFIER_RC"
        echo "CLASSIFICATION_GATE_RC=$CLASSIFICATION_GATE_RC"
        echo "RECOVERY_ARCHIVE=$RECOVERY_ARCHIVE"
        echo "RECOVERY_ARCHIVE_SHA256=$RECOVERY_ARCHIVE_SHA256"
        echo "SOURCE_MUTATION_AUTHORIZED=NO"
        echo "OA_EDIT_AUTHORIZED=NO"
        echo "GENUS_EXECUTED=NO"
        echo "INNOVUS_EXECUTED=NO"
        echo "BRIDGE_GEOMETRY_AUTHORIZED=NO"
        echo "NEXT_GATE=RETURN_I6_CORRIDOR_EVIDENCE_FOR_BRIDGE_CANDIDATE_DEFINITION"
    } > "$EVIDENCE_STATUS"
fi

if [ "$PRESEAL_GATE_RC" = "0" ]; then
    create_manifest "$DIAGNOSTIC_ROOT"
    OUTER_MANIFEST_CREATE_RC=$?
    if [ "$OUTER_MANIFEST_CREATE_RC" = "0" ]; then
        "$CHMOD_BIN" -R a-w "$DIAGNOSTIC_ROOT"
        ROOT_SEAL_RC=$?
    else
        ROOT_SEAL_RC=1
    fi
fi
ROOT_WRITABLE_PATH="$(
    find "$DIAGNOSTIC_ROOT" -perm /222 -print -quit 2>/dev/null
)"
ROOT_READ_ONLY_FIND_RC=$?
if [ "$ROOT_READ_ONLY_FIND_RC" = "0" ] && \
   [ -z "$ROOT_WRITABLE_PATH" ]; then
    ROOT_READ_ONLY_RC=0
fi
if [ "$ROOT_SEAL_RC" = "0" ]; then
    verify_manifest "$DIAGNOSTIC_ROOT" "$DIAGNOSTIC_ROOT/SHA256SUMS" >/dev/null
    OUTER_MANIFEST_POST_SEAL_RC=$?
fi
if [ "$PRESEAL_GATE_RC" = "0" ] && \
   [ "$OUTER_MANIFEST_CREATE_RC" = "0" ] && \
   [ "$ROOT_SEAL_RC" = "0" ] && \
   [ "$ROOT_READ_ONLY_RC" = "0" ] && \
   [ "$OUTER_MANIFEST_POST_SEAL_RC" = "0" ]; then
    PROBE_STATUS=PASS_EVIDENCE_READY
fi

echo
echo "EXPECTED_HEAD=$EXPECTED_HEAD"
echo "ACTUAL_HEAD=$ACTUAL_HEAD"
echo "WRAPPER_SHA256=$WRAPPER_SHA256"
echo "PROBE_SKILL_SHA256=$PROBE_SKILL_SHA256"
echo "CLASSIFIER_SHA256=$CLASSIFIER_SHA256"
echo "CONTRACT_SHA256=$CONTRACT_SHA256"
echo "SHA256SUM_BIN_SHA256=$SHA256SUM_BIN_SHA256"
echo "SOURCE_ROOT=$SOURCE_ROOT"
echo "EXPECTED_SOURCE_ARCHIVE_SHA256=$EXPECTED_SOURCE_ARCHIVE_SHA256"
echo "ACTUAL_SOURCE_ARCHIVE_SHA256=$ACTUAL_SOURCE_ARCHIVE_SHA256"
echo "PG_ROOT=$PG_ROOT"
echo "EXPECTED_PG_ARCHIVE_SHA256=$EXPECTED_PG_ARCHIVE_SHA256"
echo "ACTUAL_PG_ARCHIVE_SHA256=$ACTUAL_PG_ARCHIVE_SHA256"
echo "FLOORPLAN_ROOT=$FLOORPLAN_ROOT"
echo "SOURCE_MANIFEST_PRE_RC=$SOURCE_MANIFEST_PRE_RC"
echo "PG_MANIFEST_PRE_RC=$PG_MANIFEST_PRE_RC"
echo "FLOORPLAN_MANIFEST_PRE_RC=$FLOORPLAN_MANIFEST_PRE_RC"
echo "SOURCE_READ_ONLY_PATH=${SOURCE_WRITABLE_PATH:-NONE}"
echo "PG_READ_ONLY_PATH=${PG_WRITABLE_PATH:-NONE}"
echo "FLOORPLAN_READ_ONLY_PATH=${FLOORPLAN_WRITABLE_PATH:-NONE}"
echo "ACTIVE_PROBE=${ACTIVE_PROBE:-NONE}"
echo "CHECKSUM_SELFTEST_RC=$CHECKSUM_SELFTEST_RC"
echo "VIRTUOSO_RC=$VIRTUOSO_RC"
echo "RAW_EXPORT_GATE_RC=$RAW_EXPORT_GATE_RC"
echo "CLASSIFIER_RC=$CLASSIFIER_RC"
echo "CLASSIFICATION_GATE_RC=$CLASSIFICATION_GATE_RC"
echo "SOURCE_STABILITY_RC=$SOURCE_STABILITY_RC"
echo "UPSTREAM_READ_ONLY_POST_RC=$UPSTREAM_READ_ONLY_POST_RC"
echo "RECOVERY_ARCHIVE_SHA256=$RECOVERY_ARCHIVE_SHA256"
echo "DIAGNOSTIC_ROOT=$DIAGNOSTIC_ROOT"
echo "OUTER_MANIFEST_POST_SEAL_RC=$OUTER_MANIFEST_POST_SEAL_RC"
echo "WRITABLE_EVIDENCE_PATH=${ROOT_WRITABLE_PATH:-NONE}"

for REPORT in \
    "$RAW_ROOT/corridor_query_status.rpt" \
    "$RAW_ROOT/target_instance.tsv" \
    "$RAW_ROOT/target_pg_pins.tsv" \
    "$PROCESSED_ROOT/selected_i6_corridor_status.rpt" \
    "$PROCESSED_ROOT/corridor_search_regions.tsv" \
    "$PROCESSED_ROOT/corridor_layer_summary.tsv" \
    "$PROCESSED_ROOT/target_pin_hierarchy_coverage.tsv"
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
echo "===== FIRST 200 CORRIDOR REGION CONTACTS ====="
if [ -r "$PROCESSED_ROOT/corridor_region_contacts.tsv" ]; then
    sed -n '1,200p' "$PROCESSED_ROOT/corridor_region_contacts.tsv"
else
    echo "MISSING=$PROCESSED_ROOT/corridor_region_contacts.tsv"
fi

echo
echo "READ_ONLY_SELECTED_I6_METTP_CORRIDOR_PROBE_STATUS=$PROBE_STATUS"
if [ "$PROBE_STATUS" = "PASS_EVIDENCE_READY" ]; then
    echo "NEXT_GATE=RETURN_I6_CORRIDOR_EVIDENCE_FOR_BRIDGE_CANDIDATE_DEFINITION"
    echo "DO_NOT_START_GENUS_INNOVUS_OR_EDIT_OA"
    true
else
    echo "STOP_HERE_DO_NOT_START_GENUS_INNOVUS_OR_EDIT_OA"
    false
fi
