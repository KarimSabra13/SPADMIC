#!/usr/bin/env bash
# Execute and classify one attributable Position density PVS DRC run.

set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
EXPECTED_HEAD="${1:-MISSING}"
BASE_DRC_ROOT="${2:-MISSING}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"

PACKAGE="$WORK_ROOT/handoff/innovus/blocks/spadmic_position_core/innovus_ooc_harden_position_core_gridfit_20260717_114810"
PACKAGE_GDS="$PACKAGE/gds/spadmic_position_core.gds"
EXPECTED_GDS_SHA=ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1
POSITION_TOP=spadmic_position_core

PRIMARY_SEED=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/layoutverification/pvs_drc/spadmic_tx_packet_core
PRIMARY_SEED_GDS="$PRIMARY_SEED/spadmic_tx_packet_core.gds"
PRIMARY_SEED_TOP=spadmic_tx_packet_core

EXPECTED_BASE_EXECUTION_STATUS_SHA=dd6ddf67f0c6750109eaa1f9e9915bb3cd25b1c201de43167f26dd620ee8dc00
EXPECTED_BASE_RUN_STATUS_SHA=7d34c9135caf7fccd5d53e803794bb87a53b461bbdfabfb6f9752595c59129c4
EXPECTED_BASE_REPLAY_SHA=81dd3cc0ed5231179242b4a9af59672ec3eb23e0b6748ac25dc7b1b9f8346115
EXPECTED_BASE_ISOLATION_SHA=3710cd3af7975f3e10617f519ad03165f8c76ce747e57033a9f8523e634fb7c8
EXPECTED_BASE_DEFINES_SHA=1f8ef07f31201a170d0f770d26596c031821f4c72d58b3ab4517b90f4f837dfa
EXPECTED_BASE_REFERENCES_SHA=44f77c9f4bcf74665edd21bbd41fd315183156791124c2b898724e173092250a

PVS_BIN=/eda/cadence/2023-24/RHELx86/PVS_22.22.000/bin/pvs
STREAM_LAYER_TABLE=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/.xkit/setup/xh018/cadence/PDK/TECH_XH018_1131/strmInOut.layertable
STREAM_OBJECT_MAP=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/.xkit/setup/xh018/cadence/PDK/TECH_XH018_1131/strmOutObjects.map
PVTECH_LIB=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/pvtech.lib

RUN_OK=1
CD_RC=NOT_RUN
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
DIAGNOSTIC_ROOT=UNKNOWN
DIAGNOSTIC_CREATE_RC=NOT_RUN
BASE_FILE_GATE_RC=NOT_RUN
BASE_HASH_GATE_RC=NOT_RUN
BASE_MANIFEST_RC=NOT_RUN
BASE_STATUS_GATE_RC=NOT_RUN
PACKAGE_GATE_RC=NOT_RUN
PACKAGE_SHA_MANIFEST_RC=NOT_RUN
SEED_FILE_GATE_RC=NOT_RUN
SEED_IDENTITY_GATE_RC=NOT_RUN
SOURCE_REFERENCE_GATE_RC=NOT_RUN
PVS_WRAPPER_RC=NOT_RUN
RUN_DIR=UNKNOWN
RUN_FILE_GATE_RC=NOT_RUN
RUN_AUDIT_GATE_RC=NOT_RUN
RUN_MANIFEST_RC=NOT_RUN
SOURCE_POST_RECHECK_RC=NOT_RUN
PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC=NOT_RUN
RULE_ANALYSIS_RC=NOT_RUN
RULE_ANALYSIS_STATUS=NOT_RUN
DIAGNOSTIC_COPY_GATE_RC=NOT_RUN
PVS_TOOL_RC=UNKNOWN
PVS_DENSITY_DRC_STATUS=UNKNOWN
DRC_TOTAL_PRIMARY=UNKNOWN
DRC_TOTAL_EXPANDED=UNKNOWN
DRC_TOTAL_MATCH_COUNT=UNKNOWN
PVS_EVIDENCE=UNKNOWN
REPLAY_CONTRACT_STATUS=UNKNOWN
OUTPUT_ISOLATION_STATUS=UNKNOWN
PVS_DENSITY_DRC_EXECUTION_AUTHORIZED=NO
PVS_REPLAY_AUTHORIZED=NO
PVS_EXECUTED=NO
OUTCOME_CLASS=NOT_CLASSIFIED
TRANSACTION_STATUS=FAIL
TRANSACTION_RESULT=DENSITY_PVS_DRC_NOT_EXECUTED
NEXT_GATE=STOP_AND_REVIEW_DENSITY_PVS_EXECUTION_FAILURE

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

if [ "$BASE_DRC_ROOT" = "MISSING" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: successful base-DRC diagnostic root missing"
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
    DIAGNOSTIC_ROOT="$WORK_ROOT/diagnostics/position_pvs_drc_density_execution_$EXECUTION_STAMP"
    RUN_ID="position_density_drc_$EXECUTION_STAMP"
    RUN_DIR="$PACKAGE/pvs/drc/$RUN_ID"
    if [ -e "$DIAGNOSTIC_ROOT" ] || [ -e "$RUN_DIR" ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: fresh execution path already exists"
        DIAGNOSTIC_CREATE_RC=1
    else
        mkdir -p "$DIAGNOSTIC_ROOT/source_base_drc" "$DIAGNOSTIC_ROOT/run_evidence"
        DIAGNOSTIC_CREATE_RC=$?
    fi
    echo "DIAGNOSTIC_ROOT=$DIAGNOSTIC_ROOT"
    echo "RUN_DIR=$RUN_DIR"
    echo "DIAGNOSTIC_CREATE_RC=$DIAGNOSTIC_CREATE_RC"
    if [ "$DIAGNOSTIC_CREATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: density-execution diagnostic creation failed"
        DIAGNOSTIC_ROOT=UNKNOWN
        RUN_DIR=UNKNOWN
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    BASE_EXECUTION_STATUS="$BASE_DRC_ROOT/position_pvs_drc_base_execution_status.rpt"
    BASE_RUN_STATUS="$BASE_DRC_ROOT/run_evidence/pvs_drc_status.rpt"
    BASE_REPLAY="$BASE_DRC_ROOT/run_evidence/replay_contract_status.rpt"
    BASE_ISOLATION="$BASE_DRC_ROOT/run_evidence/output_isolation.rpt"
    BASE_DEFINES="$BASE_DRC_ROOT/run_evidence/preprocessor_defines.rpt"
    BASE_REFERENCES="$BASE_DRC_ROOT/run_evidence/external_references.rpt"

    BASE_FILE_GATE_RC=0
    for FILE in \
        "$BASE_EXECUTION_STATUS" \
        "$BASE_RUN_STATUS" \
        "$BASE_REPLAY" \
        "$BASE_ISOLATION" \
        "$BASE_DEFINES" \
        "$BASE_REFERENCES" \
        "$BASE_DRC_ROOT/SHA256SUMS"
    do
        if [ ! -s "$FILE" ]; then
            echo "MISSING_OR_EMPTY=$FILE"
            BASE_FILE_GATE_RC=1
        fi
    done
    echo "BASE_FILE_GATE_RC=$BASE_FILE_GATE_RC"
    if [ "$BASE_FILE_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: successful base-DRC evidence is incomplete"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    BASE_HASH_GATE_RC=0
    for SPEC in \
        "$BASE_EXECUTION_STATUS|$EXPECTED_BASE_EXECUTION_STATUS_SHA" \
        "$BASE_RUN_STATUS|$EXPECTED_BASE_RUN_STATUS_SHA" \
        "$BASE_REPLAY|$EXPECTED_BASE_REPLAY_SHA" \
        "$BASE_ISOLATION|$EXPECTED_BASE_ISOLATION_SHA" \
        "$BASE_DEFINES|$EXPECTED_BASE_DEFINES_SHA" \
        "$BASE_REFERENCES|$EXPECTED_BASE_REFERENCES_SHA"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_SHA="${SPEC#*|}"
        ACTUAL_SHA="$(sha256sum "$FILE" | awk '{print $1}')"
        echo "BASE_FILE=$FILE"
        echo "BASE_EXPECTED_SHA256=$EXPECTED_SHA"
        echo "BASE_ACTUAL_SHA256=$ACTUAL_SHA"
        if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
            BASE_HASH_GATE_RC=1
        fi
    done
    echo "BASE_HASH_GATE_RC=$BASE_HASH_GATE_RC"
    if [ "$BASE_HASH_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: successful base-DRC evidence changed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    (
        if cd "$BASE_DRC_ROOT"; then
            sha256sum -c SHA256SUMS
        else
            false
        fi
    ) >"$DIAGNOSTIC_ROOT/source_base_drc/SHA256SUMS.check.rpt" 2>&1
    BASE_MANIFEST_RC=$?
    echo "BASE_MANIFEST_RC=$BASE_MANIFEST_RC"
    if [ "$BASE_MANIFEST_RC" -ne 0 ]; then
        cat "$DIAGNOSTIC_ROOT/source_base_drc/SHA256SUMS.check.rpt"
        echo "STOP_HERE_DO_NOT_CONTINUE: base-DRC diagnostic manifest failed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    BASE_STATUS_GATE_RC=0
    for SPEC in \
        "$BASE_EXECUTION_STATUS|STATUS=PASS" \
        "$BASE_EXECUTION_STATUS|RESULT=PVS_BASE_DRC_ZERO_RESULTS_RECORDED" \
        "$BASE_EXECUTION_STATUS|PACKAGE_GDS_SHA256=$EXPECTED_GDS_SHA" \
        "$BASE_EXECUTION_STATUS|POSITION_TOP=$POSITION_TOP" \
        "$BASE_EXECUTION_STATUS|OUTCOME_CLASS=ATTRIBUTABLE_ZERO_RESULTS" \
        "$BASE_EXECUTION_STATUS|PVS_WRAPPER_RC=0" \
        "$BASE_EXECUTION_STATUS|PVS_TOOL_RC=0" \
        "$BASE_EXECUTION_STATUS|PVS_BASE_DRC_STATUS=PASS" \
        "$BASE_EXECUTION_STATUS|DRC_TOTAL_PRIMARY=0" \
        "$BASE_EXECUTION_STATUS|DRC_TOTAL_EXPANDED=0" \
        "$BASE_EXECUTION_STATUS|REPLAY_CONTRACT_STATUS=PASS" \
        "$BASE_EXECUTION_STATUS|OUTPUT_ISOLATION_STATUS=PASS" \
        "$BASE_EXECUTION_STATUS|RUN_FILE_GATE_RC=0" \
        "$BASE_EXECUTION_STATUS|RUN_AUDIT_GATE_RC=0" \
        "$BASE_EXECUTION_STATUS|RUN_MANIFEST_RC=0" \
        "$BASE_EXECUTION_STATUS|RULE_ANALYSIS_STATUS=NOT_APPLICABLE_ZERO_RESULTS" \
        "$BASE_EXECUTION_STATUS|DIAGNOSTIC_COPY_GATE_RC=0" \
        "$BASE_EXECUTION_STATUS|SOURCE_POST_RECHECK_RC=0" \
        "$BASE_EXECUTION_STATUS|PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC=0" \
        "$BASE_EXECUTION_STATUS|PVS_EXECUTED=YES" \
        "$BASE_EXECUTION_STATUS|PVS_DENSITY_DRC_STATUS=NOT_RUN" \
        "$BASE_EXECUTION_STATUS|NEXT_GATE=FOREGROUND_DENSITY_PVS_DRC" \
        "$BASE_RUN_STATUS|PVS_RC=0" \
        "$BASE_RUN_STATUS|PVS_DRC_STATUS=PASS" \
        "$BASE_RUN_STATUS|DRC_TOTAL_PRIMARY=0" \
        "$BASE_RUN_STATUS|DRC_TOTAL_EXPANDED=0" \
        "$BASE_RUN_STATUS|PVS_DRC_VARIANT=BASE" \
        "$BASE_RUN_STATUS|GDS_SHA256=$EXPECTED_GDS_SHA" \
        "$BASE_REPLAY|STATUS=PASS" \
        "$BASE_REPLAY|EXECUTION_DIRECTORY_STATUS=PASS" \
        "$BASE_REPLAY|OUTPUT_ISOLATION_STATUS=PASS" \
        "$BASE_REPLAY|LAYOUT_TOP=$POSITION_TOP" \
        "$BASE_ISOLATION|STATUS=PASS" \
        "$BASE_DEFINES|UNDEFINE=DENSITY|OCCURRENCES=1"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_LINE="${SPEC#*|}"
        grep -Fxq -- "$EXPECTED_LINE" "$FILE"
        LINE_RC=$?
        echo "BASE_STATUS_LINE_RC=$LINE_RC FILE=$FILE EXPECTED=$EXPECTED_LINE"
        [ "$LINE_RC" -eq 0 ] || BASE_STATUS_GATE_RC=1
    done
    grep -q '^MISSING=' "$BASE_REFERENCES"
    [ "$?" -ne 0 ] || BASE_STATUS_GATE_RC=1
    echo "BASE_STATUS_GATE_RC=$BASE_STATUS_GATE_RC"
    if [ "$BASE_STATUS_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: base result does not authorize density execution"
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
    (
        if cd "$PACKAGE"; then
            sha256sum -c manifests/SHA256SUMS
        else
            false
        fi
    ) >"$DIAGNOSTIC_ROOT/package_sha256_check.rpt" 2>&1
    PACKAGE_SHA_MANIFEST_RC=$?
    echo "PACKAGE_SHA_MANIFEST_RC=$PACKAGE_SHA_MANIFEST_RC"
    if [ "$PACKAGE_SHA_MANIFEST_RC" -ne 0 ]; then
        cat "$DIAGNOSTIC_ROOT/package_sha256_check.rpt"
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
        [ "$ACTUAL_SHA" = "$EXPECTED_SHA" ] || SEED_IDENTITY_GATE_RC=1
    done
    echo "SEED_IDENTITY_GATE_RC=$SEED_IDENTITY_GATE_RC"
    if [ "$SEED_IDENTITY_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: authorized seed scaffold changed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    SOURCE_REFERENCE_GATE_RC=0
    for SPEC in \
        "$PVS_BIN|e2a50b5eb73539f78adb042ede0613c8ef9be3d9e2ed4a453a3c9266bcae3f15" \
        "$STREAM_LAYER_TABLE|3198c31b841a29b1126206f7962632fd7f6dc239c53931962cd57327d2320869" \
        "$STREAM_OBJECT_MAP|151695165c1679190e1f95aa0ccb854de233c7a7e3f589a5ac83c93c0c487c7c" \
        "$PVTECH_LIB|1fe31de76c4b1c0d69afe6bdb31ccad89dd1f43429697f5043c57d4547a93bef"
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
    if [ "$SOURCE_REFERENCE_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: pinned external reference changed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    echo "MANUAL_REVIEW_DECISION=AUTHORIZE_ONE_FOREGROUND_DENSITY_PVS_DRC"
    PVS_DENSITY_DRC_EXECUTION_AUTHORIZED=YES
    PVS_REPLAY_AUTHORIZED=YES
    EXPECTED_HEAD="$EXPECTED_HEAD" \
    bash TOP/pnr/scripts/run_pvs_drc_handoff.sh \
        --package "$PACKAGE" \
        --template "$PRIMARY_SEED" \
        --template-gds "$PRIMARY_SEED_GDS" \
        --template-top "$PRIMARY_SEED_TOP" \
        --variant density \
        --run-id "$RUN_ID" \
        --allow-cross-block-control-scaffold \
        2>&1 | tee "$DIAGNOSTIC_ROOT/pvs_density.console.log"
    PVS_WRAPPER_RC=${PIPESTATUS[0]}
    echo "PVS_WRAPPER_RC=$PVS_WRAPPER_RC"
fi

RUN_STATUS="$RUN_DIR/pvs_drc_status.rpt"
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
        "$RUN_DIR/pvsdrcctl" \
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
    PVS_DENSITY_DRC_STATUS="$(kv_field "$RUN_STATUS" PVS_DRC_STATUS)"
    DRC_TOTAL_PRIMARY="$(kv_field "$RUN_STATUS" DRC_TOTAL_PRIMARY)"
    DRC_TOTAL_EXPANDED="$(kv_field "$RUN_STATUS" DRC_TOTAL_EXPANDED)"
    DRC_TOTAL_MATCH_COUNT="$(kv_field "$RUN_STATUS" DRC_TOTAL_MATCH_COUNT)"
    PVS_EVIDENCE="$(kv_field "$RUN_STATUS" EVIDENCE)"
    REPLAY_CONTRACT_STATUS="$(kv_field "$RUN_REPLAY" STATUS)"
    OUTPUT_ISOLATION_STATUS="$(kv_field "$RUN_ISOLATION" STATUS)"
    if is_uint "$PVS_TOOL_RC"; then
        PVS_EXECUTED=YES
    fi

    RUN_AUDIT_GATE_RC=0
    for SPEC in \
        "$RUN_STATUS|LABEL=SPADMIC_PVS_HANDOFF_RESULT" \
        "$RUN_STATUS|MODE=DRC" \
        "$RUN_STATUS|PVS_DRC_VARIANT=DENSITY" \
        "$RUN_STATUS|CROSS_BLOCK_CONTROL_SCAFFOLD_AUTHORIZED=YES" \
        "$RUN_STATUS|PACKAGE=$PACKAGE" \
        "$RUN_STATUS|GDS=$PACKAGE_GDS" \
        "$RUN_STATUS|GDS_SHA256=$EXPECTED_GDS_SHA" \
        "$RUN_REPLAY|STATUS=PASS" \
        "$RUN_REPLAY|MODE=DRC" \
        "$RUN_REPLAY|EXECUTION_DIRECTORY_STATUS=PASS" \
        "$RUN_REPLAY|OUTPUT_ISOLATION_STATUS=PASS" \
        "$RUN_REPLAY|LAYOUT_TOP=$POSITION_TOP" \
        "$RUN_ISOLATION|STATUS=PASS" \
        "$RUN_ISOLATION|MODE=DRC" \
        "$RUN_DEFINES|DEFINE=DENSITY|OCCURRENCES=1"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_LINE="${SPEC#*|}"
        grep -Fxq -- "$EXPECTED_LINE" "$FILE"
        [ "$?" -eq 0 ] || RUN_AUDIT_GATE_RC=1
    done
    for DIRECTIVE in \
        "#DEFINE DENSITY" \
        "#UNDEFINE POPPING" \
        "#UNDEFINE PIMIDE" \
        "#UNDEFINE DUMMY_FILL" \
        "#DEFINE VAR_ANT_RATIO"
    do
        grep -Fxq -- "$DIRECTIVE" "$RUN_DIR/pvsdrcctl"
        [ "$?" -eq 0 ] || RUN_AUDIT_GATE_RC=1
    done
    grep -q '^MISSING=' "$RUN_REFERENCES"
    [ "$?" -ne 0 ] || RUN_AUDIT_GATE_RC=1
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
   is_uint "$DRC_TOTAL_PRIMARY" && \
   is_uint "$DRC_TOTAL_EXPANDED" && \
   is_uint "$DRC_TOTAL_MATCH_COUNT" && \
   [ "$DRC_TOTAL_MATCH_COUNT" -gt 0 ]; then

    case "$PVS_EVIDENCE" in
        *"Total DRC Results=$DRC_TOTAL_PRIMARY($DRC_TOTAL_EXPANDED)"*)
            EVIDENCE_TOTAL_STATUS=PASS
            ;;
        *)
            EVIDENCE_TOTAL_STATUS=FAIL
            ;;
    esac

    if [ "$PVS_WRAPPER_RC" = "0" ] && \
       [ "$PVS_DENSITY_DRC_STATUS" = "PASS" ] && \
       [ "$DRC_TOTAL_PRIMARY" -eq 0 ] && \
       [ "$DRC_TOTAL_EXPANDED" -eq 0 ] && \
       [ "$EVIDENCE_TOTAL_STATUS" = "PASS" ]; then
        OUTCOME_CLASS=ATTRIBUTABLE_ZERO_RESULTS
    elif [ "$PVS_WRAPPER_RC" = "8" ] && \
         [ "$PVS_DENSITY_DRC_STATUS" = "FAIL" ] && \
         { [ "$DRC_TOTAL_PRIMARY" -gt 0 ] || [ "$DRC_TOTAL_EXPANDED" -gt 0 ]; } && \
         [ "$EVIDENCE_TOTAL_STATUS" = "PASS" ]; then
        OUTCOME_CLASS=ATTRIBUTABLE_NONZERO_RESULTS
    fi
fi

echo "PVS_TOOL_RC=$PVS_TOOL_RC"
echo "PVS_DENSITY_DRC_STATUS=$PVS_DENSITY_DRC_STATUS"
echo "DRC_TOTAL_PRIMARY=$DRC_TOTAL_PRIMARY"
echo "DRC_TOTAL_EXPANDED=$DRC_TOTAL_EXPANDED"
echo "OUTCOME_CLASS=$OUTCOME_CLASS"

if [ "$OUTCOME_CLASS" = "ATTRIBUTABLE_NONZERO_RESULTS" ]; then
    python3 TOP/pnr/scripts/analyze_pvs_drc_run.py \
        --run-dir "$RUN_DIR" \
        --output-dir "$DIAGNOSTIC_ROOT/rule_analysis" \
        --expected-primary "$DRC_TOTAL_PRIMARY" \
        --expected-expanded "$DRC_TOTAL_EXPANDED" \
        --expected-variant density \
        >"$DIAGNOSTIC_ROOT/rule_analysis.console.log" 2>&1
    RULE_ANALYSIS_RC=$?
    ANALYSIS_STATUS_REPORT="$DIAGNOSTIC_ROOT/rule_analysis/pvs_drc_analysis_status.rpt"
    RULE_ANALYSIS_STATUS="$(kv_field "$ANALYSIS_STATUS_REPORT" STATUS)"
    ANALYSIS_GATE_RC=0
    for EXPECTED_LINE in \
        "STATUS=PASS" \
        "RESULT=PVS_DRC_RULE_DEBT_CLASSIFIED" \
        "REPLAY_CONTRACT_STATUS=PASS" \
        "OUTPUT_ISOLATION_STATUS=PASS" \
        "PVS_RC=0" \
        "PVS_DRC_STATUS=FAIL" \
        "PVS_DRC_VARIANT=DENSITY" \
        "LAYOUT_TOP=$POSITION_TOP" \
        "DRC_TOTAL_PRIMARY=$DRC_TOTAL_PRIMARY" \
        "DRC_TOTAL_EXPANDED=$DRC_TOTAL_EXPANDED" \
        "RESULT_COUNT_RECONCILIATION=PASS" \
        "ASCII_ERROR_GEOMETRY_RECONCILIATION=PASS" \
        "DENSITY_STATE=DEFINED" \
        "PVS_BASE_DRC_STATUS=UNCHANGED_SEPARATE_GATE" \
        "PVS_DENSITY_DRC_STATUS=FAIL" \
        "FINAL_SIGNOFF_READY=NO" \
        "BLOCK_PROMOTION_AUTHORIZED=NO"
    do
        grep -Fxq -- "$EXPECTED_LINE" "$ANALYSIS_STATUS_REPORT" 2>/dev/null
        [ "$?" -eq 0 ] || ANALYSIS_GATE_RC=1
    done
    if [ "$RULE_ANALYSIS_RC" -ne 0 ] || [ "$ANALYSIS_GATE_RC" -ne 0 ]; then
        RULE_ANALYSIS_STATUS=FAIL
    fi
    echo "RULE_ANALYSIS_RC=$RULE_ANALYSIS_RC"
    echo "RULE_ANALYSIS_STATUS=$RULE_ANALYSIS_STATUS"
elif [ "$OUTCOME_CLASS" = "ATTRIBUTABLE_ZERO_RESULTS" ]; then
    RULE_ANALYSIS_RC=NOT_APPLICABLE
    RULE_ANALYSIS_STATUS=NOT_APPLICABLE_ZERO_RESULTS
fi

if [ "$DIAGNOSTIC_ROOT" != "UNKNOWN" ]; then
    DIAGNOSTIC_COPY_GATE_RC=0
    for SPEC in \
        "$BASE_EXECUTION_STATUS|$DIAGNOSTIC_ROOT/source_base_drc/position_pvs_drc_base_execution_status.rpt" \
        "$BASE_RUN_STATUS|$DIAGNOSTIC_ROOT/source_base_drc/pvs_drc_status.rpt" \
        "$BASE_REPLAY|$DIAGNOSTIC_ROOT/source_base_drc/replay_contract_status.rpt" \
        "$BASE_ISOLATION|$DIAGNOSTIC_ROOT/source_base_drc/output_isolation.rpt" \
        "$BASE_DEFINES|$DIAGNOSTIC_ROOT/source_base_drc/preprocessor_defines.rpt" \
        "$BASE_REFERENCES|$DIAGNOSTIC_ROOT/source_base_drc/external_references.rpt" \
        "$BASE_DRC_ROOT/SHA256SUMS|$DIAGNOSTIC_ROOT/source_base_drc/SHA256SUMS" \
        "$RUN_STATUS|$DIAGNOSTIC_ROOT/run_evidence/pvs_drc_status.rpt" \
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
        elif [ "$OUTCOME_CLASS" = "ATTRIBUTABLE_ZERO_RESULTS" ] || \
             [ "$OUTCOME_CLASS" = "ATTRIBUTABLE_NONZERO_RESULTS" ]; then
            echo "MISSING_DIAGNOSTIC_SOURCE=$SOURCE_FILE"
            DIAGNOSTIC_COPY_GATE_RC=1
        fi
    done
    echo "DIAGNOSTIC_COPY_GATE_RC=$DIAGNOSTIC_COPY_GATE_RC"
fi

if [ "$DIAGNOSTIC_ROOT" != "UNKNOWN" ]; then
    (
        if cd "$BASE_DRC_ROOT"; then
            sha256sum -c SHA256SUMS
        else
            false
        fi
    ) >"$DIAGNOSTIC_ROOT/source_base_drc/SHA256SUMS.post_execution_check.rpt" 2>&1
    SOURCE_POST_RECHECK_RC=$?

    for SPEC in \
        "$BASE_EXECUTION_STATUS|$EXPECTED_BASE_EXECUTION_STATUS_SHA" \
        "$BASE_RUN_STATUS|$EXPECTED_BASE_RUN_STATUS_SHA" \
        "$BASE_REPLAY|$EXPECTED_BASE_REPLAY_SHA" \
        "$BASE_ISOLATION|$EXPECTED_BASE_ISOLATION_SHA" \
        "$BASE_DEFINES|$EXPECTED_BASE_DEFINES_SHA" \
        "$BASE_REFERENCES|$EXPECTED_BASE_REFERENCES_SHA" \
        "$PRIMARY_SEED/.config.rul|e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" \
        "$PRIMARY_SEED/.preset.autosave|97b3a7e63c3e8a01ea1291a19de384e2c41f77cd11653a92c7f5618e73421000" \
        "$PRIMARY_SEED/.technology.rul|74a297facf6422635df2c58d79aa8b8ae46ca0b8232380471a88a182d8400ab6" \
        "$PRIMARY_SEED/cell_tree.txt|cb6844854e367a916909b7b31d3451d21805d09f46f3ba876b940d901dc695e4" \
        "$PRIMARY_SEED/pipo1.setup|949ce7ec915d1ddbd3e78534720c33aad9036d83932c6bac33730a113aba00dd" \
        "$PRIMARY_SEED/pvsdrcctl|b9a8451c6cc43647ec606ae706e450893e3673e22215dc5a64edeeb383b902ef" \
        "$PRIMARY_SEED/run.pvs|11ae3fc935041b8a4e0f3b406941c699c769ed1d50a504e8df36fcb544c7255a" \
        "$PVS_BIN|e2a50b5eb73539f78adb042ede0613c8ef9be3d9e2ed4a453a3c9266bcae3f15" \
        "$STREAM_LAYER_TABLE|3198c31b841a29b1126206f7962632fd7f6dc239c53931962cd57327d2320869" \
        "$STREAM_OBJECT_MAP|151695165c1679190e1f95aa0ccb854de233c7a7e3f589a5ac83c93c0c487c7c" \
        "$PVTECH_LIB|1fe31de76c4b1c0d69afe6bdb31ccad89dd1f43429697f5043c57d4547a93bef"
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
    POST_GDS_SHA="$(sha256sum "$PACKAGE_GDS" 2>/dev/null | awk '{print $1}')"
    if [ "$POST_GDS_SHA" != "$EXPECTED_GDS_SHA" ]; then
        PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC=1
    fi
    echo "SOURCE_POST_RECHECK_RC=$SOURCE_POST_RECHECK_RC"
    echo "PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC=$PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC"
fi

if [ "$OUTCOME_CLASS" = "ATTRIBUTABLE_ZERO_RESULTS" ] && \
   [ "$DIAGNOSTIC_COPY_GATE_RC" = "0" ] && \
   [ "$SOURCE_POST_RECHECK_RC" = "0" ] && \
   [ "$PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC" = "0" ]; then
    TRANSACTION_STATUS=PASS
    TRANSACTION_RESULT=PVS_DENSITY_DRC_ZERO_RESULTS_RECORDED
    NEXT_GATE=FOREGROUND_EXACT_GDS_PVS_LVS
elif [ "$OUTCOME_CLASS" = "ATTRIBUTABLE_NONZERO_RESULTS" ] && \
     [ "$RULE_ANALYSIS_RC" = "0" ] && \
     [ "$RULE_ANALYSIS_STATUS" = "PASS" ] && \
     [ "$DIAGNOSTIC_COPY_GATE_RC" = "0" ] && \
     [ "$SOURCE_POST_RECHECK_RC" = "0" ] && \
     [ "$PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC" = "0" ]; then
    TRANSACTION_STATUS=PASS
    TRANSACTION_RESULT=PVS_DENSITY_DRC_NONZERO_RULE_DEBT_CLASSIFIED
    NEXT_GATE=FOREGROUND_EXACT_GDS_PVS_LVS
elif [ "$OUTCOME_CLASS" = "ATTRIBUTABLE_NONZERO_RESULTS" ]; then
    TRANSACTION_RESULT=PVS_DENSITY_DRC_NONZERO_RULE_ANALYSIS_FAILED
    NEXT_GATE=STOP_AND_REVIEW_DENSITY_RULE_ANALYSIS_FAILURE
elif [ "$PVS_EXECUTED" = "YES" ]; then
    TRANSACTION_RESULT=PVS_DENSITY_DRC_INFRASTRUCTURE_OR_RESULT_CLASSIFICATION_FAILED
fi

if [ "$DIAGNOSTIC_ROOT" != "UNKNOWN" ]; then
    STATUS_REPORT="$DIAGNOSTIC_ROOT/position_pvs_drc_density_execution_status.rpt"
    {
        echo "LABEL=SPADMIC_POSITION_PVS_DENSITY_DRC_EXECUTION"
        echo "STATUS=$TRANSACTION_STATUS"
        echo "RESULT=$TRANSACTION_RESULT"
        echo "SOURCE_BASE_DRC_ROOT=$BASE_DRC_ROOT"
        echo "SOURCE_BASE_DRC_STATUS_SHA256=$EXPECTED_BASE_EXECUTION_STATUS_SHA"
        echo "MANUAL_REVIEW_DECISION=AUTHORIZE_ONE_FOREGROUND_DENSITY_PVS_DRC"
        echo "PACKAGE=$PACKAGE"
        echo "PACKAGE_GDS=$PACKAGE_GDS"
        echo "PACKAGE_GDS_SHA256=$EXPECTED_GDS_SHA"
        echo "POSITION_TOP=$POSITION_TOP"
        echo "RUN_DIR=$RUN_DIR"
        echo "OUTCOME_CLASS=$OUTCOME_CLASS"
        echo "PVS_WRAPPER_RC=$PVS_WRAPPER_RC"
        echo "PVS_TOOL_RC=$PVS_TOOL_RC"
        echo "PVS_BASE_DRC_STATUS=PASS"
        echo "PVS_DENSITY_DRC_STATUS=$PVS_DENSITY_DRC_STATUS"
        echo "DRC_TOTAL_PRIMARY=$DRC_TOTAL_PRIMARY"
        echo "DRC_TOTAL_EXPANDED=$DRC_TOTAL_EXPANDED"
        echo "DRC_TOTAL_MATCH_COUNT=$DRC_TOTAL_MATCH_COUNT"
        echo "PVS_RESULT_EVIDENCE=$PVS_EVIDENCE"
        echo "REPLAY_CONTRACT_STATUS=$REPLAY_CONTRACT_STATUS"
        echo "OUTPUT_ISOLATION_STATUS=$OUTPUT_ISOLATION_STATUS"
        echo "RUN_FILE_GATE_RC=$RUN_FILE_GATE_RC"
        echo "RUN_AUDIT_GATE_RC=$RUN_AUDIT_GATE_RC"
        echo "RUN_MANIFEST_RC=$RUN_MANIFEST_RC"
        echo "RULE_ANALYSIS_RC=$RULE_ANALYSIS_RC"
        echo "RULE_ANALYSIS_STATUS=$RULE_ANALYSIS_STATUS"
        echo "DIAGNOSTIC_COPY_GATE_RC=$DIAGNOSTIC_COPY_GATE_RC"
        echo "SOURCE_POST_RECHECK_RC=$SOURCE_POST_RECHECK_RC"
        echo "PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC=$PACKAGE_POST_EXECUTION_SHA_MANIFEST_RC"
        echo "PVS_BASE_DRC_EXECUTION_AUTHORIZED=NO"
        echo "PVS_DENSITY_DRC_EXECUTION_AUTHORIZED=$PVS_DENSITY_DRC_EXECUTION_AUTHORIZED"
        echo "PVS_REPLAY_AUTHORIZED=$PVS_REPLAY_AUTHORIZED"
        echo "PVS_EXECUTED=$PVS_EXECUTED"
        echo "PVS_LVS_STATUS=NOT_RUN"
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
    echo "===== POSITION DENSITY PVS DRC EXECUTION STATUS ====="
    cat "$STATUS_REPORT"
    if [ -r "$DIAGNOSTIC_ROOT/rule_analysis/pvs_drc_analysis_status.rpt" ]; then
        echo
        echo "===== POSITION DENSITY PVS DRC RULE ANALYSIS STATUS ====="
        cat "$DIAGNOSTIC_ROOT/rule_analysis/pvs_drc_analysis_status.rpt"
    fi
fi

if [ "$TRANSACTION_STATUS" = "PASS" ] && \
   [ "${DIAGNOSTIC_MANIFEST_CREATE_RC:-1}" = "0" ]; then
    true
else
    false
fi
