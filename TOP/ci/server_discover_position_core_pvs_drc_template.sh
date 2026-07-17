#!/usr/bin/env bash
# Discover attributable PVS DRC template candidates for Position core.
# This stage is read-only with respect to the immutable package and runs no PVS.

set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
EXPECTED_HEAD="${1:-MISSING}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
PACKAGE="$WORK_ROOT/handoff/innovus/blocks/spadmic_position_core/innovus_ooc_harden_position_core_gridfit_20260717_114810"
PACKAGE_GDS="$PACKAGE/gds/spadmic_position_core.gds"
EXPECTED_GDS_SHA=ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1
DEFAULT_SEARCH_ROOTS=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/layoutverification/pvs_drc:/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/PvsDRC:/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/PVS_DRC
SEARCH_ROOTS_RAW="${SPADMIC_POSITION_PVS_DRC_SEARCH_ROOTS:-$DEFAULT_SEARCH_ROOTS}"

RUN_OK=1
CD_RC=NOT_RUN
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
PACKAGE_FILE_GATE_RC=NOT_RUN
PACKAGE_HASH_GATE_RC=NOT_RUN
PACKAGE_STATUS_GATE_RC=NOT_RUN
PACKAGE_SHA_MANIFEST_RC=NOT_RUN
DIAGNOSTIC_CREATE_RC=NOT_RUN
TEMPLATE_CANDIDATE_COUNT=0
POSITION_NAMED_CANDIDATE_COUNT=0

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
    PACKAGE_FILE_GATE_RC=0

    for FILE in \
        "$PACKAGE_GDS" \
        "$PACKAGE/manifests/package.json" \
        "$PACKAGE/manifests/SHA256SUMS" \
        "$PACKAGE/status/qualification.rpt" \
        "$PACKAGE/status/handoff_audit.rpt" \
        "$PACKAGE/reports/lvs_source_preparation.rpt"
    do
        if [ ! -s "$FILE" ]; then
            echo "MISSING_OR_EMPTY=$FILE"
            PACKAGE_FILE_GATE_RC=1
        fi
    done

    echo "PACKAGE_FILE_GATE_RC=$PACKAGE_FILE_GATE_RC"

    if [ "$PACKAGE_FILE_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: immutable package evidence missing"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    ACTUAL_GDS_SHA="$(sha256sum "$PACKAGE_GDS" | awk '{print $1}')"
    PACKAGE_HASH_GATE_RC=0

    if [ "$ACTUAL_GDS_SHA" != "$EXPECTED_GDS_SHA" ]; then
        PACKAGE_HASH_GATE_RC=1
    fi

    echo "EXPECTED_GDS_SHA=$EXPECTED_GDS_SHA"
    echo "ACTUAL_GDS_SHA=$ACTUAL_GDS_SHA"
    echo "PACKAGE_HASH_GATE_RC=$PACKAGE_HASH_GATE_RC"

    PACKAGE_STATUS_GATE_RC=0
    for SPEC in \
        "$PACKAGE/status/handoff_audit.rpt|STATUS=PASS" \
        "$PACKAGE/status/handoff_audit.rpt|ERROR_COUNT=0" \
        "$PACKAGE/status/qualification.rpt|PACKAGE_STATUS=CANDIDATE" \
        "$PACKAGE/status/qualification.rpt|PIN_PARITY_STATUS=PASS" \
        "$PACKAGE/status/qualification.rpt|PVS_BASE_DRC_STATUS=NOT_RUN" \
        "$PACKAGE/status/qualification.rpt|SIGNOFF_READY=NO" \
        "$PACKAGE/reports/lvs_source_preparation.rpt|STATUS=PASS" \
        "$PACKAGE/reports/lvs_source_preparation.rpt|ERROR_COUNT=0"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_LINE="${SPEC#*|}"
        grep -Fqx "$EXPECTED_LINE" "$FILE"
        LINE_RC=$?
        echo "PACKAGE_STATUS_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"

        if [ "$LINE_RC" -ne 0 ]; then
            PACKAGE_STATUS_GATE_RC=1
        fi
    done

    echo "PACKAGE_STATUS_GATE_RC=$PACKAGE_STATUS_GATE_RC"

    if [ "$PACKAGE_HASH_GATE_RC" -ne 0 ] || \
       [ "$PACKAGE_STATUS_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: package is not the accepted candidate"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    DIAGNOSTIC_ID="position_pvs_drc_template_discovery_$(date +%Y%m%d_%H%M%S)"
    DIAGNOSTIC_ROOT="$WORK_ROOT/diagnostics/$DIAGNOSTIC_ID"
    mkdir -p "$DIAGNOSTIC_ROOT"
    DIAGNOSTIC_CREATE_RC=$?

    echo "DIAGNOSTIC_ID=$DIAGNOSTIC_ID"
    echo "DIAGNOSTIC_ROOT=$DIAGNOSTIC_ROOT"
    echo "DIAGNOSTIC_CREATE_RC=$DIAGNOSTIC_CREATE_RC"

    if [ "$DIAGNOSTIC_CREATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: diagnostic directory creation failed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    PACKAGE_SHA_CONSOLE="$DIAGNOSTIC_ROOT/package_sha256_check.rpt"
    (
        cd "$PACKAGE" || false
        sha256sum -c manifests/SHA256SUMS
    ) >"$PACKAGE_SHA_CONSOLE" 2>&1
    PACKAGE_SHA_MANIFEST_RC=$?

    echo "PACKAGE_SHA_MANIFEST_RC=$PACKAGE_SHA_MANIFEST_RC"

    if [ "$PACKAGE_SHA_MANIFEST_RC" -ne 0 ]; then
        cat "$PACKAGE_SHA_CONSOLE"
        echo "STOP_HERE_DO_NOT_CONTINUE: package SHA manifest failed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    ROOT_STATUS="$DIAGNOSTIC_ROOT/search_roots.rpt"
    RAW_CANDIDATES="$DIAGNOSTIC_ROOT/candidate_directories.raw"
    CANDIDATES="$DIAGNOSTIC_ROOT/candidate_directories.txt"
    INVENTORY="$DIAGNOSTIC_ROOT/template_candidate_inventory.rpt"

    : >"$ROOT_STATUS"
    : >"$RAW_CANDIDATES"

    IFS=':' read -r -a SEARCH_ROOTS <<< "$SEARCH_ROOTS_RAW"

    for ROOT in "${SEARCH_ROOTS[@]}"
    do
        if [ -d "$ROOT" ]; then
            echo "SEARCH_ROOT_STATUS=FOUND ROOT=$ROOT" >>"$ROOT_STATUS"
            find "$ROOT" -maxdepth 5 -type f \
                \( -name run.pvs -o -name pvsdrcctl \) \
                -printf '%h\n' 2>/dev/null >>"$RAW_CANDIDATES"
        else
            echo "SEARCH_ROOT_STATUS=MISSING ROOT=$ROOT" >>"$ROOT_STATUS"
        fi
    done

    sort -u "$RAW_CANDIDATES" >"$CANDIDATES"
    TEMPLATE_CANDIDATE_COUNT="$(awk 'NF {count++} END {print count + 0}' "$CANDIDATES")"

    {
        echo "LABEL=SPADMIC_POSITION_PVS_DRC_TEMPLATE_CANDIDATE_INVENTORY"
        echo "PACKAGE=$PACKAGE"
        echo "PACKAGE_GDS=$PACKAGE_GDS"
        echo "PACKAGE_GDS_SHA256=$EXPECTED_GDS_SHA"
        echo "TEMPLATE_CANDIDATE_COUNT=$TEMPLATE_CANDIDATE_COUNT"

        while IFS= read -r CANDIDATE
        do
            [ -n "$CANDIDATE" ] || continue
            POSITION_EVIDENCE=ABSENT
            DENSITY_HOOK_EVIDENCE=ABSENT

            if printf '%s\n' "$CANDIDATE" | grep -qiE 'position|spadmic_position_core'; then
                POSITION_EVIDENCE=PATH_MATCH
            fi

            echo "CANDIDATE_BEGIN=$CANDIDATE"

            while IFS= read -r CONTROL
            do
                [ -n "$CONTROL" ] || continue
                echo "CONTROL_FILE=$CONTROL"
                echo "CONTROL_BYTES=$(stat -c '%s' "$CONTROL" 2>/dev/null || echo UNKNOWN)"
                echo "CONTROL_SHA256=$(sha256sum "$CONTROL" 2>/dev/null | awk '{print $1}')"

                if grep -qiE 'position|spadmic_position_core' "$CONTROL" 2>/dev/null; then
                    POSITION_EVIDENCE=CONTROL_MATCH
                fi

                if grep -qE '#[[:space:]]*(UN)?DEFINE[[:space:]]+DENSITY|DENSITY' \
                    "$CONTROL" 2>/dev/null; then
                    DENSITY_HOOK_EVIDENCE=PRESENT
                fi

                grep -nEi '\.gds|top_cell|DENSITY|position|spadmic|xh018|DRC' \
                    "$CONTROL" 2>/dev/null | head -n 120
            done < <(
                find "$CANDIDATE" -maxdepth 4 -type f \
                    \( -name run.pvs \
                       -o -name pvsdrcctl \
                       -o -name .config.rul \
                       -o -name .technology.rul \
                       -o -name .preset.autosave \
                       -o -name '*.setup' \) \
                    -print 2>/dev/null | sort
            )

            find "$CANDIDATE" -maxdepth 3 -type f -iname '*.gds' \
                -printf 'GDS_FILE=%p\n' 2>/dev/null | sort

            echo "POSITION_NAME_EVIDENCE=$POSITION_EVIDENCE"
            echo "DENSITY_HOOK_EVIDENCE=$DENSITY_HOOK_EVIDENCE"
            echo "CANDIDATE_END=$CANDIDATE"

            if [ "$POSITION_EVIDENCE" != "ABSENT" ]; then
                POSITION_NAMED_CANDIDATE_COUNT=$((POSITION_NAMED_CANDIDATE_COUNT + 1))
            fi
        done <"$CANDIDATES"

        echo "POSITION_NAMED_CANDIDATE_COUNT=$POSITION_NAMED_CANDIDATE_COUNT"
    } >"$INVENTORY"

    DISCOVERY_STATUS=FAIL
    DISCOVERY_RESULT=NO_PVS_DRC_TEMPLATE_CANDIDATES_FOUND
    POSITION_TEMPLATE_EVIDENCE_STATUS=NOT_FOUND

    if [ "$TEMPLATE_CANDIDATE_COUNT" -gt 0 ]; then
        DISCOVERY_STATUS=PASS
        DISCOVERY_RESULT=CANDIDATES_RECORDED_FOR_REVIEW
    fi

    if [ "$POSITION_NAMED_CANDIDATE_COUNT" -gt 0 ]; then
        POSITION_TEMPLATE_EVIDENCE_STATUS=CANDIDATE_FOUND_REVIEW_REQUIRED
    fi

    STATUS_REPORT="$DIAGNOSTIC_ROOT/template_discovery_status.rpt"
    {
        echo "LABEL=SPADMIC_POSITION_PVS_DRC_TEMPLATE_DISCOVERY"
        echo "STATUS=$DISCOVERY_STATUS"
        echo "RESULT=$DISCOVERY_RESULT"
        echo "PACKAGE=$PACKAGE"
        echo "GDS_SHA256=$EXPECTED_GDS_SHA"
        echo "TEMPLATE_CANDIDATE_COUNT=$TEMPLATE_CANDIDATE_COUNT"
        echo "POSITION_NAMED_CANDIDATE_COUNT=$POSITION_NAMED_CANDIDATE_COUNT"
        echo "POSITION_TEMPLATE_EVIDENCE_STATUS=$POSITION_TEMPLATE_EVIDENCE_STATUS"
        echo "ATTRIBUTABLE_POSITION_TEMPLATE_STATUS=NOT_PROVEN"
        echo "TEMPLATE_SELECTION_AUTHORIZED=NO"
        echo "CROSS_BLOCK_TEMPLATE_REUSE_AUTHORIZED=NO"
        echo "PVS_REPLAY_AUTHORIZED=NO"
        echo "CANDIDATE_LIST=$CANDIDATES"
        echo "CANDIDATE_INVENTORY=$INVENTORY"
        echo "PACKAGE_SHA_MANIFEST_RC=$PACKAGE_SHA_MANIFEST_RC"
        echo "PACKAGE_MODIFIED=NO"
        echo "PVS_EXECUTED=NO"
        echo "BLOCK_PROMOTION_AUTHORIZED=NO"
        echo "SIGNOFF_READY=NO"
        echo "NEXT_GATE=POSITION_PVS_DRC_TEMPLATE_REVIEW"
    } >"$STATUS_REPORT"

    echo
    echo "===== SEARCH ROOTS ====="
    cat "$ROOT_STATUS"

    echo
    echo "===== TEMPLATE CANDIDATES ====="
    cat "$CANDIDATES"

    echo
    echo "===== TEMPLATE CANDIDATE INVENTORY ====="
    cat "$INVENTORY"

    echo
    echo "===== TEMPLATE DISCOVERY STATUS ====="
    cat "$STATUS_REPORT"

    echo
    echo "===== DIAGNOSTIC HASHES ====="
    find "$DIAGNOSTIC_ROOT" -maxdepth 1 -type f ! -name SHA256SUMS \
        -print0 | sort -z | xargs -0 sha256sum | tee "$DIAGNOSTIC_ROOT/SHA256SUMS"

    if [ "$DISCOVERY_STATUS" = "PASS" ]; then
        true
    else
        false
    fi
else
    echo "POSITION_PVS_DRC_TEMPLATE_DISCOVERY_STATUS=NOT_RUN"
    echo "PVS_EXECUTED=NO"
    echo "STOP_HERE_DO_NOT_RUN_PVS"
    false
fi
