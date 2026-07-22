#!/usr/bin/env bash

###############################################################################
# Hash-bound PVS dry-run preflight for one cumulative digital assembly phase.
# This materializes run-local controls but never executes PVS.
#
# Usage:
#   bash TOP/ci/server_preflight_digital_assembly_phase_pvs.sh \
#     <expected-head> <phase> <immutable-handoff-package>
###############################################################################

set +e

REPO="${SPADMIC_REPO:-/home/validmgr/ksabra/2026_SPAD/SPADMIC}"
EXPECTED_HEAD="${1:-MISSING}"
PHASE="${2:-MISSING}"
PACKAGE="${3:-MISSING}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_ROOT="$WORK_ROOT/diagnostics/digital_assembly_pvs_preflight_${PHASE}_${TIMESTAMP}"

PVS_BIN="${SPADMIC_CADENCE_PVS_BIN:-/eda/cadence/2023-24/RHELx86/PVS_22.22.000/bin/pvs}"
DRC_TEMPLATE="${SPADMIC_ASSEMBLY_PVS_DRC_TEMPLATE:-/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/layoutverification/pvs_drc/spadmic_tx_packet_core}"
DRC_TEMPLATE_GDS="${SPADMIC_ASSEMBLY_PVS_DRC_TEMPLATE_GDS:-$DRC_TEMPLATE/spadmic_tx_packet_core.gds}"
DRC_TEMPLATE_TOP="${SPADMIC_ASSEMBLY_PVS_DRC_TEMPLATE_TOP:-spadmic_tx_packet_core}"
LVS_TEMPLATE="${SPADMIC_ASSEMBLY_PVS_LVS_TEMPLATE:-/group/validmgr/PROJET/Prj_xh018/ebecheto/cds_V0/PvsLVS/spadmic_tx_packet_core_HV}"

RUN_OK=1
CD_RC=NOT_RUN
CHECKOUT_RC=NOT_RUN
PULL_RC=NOT_RUN
ACTUAL_HEAD=UNKNOWN
TRACKED_DIFF_RC=NOT_RUN
STAGED_DIFF_RC=NOT_RUN
SCRIPT_GATE_RC=NOT_RUN
PACKAGE_MANIFEST_RC=NOT_RUN
PACKAGE_AUDIT_RC=NOT_RUN
PACKAGE_IDENTITY_RC=NOT_RUN
TEMPLATE_FILE_GATE_RC=NOT_RUN
TEMPLATE_SCAFFOLD_RC=NOT_RUN
TEMPLATE_STABILITY_RC=NOT_RUN
BASE_DRY_RUN_RC=NOT_RUN
DENSITY_DRY_RUN_RC=NOT_APPLICABLE
LVS_DRY_RUN_RC=NOT_RUN
DRY_RUN_AUDIT_RC=NOT_RUN
PACKAGE_POSTCHECK_RC=NOT_RUN
DIAGNOSTIC_MANIFEST_RC=NOT_RUN
BASE_RUN_DIR=UNKNOWN
DENSITY_RUN_DIR=NOT_APPLICABLE
LVS_RUN_DIR=UNKNOWN

case "$PHASE" in
  p00_tx) TOP_MODULE=spadmic_digital_assembly_v1_p00_tx ;;
  p01_position) TOP_MODULE=spadmic_digital_assembly_v1_p01_position ;;
  p02_event_control) TOP_MODULE=spadmic_digital_assembly_v1_p02_event_control ;;
  p03_matrix_interface) TOP_MODULE=spadmic_digital_assembly_v1_p03_matrix_interface ;;
  *)
    TOP_MODULE=UNKNOWN
    echo "STOP_HERE_DO_NOT_CONTINUE: unsupported assembly phase: $PHASE"
    RUN_OK=0
    ;;
esac

json_field() {
  local path="$1"
  local key="$2"
  python3 - "$path" "$key" <<'PY'
import json
import sys

value = json.load(open(sys.argv[1], encoding="utf-8"))
for part in sys.argv[2].split("."):
    value = value[part]
print(value)
PY
}

check_manifest() {
  local root="$1"
  local manifest="$2"
  if [ ! -r "$manifest" ]; then
    return 1
  fi
  (
    cd "$root"
    local local_cd_rc=$?
    if [ "$local_cd_rc" = "0" ]; then
      sha256sum -c "$manifest"
    else
      false
    fi
  )
}

record_template_file() {
  local kind="$1"
  local path="$2"
  local output="$3"
  if [ -f "$path" ]; then
    printf '%s\t%s\t%s\t%s\n' \
      "$kind" "$path" "$(wc -c < "$path")" "$(sha256sum "$path" | awk '{print $1}')" \
      >> "$output"
  else
    echo "MISSING_TEMPLATE_FILE=$path"
    TEMPLATE_FILE_GATE_RC=1
  fi
}

require_line() {
  local file="$1"
  local line="$2"
  grep -Fxq -- "$line" "$file" 2>/dev/null
}

if [ "$EXPECTED_HEAD" = "MISSING" ] || [ "$PACKAGE" = "MISSING" ]; then
  echo "STOP_HERE_DO_NOT_CONTINUE: expected HEAD, phase, and package are required"
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

if [ "$RUN_OK" = "1" ]; then
  git checkout SPADMIC_test
  CHECKOUT_RC=$?
  if [ "$CHECKOUT_RC" = "0" ]; then
    git pull --ff-only origin SPADMIC_test
    PULL_RC=$?
  fi
  ACTUAL_HEAD="$(git rev-parse HEAD 2>/dev/null)"
  git diff --quiet
  TRACKED_DIFF_RC=$?
  git diff --cached --quiet
  STAGED_DIFF_RC=$?
  SCRIPT_GATE_RC=0
  for file in \
    TOP/pnr/scripts/run_pvs_drc_handoff.sh \
    TOP/pnr/scripts/run_pvs_lvs_handoff.sh \
    TOP/pnr/scripts/audit_pvs_lvs_control_scaffold.py \
    TOP/pnr/scripts/audit_innovus_handoff.py
  do
    if [ ! -s "$file" ]; then
      echo "MISSING_OR_EMPTY=$file"
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
  if [ "$CHECKOUT_RC" != "0" ] || \
     [ "$PULL_RC" != "0" ] || \
     [ "$ACTUAL_HEAD" != "$EXPECTED_HEAD" ] || \
     [ "$TRACKED_DIFF_RC" != "0" ] || \
     [ "$STAGED_DIFF_RC" != "0" ] || \
     [ "$SCRIPT_GATE_RC" != "0" ]; then
    echo "STOP_HERE_DO_NOT_CONTINUE: checkout is not attributable"
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  if [ -d "$PACKAGE" ]; then
    PACKAGE="$(cd "$PACKAGE" && pwd -P)"
  else
    echo "STOP_HERE_DO_NOT_CONTINUE: package missing: $PACKAGE"
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  mkdir -p "$OUTPUT_ROOT/logs" "$OUTPUT_ROOT/package" \
    "$OUTPUT_ROOT/dry_runs/base" "$OUTPUT_ROOT/dry_runs/lvs"
  if [ "$PHASE" = "p03_matrix_interface" ]; then
    mkdir -p "$OUTPUT_ROOT/dry_runs/density"
  fi
  if [ "$?" != "0" ]; then
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  check_manifest "$PACKAGE" "$PACKAGE/manifests/SHA256SUMS" \
    > "$OUTPUT_ROOT/logs/package_manifest.log" 2>&1
  PACKAGE_MANIFEST_RC=$?
  python3 TOP/pnr/scripts/audit_innovus_handoff.py "$PACKAGE" \
    > "$OUTPUT_ROOT/package/handoff_audit.rpt" 2>&1
  PACKAGE_AUDIT_RC=$?
  PACKAGE_MANIFEST="$PACKAGE/manifests/package.json"
  PACKAGE_NAME="$(json_field "$PACKAGE_MANIFEST" name 2>/dev/null)"
  PACKAGE_LAYOUT_TOP="$(json_field "$PACKAGE_MANIFEST" layout_top 2>/dev/null)"
  PACKAGE_SOURCE_TOP="$(json_field "$PACKAGE_MANIFEST" source_top 2>/dev/null)"
  PACKAGE_KIND="$(json_field "$PACKAGE_MANIFEST" kind 2>/dev/null)"
  PACKAGE_PROFILE="$(json_field "$PACKAGE_MANIFEST" qualification_profile 2>/dev/null)"
  PACKAGE_PHASE="$(json_field "$PACKAGE_MANIFEST" digital_assembly_tc_gate.phase 2>/dev/null)"
  if [ "$PACKAGE_NAME" = "$TOP_MODULE" ] && \
     [ "$PACKAGE_LAYOUT_TOP" = "$TOP_MODULE" ] && \
     [ "$PACKAGE_SOURCE_TOP" = "$TOP_MODULE" ] && \
     [ "$PACKAGE_KIND" = "assembly" ] && \
     [ "$PACKAGE_PROFILE" = "digital_assembly_tc" ] && \
     [ "$PACKAGE_PHASE" = "$PHASE" ]; then
    PACKAGE_IDENTITY_RC=0
  else
    PACKAGE_IDENTITY_RC=1
  fi
  cp -p "$PACKAGE_MANIFEST" "$OUTPUT_ROOT/package/package.json" 2>/dev/null
  cp -p "$PACKAGE/status/qualification.rpt" "$OUTPUT_ROOT/package/qualification.rpt" 2>/dev/null
  cp -p "$PACKAGE/reports/digital_assembly_innovus_gate.rpt" "$OUTPUT_ROOT/package/digital_assembly_innovus_gate.rpt" 2>/dev/null
  echo "PACKAGE_MANIFEST_RC=$PACKAGE_MANIFEST_RC"
  echo "PACKAGE_AUDIT_RC=$PACKAGE_AUDIT_RC"
  echo "PACKAGE_IDENTITY_RC=$PACKAGE_IDENTITY_RC"
  if [ "$PACKAGE_MANIFEST_RC" != "0" ] || \
     [ "$PACKAGE_AUDIT_RC" != "0" ] || \
     [ "$PACKAGE_IDENTITY_RC" != "0" ]; then
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  TEMPLATE_FILE_GATE_RC=0
  TEMPLATE_PRE="$OUTPUT_ROOT/template_files.pre.tsv"
  printf 'kind\tpath\tbytes\tsha256\n' > "$TEMPLATE_PRE"
  record_template_file TOOL "$PVS_BIN" "$TEMPLATE_PRE"
  for file in .config.rul .preset.autosave .technology.rul cell_tree.txt pipo1.setup pvsdrcctl run.pvs; do
    record_template_file DRC "$DRC_TEMPLATE/$file" "$TEMPLATE_PRE"
  done
  record_template_file DRC "$DRC_TEMPLATE_GDS" "$TEMPLATE_PRE"
  for file in .config.rul .preset.autosave .technology.rul pipo1.setup pvslvsctl run.pvs; do
    record_template_file LVS "$LVS_TEMPLATE/$file" "$TEMPLATE_PRE"
  done
  python3 TOP/pnr/scripts/audit_pvs_lvs_control_scaffold.py \
    --template "$LVS_TEMPLATE" \
    --output "$OUTPUT_ROOT/lvs_template_scaffold_audit.rpt" \
    --expected-pvs-bin "$PVS_BIN" \
    > "$OUTPUT_ROOT/logs/lvs_template_audit.log" 2>&1
  TEMPLATE_SCAFFOLD_RC=$?
  LVS_TEMPLATE_GDS="$(sed -n 's/^TEMPLATE_GDS=//p' "$OUTPUT_ROOT/lvs_template_scaffold_audit.rpt" | head -n 1)"
  LVS_TEMPLATE_SOURCE="$(sed -n 's/^TEMPLATE_SOURCE=//p' "$OUTPUT_ROOT/lvs_template_scaffold_audit.rpt" | head -n 1)"
  LVS_TEMPLATE_LAYOUT_TOP="$(sed -n 's/^TEMPLATE_LAYOUT_TOP=//p' "$OUTPUT_ROOT/lvs_template_scaffold_audit.rpt" | head -n 1)"
  LVS_TEMPLATE_SOURCE_TOP="$(sed -n 's/^TEMPLATE_SOURCE_TOP=//p' "$OUTPUT_ROOT/lvs_template_scaffold_audit.rpt" | head -n 1)"
  LVS_TEMPLATE_CDL="$(sed -n 's/^TEMPLATE_EXECUTABLE_CDL=//p' "$OUTPUT_ROOT/lvs_template_scaffold_audit.rpt" | head -n 1)"
  record_template_file LVS "$LVS_TEMPLATE_GDS" "$TEMPLATE_PRE"
  record_template_file LVS "$LVS_TEMPLATE_SOURCE" "$TEMPLATE_PRE"
  if [ "$LVS_TEMPLATE_CDL" != "NONE" ] && [ -n "$LVS_TEMPLATE_CDL" ]; then
    record_template_file LVS "$LVS_TEMPLATE_CDL" "$TEMPLATE_PRE"
  fi
  echo "TEMPLATE_FILE_GATE_RC=$TEMPLATE_FILE_GATE_RC"
  echo "TEMPLATE_SCAFFOLD_RC=$TEMPLATE_SCAFFOLD_RC"
  if [ "$TEMPLATE_FILE_GATE_RC" != "0" ] || [ "$TEMPLATE_SCAFFOLD_RC" != "0" ]; then
    RUN_OK=0
  fi
fi

if [ "$RUN_OK" = "1" ]; then
  BASE_RUN_ID="digital_assembly_${PHASE}_preflight_${TIMESTAMP}_base"
  BASE_RUN_DIR="$PACKAGE/pvs/drc/$BASE_RUN_ID"
  EXPECTED_HEAD="$EXPECTED_HEAD" SPADMIC_CADENCE_PVS_BIN="$PVS_BIN" \
    bash TOP/pnr/scripts/run_pvs_drc_handoff.sh \
      --package "$PACKAGE" \
      --template "$DRC_TEMPLATE" \
      --template-gds "$DRC_TEMPLATE_GDS" \
      --template-top "$DRC_TEMPLATE_TOP" \
      --variant base \
      --run-id "$BASE_RUN_ID" \
      --dry-run \
      --allow-cross-block-control-scaffold \
      > "$OUTPUT_ROOT/logs/base_dry_run.log" 2>&1
  BASE_DRY_RUN_RC=$?

  if [ "$PHASE" = "p03_matrix_interface" ]; then
    DENSITY_RUN_ID="digital_assembly_${PHASE}_preflight_${TIMESTAMP}_density"
    DENSITY_RUN_DIR="$PACKAGE/pvs/drc/$DENSITY_RUN_ID"
    EXPECTED_HEAD="$EXPECTED_HEAD" SPADMIC_CADENCE_PVS_BIN="$PVS_BIN" \
      bash TOP/pnr/scripts/run_pvs_drc_handoff.sh \
        --package "$PACKAGE" \
        --template "$DRC_TEMPLATE" \
        --template-gds "$DRC_TEMPLATE_GDS" \
        --template-top "$DRC_TEMPLATE_TOP" \
        --variant density \
        --run-id "$DENSITY_RUN_ID" \
        --dry-run \
        --allow-cross-block-control-scaffold \
        > "$OUTPUT_ROOT/logs/density_dry_run.log" 2>&1
    DENSITY_DRY_RUN_RC=$?
  fi

  LVS_RUN_ID="digital_assembly_${PHASE}_preflight_${TIMESTAMP}_lvs"
  LVS_RUN_DIR="$PACKAGE/pvs/lvs/$LVS_RUN_ID"
  LVS_ARGS=(
    --package "$PACKAGE"
    --template "$LVS_TEMPLATE"
    --template-gds "$LVS_TEMPLATE_GDS"
    --template-source "$LVS_TEMPLATE_SOURCE"
    --template-layout-top "$LVS_TEMPLATE_LAYOUT_TOP"
    --template-source-top "$LVS_TEMPLATE_SOURCE_TOP"
    --run-id "$LVS_RUN_ID"
    --dry-run
    --allow-cross-block-control-scaffold
  )
  if [ "$LVS_TEMPLATE_CDL" != "NONE" ] && [ -n "$LVS_TEMPLATE_CDL" ]; then
    LVS_ARGS+=(--template-cdl "$LVS_TEMPLATE_CDL")
  fi
  EXPECTED_HEAD="$EXPECTED_HEAD" SPADMIC_CADENCE_PVS_BIN="$PVS_BIN" \
    bash TOP/pnr/scripts/run_pvs_lvs_handoff.sh "${LVS_ARGS[@]}" \
      > "$OUTPUT_ROOT/logs/lvs_dry_run.log" 2>&1
  LVS_DRY_RUN_RC=$?
  echo "BASE_DRY_RUN_RC=$BASE_DRY_RUN_RC"
  echo "DENSITY_DRY_RUN_RC=$DENSITY_DRY_RUN_RC"
  echo "LVS_DRY_RUN_RC=$LVS_DRY_RUN_RC"
fi

if [ "$BASE_DRY_RUN_RC" = "0" ] && [ "$LVS_DRY_RUN_RC" = "0" ] && \
   { [ "$PHASE" != "p03_matrix_interface" ] || [ "$DENSITY_DRY_RUN_RC" = "0" ]; }; then
  cp -a "$BASE_RUN_DIR/." "$OUTPUT_ROOT/dry_runs/base/"
  cp -a "$LVS_RUN_DIR/." "$OUTPUT_ROOT/dry_runs/lvs/"
  if [ "$PHASE" = "p03_matrix_interface" ]; then
    cp -a "$DENSITY_RUN_DIR/." "$OUTPUT_ROOT/dry_runs/density/"
  fi
  DRY_RUN_AUDIT_RC=0
  require_line "$BASE_RUN_DIR/pvs_drc_status.rpt" 'PVS_DRC_STATUS=DRY_RUN_READY' || DRY_RUN_AUDIT_RC=1
  require_line "$BASE_RUN_DIR/pvs_drc_status.rpt" 'PVS_DRC_VARIANT=BASE' || DRY_RUN_AUDIT_RC=1
  require_line "$BASE_RUN_DIR/replay_contract_status.rpt" 'STATUS=PASS' || DRY_RUN_AUDIT_RC=1
  require_line "$BASE_RUN_DIR/output_isolation.rpt" 'STATUS=PASS' || DRY_RUN_AUDIT_RC=1
  require_line "$LVS_RUN_DIR/pvs_lvs_status.rpt" 'PVS_LVS_STATUS=DRY_RUN_READY' || DRY_RUN_AUDIT_RC=1
  require_line "$LVS_RUN_DIR/pvs_lvs_status.rpt" "LAYOUT_TOP=$TOP_MODULE" || DRY_RUN_AUDIT_RC=1
  require_line "$LVS_RUN_DIR/pvs_lvs_status.rpt" "SOURCE_TOP=$TOP_MODULE" || DRY_RUN_AUDIT_RC=1
  if [ "$PHASE" = "p03_matrix_interface" ]; then
    require_line "$DENSITY_RUN_DIR/pvs_drc_status.rpt" 'PVS_DRC_STATUS=DRY_RUN_READY' || DRY_RUN_AUDIT_RC=1
    require_line "$DENSITY_RUN_DIR/pvs_drc_status.rpt" 'PVS_DRC_VARIANT=DENSITY' || DRY_RUN_AUDIT_RC=1
  fi
else
  DRY_RUN_AUDIT_RC=1
fi

if [ -d "$OUTPUT_ROOT" ]; then
  TEMPLATE_POST="$OUTPUT_ROOT/template_files.post.tsv"
  cp -p "$OUTPUT_ROOT/template_files.pre.tsv" "$TEMPLATE_POST.reference" 2>/dev/null
  printf 'kind\tpath\tbytes\tsha256\n' > "$TEMPLATE_POST"
  TEMPLATE_FILE_GATE_RC=0
  tail -n +2 "$OUTPUT_ROOT/template_files.pre.tsv" 2>/dev/null | while IFS=$'\t' read -r kind path bytes sha; do
    record_template_file "$kind" "$path" "$TEMPLATE_POST"
  done
  cmp -s "$OUTPUT_ROOT/template_files.pre.tsv" "$TEMPLATE_POST"
  TEMPLATE_STABILITY_RC=$?
  check_manifest "$PACKAGE" "$PACKAGE/manifests/SHA256SUMS" \
    > "$OUTPUT_ROOT/logs/package_postcheck.log" 2>&1
  PACKAGE_POSTCHECK_RC=$?
fi

if [ "$RUN_OK" = "1" ] && \
   [ "$DRY_RUN_AUDIT_RC" = "0" ] && \
   [ "$TEMPLATE_STABILITY_RC" = "0" ] && \
   [ "$PACKAGE_POSTCHECK_RC" = "0" ]; then
  STATUS_VALUE=PASS
  RESULT=EXACT_PHASE_PVS_CONTROLS_MATERIALIZED_WITHOUT_EXECUTION
  NEXT_GATE=REVIEW_PREFLIGHT_THEN_RUN_ONE_BASE_DRC
else
  STATUS_VALUE=FAIL
  RESULT=PVS_PREFLIGHT_REVIEW_REQUIRED
  NEXT_GATE=STOP_AND_REVIEW_PVS_PREFLIGHT
fi

STATUS_REPORT="$OUTPUT_ROOT/digital_assembly_pvs_preflight_status.rpt"
if [ -d "$OUTPUT_ROOT" ]; then
  GDS="$PACKAGE/gds/$TOP_MODULE.gds"
  SOURCE="$PACKAGE/netlist/$TOP_MODULE.lvs.pg.v"
  CDL="$PACKAGE/pdk/xh018_D_CELLS_JIHD.cdl"
  {
    echo "LABEL=SPADMIC_DIGITAL_ASSEMBLY_PVS_PREFLIGHT"
    echo "STATUS=$STATUS_VALUE"
    echo "RESULT=$RESULT"
    echo "EXPECTED_HEAD=$EXPECTED_HEAD"
    echo "ACTUAL_HEAD=$ACTUAL_HEAD"
    echo "PHASE=$PHASE"
    echo "TOP_MODULE=$TOP_MODULE"
    echo "SOURCE_TOP=$TOP_MODULE"
    echo "LAYOUT_TOP=$TOP_MODULE"
    echo "PACKAGE=$PACKAGE"
    echo "PACKAGE_MANIFEST_SHA256=$(sha256sum "$PACKAGE/manifests/package.json" 2>/dev/null | awk '{print $1}')"
    echo "GDS_SHA256=$(sha256sum "$GDS" 2>/dev/null | awk '{print $1}')"
    echo "LVS_SOURCE_SHA256=$(sha256sum "$SOURCE" 2>/dev/null | awk '{print $1}')"
    echo "STDCELL_CDL_SHA256=$(sha256sum "$CDL" 2>/dev/null | awk '{print $1}')"
    echo "PACKAGE_MANIFEST_RC=$PACKAGE_MANIFEST_RC"
    echo "PACKAGE_AUDIT_RC=$PACKAGE_AUDIT_RC"
    echo "PACKAGE_IDENTITY_RC=$PACKAGE_IDENTITY_RC"
    echo "TEMPLATE_FILE_GATE_RC=$TEMPLATE_FILE_GATE_RC"
    echo "TEMPLATE_SCAFFOLD_RC=$TEMPLATE_SCAFFOLD_RC"
    echo "TEMPLATE_STABILITY_RC=$TEMPLATE_STABILITY_RC"
    echo "BASE_DRY_RUN_RC=$BASE_DRY_RUN_RC"
    echo "DENSITY_DRY_RUN_RC=$DENSITY_DRY_RUN_RC"
    echo "LVS_DRY_RUN_RC=$LVS_DRY_RUN_RC"
    echo "DRY_RUN_AUDIT_RC=$DRY_RUN_AUDIT_RC"
    echo "PACKAGE_POSTCHECK_RC=$PACKAGE_POSTCHECK_RC"
    echo "BASE_RUN_DIR=$BASE_RUN_DIR"
    echo "DENSITY_RUN_DIR=$DENSITY_RUN_DIR"
    echo "LVS_RUN_DIR=$LVS_RUN_DIR"
    echo "PVS_EXECUTED=NO"
    echo "PVS_BASE_DRC_STATUS=NOT_RUN"
    echo "PVS_DENSITY_DRC_STATUS=NOT_RUN"
    echo "PVS_LVS_STATUS=NOT_RUN"
    echo "OA_INSERTION_AUTHORIZED=NO"
    echo "SIGNOFF_READY=NO"
    echo "NEXT_GATE=$NEXT_GATE"
  } > "$STATUS_REPORT"
  (
    cd "$OUTPUT_ROOT"
    local_cd_rc=$?
    if [ "$local_cd_rc" = "0" ]; then
      find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
    else
      false
    fi
  )
  DIAGNOSTIC_MANIFEST_RC=$?
fi

echo "OUTPUT_ROOT=$OUTPUT_ROOT"
echo "DIAGNOSTIC_MANIFEST_RC=$DIAGNOSTIC_MANIFEST_RC"
cat "$STATUS_REPORT" 2>/dev/null
if [ "$STATUS_VALUE" = "PASS" ] && [ "$DIAGNOSTIC_MANIFEST_RC" = "0" ]; then
  echo "DIGITAL_ASSEMBLY_PVS_PREFLIGHT_TRANSACTION_STATUS=PASS"
  echo "RETURN_OUTPUT_FOR_PHASE_BASE_DRC_REVIEW"
  echo "DO_NOT_START_PVS_UNTIL_REVIEWED"
  true
else
  echo "DIGITAL_ASSEMBLY_PVS_PREFLIGHT_TRANSACTION_STATUS=FAIL"
  echo "STOP_HERE_DO_NOT_START_PVS"
  false
fi
