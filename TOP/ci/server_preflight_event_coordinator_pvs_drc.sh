#!/usr/bin/env bash
# Materialize attributable Event base and density DRC controls without PVS.

set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
EXPECTED_HEAD="${1:-MISSING}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"

SOURCE_STAGING_HEAD=0fff3d2afb447f746c69ea946450ff6f5cdd7400
SOURCE_STAGING_ROOT="$WORK_ROOT/diagnostics/event_handoff_staging_20260721_101249"
PACKAGE="$WORK_ROOT/handoff/innovus/blocks/spadmic_event_coordinator/innovus_ooc_harden_event_coordinator_20260720_173527"
PACKAGE_GDS="$PACKAGE/gds/spadmic_event_coordinator.gds"
EVENT_TOP=spadmic_event_coordinator

EXPECTED_GDS_SHA256=837538f219dacc9521f02bc58b3e2e5e587f859b4e70b69a1ca4a3e5fe7b6857
EXPECTED_LEF_SHA256=56345986a887317f0374984b1ea8b3442ea482aeec0572614e9fd2c0b6732a14
EXPECTED_DEF_SHA256=f9d6a927c7cecad40916cac67b8142f6fb6c6b013e3d57ab779889fd0ab21a68
EXPECTED_RAW_PG_NETLIST_SHA256=0ecc571317f6beaa13c7f006ac3ecc4f1ff2a72b9655a176c0fa21e3c0a07398
EXPECTED_LVS_SOURCE_SHA256=f9ec957b23b1a229c7c2ff19309fb7463dfc5cac7e570ad1ca68ad8b08089b27
EXPECTED_STDCELL_CDL_SHA256=5ff10b0b31003da9bb6db59eba7d52c82435e3ab68b2ba0a1956e4d9fbaef8cf

PDK_PVS_ROOT=/data/pdk/xfab/xh018/cadence/v10_1/pvs/v10_1_1/PVS
DRC_RULE="$PDK_PVS_ROOT/xh018_DRC.rul"
EXPECTED_DRC_RULE_SHA256=0b1ce563da515dd50d17a5e16baa2a2addc10354aa06ab5e1a111b01ed039cb6
STREAM_MAP=/data/pdk/xfab/xh018/cadence/v10_1/PDK/IC61/v10_1_1/TECH_XH018_HD_1131/pnr_streamout.map
EXPECTED_STREAM_MAP_SHA256=4d7b850f74ef193b6bc7b15b1e52fd38ba61cc4a6e1b283c4201343a20ad233d

# Reuse only the hash-reviewed GUI control scaffold accepted for Position.
PRIMARY_SEED=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/layoutverification/pvs_drc/spadmic_tx_packet_core
PRIMARY_SEED_GDS="$PRIMARY_SEED/spadmic_tx_packet_core.gds"
PRIMARY_SEED_TOP=spadmic_tx_packet_core

RUN_OK=1
CD_RC=NOT_RUN
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
SCRIPT_GATE_RC=NOT_RUN
SOURCE_FILE_GATE_RC=NOT_RUN
SOURCE_STATUS_GATE_RC=NOT_RUN
SOURCE_STAGING_MANIFEST_RC=NOT_RUN
PACKAGE_FILE_GATE_RC=NOT_RUN
PACKAGE_HASH_GATE_RC=NOT_RUN
PACKAGE_SHA_MANIFEST_RC=NOT_RUN
HANDOFF_AUDIT_RC=NOT_RUN
PDK_FILE_GATE_RC=NOT_RUN
PDK_HASH_GATE_RC=NOT_RUN
SEED_FILE_GATE_RC=NOT_RUN
SEED_IDENTITY_GATE_RC=NOT_RUN
DIAGNOSTIC_CREATE_RC=NOT_RUN
GDS_LAYER_COLLECTOR_RC=NOT_RUN
GDS_LAYER_APPLICABILITY_GATE_RC=NOT_RUN
BASE_DRY_RUN_RC=NOT_RUN
DENSITY_DRY_RUN_RC=NOT_RUN
RUN_AUDIT_GATE_RC=NOT_RUN
DIAGNOSTIC_COPY_GATE_RC=NOT_RUN
SOURCE_POST_RECHECK_RC=NOT_RUN
SOURCE_STAGING_POST_MANIFEST_RC=NOT_RUN
PACKAGE_POST_PREFLIGHT_SHA_MANIFEST_RC=NOT_RUN
DIAGNOSTIC_MANIFEST_CREATE_RC=NOT_RUN
DIAGNOSTIC_ROOT=UNKNOWN
BASE_RUN_DIR=UNKNOWN
DENSITY_RUN_DIR=UNKNOWN
PIMIDE_EVENT_APPLICABILITY_STATUS=UNKNOWN

require_line() {
    local file="$1"
    local expected_line="$2"
    local label="$3"

    grep -Fqx -- "$expected_line" "$file" 2>/dev/null
    LINE_MATCH_RC=$?
    echo "$label=$LINE_MATCH_RC FILE=$file EXPECTED=$expected_line"
    return "$LINE_MATCH_RC"
}

check_hash() {
    local file="$1"
    local expected_sha="$2"
    local label="$3"
    local actual_sha

    actual_sha="$(sha256sum "$file" 2>/dev/null | awk '{print $1}')"
    echo "${label}_FILE=$file"
    echo "${label}_EXPECTED_SHA256=$expected_sha"
    echo "${label}_ACTUAL_SHA256=$actual_sha"
    [ "$actual_sha" = "$expected_sha" ]
}

copy_if_readable() {
    local source_file="$1"
    local destination_file="$2"

    if [ -r "$source_file" ]; then
        mkdir -p "$(dirname "$destination_file")"
        cp -p "$source_file" "$destination_file"
        [ "$?" -eq 0 ] || DIAGNOSTIC_COPY_GATE_RC=1
    else
        echo "MISSING_OR_UNREADABLE_COPY_SOURCE=$source_file"
        DIAGNOSTIC_COPY_GATE_RC=1
    fi
}

if [ "$EXPECTED_HEAD" = "MISSING" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: expected repository HEAD argument missing"
    RUN_OK=0
fi

if [ -d "$REPO/.git" ]; then
    cd "$REPO"
    CD_RC=$?
else
    echo "STOP_HERE_DO_NOT_CONTINUE: repository missing: $REPO"
    CD_RC=1
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

    SCRIPT_GATE_RC=0
    for SCRIPT in \
        TOP/pnr/scripts/audit_innovus_handoff.py \
        TOP/pnr/scripts/collect_position_pvs_gds_layer_applicability.py \
        TOP/pnr/scripts/run_pvs_drc_handoff.sh
    do
        if [ ! -f "$SCRIPT" ]; then
            echo "MISSING_SCRIPT=$SCRIPT"
            SCRIPT_GATE_RC=1
        fi
    done

    echo "CHECKOUT_RC=$CHECKOUT_RC"
    echo "PULL_RC=$PULL_RC"
    echo "EXPECTED_HEAD=$EXPECTED_HEAD"
    echo "ACTUAL_HEAD=$ACTUAL_HEAD"
    echo "TRACKED_DIFF_RC=$TRACKED_DIFF_RC"
    echo "STAGED_DIFF_RC=$STAGED_DIFF_RC"
    echo "SCRIPT_GATE_RC=$SCRIPT_GATE_RC"
    git status --short --branch --untracked-files=no

    if [ "$CHECKOUT_RC" -ne 0 ] || \
       [ "$PULL_RC" != "0" ] || \
       [ "$ACTUAL_HEAD" != "$EXPECTED_HEAD" ] || \
       [ "$TRACKED_DIFF_RC" -ne 0 ] || \
       [ "$STAGED_DIFF_RC" -ne 0 ] || \
       [ "$SCRIPT_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: checkout is not attributable"
        RUN_OK=0
    fi
fi

SOURCE_STATUS="$SOURCE_STAGING_ROOT/event_handoff_staging_status.rpt"
SOURCE_MANIFEST="$SOURCE_STAGING_ROOT/SHA256SUMS"
PACKAGE_QUALIFICATION="$PACKAGE/status/qualification.rpt"
PACKAGE_AUDIT="$PACKAGE/status/handoff_audit.rpt"
PACKAGE_SOURCE_PREP="$PACKAGE/reports/lvs_source_preparation.rpt"
PACKAGE_GDS_AUDIT="$PACKAGE/reports/gds_export_audit.rpt"

if [ "$RUN_OK" -eq 1 ]; then
    SOURCE_FILE_GATE_RC=0
    for FILE in \
        "$SOURCE_STATUS" \
        "$SOURCE_MANIFEST" \
        "$SOURCE_STAGING_ROOT/package_evidence/package_sha256_check.rpt" \
        "$PACKAGE_QUALIFICATION" \
        "$PACKAGE_AUDIT" \
        "$PACKAGE_SOURCE_PREP" \
        "$PACKAGE_GDS_AUDIT" \
        "$PACKAGE/manifests/package.json" \
        "$PACKAGE/manifests/SHA256SUMS"
    do
        if [ ! -s "$FILE" ]; then
            echo "MISSING_OR_EMPTY=$FILE"
            SOURCE_FILE_GATE_RC=1
        fi
    done
    echo "SOURCE_FILE_GATE_RC=$SOURCE_FILE_GATE_RC"
    if [ "$SOURCE_FILE_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: Event staging evidence is incomplete"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    SOURCE_STATUS_GATE_RC=0
    for EXPECTED_LINE in \
        "STATUS=PASS" \
        "RESULT=EVENT_IMMUTABLE_HANDOFF_STAGED" \
        "OUTCOME_CLASS=ATTRIBUTABLE_CANDIDATE_PACKAGE" \
        "EXPECTED_HEAD=$SOURCE_STAGING_HEAD" \
        "ACTUAL_HEAD=$SOURCE_STAGING_HEAD" \
        "PACKAGE=$PACKAGE" \
        "PACKAGE_GDS_SHA256=$EXPECTED_GDS_SHA256" \
        "PACKAGE_LEF_SHA256=$EXPECTED_LEF_SHA256" \
        "PACKAGE_DEF_SHA256=$EXPECTED_DEF_SHA256" \
        "PACKAGE_RAW_PG_NETLIST_SHA256=$EXPECTED_RAW_PG_NETLIST_SHA256" \
        "PACKAGE_LVS_SOURCE_SHA256=$EXPECTED_LVS_SOURCE_SHA256" \
        "PACKAGE_STDCELL_CDL_SHA256=$EXPECTED_STDCELL_CDL_SHA256" \
        "PACKAGE_HASH_GATE_RC=0" \
        "PACKAGE_MANIFEST_GATE_RC=0" \
        "PACKAGE_SHA_MANIFEST_RC=0" \
        "QUALIFICATION_GATE_RC=0" \
        "AUDIT_REPORT_GATE_RC=0" \
        "SOURCE_PREP_GATE_RC=0" \
        "PACKAGE_EVIDENCE_GATE_RC=0" \
        "SOURCE_POST_RECHECK_RC=0" \
        "EVENT_IMMUTABLE_HANDOFF_STAGING_STATUS=PASS" \
        "EVENT_PVS_BASE_DRC_STATUS=NOT_RUN" \
        "EVENT_PVS_DENSITY_DRC_STATUS=NOT_RUN" \
        "EVENT_PVS_LVS_STATUS=NOT_RUN" \
        "PVS_EXECUTED=NO" \
        "EVENT_PVS_PREFLIGHT_AUTHORIZED=YES" \
        "ASSEMBLY_INSERTION_AUTHORIZED=NO" \
        "ASSEMBLY_BLOCKED_BY=p00_tx,p01_position" \
        "FULL_TOP_PNR_AUTHORIZED=NO" \
        "BLOCK_PROMOTION_AUTHORIZED=NO" \
        "SIGNOFF_READY=NO" \
        "NEXT_GATE=PREPARE_EVENT_PVS_BASE_DRC_STRICT_PREFLIGHT"
    do
        require_line "$SOURCE_STATUS" "$EXPECTED_LINE" SOURCE_STATUS_LINE_RC
        [ "$?" -eq 0 ] || SOURCE_STATUS_GATE_RC=1
    done
    echo "SOURCE_STATUS_GATE_RC=$SOURCE_STATUS_GATE_RC"
    if [ "$SOURCE_STATUS_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: staging status does not authorize Event preflight"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    PREFLIGHT_STAMP="$(date +%Y%m%d_%H%M%S)"
    DIAGNOSTIC_ROOT="$WORK_ROOT/diagnostics/event_pvs_drc_strict_preflight_$PREFLIGHT_STAMP"
    BASE_RUN_ID="event_strict_preflight_${PREFLIGHT_STAMP}_base"
    DENSITY_RUN_ID="event_strict_preflight_${PREFLIGHT_STAMP}_density"
    BASE_RUN_DIR="$PACKAGE/pvs/drc/$BASE_RUN_ID"
    DENSITY_RUN_DIR="$PACKAGE/pvs/drc/$DENSITY_RUN_ID"
    mkdir -p \
        "$DIAGNOSTIC_ROOT/source_staging" \
        "$DIAGNOSTIC_ROOT/gds_layer_applicability" \
        "$DIAGNOSTIC_ROOT/base" \
        "$DIAGNOSTIC_ROOT/density"
    DIAGNOSTIC_CREATE_RC=$?
    echo "DIAGNOSTIC_ROOT=$DIAGNOSTIC_ROOT"
    echo "BASE_RUN_DIR=$BASE_RUN_DIR"
    echo "DENSITY_RUN_DIR=$DENSITY_RUN_DIR"
    echo "DIAGNOSTIC_CREATE_RC=$DIAGNOSTIC_CREATE_RC"
    if [ "$DIAGNOSTIC_CREATE_RC" -ne 0 ]; then
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    (
        if cd "$SOURCE_STAGING_ROOT"; then
            sha256sum -c SHA256SUMS
        else
            false
        fi
    ) >"$DIAGNOSTIC_ROOT/source_staging/SHA256SUMS.preflight_check.rpt" 2>&1
    SOURCE_STAGING_MANIFEST_RC=$?
    echo "SOURCE_STAGING_MANIFEST_RC=$SOURCE_STAGING_MANIFEST_RC"
    if [ "$SOURCE_STAGING_MANIFEST_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: Event staging diagnostic manifest failed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    PACKAGE_FILE_GATE_RC=0
    for FILE in \
        "$PACKAGE_GDS" \
        "$PACKAGE/lef/event_coordinator.abstract.lef" \
        "$PACKAGE/def/spadmic_event_coordinator.def" \
        "$PACKAGE/netlist/spadmic_event_coordinator.innovus.pg.v" \
        "$PACKAGE/netlist/spadmic_event_coordinator.lvs.pg.v" \
        "$PACKAGE/pdk/xh018_D_CELLS_JIHD.cdl"
    do
        if [ ! -s "$FILE" ]; then
            echo "MISSING_OR_EMPTY=$FILE"
            PACKAGE_FILE_GATE_RC=1
        fi
    done
    echo "PACKAGE_FILE_GATE_RC=$PACKAGE_FILE_GATE_RC"
    if [ "$PACKAGE_FILE_GATE_RC" -ne 0 ]; then
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    PACKAGE_HASH_GATE_RC=0
    for SPEC in \
        "$PACKAGE_GDS|$EXPECTED_GDS_SHA256|EVENT_GDS" \
        "$PACKAGE/lef/event_coordinator.abstract.lef|$EXPECTED_LEF_SHA256|EVENT_LEF" \
        "$PACKAGE/def/spadmic_event_coordinator.def|$EXPECTED_DEF_SHA256|EVENT_DEF" \
        "$PACKAGE/netlist/spadmic_event_coordinator.innovus.pg.v|$EXPECTED_RAW_PG_NETLIST_SHA256|EVENT_RAW_PG_NETLIST" \
        "$PACKAGE/netlist/spadmic_event_coordinator.lvs.pg.v|$EXPECTED_LVS_SOURCE_SHA256|EVENT_LVS_SOURCE" \
        "$PACKAGE/pdk/xh018_D_CELLS_JIHD.cdl|$EXPECTED_STDCELL_CDL_SHA256|EVENT_STDCELL_CDL"
    do
        FILE="${SPEC%%|*}"
        REMAINDER="${SPEC#*|}"
        EXPECTED_SHA="${REMAINDER%%|*}"
        LABEL="${REMAINDER#*|}"
        check_hash "$FILE" "$EXPECTED_SHA" "$LABEL"
        [ "$?" -eq 0 ] || PACKAGE_HASH_GATE_RC=1
    done
    echo "PACKAGE_HASH_GATE_RC=$PACKAGE_HASH_GATE_RC"
    if [ "$PACKAGE_HASH_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: accepted Event package changed"
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
    ) >"$DIAGNOSTIC_ROOT/package_sha256_preflight_check.rpt" 2>&1
    PACKAGE_SHA_MANIFEST_RC=$?
    echo "PACKAGE_SHA_MANIFEST_RC=$PACKAGE_SHA_MANIFEST_RC"
    if [ "$PACKAGE_SHA_MANIFEST_RC" -ne 0 ]; then
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    python3 TOP/pnr/scripts/audit_innovus_handoff.py "$PACKAGE"
    HANDOFF_AUDIT_RC=$?
    echo "HANDOFF_AUDIT_RC=$HANDOFF_AUDIT_RC"
    if [ "$HANDOFF_AUDIT_RC" -ne 0 ]; then
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    PDK_FILE_GATE_RC=0
    for FILE in "$DRC_RULE" "$STREAM_MAP"
    do
        if [ ! -s "$FILE" ]; then
            echo "MISSING_OR_EMPTY=$FILE"
            PDK_FILE_GATE_RC=1
        fi
    done
    echo "PDK_FILE_GATE_RC=$PDK_FILE_GATE_RC"

    PDK_HASH_GATE_RC=0
    check_hash "$DRC_RULE" "$EXPECTED_DRC_RULE_SHA256" DRC_RULE
    [ "$?" -eq 0 ] || PDK_HASH_GATE_RC=1
    check_hash "$STREAM_MAP" "$EXPECTED_STREAM_MAP_SHA256" STREAM_MAP
    [ "$?" -eq 0 ] || PDK_HASH_GATE_RC=1
    echo "PDK_HASH_GATE_RC=$PDK_HASH_GATE_RC"

    if [ "$PDK_FILE_GATE_RC" -ne 0 ] || [ "$PDK_HASH_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: pinned PDK DRC evidence changed"
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
        check_hash "$PRIMARY_SEED/$NAME" "$EXPECTED_SHA" SEED_CONTROL
        [ "$?" -eq 0 ] || SEED_IDENTITY_GATE_RC=1
    done
    echo "SEED_IDENTITY_GATE_RC=$SEED_IDENTITY_GATE_RC"
    if [ "$SEED_IDENTITY_GATE_RC" -ne 0 ]; then
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    python3 TOP/pnr/scripts/collect_position_pvs_gds_layer_applicability.py \
        --gds "$PACKAGE_GDS" \
        --stream-map "$STREAM_MAP" \
        --drc-rule "$DRC_RULE" \
        --top-structure "$EVENT_TOP" \
        --subject-label event \
        --output-dir "$DIAGNOSTIC_ROOT/gds_layer_applicability" \
        --expected-gds-sha "$EXPECTED_GDS_SHA256" \
        --expected-stream-map-sha "$EXPECTED_STREAM_MAP_SHA256" \
        --expected-drc-sha "$EXPECTED_DRC_RULE_SHA256"
    GDS_LAYER_COLLECTOR_RC=$?

    COLLECTOR_STATUS="$DIAGNOSTIC_ROOT/gds_layer_applicability/gds_layer_applicability_collector_status.rpt"
    EVENT_POLICY="$DIAGNOSTIC_ROOT/gds_layer_applicability/event_option_policy_contract.rpt"
    PIMIDE_EVENT_APPLICABILITY_STATUS="$(
        sed -n 's/^PIMIDE_EVENT_APPLICABILITY_STATUS=//p' "$COLLECTOR_STATUS" |
        head -n 1
    )"
    if [ -z "$PIMIDE_EVENT_APPLICABILITY_STATUS" ]; then
        PIMIDE_EVENT_APPLICABILITY_STATUS=UNKNOWN
    fi
    GDS_LAYER_APPLICABILITY_GATE_RC=0
    for SPEC in \
        "$COLLECTOR_STATUS|COLLECTOR_STATUS=PASS" \
        "$COLLECTOR_STATUS|KNOWN_SOURCE_HASH_GATE_STATUS=PASS" \
        "$COLLECTOR_STATUS|GDS_PARSE_STATUS=PASS" \
        "$COLLECTOR_STATUS|GDS_TOP_STRUCTURE_STATUS=PASS" \
        "$COLLECTOR_STATUS|GDS_HIERARCHY_STATUS=PASS" \
        "$COLLECTOR_STATUS|TARGET_LAYER_MAPPING_STATUS=PASS" \
        "$COLLECTOR_STATUS|SOURCE_RECHECK_STATUS=PASS" \
        "$COLLECTOR_STATUS|GDS_SHA256=$EXPECTED_GDS_SHA256" \
        "$COLLECTOR_STATUS|STREAM_MAP_SHA256=$EXPECTED_STREAM_MAP_SHA256" \
        "$COLLECTOR_STATUS|DRC_RULE_SHA256=$EXPECTED_DRC_RULE_SHA256" \
        "$COLLECTOR_STATUS|TOP_STRUCTURE=$EVENT_TOP" \
        "$COLLECTOR_STATUS|PAD_REACHABLE_GEOMETRY_ELEMENT_COUNT=0" \
        "$COLLECTOR_STATUS|PIMIDE_REACHABLE_GEOMETRY_ELEMENT_COUNT=0" \
        "$COLLECTOR_STATUS|NOPIM_REACHABLE_GEOMETRY_ELEMENT_COUNT=0" \
        "$COLLECTOR_STATUS|PIMIDE_EVENT_APPLICABILITY_STATUS=NOT_APPLICABLE_NO_REACHABLE_PAD_OR_PIMIDE_GEOMETRY" \
        "$COLLECTOR_STATUS|STRICT_DRY_RUN_PREFLIGHT_RECOMMENDATION=READY_FOR_MANUAL_AUTHORIZATION" \
        "$COLLECTOR_STATUS|PVS_EXECUTED=NO" \
        "$COLLECTOR_STATUS|ERROR_COUNT=0" \
        "$EVENT_POLICY|DEFAULT_RULE_SET_SELECTION_STATUS=PASS" \
        "$EVENT_POLICY|DENSITY_POLICY=BASE_DRC_PLUS_SEPARATE_DENSITY_DRC" \
        "$EVENT_POLICY|POPPING_STATE=UNDEFINED" \
        "$EVENT_POLICY|PIMIDE_STATE=UNDEFINED" \
        "$EVENT_POLICY|DUMMY_FILL_STATE=UNDEFINED" \
        "$EVENT_POLICY|VAR_ANT_RATIO_STATE=DEFINED"
    do
        FILE="${SPEC%%|*}"
        EXPECTED_LINE="${SPEC#*|}"
        require_line "$FILE" "$EXPECTED_LINE" GDS_APPLICABILITY_LINE_RC
        [ "$?" -eq 0 ] || GDS_LAYER_APPLICABILITY_GATE_RC=1
    done
    echo "GDS_LAYER_COLLECTOR_RC=$GDS_LAYER_COLLECTOR_RC"
    echo "GDS_LAYER_APPLICABILITY_GATE_RC=$GDS_LAYER_APPLICABILITY_GATE_RC"
    if [ "$GDS_LAYER_COLLECTOR_RC" -ne 0 ] || \
       [ "$GDS_LAYER_APPLICABILITY_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: exact Event GDS does not support selector policy"
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
        pvs_drc_status.rpt replay_contract_status.rpt output_isolation.rpt \
        preprocessor_defines.rpt external_references.rpt pvsdrcctl run.pvs SHA256SUMS
    do
        [ -s "$run_dir/$file" ] || gate_rc=1
    done

    require_line "$run_dir/pvs_drc_status.rpt" "PVS_DRC_STATUS=DRY_RUN_READY" RUN_STATUS_LINE_RC
    [ "$?" -eq 0 ] || gate_rc=1
    require_line "$run_dir/pvs_drc_status.rpt" "PVS_DRC_VARIANT=$variant" RUN_STATUS_LINE_RC
    [ "$?" -eq 0 ] || gate_rc=1
    require_line "$run_dir/pvs_drc_status.rpt" "CROSS_BLOCK_CONTROL_SCAFFOLD_AUTHORIZED=YES" RUN_STATUS_LINE_RC
    [ "$?" -eq 0 ] || gate_rc=1
    require_line "$run_dir/pvs_drc_status.rpt" "PACKAGE=$PACKAGE" RUN_STATUS_LINE_RC
    [ "$?" -eq 0 ] || gate_rc=1
    require_line "$run_dir/pvs_drc_status.rpt" "GDS_SHA256=$EXPECTED_GDS_SHA256" RUN_STATUS_LINE_RC
    [ "$?" -eq 0 ] || gate_rc=1
    require_line "$run_dir/replay_contract_status.rpt" "STATUS=PASS" REPLAY_LINE_RC
    [ "$?" -eq 0 ] || gate_rc=1
    require_line "$run_dir/output_isolation.rpt" "STATUS=PASS" ISOLATION_LINE_RC
    [ "$?" -eq 0 ] || gate_rc=1
    require_line "$run_dir/preprocessor_defines.rpt" "$density_report_line" PREPROCESSOR_LINE_RC
    [ "$?" -eq 0 ] || gate_rc=1
    require_line "$run_dir/pvsdrcctl" "$density_directive" CONTROL_LINE_RC
    [ "$?" -eq 0 ] || gate_rc=1

    for DIRECTIVE in \
        "#UNDEFINE POPPING" \
        "#UNDEFINE PIMIDE" \
        "#UNDEFINE DUMMY_FILL" \
        "#DEFINE VAR_ANT_RATIO"
    do
        require_line "$run_dir/pvsdrcctl" "$DIRECTIVE" CONTROL_LINE_RC
        [ "$?" -eq 0 ] || gate_rc=1
    done

    grep -Fq -- "layout_path \"$PACKAGE_GDS\";" "$run_dir/pvsdrcctl"
    [ "$?" -eq 0 ] || gate_rc=1
    grep -Fq -- "-top_cell $EVENT_TOP" "$run_dir/run.pvs"
    [ "$?" -eq 0 ] || gate_rc=1
    grep -Fq -- "$PRIMARY_SEED" "$run_dir/run.pvs" "$run_dir/pvsdrcctl"
    [ "$?" -ne 0 ] || gate_rc=1
    grep -Fq -- "$PRIMARY_SEED_TOP" "$run_dir/run.pvs" "$run_dir/pvsdrcctl"
    [ "$?" -ne 0 ] || gate_rc=1
    grep -q '^MISSING=' "$run_dir/external_references.rpt"
    [ "$?" -ne 0 ] || gate_rc=1
    [ ! -e "$run_dir/pvs.stdout.log" ] || gate_rc=1
    (
        if cd "$run_dir"; then
            sha256sum -c SHA256SUMS >/dev/null 2>&1
        else
            false
        fi
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
    [ "$?" -eq 0 ] || RUN_AUDIT_GATE_RC=1
    audit_preflight_run \
        "$DENSITY_RUN_DIR" DENSITY "#DEFINE DENSITY" \
        "DEFINE=DENSITY|OCCURRENCES=1"
    [ "$?" -eq 0 ] || RUN_AUDIT_GATE_RC=1
    echo "RUN_AUDIT_GATE_RC=$RUN_AUDIT_GATE_RC"
    if [ "$RUN_AUDIT_GATE_RC" -ne 0 ]; then
        RUN_OK=0
    fi
fi

if [ "$DIAGNOSTIC_ROOT" != "UNKNOWN" ]; then
    DIAGNOSTIC_COPY_GATE_RC=0
    copy_if_readable "$SOURCE_STATUS" "$DIAGNOSTIC_ROOT/source_staging/event_handoff_staging_status.rpt"
    copy_if_readable "$PACKAGE_QUALIFICATION" "$DIAGNOSTIC_ROOT/source_staging/qualification.rpt"
    copy_if_readable "$PACKAGE_AUDIT" "$DIAGNOSTIC_ROOT/source_staging/handoff_audit.rpt"
    copy_if_readable "$PACKAGE_SOURCE_PREP" "$DIAGNOSTIC_ROOT/source_staging/lvs_source_preparation.rpt"
    copy_if_readable "$PACKAGE_GDS_AUDIT" "$DIAGNOSTIC_ROOT/source_staging/gds_export_audit.rpt"

    for VARIANT_SPEC in \
        "$BASE_RUN_DIR|$DIAGNOSTIC_ROOT/base|$BASE_DRY_RUN_RC" \
        "$DENSITY_RUN_DIR|$DIAGNOSTIC_ROOT/density|$DENSITY_DRY_RUN_RC"
    do
        SOURCE_DIR="${VARIANT_SPEC%%|*}"
        REMAINDER="${VARIANT_SPEC#*|}"
        DESTINATION_DIR="${REMAINDER%%|*}"
        VARIANT_DRY_RUN_RC="${REMAINDER#*|}"
        for NAME in \
            pvs_drc_status.rpt replay_contract_status.rpt output_isolation.rpt \
            preprocessor_defines.rpt external_references.rpt \
            template_replacements.rpt pvsdrcctl run.pvs SHA256SUMS
        do
            if [ -f "$SOURCE_DIR/$NAME" ]; then
                copy_if_readable "$SOURCE_DIR/$NAME" "$DESTINATION_DIR/$NAME"
            elif [ "$VARIANT_DRY_RUN_RC" = "0" ]; then
                DIAGNOSTIC_COPY_GATE_RC=1
            fi
        done
    done
    echo "DIAGNOSTIC_COPY_GATE_RC=$DIAGNOSTIC_COPY_GATE_RC"
    if [ "$DIAGNOSTIC_COPY_GATE_RC" -ne 0 ]; then
        RUN_OK=0
    fi
fi

if [ "$DIAGNOSTIC_ROOT" != "UNKNOWN" ]; then
    SOURCE_POST_RECHECK_RC=0
    for SPEC in \
        "$PACKAGE_GDS|$EXPECTED_GDS_SHA256" \
        "$PACKAGE/lef/event_coordinator.abstract.lef|$EXPECTED_LEF_SHA256" \
        "$PACKAGE/def/spadmic_event_coordinator.def|$EXPECTED_DEF_SHA256" \
        "$PACKAGE/netlist/spadmic_event_coordinator.innovus.pg.v|$EXPECTED_RAW_PG_NETLIST_SHA256" \
        "$PACKAGE/netlist/spadmic_event_coordinator.lvs.pg.v|$EXPECTED_LVS_SOURCE_SHA256" \
        "$PACKAGE/pdk/xh018_D_CELLS_JIHD.cdl|$EXPECTED_STDCELL_CDL_SHA256" \
        "$DRC_RULE|$EXPECTED_DRC_RULE_SHA256" \
        "$STREAM_MAP|$EXPECTED_STREAM_MAP_SHA256" \
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
        [ "$ACTUAL_SHA" = "$EXPECTED_SHA" ] || SOURCE_POST_RECHECK_RC=1
    done
    echo "SOURCE_POST_RECHECK_RC=$SOURCE_POST_RECHECK_RC"
    [ "$SOURCE_POST_RECHECK_RC" -eq 0 ] || RUN_OK=0

    (
        if cd "$SOURCE_STAGING_ROOT"; then
            sha256sum -c SHA256SUMS
        else
            false
        fi
    ) >"$DIAGNOSTIC_ROOT/source_staging/SHA256SUMS.post_preflight_check.rpt" 2>&1
    SOURCE_STAGING_POST_MANIFEST_RC=$?
    echo "SOURCE_STAGING_POST_MANIFEST_RC=$SOURCE_STAGING_POST_MANIFEST_RC"
    [ "$SOURCE_STAGING_POST_MANIFEST_RC" -eq 0 ] || RUN_OK=0

    (
        if cd "$PACKAGE"; then
            sha256sum -c manifests/SHA256SUMS
        else
            false
        fi
    ) >"$DIAGNOSTIC_ROOT/package_sha256_post_preflight.rpt" 2>&1
    PACKAGE_POST_PREFLIGHT_SHA_MANIFEST_RC=$?
    echo "PACKAGE_POST_PREFLIGHT_SHA_MANIFEST_RC=$PACKAGE_POST_PREFLIGHT_SHA_MANIFEST_RC"
    [ "$PACKAGE_POST_PREFLIGHT_SHA_MANIFEST_RC" -eq 0 ] || RUN_OK=0
fi

if [ "$DIAGNOSTIC_ROOT" != "UNKNOWN" ]; then
    if [ "$RUN_OK" -eq 1 ]; then
        FINAL_STATUS=PASS
        FINAL_RESULT=EVENT_BASE_AND_DENSITY_RUN_LOCAL_CONTROLS_MATERIALIZED_WITHOUT_PVS_EXECUTION
        OUTCOME_CLASS=ATTRIBUTABLE_DRY_RUN_CONTROLS
        PREFLIGHT_STATUS=PASS
        BASE_EXECUTION_AUTHORIZED=YES
        PVS_REPLAY_AUTHORIZATION=BASE_ONLY
        NEXT_GATE=RUN_EVENT_PVS_BASE_DRC_ON_EXACT_STAGED_GDS
    else
        FINAL_STATUS=FAIL
        FINAL_RESULT=EVENT_STRICT_DRY_RUN_PREFLIGHT_INCOMPLETE
        OUTCOME_CLASS=UNATTRIBUTABLE_PREFLIGHT
        PREFLIGHT_STATUS=FAIL
        BASE_EXECUTION_AUTHORIZED=NO
        PVS_REPLAY_AUTHORIZATION=NO
        NEXT_GATE=STOP_AND_REVIEW_EVENT_STRICT_DRY_RUN_PREFLIGHT_FAILURE
    fi

    STATUS_REPORT="$DIAGNOSTIC_ROOT/event_pvs_drc_strict_preflight_status.rpt"
    {
        echo "LABEL=SPADMIC_EVENT_PVS_DRC_STRICT_PREFLIGHT"
        echo "STATUS=$FINAL_STATUS"
        echo "RESULT=$FINAL_RESULT"
        echo "OUTCOME_CLASS=$OUTCOME_CLASS"
        echo "EXPECTED_HEAD=$EXPECTED_HEAD"
        echo "ACTUAL_HEAD=$ACTUAL_HEAD"
        echo "SOURCE_STAGING_HEAD=$SOURCE_STAGING_HEAD"
        echo "SOURCE_STAGING_ROOT=$SOURCE_STAGING_ROOT"
        echo "SOURCE_STAGING_MANIFEST_RC=$SOURCE_STAGING_MANIFEST_RC"
        echo "SOURCE_STATUS_GATE_RC=$SOURCE_STATUS_GATE_RC"
        echo "PACKAGE=$PACKAGE"
        echo "PACKAGE_GDS_SHA256=$EXPECTED_GDS_SHA256"
        echo "EVENT_TOP=$EVENT_TOP"
        echo "PACKAGE_HASH_GATE_RC=$PACKAGE_HASH_GATE_RC"
        echo "PACKAGE_SHA_MANIFEST_RC=$PACKAGE_SHA_MANIFEST_RC"
        echo "HANDOFF_AUDIT_RC=$HANDOFF_AUDIT_RC"
        echo "DRC_RULE_SHA256=$EXPECTED_DRC_RULE_SHA256"
        echo "STREAM_MAP_SHA256=$EXPECTED_STREAM_MAP_SHA256"
        echo "PRIMARY_SEED=$PRIMARY_SEED"
        echo "CROSS_BLOCK_TEMPLATE_REUSE_SCOPE=CONTROL_SCAFFOLD_ONLY"
        echo "GDS_LAYER_COLLECTOR_RC=$GDS_LAYER_COLLECTOR_RC"
        echo "GDS_LAYER_APPLICABILITY_GATE_RC=$GDS_LAYER_APPLICABILITY_GATE_RC"
        echo "PIMIDE_EVENT_APPLICABILITY_STATUS=$PIMIDE_EVENT_APPLICABILITY_STATUS"
        echo "DEFAULT_RULE_SET=default"
        echo "PIMIDE_STATE=UNDEFINED"
        echo "POPPING_STATE=UNDEFINED"
        echo "DUMMY_FILL_STATE=UNDEFINED"
        echo "VAR_ANT_RATIO_STATE=DEFINED"
        echo "BASE_DENSITY_STATE=UNDEFINED"
        echo "DENSITY_VARIANT_DENSITY_STATE=DEFINED"
        echo "VARIANT_DIFFERENCE_POLICY=DENSITY_SELECTOR_ONLY"
        echo "BASE_RUN_DIR=$BASE_RUN_DIR"
        echo "DENSITY_RUN_DIR=$DENSITY_RUN_DIR"
        echo "BASE_DRY_RUN_RC=$BASE_DRY_RUN_RC"
        echo "DENSITY_DRY_RUN_RC=$DENSITY_DRY_RUN_RC"
        echo "RUN_AUDIT_GATE_RC=$RUN_AUDIT_GATE_RC"
        echo "DIAGNOSTIC_COPY_GATE_RC=$DIAGNOSTIC_COPY_GATE_RC"
        echo "SOURCE_POST_RECHECK_RC=$SOURCE_POST_RECHECK_RC"
        echo "SOURCE_STAGING_POST_MANIFEST_RC=$SOURCE_STAGING_POST_MANIFEST_RC"
        echo "PACKAGE_POST_PREFLIGHT_SHA_MANIFEST_RC=$PACKAGE_POST_PREFLIGHT_SHA_MANIFEST_RC"
        echo "EVENT_STRICT_DRY_RUN_PREFLIGHT_STATUS=$PREFLIGHT_STATUS"
        echo "EVENT_PVS_BASE_DRC_EXECUTION_AUTHORIZED=$BASE_EXECUTION_AUTHORIZED"
        echo "EVENT_PVS_DENSITY_DRC_EXECUTION_AUTHORIZED=NO"
        echo "PVS_REPLAY_AUTHORIZED=$PVS_REPLAY_AUTHORIZATION"
        echo "PVS_EXECUTED=NO"
        echo "EVENT_PVS_BASE_DRC_STATUS=NOT_RUN"
        echo "EVENT_PVS_DENSITY_DRC_STATUS=NOT_RUN"
        echo "EVENT_PVS_LVS_STATUS=NOT_RUN"
        echo "ASSEMBLY_PHASE=p02_event_control"
        echo "ASSEMBLY_INSERTION_AUTHORIZED=NO"
        echo "ASSEMBLY_BLOCKED_BY=p00_tx,p01_position"
        echo "FULL_TOP_PNR_AUTHORIZED=NO"
        echo "BLOCK_PROMOTION_AUTHORIZED=NO"
        echo "SIGNOFF_READY=NO"
        echo "NEXT_GATE=$NEXT_GATE"
    } >"$STATUS_REPORT"

    find "$DIAGNOSTIC_ROOT" -type f ! -name SHA256SUMS \
        -print0 | sort -z | xargs -0 sha256sum >"$DIAGNOSTIC_ROOT/SHA256SUMS"
    DIAGNOSTIC_MANIFEST_CREATE_RC=$?
    echo "DIAGNOSTIC_MANIFEST_CREATE_RC=$DIAGNOSTIC_MANIFEST_CREATE_RC"

    echo
    echo "===== EVENT PVS DRC STRICT PREFLIGHT STATUS ====="
    cat "$STATUS_REPORT"
    echo
    echo "===== EVENT GDS LAYER APPLICABILITY ====="
    cat "$DIAGNOSTIC_ROOT/gds_layer_applicability/gds_layer_applicability_collector_status.rpt" 2>/dev/null
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

    if [ "$FINAL_STATUS" = "PASS" ] && \
       [ "$DIAGNOSTIC_MANIFEST_CREATE_RC" -eq 0 ]; then
        true
    else
        false
    fi
else
    echo "EVENT_PVS_DRC_STRICT_PREFLIGHT_STATUS=NOT_RUN"
    echo "PVS_EXECUTED=NO"
    false
fi
