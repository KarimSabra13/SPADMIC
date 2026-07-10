#!/usr/bin/env bash
# P02-R4 PG geometry fix with one fresh Innovus process per helper candidate.
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SOURCE_BLOCK_ROOT="${1:-}"
BLOCK="${2:-}"
RUN_ID="${3:-innovus_ooc_pg_geometry_fix_${BLOCK:-block}_$(date +%Y%m%d_%H%M%S)}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"

if [[ -z "$SOURCE_BLOCK_ROOT" || -z "$BLOCK" ]]; then
  echo "Usage: $0 <signal-block-root> <block-name> [run-id]" >&2
  exit 2
fi
if [[ "$BLOCK" != "tx_ddr_strip" ]]; then
  echo "ERROR: P02-R4 is approved only for tx_ddr_strip" >&2
  exit 6
fi

CHECKPOINT="$SOURCE_BLOCK_ROOT/checkpoints/05_postroute_export.enc.dat"
[[ -d "$CHECKPOINT" ]] || CHECKPOINT="$SOURCE_BLOCK_ROOT/checkpoints/05_postroute_export.enc"
if [[ ! -e "$CHECKPOINT" ]]; then
  echo "ERROR: clean P01 checkpoint missing under $SOURCE_BLOCK_ROOT/checkpoints" >&2
  exit 6
fi
if ! command -v innovus >/dev/null 2>&1; then
  echo "ERROR: innovus missing; source /eda/cadence/eda_2023-2024" >&2
  exit 3
fi

RUN_ROOT="$WORK_ROOT/innovus/$RUN_ID"
if [[ -e "$RUN_ROOT" ]]; then
  echo "ERROR: immutable run exists: $RUN_ROOT" >&2
  exit 2
fi
mkdir -p "$RUN_ROOT"/{checkpoints,logs,outputs,reports,trials}

STREAM_MAP="${SPADMIC_STREAMOUT_MAP_FILE:-/eda/pdk/xfab/xh018/cadence/v10_1/PDK/IC61/v10_1_1/TECH_XH018_HD_1131/pnr_streamout.map}"
STDCELL_GDS="${SPADMIC_STDCELL_GDS:-/data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/gds/xh018_D_CELLS_JIHD.gds}"
[[ -s "$STREAM_MAP" ]] || { echo "ERROR: stream map missing: $STREAM_MAP" >&2; exit 6; }
[[ -s "$STDCELL_GDS" ]] || { echo "ERROR: JIHD GDS missing: $STDCELL_GDS" >&2; exit 6; }

export SPADMIC_PG_FIX_SOURCE_CHECKPOINT="$CHECKPOINT"
export SPADMIC_PG_FIX_TOP=spadmic_tx_ddr_strip
export SPADMIC_PG_FIX_BLOCK="$BLOCK"
export SPADMIC_PG_FIX_STRIPE_WIDTH_UM="${SPADMIC_PG_FIX_STRIPE_WIDTH_UM:-3.360}"
export SPADMIC_PG_FIX_VDD_X_FALLBACK_UM="${SPADMIC_PG_FIX_VDD_X_FALLBACK_UM:-858.480}"
export SPADMIC_PG_FIX_VSS_X_FALLBACK_UM="${SPADMIC_PG_FIX_VSS_X_FALLBACK_UM:-2574.880}"
export SPADMIC_PG_FIX_VDD_Y0_UM="${SPADMIC_PG_FIX_VDD_Y0_UM:-10.080}"
export SPADMIC_PG_FIX_VSS_Y0_UM="${SPADMIC_PG_FIX_VSS_Y0_UM:-14.560}"
export SPADMIC_PG_FIX_Y1_UM="${SPADMIC_PG_FIX_Y1_UM:-180.880}"
export SPADMIC_PG_FIX_EXPECTED_CORE_BOX="${SPADMIC_PG_FIX_EXPECTED_CORE_BOX:-10.080 10.080 3423.280 170.800}"
export SPADMIC_PG_FIX_EXPECTED_DIE_BOX="${SPADMIC_PG_FIX_EXPECTED_DIE_BOX:-0.000 0.000 3433.360 180.880}"
export SPADMIC_PG_FIX_VDD_HELPER_CANDIDATES_UM="${SPADMIC_PG_FIX_VDD_HELPER_CANDIDATES_UM:-970.480 746.480 1082.480 634.480 1194.480 522.480 1306.480 410.480 1418.480 298.480}"
export SPADMIC_PG_FIX_VDD_HELPER_Y0_UM="${SPADMIC_PG_FIX_VDD_HELPER_Y0_UM:-126.560}"
export SPADMIC_PG_FIX_VDD_HELPER_Y1_UM="${SPADMIC_PG_FIX_VDD_HELPER_Y1_UM:-153.440}"
export SPADMIC_PG_FIX_VDD_HELPER_AREA_HALF_WIDTH_UM="${SPADMIC_PG_FIX_VDD_HELPER_AREA_HALF_WIDTH_UM:-5.600}"
export SPADMIC_STREAMOUT_MAP_FILE="$STREAM_MAP"
export SPADMIC_PG_FIX_STDCELL_GDS="$STDCELL_GDS"

CANDIDATE_SUMMARY="$RUN_ROOT/reports/vdd_helper_candidate_summary.tsv"
export SPADMIC_PG_FIX_CANDIDATE_REPORT="$CANDIDATE_SUMMARY"

{
  echo "RUN_ID=$RUN_ID"
  echo "SOURCE_BLOCK_ROOT=$SOURCE_BLOCK_ROOT"
  echo "SOURCE_CHECKPOINT=$CHECKPOINT"
  echo "BLOCK=$BLOCK"
  echo "HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
  echo "PHASE=P02_R4"
  echo "POLICY=RESTORE_P01_EXPLICIT_PG_GEOMETRY_LOCAL_VDD_HELPER_NO_SIGNAL_ROUTE"
  echo "PROCESS_ISOLATION=ONE_INNOVUS_PROCESS_PER_CANDIDATE"
  echo "CANDIDATES_UM=$SPADMIC_PG_FIX_VDD_HELPER_CANDIDATES_UM"
  echo "STREAM_MAP=$STREAM_MAP"
  echo "STDCELL_GDS=$STDCELL_GDS"
} >"$RUN_ROOT/run_manifest.rpt"

report_value() {
  local report="$1"
  local key="$2"
  if [[ ! -r "$report" ]]; then
    printf '%s\n' MISSING
    return
  fi
  awk -F= -v key="$key" '$1 == key {sub(/^[^=]*=/, ""); print; found=1; exit} END {if (!found) print "MISSING"}' "$report"
}

printf 'trial\tx_um\tinnovus_rc\tstatus\tresult\tpg_violations\tpg_markers\tregular_violations\tdrc_violations\ttrial_root\tverdict\n' \
  >"$CANDIDATE_SUMMARY"

TRIAL=0
SELECTED_X=""
SELECTED_TRIAL=NONE

for CANDIDATE_X in $SPADMIC_PG_FIX_VDD_HELPER_CANDIDATES_UM; do
  TRIAL=$((TRIAL + 1))
  if [[ ! "$CANDIDATE_X" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    printf '%s\t%s\tNOT_RUN\tFAIL\tINVALID_CANDIDATE\tUNKNOWN\tUNKNOWN\tUNKNOWN\tUNKNOWN\tNONE\tREJECT\n' \
      "$TRIAL" "$CANDIDATE_X" >>"$CANDIDATE_SUMMARY"
    continue
  fi

  CANDIDATE_TAG="${CANDIDATE_X//./p}"
  TRIAL_ROOT=$(printf '%s/trials/trial_%02d_x_%s' "$RUN_ROOT" "$TRIAL" "$CANDIDATE_TAG")
  mkdir -p "$TRIAL_ROOT"/{checkpoints,logs,outputs,reports}
  echo "PG_HELPER_TRIAL_START=$TRIAL X_UM=$CANDIDATE_X ROOT=$TRIAL_ROOT"

  export SPADMIC_PG_FIX_RUN_ROOT="$TRIAL_ROOT"
  export SPADMIC_PG_FIX_VDD_HELPER_X_UM="$CANDIDATE_X"
  export SPADMIC_PG_FIX_TRIAL_MODE=1

  innovus -nowin -init "$SCRIPT_DIR/run_innovus_ooc_pg_geometry_fix.tcl" \
    -log "$TRIAL_ROOT/logs/innovus.log" \
    >"$TRIAL_ROOT/logs/innovus.stdout.log" 2>&1
  TRIAL_RC=$?

  TRIAL_STATUS_REPORT="$TRIAL_ROOT/reports/pg_geometry_fix_status.rpt"
  TRIAL_STATUS=$(report_value "$TRIAL_STATUS_REPORT" STATUS)
  TRIAL_RESULT=$(report_value "$TRIAL_STATUS_REPORT" RESULT)
  TRIAL_PG=$(report_value "$TRIAL_STATUS_REPORT" PG_CONNECTIVITY_VIOLATION_COUNT)
  TRIAL_MARKERS=$(report_value "$TRIAL_STATUS_REPORT" PG_MARKER_COUNT)
  TRIAL_REGULAR=$(report_value "$TRIAL_STATUS_REPORT" REGULAR_CONNECTIVITY_VIOLATION_COUNT)
  TRIAL_DRC=$(report_value "$TRIAL_STATUS_REPORT" DRC_MARKER_TOTAL)
  VERDICT=REJECT

  if [[ "$TRIAL_RC" -eq 0 && "$TRIAL_STATUS" == "PASS" &&
        "$TRIAL_RESULT" == "PG_HELPER_CANDIDATE_CLEAN" &&
        "$TRIAL_PG" == "0" && "$TRIAL_MARKERS" == "0" &&
        "$TRIAL_REGULAR" == "0" &&
        "$TRIAL_DRC" == "0" ]]; then
    VERDICT=ACCEPT_FOR_CANONICAL_REPLAY
    SELECTED_X="$CANDIDATE_X"
    SELECTED_TRIAL="$TRIAL"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$TRIAL" "$CANDIDATE_X" "$TRIAL_RC" "$TRIAL_STATUS" "$TRIAL_RESULT" \
    "$TRIAL_PG" "$TRIAL_MARKERS" "$TRIAL_REGULAR" "$TRIAL_DRC" \
    "$TRIAL_ROOT" "$VERDICT" \
    >>"$CANDIDATE_SUMMARY"
  echo "PG_HELPER_TRIAL_RESULT=$TRIAL RC=$TRIAL_RC PG=$TRIAL_PG MARKERS=$TRIAL_MARKERS REGULAR=$TRIAL_REGULAR DRC=$TRIAL_DRC VERDICT=$VERDICT"

  if [[ -n "$SELECTED_X" ]]; then
    break
  fi
done

if [[ -z "$SELECTED_X" ]]; then
  {
    echo "LABEL=SPADMIC_OOC_PG_GEOMETRY_FIX"
    echo "PHASE=P02_R4"
    echo "POLICY=RESTORE_P01_EXPLICIT_PG_GEOMETRY_LOCAL_VDD_HELPER_NO_SIGNAL_ROUTE"
    echo "PROCESS_ISOLATION=ONE_INNOVUS_PROCESS_PER_CANDIDATE"
    echo "VDD_HELPER_CANDIDATE_REPORT=$CANDIDATE_SUMMARY"
    echo "VDD_HELPER_SELECTED_X_UM=NONE"
    echo "CANONICAL_REPLAY=NOT_RUN"
    echo "INTERNAL_PG_STATUS=FAIL"
    echo "SIGNOFF_READY=NO"
    echo "STATUS=FAIL"
    echo "RESULT=FAIL_NO_CLEAN_CANDIDATE"
  } >"$RUN_ROOT/reports/pg_geometry_fix_status.rpt"
  {
    echo "LABEL=SPADMIC_OOC_PG_GEOMETRY_FIX_WRAPPER"
    echo "PHASE=P02_R4"
    echo "PROCESS_ISOLATION=ONE_INNOVUS_PROCESS_PER_CANDIDATE"
    echo "VDD_HELPER_CANDIDATE_REPORT=$CANDIDATE_SUMMARY"
    echo "VDD_HELPER_SELECTED_TRIAL=NONE"
    echo "VDD_HELPER_SELECTED_X_UM=NONE"
    echo "CANONICAL_REPLAY=NOT_RUN"
    echo "CANONICAL_INNOVUS_RC=NOT_RUN"
    echo "GDS_AUDIT_RC=NOT_RUN"
    echo "STATUS=FAIL"
    echo "RESULT=FAIL_NO_CLEAN_CANDIDATE"
  } >"$RUN_ROOT/reports/pg_geometry_fix_wrapper_status.rpt"
  echo "PG_GEOMETRY_FIX_INNOVUS_RC=NOT_RUN_CANONICAL"
  echo "PG_GEOMETRY_FIX_GDS_AUDIT_RC=NOT_RUN"
  echo "PG_GEOMETRY_FIX_RC=8"
  echo "PG_GEOMETRY_FIX_ROOT=$RUN_ROOT"
  cat "$RUN_ROOT/reports/pg_geometry_fix_status.rpt"
  cat "$RUN_ROOT/reports/pg_geometry_fix_wrapper_status.rpt"
  exit 8
fi

export SPADMIC_PG_FIX_RUN_ROOT="$RUN_ROOT"
export SPADMIC_PG_FIX_VDD_HELPER_X_UM="$SELECTED_X"
export SPADMIC_PG_FIX_TRIAL_MODE=0
echo "PG_CANONICAL_REPLAY_START=TRIAL_$SELECTED_TRIAL X_UM=$SELECTED_X ROOT=$RUN_ROOT"

innovus -nowin -init "$SCRIPT_DIR/run_innovus_ooc_pg_geometry_fix.tcl" \
  -log "$RUN_ROOT/logs/innovus.log" \
  >"$RUN_ROOT/logs/innovus.stdout.log" 2>&1
INNOVUS_RC=$?

GDS_AUDIT_RC=NOT_RUN
if [[ "$INNOVUS_RC" -eq 0 && -s "$RUN_ROOT/outputs/$BLOCK.gds" ]]; then
  python3 "$SCRIPT_DIR/audit_innovus_gds_export.py" \
    --gds "$RUN_ROOT/outputs/$BLOCK.gds" \
    --log "$RUN_ROOT/logs/innovus.log" \
    --stream-map "$STREAM_MAP" \
    --required-merge "$STDCELL_GDS" \
    --status "$RUN_ROOT/reports/gds_export_audit.rpt"
  GDS_AUDIT_RC=$?
fi

FINAL_RC="$INNOVUS_RC"
WRAPPER_STATUS=FAIL
WRAPPER_RESULT=CANONICAL_REPLAY_FAILED
if [[ "$INNOVUS_RC" -eq 0 && "$GDS_AUDIT_RC" == "0" ]]; then
  FINAL_RC=0
  WRAPPER_STATUS=PASS
  WRAPPER_RESULT=PG_GEOMETRY_FIX_AND_GDS_AUDIT_PASS
elif [[ "$INNOVUS_RC" -eq 0 ]]; then
  FINAL_RC=8
  WRAPPER_RESULT=GDS_AUDIT_FAILED
fi

{
  echo "LABEL=SPADMIC_OOC_PG_GEOMETRY_FIX_WRAPPER"
  echo "PHASE=P02_R4"
  echo "PROCESS_ISOLATION=ONE_INNOVUS_PROCESS_PER_CANDIDATE"
  echo "VDD_HELPER_CANDIDATE_REPORT=$CANDIDATE_SUMMARY"
  echo "VDD_HELPER_SELECTED_TRIAL=$SELECTED_TRIAL"
  echo "VDD_HELPER_SELECTED_X_UM=$SELECTED_X"
  echo "CANONICAL_REPLAY=RUN"
  echo "CANONICAL_INNOVUS_RC=$INNOVUS_RC"
  echo "GDS_AUDIT_RC=$GDS_AUDIT_RC"
  echo "STATUS=$WRAPPER_STATUS"
  echo "RESULT=$WRAPPER_RESULT"
} >"$RUN_ROOT/reports/pg_geometry_fix_wrapper_status.rpt"

echo "PG_GEOMETRY_FIX_INNOVUS_RC=$INNOVUS_RC"
echo "PG_GEOMETRY_FIX_GDS_AUDIT_RC=$GDS_AUDIT_RC"
echo "PG_GEOMETRY_FIX_RC=$FINAL_RC"
echo "PG_GEOMETRY_FIX_ROOT=$RUN_ROOT"
cat "$RUN_ROOT/reports/pg_geometry_fix_status.rpt" 2>/dev/null || echo "MISSING STATUS"
cat "$RUN_ROOT/reports/pg_geometry_fix_wrapper_status.rpt"
exit "$FINAL_RC"
