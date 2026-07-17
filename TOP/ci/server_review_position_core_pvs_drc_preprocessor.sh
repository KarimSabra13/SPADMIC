#!/usr/bin/env bash
# Collect exact XH018 preprocessor semantics for the reviewed Position DRC seed.
# This stage is read-only with respect to the seed and package. It never creates
# a replay directory, patches controls, or launches PVS.

set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
EXPECTED_HEAD="${1:-MISSING}"
SEED_REVIEW_ROOT="${2:-MISSING}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"

PACKAGE="$WORK_ROOT/handoff/innovus/blocks/spadmic_position_core/innovus_ooc_harden_position_core_gridfit_20260717_114810"
PACKAGE_GDS="$PACKAGE/gds/spadmic_position_core.gds"
EXPECTED_GDS_SHA=ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1

TEMPLATE_ROOT=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/layoutverification/pvs_drc
PRIMARY_SEED="$TEMPLATE_ROOT/spadmic_tx_packet_core"
PRIMARY_CONTROL="$PRIMARY_SEED/pvsdrcctl"
PRIMARY_TECHNOLOGY_CONTROL="$PRIMARY_SEED/.technology.rul"
PRIMARY_PRESET="$PRIMARY_SEED/.preset.autosave"

EXPECTED_REVIEW_STATUS_SHA=9b9c443505bd9cfdacd59de17ba2ac5dc0dd21d4980bd3afea3c5eb8c5415925
EXPECTED_REVIEW_CONTRACT_SHA=a25d7ca23a36e30d1e060c1dc568af43cb303ef5659c2c2a8037392ac39a9bec
EXPECTED_REVIEW_DIRECTIVES_SHA=14f9d02f743dde4b855678df9eccb21d6ebf6c5b71d239d16ea5d238092f947e
EXPECTED_REVIEW_RISK_SHA=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
EXPECTED_CANDIDATE_LIST_SHA=21911e928f6d582627882cbc47374a281e9ef287c62819d53fe8590c460fa268

RUN_OK=1
CD_RC=NOT_RUN
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
REVIEW_FILE_GATE_RC=NOT_RUN
REVIEW_HASH_GATE_RC=NOT_RUN
REVIEW_STATUS_GATE_RC=NOT_RUN
DIRECTIVE_CONTRACT_GATE_RC=NOT_RUN
PACKAGE_GATE_RC=NOT_RUN
PACKAGE_SHA_MANIFEST_RC=NOT_RUN
PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=NOT_RUN
PRIMARY_CONTROL_IDENTITY_GATE_RC=NOT_RUN
CANDIDATE_LIST_GATE_RC=NOT_RUN
TECHLIB_RESOLUTION_GATE_RC=NOT_RUN
DIAGNOSTIC_CREATE_RC=NOT_RUN
DIAGNOSTIC_COPY_GATE_RC=NOT_RUN
PACKAGE_SHA_CONSOLE=""

directive_state() {
    local control="$1"
    local symbol="$2"
    local define_count
    local undefine_count

    if [ ! -f "$control" ]; then
        echo MISSING_CONTROL
        return
    fi

    define_count="$(grep -Ec "^[[:space:]]*#DEFINE[[:space:]]+$symbol([[:space:]]|$)" "$control" 2>/dev/null)"
    undefine_count="$(grep -Ec "^[[:space:]]*#UNDEFINE[[:space:]]+$symbol([[:space:]]|$)" "$control" 2>/dev/null)"

    if [ "$define_count" -eq 1 ] && [ "$undefine_count" -eq 0 ]; then
        echo DEFINED
    elif [ "$define_count" -eq 0 ] && [ "$undefine_count" -eq 1 ]; then
        echo UNDEFINED
    elif [ "$define_count" -eq 0 ] && [ "$undefine_count" -eq 0 ]; then
        echo NOT_DECLARED
    else
        echo CONFLICT
    fi
}

if [ "$EXPECTED_HEAD" = "MISSING" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: expected repository HEAD argument missing"
    RUN_OK=0
fi

if [ "$SEED_REVIEW_ROOT" = "MISSING" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: corrected seed-review root argument missing"
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
    REVIEW_STATUS="$SEED_REVIEW_ROOT/seed_review_status.rpt"
    REVIEW_CONTRACT="$SEED_REVIEW_ROOT/primary_seed_contract.rpt"
    REVIEW_DIRECTIVES="$SEED_REVIEW_ROOT/primary_pvsdrcctl_preprocessor_directives.rpt"
    REVIEW_RISK="$SEED_REVIEW_ROOT/primary_pvsdrcctl_risk_scan.rpt"
    REVIEW_FILE_GATE_RC=0

    for FILE in "$REVIEW_STATUS" "$REVIEW_CONTRACT" "$REVIEW_DIRECTIVES"
    do
        if [ ! -s "$FILE" ]; then
            echo "MISSING_OR_EMPTY=$FILE"
            REVIEW_FILE_GATE_RC=1
        fi
    done

    if [ ! -f "$REVIEW_RISK" ]; then
        echo "MISSING=$REVIEW_RISK"
        REVIEW_FILE_GATE_RC=1
    fi

    echo "REVIEW_FILE_GATE_RC=$REVIEW_FILE_GATE_RC"
    if [ "$REVIEW_FILE_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: corrected seed-review evidence missing"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    ACTUAL_REVIEW_STATUS_SHA="$(sha256sum "$REVIEW_STATUS" | awk '{print $1}')"
    ACTUAL_REVIEW_CONTRACT_SHA="$(sha256sum "$REVIEW_CONTRACT" | awk '{print $1}')"
    ACTUAL_REVIEW_DIRECTIVES_SHA="$(sha256sum "$REVIEW_DIRECTIVES" | awk '{print $1}')"
    ACTUAL_REVIEW_RISK_SHA="$(sha256sum "$REVIEW_RISK" | awk '{print $1}')"
    REVIEW_HASH_GATE_RC=0

    for SPEC in \
        "REVIEW_STATUS|$EXPECTED_REVIEW_STATUS_SHA|$ACTUAL_REVIEW_STATUS_SHA" \
        "REVIEW_CONTRACT|$EXPECTED_REVIEW_CONTRACT_SHA|$ACTUAL_REVIEW_CONTRACT_SHA" \
        "REVIEW_DIRECTIVES|$EXPECTED_REVIEW_DIRECTIVES_SHA|$ACTUAL_REVIEW_DIRECTIVES_SHA" \
        "REVIEW_RISK|$EXPECTED_REVIEW_RISK_SHA|$ACTUAL_REVIEW_RISK_SHA"
    do
        LABEL="${SPEC%%|*}"
        REST="${SPEC#*|}"
        EXPECTED_SHA="${REST%%|*}"
        ACTUAL_SHA="${REST#*|}"
        echo "EXPECTED_${LABEL}_SHA=$EXPECTED_SHA"
        echo "ACTUAL_${LABEL}_SHA=$ACTUAL_SHA"
        if [ "$EXPECTED_SHA" != "$ACTUAL_SHA" ]; then
            REVIEW_HASH_GATE_RC=1
        fi
    done

    echo "REVIEW_HASH_GATE_RC=$REVIEW_HASH_GATE_RC"
    if [ "$REVIEW_HASH_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: corrected seed-review hashes changed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    REVIEW_STATUS_GATE_RC=0
    for EXPECTED_LINE in \
        "STATUS=PASS" \
        "PRIMARY_CONTROL_IDENTITY_STATUS=PASS" \
        "PRIMARY_EXECUTABLE_CONTRACT_STATUS=PASS" \
        "DENSITY_HOOK_STATUS=PASS" \
        "PREPROCESSOR_DIRECTIVE_COUNT=5" \
        "NON_DENSITY_PREPROCESSOR_DIRECTIVE_COUNT=4" \
        "PREPROCESSOR_DIRECTIVE_REVIEW_STATUS=REVIEW_REQUIRED" \
        "AUTOMATED_CONTROL_RISK_SCAN_STATUS=PASS" \
        "EXECUTABLE_RISK_LINE_COUNT=0" \
        "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO" \
        "PVS_REPLAY_AUTHORIZED=NO" \
        "PACKAGE_MODIFIED=NO" \
        "PINNED_SOURCE_CONTROLS_UNCHANGED=YES" \
        "PVS_EXECUTED=NO" \
        "NEXT_GATE=POSITION_PVS_DRC_SEED_PREPROCESSOR_MANUAL_REVIEW"
    do
        grep -Fqx "$EXPECTED_LINE" "$REVIEW_STATUS"
        LINE_RC=$?
        echo "REVIEW_STATUS_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"
        if [ "$LINE_RC" -ne 0 ]; then
            REVIEW_STATUS_GATE_RC=1
        fi
    done

    DIRECTIVE_CONTRACT_GATE_RC=0
    for EXPECTED_LINE in \
        "18:#UNDEFINE DENSITY" \
        "19:#UNDEFINE POPPING" \
        "20:#UNDEFINE PIMIDE" \
        "22:#UNDEFINE DUMMY_FILL" \
        "24:#DEFINE VAR_ANT_RATIO"
    do
        grep -Fqx "$EXPECTED_LINE" "$REVIEW_DIRECTIVES"
        LINE_RC=$?
        echo "DIRECTIVE_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"
        if [ "$LINE_RC" -ne 0 ]; then
            DIRECTIVE_CONTRACT_GATE_RC=1
        fi
    done

    grep -Fqx "PRIMARY_EXECUTABLE_CONTRACT_GATE_RC=0" "$REVIEW_CONTRACT"
    CONTRACT_GATE_LINE_RC=$?
    if [ "$CONTRACT_GATE_LINE_RC" -ne 0 ]; then
        DIRECTIVE_CONTRACT_GATE_RC=1
    fi

    echo "REVIEW_STATUS_GATE_RC=$REVIEW_STATUS_GATE_RC"
    echo "DIRECTIVE_CONTRACT_GATE_RC=$DIRECTIVE_CONTRACT_GATE_RC"
    if [ "$REVIEW_STATUS_GATE_RC" -ne 0 ] || \
       [ "$DIRECTIVE_CONTRACT_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: corrected seed-review contract changed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    SOURCE_DISCOVERY_ROOT="$(sed -n 's/^SOURCE_DISCOVERY_ROOT=//p' "$REVIEW_STATUS")"
    CANDIDATE_LIST="$SOURCE_DISCOVERY_ROOT/candidate_directories.txt"
    ACTUAL_CANDIDATE_LIST_SHA=UNKNOWN
    CANDIDATE_LIST_GATE_RC=0

    if [ -s "$CANDIDATE_LIST" ]; then
        ACTUAL_CANDIDATE_LIST_SHA="$(sha256sum "$CANDIDATE_LIST" | awk '{print $1}')"
    else
        CANDIDATE_LIST_GATE_RC=1
    fi

    if [ "$ACTUAL_CANDIDATE_LIST_SHA" != "$EXPECTED_CANDIDATE_LIST_SHA" ]; then
        CANDIDATE_LIST_GATE_RC=1
    fi

    echo "SOURCE_DISCOVERY_ROOT=$SOURCE_DISCOVERY_ROOT"
    echo "EXPECTED_CANDIDATE_LIST_SHA=$EXPECTED_CANDIDATE_LIST_SHA"
    echo "ACTUAL_CANDIDATE_LIST_SHA=$ACTUAL_CANDIDATE_LIST_SHA"
    echo "CANDIDATE_LIST_GATE_RC=$CANDIDATE_LIST_GATE_RC"

    if [ "$CANDIDATE_LIST_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: source candidate inventory changed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    PACKAGE_GATE_RC=0
    for FILE in \
        "$PACKAGE_GDS" \
        "$PACKAGE/status/handoff_audit.rpt" \
        "$PACKAGE/status/qualification.rpt" \
        "$PACKAGE/manifests/SHA256SUMS"
    do
        if [ ! -s "$FILE" ]; then
            echo "MISSING_OR_EMPTY=$FILE"
            PACKAGE_GATE_RC=1
        fi
    done

    ACTUAL_GDS_SHA=UNKNOWN
    if [ -f "$PACKAGE_GDS" ]; then
        ACTUAL_GDS_SHA="$(sha256sum "$PACKAGE_GDS" | awk '{print $1}')"
    fi
    if [ "$ACTUAL_GDS_SHA" != "$EXPECTED_GDS_SHA" ]; then
        PACKAGE_GATE_RC=1
    fi

    for SPEC in \
        "$PACKAGE/status/handoff_audit.rpt|STATUS=PASS" \
        "$PACKAGE/status/handoff_audit.rpt|ERROR_COUNT=0" \
        "$PACKAGE/status/qualification.rpt|PACKAGE_STATUS=CANDIDATE" \
        "$PACKAGE/status/qualification.rpt|PVS_BASE_DRC_STATUS=NOT_RUN" \
        "$PACKAGE/status/qualification.rpt|PVS_DENSITY_DRC_STATUS=NOT_RUN" \
        "$PACKAGE/status/qualification.rpt|PVS_LVS_STATUS=NOT_RUN" \
        "$PACKAGE/status/qualification.rpt|SIGNOFF_READY=NO"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_LINE="${SPEC#*|}"
        grep -Fqx "$EXPECTED_LINE" "$FILE" 2>/dev/null
        if [ "$?" -ne 0 ]; then
            PACKAGE_GATE_RC=1
        fi
    done

    echo "EXPECTED_GDS_SHA=$EXPECTED_GDS_SHA"
    echo "ACTUAL_GDS_SHA=$ACTUAL_GDS_SHA"
    echo "PACKAGE_GATE_RC=$PACKAGE_GATE_RC"
    if [ "$PACKAGE_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: package is not the accepted candidate"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    PACKAGE_SHA_CONSOLE="$WORK_ROOT/diagnostics/position_preprocessor_package_sha_$$.rpt"
    mkdir -p "$WORK_ROOT/diagnostics"
    (
        if cd "$PACKAGE"; then
            sha256sum -c manifests/SHA256SUMS
        else
            echo "PACKAGE_CD_FAILED=$PACKAGE"
            false
        fi
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
    PRIMARY_CONTROL_IDENTITY_GATE_RC=0
    for SPEC in \
        ".config.rul|e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" \
        ".preset.autosave|97b3a7e63c3e8a01ea1291a19de384e2c41f77cd11653a92c7f5618e73421000" \
        ".technology.rul|74a297facf6422635df2c58d79aa8b8ae46ca0b8232380471a88a182d8400ab6" \
        "pipo1.setup|949ce7ec915d1ddbd3e78534720c33aad9036d83932c6bac33730a113aba00dd" \
        "pvsdrcctl|b9a8451c6cc43647ec606ae706e450893e3673e22215dc5a64edeeb383b902ef" \
        "run.pvs|11ae3fc935041b8a4e0f3b406941c699c769ed1d50a504e8df36fcb544c7255a"
    do
        NAME="${SPEC%%|*}"
        EXPECTED_SHA="${SPEC#*|}"
        ACTUAL_SHA="$(sha256sum "$PRIMARY_SEED/$NAME" 2>/dev/null | awk '{print $1}')"
        echo "PRIMARY_CONTROL_FILE=$PRIMARY_SEED/$NAME"
        echo "PRIMARY_CONTROL_EXPECTED_SHA256=$EXPECTED_SHA"
        echo "PRIMARY_CONTROL_ACTUAL_SHA256=$ACTUAL_SHA"
        if [ "$EXPECTED_SHA" != "$ACTUAL_SHA" ]; then
            PRIMARY_CONTROL_IDENTITY_GATE_RC=1
        fi
    done

    echo "PRIMARY_CONTROL_IDENTITY_GATE_RC=$PRIMARY_CONTROL_IDENTITY_GATE_RC"
    if [ "$PRIMARY_CONTROL_IDENTITY_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: primary seed controls changed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    TECHLIB_PATH_COUNT="$(sed -nE 's/.*-techLib[[:space:]]+"([^"]+)".*/\1/p' "$PRIMARY_TECHNOLOGY_CONTROL" | awk 'NF {count++} END {print count + 0}')"
    TECHLIB_PATH="$(sed -nE 's/.*-techLib[[:space:]]+"([^"]+)".*/\1/p' "$PRIMARY_TECHNOLOGY_CONTROL" | head -n 1)"
    TECHLIB_RESOLUTION_GATE_RC=0

    if [ "$TECHLIB_PATH_COUNT" -ne 1 ] || [ ! -r "$TECHLIB_PATH" ]; then
        TECHLIB_RESOLUTION_GATE_RC=1
    fi

    TECHLIB_SHA=UNKNOWN
    TECHLIB_BYTES=UNKNOWN
    if [ "$TECHLIB_RESOLUTION_GATE_RC" -eq 0 ]; then
        TECHLIB_SHA="$(sha256sum "$TECHLIB_PATH" | awk '{print $1}')"
        TECHLIB_BYTES="$(stat -c '%s' "$TECHLIB_PATH")"
    fi

    echo "TECHLIB_PATH_COUNT=$TECHLIB_PATH_COUNT"
    echo "TECHLIB_PATH=$TECHLIB_PATH"
    echo "TECHLIB_BYTES=$TECHLIB_BYTES"
    echo "TECHLIB_SHA256=$TECHLIB_SHA"
    echo "TECHLIB_RESOLUTION_GATE_RC=$TECHLIB_RESOLUTION_GATE_RC"

    if [ "$TECHLIB_RESOLUTION_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: XH018 pvtech library is not attributable"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    DIAGNOSTIC_ID="position_pvs_drc_preprocessor_review_$(date +%Y%m%d_%H%M%S)"
    DIAGNOSTIC_ROOT="$WORK_ROOT/diagnostics/$DIAGNOSTIC_ID"
    mkdir -p \
        "$DIAGNOSTIC_ROOT/source_seed_review" \
        "$DIAGNOSTIC_ROOT/technology"
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
    DIAGNOSTIC_COPY_GATE_RC=0
    for SPEC in \
        "$REVIEW_STATUS|$DIAGNOSTIC_ROOT/source_seed_review/seed_review_status.rpt" \
        "$REVIEW_CONTRACT|$DIAGNOSTIC_ROOT/source_seed_review/primary_seed_contract.rpt" \
        "$REVIEW_DIRECTIVES|$DIAGNOSTIC_ROOT/source_seed_review/primary_pvsdrcctl_preprocessor_directives.rpt" \
        "$REVIEW_RISK|$DIAGNOSTIC_ROOT/source_seed_review/primary_pvsdrcctl_risk_scan.rpt" \
        "$TECHLIB_PATH|$DIAGNOSTIC_ROOT/technology/pvtech.lib" \
        "$PACKAGE_SHA_CONSOLE|$DIAGNOSTIC_ROOT/package_sha256_check.rpt"
    do
        SOURCE_FILE="${SPEC%%|*}"
        DESTINATION_FILE="${SPEC#*|}"
        cp -p "$SOURCE_FILE" "$DESTINATION_FILE"
        COPY_RC=$?
        if [ "$COPY_RC" -ne 0 ]; then
            DIAGNOSTIC_COPY_GATE_RC=1
        fi
    done
    rm -f "$PACKAGE_SHA_CONSOLE"

    echo "DIAGNOSTIC_COPY_GATE_RC=$DIAGNOSTIC_COPY_GATE_RC"
    if [ "$DIAGNOSTIC_COPY_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: diagnostic evidence copy failed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    PRIMARY_CONTEXT_REPORT="$DIAGNOSTIC_ROOT/primary_directive_context.rpt"
    PRIMARY_PRESET_REPORT="$DIAGNOSTIC_ROOT/primary_preset_option_extract.rpt"
    PVTECH_KEY_REPORT="$DIAGNOSTIC_ROOT/technology/pvtech_key_lines.rpt"
    PVTECH_REFERENCE_REPORT="$DIAGNOSTIC_ROOT/technology/pvtech_reference_candidates.rpt"

    {
        echo "LABEL=SPADMIC_POSITION_PVS_DRC_PRIMARY_DIRECTIVE_CONTEXT"
        grep -nEi -B 2 -A 2 'DENSITY|POPPING|PIMIDE|DUMMY_FILL|VAR_ANT_RATIO' \
            "$PRIMARY_CONTROL" 2>/dev/null
    } >"$PRIMARY_CONTEXT_REPORT"

    {
        echo "LABEL=SPADMIC_POSITION_PVS_DRC_PRIMARY_PRESET_OPTIONS"
        grep -nEi -C 3 'DENSITY|POPPING|PIMIDE|DUMMY_FILL|VAR_ANT_RATIO' \
            "$PRIMARY_PRESET" 2>/dev/null
    } >"$PRIMARY_PRESET_REPORT"

    {
        echo "LABEL=SPADMIC_POSITION_PVS_DRC_PVTECH_KEY_LINES"
        echo "TECHLIB_PATH=$TECHLIB_PATH"
        echo "TECHLIB_BYTES=$TECHLIB_BYTES"
        echo "TECHLIB_SHA256=$TECHLIB_SHA"
        grep -nEi -C 4 'XH018_1131|ruleSet|rule.?deck|include|POPPING|PIMIDE|DUMMY_FILL|VAR_ANT_RATIO' \
            "$TECHLIB_PATH" 2>/dev/null
    } >"$PVTECH_KEY_REPORT"

    {
        echo "LABEL=SPADMIC_POSITION_PVS_DRC_PVTECH_REFERENCE_CANDIDATES"
        awk '$1 == "DEFINE" && NF >= 3 {print "REFERENCE_RAW=" $3}' \
            "$TECHLIB_PATH" 2>/dev/null | sort -u
    } >"$PVTECH_REFERENCE_REPORT"

    PRIMARY_CONTEXT_LINE_COUNT="$(grep -Ec '^[0-9]+[-:]' "$PRIMARY_CONTEXT_REPORT")"
    PRIMARY_PRESET_LINE_COUNT="$(grep -Ec '^[0-9]+[-:]' "$PRIMARY_PRESET_REPORT")"
    PVTECH_KEY_LINE_COUNT="$(grep -Ec '^[0-9]+[-:]' "$PVTECH_KEY_REPORT")"
    PVTECH_REFERENCE_CANDIDATE_COUNT="$(grep -Ec '^REFERENCE_RAW=' "$PVTECH_REFERENCE_REPORT")"
fi

if [ "$RUN_OK" -eq 1 ]; then
    MATRIX_REPORT="$DIAGNOSTIC_ROOT/candidate_directive_matrix.tsv"
    TUPLE_REPORT="$DIAGNOSTIC_ROOT/candidate_directive_tuple_summary.tsv"
    MATRIX_CANDIDATE_COUNT=0
    MATRIX_INCOMPLETE_COUNT=0

    printf 'candidate\tDENSITY\tPOPPING\tPIMIDE\tDUMMY_FILL\tVAR_ANT_RATIO\n' \
        >"$MATRIX_REPORT"

    while IFS= read -r CANDIDATE
    do
        if [ -z "$CANDIDATE" ]; then
            continue
        fi

        CONTROL="$CANDIDATE/pvsdrcctl"
        DENSITY_STATE="$(directive_state "$CONTROL" DENSITY)"
        POPPING_STATE="$(directive_state "$CONTROL" POPPING)"
        PIMIDE_STATE="$(directive_state "$CONTROL" PIMIDE)"
        DUMMY_FILL_STATE="$(directive_state "$CONTROL" DUMMY_FILL)"
        VAR_ANT_RATIO_STATE="$(directive_state "$CONTROL" VAR_ANT_RATIO)"

        printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$CANDIDATE" \
            "$DENSITY_STATE" \
            "$POPPING_STATE" \
            "$PIMIDE_STATE" \
            "$DUMMY_FILL_STATE" \
            "$VAR_ANT_RATIO_STATE" >>"$MATRIX_REPORT"

        MATRIX_CANDIDATE_COUNT=$((MATRIX_CANDIDATE_COUNT + 1))
        case "$DENSITY_STATE|$POPPING_STATE|$PIMIDE_STATE|$DUMMY_FILL_STATE|$VAR_ANT_RATIO_STATE" in
            *MISSING*|*CONFLICT*)
                MATRIX_INCOMPLETE_COUNT=$((MATRIX_INCOMPLETE_COUNT + 1))
                ;;
        esac
    done <"$CANDIDATE_LIST"

    {
        printf 'candidate_count\tDENSITY\tPOPPING\tPIMIDE\tDUMMY_FILL\tVAR_ANT_RATIO\n'
        awk -F '\t' '
            NR > 1 {
                key = $2 FS $3 FS $4 FS $5 FS $6
                count[key]++
            }
            END {
                for (key in count) print count[key] FS key
            }
        ' "$MATRIX_REPORT" | sort -nr
    } >"$TUPLE_REPORT"

    UNIQUE_DIRECTIVE_TUPLE_COUNT="$(awk 'NR > 1 {count++} END {print count + 0}' "$TUPLE_REPORT")"
    MATRIX_COMPLETENESS_STATUS=PASS
    if [ "$MATRIX_CANDIDATE_COUNT" -ne 114 ] || \
       [ "$MATRIX_INCOMPLETE_COUNT" -ne 0 ]; then
        MATRIX_COMPLETENESS_STATUS=FAIL
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    SEMANTIC_REPORT="$DIAGNOSTIC_ROOT/preprocessor_semantic_classification.rpt"
    {
        echo "LABEL=SPADMIC_POSITION_PVS_DRC_PREPROCESSOR_SEMANTIC_CLASSIFICATION"
        echo "DIRECTIVE=DENSITY"
        echo "STATE=UNDEFINED"
        echo "CLASS=BASE_DRC_VARIANT_SELECTOR"
        echo "COVERAGE_EFFECT=SEPARATE_DENSITY_DRC_REQUIRED"
        echo "DIRECTIVE=POPPING"
        echo "STATE=UNDEFINED"
        echo "CLASS=PDK_SEMANTICS_UNRESOLVED"
        echo "COVERAGE_EFFECT=REVIEW_REQUIRED"
        echo "DIRECTIVE=PIMIDE"
        echo "STATE=UNDEFINED"
        echo "CLASS=PDK_SEMANTICS_UNRESOLVED"
        echo "COVERAGE_EFFECT=REVIEW_REQUIRED"
        echo "DIRECTIVE=DUMMY_FILL"
        echo "STATE=UNDEFINED"
        echo "CLASS=DUMMY_PATTERN_GENERATION_SELECTOR"
        echo "COVERAGE_EFFECT=RULE_DECK_USAGE_REVIEW_REQUIRED"
        echo "DIRECTIVE=VAR_ANT_RATIO"
        echo "STATE=DEFINED"
        echo "CLASS=ADDITIONAL_VARIABLE_RATIO_ANTENNA_FAMILY"
        echo "COVERAGE_EFFECT=ADDITIONAL_ANTENNA_FAMILY_ENABLED"
        echo "PREPROCESSOR_SEMANTIC_REVIEW_STATUS=REVIEW_REQUIRED"
        echo "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO"
        echo "PVS_REPLAY_AUTHORIZED=NO"
        echo "PVS_EXECUTED=NO"
    } >"$SEMANTIC_REPORT"

    SOURCE_CONTROL_RECHECK_RC=0
    for SPEC in \
        ".preset.autosave|97b3a7e63c3e8a01ea1291a19de384e2c41f77cd11653a92c7f5618e73421000" \
        ".technology.rul|74a297facf6422635df2c58d79aa8b8ae46ca0b8232380471a88a182d8400ab6" \
        "pvsdrcctl|b9a8451c6cc43647ec606ae706e450893e3673e22215dc5a64edeeb383b902ef"
    do
        NAME="${SPEC%%|*}"
        EXPECTED_SHA="${SPEC#*|}"
        ACTUAL_SHA="$(sha256sum "$PRIMARY_SEED/$NAME" | awk '{print $1}')"
        if [ "$EXPECTED_SHA" != "$ACTUAL_SHA" ]; then
            SOURCE_CONTROL_RECHECK_RC=1
        fi
    done

    ACTUAL_TECHLIB_POST_SHA="$(sha256sum "$TECHLIB_PATH" | awk '{print $1}')"
    TECHLIB_RECHECK_RC=0
    if [ "$TECHLIB_SHA" != "$ACTUAL_TECHLIB_POST_SHA" ]; then
        TECHLIB_RECHECK_RC=1
    fi

    ACTUAL_CANDIDATE_LIST_POST_SHA="$(sha256sum "$CANDIDATE_LIST" | awk '{print $1}')"
    CANDIDATE_LIST_RECHECK_RC=0
    if [ "$EXPECTED_CANDIDATE_LIST_SHA" != "$ACTUAL_CANDIDATE_LIST_POST_SHA" ]; then
        CANDIDATE_LIST_RECHECK_RC=1
    fi

    (
        if cd "$PACKAGE"; then
            sha256sum -c manifests/SHA256SUMS
        else
            echo "PACKAGE_CD_FAILED=$PACKAGE"
            false
        fi
    ) >"$DIAGNOSTIC_ROOT/package_sha256_post_review.rpt" 2>&1
    PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=$?

    FINAL_STATUS=PASS
    if [ "$MATRIX_COMPLETENESS_STATUS" != "PASS" ] || \
       [ "$SOURCE_CONTROL_RECHECK_RC" -ne 0 ] || \
       [ "$TECHLIB_RECHECK_RC" -ne 0 ] || \
       [ "$CANDIDATE_LIST_RECHECK_RC" -ne 0 ] || \
       [ "$PACKAGE_POST_REVIEW_SHA_MANIFEST_RC" -ne 0 ]; then
        FINAL_STATUS=FAIL
    fi

    STATUS_REPORT="$DIAGNOSTIC_ROOT/preprocessor_review_status.rpt"
    {
        echo "LABEL=SPADMIC_POSITION_PVS_DRC_PREPROCESSOR_REVIEW"
        echo "STATUS=$FINAL_STATUS"
        echo "RESULT=PDK_PREPROCESSOR_EVIDENCE_RECORDED_FOR_MANUAL_REVIEW"
        echo "SOURCE_SEED_REVIEW_ROOT=$SEED_REVIEW_ROOT"
        echo "SOURCE_SEED_REVIEW_STATUS_SHA256=$EXPECTED_REVIEW_STATUS_SHA"
        echo "SOURCE_DISCOVERY_ROOT=$SOURCE_DISCOVERY_ROOT"
        echo "PACKAGE=$PACKAGE"
        echo "PACKAGE_GDS_SHA256=$EXPECTED_GDS_SHA"
        echo "PRIMARY_SEED=$PRIMARY_SEED"
        echo "PRIMARY_CONTROL_IDENTITY_STATUS=PASS"
        echo "PRIMARY_EXECUTABLE_CONTRACT_STATUS=PASS"
        echo "PRIMARY_DENSITY_STATE=UNDEFINED"
        echo "PRIMARY_POPPING_STATE=UNDEFINED"
        echo "PRIMARY_PIMIDE_STATE=UNDEFINED"
        echo "PRIMARY_DUMMY_FILL_STATE=UNDEFINED"
        echo "PRIMARY_VAR_ANT_RATIO_STATE=DEFINED"
        echo "MATRIX_CANDIDATE_COUNT=$MATRIX_CANDIDATE_COUNT"
        echo "MATRIX_INCOMPLETE_COUNT=$MATRIX_INCOMPLETE_COUNT"
        echo "UNIQUE_DIRECTIVE_TUPLE_COUNT=$UNIQUE_DIRECTIVE_TUPLE_COUNT"
        echo "MATRIX_COMPLETENESS_STATUS=$MATRIX_COMPLETENESS_STATUS"
        echo "PRIMARY_CONTEXT_LINE_COUNT=$PRIMARY_CONTEXT_LINE_COUNT"
        echo "PRIMARY_PRESET_LINE_COUNT=$PRIMARY_PRESET_LINE_COUNT"
        echo "TECHLIB_PATH=$TECHLIB_PATH"
        echo "TECHLIB_BYTES=$TECHLIB_BYTES"
        echo "TECHLIB_SHA256=$TECHLIB_SHA"
        echo "PVTECH_KEY_LINE_COUNT=$PVTECH_KEY_LINE_COUNT"
        echo "PVTECH_REFERENCE_CANDIDATE_COUNT=$PVTECH_REFERENCE_CANDIDATE_COUNT"
        echo "DENSITY_SEMANTIC_STATUS=BASE_SELECTOR_ACCEPTED_SEPARATE_DENSITY_REQUIRED"
        echo "POPPING_SEMANTIC_STATUS=REVIEW_REQUIRED"
        echo "PIMIDE_SEMANTIC_STATUS=REVIEW_REQUIRED"
        echo "DUMMY_FILL_SEMANTIC_STATUS=RULE_DECK_USAGE_REVIEW_REQUIRED"
        echo "VAR_ANT_RATIO_SEMANTIC_STATUS=ADDITIONAL_ANTENNA_FAMILY_ENABLED"
        echo "PREPROCESSOR_SEMANTIC_REVIEW_STATUS=REVIEW_REQUIRED"
        echo "SOURCE_CONTROL_RECHECK_RC=$SOURCE_CONTROL_RECHECK_RC"
        echo "TECHLIB_RECHECK_RC=$TECHLIB_RECHECK_RC"
        echo "CANDIDATE_LIST_RECHECK_RC=$CANDIDATE_LIST_RECHECK_RC"
        echo "PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=$PACKAGE_POST_REVIEW_SHA_MANIFEST_RC"
        echo "PACKAGE_MODIFIED=NO"
        echo "SOURCE_TEMPLATE_WRITE_ATTEMPTED=NO"
        echo "PVS_TEMPLATE_CREATED=NO"
        echo "TEMPLATE_SELECTION_AUTHORIZED=NO"
        echo "CROSS_BLOCK_TEMPLATE_REUSE_AUTHORIZED=NO"
        echo "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO"
        echo "PVS_REPLAY_AUTHORIZED=NO"
        echo "PVS_EXECUTED=NO"
        echo "PVS_BASE_DRC_STATUS=NOT_RUN"
        echo "PVS_DENSITY_DRC_STATUS=NOT_RUN"
        echo "PVS_LVS_STATUS=NOT_RUN"
        echo "BLOCK_PROMOTION_AUTHORIZED=NO"
        echo "SIGNOFF_READY=NO"
        echo "NEXT_GATE=RETURN_PVTECH_AND_DIRECTIVE_MATRIX_FOR_MANUAL_REVIEW"
    } >"$STATUS_REPORT"

    echo
    echo "===== PREPROCESSOR REVIEW STATUS ====="
    cat "$STATUS_REPORT"

    echo
    echo "===== PRIMARY DIRECTIVE CONTEXT ====="
    cat "$PRIMARY_CONTEXT_REPORT"

    echo
    echo "===== PRIMARY PRESET OPTIONS ====="
    cat "$PRIMARY_PRESET_REPORT"

    echo
    echo "===== DIRECTIVE TUPLE SUMMARY ====="
    cat "$TUPLE_REPORT"

    echo
    echo "===== PVTECH KEY LINES ====="
    cat "$PVTECH_KEY_REPORT"

    echo
    echo "===== PVTECH REFERENCE CANDIDATES ====="
    cat "$PVTECH_REFERENCE_REPORT"

    echo
    echo "===== PVTECH CONTENT FIRST 400 LINES ====="
    sed -n '1,400p' "$TECHLIB_PATH"

    echo
    echo "===== DIAGNOSTIC HASHES ====="
    find "$DIAGNOSTIC_ROOT" -type f ! -name SHA256SUMS \
        -print0 | sort -z | xargs -0 sha256sum | tee "$DIAGNOSTIC_ROOT/SHA256SUMS"

    if [ "$FINAL_STATUS" = "PASS" ]; then
        true
    else
        false
    fi
else
    if [ "$PACKAGE_SHA_CONSOLE" != "" ]; then
        rm -f "$PACKAGE_SHA_CONSOLE"
    fi
    echo "POSITION_PVS_DRC_PREPROCESSOR_REVIEW_STATUS=NOT_RUN"
    echo "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO"
    echo "PVS_EXECUTED=NO"
    echo "STOP_HERE_DO_NOT_RUN_PVS"
    false
fi
