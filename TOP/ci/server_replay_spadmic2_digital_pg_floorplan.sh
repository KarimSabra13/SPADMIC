#!/usr/bin/env bash

###############################################################################
# Processor-only replay of sealed SPADMIC2 assembly and digital-PG evidence.
# Usage:
#   bash TOP/ci/server_replay_spadmic2_digital_pg_floorplan.sh \
#     <expected-head> \
#     <sealed-assembly-audit-root> <expected-assembly-archive-sha256> \
#     <sealed-pg-probe-root> <expected-pg-archive-sha256>
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

SOURCE_RAW="$SOURCE_ROOT/raw_oa_export"
SOURCE_STATUS="$SOURCE_ROOT/processed_contract/assembly_audit_status.rpt"
PG_RAW="$PG_ROOT/raw_oa_probe"
PG_PROCESSED="$PG_ROOT/processed_classification"
PG_EVIDENCE_STATUS="$PG_ROOT/pg_access_probe_evidence_status.rpt"
CLASSIFIER="$REPO/TOP/pnr/scripts/classify_spadmic2_digital_pg_access.py"
CONTRACT="$REPO/TOP/pnr/assembly/spadmic_digital_assembly_contract.json"
WRAPPER="$REPO/TOP/ci/server_replay_spadmic2_digital_pg_floorplan.sh"
REPLAY_PARENT="${PG_ROOT%/*}"
RUN_ID="$(date +%Y%m%d_%H%M%S)_pid$$"
REPLAY_ROOT="$REPLAY_PARENT/spadmic2_digital_pg_floorplan_replay_$RUN_ID"
STATUS_REPORT="$REPLAY_ROOT/digital_pg_access_status.rpt"

CD_RC=1
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
SHA256SUM_BIN=UNKNOWN
TAR_BIN=UNKNOWN
CHMOD_BIN=UNKNOWN
WRAPPER_SHA256=UNKNOWN
CLASSIFIER_SHA256=UNKNOWN
CONTRACT_SHA256=UNKNOWN
ACTIVE_CLASSIFIER=UNKNOWN
SOURCE_FILE_GATE_RC=1
PG_FILE_GATE_RC=1
SOURCE_STATUS_GATE_RC=1
PG_STATUS_GATE_RC=1
SOURCE_MANIFEST_PRE_RC=NOT_RUN
SOURCE_RAW_MANIFEST_PRE_RC=NOT_RUN
PG_MANIFEST_PRE_RC=NOT_RUN
PG_RAW_MANIFEST_PRE_RC=NOT_RUN
PG_PROCESSED_MANIFEST_PRE_RC=NOT_RUN
SOURCE_ARCHIVE_DETACHED_HASH_RC=NOT_RUN
SOURCE_ARCHIVE_EXPECTED_HASH_RC=NOT_RUN
SOURCE_ARCHIVE_TAR_RC=NOT_RUN
PG_ARCHIVE_DETACHED_HASH_RC=NOT_RUN
PG_ARCHIVE_EXPECTED_HASH_RC=NOT_RUN
PG_ARCHIVE_TAR_RC=NOT_RUN
SOURCE_READ_ONLY_RC=1
PG_READ_ONLY_RC=1
PREFLIGHT_RC=1
REPLAY_MKDIR_RC=NOT_RUN
PROCESS_RC=NOT_RUN
STATUS_GATE_RC=1
REPLAY_MANIFEST_PRE_SEAL_RC=NOT_RUN
REPLAY_SEAL_RC=NOT_RUN
REPLAY_READ_ONLY_RC=1
REPLAY_MANIFEST_POST_SEAL_RC=NOT_RUN
SOURCE_MANIFEST_POST_RC=NOT_RUN
SOURCE_RAW_MANIFEST_POST_RC=NOT_RUN
PG_MANIFEST_POST_RC=NOT_RUN
PG_RAW_MANIFEST_POST_RC=NOT_RUN
PG_PROCESSED_MANIFEST_POST_RC=NOT_RUN
SOURCE_READ_ONLY_POST_RC=1
PG_READ_ONLY_POST_RC=1
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
            echo "MISSING_STATUS_LINE=$report|$expected"
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
        WRAPPER_SHA256="$(
            "$SHA256SUM_BIN" "$WRAPPER" 2>/dev/null |
                awk '{print $1}'
        )"
        CLASSIFIER_SHA256="$(
            "$SHA256SUM_BIN" "$CLASSIFIER" 2>/dev/null |
                awk '{print $1}'
        )"
        CONTRACT_SHA256="$(
            "$SHA256SUM_BIN" "$CONTRACT" 2>/dev/null |
                awk '{print $1}'
        )"
    fi
    ACTIVE_CLASSIFIER="$(
        pgrep -af '[c]lassify_spadmic2_digital_pg_access\.py' 2>/dev/null
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
    "$SOURCE_STATUS" \
    "$SOURCE_RAW/SHA256SUMS" \
    "$SOURCE_RAW/spadmic2_instances.tsv" \
    "$SOURCE_RAW/spadmic2_top_shapes.tsv"
do
    if [ ! -r "$REQUIRED" ]; then
        echo "MISSING_SOURCE_FILE=$REQUIRED"
        SOURCE_FILE_GATE_RC=1
    fi
done

PG_FILE_GATE_RC=0
for REQUIRED in \
    "$PG_ROOT/SHA256SUMS" \
    "$PG_ROOT/evidence_payload.tar.gz" \
    "$PG_ROOT/evidence_payload.tar.gz.sha256" \
    "$PG_EVIDENCE_STATUS" \
    "$PG_RAW/SHA256SUMS" \
    "$PG_RAW/virtuoso_export_status.rpt" \
    "$PG_RAW/source_identity.tsv" \
    "$PG_RAW/supply_top_shapes.tsv" \
    "$PG_RAW/supply_top_terminals.tsv" \
    "$PG_RAW/supply_instance_pins.tsv" \
    "$PG_RAW/direct_mettp_shapes.tsv" \
    "$PG_PROCESSED/SHA256SUMS" \
    "$PG_PROCESSED/digital_pg_access_status.rpt" \
    "$CLASSIFIER" \
    "$CONTRACT" \
    "$WRAPPER"
do
    if [ ! -r "$REQUIRED" ]; then
        echo "MISSING_PG_FILE=$REQUIRED"
        PG_FILE_GATE_RC=1
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
    'STATUS=FAIL' \
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
require_status_lines "$PG_RAW/virtuoso_export_status.rpt" \
    'STATUS=PASS' \
    'SOURCE_MUTATION_AUTHORIZED=NO' \
    'OA_EDIT_AUTHORIZED=NO' \
    'INSTANCE_TERMINAL_ENUMERATION_POLICY=MASTER_TERMINALS_WITH_OPTIONAL_INSTTERM_CONNECTIVITY_AND_TRANSFORM_PROVENANCE_V2' \
    'INSTANCE_TRANSFORM_POLICY=DB_TRANSFORM_OR_BBOX_VERIFIED_XY_ORIENT_UNIT_MAG_STANDARD_INSTANCE' \
    'UNAVAILABLE_TRANSFORM_POLICY=MASTER_LOCAL_ONLY_NOT_A_CANDIDATE'
PG_RAW_STATUS_RC=$?
require_status_lines "$PG_PROCESSED/digital_pg_access_status.rpt" \
    'STATUS=PASS' \
    'SOURCE_IDENTITY_GATE_STATUS=PASS' \
    'SOURCE_TO_LOCAL_PG_MAPPING_STATUS=PASS' \
    'LOCAL_VDD_NET=VDD' \
    'CHIP_VDD_NET=DVDD' \
    'LOCAL_VSS_NET=VSS' \
    'CHIP_VSS_NET=DVSS' \
    'INSTANCE_PIN_CHIP_PG_METTP_CANDIDATE_STATUS=PASS' \
    'REVIEW_CANDIDATE_COUNT=4' \
    'P00_P02_IMPLEMENTATION_AUTHORIZED=NO' \
    'P03_IMPLEMENTATION_AUTHORIZED=NO'
PG_PROCESSED_STATUS_RC=$?
if [ "$PG_EVIDENCE_STATUS_RC" = "0" ] && \
   [ "$PG_RAW_STATUS_RC" = "0" ] && \
   [ "$PG_PROCESSED_STATUS_RC" = "0" ]; then
    PG_STATUS_GATE_RC=0
fi

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

    (
        cd "$SOURCE_ROOT"
        SOURCE_ARCHIVE_CD_RC=$?
        if [ "$SOURCE_ARCHIVE_CD_RC" = "0" ]; then
            "$SHA256SUM_BIN" -c evidence_payload.tar.gz.sha256
        else
            false
        fi
    ) >/dev/null
    SOURCE_ARCHIVE_DETACHED_HASH_RC=$?
    ACTUAL_SOURCE_ARCHIVE_SHA256="$(
        "$SHA256SUM_BIN" "$SOURCE_ROOT/evidence_payload.tar.gz" 2>/dev/null |
            awk '{print $1}'
    )"
    if [ "$ACTUAL_SOURCE_ARCHIVE_SHA256" = \
         "$EXPECTED_SOURCE_ARCHIVE_SHA256" ]; then
        SOURCE_ARCHIVE_EXPECTED_HASH_RC=0
    else
        SOURCE_ARCHIVE_EXPECTED_HASH_RC=1
    fi

    (
        cd "$PG_ROOT"
        PG_ARCHIVE_CD_RC=$?
        if [ "$PG_ARCHIVE_CD_RC" = "0" ]; then
            "$SHA256SUM_BIN" -c evidence_payload.tar.gz.sha256
        else
            false
        fi
    ) >/dev/null
    PG_ARCHIVE_DETACHED_HASH_RC=$?
    ACTUAL_PG_ARCHIVE_SHA256="$(
        "$SHA256SUM_BIN" "$PG_ROOT/evidence_payload.tar.gz" 2>/dev/null |
            awk '{print $1}'
    )"
    if [ "$ACTUAL_PG_ARCHIVE_SHA256" = "$EXPECTED_PG_ARCHIVE_SHA256" ]; then
        PG_ARCHIVE_EXPECTED_HASH_RC=0
    else
        PG_ARCHIVE_EXPECTED_HASH_RC=1
    fi
else
    SOURCE_MANIFEST_PRE_RC=1
    SOURCE_RAW_MANIFEST_PRE_RC=1
    PG_MANIFEST_PRE_RC=1
    PG_RAW_MANIFEST_PRE_RC=1
    PG_PROCESSED_MANIFEST_PRE_RC=1
    SOURCE_ARCHIVE_DETACHED_HASH_RC=1
    SOURCE_ARCHIVE_EXPECTED_HASH_RC=1
    PG_ARCHIVE_DETACHED_HASH_RC=1
    PG_ARCHIVE_EXPECTED_HASH_RC=1
    ACTUAL_SOURCE_ARCHIVE_SHA256=UNKNOWN
    ACTUAL_PG_ARCHIVE_SHA256=UNKNOWN
fi

if [ -n "$TAR_BIN" ] && [ -x "$TAR_BIN" ]; then
    "$TAR_BIN" -tzf "$SOURCE_ROOT/evidence_payload.tar.gz" >/dev/null 2>&1
    SOURCE_ARCHIVE_TAR_RC=$?
    "$TAR_BIN" -tzf "$PG_ROOT/evidence_payload.tar.gz" >/dev/null 2>&1
    PG_ARCHIVE_TAR_RC=$?
else
    SOURCE_ARCHIVE_TAR_RC=1
    PG_ARCHIVE_TAR_RC=1
fi

SOURCE_WRITABLE_PATH="$(
    find "$SOURCE_ROOT" -perm /222 -print -quit 2>/dev/null
)"
SOURCE_READ_ONLY_FIND_RC=$?
if [ "$SOURCE_READ_ONLY_FIND_RC" = "0" ] && \
   [ -z "$SOURCE_WRITABLE_PATH" ]; then
    SOURCE_READ_ONLY_RC=0
fi
PG_WRITABLE_PATH="$(
    find "$PG_ROOT" -perm /222 -print -quit 2>/dev/null
)"
PG_READ_ONLY_FIND_RC=$?
if [ "$PG_READ_ONLY_FIND_RC" = "0" ] && [ -z "$PG_WRITABLE_PATH" ]; then
    PG_READ_ONLY_RC=0
fi

if [ "$CD_RC" = "0" ] && \
   [ "$ACTUAL_HEAD" = "$EXPECTED_HEAD" ] && \
   [ "$TRACKED_DIFF_RC" = "0" ] && \
   [ "$STAGED_DIFF_RC" = "0" ] && \
   [ "$SOURCE_FILE_GATE_RC" = "0" ] && \
   [ "$PG_FILE_GATE_RC" = "0" ] && \
   [ "$SOURCE_STATUS_GATE_RC" = "0" ] && \
   [ "$PG_STATUS_GATE_RC" = "0" ] && \
   [ "$SOURCE_MANIFEST_PRE_RC" = "0" ] && \
   [ "$SOURCE_RAW_MANIFEST_PRE_RC" = "0" ] && \
   [ "$PG_MANIFEST_PRE_RC" = "0" ] && \
   [ "$PG_RAW_MANIFEST_PRE_RC" = "0" ] && \
   [ "$PG_PROCESSED_MANIFEST_PRE_RC" = "0" ] && \
   [ "$SOURCE_ARCHIVE_DETACHED_HASH_RC" = "0" ] && \
   [ "$SOURCE_ARCHIVE_EXPECTED_HASH_RC" = "0" ] && \
   [ "$SOURCE_ARCHIVE_TAR_RC" = "0" ] && \
   [ "$PG_ARCHIVE_DETACHED_HASH_RC" = "0" ] && \
   [ "$PG_ARCHIVE_EXPECTED_HASH_RC" = "0" ] && \
   [ "$PG_ARCHIVE_TAR_RC" = "0" ] && \
   [ "$SOURCE_READ_ONLY_RC" = "0" ] && \
   [ "$PG_READ_ONLY_RC" = "0" ] && \
   [ -n "$CHMOD_BIN" ] && [ -x "$CHMOD_BIN" ] && \
   [ -z "$ACTIVE_CLASSIFIER" ]; then
    PREFLIGHT_RC=0
fi

echo
echo "EXPECTED_HEAD=$EXPECTED_HEAD"
echo "ACTUAL_HEAD=$ACTUAL_HEAD"
echo "TRACKED_DIFF_RC=$TRACKED_DIFF_RC"
echo "STAGED_DIFF_RC=$STAGED_DIFF_RC"
echo "WRAPPER_SHA256=$WRAPPER_SHA256"
echo "CLASSIFIER_SHA256=$CLASSIFIER_SHA256"
echo "CONTRACT_SHA256=$CONTRACT_SHA256"
echo "ACTIVE_CLASSIFIER=${ACTIVE_CLASSIFIER:-NONE}"
echo "SOURCE_ROOT=$SOURCE_ROOT"
echo "EXPECTED_SOURCE_ARCHIVE_SHA256=$EXPECTED_SOURCE_ARCHIVE_SHA256"
echo "ACTUAL_SOURCE_ARCHIVE_SHA256=$ACTUAL_SOURCE_ARCHIVE_SHA256"
echo "PG_ROOT=$PG_ROOT"
echo "EXPECTED_PG_ARCHIVE_SHA256=$EXPECTED_PG_ARCHIVE_SHA256"
echo "ACTUAL_PG_ARCHIVE_SHA256=$ACTUAL_PG_ARCHIVE_SHA256"
echo "SOURCE_STATUS_GATE_RC=$SOURCE_STATUS_GATE_RC"
echo "PG_STATUS_GATE_RC=$PG_STATUS_GATE_RC"
echo "SOURCE_MANIFEST_PRE_RC=$SOURCE_MANIFEST_PRE_RC"
echo "SOURCE_RAW_MANIFEST_PRE_RC=$SOURCE_RAW_MANIFEST_PRE_RC"
echo "PG_MANIFEST_PRE_RC=$PG_MANIFEST_PRE_RC"
echo "PG_RAW_MANIFEST_PRE_RC=$PG_RAW_MANIFEST_PRE_RC"
echo "PG_PROCESSED_MANIFEST_PRE_RC=$PG_PROCESSED_MANIFEST_PRE_RC"
echo "SOURCE_WRITABLE_PATH=${SOURCE_WRITABLE_PATH:-NONE}"
echo "PG_WRITABLE_PATH=${PG_WRITABLE_PATH:-NONE}"
echo "PREFLIGHT_RC=$PREFLIGHT_RC"

if [ "$PREFLIGHT_RC" = "0" ]; then
    mkdir "$REPLAY_ROOT"
    REPLAY_MKDIR_RC=$?
    if [ "$REPLAY_MKDIR_RC" = "0" ]; then
        python3 "$CLASSIFIER" \
            --probe-root "$PG_RAW" \
            --source-audit-root "$SOURCE_ROOT" \
            --out "$REPLAY_ROOT" \
            --contract "$CONTRACT"
        PROCESS_RC=$?
    fi
else
    echo "STOP_HERE_FLOORPLAN_REPLAY_NOT_RUN=PREFLIGHT_FAILED"
fi

require_status_lines "$STATUS_REPORT" \
    'STATUS=PASS' \
    'RESULT=PG_ACCESS_EVIDENCE_READY_FOR_REVIEW' \
    'ASSEMBLY_FLOORPLAN_MODEL_STATUS=PASS' \
    'ASSEMBLY_BOUNDARY_INSTANCE=I5' \
    'ASSEMBLY_BOUNDARY_MASTER=SPADMIC/BOX_RING2/layout' \
    'ASSEMBLY_BOUNDARY_ORIENT=R0' \
    'ASSEMBLY_BOUNDARY_POLICY=HOLLOW_PAD_RING_REFERENCE' \
    'ASSEMBLY_COORDINATE_POLICY=NORMALIZE_TO_BOUNDARY_INSTANCE_LOWER_LEFT' \
    'ASSEMBLY_NORMALIZED_DIE_BBOX_UM=0.000000 0.000000 4116.031000 3740.792000' \
    'SOURCE_TO_ASSEMBLY_TRANSLATION_UM=0.240000 287.715000' \
    'ASSEMBLY_TO_SOURCE_TRANSLATION_UM=-0.240000 -287.715000' \
    'ASSEMBLY_CORE_KEEPOUT_UM=164.000000' \
    'SOURCE_INSTANCES_SHA256=9dc5e18abadd3b3d38fb43347ff11486ec8c1b13f194bf070dd6ac5957709360' \
    'ASSEMBLY_FIXED_OBSTACLE_COUNT=13' \
    'ASSEMBLY_CORE_OVERLAP_OBSTACLE_COUNT=13' \
    'ASSEMBLY_VERIFIED_INTERIOR_WHITESPACE_RECT_COUNT=62' \
    'ASSEMBLY_PRIMARY_WHITESPACE_SOURCE_BBOX_UM=3662.535000 -123.715000 3951.791000 3289.077000' \
    'ASSEMBLY_PRIMARY_WHITESPACE_NORMALIZED_BBOX_UM=3662.775000 164.000000 3952.031000 3576.792000' \
    'ASSEMBLY_PRIMARY_WHITESPACE_AREA_UM2=987170.562752' \
    'ASSEMBLY_FLOORPLAN_BOUNDARY_SHA256=c853a86f2f162d89d4466b7adc11b9d3794a2c120541ec39afe59ff0be45a1e7' \
    'ASSEMBLY_FIXED_OBSTACLES_SHA256=06bddfa61ecad1b4d7017d3a3a9cd96fb562db57cd1e27952f37635a7c3c5562' \
    'ASSEMBLY_VERIFIED_WHITESPACE_SHA256=846b03a9ba27a4843a94e8b6c8436f2cfbbee529e4723f09328878911597fb66' \
    'COMPLETE_SAME_INSTANCE_PG_PAIR_STATUS=PASS' \
    'REVIEW_CANDIDATE_PAIR_INSTANCE=I6' \
    'REVIEW_CANDIDATE_PAIR_OWNER_SCOPE=INSTANCE' \
    'TARGET_INSTANCE_METTP_CONTEXT_STATUS=NOT_PROBED' \
    'BRIDGE_GEOMETRY_STATUS=NOT_AUTHORIZED' \
    'P00_P02_IMPLEMENTATION_AUTHORIZED=NO' \
    'P03_IMPLEMENTATION_AUTHORIZED=NO' \
    'NEXT_GATE=RUN_READ_ONLY_SELECTED_INSTANCE_METTP_CORRIDOR_PROBE'
STATUS_GATE_RC=$?

if [ "$PROCESS_RC" = "0" ] && \
   [ "$STATUS_GATE_RC" = "0" ] && \
   [ -r "$REPLAY_ROOT/SHA256SUMS" ]; then
    verify_manifest "$REPLAY_ROOT" "$REPLAY_ROOT/SHA256SUMS" >/dev/null
    REPLAY_MANIFEST_PRE_SEAL_RC=$?
else
    REPLAY_MANIFEST_PRE_SEAL_RC=1
fi

if [ "$REPLAY_MANIFEST_PRE_SEAL_RC" = "0" ]; then
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
verify_manifest "$SOURCE_RAW" "$SOURCE_RAW/SHA256SUMS" >/dev/null
SOURCE_RAW_MANIFEST_POST_RC=$?
verify_manifest "$PG_ROOT" "$PG_ROOT/SHA256SUMS" >/dev/null
PG_MANIFEST_POST_RC=$?
verify_manifest "$PG_RAW" "$PG_RAW/SHA256SUMS" >/dev/null
PG_RAW_MANIFEST_POST_RC=$?
verify_manifest "$PG_PROCESSED" "$PG_PROCESSED/SHA256SUMS" >/dev/null
PG_PROCESSED_MANIFEST_POST_RC=$?

SOURCE_WRITABLE_PATH_POST="$(
    find "$SOURCE_ROOT" -perm /222 -print -quit 2>/dev/null
)"
SOURCE_READ_ONLY_POST_FIND_RC=$?
if [ "$SOURCE_READ_ONLY_POST_FIND_RC" = "0" ] && \
   [ -z "$SOURCE_WRITABLE_PATH_POST" ]; then
    SOURCE_READ_ONLY_POST_RC=0
fi
PG_WRITABLE_PATH_POST="$(
    find "$PG_ROOT" -perm /222 -print -quit 2>/dev/null
)"
PG_READ_ONLY_POST_FIND_RC=$?
if [ "$PG_READ_ONLY_POST_FIND_RC" = "0" ] && \
   [ -z "$PG_WRITABLE_PATH_POST" ]; then
    PG_READ_ONLY_POST_RC=0
fi

echo
echo "REPLAY_ROOT=$REPLAY_ROOT"
echo "REPLAY_MKDIR_RC=$REPLAY_MKDIR_RC"
echo "PROCESS_RC=$PROCESS_RC"
echo "STATUS_GATE_RC=$STATUS_GATE_RC"
echo "REPLAY_MANIFEST_PRE_SEAL_RC=$REPLAY_MANIFEST_PRE_SEAL_RC"
echo "REPLAY_SEAL_RC=$REPLAY_SEAL_RC"
echo "REPLAY_WRITABLE_PATH=${REPLAY_WRITABLE_PATH:-NONE}"
echo "REPLAY_MANIFEST_POST_SEAL_RC=$REPLAY_MANIFEST_POST_SEAL_RC"
echo "SOURCE_MANIFEST_POST_RC=$SOURCE_MANIFEST_POST_RC"
echo "SOURCE_RAW_MANIFEST_POST_RC=$SOURCE_RAW_MANIFEST_POST_RC"
echo "PG_MANIFEST_POST_RC=$PG_MANIFEST_POST_RC"
echo "PG_RAW_MANIFEST_POST_RC=$PG_RAW_MANIFEST_POST_RC"
echo "PG_PROCESSED_MANIFEST_POST_RC=$PG_PROCESSED_MANIFEST_POST_RC"
echo "SOURCE_WRITABLE_PATH_POST=${SOURCE_WRITABLE_PATH_POST:-NONE}"
echo "PG_WRITABLE_PATH_POST=${PG_WRITABLE_PATH_POST:-NONE}"

for REPORT in \
    "$STATUS_REPORT" \
    "$REPLAY_ROOT/assembly_floorplan_boundary.tsv" \
    "$REPLAY_ROOT/assembly_verified_whitespace_normalized.tsv" \
    "$REPLAY_ROOT/digital_pg_pair_ranking.tsv" \
    "$REPLAY_ROOT/digital_pg_review_pair.tsv"
do
    echo
    echo "===== $REPORT ====="
    if [ -r "$REPORT" ]; then
        cat "$REPORT"
    else
        echo "MISSING=$REPORT"
    fi
done

if [ "$PREFLIGHT_RC" = "0" ] && \
   [ "$PROCESS_RC" = "0" ] && \
   [ "$STATUS_GATE_RC" = "0" ] && \
   [ "$REPLAY_MANIFEST_PRE_SEAL_RC" = "0" ] && \
   [ "$REPLAY_SEAL_RC" = "0" ] && \
   [ "$REPLAY_READ_ONLY_RC" = "0" ] && \
   [ "$REPLAY_MANIFEST_POST_SEAL_RC" = "0" ] && \
   [ "$SOURCE_MANIFEST_POST_RC" = "0" ] && \
   [ "$SOURCE_RAW_MANIFEST_POST_RC" = "0" ] && \
   [ "$PG_MANIFEST_POST_RC" = "0" ] && \
   [ "$PG_RAW_MANIFEST_POST_RC" = "0" ] && \
   [ "$PG_PROCESSED_MANIFEST_POST_RC" = "0" ] && \
   [ "$SOURCE_READ_ONLY_POST_RC" = "0" ] && \
   [ "$PG_READ_ONLY_POST_RC" = "0" ]; then
    REPLAY_STATUS=PASS_EVIDENCE_READY
fi

echo
echo "PROCESSOR_ONLY_DIGITAL_PG_FLOORPLAN_REPLAY_STATUS=$REPLAY_STATUS"
if [ "$REPLAY_STATUS" = "PASS_EVIDENCE_READY" ]; then
    echo "NEXT_GATE=RUN_READ_ONLY_SELECTED_INSTANCE_METTP_CORRIDOR_PROBE"
    echo "DO_NOT_START_CADENCE_GENUS_INNOVUS_OR_EDIT_OA"
    true
else
    echo "STOP_HERE_DO_NOT_START_CADENCE_GENUS_INNOVUS_OR_EDIT_OA"
    false
fi
