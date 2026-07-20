#!/usr/bin/env bash
# Execute and classify one attributable exact-GDS Position PVS LVS run.

set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
EXPECTED_HEAD="${1:-MISSING}"
DENSITY_DRC_ROOT="${2:-MISSING}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"

PACKAGE="$WORK_ROOT/handoff/innovus/blocks/spadmic_position_core/innovus_ooc_harden_position_core_gridfit_20260717_114810"
PACKAGE_GDS="$PACKAGE/gds/spadmic_position_core.gds"
PACKAGE_SOURCE="$PACKAGE/netlist/spadmic_position_core.lvs.pg.v"
PACKAGE_CDL="$PACKAGE/pdk/xh018_D_CELLS_JIHD.cdl"
POSITION_TOP=spadmic_position_core
EXPECTED_GDS_SHA=ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1
EXPECTED_SOURCE_SHA=a5e81c21e633ae1b55d8da5c8e971997f890d9cee42dff2f6cf9f9f43cad9ffb
EXPECTED_CDL_SHA=5ff10b0b31003da9bb6db59eba7d52c82435e3ab68b2ba0a1956e4d9fbaef8cf

LVS_TEMPLATE=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/PvsLVS/spadmic_tx_packet_core_HV
TEMPLATE_BASELINE_ID=SERVER_OBSERVED_20260720_141229
EXPECTED_TEMPLATE_CONFIG_SHA=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
EXPECTED_TEMPLATE_PRESET_SHA=43d19579b0569863b1c5fcc317206cc5f3f70611b22f9bdea932d757ff902dfe
EXPECTED_TEMPLATE_TECHNOLOGY_SHA=74a297facf6422635df2c58d79aa8b8ae46ca0b8232380471a88a182d8400ab6
EXPECTED_TEMPLATE_PIPO1_SHA=ed8c1a13ab8ec90af3f367b4d408e5f9c767f1e99736e31f02c54be9fa91abbc
EXPECTED_TEMPLATE_CONTROL_SHA=8e53876734717f4c0857f1310d08e3a4c8fb18aeaa7694800b7d0cdcd511c5e6
EXPECTED_TEMPLATE_RUN_SHA=dfe5394bd98c828e868a7a3f18acda2f56f993ba58dcf8343f097858f77b0c27
TEMPLATE_GDS=UNKNOWN
TEMPLATE_SOURCE=UNKNOWN
TEMPLATE_LAYOUT_TOP=UNKNOWN
TEMPLATE_SOURCE_TOP=UNKNOWN
TEMPLATE_AUDIT=UNKNOWN

EXPECTED_DENSITY_STATUS_SHA=8ec65bc2a36c6ea51bb163e3bce796d8288f4dee25a4b4c27670a3309ef66686
EXPECTED_DENSITY_RUN_SHA=9b6a1ec7fa75111a393a6a63f7af44cc66f1c7ef6334506d24cd35880c8ce90e
EXPECTED_DENSITY_REPLAY_SHA=81dd3cc0ed5231179242b4a9af59672ec3eb23e0b6748ac25dc7b1b9f8346115
EXPECTED_DENSITY_ISOLATION_SHA=9ea0552d672fe970d7bd521a5ca1bf652f308e2686be1c1c683f5bfe09e310a4
EXPECTED_DENSITY_DEFINES_SHA=6fb64ded8ddc233d1189d0da3cb6e3857ea998dc4ae6c59b7e4db972f89b6e3c
EXPECTED_DENSITY_REFERENCES_SHA=44f77c9f4bcf74665edd21bbd41fd315183156791124c2b898724e173092250a
EXPECTED_DENSITY_ANALYSIS_SHA=a6d6e3b7359f49dac74f71d58c62f82269c6e682df7f503b55745a4448b09717
EXPECTED_DENSITY_INVENTORY_SHA=d3fa48ffaeb2e94069c9a132188ca08dd25377bc31d5299fe418da2ee6f229f1

PVS_BIN=/eda/cadence/2023-24/RHELx86/PVS_22.22.000/bin/pvs
STREAM_LAYER_TABLE=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/.xkit/setup/xh018/cadence/PDK/TECH_XH018_1131/strmInOut.layertable
STREAM_OBJECT_MAP=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/.xkit/setup/xh018/cadence/PDK/TECH_XH018_1131/strmOutObjects.map
PVTECH_LIB=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/pvtech.lib
LVS_RULE=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/.xkit/setup/xh018/cadence/pvs/PVS/xh018_LVS.rul

RUN_OK=1
CD_RC=NOT_RUN
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
DIAGNOSTIC_ROOT=UNKNOWN
DIAGNOSTIC_CREATE_RC=NOT_RUN
DENSITY_FILE_GATE_RC=NOT_RUN
DENSITY_HASH_GATE_RC=NOT_RUN
DENSITY_MANIFEST_RC=NOT_RUN
DENSITY_STATUS_GATE_RC=NOT_RUN
DENSITY_SEMANTIC_GATE_RC=NOT_RUN
PACKAGE_GATE_RC=NOT_RUN
PACKAGE_SHA_MANIFEST_RC=NOT_RUN
TEMPLATE_FILE_GATE_RC=NOT_RUN
TEMPLATE_IDENTITY_GATE_RC=NOT_RUN
TEMPLATE_SEMANTIC_GATE_RC=NOT_RUN
SOURCE_REFERENCE_GATE_RC=NOT_RUN
PVS_WRAPPER_RC=NOT_RUN
RUN_DIR=UNKNOWN
RUN_FILE_GATE_RC=NOT_RUN
RUN_AUDIT_GATE_RC=NOT_RUN
RUN_MANIFEST_RC=NOT_RUN
DIAGNOSTIC_COPY_GATE_RC=NOT_RUN
SOURCE_POST_RECHECK_RC=NOT_RUN
PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC=NOT_RUN
PVS_TOOL_RC=UNKNOWN
PVS_LVS_STATUS=UNKNOWN
LVS_NEGATIVE_MATCH_COUNT=UNKNOWN
LVS_POSITIVE_MATCH_COUNT=UNKNOWN
PVS_EVIDENCE=UNKNOWN
REPLAY_CONTRACT_STATUS=UNKNOWN
OUTPUT_ISOLATION_STATUS=UNKNOWN
PVS_LVS_EXECUTION_AUTHORIZED=NO
PVS_REPLAY_AUTHORIZED=NO
PVS_EXECUTED=NO
OUTCOME_CLASS=NOT_CLASSIFIED
TRANSACTION_STATUS=FAIL
TRANSACTION_RESULT=EXACT_GDS_PVS_LVS_NOT_EXECUTED
NEXT_GATE=STOP_AND_REVIEW_EXACT_GDS_PVS_LVS_FAILURE

kv_field() {
    local path="$1"
    local key="$2"
    if [ -r "$path" ]; then
        awk -F= -v key="$key" \
            '$1 == key {value = substr($0, index($0, "=") + 1)} END {print value}' \
            "$path"
    fi
}

is_uint() {
    case "$1" in
        ''|*[!0-9]*) return 1 ;;
        *) return 0 ;;
    esac
}

if [ "$EXPECTED_HEAD" = "MISSING" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: expected repository HEAD argument missing"
    RUN_OK=0
fi

if [ "$DENSITY_DRC_ROOT" = "MISSING" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: density-DRC diagnostic root missing"
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
    EXECUTION_STAMP="$(date +%Y%m%d_%H%M%S)"
    DIAGNOSTIC_ROOT="$WORK_ROOT/diagnostics/position_pvs_lvs_execution_$EXECUTION_STAMP"
    RUN_ID="position_exact_gds_lvs_$EXECUTION_STAMP"
    RUN_DIR="$PACKAGE/pvs/lvs/$RUN_ID"
    if [ -e "$DIAGNOSTIC_ROOT" ] || [ -e "$RUN_DIR" ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: fresh execution path already exists"
        DIAGNOSTIC_CREATE_RC=1
    else
        mkdir -p "$DIAGNOSTIC_ROOT/source_density_drc" "$DIAGNOSTIC_ROOT/run_evidence"
        DIAGNOSTIC_CREATE_RC=$?
    fi
    echo "DIAGNOSTIC_ROOT=$DIAGNOSTIC_ROOT"
    echo "RUN_DIR=$RUN_DIR"
    echo "DIAGNOSTIC_CREATE_RC=$DIAGNOSTIC_CREATE_RC"
    if [ "$DIAGNOSTIC_CREATE_RC" -ne 0 ]; then
        DIAGNOSTIC_ROOT=UNKNOWN
        RUN_DIR=UNKNOWN
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    DENSITY_STATUS="$DENSITY_DRC_ROOT/position_pvs_drc_density_execution_status.rpt"
    DENSITY_RUN_STATUS="$DENSITY_DRC_ROOT/run_evidence/pvs_drc_status.rpt"
    DENSITY_REPLAY="$DENSITY_DRC_ROOT/run_evidence/replay_contract_status.rpt"
    DENSITY_ISOLATION="$DENSITY_DRC_ROOT/run_evidence/output_isolation.rpt"
    DENSITY_DEFINES="$DENSITY_DRC_ROOT/run_evidence/preprocessor_defines.rpt"
    DENSITY_REFERENCES="$DENSITY_DRC_ROOT/run_evidence/external_references.rpt"
    DENSITY_ANALYSIS="$DENSITY_DRC_ROOT/rule_analysis/pvs_drc_analysis_status.rpt"
    DENSITY_INVENTORY="$DENSITY_DRC_ROOT/rule_analysis/pvs_drc_rule_inventory.tsv"

    DENSITY_FILE_GATE_RC=0
    for FILE in \
        "$DENSITY_STATUS" \
        "$DENSITY_RUN_STATUS" \
        "$DENSITY_REPLAY" \
        "$DENSITY_ISOLATION" \
        "$DENSITY_DEFINES" \
        "$DENSITY_REFERENCES" \
        "$DENSITY_ANALYSIS" \
        "$DENSITY_INVENTORY" \
        "$DENSITY_DRC_ROOT/SHA256SUMS"
    do
        if [ ! -s "$FILE" ]; then
            echo "MISSING_OR_EMPTY=$FILE"
            DENSITY_FILE_GATE_RC=1
        fi
    done
    echo "DENSITY_FILE_GATE_RC=$DENSITY_FILE_GATE_RC"
    [ "$DENSITY_FILE_GATE_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    DENSITY_HASH_GATE_RC=0
    for SPEC in \
        "$DENSITY_STATUS|$EXPECTED_DENSITY_STATUS_SHA" \
        "$DENSITY_RUN_STATUS|$EXPECTED_DENSITY_RUN_SHA" \
        "$DENSITY_REPLAY|$EXPECTED_DENSITY_REPLAY_SHA" \
        "$DENSITY_ISOLATION|$EXPECTED_DENSITY_ISOLATION_SHA" \
        "$DENSITY_DEFINES|$EXPECTED_DENSITY_DEFINES_SHA" \
        "$DENSITY_REFERENCES|$EXPECTED_DENSITY_REFERENCES_SHA" \
        "$DENSITY_ANALYSIS|$EXPECTED_DENSITY_ANALYSIS_SHA" \
        "$DENSITY_INVENTORY|$EXPECTED_DENSITY_INVENTORY_SHA"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_SHA="${SPEC#*|}"
        ACTUAL_SHA="$(sha256sum "$FILE" | awk '{print $1}')"
        echo "DENSITY_FILE=$FILE"
        echo "DENSITY_EXPECTED_SHA256=$EXPECTED_SHA"
        echo "DENSITY_ACTUAL_SHA256=$ACTUAL_SHA"
        [ "$ACTUAL_SHA" = "$EXPECTED_SHA" ] || DENSITY_HASH_GATE_RC=1
    done
    echo "DENSITY_HASH_GATE_RC=$DENSITY_HASH_GATE_RC"
    [ "$DENSITY_HASH_GATE_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    (
        if cd "$DENSITY_DRC_ROOT"; then
            sha256sum -c SHA256SUMS
        else
            false
        fi
    ) >"$DIAGNOSTIC_ROOT/source_density_drc/SHA256SUMS.check.rpt" 2>&1
    DENSITY_MANIFEST_RC=$?
    echo "DENSITY_MANIFEST_RC=$DENSITY_MANIFEST_RC"
    [ "$DENSITY_MANIFEST_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    DENSITY_STATUS_GATE_RC=0
    for SPEC in \
        "$DENSITY_STATUS|STATUS=PASS" \
        "$DENSITY_STATUS|RESULT=PVS_DENSITY_DRC_NONZERO_RULE_DEBT_CLASSIFIED" \
        "$DENSITY_STATUS|PACKAGE_GDS_SHA256=$EXPECTED_GDS_SHA" \
        "$DENSITY_STATUS|POSITION_TOP=$POSITION_TOP" \
        "$DENSITY_STATUS|OUTCOME_CLASS=ATTRIBUTABLE_NONZERO_RESULTS" \
        "$DENSITY_STATUS|PVS_TOOL_RC=0" \
        "$DENSITY_STATUS|PVS_BASE_DRC_STATUS=PASS" \
        "$DENSITY_STATUS|PVS_DENSITY_DRC_STATUS=FAIL" \
        "$DENSITY_STATUS|DRC_TOTAL_PRIMARY=4" \
        "$DENSITY_STATUS|DRC_TOTAL_EXPANDED=4" \
        "$DENSITY_STATUS|RULE_ANALYSIS_RC=0" \
        "$DENSITY_STATUS|RULE_ANALYSIS_STATUS=PASS" \
        "$DENSITY_STATUS|PVS_EXECUTED=YES" \
        "$DENSITY_STATUS|PVS_LVS_STATUS=NOT_RUN" \
        "$DENSITY_STATUS|NEXT_GATE=FOREGROUND_EXACT_GDS_PVS_LVS" \
        "$DENSITY_RUN_STATUS|PVS_RC=0" \
        "$DENSITY_RUN_STATUS|PVS_DRC_STATUS=FAIL" \
        "$DENSITY_RUN_STATUS|DRC_TOTAL_PRIMARY=4" \
        "$DENSITY_RUN_STATUS|DRC_TOTAL_EXPANDED=4" \
        "$DENSITY_RUN_STATUS|PVS_DRC_VARIANT=DENSITY" \
        "$DENSITY_RUN_STATUS|GDS_SHA256=$EXPECTED_GDS_SHA" \
        "$DENSITY_REPLAY|STATUS=PASS" \
        "$DENSITY_REPLAY|LAYOUT_TOP=$POSITION_TOP" \
        "$DENSITY_DEFINES|DEFINE=DENSITY|OCCURRENCES=1" \
        "$DENSITY_ANALYSIS|STATUS=PASS" \
        "$DENSITY_ANALYSIS|NONZERO_RULE_COUNT=4" \
        "$DENSITY_ANALYSIS|RESULT_COUNT_RECONCILIATION=PASS" \
        "$DENSITY_ANALYSIS|ASCII_ERROR_GEOMETRY_RECONCILIATION=PASS" \
        "$DENSITY_ANALYSIS|DENSITY_STATE=DEFINED" \
        "$DENSITY_ANALYSIS|ANTENNA_PRIMARY_RESULT_COUNT=0" \
        "$DENSITY_ANALYSIS|NON_ANTENNA_PRIMARY_RESULT_COUNT=4"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_LINE="${SPEC#*|}"
        grep -Fxq -- "$EXPECTED_LINE" "$FILE"
        [ "$?" -eq 0 ] || DENSITY_STATUS_GATE_RC=1
    done
    grep -q '^MISSING=' "$DENSITY_REFERENCES"
    [ "$?" -ne 0 ] || DENSITY_STATUS_GATE_RC=1
    echo "DENSITY_STATUS_GATE_RC=$DENSITY_STATUS_GATE_RC"
    [ "$DENSITY_STATUS_GATE_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    awk -F '\t' '
        NR == 1 { next }
        {
            count++
            expected["R1M1"] = "MET1"
            expected["R1M2"] = "MET2"
            expected["R1M3"] = "MET3"
            expected["R1MT"] = "METTP"
            if (!($2 in expected) || seen[$2]++) bad = 1
            if ($3 != 1 || $4 != 1 || $9 != expected[$2]) bad = 1
            if ($10 != "Minimum ratio of " expected[$2] " area to EXTENT area ... 30.0%") bad = 1
            if ($11 != 1 || $12 != "0.000000 0.000000 951.440000 659.680000") bad = 1
        }
        END {
            if (count != 4) bad = 1
            for (rule in expected) if (seen[rule] != 1) bad = 1
            exit bad
        }
    ' "$DENSITY_INVENTORY"
    DENSITY_SEMANTIC_GATE_RC=$?
    echo "DENSITY_SEMANTIC_GATE_RC=$DENSITY_SEMANTIC_GATE_RC"
    [ "$DENSITY_SEMANTIC_GATE_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    PACKAGE_GATE_RC=0
    for SPEC in \
        "$PACKAGE_GDS|$EXPECTED_GDS_SHA" \
        "$PACKAGE_SOURCE|$EXPECTED_SOURCE_SHA" \
        "$PACKAGE_CDL|$EXPECTED_CDL_SHA"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_SHA="${SPEC#*|}"
        if [ ! -s "$FILE" ]; then
            PACKAGE_GATE_RC=1
            continue
        fi
        ACTUAL_SHA="$(sha256sum "$FILE" | awk '{print $1}')"
        echo "PACKAGE_FILE=$FILE"
        echo "PACKAGE_EXPECTED_SHA256=$EXPECTED_SHA"
        echo "PACKAGE_ACTUAL_SHA256=$ACTUAL_SHA"
        [ "$ACTUAL_SHA" = "$EXPECTED_SHA" ] || PACKAGE_GATE_RC=1
    done
    [ -s "$PACKAGE/manifests/SHA256SUMS" ] || PACKAGE_GATE_RC=1
    echo "PACKAGE_GATE_RC=$PACKAGE_GATE_RC"
    [ "$PACKAGE_GATE_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    (
        if cd "$PACKAGE"; then
            sha256sum -c manifests/SHA256SUMS
        else
            false
        fi
    ) >"$DIAGNOSTIC_ROOT/package_sha256_check.rpt" 2>&1
    PACKAGE_SHA_MANIFEST_RC=$?
    echo "PACKAGE_SHA_MANIFEST_RC=$PACKAGE_SHA_MANIFEST_RC"
    [ "$PACKAGE_SHA_MANIFEST_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    TEMPLATE_FILE_GATE_RC=0
    for FILE in \
        "$LVS_TEMPLATE/.config.rul" \
        "$LVS_TEMPLATE/.preset.autosave" \
        "$LVS_TEMPLATE/.technology.rul" \
        "$LVS_TEMPLATE/pipo1.setup" \
        "$LVS_TEMPLATE/pvslvsctl" \
        "$LVS_TEMPLATE/run.pvs"
    do
        if [ ! -f "$FILE" ]; then
            echo "MISSING=$FILE"
            TEMPLATE_FILE_GATE_RC=1
        fi
    done
    echo "TEMPLATE_FILE_GATE_RC=$TEMPLATE_FILE_GATE_RC"
    [ "$TEMPLATE_FILE_GATE_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    TEMPLATE_IDENTITY_GATE_RC=0
    for SPEC in \
        ".config.rul|$EXPECTED_TEMPLATE_CONFIG_SHA" \
        ".preset.autosave|$EXPECTED_TEMPLATE_PRESET_SHA" \
        ".technology.rul|$EXPECTED_TEMPLATE_TECHNOLOGY_SHA" \
        "pipo1.setup|$EXPECTED_TEMPLATE_PIPO1_SHA" \
        "pvslvsctl|$EXPECTED_TEMPLATE_CONTROL_SHA" \
        "run.pvs|$EXPECTED_TEMPLATE_RUN_SHA"
    do
        NAME="${SPEC%%|*}"
        EXPECTED_SHA="${SPEC#*|}"
        ACTUAL_SHA="$(sha256sum "$LVS_TEMPLATE/$NAME" | awk '{print $1}')"
        echo "TEMPLATE_CONTROL=$LVS_TEMPLATE/$NAME"
        echo "TEMPLATE_EXPECTED_SHA256=$EXPECTED_SHA"
        echo "TEMPLATE_ACTUAL_SHA256=$ACTUAL_SHA"
        [ "$ACTUAL_SHA" = "$EXPECTED_SHA" ] || TEMPLATE_IDENTITY_GATE_RC=1
    done
    echo "TEMPLATE_IDENTITY_GATE_RC=$TEMPLATE_IDENTITY_GATE_RC"
    [ "$TEMPLATE_IDENTITY_GATE_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    TEMPLATE_AUDIT="$DIAGNOSTIC_ROOT/template_scaffold_audit.rpt"
    python3 TOP/pnr/scripts/audit_pvs_lvs_control_scaffold.py \
        --template "$LVS_TEMPLATE" \
        --output "$TEMPLATE_AUDIT" \
        --expected-pvs-bin "$PVS_BIN"
    TEMPLATE_SEMANTIC_GATE_RC=$?
    echo "TEMPLATE_SEMANTIC_GATE_RC=$TEMPLATE_SEMANTIC_GATE_RC"

    if [ "$TEMPLATE_SEMANTIC_GATE_RC" -eq 0 ]; then
        TEMPLATE_GDS="$(kv_field "$TEMPLATE_AUDIT" TEMPLATE_GDS)"
        TEMPLATE_SOURCE="$(kv_field "$TEMPLATE_AUDIT" TEMPLATE_SOURCE)"
        TEMPLATE_LAYOUT_TOP="$(kv_field "$TEMPLATE_AUDIT" TEMPLATE_LAYOUT_TOP)"
        TEMPLATE_SOURCE_TOP="$(kv_field "$TEMPLATE_AUDIT" TEMPLATE_SOURCE_TOP)"
        for VALUE in \
            "$TEMPLATE_GDS" \
            "$TEMPLATE_SOURCE" \
            "$TEMPLATE_LAYOUT_TOP" \
            "$TEMPLATE_SOURCE_TOP"
        do
            if [ -z "$VALUE" ] || [ "$VALUE" = "UNKNOWN" ]; then
                TEMPLATE_SEMANTIC_GATE_RC=1
            fi
        done
    fi

    echo "TEMPLATE_GDS=$TEMPLATE_GDS"
    echo "TEMPLATE_SOURCE=$TEMPLATE_SOURCE"
    echo "TEMPLATE_LAYOUT_TOP=$TEMPLATE_LAYOUT_TOP"
    echo "TEMPLATE_SOURCE_TOP=$TEMPLATE_SOURCE_TOP"
    [ "$TEMPLATE_SEMANTIC_GATE_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    SOURCE_REFERENCE_GATE_RC=0
    for SPEC in \
        "$PVS_BIN|e2a50b5eb73539f78adb042ede0613c8ef9be3d9e2ed4a453a3c9266bcae3f15" \
        "$STREAM_LAYER_TABLE|3198c31b841a29b1126206f7962632fd7f6dc239c53931962cd57327d2320869" \
        "$STREAM_OBJECT_MAP|151695165c1679190e1f95aa0ccb854de233c7a7e3f589a5ac83c93c0c487c7c" \
        "$PVTECH_LIB|1fe31de76c4b1c0d69afe6bdb31ccad89dd1f43429697f5043c57d4547a93bef" \
        "$LVS_RULE|30c5b47434035ca4b9540f2f333fc2506a063f0b3dfc05f49de72c3a60c755f0"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_SHA="${SPEC#*|}"
        if [ ! -s "$FILE" ]; then
            echo "MISSING_OR_EMPTY=$FILE"
            SOURCE_REFERENCE_GATE_RC=1
            continue
        fi
        ACTUAL_SHA="$(sha256sum "$FILE" | awk '{print $1}')"
        echo "SOURCE_REFERENCE=$FILE"
        echo "SOURCE_EXPECTED_SHA256=$EXPECTED_SHA"
        echo "SOURCE_ACTUAL_SHA256=$ACTUAL_SHA"
        [ "$ACTUAL_SHA" = "$EXPECTED_SHA" ] || SOURCE_REFERENCE_GATE_RC=1
    done
    echo "SOURCE_REFERENCE_GATE_RC=$SOURCE_REFERENCE_GATE_RC"
    [ "$SOURCE_REFERENCE_GATE_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$RUN_OK" -eq 1 ]; then
    echo "MANUAL_REVIEW_DECISION=AUTHORIZE_ONE_FOREGROUND_EXACT_GDS_PVS_LVS"
    echo "CROSS_BLOCK_TEMPLATE_REUSE_SCOPE=CONTROL_SCAFFOLD_ONLY"
    PVS_LVS_EXECUTION_AUTHORIZED=YES
    PVS_REPLAY_AUTHORIZED=YES
    EXPECTED_HEAD="$EXPECTED_HEAD" \
    SPADMIC_CADENCE_PVS_BIN="$PVS_BIN" \
    bash TOP/pnr/scripts/run_pvs_lvs_handoff.sh \
        --package "$PACKAGE" \
        --template "$LVS_TEMPLATE" \
        --template-gds "$TEMPLATE_GDS" \
        --template-source "$TEMPLATE_SOURCE" \
        --template-layout-top "$TEMPLATE_LAYOUT_TOP" \
        --template-source-top "$TEMPLATE_SOURCE_TOP" \
        --run-id "$RUN_ID" \
        --allow-cross-block-control-scaffold \
        2>&1 | tee "$DIAGNOSTIC_ROOT/pvs_lvs.console.log"
    PVS_WRAPPER_RC=${PIPESTATUS[0]}
    echo "PVS_WRAPPER_RC=$PVS_WRAPPER_RC"
fi

RUN_STATUS="$RUN_DIR/pvs_lvs_status.rpt"
RUN_REPLAY="$RUN_DIR/replay_contract_status.rpt"
RUN_ISOLATION="$RUN_DIR/output_isolation.rpt"
RUN_REFERENCES="$RUN_DIR/external_references.rpt"
RUN_DEFINES="$RUN_DIR/preprocessor_defines.rpt"

if [ -f "$RUN_DIR/pvs.stdout.log" ]; then
    PVS_EXECUTED=YES
fi

if [ "$RUN_DIR" != "UNKNOWN" ]; then
    RUN_FILE_GATE_RC=0
    for FILE in \
        "$RUN_STATUS" \
        "$RUN_REPLAY" \
        "$RUN_ISOLATION" \
        "$RUN_REFERENCES" \
        "$RUN_DEFINES" \
        "$RUN_DIR/pvslvsctl" \
        "$RUN_DIR/run.pvs" \
        "$RUN_DIR/pvs_result_evidence_inventory.rpt" \
        "$RUN_DIR/SHA256SUMS"
    do
        if [ ! -s "$FILE" ]; then
            echo "MISSING_OR_EMPTY=$FILE"
            RUN_FILE_GATE_RC=1
        fi
    done
    echo "RUN_FILE_GATE_RC=$RUN_FILE_GATE_RC"
fi

if [ "$RUN_FILE_GATE_RC" = "0" ]; then
    PVS_TOOL_RC="$(kv_field "$RUN_STATUS" PVS_RC)"
    PVS_LVS_STATUS="$(kv_field "$RUN_STATUS" PVS_LVS_STATUS)"
    LVS_NEGATIVE_MATCH_COUNT="$(kv_field "$RUN_STATUS" LVS_NEGATIVE_MATCH_COUNT)"
    LVS_POSITIVE_MATCH_COUNT="$(kv_field "$RUN_STATUS" LVS_POSITIVE_MATCH_COUNT)"
    PVS_EVIDENCE="$(kv_field "$RUN_STATUS" EVIDENCE)"
    REPLAY_CONTRACT_STATUS="$(kv_field "$RUN_REPLAY" STATUS)"
    OUTPUT_ISOLATION_STATUS="$(kv_field "$RUN_ISOLATION" STATUS)"

    RUN_AUDIT_GATE_RC=0
    for SPEC in \
        "$RUN_STATUS|LABEL=SPADMIC_PVS_HANDOFF_RESULT" \
        "$RUN_STATUS|MODE=LVS" \
        "$RUN_STATUS|CROSS_BLOCK_CONTROL_SCAFFOLD_AUTHORIZED=YES" \
        "$RUN_STATUS|PACKAGE=$PACKAGE" \
        "$RUN_STATUS|LAYOUT_TOP=$POSITION_TOP" \
        "$RUN_STATUS|SOURCE_TOP=$POSITION_TOP" \
        "$RUN_STATUS|GDS=$PACKAGE_GDS" \
        "$RUN_STATUS|GDS_SHA256=$EXPECTED_GDS_SHA" \
        "$RUN_STATUS|LVS_SOURCE=$PACKAGE_SOURCE" \
        "$RUN_STATUS|LVS_SOURCE_SHA256=$EXPECTED_SOURCE_SHA" \
        "$RUN_STATUS|STDCELL_CDL=$PACKAGE_CDL" \
        "$RUN_STATUS|STDCELL_CDL_SHA256=$EXPECTED_CDL_SHA" \
        "$RUN_REPLAY|STATUS=PASS" \
        "$RUN_REPLAY|MODE=LVS" \
        "$RUN_REPLAY|EXECUTION_DIRECTORY_STATUS=PASS" \
        "$RUN_REPLAY|OUTPUT_ISOLATION_STATUS=PASS" \
        "$RUN_REPLAY|LAYOUT_TOP=$POSITION_TOP" \
        "$RUN_REPLAY|SOURCE_TOP=$POSITION_TOP" \
        "$RUN_REPLAY|GDS=$PACKAGE_GDS" \
        "$RUN_REPLAY|SOURCE=$PACKAGE_SOURCE" \
        "$RUN_REPLAY|CDL=$PACKAGE_CDL" \
        "$RUN_ISOLATION|STATUS=PASS" \
        "$RUN_ISOLATION|MODE=LVS" \
        "$RUN_ISOLATION|SPICE_OUTPUT_REWRITE_COUNT=1" \
        "$RUN_ISOLATION|LAYOUT_GDS_INPUT=$PACKAGE_GDS" \
        "$RUN_ISOLATION|LAYOUT_GDS_REWRITE_COUNT=1" \
        "$RUN_ISOLATION|SCHEMATIC_VERILOG_INPUT=$PACKAGE_SOURCE" \
        "$RUN_ISOLATION|SCHEMATIC_VERILOG_ACTION=REPLACED_EXISTING" \
        "$RUN_ISOLATION|SCHEMATIC_CDL_INPUT=$PACKAGE_CDL" \
        "$RUN_ISOLATION|SCHEMATIC_CDL_ACTION=ADDED_MISSING" \
        "$RUN_ISOLATION|LVS_REPORT_REWRITE_COUNT=1" \
        "$RUN_ISOLATION|ERC_SUMMARY_REWRITE_COUNT=1" \
        "$RUN_ISOLATION|ERC_RESULTS_DB_REWRITE_COUNT=1" \
        "$RUN_ISOLATION|SVDB_DIRECTORY=$RUN_DIR/svdb" \
        "$RUN_ISOLATION|SVDB_ACTION=ADDED_MISSING" \
        "$RUN_ISOLATION|SVDB_REWRITE_COUNT=0"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_LINE="${SPEC#*|}"
        grep -Fxq -- "$EXPECTED_LINE" "$FILE"
        [ "$?" -eq 0 ] || RUN_AUDIT_GATE_RC=1
    done
    grep -q '^MISSING=' "$RUN_REFERENCES"
    [ "$?" -ne 0 ] || RUN_AUDIT_GATE_RC=1
    [ "$(grep -Foc "$PACKAGE_SOURCE" "$RUN_DIR/pvslvsctl")" -eq 1 ] || RUN_AUDIT_GATE_RC=1
    [ "$(grep -Foc "$PACKAGE_CDL" "$RUN_DIR/pvslvsctl")" -eq 1 ] || RUN_AUDIT_GATE_RC=1
    if [ "$TEMPLATE_SOURCE" != "$PACKAGE_SOURCE" ]; then
        grep -Fq "$TEMPLATE_SOURCE" "$RUN_DIR/pvslvsctl"
        [ "$?" -ne 0 ] || RUN_AUDIT_GATE_RC=1
    fi
    if [ "$TEMPLATE_GDS" != "$PACKAGE_GDS" ]; then
        grep -Fq "$TEMPLATE_GDS" "$RUN_DIR/pvslvsctl"
        [ "$?" -ne 0 ] || RUN_AUDIT_GATE_RC=1
    fi
    echo "RUN_AUDIT_GATE_RC=$RUN_AUDIT_GATE_RC"

    (
        if cd "$RUN_DIR"; then
            sha256sum -c SHA256SUMS
        else
            false
        fi
    ) >"$DIAGNOSTIC_ROOT/run_evidence/SHA256SUMS.check.rpt" 2>&1
    RUN_MANIFEST_RC=$?
    echo "RUN_MANIFEST_RC=$RUN_MANIFEST_RC"
fi

if [ "$RUN_FILE_GATE_RC" = "0" ] && \
   [ "$RUN_AUDIT_GATE_RC" = "0" ] && \
   [ "$RUN_MANIFEST_RC" = "0" ] && \
   [ "$PVS_TOOL_RC" = "0" ] && \
   is_uint "$LVS_NEGATIVE_MATCH_COUNT" && \
   is_uint "$LVS_POSITIVE_MATCH_COUNT" && \
   [ -s "$PVS_EVIDENCE" ]; then
    if [ "$PVS_WRAPPER_RC" = "0" ] && \
       [ "$PVS_LVS_STATUS" = "MATCH" ] && \
       [ "$LVS_NEGATIVE_MATCH_COUNT" -eq 0 ] && \
       [ "$LVS_POSITIVE_MATCH_COUNT" -gt 0 ]; then
        OUTCOME_CLASS=ATTRIBUTABLE_MATCH
    elif [ "$PVS_WRAPPER_RC" = "8" ] && \
         [ "$PVS_LVS_STATUS" = "MISMATCH" ] && \
         [ "$LVS_NEGATIVE_MATCH_COUNT" -gt 0 ]; then
        OUTCOME_CLASS=ATTRIBUTABLE_MISMATCH
    fi
fi

echo "PVS_TOOL_RC=$PVS_TOOL_RC"
echo "PVS_LVS_STATUS=$PVS_LVS_STATUS"
echo "LVS_NEGATIVE_MATCH_COUNT=$LVS_NEGATIVE_MATCH_COUNT"
echo "LVS_POSITIVE_MATCH_COUNT=$LVS_POSITIVE_MATCH_COUNT"
echo "OUTCOME_CLASS=$OUTCOME_CLASS"

if [ "$DIAGNOSTIC_ROOT" != "UNKNOWN" ]; then
    DIAGNOSTIC_COPY_GATE_RC=0
    for SPEC in \
        "$DENSITY_STATUS|$DIAGNOSTIC_ROOT/source_density_drc/position_pvs_drc_density_execution_status.rpt" \
        "$DENSITY_RUN_STATUS|$DIAGNOSTIC_ROOT/source_density_drc/pvs_drc_status.rpt" \
        "$DENSITY_REPLAY|$DIAGNOSTIC_ROOT/source_density_drc/replay_contract_status.rpt" \
        "$DENSITY_ISOLATION|$DIAGNOSTIC_ROOT/source_density_drc/output_isolation.rpt" \
        "$DENSITY_DEFINES|$DIAGNOSTIC_ROOT/source_density_drc/preprocessor_defines.rpt" \
        "$DENSITY_REFERENCES|$DIAGNOSTIC_ROOT/source_density_drc/external_references.rpt" \
        "$DENSITY_ANALYSIS|$DIAGNOSTIC_ROOT/source_density_drc/pvs_drc_analysis_status.rpt" \
        "$DENSITY_INVENTORY|$DIAGNOSTIC_ROOT/source_density_drc/pvs_drc_rule_inventory.tsv" \
        "$DENSITY_DRC_ROOT/SHA256SUMS|$DIAGNOSTIC_ROOT/source_density_drc/SHA256SUMS" \
        "$RUN_STATUS|$DIAGNOSTIC_ROOT/run_evidence/pvs_lvs_status.rpt" \
        "$RUN_REPLAY|$DIAGNOSTIC_ROOT/run_evidence/replay_contract_status.rpt" \
        "$RUN_ISOLATION|$DIAGNOSTIC_ROOT/run_evidence/output_isolation.rpt" \
        "$RUN_REFERENCES|$DIAGNOSTIC_ROOT/run_evidence/external_references.rpt" \
        "$RUN_DEFINES|$DIAGNOSTIC_ROOT/run_evidence/preprocessor_defines.rpt" \
        "$RUN_DIR/pvs_result_evidence_inventory.rpt|$DIAGNOSTIC_ROOT/run_evidence/pvs_result_evidence_inventory.rpt" \
        "$RUN_DIR/SHA256SUMS|$DIAGNOSTIC_ROOT/run_evidence/SHA256SUMS"
    do
        SOURCE_FILE="${SPEC%%|*}"
        DESTINATION_FILE="${SPEC#*|}"
        if [ -f "$SOURCE_FILE" ]; then
            cp -p "$SOURCE_FILE" "$DESTINATION_FILE"
            [ "$?" -eq 0 ] || DIAGNOSTIC_COPY_GATE_RC=1
        elif [ "$OUTCOME_CLASS" = "ATTRIBUTABLE_MATCH" ] || \
             [ "$OUTCOME_CLASS" = "ATTRIBUTABLE_MISMATCH" ]; then
            echo "MISSING_DIAGNOSTIC_SOURCE=$SOURCE_FILE"
            DIAGNOSTIC_COPY_GATE_RC=1
        fi
    done
    echo "DIAGNOSTIC_COPY_GATE_RC=$DIAGNOSTIC_COPY_GATE_RC"
fi

if [ "$DIAGNOSTIC_ROOT" != "UNKNOWN" ]; then
    (
        if cd "$DENSITY_DRC_ROOT"; then
            sha256sum -c SHA256SUMS
        else
            false
        fi
    ) >"$DIAGNOSTIC_ROOT/source_density_drc/SHA256SUMS.post_execution_check.rpt" 2>&1
    SOURCE_POST_RECHECK_RC=$?

    for SPEC in \
        "$DENSITY_STATUS|$EXPECTED_DENSITY_STATUS_SHA" \
        "$DENSITY_RUN_STATUS|$EXPECTED_DENSITY_RUN_SHA" \
        "$DENSITY_REPLAY|$EXPECTED_DENSITY_REPLAY_SHA" \
        "$DENSITY_ISOLATION|$EXPECTED_DENSITY_ISOLATION_SHA" \
        "$DENSITY_DEFINES|$EXPECTED_DENSITY_DEFINES_SHA" \
        "$DENSITY_REFERENCES|$EXPECTED_DENSITY_REFERENCES_SHA" \
        "$DENSITY_ANALYSIS|$EXPECTED_DENSITY_ANALYSIS_SHA" \
        "$DENSITY_INVENTORY|$EXPECTED_DENSITY_INVENTORY_SHA" \
        "$LVS_TEMPLATE/.config.rul|$EXPECTED_TEMPLATE_CONFIG_SHA" \
        "$LVS_TEMPLATE/.preset.autosave|$EXPECTED_TEMPLATE_PRESET_SHA" \
        "$LVS_TEMPLATE/.technology.rul|$EXPECTED_TEMPLATE_TECHNOLOGY_SHA" \
        "$LVS_TEMPLATE/pipo1.setup|$EXPECTED_TEMPLATE_PIPO1_SHA" \
        "$LVS_TEMPLATE/pvslvsctl|$EXPECTED_TEMPLATE_CONTROL_SHA" \
        "$LVS_TEMPLATE/run.pvs|$EXPECTED_TEMPLATE_RUN_SHA" \
        "$PVS_BIN|e2a50b5eb73539f78adb042ede0613c8ef9be3d9e2ed4a453a3c9266bcae3f15" \
        "$STREAM_LAYER_TABLE|3198c31b841a29b1126206f7962632fd7f6dc239c53931962cd57327d2320869" \
        "$STREAM_OBJECT_MAP|151695165c1679190e1f95aa0ccb854de233c7a7e3f589a5ac83c93c0c487c7c" \
        "$PVTECH_LIB|1fe31de76c4b1c0d69afe6bdb31ccad89dd1f43429697f5043c57d4547a93bef" \
        "$LVS_RULE|30c5b47434035ca4b9540f2f333fc2506a063f0b3dfc05f49de72c3a60c755f0"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_SHA="${SPEC#*|}"
        ACTUAL_SHA="$(sha256sum "$FILE" 2>/dev/null | awk '{print $1}')"
        if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
            echo "SOURCE_POST_RECHECK_MISMATCH=$FILE"
            SOURCE_POST_RECHECK_RC=1
        fi
    done

    (
        if cd "$PACKAGE"; then
            sha256sum -c manifests/SHA256SUMS
        else
            false
        fi
    ) >"$DIAGNOSTIC_ROOT/package_sha256_post_execution.rpt" 2>&1
    PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC=$?
    for SPEC in \
        "$PACKAGE_GDS|$EXPECTED_GDS_SHA" \
        "$PACKAGE_SOURCE|$EXPECTED_SOURCE_SHA" \
        "$PACKAGE_CDL|$EXPECTED_CDL_SHA"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_SHA="${SPEC#*|}"
        ACTUAL_SHA="$(sha256sum "$FILE" 2>/dev/null | awk '{print $1}')"
        [ "$ACTUAL_SHA" = "$EXPECTED_SHA" ] || PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC=1
    done
    echo "SOURCE_POST_RECHECK_RC=$SOURCE_POST_RECHECK_RC"
    echo "PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC=$PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC"
fi

if [ "$OUTCOME_CLASS" = "ATTRIBUTABLE_MATCH" ] && \
   [ "$DIAGNOSTIC_COPY_GATE_RC" = "0" ] && \
   [ "$SOURCE_POST_RECHECK_RC" = "0" ] && \
   [ "$PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC" = "0" ]; then
    TRANSACTION_STATUS=PASS
    TRANSACTION_RESULT=PVS_EXACT_GDS_LVS_MATCH_RECORDED
    NEXT_GATE=START_EVENT_OOC_AND_REVIEW_POSITION_DENSITY_DISPOSITION
elif [ "$OUTCOME_CLASS" = "ATTRIBUTABLE_MISMATCH" ] && \
     [ "$DIAGNOSTIC_COPY_GATE_RC" = "0" ] && \
     [ "$SOURCE_POST_RECHECK_RC" = "0" ] && \
     [ "$PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC" = "0" ]; then
    TRANSACTION_STATUS=PASS
    TRANSACTION_RESULT=PVS_EXACT_GDS_LVS_MISMATCH_RECORDED
    NEXT_GATE=CLASSIFY_POSITION_LVS_MISMATCH_NO_RERUN
elif [ "$PVS_EXECUTED" = "YES" ]; then
    TRANSACTION_RESULT=PVS_EXACT_GDS_LVS_INFRASTRUCTURE_OR_RESULT_CLASSIFICATION_FAILED
fi

if [ "$DIAGNOSTIC_ROOT" != "UNKNOWN" ]; then
    STATUS_REPORT="$DIAGNOSTIC_ROOT/position_pvs_lvs_execution_status.rpt"
    {
        echo "LABEL=SPADMIC_POSITION_PVS_LVS_EXECUTION"
        echo "STATUS=$TRANSACTION_STATUS"
        echo "RESULT=$TRANSACTION_RESULT"
        echo "SOURCE_DENSITY_DRC_ROOT=$DENSITY_DRC_ROOT"
        echo "SOURCE_DENSITY_DRC_STATUS_SHA256=$EXPECTED_DENSITY_STATUS_SHA"
        echo "MANUAL_REVIEW_DECISION=AUTHORIZE_ONE_FOREGROUND_EXACT_GDS_PVS_LVS"
        echo "CROSS_BLOCK_TEMPLATE_REUSE_SCOPE=CONTROL_SCAFFOLD_ONLY"
        echo "TEMPLATE_BASELINE_ID=$TEMPLATE_BASELINE_ID"
        echo "TEMPLATE_CONTROL_SOURCE_MUTATION_AUTHORIZED=NO"
        echo "TEMPLATE_IDENTITY_GATE_RC=$TEMPLATE_IDENTITY_GATE_RC"
        echo "TEMPLATE_SEMANTIC_GATE_RC=$TEMPLATE_SEMANTIC_GATE_RC"
        echo "TEMPLATE_SCAFFOLD_AUDIT=$TEMPLATE_AUDIT"
        echo "TEMPLATE_LAYOUT_TOP=$TEMPLATE_LAYOUT_TOP"
        echo "TEMPLATE_SOURCE_TOP=$TEMPLATE_SOURCE_TOP"
        echo "TEMPLATE_GDS=$TEMPLATE_GDS"
        echo "TEMPLATE_SOURCE=$TEMPLATE_SOURCE"
        echo "PACKAGE=$PACKAGE"
        echo "PACKAGE_GDS=$PACKAGE_GDS"
        echo "PACKAGE_GDS_SHA256=$EXPECTED_GDS_SHA"
        echo "CANONICAL_LVS_SOURCE=$PACKAGE_SOURCE"
        echo "CANONICAL_LVS_SOURCE_SHA256=$EXPECTED_SOURCE_SHA"
        echo "STDCELL_CDL=$PACKAGE_CDL"
        echo "STDCELL_CDL_SHA256=$EXPECTED_CDL_SHA"
        echo "LAYOUT_TOP=$POSITION_TOP"
        echo "SOURCE_TOP=$POSITION_TOP"
        echo "RUN_DIR=$RUN_DIR"
        echo "OUTCOME_CLASS=$OUTCOME_CLASS"
        echo "PVS_WRAPPER_RC=$PVS_WRAPPER_RC"
        echo "PVS_TOOL_RC=$PVS_TOOL_RC"
        echo "PVS_BASE_DRC_STATUS=PASS"
        echo "PVS_DENSITY_DRC_STATUS=FAIL"
        echo "PVS_DENSITY_DRC_PRIMARY_RESULTS=4"
        echo "PVS_DENSITY_DRC_EXPANDED_RESULTS=4"
        echo "DENSITY_DEBT_CLASS=OOC_WHOLE_EXTENT_MINIMUM_COVERAGE"
        echo "DENSITY_DISPOSITION_STATUS=REVIEW_REQUIRED_FOR_ASSEMBLED_FILL_OR_FORMAL_WAIVER"
        echo "PVS_LVS_STATUS=$PVS_LVS_STATUS"
        echo "LVS_NEGATIVE_MATCH_COUNT=$LVS_NEGATIVE_MATCH_COUNT"
        echo "LVS_POSITIVE_MATCH_COUNT=$LVS_POSITIVE_MATCH_COUNT"
        echo "PVS_RESULT_EVIDENCE=$PVS_EVIDENCE"
        echo "REPLAY_CONTRACT_STATUS=$REPLAY_CONTRACT_STATUS"
        echo "OUTPUT_ISOLATION_STATUS=$OUTPUT_ISOLATION_STATUS"
        echo "RUN_FILE_GATE_RC=$RUN_FILE_GATE_RC"
        echo "RUN_AUDIT_GATE_RC=$RUN_AUDIT_GATE_RC"
        echo "RUN_MANIFEST_RC=$RUN_MANIFEST_RC"
        echo "DIAGNOSTIC_COPY_GATE_RC=$DIAGNOSTIC_COPY_GATE_RC"
        echo "SOURCE_POST_RECHECK_RC=$SOURCE_POST_RECHECK_RC"
        echo "PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC=$PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC"
        echo "PVS_BASE_DRC_EXECUTION_AUTHORIZED=NO"
        echo "PVS_DENSITY_DRC_EXECUTION_AUTHORIZED=NO"
        echo "PVS_LVS_EXECUTION_AUTHORIZED=$PVS_LVS_EXECUTION_AUTHORIZED"
        echo "PVS_REPLAY_AUTHORIZED=$PVS_REPLAY_AUTHORIZED"
        echo "PVS_EXECUTED=$PVS_EXECUTED"
        echo "BLOCK_PROMOTION_AUTHORIZED=NO"
        echo "SIGNOFF_READY=NO"
        echo "NEXT_GATE=$NEXT_GATE"
    } | tee "$STATUS_REPORT"

    (
        if cd "$DIAGNOSTIC_ROOT"; then
            find . -type f ! -name SHA256SUMS -print0 \
                | sort -z | xargs -0 sha256sum
        else
            false
        fi
    ) >"$DIAGNOSTIC_ROOT/SHA256SUMS"
    DIAGNOSTIC_MANIFEST_CREATE_RC=$?
    echo "DIAGNOSTIC_MANIFEST_CREATE_RC=$DIAGNOSTIC_MANIFEST_CREATE_RC"

    echo
    echo "===== POSITION EXACT-GDS PVS LVS EXECUTION STATUS ====="
    cat "$STATUS_REPORT"
    if [ -r "$RUN_STATUS" ]; then
        echo
        echo "===== RAW PVS LVS STATUS ====="
        cat "$RUN_STATUS"
    fi
fi

if [ "$TRANSACTION_STATUS" = "PASS" ] && \
   [ "${DIAGNOSTIC_MANIFEST_CREATE_RC:-1}" = "0" ]; then
    true
else
    false
fi
