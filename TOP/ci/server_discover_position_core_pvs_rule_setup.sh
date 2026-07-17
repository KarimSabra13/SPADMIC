#!/usr/bin/env bash
# Resolve the reviewed Position seed's relative pvtech mapping and collect
# bounded rule-setup evidence. This script never creates controls or runs PVS.

set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
EXPECTED_HEAD="${1:-MISSING}"
PREPROCESSOR_ROOT="${2:-MISSING}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"

PACKAGE="$WORK_ROOT/handoff/innovus/blocks/spadmic_position_core/innovus_ooc_harden_position_core_gridfit_20260717_114810"
PACKAGE_GDS="$PACKAGE/gds/spadmic_position_core.gds"
EXPECTED_GDS_SHA=ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1

PRIMARY_SEED=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/layoutverification/pvs_drc/spadmic_tx_packet_core
PRIMARY_CONTROL="$PRIMARY_SEED/pvsdrcctl"
TECHLIB_SOURCE=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/pvtech.lib

EXPECTED_STATUS_SHA=ba8d72355f691f0877a26d28b91de7c18c6a7f3c95c4a75bec76cd23430823c7
EXPECTED_SEMANTIC_SHA=88b2d8db9f27780bc7dfbd86cdf108ba6f1aa34bb20fe906711ab1c6e440d215
EXPECTED_MATRIX_SHA=6a62ab324fb378adf57dee66ab9b8faa5236ee91f3697cec7d5c1064968bf0ca
EXPECTED_TUPLE_SHA=57391e0160c0f4dbaad428cae0df4ca9c64d8c8f2cfe461062272b8a943c0a98
EXPECTED_CONTEXT_SHA=8d47f83059ad6d4cc64cdce8f4f3f49f78a946b0eb2f5de71d7816c7e9603a1d
EXPECTED_PRESET_SHA=8b2159c071af3752ac34c297951f90db832a627cdd2936c696d99b098ed7216c
EXPECTED_TECHLIB_SHA=1fe31de76c4b1c0d69afe6bdb31ccad89dd1f43429697f5043c57d4547a93bef
EXPECTED_TECHLIB_KEY_SHA=087a45812f6b7ae1103afdc3f4eedeb4ecea56ece936e2ca43a86c54758c69ba
EXPECTED_TECHLIB_REFERENCE_SHA=a25613e1d98192afc6a35fbb275867701fb8351d323eca9821f0b0aceb0da3b6
EXPECTED_PRIMARY_CONTROL_SHA=b9a8451c6cc43647ec606ae706e450893e3673e22215dc5a64edeeb383b902ef

RUN_OK=1
CD_RC=NOT_RUN
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
INPUT_FILE_GATE_RC=NOT_RUN
INPUT_HASH_GATE_RC=NOT_RUN
INPUT_STATUS_GATE_RC=NOT_RUN
PACKAGE_GATE_RC=NOT_RUN
PACKAGE_SHA_MANIFEST_RC=NOT_RUN
PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=NOT_RUN
SOURCE_IDENTITY_GATE_RC=NOT_RUN
DIAGNOSTIC_CREATE_RC=NOT_RUN
DIAGNOSTIC_COPY_GATE_RC=NOT_RUN
RULE_SETUP_COLLECTOR_RC=NOT_RUN
RULE_SETUP_COLLECTOR_GATE_RC=NOT_RUN
SOURCE_POST_RECHECK_RC=NOT_RUN
PACKAGE_SHA_CONSOLE=""

if [ "$EXPECTED_HEAD" = "MISSING" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: expected repository HEAD argument missing"
    RUN_OK=0
fi

if [ "$PREPROCESSOR_ROOT" = "MISSING" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: preprocessor-review root argument missing"
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
    INPUT_STATUS="$PREPROCESSOR_ROOT/preprocessor_review_status.rpt"
    INPUT_SEMANTIC="$PREPROCESSOR_ROOT/preprocessor_semantic_classification.rpt"
    INPUT_MATRIX="$PREPROCESSOR_ROOT/candidate_directive_matrix.tsv"
    INPUT_TUPLE="$PREPROCESSOR_ROOT/candidate_directive_tuple_summary.tsv"
    INPUT_CONTEXT="$PREPROCESSOR_ROOT/primary_directive_context.rpt"
    INPUT_PRESET="$PREPROCESSOR_ROOT/primary_preset_option_extract.rpt"
    INPUT_TECHLIB="$PREPROCESSOR_ROOT/technology/pvtech.lib"
    INPUT_TECHLIB_KEY="$PREPROCESSOR_ROOT/technology/pvtech_key_lines.rpt"
    INPUT_TECHLIB_REFERENCE="$PREPROCESSOR_ROOT/technology/pvtech_reference_candidates.rpt"
    INPUT_FILE_GATE_RC=0

    for FILE in \
        "$INPUT_STATUS" \
        "$INPUT_SEMANTIC" \
        "$INPUT_MATRIX" \
        "$INPUT_TUPLE" \
        "$INPUT_CONTEXT" \
        "$INPUT_PRESET" \
        "$INPUT_TECHLIB" \
        "$INPUT_TECHLIB_KEY" \
        "$INPUT_TECHLIB_REFERENCE"
    do
        if [ ! -s "$FILE" ]; then
            echo "MISSING_OR_EMPTY=$FILE"
            INPUT_FILE_GATE_RC=1
        fi
    done

    echo "INPUT_FILE_GATE_RC=$INPUT_FILE_GATE_RC"
    if [ "$INPUT_FILE_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: preprocessor-review evidence missing"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    INPUT_HASH_GATE_RC=0
    for SPEC in \
        "$INPUT_STATUS|$EXPECTED_STATUS_SHA" \
        "$INPUT_SEMANTIC|$EXPECTED_SEMANTIC_SHA" \
        "$INPUT_MATRIX|$EXPECTED_MATRIX_SHA" \
        "$INPUT_TUPLE|$EXPECTED_TUPLE_SHA" \
        "$INPUT_CONTEXT|$EXPECTED_CONTEXT_SHA" \
        "$INPUT_PRESET|$EXPECTED_PRESET_SHA" \
        "$INPUT_TECHLIB|$EXPECTED_TECHLIB_SHA" \
        "$INPUT_TECHLIB_KEY|$EXPECTED_TECHLIB_KEY_SHA" \
        "$INPUT_TECHLIB_REFERENCE|$EXPECTED_TECHLIB_REFERENCE_SHA"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_SHA="${SPEC#*|}"
        ACTUAL_SHA="$(sha256sum "$FILE" | awk '{print $1}')"
        echo "INPUT_FILE=$FILE"
        echo "INPUT_EXPECTED_SHA256=$EXPECTED_SHA"
        echo "INPUT_ACTUAL_SHA256=$ACTUAL_SHA"
        if [ "$EXPECTED_SHA" != "$ACTUAL_SHA" ]; then
            INPUT_HASH_GATE_RC=1
        fi
    done

    echo "INPUT_HASH_GATE_RC=$INPUT_HASH_GATE_RC"
    if [ "$INPUT_HASH_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: preprocessor-review hashes changed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    INPUT_STATUS_GATE_RC=0
    for EXPECTED_LINE in \
        "STATUS=PASS" \
        "MATRIX_CANDIDATE_COUNT=114" \
        "MATRIX_INCOMPLETE_COUNT=0" \
        "UNIQUE_DIRECTIVE_TUPLE_COUNT=2" \
        "MATRIX_COMPLETENESS_STATUS=PASS" \
        "TECHLIB_PATH=$TECHLIB_SOURCE" \
        "TECHLIB_BYTES=52" \
        "TECHLIB_SHA256=$EXPECTED_TECHLIB_SHA" \
        "PREPROCESSOR_SEMANTIC_REVIEW_STATUS=REVIEW_REQUIRED" \
        "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO" \
        "PVS_REPLAY_AUTHORIZED=NO" \
        "PVS_EXECUTED=NO" \
        "NEXT_GATE=RETURN_PVTECH_AND_DIRECTIVE_MATRIX_FOR_MANUAL_REVIEW"
    do
        grep -Fqx "$EXPECTED_LINE" "$INPUT_STATUS"
        LINE_RC=$?
        echo "INPUT_STATUS_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"
        if [ "$LINE_RC" -ne 0 ]; then
            INPUT_STATUS_GATE_RC=1
        fi
    done

    echo "INPUT_STATUS_GATE_RC=$INPUT_STATUS_GATE_RC"
    if [ "$INPUT_STATUS_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: preprocessor-review status changed"
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

    ACTUAL_GDS_SHA="$(sha256sum "$PACKAGE_GDS" 2>/dev/null | awk '{print $1}')"
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
    SOURCE_IDENTITY_GATE_RC=0
    ACTUAL_TECHLIB_SHA="$(sha256sum "$TECHLIB_SOURCE" 2>/dev/null | awk '{print $1}')"
    ACTUAL_PRIMARY_CONTROL_SHA="$(sha256sum "$PRIMARY_CONTROL" 2>/dev/null | awk '{print $1}')"

    if [ "$ACTUAL_TECHLIB_SHA" != "$EXPECTED_TECHLIB_SHA" ] || \
       [ "$ACTUAL_PRIMARY_CONTROL_SHA" != "$EXPECTED_PRIMARY_CONTROL_SHA" ]; then
        SOURCE_IDENTITY_GATE_RC=1
    fi

    echo "EXPECTED_TECHLIB_SHA=$EXPECTED_TECHLIB_SHA"
    echo "ACTUAL_TECHLIB_SHA=$ACTUAL_TECHLIB_SHA"
    echo "EXPECTED_PRIMARY_CONTROL_SHA=$EXPECTED_PRIMARY_CONTROL_SHA"
    echo "ACTUAL_PRIMARY_CONTROL_SHA=$ACTUAL_PRIMARY_CONTROL_SHA"
    echo "SOURCE_IDENTITY_GATE_RC=$SOURCE_IDENTITY_GATE_RC"
    if [ "$SOURCE_IDENTITY_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: source rule setup or seed control changed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    PACKAGE_SHA_CONSOLE="$WORK_ROOT/diagnostics/position_rule_setup_package_sha_$$.rpt"
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
    DIAGNOSTIC_ID="position_pvs_drc_rule_setup_discovery_$(date +%Y%m%d_%H%M%S)"
    DIAGNOSTIC_ROOT="$WORK_ROOT/diagnostics/$DIAGNOSTIC_ID"
    mkdir -p \
        "$DIAGNOSTIC_ROOT/source_preprocessor_review" \
        "$DIAGNOSTIC_ROOT/rule_setup"
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
        "$INPUT_STATUS|$DIAGNOSTIC_ROOT/source_preprocessor_review/preprocessor_review_status.rpt" \
        "$INPUT_SEMANTIC|$DIAGNOSTIC_ROOT/source_preprocessor_review/preprocessor_semantic_classification.rpt" \
        "$INPUT_MATRIX|$DIAGNOSTIC_ROOT/source_preprocessor_review/candidate_directive_matrix.tsv" \
        "$INPUT_TUPLE|$DIAGNOSTIC_ROOT/source_preprocessor_review/candidate_directive_tuple_summary.tsv" \
        "$INPUT_TECHLIB|$DIAGNOSTIC_ROOT/source_preprocessor_review/pvtech.lib" \
        "$PACKAGE_SHA_CONSOLE|$DIAGNOSTIC_ROOT/package_sha256_check.rpt"
    do
        SOURCE_FILE="${SPEC%%|*}"
        DESTINATION_FILE="${SPEC#*|}"
        cp -p "$SOURCE_FILE" "$DESTINATION_FILE"
        if [ "$?" -ne 0 ]; then
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
    python3 TOP/pnr/scripts/collect_position_pvs_rule_setup.py \
        --techlib "$TECHLIB_SOURCE" \
        --candidate-matrix "$INPUT_MATRIX" \
        --output-dir "$DIAGNOSTIC_ROOT/rule_setup" \
        --technology XH018_1131 \
        --expected-mapping .pvsSetup/PVS \
        --expected-candidate-count 114
    RULE_SETUP_COLLECTOR_RC=$?

    COLLECTOR_STATUS_REPORT="$DIAGNOSTIC_ROOT/rule_setup/rule_setup_collector_status.rpt"
    RULE_SETUP_COLLECTOR_GATE_RC=0
    for EXPECTED_LINE in \
        "COLLECTOR_STATUS=PASS" \
        "TECHLIB_PATH=$TECHLIB_SOURCE" \
        "TECHLIB_SHA256=$EXPECTED_TECHLIB_SHA" \
        "MAPPING_RAW=.pvsSetup/PVS" \
        "MAPPING_GATE_STATUS=PASS" \
        "MATRIX_CANDIDATE_COUNT=114" \
        "VAR_ANT_DEFINED_CANDIDATE_COUNT=3" \
        "MATRIX_GATE_STATUS=PASS" \
        "RULE_SETUP_SCAN_STATUS=PASS" \
        "SOURCE_RECHECK_STATUS=PASS" \
        "PREPROCESSOR_SEMANTIC_REVIEW_STATUS=REVIEW_REQUIRED" \
        "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO" \
        "PVS_REPLAY_AUTHORIZED=NO" \
        "PVS_EXECUTED=NO"
    do
        grep -Fqx "$EXPECTED_LINE" "$COLLECTOR_STATUS_REPORT" 2>/dev/null
        LINE_RC=$?
        echo "COLLECTOR_STATUS_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"
        if [ "$LINE_RC" -ne 0 ]; then
            RULE_SETUP_COLLECTOR_GATE_RC=1
        fi
    done

    echo "RULE_SETUP_COLLECTOR_RC=$RULE_SETUP_COLLECTOR_RC"
    echo "RULE_SETUP_COLLECTOR_GATE_RC=$RULE_SETUP_COLLECTOR_GATE_RC"
fi

if [ "$RUN_OK" -eq 1 ]; then
    SOURCE_POST_RECHECK_RC=0
    ACTUAL_TECHLIB_POST_SHA="$(sha256sum "$TECHLIB_SOURCE" | awk '{print $1}')"
    ACTUAL_PRIMARY_CONTROL_POST_SHA="$(sha256sum "$PRIMARY_CONTROL" | awk '{print $1}')"
    ACTUAL_MATRIX_POST_SHA="$(sha256sum "$INPUT_MATRIX" | awk '{print $1}')"

    if [ "$ACTUAL_TECHLIB_POST_SHA" != "$EXPECTED_TECHLIB_SHA" ] || \
       [ "$ACTUAL_PRIMARY_CONTROL_POST_SHA" != "$EXPECTED_PRIMARY_CONTROL_SHA" ] || \
       [ "$ACTUAL_MATRIX_POST_SHA" != "$EXPECTED_MATRIX_SHA" ]; then
        SOURCE_POST_RECHECK_RC=1
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
    if [ "$RULE_SETUP_COLLECTOR_RC" -ne 0 ] || \
       [ "$RULE_SETUP_COLLECTOR_GATE_RC" -ne 0 ] || \
       [ "$SOURCE_POST_RECHECK_RC" -ne 0 ] || \
       [ "$PACKAGE_POST_REVIEW_SHA_MANIFEST_RC" -ne 0 ]; then
        FINAL_STATUS=FAIL
    fi

    WRAPPER_STATUS_REPORT="$DIAGNOSTIC_ROOT/rule_setup_discovery_status.rpt"
    {
        echo "LABEL=SPADMIC_POSITION_PVS_DRC_RULE_SETUP_DISCOVERY"
        echo "STATUS=$FINAL_STATUS"
        echo "RESULT=RELATIVE_PVTECH_MAPPING_AND_RULE_SETUP_RECORDED_FOR_MANUAL_REVIEW"
        echo "SOURCE_PREPROCESSOR_ROOT=$PREPROCESSOR_ROOT"
        echo "SOURCE_PREPROCESSOR_STATUS_SHA256=$EXPECTED_STATUS_SHA"
        echo "PACKAGE=$PACKAGE"
        echo "PACKAGE_GDS_SHA256=$EXPECTED_GDS_SHA"
        echo "PRIMARY_SEED=$PRIMARY_SEED"
        echo "TECHLIB_SOURCE=$TECHLIB_SOURCE"
        echo "TECHLIB_SHA256=$EXPECTED_TECHLIB_SHA"
        echo "PVTECH_MAPPING_RAW=.pvsSetup/PVS"
        echo "PREVIOUS_REFERENCE_RENDERING=/PVS"
        echo "PREVIOUS_REFERENCE_RENDERING_STATUS=TRUNCATED_RELATIVE_TOKEN"
        echo "MATRIX_CANDIDATE_COUNT=114"
        echo "VAR_ANT_DEFINED_CANDIDATE_COUNT=3"
        echo "RULE_SETUP_COLLECTOR_RC=$RULE_SETUP_COLLECTOR_RC"
        echo "RULE_SETUP_COLLECTOR_GATE_RC=$RULE_SETUP_COLLECTOR_GATE_RC"
        echo "SOURCE_POST_RECHECK_RC=$SOURCE_POST_RECHECK_RC"
        echo "PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=$PACKAGE_POST_REVIEW_SHA_MANIFEST_RC"
        echo "PACKAGE_MODIFIED=NO"
        echo "SOURCE_TEMPLATE_WRITE_ATTEMPTED=NO"
        echo "RULE_DECK_COPIED=NO"
        echo "PVS_TEMPLATE_CREATED=NO"
        echo "PREPROCESSOR_SEMANTIC_REVIEW_STATUS=REVIEW_REQUIRED"
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
        echo "NEXT_GATE=POSITION_PVS_DRC_RULE_SETUP_MANUAL_REVIEW"
    } >"$WRAPPER_STATUS_REPORT"

    echo
    echo "===== RULE SETUP DISCOVERY STATUS ====="
    cat "$WRAPPER_STATUS_REPORT"

    for REPORT in \
        rule_setup_collector_status.rpt \
        pvtech_mapping_resolution.rpt \
        var_ant_defined_candidates.tsv \
        directive_symbol_file_summary.tsv \
        directive_context_excerpt.rpt \
        rule_reference_excerpt.rpt
    do
        echo
        echo "===== $DIAGNOSTIC_ROOT/rule_setup/$REPORT ====="
        sed -n '1,500p' "$DIAGNOSTIC_ROOT/rule_setup/$REPORT"
    done

    echo
    echo "===== RULE SETUP INVENTORY FIRST 300 LINES ====="
    sed -n '1,300p' "$DIAGNOSTIC_ROOT/rule_setup/rule_setup_inventory.tsv"

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
    echo "POSITION_PVS_DRC_RULE_SETUP_DISCOVERY_STATUS=NOT_RUN"
    echo "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO"
    echo "PVS_EXECUTED=NO"
    echo "STOP_HERE_DO_NOT_RUN_PVS"
    false
fi
