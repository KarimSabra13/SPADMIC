#!/usr/bin/env bash
# Review one exact cross-block PVS DRC seed candidate for Position core.
# This stage copies controls into diagnostics, but modifies no template/package
# file and never launches PVS or the strict replay wrapper.

set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
EXPECTED_HEAD="${1:-MISSING}"
DISCOVERY_ROOT="${2:-MISSING}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
PACKAGE="$WORK_ROOT/handoff/innovus/blocks/spadmic_position_core/innovus_ooc_harden_position_core_gridfit_20260717_114810"
PACKAGE_GDS="$PACKAGE/gds/spadmic_position_core.gds"
EXPECTED_GDS_SHA=ebba26a43c6fdf8257b60625ac7f823d7ce13a3c9b83607470393116b49f72e1

EXPECTED_CANDIDATE_LIST_SHA=21911e928f6d582627882cbc47374a281e9ef287c62819d53fe8590c460fa268
EXPECTED_CANDIDATE_INVENTORY_SHA=0347f9bde497d4d7373a17c18b49e7d523609806160c1092bb651068c0601e1a
EXPECTED_DISCOVERY_STATUS_SHA=1f4d5b6bdfe25970e085b61f32e400c7528fdf621500de9c1dcca30761491c89

TEMPLATE_ROOT=/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/layoutverification/pvs_drc
PRIMARY_SEED="$TEMPLATE_ROOT/spadmic_tx_packet_core"
PRIMARY_SEED_GDS="$PRIMARY_SEED/spadmic_tx_packet_core.gds"
PRIMARY_SEED_TOP=spadmic_tx_packet_core

RUN_OK=1
CD_RC=NOT_RUN
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
DISCOVERY_FILE_GATE_RC=NOT_RUN
DISCOVERY_HASH_GATE_RC=NOT_RUN
DISCOVERY_STATUS_GATE_RC=NOT_RUN
PACKAGE_FILE_GATE_RC=NOT_RUN
PACKAGE_HASH_GATE_RC=NOT_RUN
PACKAGE_STATUS_GATE_RC=NOT_RUN
PACKAGE_SHA_MANIFEST_RC=NOT_RUN
PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=NOT_RUN
DIAGNOSTIC_CREATE_RC=NOT_RUN
DIAGNOSTIC_COPY_GATE_RC=NOT_RUN
PRIMARY_REQUIRED_FILE_GATE_RC=NOT_RUN
PRIMARY_CONTROL_IDENTITY_GATE_RC=NOT_RUN
PRIMARY_CONTROL_COPY_GATE_RC=NOT_RUN
PRIMARY_EXECUTABLE_CONTRACT_GATE_RC=NOT_RUN
SOURCE_TEMPLATE_RECHECK_RC=NOT_RUN
PACKAGE_SHA_CONSOLE=""

if [ "$EXPECTED_HEAD" = "MISSING" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: expected repository HEAD argument missing"
    RUN_OK=0
fi

if [ "$DISCOVERY_ROOT" = "MISSING" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: discovery root argument missing"
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
    CANDIDATE_LIST="$DISCOVERY_ROOT/candidate_directories.txt"
    CANDIDATE_INVENTORY="$DISCOVERY_ROOT/template_candidate_inventory.rpt"
    DISCOVERY_STATUS="$DISCOVERY_ROOT/template_discovery_status.rpt"
    DISCOVERY_FILE_GATE_RC=0

    for FILE in \
        "$CANDIDATE_LIST" \
        "$CANDIDATE_INVENTORY" \
        "$DISCOVERY_STATUS"
    do
        if [ ! -s "$FILE" ]; then
            echo "MISSING_OR_EMPTY=$FILE"
            DISCOVERY_FILE_GATE_RC=1
        fi
    done

    echo "DISCOVERY_FILE_GATE_RC=$DISCOVERY_FILE_GATE_RC"

    if [ "$DISCOVERY_FILE_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: discovery evidence missing"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    ACTUAL_CANDIDATE_LIST_SHA="$(sha256sum "$CANDIDATE_LIST" | awk '{print $1}')"
    ACTUAL_CANDIDATE_INVENTORY_SHA="$(sha256sum "$CANDIDATE_INVENTORY" | awk '{print $1}')"
    ACTUAL_DISCOVERY_STATUS_SHA="$(sha256sum "$DISCOVERY_STATUS" | awk '{print $1}')"
    DISCOVERY_HASH_GATE_RC=0

    if [ "$ACTUAL_CANDIDATE_LIST_SHA" != "$EXPECTED_CANDIDATE_LIST_SHA" ] || \
       [ "$ACTUAL_CANDIDATE_INVENTORY_SHA" != "$EXPECTED_CANDIDATE_INVENTORY_SHA" ] || \
       [ "$ACTUAL_DISCOVERY_STATUS_SHA" != "$EXPECTED_DISCOVERY_STATUS_SHA" ]; then

        DISCOVERY_HASH_GATE_RC=1
    fi

    echo "EXPECTED_CANDIDATE_LIST_SHA=$EXPECTED_CANDIDATE_LIST_SHA"
    echo "ACTUAL_CANDIDATE_LIST_SHA=$ACTUAL_CANDIDATE_LIST_SHA"
    echo "EXPECTED_CANDIDATE_INVENTORY_SHA=$EXPECTED_CANDIDATE_INVENTORY_SHA"
    echo "ACTUAL_CANDIDATE_INVENTORY_SHA=$ACTUAL_CANDIDATE_INVENTORY_SHA"
    echo "EXPECTED_DISCOVERY_STATUS_SHA=$EXPECTED_DISCOVERY_STATUS_SHA"
    echo "ACTUAL_DISCOVERY_STATUS_SHA=$ACTUAL_DISCOVERY_STATUS_SHA"
    echo "DISCOVERY_HASH_GATE_RC=$DISCOVERY_HASH_GATE_RC"

    DISCOVERY_STATUS_GATE_RC=0
    for EXPECTED_LINE in \
        "STATUS=PASS" \
        "RESULT=CANDIDATES_RECORDED_FOR_REVIEW" \
        "GDS_SHA256=$EXPECTED_GDS_SHA" \
        "TEMPLATE_CANDIDATE_COUNT=114" \
        "POSITION_NAMED_CANDIDATE_COUNT=0" \
        "POSITION_TEMPLATE_EVIDENCE_STATUS=NOT_FOUND" \
        "ATTRIBUTABLE_POSITION_TEMPLATE_STATUS=NOT_PROVEN" \
        "CROSS_BLOCK_TEMPLATE_REUSE_AUTHORIZED=NO" \
        "PVS_REPLAY_AUTHORIZED=NO" \
        "PACKAGE_MODIFIED=NO" \
        "PVS_EXECUTED=NO"
    do
        grep -Fqx "$EXPECTED_LINE" "$DISCOVERY_STATUS"
        LINE_RC=$?
        echo "DISCOVERY_STATUS_LINE_RC=$LINE_RC EXPECTED=$EXPECTED_LINE"

        if [ "$LINE_RC" -ne 0 ]; then
            DISCOVERY_STATUS_GATE_RC=1
        fi
    done

    echo "DISCOVERY_STATUS_GATE_RC=$DISCOVERY_STATUS_GATE_RC"

    if [ "$DISCOVERY_HASH_GATE_RC" -ne 0 ] || \
       [ "$DISCOVERY_STATUS_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: discovery evidence is not attributable"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    PACKAGE_FILE_GATE_RC=0

    for FILE in \
        "$PACKAGE_GDS" \
        "$PACKAGE/manifests/SHA256SUMS" \
        "$PACKAGE/status/qualification.rpt" \
        "$PACKAGE/status/handoff_audit.rpt"
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
        "$PACKAGE/status/qualification.rpt|PVS_BASE_DRC_STATUS=NOT_RUN" \
        "$PACKAGE/status/qualification.rpt|PVS_DENSITY_DRC_STATUS=NOT_RUN" \
        "$PACKAGE/status/qualification.rpt|PVS_LVS_STATUS=NOT_RUN" \
        "$PACKAGE/status/qualification.rpt|SIGNOFF_READY=NO"
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
    PACKAGE_SHA_CONSOLE="$WORK_ROOT/diagnostics/position_package_sha_check_$$.rpt"
    mkdir -p "$WORK_ROOT/diagnostics"
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
    grep -Fqx "$PRIMARY_SEED" "$CANDIDATE_LIST"
    PRIMARY_LISTED_RC=$?
    echo "PRIMARY_LISTED_RC=$PRIMARY_LISTED_RC"

    if [ "$PRIMARY_LISTED_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: pinned primary seed absent from discovery"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    DIAGNOSTIC_ID="position_pvs_drc_seed_review_$(date +%Y%m%d_%H%M%S)"
    DIAGNOSTIC_ROOT="$WORK_ROOT/diagnostics/$DIAGNOSTIC_ID"
    mkdir -p "$DIAGNOSTIC_ROOT/primary_controls"
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
    cp "$PACKAGE_SHA_CONSOLE" "$DIAGNOSTIC_ROOT/package_sha256_check.rpt"
    DIAGNOSTIC_COPY_GATE_RC=$?
    rm -f "$PACKAGE_SHA_CONSOLE"

    echo "DIAGNOSTIC_COPY_GATE_RC=$DIAGNOSTIC_COPY_GATE_RC"

    if [ "$DIAGNOSTIC_COPY_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: diagnostic evidence copy failed"
        RUN_OK=0
    fi

    PRIMARY_REQUIRED_FILE_GATE_RC=0
fi

if [ "$RUN_OK" -eq 1 ]; then

    for FILE in \
        "$PRIMARY_SEED/.config.rul" \
        "$PRIMARY_SEED/.preset.autosave" \
        "$PRIMARY_SEED/.technology.rul" \
        "$PRIMARY_SEED/pipo1.setup" \
        "$PRIMARY_SEED/pvsdrcctl" \
        "$PRIMARY_SEED/run.pvs" \
        "$PRIMARY_SEED/cell_tree.txt" \
        "$PRIMARY_SEED_GDS"
    do
        if [ ! -f "$FILE" ]; then
            echo "MISSING=$FILE"
            PRIMARY_REQUIRED_FILE_GATE_RC=1
        fi
    done

    echo "PRIMARY_REQUIRED_FILE_GATE_RC=$PRIMARY_REQUIRED_FILE_GATE_RC"

    if [ "$PRIMARY_REQUIRED_FILE_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: primary seed files missing"
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
        ACTUAL_SHA="$(sha256sum "$PRIMARY_SEED/$NAME" | awk '{print $1}')"
        echo "PRIMARY_CONTROL_FILE=$PRIMARY_SEED/$NAME"
        echo "PRIMARY_CONTROL_EXPECTED_SHA256=$EXPECTED_SHA"
        echo "PRIMARY_CONTROL_ACTUAL_SHA256=$ACTUAL_SHA"

        if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
            PRIMARY_CONTROL_IDENTITY_GATE_RC=1
        fi
    done

    echo "PRIMARY_CONTROL_IDENTITY_GATE_RC=$PRIMARY_CONTROL_IDENTITY_GATE_RC"

    if [ "$PRIMARY_CONTROL_IDENTITY_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: primary seed controls changed since discovery"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    PRIMARY_CONTROL_COPY_GATE_RC=0
    for NAME in \
        .config.rul \
        .preset.autosave \
        .technology.rul \
        pipo1.setup \
        pvsdrcctl \
        run.pvs \
        cell_tree.txt
    do
        cp -p "$PRIMARY_SEED/$NAME" "$DIAGNOSTIC_ROOT/primary_controls/$NAME"
        COPY_RC=$?
        if [ "$COPY_RC" -ne 0 ]; then
            PRIMARY_CONTROL_COPY_GATE_RC=1
        fi
    done

    echo "PRIMARY_CONTROL_COPY_GATE_RC=$PRIMARY_CONTROL_COPY_GATE_RC"

    if [ "$PRIMARY_CONTROL_COPY_GATE_RC" -ne 0 ]; then
        echo "STOP_HERE_DO_NOT_CONTINUE: primary control snapshot failed"
        RUN_OK=0
    fi
fi

if [ "$RUN_OK" -eq 1 ]; then
    PRIMARY_EXECUTABLE_CONTRACT_GATE_RC=0
    CONTRACT_REPORT="$DIAGNOSTIC_ROOT/primary_seed_contract.rpt"
    : >"$CONTRACT_REPORT"

    for SPEC in \
        "$PRIMARY_SEED/run.pvs|-drc" \
        "$PRIMARY_SEED/run.pvs|-top_cell $PRIMARY_SEED_TOP" \
        "$PRIMARY_SEED/run.pvs|-control $PRIMARY_SEED/pvsdrcctl" \
        "$PRIMARY_SEED/run.pvs|$PRIMARY_SEED/.config.rul" \
        "$PRIMARY_SEED/run.pvs|$PRIMARY_SEED/.technology.rul" \
        "$PRIMARY_SEED/pvsdrcctl|layout_path \"$PRIMARY_SEED_GDS\";" \
        "$PRIMARY_SEED/pvsdrcctl|#UNDEFINE DENSITY" \
        "$PRIMARY_SEED/pvsdrcctl|report_summary -drc" \
        "$PRIMARY_SEED/pvsdrcctl|results_db -drc" \
        "$PRIMARY_SEED/.technology.rul|technology \"XH018_1131\" -ruleSet \"default\"" \
        "$PRIMARY_SEED/pipo1.setup|techLib    \"TECH_XH018_HD\""
    do
        FILE="${SPEC%%|*}"
        EXPECTED_TEXT="${SPEC#*|}"
        grep -Fq -- "$EXPECTED_TEXT" "$FILE"
        LINE_RC=$?
        echo "CONTRACT_LINE_RC=$LINE_RC FILE=$FILE EXPECTED=$EXPECTED_TEXT" \
            >>"$CONTRACT_REPORT"

        if [ "$LINE_RC" -ne 0 ]; then
            PRIMARY_EXECUTABLE_CONTRACT_GATE_RC=1
        fi
    done

    DENSITY_DIRECTIVE_COUNT="$(grep -Ec '^[[:space:]]*#(UN)?DEFINE[[:space:]]+DENSITY([[:space:]]|$)' "$PRIMARY_SEED/pvsdrcctl")"
    PREPROCESSOR_DIRECTIVE_COUNT="$(grep -Ec '^[[:space:]]*#(UN)?DEFINE[[:space:]]+' "$PRIMARY_SEED/pvsdrcctl")"

    echo "DENSITY_DIRECTIVE_COUNT=$DENSITY_DIRECTIVE_COUNT" >>"$CONTRACT_REPORT"
    echo "PREPROCESSOR_DIRECTIVE_COUNT=$PREPROCESSOR_DIRECTIVE_COUNT" >>"$CONTRACT_REPORT"

    if [ "$DENSITY_DIRECTIVE_COUNT" -ne 1 ]; then
        PRIMARY_EXECUTABLE_CONTRACT_GATE_RC=1
    fi

    echo "PRIMARY_EXECUTABLE_CONTRACT_GATE_RC=$PRIMARY_EXECUTABLE_CONTRACT_GATE_RC" \
        >>"$CONTRACT_REPORT"
    cat "$CONTRACT_REPORT"
fi

if [ "$RUN_OK" -eq 1 ]; then
    EXECUTABLE_LINES="$DIAGNOSTIC_ROOT/primary_pvsdrcctl_executable_lines.txt"
    RISK_LINES="$DIAGNOSTIC_ROOT/primary_pvsdrcctl_risk_scan.rpt"
    KEY_LINES="$DIAGNOSTIC_ROOT/primary_control_key_lines.rpt"

    awk '
        {
            line = $0
            sub(/\/\/.*/, "", line)
            if (line !~ /^[[:space:]]*$/) print line
        }
    ' "$PRIMARY_SEED/pvsdrcctl" >"$EXECUTABLE_LINES"

    grep -niE 'waiv|exclud|ignore|suppress|filter|skip|disable|rule[[:space:]_-]*off' \
        "$EXECUTABLE_LINES" >"$RISK_LINES"
    RISK_GREP_RC=$?
    EXECUTABLE_RISK_LINE_COUNT="$(awk 'NF {count++} END {print count + 0}' "$RISK_LINES")"

    {
        echo "LABEL=SPADMIC_POSITION_PVS_DRC_PRIMARY_CONTROL_KEY_LINES"
        for FILE in \
            "$PRIMARY_SEED/.technology.rul" \
            "$PRIMARY_SEED/pipo1.setup" \
            "$PRIMARY_SEED/pvsdrcctl" \
            "$PRIMARY_SEED/run.pvs"
        do
            echo "CONTROL_BEGIN=$FILE"
            grep -nEi 'technology|techLib|layout_path|top_cell|DENSITY|report_summary|results_db|max_results|max_vertex|waiv|exclud|ignore|suppress|filter|skip|disable' \
                "$FILE" 2>/dev/null
            echo "CONTROL_END=$FILE"
        done
    } >"$KEY_LINES"

    AUTOMATED_CONTROL_RISK_SCAN_STATUS=PASS
    if [ "$EXECUTABLE_RISK_LINE_COUNT" -ne 0 ]; then
        AUTOMATED_CONTROL_RISK_SCAN_STATUS=REVIEW_REQUIRED
    fi

    echo "RISK_GREP_RC=$RISK_GREP_RC"
    echo "EXECUTABLE_RISK_LINE_COUNT=$EXECUTABLE_RISK_LINE_COUNT"
    echo "AUTOMATED_CONTROL_RISK_SCAN_STATUS=$AUTOMATED_CONTROL_RISK_SCAN_STATUS"
fi

if [ "$RUN_OK" -eq 1 ]; then
    COMPARISON_REPORT="$DIAGNOSTIC_ROOT/shortlist_comparison.rpt"
    SHORTLIST_MISSING_COUNT=0

    {
        echo "LABEL=SPADMIC_POSITION_PVS_DRC_SEED_SHORTLIST_COMPARISON"
        echo "PRIMARY_SEED=$PRIMARY_SEED"
        echo "PRIMARY_SEED_RATIONALE=SAME_PROJECT_NON_HV_DIGITAL_BLOCK_RULE_SCAFFOLD_ONLY"

        for CANDIDATE in \
            "$TEMPLATE_ROOT/spadmic_tx_packet_core" \
            "$TEMPLATE_ROOT/spadmic_tx_packet_core_HV" \
            "$TEMPLATE_ROOT/matrice3" \
            "$TEMPLATE_ROOT/SPADMIC2"
        do
            echo "CANDIDATE_BEGIN=$CANDIDATE"
            grep -Fqx "$CANDIDATE" "$CANDIDATE_LIST"
            LISTED_RC=$?
            echo "DISCOVERY_LISTED_RC=$LISTED_RC"

            if [ "$LISTED_RC" -ne 0 ]; then
                SHORTLIST_MISSING_COUNT=$((SHORTLIST_MISSING_COUNT + 1))
            fi

            for NAME in .technology.rul pipo1.setup pvsdrcctl run.pvs
            do
                FILE="$CANDIDATE/$NAME"
                if [ -f "$FILE" ]; then
                    echo "CONTROL_FILE=$FILE"
                    echo "CONTROL_BYTES=$(stat -c '%s' "$FILE")"
                    echo "CONTROL_SHA256=$(sha256sum "$FILE" | awk '{print $1}')"
                    grep -nEi 'technology|techLib|layout_path|top_cell|DENSITY|waiv|exclud|ignore|suppress|filter|skip|disable' \
                        "$FILE" 2>/dev/null | head -n 80
                else
                    echo "CONTROL_MISSING=$FILE"
                fi
            done
            echo "CANDIDATE_END=$CANDIDATE"
        done

        echo "SHORTLIST_MISSING_COUNT=$SHORTLIST_MISSING_COUNT"
    } >"$COMPARISON_REPORT"
fi

if [ "$RUN_OK" -eq 1 ]; then
    SOURCE_TEMPLATE_RECHECK_RC=0
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
        ACTUAL_SHA="$(sha256sum "$PRIMARY_SEED/$NAME" | awk '{print $1}')"
        if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
            SOURCE_TEMPLATE_RECHECK_RC=1
        fi
    done

    echo "SOURCE_TEMPLATE_RECHECK_RC=$SOURCE_TEMPLATE_RECHECK_RC"

    (
        cd "$PACKAGE" || false
        sha256sum -c manifests/SHA256SUMS
    ) >"$DIAGNOSTIC_ROOT/package_sha256_post_review.rpt" 2>&1
    PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=$?

    echo "PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=$PACKAGE_POST_REVIEW_SHA_MANIFEST_RC"

    SEED_TECHNICAL_REVIEW_STATUS=PASS
    NEXT_GATE=POSITION_CROSS_BLOCK_SEED_STRICT_DRY_RUN_PREFLIGHT

    if [ "$PRIMARY_EXECUTABLE_CONTRACT_GATE_RC" -ne 0 ] || \
       [ "$AUTOMATED_CONTROL_RISK_SCAN_STATUS" != "PASS" ] || \
       [ "$SOURCE_TEMPLATE_RECHECK_RC" -ne 0 ]; then

        SEED_TECHNICAL_REVIEW_STATUS=REVIEW_REQUIRED
        NEXT_GATE=POSITION_PVS_DRC_SEED_CONTROL_MANUAL_REVIEW
    fi

    FINAL_REVIEW_STATUS=PASS
    PACKAGE_MODIFIED=NO
    PINNED_SOURCE_CONTROLS_UNCHANGED=YES

    if [ "$SOURCE_TEMPLATE_RECHECK_RC" -ne 0 ]; then
        FINAL_REVIEW_STATUS=FAIL
        PINNED_SOURCE_CONTROLS_UNCHANGED=NO
        NEXT_GATE=STOP_AND_INVESTIGATE_SEED_CONTROL_DRIFT
    fi

    if [ "$PACKAGE_POST_REVIEW_SHA_MANIFEST_RC" -ne 0 ]; then
        FINAL_REVIEW_STATUS=FAIL
        PACKAGE_MODIFIED=UNKNOWN_OR_YES
        NEXT_GATE=STOP_AND_INVESTIGATE_PACKAGE_HASH_DRIFT
    fi

    STATUS_REPORT="$DIAGNOSTIC_ROOT/seed_review_status.rpt"
    {
        echo "LABEL=SPADMIC_POSITION_PVS_DRC_SEED_REVIEW"
        echo "STATUS=$FINAL_REVIEW_STATUS"
        echo "RESULT=CROSS_BLOCK_SEED_CONTROLS_RECORDED_FOR_REVIEW"
        echo "SOURCE_DISCOVERY_ROOT=$DISCOVERY_ROOT"
        echo "SOURCE_DISCOVERY_STATUS_SHA256=$EXPECTED_DISCOVERY_STATUS_SHA"
        echo "PACKAGE=$PACKAGE"
        echo "PACKAGE_GDS=$PACKAGE_GDS"
        echo "PACKAGE_GDS_SHA256=$EXPECTED_GDS_SHA"
        echo "PRIMARY_SEED=$PRIMARY_SEED"
        echo "PRIMARY_SEED_GDS=$PRIMARY_SEED_GDS"
        echo "PRIMARY_SEED_TOP=$PRIMARY_SEED_TOP"
        echo "PRIMARY_SEED_CLASSIFICATION=CROSS_BLOCK_RULE_LAUNCH_SCAFFOLD_CANDIDATE_ONLY"
        echo "PRIMARY_CONTROL_IDENTITY_STATUS=PASS"
        echo "PRIMARY_EXECUTABLE_CONTRACT_STATUS=$([ "$PRIMARY_EXECUTABLE_CONTRACT_GATE_RC" -eq 0 ] && echo PASS || echo FAIL)"
        echo "DENSITY_HOOK_STATUS=$([ "$DENSITY_DIRECTIVE_COUNT" -eq 1 ] && echo PASS || echo FAIL)"
        echo "AUTOMATED_CONTROL_RISK_SCAN_STATUS=$AUTOMATED_CONTROL_RISK_SCAN_STATUS"
        echo "EXECUTABLE_RISK_LINE_COUNT=$EXECUTABLE_RISK_LINE_COUNT"
        echo "SEED_TECHNICAL_REVIEW_STATUS=$SEED_TECHNICAL_REVIEW_STATUS"
        echo "ATTRIBUTABLE_POSITION_TEMPLATE_STATUS=NOT_PROVEN"
        echo "TEMPLATE_SELECTION_AUTHORIZED=NO"
        echo "CROSS_BLOCK_TEMPLATE_REUSE_AUTHORIZED=NO"
        echo "STRICT_DRY_RUN_PREFLIGHT_AUTHORIZED=NO"
        echo "PVS_REPLAY_AUTHORIZED=NO"
        echo "PACKAGE_POST_REVIEW_SHA_MANIFEST_RC=$PACKAGE_POST_REVIEW_SHA_MANIFEST_RC"
        echo "PACKAGE_MODIFIED=$PACKAGE_MODIFIED"
        echo "SOURCE_TEMPLATE_WRITE_ATTEMPTED=NO"
        echo "PINNED_SOURCE_CONTROLS_UNCHANGED=$PINNED_SOURCE_CONTROLS_UNCHANGED"
        echo "PVS_EXECUTED=NO"
        echo "PVS_BASE_DRC_STATUS=NOT_RUN"
        echo "PVS_DENSITY_DRC_STATUS=NOT_RUN"
        echo "PVS_LVS_STATUS=NOT_RUN"
        echo "BLOCK_PROMOTION_AUTHORIZED=NO"
        echo "SIGNOFF_READY=NO"
        echo "NEXT_GATE=$NEXT_GATE"
    } >"$STATUS_REPORT"

    echo
    echo "===== PRIMARY SEED CONTROL CONTRACT ====="
    cat "$CONTRACT_REPORT"

    echo
    echo "===== PRIMARY SEED CONTROL RISK SCAN ====="
    if [ -s "$RISK_LINES" ]; then
        cat "$RISK_LINES"
    else
        echo "NO_EXECUTABLE_RISK_KEYWORDS_FOUND"
    fi

    echo
    echo "===== SHORTLIST COMPARISON ====="
    cat "$COMPARISON_REPORT"

    echo
    echo "===== SEED REVIEW STATUS ====="
    cat "$STATUS_REPORT"

    echo
    echo "===== DIAGNOSTIC HASHES ====="
    find "$DIAGNOSTIC_ROOT" -type f ! -name SHA256SUMS \
        -print0 | sort -z | xargs -0 sha256sum | tee "$DIAGNOSTIC_ROOT/SHA256SUMS"

    if [ "$FINAL_REVIEW_STATUS" = "PASS" ]; then
        true
    else
        false
    fi
else
    if [ "$PACKAGE_SHA_CONSOLE" != "" ]; then
        rm -f "$PACKAGE_SHA_CONSOLE"
    fi
    echo "POSITION_PVS_DRC_SEED_REVIEW_STATUS=NOT_RUN"
    echo "PVS_EXECUTED=NO"
    echo "STOP_HERE_DO_NOT_RUN_PVS"
    false
fi
