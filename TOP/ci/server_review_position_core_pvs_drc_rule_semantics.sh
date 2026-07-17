#!/usr/bin/env bash
# Capture named rule-set and complete preprocessor-block evidence for Position.
# This script is read-only with respect to the package, seed, and PDK and never runs PVS.

set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
EXPECTED_HEAD="${1:-MISSING}"
RULE_SETUP_ROOT="${2:-MISSING}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"

PACKAGE="$WORK_ROOT/handoff/innovus/blocks/spadmic_position_core/innovus_ooc_harden_position_core_gridfit_20260717_114810"
PACKAGE_GDS="$PACKAGE/gds/spadmic_position_core.gds"
EXPECTED_GDS_SHA=ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1

PROJECT_ROOT=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0
PRIMARY_SEED="$PROJECT_ROOT/layoutverification/pvs_drc/spadmic_tx_packet_core"
TECHLIB_SOURCE="$PROJECT_ROOT/pvtech.lib"
PROJECT_PVS_ROOT="$PROJECT_ROOT/.pvsSetup/PVS"
PDK_PVS_ROOT=/data/pdk/xfab/xh018/cadence/v10_1/pvs/v10_1_1/PVS

PROJECT_TECHRULESETS="$PROJECT_PVS_ROOT/techRuleSets"
PDK_TECHRULESETS="$PDK_PVS_ROOT/XH018_1131/techRuleSets"
METALSWITCH="$PDK_PVS_ROOT/XH018_1131/xh018_1131"
PVS_REVISION="$PDK_PVS_ROOT/PVS.revision"
DRC_RULE="$PDK_PVS_ROOT/xh018_DRC.rul"
PVS_CONFIG="$PDK_PVS_ROOT/pvs.cfg"
DUMMY_CONFIG="$PDK_PVS_ROOT/dummy.cfg"
DUMMY_OUTPUT="$PDK_PVS_ROOT/dummy_out.pvl"
DENSITY_SELECTOR="$PDK_PVS_ROOT/density.pvl"
USER_GUIDE="$PDK_PVS_ROOT/doc/UserGuide-Cadence_IC61_PVS.pdf"

EXPECTED_RULE_SETUP_STATUS_SHA=b54eb78f97839ddfc0b782576e04ecc64d2f327a4cd0c7c43764d8d1a6b95f04
EXPECTED_COLLECTOR_STATUS_SHA=1b6d709cd5f4f71c32b2d53206ee829f9b7251456445a205b25b002c30a6d01b
EXPECTED_MAPPING_SHA=53b8e83f9a748079175f69f46854f46e89983db4e3ea998c5e18810124027e49
EXPECTED_REFERENCE_SHA=ca84df7c40fa1cdcc15e4d8646c7ea2118de922ce5700bb19b8d520b7e47e644
EXPECTED_SYMBOL_SUMMARY_SHA=95592a51040f7dadc2e7455ca5621f7cf461d0d234c0c5163413309f631c389d
EXPECTED_CONTEXT_SHA=8c844c165c9a0d865cf5df6f3d9064c70dd53d8a609372dc947f6db0d203ca86
EXPECTED_INVENTORY_SHA=5c31d310198c6043e7da76ed6c342a76cede097aafa92f858f6a0933db990b52
EXPECTED_SEARCH_ROOTS_SHA=486ff42036baf83797fd90fe5fa14c0cfa73fca09adc27b8940a2ee5672dc3e9
EXPECTED_SKIPPED_SHA=b496639fd319952c50d511afacf6cd4e3344174b1c809bdf4b8b2a8ed1149e1b
EXPECTED_VAR_ANT_CANDIDATES_SHA=94e63bd114163b890a4e64475fe59d59023537a3db70bc90b89e77933ec7536d
EXPECTED_PACKAGE_CHECK_SHA=51323c7f850d1afa5b1618ec1574a8794d3d5427a7a9518c6378a76a0914eb99

EXPECTED_TECHLIB_SHA=1fe31de76c4b1c0d69afe6bdb31ccad89dd1f43429697f5043c57d4547a93bef
EXPECTED_DRC_RULE_SHA=0b1ce563da515dd50d17a5e16baa2a2addc10354aa06ab5e1a111b01ed039cb6
EXPECTED_PVS_CONFIG_SHA=c4e82fbcca0db9454924969d010aab6b34ab480bc44a3a28aa53e26b73a1ead7
EXPECTED_DUMMY_CONFIG_SHA=a6a2d818fb2b6c43ec1ea170dcdf20fdc04ec36c873f2384ac55d1a458d7624d
EXPECTED_DUMMY_OUTPUT_SHA=53e05918c7e131558adbb82b4a31df87794b13454e5e355fa9ef5267211b4e2a
EXPECTED_DENSITY_SELECTOR_SHA=d83f4531a59700a84a7f52c5ad285399c458afdc8a1c78e15109570e903bb3b3
EXPECTED_PROJECT_TECHRULESETS_BYTES=1867
EXPECTED_PDK_TECHRULESETS_BYTES=941
EXPECTED_METALSWITCH_BYTES=741
EXPECTED_PVS_REVISION_BYTES=52
EXPECTED_USER_GUIDE_BYTES=625066

EXPECTED_CONFIG_RUL_SHA=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
EXPECTED_PRESET_SHA=97b3a7e63c3e8a01ea1291a19de384e2c41f77cd11653a92c7f5618e73421000
EXPECTED_TECHNOLOGY_RUL_SHA=74a297facf6422635df2c58d79aa8b8ae46ca0b8232380471a88a182d8400ab6
EXPECTED_PIPO_SHA=949ce7ec915d1ddbd3e78534720c33aad9036d83932c6bac33730a113aba00dd
EXPECTED_PVSDRCCTL_SHA=b9a8451c6cc43647ec606ae706e450893e3673e22215dc5a64edeeb383b902ef
EXPECTED_RUN_PVS_SHA=11ae3fc935041b8a4e0f3b406941c699c769ed1d50a504e8df36fcb544c7255a

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
SOURCE_FILE_GATE_RC=NOT_RUN
SOURCE_REFERENCE_GATE_RC=NOT_RUN
SOURCE_IDENTITY_GATE_RC=NOT_RUN
PACKAGE_SHA_MANIFEST_RC=NOT_RUN
DIAGNOSTIC_CREATE_RC=NOT_RUN
DIAGNOSTIC_COPY_GATE_RC=NOT_RUN
SEMANTICS_COLLECTOR_RC=NOT_RUN
SEMANTICS_COLLECTOR_GATE_RC=NOT_RUN
SOURCE_POST_RECHECK_RC=NOT_RUN
PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=NOT_RUN
PACKAGE_SHA_CONSOLE=""

if [ "$EXPECTED_HEAD" = "MISSING" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: expected repository HEAD argument missing"
    RUN_OK=0
fi

if [ "$RULE_SETUP_ROOT" = "MISSING" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: rule-setup diagnostic root argument missing"
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
    INPUT_STATUS="$RULE_SETUP_ROOT/rule_setup_discovery_status.rpt"
    INPUT_COLLECTOR="$RULE_SETUP_ROOT/rule_setup/rule_setup_collector_status.rpt"
    INPUT_MAPPING="$RULE_SETUP_ROOT/rule_setup/pvtech_mapping_resolution.rpt"
    INPUT_REFERENCE="$RULE_SETUP_ROOT/rule_setup/rule_reference_excerpt.rpt"
    INPUT_SYMBOL_SUMMARY="$RULE_SETUP_ROOT/rule_setup/directive_symbol_file_summary.tsv"
    INPUT_CONTEXT="$RULE_SETUP_ROOT/rule_setup/directive_context_excerpt.rpt"
    INPUT_INVENTORY="$RULE_SETUP_ROOT/rule_setup/rule_setup_inventory.tsv"
    INPUT_SEARCH_ROOTS="$RULE_SETUP_ROOT/rule_setup/rule_setup_search_roots.rpt"
    INPUT_SKIPPED="$RULE_SETUP_ROOT/rule_setup/rule_setup_skipped_files.tsv"
    INPUT_VAR_ANT="$RULE_SETUP_ROOT/rule_setup/var_ant_defined_candidates.tsv"
    INPUT_PACKAGE_CHECK="$RULE_SETUP_ROOT/package_sha256_check.rpt"
    INPUT_PACKAGE_POST="$RULE_SETUP_ROOT/package_sha256_post_review.rpt"

    INPUT_FILE_GATE_RC=0
    for FILE in \
        "$INPUT_STATUS" \
        "$INPUT_COLLECTOR" \
        "$INPUT_MAPPING" \
        "$INPUT_REFERENCE" \
        "$INPUT_SYMBOL_SUMMARY" \
        "$INPUT_CONTEXT" \
        "$INPUT_INVENTORY" \
        "$INPUT_SEARCH_ROOTS" \
        "$INPUT_SKIPPED" \
        "$INPUT_VAR_ANT" \
        "$INPUT_PACKAGE_CHECK" \
        "$INPUT_PACKAGE_POST"
    do
        if [ ! -s "$FILE" ]; then
            echo "MISSING_OR_EMPTY=$FILE"
            INPUT_FILE_GATE_RC=1
        fi
    done

    echo "INPUT_FILE_GATE_RC=$INPUT_FILE_GATE_RC"
    if [ "$INPUT_FILE_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: rule-setup evidence missing"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    INPUT_HASH_GATE_RC=0
    for SPEC in \
        "$INPUT_STATUS|$EXPECTED_RULE_SETUP_STATUS_SHA" \
        "$INPUT_COLLECTOR|$EXPECTED_COLLECTOR_STATUS_SHA" \
        "$INPUT_MAPPING|$EXPECTED_MAPPING_SHA" \
        "$INPUT_REFERENCE|$EXPECTED_REFERENCE_SHA" \
        "$INPUT_SYMBOL_SUMMARY|$EXPECTED_SYMBOL_SUMMARY_SHA" \
        "$INPUT_CONTEXT|$EXPECTED_CONTEXT_SHA" \
        "$INPUT_INVENTORY|$EXPECTED_INVENTORY_SHA" \
        "$INPUT_SEARCH_ROOTS|$EXPECTED_SEARCH_ROOTS_SHA" \
        "$INPUT_SKIPPED|$EXPECTED_SKIPPED_SHA" \
        "$INPUT_VAR_ANT|$EXPECTED_VAR_ANT_CANDIDATES_SHA" \
        "$INPUT_PACKAGE_CHECK|$EXPECTED_PACKAGE_CHECK_SHA" \
        "$INPUT_PACKAGE_POST|$EXPECTED_PACKAGE_CHECK_SHA"
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
        echo "STOP_HERE_DO_NOT_CONTINUE: rule-setup evidence hashes changed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    INPUT_STATUS_GATE_RC=0
    for EXPECTED_LINE in \
        "STATUS=PASS" \
        "RESULT=RELATIVE_PVTECH_MAPPING_AND_RULE_SETUP_RECORDED_FOR_MANUAL_REVIEW" \
        "PACKAGE_GDS_SHA256=$EXPECTED_GDS_SHA" \
        "PVTECH_MAPPING_RAW=.pvsSetup/PVS" \
        "MATRIX_CANDIDATE_COUNT=114" \
        "VAR_ANT_DEFINED_CANDIDATE_COUNT=3" \
        "PREPROCESSOR_SEMANTIC_REVIEW_STATUS=REVIEW_REQUIRED" \
        "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO" \
        "PVS_REPLAY_AUTHORIZED=NO" \
        "PVS_EXECUTED=NO" \
        "NEXT_GATE=POSITION_PVS_DRC_RULE_SETUP_MANUAL_REVIEW"
    do
        grep -Fqx "$EXPECTED_LINE" "$INPUT_STATUS"
        LINE_RC=$?
        echo "INPUT_STATUS_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"
        if [ "$LINE_RC" -ne 0 ]; then
            INPUT_STATUS_GATE_RC=1
        fi
    done

    for EXPECTED_LINE in \
        "COLLECTOR_STATUS=PASS" \
        "MAPPING_RAW=.pvsSetup/PVS" \
        "MAPPING_GATE_STATUS=PASS" \
        "MATRIX_CANDIDATE_COUNT=114" \
        "VAR_ANT_DEFINED_CANDIDATE_COUNT=3" \
        "RULE_SETUP_SCAN_STATUS=PASS" \
        "SOURCE_RECHECK_STATUS=PASS" \
        "PVS_EXECUTED=NO"
    do
        grep -Fqx "$EXPECTED_LINE" "$INPUT_COLLECTOR"
        LINE_RC=$?
        echo "INPUT_COLLECTOR_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"
        if [ "$LINE_RC" -ne 0 ]; then
            INPUT_STATUS_GATE_RC=1
        fi
    done

    echo "INPUT_STATUS_GATE_RC=$INPUT_STATUS_GATE_RC"
    if [ "$INPUT_STATUS_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: rule-setup evidence status changed"
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
    SOURCE_FILE_GATE_RC=0
    for FILE in \
        "$TECHLIB_SOURCE" \
        "$PROJECT_TECHRULESETS" \
        "$PDK_TECHRULESETS" \
        "$METALSWITCH" \
        "$PVS_REVISION" \
        "$DRC_RULE" \
        "$PVS_CONFIG" \
        "$DUMMY_CONFIG" \
        "$DUMMY_OUTPUT" \
        "$DENSITY_SELECTOR" \
        "$USER_GUIDE" \
        "$PRIMARY_SEED/.config.rul" \
        "$PRIMARY_SEED/.preset.autosave" \
        "$PRIMARY_SEED/.technology.rul" \
        "$PRIMARY_SEED/pipo1.setup" \
        "$PRIMARY_SEED/pvsdrcctl" \
        "$PRIMARY_SEED/run.pvs"
    do
        if [ ! -f "$FILE" ]; then
            echo "MISSING=$FILE"
            SOURCE_FILE_GATE_RC=1
        fi
    done
    echo "SOURCE_FILE_GATE_RC=$SOURCE_FILE_GATE_RC"
    if [ "$SOURCE_FILE_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: source rule setup or seed control missing"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    SOURCE_REFERENCE_GATE_RC=0
    for SPEC in \
        "$PROJECT_TECHRULESETS|$EXPECTED_PROJECT_TECHRULESETS_BYTES" \
        "$PDK_TECHRULESETS|$EXPECTED_PDK_TECHRULESETS_BYTES" \
        "$METALSWITCH|$EXPECTED_METALSWITCH_BYTES" \
        "$PVS_REVISION|$EXPECTED_PVS_REVISION_BYTES" \
        "$USER_GUIDE|$EXPECTED_USER_GUIDE_BYTES"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_BYTES="${SPEC#*|}"
        ACTUAL_BYTES="$(wc -c <"$FILE" 2>/dev/null | tr -d '[:space:]')"
        echo "SOURCE_SIZE_FILE=$FILE"
        echo "SOURCE_EXPECTED_BYTES=$EXPECTED_BYTES"
        echo "SOURCE_ACTUAL_BYTES=$ACTUAL_BYTES"
        if [ "$ACTUAL_BYTES" != "$EXPECTED_BYTES" ]; then
            SOURCE_REFERENCE_GATE_RC=1
        fi
    done

    for SPEC in \
        "$PROJECT_TECHRULESETS|../../.xkit/setup/xh018/cadence/pvs/PVS/XH018_1131/metalswitch.pvl" \
        "$PROJECT_TECHRULESETS|../../.xkit/setup/xh018/cadence/pvs/PVS/XH018_1131/../xh018_DRC.rul" \
        "$PDK_TECHRULESETS|metalswitch.pvl" \
        "$PDK_TECHRULESETS|../xh018_DRC.rul"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_TEXT="${SPEC#*|}"
        grep -Fq "$EXPECTED_TEXT" "$FILE"
        MATCH_RC=$?
        echo "SOURCE_REFERENCE_LINE_RC=$MATCH_RC FILE=$FILE EXPECTED=$EXPECTED_TEXT"
        if [ "$MATCH_RC" -ne 0 ]; then
            SOURCE_REFERENCE_GATE_RC=1
        fi
    done

    echo "SOURCE_REFERENCE_GATE_RC=$SOURCE_REFERENCE_GATE_RC"
    if [ "$SOURCE_REFERENCE_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: unpinned rule metadata no longer matches prior inventory"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    SOURCE_IDENTITY_GATE_RC=0
    for SPEC in \
        "$TECHLIB_SOURCE|$EXPECTED_TECHLIB_SHA" \
        "$DRC_RULE|$EXPECTED_DRC_RULE_SHA" \
        "$PVS_CONFIG|$EXPECTED_PVS_CONFIG_SHA" \
        "$DUMMY_CONFIG|$EXPECTED_DUMMY_CONFIG_SHA" \
        "$DUMMY_OUTPUT|$EXPECTED_DUMMY_OUTPUT_SHA" \
        "$DENSITY_SELECTOR|$EXPECTED_DENSITY_SELECTOR_SHA" \
        "$PRIMARY_SEED/.config.rul|$EXPECTED_CONFIG_RUL_SHA" \
        "$PRIMARY_SEED/.preset.autosave|$EXPECTED_PRESET_SHA" \
        "$PRIMARY_SEED/.technology.rul|$EXPECTED_TECHNOLOGY_RUL_SHA" \
        "$PRIMARY_SEED/pipo1.setup|$EXPECTED_PIPO_SHA" \
        "$PRIMARY_SEED/pvsdrcctl|$EXPECTED_PVSDRCCTL_SHA" \
        "$PRIMARY_SEED/run.pvs|$EXPECTED_RUN_PVS_SHA"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_SHA="${SPEC#*|}"
        ACTUAL_SHA="$(sha256sum "$FILE" 2>/dev/null | awk '{print $1}')"
        echo "SOURCE_FILE=$FILE"
        echo "SOURCE_EXPECTED_SHA256=$EXPECTED_SHA"
        echo "SOURCE_ACTUAL_SHA256=$ACTUAL_SHA"
        if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
            SOURCE_IDENTITY_GATE_RC=1
        fi
    done

    echo "SOURCE_IDENTITY_GATE_RC=$SOURCE_IDENTITY_GATE_RC"
    if [ "$SOURCE_IDENTITY_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: pinned PDK or seed source changed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    PACKAGE_SHA_CONSOLE="$WORK_ROOT/diagnostics/position_rule_semantics_package_sha_$$.rpt"
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
    DIAGNOSTIC_ID="position_pvs_drc_rule_semantics_review_$(date +%Y%m%d_%H%M%S)"
    DIAGNOSTIC_ROOT="$WORK_ROOT/diagnostics/$DIAGNOSTIC_ID"
    mkdir -p "$DIAGNOSTIC_ROOT/source_rule_setup" "$DIAGNOSTIC_ROOT/rule_semantics"
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
        "$INPUT_STATUS|$DIAGNOSTIC_ROOT/source_rule_setup/rule_setup_discovery_status.rpt" \
        "$INPUT_COLLECTOR|$DIAGNOSTIC_ROOT/source_rule_setup/rule_setup_collector_status.rpt" \
        "$INPUT_MAPPING|$DIAGNOSTIC_ROOT/source_rule_setup/pvtech_mapping_resolution.rpt" \
        "$INPUT_REFERENCE|$DIAGNOSTIC_ROOT/source_rule_setup/rule_reference_excerpt.rpt" \
        "$INPUT_SYMBOL_SUMMARY|$DIAGNOSTIC_ROOT/source_rule_setup/directive_symbol_file_summary.tsv" \
        "$INPUT_VAR_ANT|$DIAGNOSTIC_ROOT/source_rule_setup/var_ant_defined_candidates.tsv" \
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
    python3 TOP/pnr/scripts/collect_position_pvs_rule_semantics.py \
        --project-techrulesets "$PROJECT_TECHRULESETS" \
        --pdk-techrulesets "$PDK_TECHRULESETS" \
        --metalswitch "$METALSWITCH" \
        --revision "$PVS_REVISION" \
        --drc-rule "$DRC_RULE" \
        --pvs-config "$PVS_CONFIG" \
        --dummy-config "$DUMMY_CONFIG" \
        --dummy-output "$DUMMY_OUTPUT" \
        --density-selector "$DENSITY_SELECTOR" \
        --user-guide "$USER_GUIDE" \
        --output-dir "$DIAGNOSTIC_ROOT/rule_semantics" \
        --expected-drc-sha "$EXPECTED_DRC_RULE_SHA" \
        --expected-pvs-config-sha "$EXPECTED_PVS_CONFIG_SHA" \
        --expected-dummy-config-sha "$EXPECTED_DUMMY_CONFIG_SHA" \
        --expected-dummy-output-sha "$EXPECTED_DUMMY_OUTPUT_SHA" \
        --expected-density-selector-sha "$EXPECTED_DENSITY_SELECTOR_SHA"
    SEMANTICS_COLLECTOR_RC=$?

    COLLECTOR_STATUS_REPORT="$DIAGNOSTIC_ROOT/rule_semantics/rule_semantics_collector_status.rpt"
    SEMANTICS_COLLECTOR_GATE_RC=0
    for EXPECTED_LINE in \
        "COLLECTOR_STATUS=PASS" \
        "SOURCE_REQUIRED_FILE_GATE_STATUS=PASS" \
        "KNOWN_SOURCE_HASH_GATE_STATUS=PASS" \
        "SOURCE_RECHECK_STATUS=PASS" \
        "DRC_RULE_SHA256=$EXPECTED_DRC_RULE_SHA" \
        "PVS_CONFIG_SHA256=$EXPECTED_PVS_CONFIG_SHA" \
        "DEFAULT_RULE_SET_EVIDENCE_STATUS=PASS" \
        "PVS_CONFIG_OPTION_DEFAULT_GATE_STATUS=PASS" \
        "UNMATCHED_CONDITIONAL_COUNT=0" \
        "DIRECTIVE_CONDITIONAL_BLOCK_GATE_STATUS=PASS" \
        "SEMANTIC_EVIDENCE_COLLECTION_STATUS=PASS" \
        "DEFAULT_RULE_SET_SELECTION_STATUS=REVIEW_REQUIRED" \
        "POPPING_APPLICABILITY_STATUS=REVIEW_REQUIRED" \
        "PIMIDE_APPLICABILITY_STATUS=REVIEW_REQUIRED" \
        "DUMMY_FILL_APPLICABILITY_STATUS=REVIEW_REQUIRED" \
        "VAR_ANT_RATIO_POLICY_STATUS=REVIEW_REQUIRED" \
        "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO" \
        "PVS_REPLAY_AUTHORIZED=NO" \
        "PVS_EXECUTED=NO"
    do
        grep -Fqx "$EXPECTED_LINE" "$COLLECTOR_STATUS_REPORT" 2>/dev/null
        LINE_RC=$?
        echo "COLLECTOR_STATUS_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"
        if [ "$LINE_RC" -ne 0 ]; then
            SEMANTICS_COLLECTOR_GATE_RC=1
        fi
    done

    for SYMBOL in DENSITY POPPING PIMIDE DUMMY_FILL VAR_ANT_RATIO
    do
        grep -Eq "^${SYMBOL}_CONDITIONAL_BLOCK_COUNT=[1-9][0-9]*$" "$COLLECTOR_STATUS_REPORT"
        LINE_RC=$?
        echo "COLLECTOR_BLOCK_COUNT_RC=$LINE_RC SYMBOL=$SYMBOL"
        if [ "$LINE_RC" -ne 0 ]; then
            SEMANTICS_COLLECTOR_GATE_RC=1
        fi
    done

    echo "SEMANTICS_COLLECTOR_RC=$SEMANTICS_COLLECTOR_RC"
    echo "SEMANTICS_COLLECTOR_GATE_RC=$SEMANTICS_COLLECTOR_GATE_RC"
fi

if [ "$RUN_OK" -eq 1 ]; then
    SOURCE_POST_RECHECK_RC=0
    for SPEC in \
        "$INPUT_STATUS|$EXPECTED_RULE_SETUP_STATUS_SHA" \
        "$TECHLIB_SOURCE|$EXPECTED_TECHLIB_SHA" \
        "$DRC_RULE|$EXPECTED_DRC_RULE_SHA" \
        "$PVS_CONFIG|$EXPECTED_PVS_CONFIG_SHA" \
        "$DUMMY_CONFIG|$EXPECTED_DUMMY_CONFIG_SHA" \
        "$DUMMY_OUTPUT|$EXPECTED_DUMMY_OUTPUT_SHA" \
        "$DENSITY_SELECTOR|$EXPECTED_DENSITY_SELECTOR_SHA" \
        "$PRIMARY_SEED/.config.rul|$EXPECTED_CONFIG_RUL_SHA" \
        "$PRIMARY_SEED/.preset.autosave|$EXPECTED_PRESET_SHA" \
        "$PRIMARY_SEED/.technology.rul|$EXPECTED_TECHNOLOGY_RUL_SHA" \
        "$PRIMARY_SEED/pipo1.setup|$EXPECTED_PIPO_SHA" \
        "$PRIMARY_SEED/pvsdrcctl|$EXPECTED_PVSDRCCTL_SHA" \
        "$PRIMARY_SEED/run.pvs|$EXPECTED_RUN_PVS_SHA"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_SHA="${SPEC#*|}"
        ACTUAL_SHA="$(sha256sum "$FILE" 2>/dev/null | awk '{print $1}')"
        if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
            SOURCE_POST_RECHECK_RC=1
        fi
    done

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
    if [ "$SEMANTICS_COLLECTOR_RC" -ne 0 ] || \
       [ "$SEMANTICS_COLLECTOR_GATE_RC" -ne 0 ] || \
       [ "$SOURCE_POST_RECHECK_RC" -ne 0 ] || \
       [ "$PACKAGE_POST_REVIEW_SHA_MANIFEST_RC" -ne 0 ]; then
        FINAL_STATUS=FAIL
    fi

    DEFAULT_RULE_SET_EVIDENCE_STATUS="$(
        awk -F= '$1 == "DEFAULT_RULE_SET_EVIDENCE_STATUS" {print $2}' \
            "$COLLECTOR_STATUS_REPORT" 2>/dev/null | tail -n 1
    )"
    if [ -z "$DEFAULT_RULE_SET_EVIDENCE_STATUS" ]; then
        DEFAULT_RULE_SET_EVIDENCE_STATUS=UNKNOWN
    fi

    WRAPPER_STATUS_REPORT="$DIAGNOSTIC_ROOT/rule_semantics_review_status.rpt"
    {
        echo "LABEL=SPADMIC_POSITION_PVS_DRC_RULE_SEMANTICS_REVIEW"
        echo "STATUS=$FINAL_STATUS"
        echo "RESULT=NAMED_RULE_SET_AND_CONDITIONAL_EVIDENCE_RECORDED_FOR_MANUAL_REVIEW"
        echo "SOURCE_RULE_SETUP_ROOT=$RULE_SETUP_ROOT"
        echo "SOURCE_RULE_SETUP_STATUS_SHA256=$EXPECTED_RULE_SETUP_STATUS_SHA"
        echo "PACKAGE=$PACKAGE"
        echo "PACKAGE_GDS_SHA256=$EXPECTED_GDS_SHA"
        echo "PRIMARY_SEED=$PRIMARY_SEED"
        echo "PROJECT_PVS_ROOT=$PROJECT_PVS_ROOT"
        echo "PDK_PVS_ROOT=$PDK_PVS_ROOT"
        echo "DRC_RULE_SHA256=$EXPECTED_DRC_RULE_SHA"
        echo "PVS_CONFIG_SHA256=$EXPECTED_PVS_CONFIG_SHA"
        echo "SEMANTICS_COLLECTOR_RC=$SEMANTICS_COLLECTOR_RC"
        echo "SEMANTICS_COLLECTOR_GATE_RC=$SEMANTICS_COLLECTOR_GATE_RC"
        echo "SOURCE_REFERENCE_GATE_RC=$SOURCE_REFERENCE_GATE_RC"
        echo "SOURCE_POST_RECHECK_RC=$SOURCE_POST_RECHECK_RC"
        echo "PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=$PACKAGE_POST_REVIEW_SHA_MANIFEST_RC"
        echo "DEFAULT_RULE_SET_EVIDENCE_STATUS=$DEFAULT_RULE_SET_EVIDENCE_STATUS"
        echo "DEFAULT_RULE_SET_SELECTION_STATUS=REVIEW_REQUIRED"
        echo "PREPROCESSOR_SEMANTIC_REVIEW_STATUS=REVIEW_REQUIRED"
        echo "PACKAGE_MODIFIED=NO"
        echo "SOURCE_TEMPLATE_WRITE_ATTEMPTED=NO"
        echo "RULE_DECK_COPIED=NO"
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
        echo "NEXT_GATE=RETURN_NAMED_RULE_SETS_AND_CONDITIONAL_BLOCKS_FOR_MANUAL_REVIEW"
    } >"$WRAPPER_STATUS_REPORT"

    echo
    echo "===== RULE SEMANTICS REVIEW STATUS ====="
    cat "$WRAPPER_STATUS_REPORT"

    for REPORT in \
        rule_semantics_collector_status.rpt \
        named_rule_sets_numbered.rpt \
        metalswitch_and_revision_numbered.rpt \
        pdk_config_option_defaults.tsv \
        directive_conditional_block_summary.tsv \
        rule_semantic_contract.rpt \
        user_guide_semantic_scan.rpt \
        source_file_identity.tsv
    do
        echo
        echo "===== $DIAGNOSTIC_ROOT/rule_semantics/$REPORT ====="
        cat "$DIAGNOSTIC_ROOT/rule_semantics/$REPORT"
    done

    echo
    echo "===== CONDITIONAL BLOCK CONTEXT FIRST 1800 LINES ====="
    sed -n '1,1800p' "$DIAGNOSTIC_ROOT/rule_semantics/directive_conditional_block_context.rpt"

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
    echo "POSITION_PVS_DRC_RULE_SEMANTICS_REVIEW_STATUS=NOT_RUN"
    echo "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO"
    echo "PVS_EXECUTED=NO"
    echo "STOP_HERE_DO_NOT_RUN_PVS"
    false
fi
