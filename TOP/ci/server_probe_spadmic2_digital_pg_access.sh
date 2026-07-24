#!/usr/bin/env bash

###############################################################################
# One foreground, read-only SPADMIC2 DVDD/DVSS access probe.
# Usage:
#   bash TOP/ci/server_probe_spadmic2_digital_pg_access.sh \
#     <expected-head> <sealed-assembly-audit-root> <expected-archive-sha256>
###############################################################################

set +e

REPO="${SPADMIC_REPO:-/home/validmgr/ksabra/2026_SPAD/SPADMIC}"
EXPECTED_HEAD="${1:-MISSING}"
SOURCE_ROOT="${2:-MISSING}"
SOURCE_ROOT="${SOURCE_ROOT%/}"
EXPECTED_ARCHIVE_SHA256="${3:-MISSING}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
CADENCE_LAUNCH_DIR="${SPADMIC_CADENCE_LAUNCH_DIR:-/group/validmgr/PROJET/Prj_xh018/ksabra/cds_V0}"
CADENCE_CDS_LIB="$CADENCE_LAUNCH_DIR/cds.lib"
TOP_OA_PATH=/group/validmgr/PROJET/Prj_xh018/ksabra/cds/design/SPADMIC2/layout
RAW_SOURCE_ROOT="$SOURCE_ROOT/raw_oa_export"
SOURCE_CONTRACT_REPORT="$SOURCE_ROOT/processed_contract/assembly_audit_status.rpt"
WRAPPER="$REPO/TOP/ci/server_probe_spadmic2_digital_pg_access.sh"
CONTRACT="$REPO/TOP/pnr/assembly/spadmic_digital_assembly_contract.json"
PROBE_SKILL="$REPO/TOP/pnr/scripts/probe_spadmic2_digital_pg_access.il"
CLASSIFIER="$REPO/TOP/pnr/scripts/classify_spadmic2_digital_pg_access.py"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RUN_ID="${TIMESTAMP}_pid$$"
DIAGNOSTIC_PARENT="$WORK_ROOT/diagnostics"
DIAGNOSTIC_ROOT="$DIAGNOSTIC_PARENT/spadmic2_digital_pg_access_probe_$RUN_ID"
RAW_ROOT="$DIAGNOSTIC_ROOT/raw_oa_probe"
PROCESSED_ROOT="$DIAGNOSTIC_ROOT/processed_classification"
SESSION_CDS_LIB="$DIAGNOSTIC_ROOT/spadmic2_session.cds.lib"
PROBE_LOG="$DIAGNOSTIC_ROOT/virtuoso_spadmic2_pg_access.log"
CHECKSUM_SELFTEST_ROOT="$DIAGNOSTIC_ROOT/checksum_selftest"
RECOVERY_ARCHIVE="$DIAGNOSTIC_ROOT/evidence_payload.tar.gz"
RECOVERY_ARCHIVE_SHA256_FILE="$RECOVERY_ARCHIVE.sha256"
RECOVERY_ARCHIVE_FILELIST="$DIAGNOSTIC_ROOT/evidence_payload_filelist.txt"
EVIDENCE_STATUS="$DIAGNOSTIC_ROOT/pg_access_probe_evidence_status.rpt"
EXPECTED_CHECKSUM_SELFTEST_SHA256=8f07d5176d42a4f11c17a591edc7e38026d0b4e4a31366b9e5a807b5e70cecd5
REEXECUTED="${SPADMIC_PG_PROBE_REEXECUTED:-0}"

RUN_OK=1
CD_RC=1
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ENTRY_HEAD=UNKNOWN
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
REEXEC_EXEC_RC=NOT_RUN
SOURCE_FILE_GATE_RC=1
SOURCE_SEAL_STATUS_RC=1
SOURCE_STABILITY_STATUS_RC=1
SOURCE_CONTRACT_STATUS_RC=1
SOURCE_MANIFEST_PRE_RC=NOT_RUN
SOURCE_RAW_MANIFEST_PRE_RC=NOT_RUN
ARCHIVE_HASH_RC=NOT_RUN
ARCHIVE_EXPECTED_HASH_RC=NOT_RUN
ARCHIVE_TAR_RC=NOT_RUN
SOURCE_READ_ONLY_RC=1
CADENCE_GATE_RC=1
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
RAW_MANIFEST_POST_ARCHIVE_RC=NOT_RUN
PROCESSED_MANIFEST_POST_ARCHIVE_RC=NOT_RUN
RECOVERY_ARCHIVE_FILELIST_RC=NOT_RUN
RECOVERY_ARCHIVE_CREATE_RC=NOT_RUN
RECOVERY_ARCHIVE_TAR_VERIFY_RC=NOT_RUN
RECOVERY_ARCHIVE_HASH_CREATE_RC=NOT_RUN
RECOVERY_ARCHIVE_HASH_VERIFY_RC=NOT_RUN
RECOVERY_ARCHIVE_SHA256=UNKNOWN
SOURCE_INVENTORY_POST_RC=NOT_RUN
SOURCE_STABILITY_RC=NOT_RUN
SOURCE_MANIFEST_POST_RC=NOT_RUN
SOURCE_RAW_MANIFEST_POST_RC=NOT_RUN
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

    if [ "$SELFTEST_PAYLOAD_CREATE_RC" = "0" ] && \
       [ "$manifest_create_rc" = "0" ] && \
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

if [ "$EXPECTED_HEAD" = "MISSING" ] || \
   [ "$SOURCE_ROOT" = "MISSING" ] || \
   [ "$EXPECTED_ARCHIVE_SHA256" = "MISSING" ]; then
    echo "STOP_HERE_PG_ACCESS_PROBE_NOT_RUN=REQUIRED_ARGUMENT_MISSING"
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
        export SPADMIC_PG_PROBE_REEXECUTED=1
        exec bash "$REPO/TOP/ci/server_probe_spadmic2_digital_pg_access.sh" \
            "$EXPECTED_HEAD" \
            "$SOURCE_ROOT" \
            "$EXPECTED_ARCHIVE_SHA256"
        REEXEC_EXEC_RC=$?
        RUN_OK=0
    else
        echo "STOP_HERE_PG_ACCESS_PROBE_NOT_RUN=CHECKOUT_CHANGED_TWICE"
        RUN_OK=0
    fi
fi

SOURCE_FILE_GATE_RC=0
for REQUIRED in \
    "$SOURCE_ROOT/SHA256SUMS" \
    "$SOURCE_ROOT/evidence_seal_status.rpt" \
    "$SOURCE_ROOT/evidence_payload.tar.gz" \
    "$SOURCE_ROOT/evidence_payload.tar.gz.sha256" \
    "$SOURCE_ROOT/source_stability_status.rpt" \
    "$SOURCE_CONTRACT_REPORT" \
    "$RAW_SOURCE_ROOT/SHA256SUMS" \
    "$RAW_SOURCE_ROOT/spadmic2_virtuoso_export_status.rpt" \
    "$RAW_SOURCE_ROOT/spadmic2_top_shapes.tsv" \
    "$SOURCE_ROOT/processed_contract/verified_digital_whitespace.tsv" \
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
require_status_lines "$SOURCE_CONTRACT_REPORT" \
    'SOURCE_IDENTITY_GATE_STATUS=PASS' \
    'EXACT_MATRICE5_INSTANCE_GATE_STATUS=PASS' \
    'P03_INTERFACE_CONTRACT_STATUS=PASS' \
    'PG_ANCHOR_GATE_STATUS=FAIL' \
    'P00_P02_IMPLEMENTATION_AUTHORIZED=NO' \
    'P03_IMPLEMENTATION_AUTHORIZED=NO'
SOURCE_CONTRACT_STATUS_RC=$?

if [ -n "$SHA256SUM_BIN" ] && [ -x "$SHA256SUM_BIN" ]; then
    verify_manifest "$SOURCE_ROOT" "$SOURCE_ROOT/SHA256SUMS" >/dev/null
    SOURCE_MANIFEST_PRE_RC=$?
    verify_manifest "$RAW_SOURCE_ROOT" "$RAW_SOURCE_ROOT/SHA256SUMS" >/dev/null
    SOURCE_RAW_MANIFEST_PRE_RC=$?
    (
        cd "$SOURCE_ROOT"
        ARCHIVE_CD_RC=$?
        if [ "$ARCHIVE_CD_RC" = "0" ]; then
            "$SHA256SUM_BIN" -c evidence_payload.tar.gz.sha256
        else
            false
        fi
    ) >/dev/null
    ARCHIVE_HASH_RC=$?
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
    SOURCE_RAW_MANIFEST_PRE_RC=1
    ARCHIVE_HASH_RC=1
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

CADENCE_GATE_RC=0
for TOOL in "$SHA256SUM_BIN" "$TAR_BIN" "$CHMOD_BIN" "$VIRTUOSO_BIN"; do
    if [ -z "$TOOL" ] || [ ! -x "$TOOL" ]; then
        CADENCE_GATE_RC=1
    fi
done
if [ "$CADENCE_GATE_RC" = "0" ]; then
    SHA256SUM_BIN_SHA256="$(
        "$SHA256SUM_BIN" "$SHA256SUM_BIN" 2>/dev/null |
            awk '{print $1}'
    )"
    WRAPPER_SHA256="$("$SHA256SUM_BIN" "$WRAPPER" | awk '{print $1}')"
    PROBE_SKILL_SHA256="$("$SHA256SUM_BIN" "$PROBE_SKILL" | awk '{print $1}')"
    CLASSIFIER_SHA256="$("$SHA256SUM_BIN" "$CLASSIFIER" | awk '{print $1}')"
    CONTRACT_SHA256="$("$SHA256SUM_BIN" "$CONTRACT" | awk '{print $1}')"
    for HASH in \
        "$SHA256SUM_BIN_SHA256" \
        "$WRAPPER_SHA256" \
        "$PROBE_SKILL_SHA256" \
        "$CLASSIFIER_SHA256" \
        "$CONTRACT_SHA256"
    do
        if [ -z "$HASH" ]; then
            CADENCE_GATE_RC=1
        fi
    done
fi
ACTIVE_PROBE="$(
    pgrep -af \
        '[v]irtuoso.*probe_spadmic2_digital_pg_access\.il|[c]lassify_spadmic2_digital_pg_access\.py' \
        2>/dev/null
)"

if [ "$RUN_OK" = "1" ] && \
   [ "$SOURCE_FILE_GATE_RC" = "0" ] && \
   [ "$SOURCE_SEAL_STATUS_RC" = "0" ] && \
   [ "$SOURCE_STABILITY_STATUS_RC" = "0" ] && \
   [ "$SOURCE_CONTRACT_STATUS_RC" = "0" ] && \
   [ "$SOURCE_MANIFEST_PRE_RC" = "0" ] && \
   [ "$SOURCE_RAW_MANIFEST_PRE_RC" = "0" ] && \
   [ "$ARCHIVE_HASH_RC" = "0" ] && \
   [ "$ARCHIVE_EXPECTED_HASH_RC" = "0" ] && \
   [ "$ARCHIVE_TAR_RC" = "0" ] && \
   [ "$SOURCE_READ_ONLY_RC" = "0" ] && \
   [ "$CADENCE_GATE_RC" = "0" ] && \
   [ -z "$ACTIVE_PROBE" ]; then
    mkdir "$DIAGNOSTIC_ROOT"
    DIAGNOSTIC_ROOT_CREATE_RC=$?
    if [ "$DIAGNOSTIC_ROOT_CREATE_RC" = "0" ]; then
        mkdir "$RAW_ROOT" "$PROCESSED_ROOT"
        PAYLOAD_DIR_CREATE_RC=$?
    else
        PAYLOAD_DIR_CREATE_RC=1
    fi
    if [ "$DIAGNOSTIC_ROOT_CREATE_RC" = "0" ] && \
       [ "$PAYLOAD_DIR_CREATE_RC" = "0" ]; then
        DIAGNOSTIC_CREATE_RC=0
        run_checksum_selftest
        CHECKSUM_SELFTEST_RC=$?
        if [ "$CHECKSUM_SELFTEST_RC" != "0" ]; then
            RUN_OK=0
        fi
    else
        DIAGNOSTIC_CREATE_RC=1
        RUN_OK=0
    fi
else
    echo "STOP_HERE_PG_ACCESS_PROBE_NOT_RUN=PREFLIGHT_FAILED"
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
    export SPADMIC_PG_PROBE_ROOT="$RAW_ROOT"
    export SPADMIC_PG_PROBE_LIBRARY=SPADMIC
    export SPADMIC_PG_PROBE_CELL=SPADMIC2
    export SPADMIC_PG_PROBE_VIEW=layout
    export SPADMIC_PG_SOURCE_PATH="$TOP_OA_PATH"
    export SPADMIC_PG_LOCAL_VDD=VDD
    export SPADMIC_PG_LOCAL_VSS=VSS
    export SPADMIC_PG_CHIP_VDD=DVDD
    export SPADMIC_PG_CHIP_VSS=DVSS
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
    "$RAW_ROOT/source_identity.tsv" \
    "$RAW_ROOT/supply_nets.tsv" \
    "$RAW_ROOT/supply_top_terminals.tsv" \
    "$RAW_ROOT/supply_top_shapes.tsv" \
    "$RAW_ROOT/supply_instance_pins.tsv" \
    "$RAW_ROOT/direct_mettp_shapes.tsv"
do
    if [ ! -s "$EXPORT" ]; then
        echo "MISSING_OR_EMPTY_PG_PROBE_EXPORT=$EXPORT"
        RAW_EXPORT_GATE_RC=1
    fi
done
require_status_lines "$RAW_ROOT/virtuoso_export_status.rpt" \
    'STATUS=PASS' \
    'SOURCE_MUTATION_AUTHORIZED=NO' \
    'OA_EDIT_AUTHORIZED=NO' \
    'INSTANCE_TERMINAL_ENUMERATION_POLICY=MASTER_TERMINALS_WITH_OPTIONAL_INSTTERM_CONNECTIVITY'
if [ "$?" != "0" ]; then
    RAW_EXPORT_GATE_RC=1
fi
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
        --source-audit-root "$SOURCE_ROOT" \
        --out "$PROCESSED_ROOT" \
        --contract "$CONTRACT"
    CLASSIFIER_RC=$?
fi

require_status_lines "$PROCESSED_ROOT/digital_pg_access_status.rpt" \
    'STATUS=PASS' \
    'RESULT=PG_ACCESS_EVIDENCE_READY_FOR_REVIEW' \
    'SOURCE_IDENTITY_GATE_STATUS=PASS' \
    'SOURCE_TO_LOCAL_PG_MAPPING_STATUS=PASS' \
    'LOCAL_VDD_NET=VDD' \
    'CHIP_VDD_NET=DVDD' \
    'LOCAL_VSS_NET=VSS' \
    'CHIP_VSS_NET=DVSS' \
    'INSTANCE_TERMINAL_ENUMERATION_POLICY=MASTER_TERMINALS_WITH_OPTIONAL_INSTTERM_CONNECTIVITY' \
    "PROCESSOR_SHA256=$CLASSIFIER_SHA256" \
    "CONTRACT_SHA256=$CONTRACT_SHA256" \
    'CANDIDATE_AUTHORIZATION=REVIEW_ONLY_NOT_AN_ASSEMBLY_ANCHOR' \
    'P00_P02_IMPLEMENTATION_AUTHORIZED=NO' \
    'P03_IMPLEMENTATION_AUTHORIZED=NO'
CLASSIFICATION_GATE_RC=$?
if [ "$CLASSIFIER_RC" = "0" ] && \
   [ "$CLASSIFICATION_GATE_RC" = "0" ]; then
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
    PROCESSED_MANIFEST_RC=1
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
else
    SOURCE_STABILITY_RC=1
fi

verify_manifest "$SOURCE_ROOT" "$SOURCE_ROOT/SHA256SUMS" >/dev/null
SOURCE_MANIFEST_POST_RC=$?
verify_manifest "$RAW_SOURCE_ROOT" "$RAW_SOURCE_ROOT/SHA256SUMS" >/dev/null
SOURCE_RAW_MANIFEST_POST_RC=$?

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
                ! -path './pg_access_probe_evidence_status.rpt' \
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
            ARCHIVE_CREATE_CD_RC=$?
            if [ "$ARCHIVE_CREATE_CD_RC" = "0" ]; then
                "$TAR_BIN" -czf evidence_payload.tar.gz \
                    -T evidence_payload_filelist.txt
            else
                false
            fi
        )
        RECOVERY_ARCHIVE_CREATE_RC=$?
    else
        RECOVERY_ARCHIVE_CREATE_RC=1
    fi
    if [ "$RECOVERY_ARCHIVE_CREATE_RC" = "0" ]; then
        "$TAR_BIN" -tzf "$RECOVERY_ARCHIVE" >/dev/null 2>&1
        RECOVERY_ARCHIVE_TAR_VERIFY_RC=$?
        (
            cd "$DIAGNOSTIC_ROOT"
            ARCHIVE_HASH_CD_RC=$?
            if [ "$ARCHIVE_HASH_CD_RC" = "0" ]; then
                "$SHA256SUM_BIN" evidence_payload.tar.gz \
                    > evidence_payload.tar.gz.sha256
            else
                false
            fi
        )
        RECOVERY_ARCHIVE_HASH_CREATE_RC=$?
    else
        RECOVERY_ARCHIVE_TAR_VERIFY_RC=1
        RECOVERY_ARCHIVE_HASH_CREATE_RC=1
    fi
    if [ "$RECOVERY_ARCHIVE_HASH_CREATE_RC" = "0" ]; then
        (
            cd "$DIAGNOSTIC_ROOT"
            ARCHIVE_VERIFY_CD_RC=$?
            if [ "$ARCHIVE_VERIFY_CD_RC" = "0" ]; then
                "$SHA256SUM_BIN" -c evidence_payload.tar.gz.sha256
            else
                false
            fi
        ) >/dev/null 2>&1
        RECOVERY_ARCHIVE_HASH_VERIFY_RC=$?
        RECOVERY_ARCHIVE_SHA256="$(
            "$SHA256SUM_BIN" "$RECOVERY_ARCHIVE" 2>/dev/null |
                awk '{print $1}'
        )"
    else
        RECOVERY_ARCHIVE_HASH_VERIFY_RC=1
    fi
    verify_manifest "$RAW_ROOT" "$RAW_ROOT/SHA256SUMS" >/dev/null
    RAW_MANIFEST_POST_ARCHIVE_RC=$?
    verify_manifest \
        "$PROCESSED_ROOT" \
        "$PROCESSED_ROOT/SHA256SUMS" \
        >/dev/null
    PROCESSED_MANIFEST_POST_ARCHIVE_RC=$?
fi

if [ "$RUN_OK" = "1" ] && \
   [ "$DIAGNOSTIC_CREATE_RC" = "0" ] && \
   [ "$CHECKSUM_SELFTEST_RC" = "0" ] && \
   [ "$VIRTUOSO_RC" = "0" ] && \
   [ "$RAW_EXPORT_GATE_RC" = "0" ] && \
   [ "$RAW_MANIFEST_CREATE_RC" = "0" ] && \
   [ "$RAW_MANIFEST_PRE_SEAL_RC" = "0" ] && \
   [ "$RAW_SEAL_RC" = "0" ] && \
   [ "$RAW_READ_ONLY_RC" = "0" ] && \
   [ "$CLASSIFIER_RC" = "0" ] && \
   [ "$CLASSIFICATION_GATE_RC" = "0" ] && \
   [ "$PROCESSED_MANIFEST_RC" = "0" ] && \
   [ "$PROCESSED_SEAL_RC" = "0" ] && \
   [ "$PROCESSED_READ_ONLY_RC" = "0" ] && \
   [ "$RAW_MANIFEST_POST_ARCHIVE_RC" = "0" ] && \
   [ "$PROCESSED_MANIFEST_POST_ARCHIVE_RC" = "0" ] && \
   [ "$RECOVERY_ARCHIVE_FILELIST_RC" = "0" ] && \
   [ "$RECOVERY_ARCHIVE_CREATE_RC" = "0" ] && \
   [ "$RECOVERY_ARCHIVE_TAR_VERIFY_RC" = "0" ] && \
   [ "$RECOVERY_ARCHIVE_HASH_CREATE_RC" = "0" ] && \
   [ "$RECOVERY_ARCHIVE_HASH_VERIFY_RC" = "0" ] && \
   [ "$SOURCE_STABILITY_RC" = "0" ] && \
   [ "$SOURCE_MANIFEST_POST_RC" = "0" ] && \
   [ "$SOURCE_RAW_MANIFEST_POST_RC" = "0" ]; then
    PRESEAL_GATE_RC=0
fi

if [ "$DIAGNOSTIC_CREATE_RC" = "0" ]; then
    {
        echo "LABEL=SPADMIC2_DIGITAL_PG_ACCESS_PROBE_EVIDENCE"
        echo "STATUS=$([ "$PRESEAL_GATE_RC" = "0" ] && echo PASS || echo FAIL)"
        echo "EXPECTED_HEAD=$EXPECTED_HEAD"
        echo "ACTUAL_HEAD=$ACTUAL_HEAD"
        echo "WRAPPER_SHA256=$WRAPPER_SHA256"
        echo "PROBE_SKILL_SHA256=$PROBE_SKILL_SHA256"
        echo "CLASSIFIER_SHA256=$CLASSIFIER_SHA256"
        echo "CONTRACT_SHA256=$CONTRACT_SHA256"
        echo "SHA256SUM_BIN=$SHA256SUM_BIN"
        echo "SHA256SUM_BIN_SHA256=$SHA256SUM_BIN_SHA256"
        echo "CHECKSUM_SELFTEST_RC=$CHECKSUM_SELFTEST_RC"
        echo "SOURCE_ROOT=$SOURCE_ROOT"
        echo "EXPECTED_ARCHIVE_SHA256=$EXPECTED_ARCHIVE_SHA256"
        echo "ACTUAL_ARCHIVE_SHA256=$ACTUAL_ARCHIVE_SHA256"
        echo "SOURCE_MANIFEST_PRE_RC=$SOURCE_MANIFEST_PRE_RC"
        echo "SOURCE_RAW_MANIFEST_PRE_RC=$SOURCE_RAW_MANIFEST_PRE_RC"
        echo "SOURCE_READ_ONLY_RC=$SOURCE_READ_ONLY_RC"
        echo "VIRTUOSO_RC=$VIRTUOSO_RC"
        echo "RAW_EXPORT_GATE_RC=$RAW_EXPORT_GATE_RC"
        echo "CLASSIFIER_RC=$CLASSIFIER_RC"
        echo "CLASSIFICATION_GATE_RC=$CLASSIFICATION_GATE_RC"
        echo "PROCESSED_SEAL_RC=$PROCESSED_SEAL_RC"
        echo "PROCESSED_READ_ONLY_RC=$PROCESSED_READ_ONLY_RC"
        echo "RAW_MANIFEST_POST_ARCHIVE_RC=$RAW_MANIFEST_POST_ARCHIVE_RC"
        echo "PROCESSED_MANIFEST_POST_ARCHIVE_RC=$PROCESSED_MANIFEST_POST_ARCHIVE_RC"
        echo "RECOVERY_ARCHIVE=$RECOVERY_ARCHIVE"
        echo "RECOVERY_ARCHIVE_SHA256=$RECOVERY_ARCHIVE_SHA256"
        echo "RECOVERY_ARCHIVE_SHA256_FILE=$RECOVERY_ARCHIVE_SHA256_FILE"
        echo "RECOVERY_ARCHIVE_FILELIST=$RECOVERY_ARCHIVE_FILELIST"
        echo "RECOVERY_ARCHIVE_FILELIST_RC=$RECOVERY_ARCHIVE_FILELIST_RC"
        echo "RECOVERY_ARCHIVE_CREATE_RC=$RECOVERY_ARCHIVE_CREATE_RC"
        echo "RECOVERY_ARCHIVE_TAR_VERIFY_RC=$RECOVERY_ARCHIVE_TAR_VERIFY_RC"
        echo "RECOVERY_ARCHIVE_HASH_CREATE_RC=$RECOVERY_ARCHIVE_HASH_CREATE_RC"
        echo "RECOVERY_ARCHIVE_HASH_VERIFY_RC=$RECOVERY_ARCHIVE_HASH_VERIFY_RC"
        echo "SOURCE_STABILITY_RC=$SOURCE_STABILITY_RC"
        echo "SOURCE_MANIFEST_POST_RC=$SOURCE_MANIFEST_POST_RC"
        echo "SOURCE_RAW_MANIFEST_POST_RC=$SOURCE_RAW_MANIFEST_POST_RC"
        echo "SOURCE_MUTATION_AUTHORIZED=NO"
        echo "OA_EDIT_AUTHORIZED=NO"
        echo "GENUS_EXECUTED=NO"
        echo "INNOVUS_EXECUTED=NO"
        echo "NEXT_GATE=RETURN_EXACT_DVDD_DVSS_ACCESS_EVIDENCE_FOR_REVIEW"
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
else
    OUTER_MANIFEST_CREATE_RC=1
    ROOT_SEAL_RC=1
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
else
    OUTER_MANIFEST_POST_SEAL_RC=1
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
echo "CHECKSUM_SELFTEST_RC=$CHECKSUM_SELFTEST_RC"
echo "SOURCE_ROOT=$SOURCE_ROOT"
echo "EXPECTED_ARCHIVE_SHA256=$EXPECTED_ARCHIVE_SHA256"
echo "ACTUAL_ARCHIVE_SHA256=$ACTUAL_ARCHIVE_SHA256"
echo "ACTIVE_PROBE=${ACTIVE_PROBE:-NONE}"
echo "SOURCE_MANIFEST_PRE_RC=$SOURCE_MANIFEST_PRE_RC"
echo "SOURCE_RAW_MANIFEST_PRE_RC=$SOURCE_RAW_MANIFEST_PRE_RC"
echo "SOURCE_READ_ONLY_PATH=${SOURCE_WRITABLE_PATH:-NONE}"
echo "VIRTUOSO_RC=$VIRTUOSO_RC"
echo "RAW_EXPORT_GATE_RC=$RAW_EXPORT_GATE_RC"
echo "CLASSIFIER_RC=$CLASSIFIER_RC"
echo "CLASSIFICATION_GATE_RC=$CLASSIFICATION_GATE_RC"
echo "PROCESSED_SEAL_RC=$PROCESSED_SEAL_RC"
echo "PROCESSED_READ_ONLY_RC=$PROCESSED_READ_ONLY_RC"
echo "RAW_MANIFEST_POST_ARCHIVE_RC=$RAW_MANIFEST_POST_ARCHIVE_RC"
echo "PROCESSED_MANIFEST_POST_ARCHIVE_RC=$PROCESSED_MANIFEST_POST_ARCHIVE_RC"
echo "RECOVERY_ARCHIVE_FILELIST_RC=$RECOVERY_ARCHIVE_FILELIST_RC"
echo "RECOVERY_ARCHIVE_CREATE_RC=$RECOVERY_ARCHIVE_CREATE_RC"
echo "RECOVERY_ARCHIVE_SHA256=$RECOVERY_ARCHIVE_SHA256"
echo "RECOVERY_ARCHIVE_TAR_VERIFY_RC=$RECOVERY_ARCHIVE_TAR_VERIFY_RC"
echo "RECOVERY_ARCHIVE_HASH_VERIFY_RC=$RECOVERY_ARCHIVE_HASH_VERIFY_RC"
echo "SOURCE_STABILITY_RC=$SOURCE_STABILITY_RC"
echo "SOURCE_MANIFEST_POST_RC=$SOURCE_MANIFEST_POST_RC"
echo "SOURCE_RAW_MANIFEST_POST_RC=$SOURCE_RAW_MANIFEST_POST_RC"
echo "DIAGNOSTIC_ROOT=$DIAGNOSTIC_ROOT"
echo "OUTER_MANIFEST_POST_SEAL_RC=$OUTER_MANIFEST_POST_SEAL_RC"
echo "WRITABLE_EVIDENCE_PATH=${ROOT_WRITABLE_PATH:-NONE}"

for REPORT in \
    "$PROCESSED_ROOT/digital_pg_access_status.rpt" \
    "$PROCESSED_ROOT/digital_pg_review_pair.tsv" \
    "$PROCESSED_ROOT/digital_pg_access_candidates.tsv" \
    "$PROCESSED_ROOT/digital_pg_access_layer_summary.tsv" \
    "$PROCESSED_ROOT/digital_pg_access_all_layers.tsv" \
    "$PROCESSED_ROOT/mettp_to_supply_access_context.tsv"
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
echo "READ_ONLY_DIGITAL_PG_ACCESS_PROBE_STATUS=$PROBE_STATUS"
if [ "$PROBE_STATUS" = "PASS_EVIDENCE_READY" ]; then
    echo "NEXT_GATE=RETURN_EXACT_DVDD_DVSS_ACCESS_EVIDENCE_FOR_REVIEW"
    echo "DO_NOT_START_GENUS_INNOVUS_OR_EDIT_OA"
    true
else
    echo "STOP_HERE_DO_NOT_START_GENUS_INNOVUS_OR_EDIT_OA"
    false
fi
