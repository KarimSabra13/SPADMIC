#!/usr/bin/env bash
# Inventory PAD/PIMIDE GDS tuples for the accepted Position hierarchy.
# This script is read-only with respect to the package and PDK and never runs PVS.

set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
EXPECTED_HEAD="${1:-MISSING}"
RULE_SEMANTICS_ROOT="${2:-MISSING}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"

PACKAGE="$WORK_ROOT/handoff/innovus/blocks/spadmic_position_core/innovus_ooc_harden_position_core_gridfit_20260717_114810"
PACKAGE_GDS="$PACKAGE/gds/spadmic_position_core.gds"
PACKAGE_GDS_AUDIT="$PACKAGE/reports/gds_export_audit.rpt"
EXPECTED_GDS_SHA=ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1
TOP_STRUCTURE=spadmic_position_core

PDK_PVS_ROOT=/data/pdk/xfab/xh018/cadence/v10_1/pvs/v10_1_1/PVS
DRC_RULE="$PDK_PVS_ROOT/xh018_DRC.rul"
EXPECTED_DRC_RULE_SHA=0b1ce563da515dd50d17a5e16baa2a2addc10354aa06ab5e1a111b01ed039cb6
STREAM_MAP=/data/pdk/xfab/xh018/cadence/v10_1/PDK/IC61/v10_1_1/TECH_XH018_HD_1131/pnr_streamout.map
EXPECTED_STREAM_MAP_SHA=4d7b850f74ef193b6bc7b15b1e52fd38ba61cc4a6e1b283c4201343a20ad233d

EXPECTED_SEMANTICS_STATUS_SHA=9de7fc2c3be8631837256734128f336927987d089f9e23a5efff7a949542ebd5
EXPECTED_SEMANTICS_COLLECTOR_SHA=1b5810194c43110991e17cbd7ca19da47fc534461ac842daf0dad306daab844a
EXPECTED_NAMED_RULE_SETS_SHA=49d1ee30a8376fe946834496c3b43f298828eb1106f40db321d62ddb5e89f599
EXPECTED_METALSWITCH_REVISION_SHA=366ceb993f2036452df51ac39b2ad996452f81b29377d27fcf8e4eb8e5170477
EXPECTED_CONFIG_DEFAULTS_SHA=81fd45828011d2b64670546cd11194aa3598943847b1d2fc15b7803e30146f92
EXPECTED_BLOCK_SUMMARY_SHA=cf19272e4fed1e25837d60da9ee90ffa7c3a8e6ddda865a6f9cf7c287ecf6f03
EXPECTED_BLOCK_CONTEXT_SHA=23dece8204f3fe15a62664dafc64d1a506afec44d9ed0d3ea0d43ecd42df437d
EXPECTED_SEMANTIC_CONTRACT_SHA=fb840200ec8cffdfc576a423c724e4deb4f6a9fff6fda02a97d8cf5cd27a2959
EXPECTED_USER_GUIDE_SCAN_SHA=aaab79b14aca08bff209e2d8dc2857e93d24b3dea03e019b73ac7a52536f9571
EXPECTED_SOURCE_IDENTITY_SHA=2928fad6f4ca721c9bd61761bd10c403a124f0698ff72cada4173106560ab12d
EXPECTED_PACKAGE_CHECK_SHA=51323c7f850d1afa5b1618ec1574a8794d3d5427a7a9518c6378a76a0914eb99

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
SOURCE_IDENTITY_GATE_RC=NOT_RUN
PACKAGE_SHA_MANIFEST_RC=NOT_RUN
DIAGNOSTIC_CREATE_RC=NOT_RUN
DIAGNOSTIC_COPY_GATE_RC=NOT_RUN
GDS_LAYER_COLLECTOR_RC=NOT_RUN
GDS_LAYER_COLLECTOR_GATE_RC=NOT_RUN
SOURCE_POST_RECHECK_RC=NOT_RUN
PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=NOT_RUN
PACKAGE_SHA_CONSOLE=""

if [ "$EXPECTED_HEAD" = "MISSING" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: expected repository HEAD argument missing"
    RUN_OK=0
fi

if [ "$RULE_SEMANTICS_ROOT" = "MISSING" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: rule-semantics diagnostic root argument missing"
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
    INPUT_STATUS="$RULE_SEMANTICS_ROOT/rule_semantics_review_status.rpt"
    INPUT_COLLECTOR="$RULE_SEMANTICS_ROOT/rule_semantics/rule_semantics_collector_status.rpt"
    INPUT_NAMED_RULE_SETS="$RULE_SEMANTICS_ROOT/rule_semantics/named_rule_sets_numbered.rpt"
    INPUT_METALSWITCH="$RULE_SEMANTICS_ROOT/rule_semantics/metalswitch_and_revision_numbered.rpt"
    INPUT_CONFIG_DEFAULTS="$RULE_SEMANTICS_ROOT/rule_semantics/pdk_config_option_defaults.tsv"
    INPUT_BLOCK_SUMMARY="$RULE_SEMANTICS_ROOT/rule_semantics/directive_conditional_block_summary.tsv"
    INPUT_BLOCK_CONTEXT="$RULE_SEMANTICS_ROOT/rule_semantics/directive_conditional_block_context.rpt"
    INPUT_SEMANTIC_CONTRACT="$RULE_SEMANTICS_ROOT/rule_semantics/rule_semantic_contract.rpt"
    INPUT_USER_GUIDE_SCAN="$RULE_SEMANTICS_ROOT/rule_semantics/user_guide_semantic_scan.rpt"
    INPUT_SOURCE_IDENTITY="$RULE_SEMANTICS_ROOT/rule_semantics/source_file_identity.tsv"
    INPUT_PACKAGE_CHECK="$RULE_SEMANTICS_ROOT/package_sha256_check.rpt"
    INPUT_PACKAGE_POST="$RULE_SEMANTICS_ROOT/package_sha256_post_review.rpt"

    INPUT_FILE_GATE_RC=0
    for FILE in \
        "$INPUT_STATUS" \
        "$INPUT_COLLECTOR" \
        "$INPUT_NAMED_RULE_SETS" \
        "$INPUT_METALSWITCH" \
        "$INPUT_CONFIG_DEFAULTS" \
        "$INPUT_BLOCK_SUMMARY" \
        "$INPUT_BLOCK_CONTEXT" \
        "$INPUT_SEMANTIC_CONTRACT" \
        "$INPUT_USER_GUIDE_SCAN" \
        "$INPUT_SOURCE_IDENTITY" \
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
        echo "STOP_HERE_DO_NOT_CONTINUE: rule-semantics evidence missing"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    INPUT_HASH_GATE_RC=0
    for SPEC in \
        "$INPUT_STATUS|$EXPECTED_SEMANTICS_STATUS_SHA" \
        "$INPUT_COLLECTOR|$EXPECTED_SEMANTICS_COLLECTOR_SHA" \
        "$INPUT_NAMED_RULE_SETS|$EXPECTED_NAMED_RULE_SETS_SHA" \
        "$INPUT_METALSWITCH|$EXPECTED_METALSWITCH_REVISION_SHA" \
        "$INPUT_CONFIG_DEFAULTS|$EXPECTED_CONFIG_DEFAULTS_SHA" \
        "$INPUT_BLOCK_SUMMARY|$EXPECTED_BLOCK_SUMMARY_SHA" \
        "$INPUT_BLOCK_CONTEXT|$EXPECTED_BLOCK_CONTEXT_SHA" \
        "$INPUT_SEMANTIC_CONTRACT|$EXPECTED_SEMANTIC_CONTRACT_SHA" \
        "$INPUT_USER_GUIDE_SCAN|$EXPECTED_USER_GUIDE_SCAN_SHA" \
        "$INPUT_SOURCE_IDENTITY|$EXPECTED_SOURCE_IDENTITY_SHA" \
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
        echo "STOP_HERE_DO_NOT_CONTINUE: rule-semantics evidence hashes changed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    INPUT_STATUS_GATE_RC=0
    for EXPECTED_LINE in \
        "STATUS=PASS" \
        "RESULT=NAMED_RULE_SET_AND_CONDITIONAL_EVIDENCE_RECORDED_FOR_MANUAL_REVIEW" \
        "PACKAGE_GDS_SHA256=$EXPECTED_GDS_SHA" \
        "DRC_RULE_SHA256=$EXPECTED_DRC_RULE_SHA" \
        "DEFAULT_RULE_SET_EVIDENCE_STATUS=PASS" \
        "DEFAULT_RULE_SET_SELECTION_STATUS=REVIEW_REQUIRED" \
        "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO" \
        "PVS_REPLAY_AUTHORIZED=NO" \
        "PVS_EXECUTED=NO" \
        "NEXT_GATE=RETURN_NAMED_RULE_SETS_AND_CONDITIONAL_BLOCKS_FOR_MANUAL_REVIEW"
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
        "KNOWN_SOURCE_HASH_GATE_STATUS=PASS" \
        "SOURCE_RECHECK_STATUS=PASS" \
        "DRC_RULE_SHA256=$EXPECTED_DRC_RULE_SHA" \
        "DEFAULT_RULE_SET_EVIDENCE_STATUS=PASS" \
        "PVS_CONFIG_OPTION_DEFAULT_GATE_STATUS=PASS" \
        "DENSITY_CONDITIONAL_BLOCK_COUNT=1" \
        "POPPING_CONDITIONAL_BLOCK_COUNT=1" \
        "PIMIDE_CONDITIONAL_BLOCK_COUNT=1" \
        "DUMMY_FILL_CONDITIONAL_BLOCK_COUNT=2" \
        "VAR_ANT_RATIO_CONDITIONAL_BLOCK_COUNT=78" \
        "UNMATCHED_CONDITIONAL_COUNT=0" \
        "USER_GUIDE_TEXT_STATUS=PASS_MATCHES_FOUND" \
        "SEMANTIC_EVIDENCE_COLLECTION_STATUS=PASS" \
        "PVS_EXECUTED=NO"
    do
        grep -Fqx "$EXPECTED_LINE" "$INPUT_COLLECTOR"
        LINE_RC=$?
        echo "INPUT_COLLECTOR_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"
        if [ "$LINE_RC" -ne 0 ]; then
            INPUT_STATUS_GATE_RC=1
        fi
    done

    for EXPECTED_LINE in \
        "DEFAULT_RULE_SET_SELECTION_STATUS=REVIEW_REQUIRED" \
        "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO" \
        "PVS_REPLAY_AUTHORIZED=NO" \
        "PVS_EXECUTED=NO"
    do
        grep -Fqx "$EXPECTED_LINE" "$INPUT_SEMANTIC_CONTRACT"
        LINE_RC=$?
        echo "INPUT_CONTRACT_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"
        if [ "$LINE_RC" -ne 0 ]; then
            INPUT_STATUS_GATE_RC=1
        fi
    done

    echo "INPUT_STATUS_GATE_RC=$INPUT_STATUS_GATE_RC"
    if [ "$INPUT_STATUS_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: rule-semantics evidence status changed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    PACKAGE_GATE_RC=0
    for FILE in \
        "$PACKAGE_GDS" \
        "$PACKAGE_GDS_AUDIT" \
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
        "$PACKAGE/status/qualification.rpt|SIGNOFF_READY=NO" \
        "$PACKAGE_GDS_AUDIT|STATUS=PASS" \
        "$PACKAGE_GDS_AUDIT|GDS_LAYER_MAP_STATUS=PASS" \
        "$PACKAGE_GDS_AUDIT|GDS_MERGE_STATUS=PASS" \
        "$PACKAGE_GDS_AUDIT|GDS_SHA256=$EXPECTED_GDS_SHA" \
        "$PACKAGE_GDS_AUDIT|STREAM_MAP_SHA256=$EXPECTED_STREAM_MAP_SHA" \
        "$PACKAGE_GDS_AUDIT|ERROR_COUNT=0"
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
    for FILE in "$DRC_RULE" "$STREAM_MAP"
    do
        if [ ! -s "$FILE" ]; then
            echo "MISSING_OR_EMPTY=$FILE"
            SOURCE_FILE_GATE_RC=1
        fi
    done
    echo "SOURCE_FILE_GATE_RC=$SOURCE_FILE_GATE_RC"
    if [ "$SOURCE_FILE_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: pinned deck or stream map missing"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    ACTUAL_DRC_RULE_SHA="$(sha256sum "$DRC_RULE" | awk '{print $1}')"
    ACTUAL_STREAM_MAP_SHA="$(sha256sum "$STREAM_MAP" | awk '{print $1}')"
    SOURCE_IDENTITY_GATE_RC=0
    if [ "$ACTUAL_DRC_RULE_SHA" != "$EXPECTED_DRC_RULE_SHA" ] || \
       [ "$ACTUAL_STREAM_MAP_SHA" != "$EXPECTED_STREAM_MAP_SHA" ]; then
        SOURCE_IDENTITY_GATE_RC=1
    fi
    echo "EXPECTED_DRC_RULE_SHA=$EXPECTED_DRC_RULE_SHA"
    echo "ACTUAL_DRC_RULE_SHA=$ACTUAL_DRC_RULE_SHA"
    echo "EXPECTED_STREAM_MAP_SHA=$EXPECTED_STREAM_MAP_SHA"
    echo "ACTUAL_STREAM_MAP_SHA=$ACTUAL_STREAM_MAP_SHA"
    echo "SOURCE_IDENTITY_GATE_RC=$SOURCE_IDENTITY_GATE_RC"
    if [ "$SOURCE_IDENTITY_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: pinned deck or stream map changed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    PACKAGE_SHA_CONSOLE="$WORK_ROOT/diagnostics/position_gds_layer_package_sha_$$.rpt"
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
    DIAGNOSTIC_ID="position_pvs_drc_gds_layer_applicability_$(date +%Y%m%d_%H%M%S)"
    DIAGNOSTIC_ROOT="$WORK_ROOT/diagnostics/$DIAGNOSTIC_ID"
    mkdir -p "$DIAGNOSTIC_ROOT/source_rule_semantics" "$DIAGNOSTIC_ROOT/gds_layer_applicability"
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
        "$INPUT_STATUS|$DIAGNOSTIC_ROOT/source_rule_semantics/rule_semantics_review_status.rpt" \
        "$INPUT_COLLECTOR|$DIAGNOSTIC_ROOT/source_rule_semantics/rule_semantics_collector_status.rpt" \
        "$INPUT_NAMED_RULE_SETS|$DIAGNOSTIC_ROOT/source_rule_semantics/named_rule_sets_numbered.rpt" \
        "$INPUT_METALSWITCH|$DIAGNOSTIC_ROOT/source_rule_semantics/metalswitch_and_revision_numbered.rpt" \
        "$INPUT_CONFIG_DEFAULTS|$DIAGNOSTIC_ROOT/source_rule_semantics/pdk_config_option_defaults.tsv" \
        "$INPUT_BLOCK_SUMMARY|$DIAGNOSTIC_ROOT/source_rule_semantics/directive_conditional_block_summary.tsv" \
        "$INPUT_SEMANTIC_CONTRACT|$DIAGNOSTIC_ROOT/source_rule_semantics/rule_semantic_contract.rpt" \
        "$INPUT_USER_GUIDE_SCAN|$DIAGNOSTIC_ROOT/source_rule_semantics/user_guide_semantic_scan.rpt" \
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
    python3 TOP/pnr/scripts/collect_position_pvs_gds_layer_applicability.py \
        --gds "$PACKAGE_GDS" \
        --stream-map "$STREAM_MAP" \
        --drc-rule "$DRC_RULE" \
        --top-structure "$TOP_STRUCTURE" \
        --output-dir "$DIAGNOSTIC_ROOT/gds_layer_applicability" \
        --expected-gds-sha "$EXPECTED_GDS_SHA" \
        --expected-stream-map-sha "$EXPECTED_STREAM_MAP_SHA" \
        --expected-drc-sha "$EXPECTED_DRC_RULE_SHA"
    GDS_LAYER_COLLECTOR_RC=$?

    COLLECTOR_STATUS_REPORT="$DIAGNOSTIC_ROOT/gds_layer_applicability/gds_layer_applicability_collector_status.rpt"
    GDS_LAYER_COLLECTOR_GATE_RC=0
    for EXPECTED_LINE in \
        "COLLECTOR_STATUS=PASS" \
        "SOURCE_REQUIRED_FILE_GATE_STATUS=PASS" \
        "KNOWN_SOURCE_HASH_GATE_STATUS=PASS" \
        "GDS_PARSE_STATUS=PASS" \
        "GDS_TOP_STRUCTURE_STATUS=PASS" \
        "GDS_HIERARCHY_STATUS=PASS" \
        "TARGET_LAYER_MAPPING_STATUS=PASS" \
        "SOURCE_RECHECK_STATUS=PASS" \
        "GDS_SHA256=$EXPECTED_GDS_SHA" \
        "STREAM_MAP_SHA256=$EXPECTED_STREAM_MAP_SHA" \
        "DRC_RULE_SHA256=$EXPECTED_DRC_RULE_SHA" \
        "TOP_STRUCTURE=$TOP_STRUCTURE" \
        "TARGET_COUNT_BASIS=UNIQUE_REACHABLE_STRUCTURE_DEFINITIONS" \
        "PAD_MAPPING_STATUS=PASS" \
        "PIMIDE_MAPPING_STATUS=PASS" \
        "PIMIDE_INTERNAL_LAYER=22150" \
        "PIMIDE_GDS_LAYER=221" \
        "PIMIDE_GDS_DATATYPE=5" \
        "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO" \
        "PVS_REPLAY_AUTHORIZED=NO" \
        "PVS_EXECUTED=NO" \
        "ERROR_COUNT=0"
    do
        grep -Fqx "$EXPECTED_LINE" "$COLLECTOR_STATUS_REPORT" 2>/dev/null
        LINE_RC=$?
        echo "COLLECTOR_STATUS_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"
        if [ "$LINE_RC" -ne 0 ]; then
            GDS_LAYER_COLLECTOR_GATE_RC=1
        fi
    done

    for FIELD in \
        STRUCTURE_COUNT \
        REACHABLE_STRUCTURE_COUNT \
        PAD_REACHABLE_GEOMETRY_ELEMENT_COUNT \
        PIMIDE_REACHABLE_GEOMETRY_ELEMENT_COUNT
    do
        grep -Eq "^${FIELD}=[0-9]+$" "$COLLECTOR_STATUS_REPORT"
        LINE_RC=$?
        echo "COLLECTOR_NUMERIC_FIELD_RC=$LINE_RC FIELD=$FIELD"
        if [ "$LINE_RC" -ne 0 ]; then
            GDS_LAYER_COLLECTOR_GATE_RC=1
        fi
    done

    grep -Eq '^PIMIDE_POSITION_APPLICABILITY_STATUS=(NOT_APPLICABLE_NO_REACHABLE_PAD_OR_PIMIDE_GEOMETRY|REVIEW_REQUIRED_REACHABLE_PAD_OR_PIMIDE_GEOMETRY_PRESENT)$' "$COLLECTOR_STATUS_REPORT"
    APPLICABILITY_LINE_RC=$?
    grep -Eq '^STRICT_DRY_RUN_PREFLIGHT_RECOMMENDATION=(READY_FOR_MANUAL_AUTHORIZATION|HOLD)$' "$COLLECTOR_STATUS_REPORT"
    RECOMMENDATION_LINE_RC=$?
    if [ "$APPLICABILITY_LINE_RC" -ne 0 ] || [ "$RECOMMENDATION_LINE_RC" -ne 0 ]; then
        GDS_LAYER_COLLECTOR_GATE_RC=1
    fi

    echo "GDS_LAYER_COLLECTOR_RC=$GDS_LAYER_COLLECTOR_RC"
    echo "GDS_LAYER_COLLECTOR_GATE_RC=$GDS_LAYER_COLLECTOR_GATE_RC"
fi

if [ "$RUN_OK" -eq 1 ]; then
    SOURCE_POST_RECHECK_RC=0
    for SPEC in \
        "$INPUT_STATUS|$EXPECTED_SEMANTICS_STATUS_SHA" \
        "$INPUT_COLLECTOR|$EXPECTED_SEMANTICS_COLLECTOR_SHA" \
        "$INPUT_NAMED_RULE_SETS|$EXPECTED_NAMED_RULE_SETS_SHA" \
        "$INPUT_METALSWITCH|$EXPECTED_METALSWITCH_REVISION_SHA" \
        "$INPUT_CONFIG_DEFAULTS|$EXPECTED_CONFIG_DEFAULTS_SHA" \
        "$INPUT_BLOCK_SUMMARY|$EXPECTED_BLOCK_SUMMARY_SHA" \
        "$INPUT_BLOCK_CONTEXT|$EXPECTED_BLOCK_CONTEXT_SHA" \
        "$INPUT_SEMANTIC_CONTRACT|$EXPECTED_SEMANTIC_CONTRACT_SHA" \
        "$INPUT_USER_GUIDE_SCAN|$EXPECTED_USER_GUIDE_SCAN_SHA" \
        "$INPUT_SOURCE_IDENTITY|$EXPECTED_SOURCE_IDENTITY_SHA" \
        "$INPUT_PACKAGE_CHECK|$EXPECTED_PACKAGE_CHECK_SHA" \
        "$INPUT_PACKAGE_POST|$EXPECTED_PACKAGE_CHECK_SHA" \
        "$PACKAGE_GDS|$EXPECTED_GDS_SHA" \
        "$DRC_RULE|$EXPECTED_DRC_RULE_SHA" \
        "$STREAM_MAP|$EXPECTED_STREAM_MAP_SHA"
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
    if [ "$GDS_LAYER_COLLECTOR_RC" -ne 0 ] || \
       [ "$GDS_LAYER_COLLECTOR_GATE_RC" -ne 0 ] || \
       [ "$SOURCE_POST_RECHECK_RC" -ne 0 ] || \
       [ "$PACKAGE_POST_REVIEW_SHA_MANIFEST_RC" -ne 0 ]; then
        FINAL_STATUS=FAIL
    fi

    PAD_REACHABLE_GEOMETRY_ELEMENT_COUNT="$(
        awk -F= '$1 == "PAD_REACHABLE_GEOMETRY_ELEMENT_COUNT" {print $2}' \
            "$COLLECTOR_STATUS_REPORT" | tail -n 1
    )"
    PIMIDE_REACHABLE_GEOMETRY_ELEMENT_COUNT="$(
        awk -F= '$1 == "PIMIDE_REACHABLE_GEOMETRY_ELEMENT_COUNT" {print $2}' \
            "$COLLECTOR_STATUS_REPORT" | tail -n 1
    )"
    PIMIDE_POSITION_APPLICABILITY_STATUS="$(
        awk -F= '$1 == "PIMIDE_POSITION_APPLICABILITY_STATUS" {print $2}' \
            "$COLLECTOR_STATUS_REPORT" | tail -n 1
    )"
    STRICT_DRY_RUN_PREFLIGHT_RECOMMENDATION="$(
        awk -F= '$1 == "STRICT_DRY_RUN_PREFLIGHT_RECOMMENDATION" {print $2}' \
            "$COLLECTOR_STATUS_REPORT" | tail -n 1
    )"

    if [ -z "$PAD_REACHABLE_GEOMETRY_ELEMENT_COUNT" ]; then
        PAD_REACHABLE_GEOMETRY_ELEMENT_COUNT=UNKNOWN
        FINAL_STATUS=FAIL
    fi
    if [ -z "$PIMIDE_REACHABLE_GEOMETRY_ELEMENT_COUNT" ]; then
        PIMIDE_REACHABLE_GEOMETRY_ELEMENT_COUNT=UNKNOWN
        FINAL_STATUS=FAIL
    fi
    if [ -z "$PIMIDE_POSITION_APPLICABILITY_STATUS" ]; then
        PIMIDE_POSITION_APPLICABILITY_STATUS=UNKNOWN
        FINAL_STATUS=FAIL
    fi
    if [ -z "$STRICT_DRY_RUN_PREFLIGHT_RECOMMENDATION" ]; then
        STRICT_DRY_RUN_PREFLIGHT_RECOMMENDATION=UNKNOWN
        FINAL_STATUS=FAIL
    fi

    WRAPPER_STATUS_REPORT="$DIAGNOSTIC_ROOT/gds_layer_applicability_review_status.rpt"
    {
        echo "LABEL=SPADMIC_POSITION_PVS_DRC_GDS_LAYER_APPLICABILITY_REVIEW"
        echo "STATUS=$FINAL_STATUS"
        echo "RESULT=ACCEPTED_GDS_TARGET_LAYER_APPLICABILITY_RECORDED_FOR_MANUAL_REVIEW"
        echo "SOURCE_RULE_SEMANTICS_ROOT=$RULE_SEMANTICS_ROOT"
        echo "SOURCE_RULE_SEMANTICS_STATUS_SHA256=$EXPECTED_SEMANTICS_STATUS_SHA"
        echo "PACKAGE=$PACKAGE"
        echo "PACKAGE_GDS_SHA256=$EXPECTED_GDS_SHA"
        echo "TOP_STRUCTURE=$TOP_STRUCTURE"
        echo "DRC_RULE=$DRC_RULE"
        echo "DRC_RULE_SHA256=$EXPECTED_DRC_RULE_SHA"
        echo "STREAM_MAP=$STREAM_MAP"
        echo "STREAM_MAP_SHA256=$EXPECTED_STREAM_MAP_SHA"
        echo "GDS_LAYER_COLLECTOR_RC=$GDS_LAYER_COLLECTOR_RC"
        echo "GDS_LAYER_COLLECTOR_GATE_RC=$GDS_LAYER_COLLECTOR_GATE_RC"
        echo "SOURCE_POST_RECHECK_RC=$SOURCE_POST_RECHECK_RC"
        echo "PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=$PACKAGE_POST_REVIEW_SHA_MANIFEST_RC"
        echo "PAD_REACHABLE_GEOMETRY_ELEMENT_COUNT=$PAD_REACHABLE_GEOMETRY_ELEMENT_COUNT"
        echo "PIMIDE_REACHABLE_GEOMETRY_ELEMENT_COUNT=$PIMIDE_REACHABLE_GEOMETRY_ELEMENT_COUNT"
        echo "PIMIDE_POSITION_APPLICABILITY_STATUS=$PIMIDE_POSITION_APPLICABILITY_STATUS"
        echo "STRICT_DRY_RUN_PREFLIGHT_RECOMMENDATION=$STRICT_DRY_RUN_PREFLIGHT_RECOMMENDATION"
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
        echo "NEXT_GATE=RETURN_GDS_TARGET_LAYER_APPLICABILITY_FOR_MANUAL_REVIEW"
    } >"$WRAPPER_STATUS_REPORT"

    echo
    echo "===== GDS LAYER APPLICABILITY REVIEW STATUS ====="
    cat "$WRAPPER_STATUS_REPORT"

    for REPORT in \
        gds_layer_applicability_collector_status.rpt \
        gds_parser_summary.rpt \
        pvs_target_layer_mapping.tsv \
        pvs_target_layer_context.rpt \
        stream_map_target_context.rpt \
        position_option_policy_contract.rpt \
        source_file_identity.tsv
    do
        echo
        echo "===== $DIAGNOSTIC_ROOT/gds_layer_applicability/$REPORT ====="
        cat "$DIAGNOSTIC_ROOT/gds_layer_applicability/$REPORT"
    done

    echo
    echo "===== REACHABLE GDS LAYER INVENTORY ====="
    awk -F '\t' 'NR == 1 || $1 == "REACHABLE"' \
        "$DIAGNOSTIC_ROOT/gds_layer_applicability/gds_layer_inventory.tsv"

    echo
    echo "===== GDS STRUCTURE INVENTORY FIRST 300 LINES ====="
    sed -n '1,300p' "$DIAGNOSTIC_ROOT/gds_layer_applicability/gds_structure_inventory.tsv"

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
    echo "POSITION_PVS_DRC_GDS_LAYER_APPLICABILITY_REVIEW_STATUS=NOT_RUN"
    echo "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO"
    echo "PVS_EXECUTED=NO"
    echo "STOP_HERE_DO_NOT_RUN_PVS"
    false
fi
