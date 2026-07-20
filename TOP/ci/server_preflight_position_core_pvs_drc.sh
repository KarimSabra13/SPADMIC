#!/usr/bin/env bash
# Materialize attributable Position base and density DRC controls without PVS.

set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
EXPECTED_HEAD="${1:-MISSING}"
APPLICABILITY_ROOT="${2:-MISSING}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"

PACKAGE="$WORK_ROOT/handoff/innovus/blocks/spadmic_position_core/innovus_ooc_harden_position_core_gridfit_20260717_114810"
PACKAGE_GDS="$PACKAGE/gds/spadmic_position_core.gds"
EXPECTED_GDS_SHA=ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1
POSITION_TOP=spadmic_position_core

PRIMARY_SEED=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/layoutverification/pvs_drc/spadmic_tx_packet_core
PRIMARY_SEED_GDS="$PRIMARY_SEED/spadmic_tx_packet_core.gds"
PRIMARY_SEED_TOP=spadmic_tx_packet_core

EXPECTED_APPLICABILITY_STATUS_SHA=934744cb9a2e524c3d5e2e4aa2c8a057117fcddfcf45aaae52e2a7e5873dc717
EXPECTED_APPLICABILITY_COLLECTOR_SHA=17b311a2548894233e24d623933ccbe5344fdc85b5f466fecdebd642ea1e3eae
EXPECTED_GDS_PARSER_SHA=09969115c583343d876cbef745b68d5aa7e52c8e2981786cb11b6afdfc93fe46
EXPECTED_LAYER_INVENTORY_SHA=0f960b3e491cd0ea6bef0fadef7ce122900bfb3bb2e9fa1b67b0b8f8c0138467
EXPECTED_STRUCTURE_INVENTORY_SHA=f0b2b1534800be0478780b64f913853f69ff6c9f31bb20e8b7b04acff0e3e103
EXPECTED_LAYER_MAPPING_SHA=3ec8ccb0a3127af8536635605ad44882d439bafbdafccda1ac01223c54bd111f
EXPECTED_LAYER_CONTEXT_SHA=221fe721dcdcc3dfbc3453de6aa9ca8e79bd3dd3c390f3ef306a9a42cda68ebe
EXPECTED_STREAM_CONTEXT_SHA=3d80bc6dcf30a10e7efd6211fb78b7604fc2b2c26b2604182461e18e6b4f529d
EXPECTED_POLICY_SHA=655274fe3bd5e493ccaef99f35b1aeea96891c6250ea4ab014fb913f733cc1af
EXPECTED_SOURCE_IDENTITY_SHA=be63a7a6993e6258757940c4e951cf65672ab047c0758cfb6ddc77a932e12d96
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
INPUT_MANIFEST_GATE_RC=NOT_RUN
INPUT_STATUS_GATE_RC=NOT_RUN
PACKAGE_GATE_RC=NOT_RUN
PACKAGE_SHA_MANIFEST_RC=NOT_RUN
SEED_FILE_GATE_RC=NOT_RUN
SEED_IDENTITY_GATE_RC=NOT_RUN
DIAGNOSTIC_CREATE_RC=NOT_RUN
BASE_DRY_RUN_RC=NOT_RUN
DENSITY_DRY_RUN_RC=NOT_RUN
RUN_AUDIT_GATE_RC=NOT_RUN
DIAGNOSTIC_COPY_GATE_RC=NOT_RUN
SOURCE_POST_RECHECK_RC=NOT_RUN
PACKAGE_POST_PREFLIGHT_SHA_MANIFEST_RC=NOT_RUN
DIAGNOSTIC_ROOT=UNKNOWN
BASE_RUN_DIR=UNKNOWN
DENSITY_RUN_DIR=UNKNOWN
INPUT_MANIFEST_CONSOLE=""
PACKAGE_SHA_CONSOLE=""

if [ "$EXPECTED_HEAD" = "MISSING" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: expected repository HEAD argument missing"
    RUN_OK=0
fi

if [ "$APPLICABILITY_ROOT" = "MISSING" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: GDS applicability diagnostic root missing"
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
    INPUT_STATUS="$APPLICABILITY_ROOT/gds_layer_applicability_review_status.rpt"
    INPUT_COLLECTOR="$APPLICABILITY_ROOT/gds_layer_applicability/gds_layer_applicability_collector_status.rpt"
    INPUT_PARSER="$APPLICABILITY_ROOT/gds_layer_applicability/gds_parser_summary.rpt"
    INPUT_LAYER_INVENTORY="$APPLICABILITY_ROOT/gds_layer_applicability/gds_layer_inventory.tsv"
    INPUT_STRUCTURE_INVENTORY="$APPLICABILITY_ROOT/gds_layer_applicability/gds_structure_inventory.tsv"
    INPUT_MAPPING="$APPLICABILITY_ROOT/gds_layer_applicability/pvs_target_layer_mapping.tsv"
    INPUT_LAYER_CONTEXT="$APPLICABILITY_ROOT/gds_layer_applicability/pvs_target_layer_context.rpt"
    INPUT_STREAM_CONTEXT="$APPLICABILITY_ROOT/gds_layer_applicability/stream_map_target_context.rpt"
    INPUT_POLICY="$APPLICABILITY_ROOT/gds_layer_applicability/position_option_policy_contract.rpt"
    INPUT_SOURCE_IDENTITY="$APPLICABILITY_ROOT/gds_layer_applicability/source_file_identity.tsv"
    INPUT_PACKAGE_CHECK="$APPLICABILITY_ROOT/package_sha256_check.rpt"
    INPUT_PACKAGE_POST="$APPLICABILITY_ROOT/package_sha256_post_review.rpt"

    INPUT_FILE_GATE_RC=0
    for FILE in \
        "$INPUT_STATUS" \
        "$INPUT_COLLECTOR" \
        "$INPUT_PARSER" \
        "$INPUT_LAYER_INVENTORY" \
        "$INPUT_STRUCTURE_INVENTORY" \
        "$INPUT_MAPPING" \
        "$INPUT_LAYER_CONTEXT" \
        "$INPUT_STREAM_CONTEXT" \
        "$INPUT_POLICY" \
        "$INPUT_SOURCE_IDENTITY" \
        "$INPUT_PACKAGE_CHECK" \
        "$INPUT_PACKAGE_POST" \
        "$APPLICABILITY_ROOT/SHA256SUMS"
    do
        if [ ! -s "$FILE" ]; then
            echo "MISSING_OR_EMPTY=$FILE"
            INPUT_FILE_GATE_RC=1
        fi
    done
    echo "INPUT_FILE_GATE_RC=$INPUT_FILE_GATE_RC"
    if [ "$INPUT_FILE_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: R10 applicability evidence missing"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    INPUT_HASH_GATE_RC=0
    for SPEC in \
        "$INPUT_STATUS|$EXPECTED_APPLICABILITY_STATUS_SHA" \
        "$INPUT_COLLECTOR|$EXPECTED_APPLICABILITY_COLLECTOR_SHA" \
        "$INPUT_PARSER|$EXPECTED_GDS_PARSER_SHA" \
        "$INPUT_LAYER_INVENTORY|$EXPECTED_LAYER_INVENTORY_SHA" \
        "$INPUT_STRUCTURE_INVENTORY|$EXPECTED_STRUCTURE_INVENTORY_SHA" \
        "$INPUT_MAPPING|$EXPECTED_LAYER_MAPPING_SHA" \
        "$INPUT_LAYER_CONTEXT|$EXPECTED_LAYER_CONTEXT_SHA" \
        "$INPUT_STREAM_CONTEXT|$EXPECTED_STREAM_CONTEXT_SHA" \
        "$INPUT_POLICY|$EXPECTED_POLICY_SHA" \
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
        if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
            INPUT_HASH_GATE_RC=1
        fi
    done
    echo "INPUT_HASH_GATE_RC=$INPUT_HASH_GATE_RC"
    if [ "$INPUT_HASH_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: R10 applicability evidence changed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    mkdir -p "$WORK_ROOT/diagnostics"
    INPUT_MANIFEST_CONSOLE="$WORK_ROOT/diagnostics/position_pvs_preflight_r10_manifest_$$.rpt"
    (
        if cd "$APPLICABILITY_ROOT"; then
            sha256sum -c SHA256SUMS
        else
            false
        fi
    ) >"$INPUT_MANIFEST_CONSOLE" 2>&1
    INPUT_MANIFEST_GATE_RC=$?
    echo "INPUT_MANIFEST_GATE_RC=$INPUT_MANIFEST_GATE_RC"
    if [ "$INPUT_MANIFEST_GATE_RC" -ne 0 ]; then
        cat "$INPUT_MANIFEST_CONSOLE"
        echo "STOP_HERE_DO_NOT_CONTINUE: R10 SHA manifest failed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    INPUT_STATUS_GATE_RC=0
    for SPEC in \
        "$INPUT_STATUS|STATUS=PASS" \
        "$INPUT_STATUS|RESULT=ACCEPTED_GDS_TARGET_LAYER_APPLICABILITY_RECORDED_FOR_MANUAL_REVIEW" \
        "$INPUT_STATUS|PACKAGE_GDS_SHA256=$EXPECTED_GDS_SHA" \
        "$INPUT_STATUS|PAD_REACHABLE_GEOMETRY_ELEMENT_COUNT=0" \
        "$INPUT_STATUS|PIMIDE_REACHABLE_GEOMETRY_ELEMENT_COUNT=0" \
        "$INPUT_STATUS|PIMIDE_POSITION_APPLICABILITY_STATUS=NOT_APPLICABLE_NO_REACHABLE_PAD_OR_PIMIDE_GEOMETRY" \
        "$INPUT_STATUS|STRICT_DRY_RUN_PREFLIGHT_RECOMMENDATION=READY_FOR_MANUAL_AUTHORIZATION" \
        "$INPUT_STATUS|STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO" \
        "$INPUT_STATUS|PVS_REPLAY_AUTHORIZED=NO" \
        "$INPUT_STATUS|PVS_EXECUTED=NO" \
        "$INPUT_COLLECTOR|COLLECTOR_STATUS=PASS" \
        "$INPUT_COLLECTOR|GDS_PARSE_STATUS=PASS" \
        "$INPUT_COLLECTOR|GDS_HIERARCHY_STATUS=PASS" \
        "$INPUT_COLLECTOR|TARGET_LAYER_MAPPING_STATUS=PASS" \
        "$INPUT_PARSER|REACHABLE_UNRESOLVED_REFERENCE_COUNT=0" \
        "$INPUT_PARSER|REACHABLE_HIERARCHY_CYCLE_EDGE_COUNT=0" \
        "$INPUT_COLLECTOR|PAD_REACHABLE_GEOMETRY_ELEMENT_COUNT=0" \
        "$INPUT_COLLECTOR|PIMIDE_REACHABLE_GEOMETRY_ELEMENT_COUNT=0" \
        "$INPUT_COLLECTOR|NOPIM_REACHABLE_GEOMETRY_ELEMENT_COUNT=0" \
        "$INPUT_COLLECTOR|ERROR_COUNT=0" \
        "$INPUT_POLICY|DEFAULT_RULE_SET_SELECTION_STATUS=PASS" \
        "$INPUT_POLICY|DENSITY_POLICY=BASE_DRC_PLUS_SEPARATE_DENSITY_DRC" \
        "$INPUT_POLICY|POPPING_STATE=UNDEFINED" \
        "$INPUT_POLICY|DUMMY_FILL_STATE=UNDEFINED" \
        "$INPUT_POLICY|VAR_ANT_RATIO_STATE=DEFINED" \
        "$INPUT_POLICY|PIMIDE_STATE=UNDEFINED" \
        "$INPUT_POLICY|STRICT_DRY_RUN_PREFLIGHT_RECOMMENDATION=READY_FOR_MANUAL_AUTHORIZATION" \
        "$INPUT_POLICY|STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO" \
        "$INPUT_POLICY|PVS_REPLAY_AUTHORIZED=NO" \
        "$INPUT_POLICY|PVS_EXECUTED=NO"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_LINE="${SPEC#*|}"
        grep -Fxq -- "$EXPECTED_LINE" "$FILE"
        LINE_RC=$?
        echo "INPUT_STATUS_LINE_RC=$LINE_RC FILE=$FILE EXPECTED=$EXPECTED_LINE"
        if [ "$LINE_RC" -ne 0 ]; then
            INPUT_STATUS_GATE_RC=1
        fi
    done
    echo "INPUT_STATUS_GATE_RC=$INPUT_STATUS_GATE_RC"
    if [ "$INPUT_STATUS_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: R10 does not support preflight authorization"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    PACKAGE_GATE_RC=0
    if [ ! -s "$PACKAGE_GDS" ] || [ ! -s "$PACKAGE/manifests/SHA256SUMS" ]; then
        PACKAGE_GATE_RC=1
    fi
    ACTUAL_GDS_SHA="$(sha256sum "$PACKAGE_GDS" 2>/dev/null | awk '{print $1}')"
    if [ "$ACTUAL_GDS_SHA" != "$EXPECTED_GDS_SHA" ]; then
        PACKAGE_GATE_RC=1
    fi
    echo "EXPECTED_GDS_SHA=$EXPECTED_GDS_SHA"
    echo "ACTUAL_GDS_SHA=$ACTUAL_GDS_SHA"
    echo "PACKAGE_GATE_RC=$PACKAGE_GATE_RC"
    if [ "$PACKAGE_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: accepted Position package changed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    PACKAGE_SHA_CONSOLE="$WORK_ROOT/diagnostics/position_pvs_preflight_package_sha_$$.rpt"
    (
        if cd "$PACKAGE"; then
            sha256sum -c manifests/SHA256SUMS
        else
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
    SEED_FILE_GATE_RC=0
    for FILE in \
        "$PRIMARY_SEED/.config.rul" \
        "$PRIMARY_SEED/.preset.autosave" \
        "$PRIMARY_SEED/.technology.rul" \
        "$PRIMARY_SEED/cell_tree.txt" \
        "$PRIMARY_SEED/pipo1.setup" \
        "$PRIMARY_SEED/pvsdrcctl" \
        "$PRIMARY_SEED/run.pvs" \
        "$PRIMARY_SEED_GDS"
    do
        if [ ! -f "$FILE" ]; then
            echo "MISSING=$FILE"
            SEED_FILE_GATE_RC=1
        fi
    done
    echo "SEED_FILE_GATE_RC=$SEED_FILE_GATE_RC"
    if [ "$SEED_FILE_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: authorized seed scaffold is incomplete"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    SEED_IDENTITY_GATE_RC=0
    for SPEC in \
        ".config.rul|e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" \
        ".preset.autosave|97b3a7e63c3e8a01ea1291a19de384e2c41f77cd11653a92c7f5618e73421000" \
        ".technology.rul|74a297facf6422635df2c58d79aa8b8ae46ca0b8232380471a88a182d8400ab6" \
        "cell_tree.txt|cb6844854e367a916909b7b31d3451d21805d09f46f3ba876b940d901dc695e4" \
        "pipo1.setup|949ce7ec915d1ddbd3e78534720c33aad9036d83932c6bac33730a113aba00dd" \
        "pvsdrcctl|b9a8451c6cc43647ec606ae706e450893e3673e22215dc5a64edeeb383b902ef" \
        "run.pvs|11ae3fc935041b8a4e0f3b406941c699c769ed1d50a504e8df36fcb544c7255a"
    do
        NAME="${SPEC%%|*}"
        EXPECTED_SHA="${SPEC#*|}"
        ACTUAL_SHA="$(sha256sum "$PRIMARY_SEED/$NAME" | awk '{print $1}')"
        echo "SEED_CONTROL=$PRIMARY_SEED/$NAME"
        echo "SEED_EXPECTED_SHA256=$EXPECTED_SHA"
        echo "SEED_ACTUAL_SHA256=$ACTUAL_SHA"
        if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
            SEED_IDENTITY_GATE_RC=1
        fi
    done
    echo "SEED_IDENTITY_GATE_RC=$SEED_IDENTITY_GATE_RC"
    if [ "$SEED_IDENTITY_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: authorized seed scaffold changed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    PREFLIGHT_STAMP="$(date +%Y%m%d_%H%M%S)"
    DIAGNOSTIC_ROOT="$WORK_ROOT/diagnostics/position_pvs_drc_strict_preflight_$PREFLIGHT_STAMP"
    BASE_RUN_ID="position_strict_preflight_${PREFLIGHT_STAMP}_base"
    DENSITY_RUN_ID="position_strict_preflight_${PREFLIGHT_STAMP}_density"
    BASE_RUN_DIR="$PACKAGE/pvs/drc/$BASE_RUN_ID"
    DENSITY_RUN_DIR="$PACKAGE/pvs/drc/$DENSITY_RUN_ID"
    mkdir -p "$DIAGNOSTIC_ROOT/source_applicability" \
        "$DIAGNOSTIC_ROOT/base" "$DIAGNOSTIC_ROOT/density"
    DIAGNOSTIC_CREATE_RC=$?
    echo "DIAGNOSTIC_ROOT=$DIAGNOSTIC_ROOT"
    echo "BASE_RUN_DIR=$BASE_RUN_DIR"
    echo "DENSITY_RUN_DIR=$DENSITY_RUN_DIR"
    echo "DIAGNOSTIC_CREATE_RC=$DIAGNOSTIC_CREATE_RC"
    if [ "$DIAGNOSTIC_CREATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: preflight diagnostic creation failed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    EXPECTED_HEAD="$EXPECTED_HEAD" \
    bash TOP/pnr/scripts/run_pvs_drc_handoff.sh \
        --package "$PACKAGE" \
        --template "$PRIMARY_SEED" \
        --template-gds "$PRIMARY_SEED_GDS" \
        --template-top "$PRIMARY_SEED_TOP" \
        --variant base \
        --run-id "$BASE_RUN_ID" \
        --allow-cross-block-control-scaffold \
        --dry-run
    BASE_DRY_RUN_RC=$?
    echo "BASE_DRY_RUN_RC=$BASE_DRY_RUN_RC"
    if [ "$BASE_DRY_RUN_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: base strict dry-run failed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    EXPECTED_HEAD="$EXPECTED_HEAD" \
    bash TOP/pnr/scripts/run_pvs_drc_handoff.sh \
        --package "$PACKAGE" \
        --template "$PRIMARY_SEED" \
        --template-gds "$PRIMARY_SEED_GDS" \
        --template-top "$PRIMARY_SEED_TOP" \
        --variant density \
        --run-id "$DENSITY_RUN_ID" \
        --allow-cross-block-control-scaffold \
        --dry-run
    DENSITY_DRY_RUN_RC=$?
    echo "DENSITY_DRY_RUN_RC=$DENSITY_DRY_RUN_RC"
    if [ "$DENSITY_DRY_RUN_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: density strict dry-run failed"
        RUN_OK=0
    fi
fi

audit_preflight_run() {
    local run_dir="$1"
    local variant="$2"
    local density_directive="$3"
    local density_report_line="$4"
    local gate_rc=0
    local file

    for file in \
        pvs_drc_status.rpt \
        replay_contract_status.rpt \
        output_isolation.rpt \
        preprocessor_defines.rpt \
        external_references.rpt \
        pvsdrcctl \
        run.pvs \
        SHA256SUMS
    do
        if [ ! -s "$run_dir/$file" ]; then
            echo "MISSING_OR_EMPTY=$run_dir/$file"
            gate_rc=1
        fi
    done

    grep -Fxq "PVS_DRC_STATUS=DRY_RUN_READY" "$run_dir/pvs_drc_status.rpt"
    [ "$?" -eq 0 ] || gate_rc=1
    grep -Fxq "PVS_DRC_VARIANT=$variant" "$run_dir/pvs_drc_status.rpt"
    [ "$?" -eq 0 ] || gate_rc=1
    grep -Fxq "CROSS_BLOCK_CONTROL_SCAFFOLD_AUTHORIZED=YES" "$run_dir/pvs_drc_status.rpt"
    [ "$?" -eq 0 ] || gate_rc=1
    grep -Fxq "STATUS=PASS" "$run_dir/replay_contract_status.rpt"
    [ "$?" -eq 0 ] || gate_rc=1
    grep -Fxq "STATUS=PASS" "$run_dir/output_isolation.rpt"
    [ "$?" -eq 0 ] || gate_rc=1
    grep -Fxq "$density_report_line" "$run_dir/preprocessor_defines.rpt"
    [ "$?" -eq 0 ] || gate_rc=1
    grep -Fxq "$density_directive" "$run_dir/pvsdrcctl"
    [ "$?" -eq 0 ] || gate_rc=1

    for directive in \
        "#UNDEFINE POPPING" \
        "#UNDEFINE PIMIDE" \
        "#UNDEFINE DUMMY_FILL" \
        "#DEFINE VAR_ANT_RATIO"
    do
        grep -Fxq "$directive" "$run_dir/pvsdrcctl"
        [ "$?" -eq 0 ] || gate_rc=1
    done

    grep -Fq -- "layout_path \"$PACKAGE_GDS\";" "$run_dir/pvsdrcctl"
    [ "$?" -eq 0 ] || gate_rc=1
    grep -Fq -- "-top_cell $POSITION_TOP" "$run_dir/run.pvs"
    [ "$?" -eq 0 ] || gate_rc=1
    grep -Fq -- "$PRIMARY_SEED" "$run_dir/run.pvs" "$run_dir/pvsdrcctl"
    [ "$?" -ne 0 ] || gate_rc=1
    grep -Fq -- "$PRIMARY_SEED_TOP" "$run_dir/run.pvs" "$run_dir/pvsdrcctl"
    [ "$?" -ne 0 ] || gate_rc=1
    grep -q '^MISSING=' "$run_dir/external_references.rpt"
    [ "$?" -ne 0 ] || gate_rc=1
    [ ! -e "$run_dir/pvs.stdout.log" ] || gate_rc=1
    (
        cd "$run_dir" && sha256sum -c SHA256SUMS >/dev/null 2>&1
    )
    [ "$?" -eq 0 ] || gate_rc=1

    echo "RUN_AUDIT_VARIANT=$variant"
    echo "RUN_AUDIT_DIR=$run_dir"
    echo "RUN_AUDIT_RC=$gate_rc"
    return "$gate_rc"
}

if [ "$RUN_OK" -eq 1 ]; then
    RUN_AUDIT_GATE_RC=0
    audit_preflight_run \
        "$BASE_RUN_DIR" BASE "#UNDEFINE DENSITY" \
        "UNDEFINE=DENSITY|OCCURRENCES=1"
    if [ "$?" -ne 0 ]; then
        RUN_AUDIT_GATE_RC=1
    fi
    audit_preflight_run \
        "$DENSITY_RUN_DIR" DENSITY "#DEFINE DENSITY" \
        "DEFINE=DENSITY|OCCURRENCES=1"
    if [ "$?" -ne 0 ]; then
        RUN_AUDIT_GATE_RC=1
    fi
    echo "RUN_AUDIT_GATE_RC=$RUN_AUDIT_GATE_RC"
    if [ "$RUN_AUDIT_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: patched control audit failed"
        RUN_OK=0
    fi
fi

if [ "$DIAGNOSTIC_ROOT" != "UNKNOWN" ]; then
    DIAGNOSTIC_COPY_GATE_RC=0
    for SPEC in \
        "$INPUT_STATUS|$DIAGNOSTIC_ROOT/source_applicability/gds_layer_applicability_review_status.rpt" \
        "$INPUT_COLLECTOR|$DIAGNOSTIC_ROOT/source_applicability/gds_layer_applicability_collector_status.rpt" \
        "$INPUT_POLICY|$DIAGNOSTIC_ROOT/source_applicability/position_option_policy_contract.rpt" \
        "$INPUT_SOURCE_IDENTITY|$DIAGNOSTIC_ROOT/source_applicability/source_file_identity.tsv" \
        "$INPUT_MANIFEST_CONSOLE|$DIAGNOSTIC_ROOT/source_applicability/SHA256SUMS.check.rpt" \
        "$PACKAGE_SHA_CONSOLE|$DIAGNOSTIC_ROOT/package_sha256_check.rpt"
    do
        SOURCE_FILE="${SPEC%%|*}"
        DESTINATION_FILE="${SPEC#*|}"
        if [ -f "$SOURCE_FILE" ]; then
            cp -p "$SOURCE_FILE" "$DESTINATION_FILE"
            [ "$?" -eq 0 ] || DIAGNOSTIC_COPY_GATE_RC=1
        else
            DIAGNOSTIC_COPY_GATE_RC=1
        fi
    done

    for VARIANT_SPEC in \
        "$BASE_RUN_DIR|$DIAGNOSTIC_ROOT/base" \
        "$DENSITY_RUN_DIR|$DIAGNOSTIC_ROOT/density"
    do
        SOURCE_DIR="${VARIANT_SPEC%%|*}"
        DESTINATION_DIR="${VARIANT_SPEC#*|}"
        for NAME in \
            pvs_drc_status.rpt \
            replay_contract_status.rpt \
            output_isolation.rpt \
            preprocessor_defines.rpt \
            external_references.rpt \
            template_replacements.rpt \
            pvsdrcctl \
            run.pvs \
            SHA256SUMS
        do
            if [ -f "$SOURCE_DIR/$NAME" ]; then
                cp -p "$SOURCE_DIR/$NAME" "$DESTINATION_DIR/$NAME"
                [ "$?" -eq 0 ] || DIAGNOSTIC_COPY_GATE_RC=1
            else
                DIAGNOSTIC_COPY_GATE_RC=1
            fi
        done
    done
    rm -f "$INPUT_MANIFEST_CONSOLE" "$PACKAGE_SHA_CONSOLE"
    echo "DIAGNOSTIC_COPY_GATE_RC=$DIAGNOSTIC_COPY_GATE_RC"
    if [ "$DIAGNOSTIC_COPY_GATE_RC" -ne 0 ]; then
        RUN_OK=0
    fi
fi

if [ "$DIAGNOSTIC_ROOT" != "UNKNOWN" ]; then
    SOURCE_POST_RECHECK_RC=0
    for SPEC in \
        "$INPUT_STATUS|$EXPECTED_APPLICABILITY_STATUS_SHA" \
        "$INPUT_COLLECTOR|$EXPECTED_APPLICABILITY_COLLECTOR_SHA" \
        "$INPUT_POLICY|$EXPECTED_POLICY_SHA" \
        "$PRIMARY_SEED/.config.rul|e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" \
        "$PRIMARY_SEED/.preset.autosave|97b3a7e63c3e8a01ea1291a19de384e2c41f77cd11653a92c7f5618e73421000" \
        "$PRIMARY_SEED/.technology.rul|74a297facf6422635df2c58d79aa8b8ae46ca0b8232380471a88a182d8400ab6" \
        "$PRIMARY_SEED/cell_tree.txt|cb6844854e367a916909b7b31d3451d21805d09f46f3ba876b940d901dc695e4" \
        "$PRIMARY_SEED/pipo1.setup|949ce7ec915d1ddbd3e78534720c33aad9036d83932c6bac33730a113aba00dd" \
        "$PRIMARY_SEED/pvsdrcctl|b9a8451c6cc43647ec606ae706e450893e3673e22215dc5a64edeeb383b902ef" \
        "$PRIMARY_SEED/run.pvs|11ae3fc935041b8a4e0f3b406941c699c769ed1d50a504e8df36fcb544c7255a"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_SHA="${SPEC#*|}"
        ACTUAL_SHA="$(sha256sum "$FILE" 2>/dev/null | awk '{print $1}')"
        if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
            SOURCE_POST_RECHECK_RC=1
        fi
    done
    echo "SOURCE_POST_RECHECK_RC=$SOURCE_POST_RECHECK_RC"
    if [ "$SOURCE_POST_RECHECK_RC" -ne 0 ]; then
        RUN_OK=0
    fi

    (
        cd "$PACKAGE" && sha256sum -c manifests/SHA256SUMS
    ) >"$DIAGNOSTIC_ROOT/package_sha256_post_preflight.rpt" 2>&1
    PACKAGE_POST_PREFLIGHT_SHA_MANIFEST_RC=$?
    echo "PACKAGE_POST_PREFLIGHT_SHA_MANIFEST_RC=$PACKAGE_POST_PREFLIGHT_SHA_MANIFEST_RC"
    if [ "$PACKAGE_POST_PREFLIGHT_SHA_MANIFEST_RC" -ne 0 ]; then
        RUN_OK=0
    fi
fi

if [ "$DIAGNOSTIC_ROOT" != "UNKNOWN" ]; then
    if [ "$RUN_OK" -eq 1 ]; then
        FINAL_STATUS=PASS
        PREFLIGHT_STATUS=PASS
        NEXT_GATE=RETURN_STRICT_DRY_RUN_CONTROLS_FOR_BASE_EXECUTION_AUTHORIZATION
    else
        FINAL_STATUS=FAIL
        PREFLIGHT_STATUS=FAIL
        NEXT_GATE=STOP_AND_REVIEW_STRICT_DRY_RUN_PREFLIGHT_FAILURE
    fi

    STATUS_REPORT="$DIAGNOSTIC_ROOT/position_pvs_drc_strict_preflight_status.rpt"
    {
        echo "LABEL=SPADMIC_POSITION_PVS_DRC_STRICT_PREFLIGHT"
        echo "STATUS=$FINAL_STATUS"
        echo "RESULT=BASE_AND_DENSITY_RUN_LOCAL_CONTROLS_MATERIALIZED_WITHOUT_PVS_EXECUTION"
        echo "SOURCE_GDS_LAYER_APPLICABILITY_ROOT=$APPLICABILITY_ROOT"
        echo "SOURCE_GDS_LAYER_APPLICABILITY_STATUS_SHA256=$EXPECTED_APPLICABILITY_STATUS_SHA"
        echo "PACKAGE=$PACKAGE"
        echo "PACKAGE_GDS_SHA256=$EXPECTED_GDS_SHA"
        echo "POSITION_TOP=$POSITION_TOP"
        echo "PRIMARY_SEED=$PRIMARY_SEED"
        echo "MANUAL_REVIEW_DECISION=AUTHORIZE_STRICT_DRY_RUN_PREFLIGHT"
        echo "CROSS_BLOCK_TEMPLATE_REUSE_SCOPE=CONTROL_SCAFFOLD_ONLY"
        echo "DEFAULT_RULE_SET=default"
        echo "PIMIDE_STATE=UNDEFINED"
        echo "POPPING_STATE=UNDEFINED"
        echo "DUMMY_FILL_STATE=UNDEFINED"
        echo "VAR_ANT_RATIO_STATE=DEFINED"
        echo "BASE_DENSITY_STATE=UNDEFINED"
        echo "DENSITY_VARIANT_DENSITY_STATE=DEFINED"
        echo "BASE_RUN_DIR=$BASE_RUN_DIR"
        echo "DENSITY_RUN_DIR=$DENSITY_RUN_DIR"
        echo "BASE_DRY_RUN_RC=$BASE_DRY_RUN_RC"
        echo "DENSITY_DRY_RUN_RC=$DENSITY_DRY_RUN_RC"
        echo "RUN_AUDIT_GATE_RC=$RUN_AUDIT_GATE_RC"
        echo "SOURCE_POST_RECHECK_RC=$SOURCE_POST_RECHECK_RC"
        echo "PACKAGE_POST_PREFLIGHT_SHA_MANIFEST_RC=$PACKAGE_POST_PREFLIGHT_SHA_MANIFEST_RC"
        echo "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=YES"
        echo "STRICT_DRY_RUN_PREFLIGHT_STATUS=$PREFLIGHT_STATUS"
        echo "PVS_BASE_DRC_EXECUTION_AUTHORIZED=NO"
        echo "PVS_DENSITY_DRC_EXECUTION_AUTHORIZED=NO"
        echo "PVS_REPLAY_AUTHORIZED=NO"
        echo "PVS_EXECUTED=NO"
        echo "PVS_BASE_DRC_STATUS=NOT_RUN"
        echo "PVS_DENSITY_DRC_STATUS=NOT_RUN"
        echo "PVS_LVS_STATUS=NOT_RUN"
        echo "BLOCK_PROMOTION_AUTHORIZED=NO"
        echo "SIGNOFF_READY=NO"
        echo "NEXT_GATE=$NEXT_GATE"
    } >"$STATUS_REPORT"

    find "$DIAGNOSTIC_ROOT" -type f ! -name SHA256SUMS \
        -print0 | sort -z | xargs -0 sha256sum >"$DIAGNOSTIC_ROOT/SHA256SUMS"

    echo
    echo "===== POSITION PVS DRC STRICT PREFLIGHT STATUS ====="
    cat "$STATUS_REPORT"
    echo
    echo "===== BASE DRY-RUN STATUS ====="
    cat "$BASE_RUN_DIR/pvs_drc_status.rpt" 2>/dev/null
    cat "$BASE_RUN_DIR/replay_contract_status.rpt" 2>/dev/null
    cat "$BASE_RUN_DIR/preprocessor_defines.rpt" 2>/dev/null
    echo
    echo "===== DENSITY DRY-RUN STATUS ====="
    cat "$DENSITY_RUN_DIR/pvs_drc_status.rpt" 2>/dev/null
    cat "$DENSITY_RUN_DIR/replay_contract_status.rpt" 2>/dev/null
    cat "$DENSITY_RUN_DIR/preprocessor_defines.rpt" 2>/dev/null

    if [ "$FINAL_STATUS" = "PASS" ]; then
        true
    else
        false
    fi
else
    if [ -n "$INPUT_MANIFEST_CONSOLE" ]; then
        rm -f "$INPUT_MANIFEST_CONSOLE"
    fi
    if [ -n "$PACKAGE_SHA_CONSOLE" ]; then
        rm -f "$PACKAGE_SHA_CONSOLE"
    fi
    echo "POSITION_PVS_DRC_STRICT_PREFLIGHT_STATUS=NOT_RUN"
    echo "PVS_EXECUTED=NO"
    false
fi
