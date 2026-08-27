#!/usr/bin/env bash
# Restore an Innovus checkpoint and prepare merged-GDS/LVS inputs for PVS replay.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=MPTDC/scripts/pvs/lib_pvs_common.sh
source "$SCRIPT_DIR/lib_pvs_common.sh"

REPO_ROOT="$(mptdc_pvs_repo_root)"
DEFAULT_INNOVUS_WORK="/sim/ksabra/SPADMIC_work/innovus"
DEFAULT_OLD_BASE="/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_falsepath_nfast_risk_235618/drygds_oa_20260702_001608"
DEFAULT_OLD_PROOF="/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_falsepath_nfast_risk_235618/drygds_pvs_pg_short_proof_20260702_151108"
DEFAULT_OLD_PROOF_CKPT="/sim/ksabra/SPADMIC_work/innovus/20260702_mptdc_pvs_pg_short_surgical_proof_145940/checkpoints/repaired_route.enc.dat"
DEFAULT_DCELL_GDS="/data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/gds/xh018_D_CELLS_JIHD.gds"
DEFAULT_DCELL_CDL="/data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/cdl/xh018_D_CELLS_JIHD.cdl"
DEFAULT_STREAM_MAP="/data/pdk/xfab/xh018/cadence/v10_1/PDK/IC61/v10_1_1/TECH_XH018_1131/pnr_streamout.map"

SOURCE_CHECKPOINT=""
RUN_ID=""
RESULT_DIR=""
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"
INNOVUS_WORK="${MPTDC_INNOVUS_WORK:-$DEFAULT_INNOVUS_WORK}"
TOP_CELL="${MPTDC_PVS_TOP_CELL:-mptdc_axis_core}"
OLD_BASE="${MPTDC_PVS_OLD_BASE:-$DEFAULT_OLD_BASE}"
OLD_PROOF_BASE="${MPTDC_PVS_OLD_PROOF_BASE:-$DEFAULT_OLD_PROOF}"
OLD_PROOF_CKPT="${MPTDC_PVS_OLD_PROOF_CKPT:-$DEFAULT_OLD_PROOF_CKPT}"
STREAMOUT_TEMPLATE="${MPTDC_PVS_STREAMOUT_TEMPLATE:-$DEFAULT_OLD_BASE/work/streamout_mptdc_merged_ro6.tcl}"
DCELL_GDS="${MPTDC_PVS_DCELL_GDS:-$DEFAULT_DCELL_GDS}"
DCELL_CDL="${MPTDC_PVS_DCELL_CDL:-$DEFAULT_DCELL_CDL}"
RO_GDS="${MPTDC_PVS_RO_GDS:-$DEFAULT_OLD_BASE/merge_libs/RO_tune6_from_OA.gds}"
ALLOW_GENERATED_STREAMOUT="${MPTDC_PVS_ALLOW_GENERATED_STREAMOUT:-0}"
STREAM_MAP="${MPTDC_PVS_STREAM_MAP:-$DEFAULT_STREAM_MAP}"
STRICT_ATTRIBUTION="${MPTDC_PVS_STRICT_ATTRIBUTION:-0}"
RO_GDS_EXPLICIT=0

usage() {
  cat <<'USAGE'
Usage:
  00_prepare_pvs_inputs_from_checkpoint.sh --checkpoint <enc.dat> [options]

Options:
  --checkpoint <path>          Innovus checkpoint to restore.
  --run-id <id>                Result directory name under --innovus-work.
  --result-dir <path>          Explicit result directory.
  --expected-head <sha>        Require repository HEAD to match this commit.
  --innovus-work <path>        Innovus work root. Default: /sim/ksabra/SPADMIC_work/innovus.
  --top-cell <name>            Top cell. Default: mptdc_axis_core.
  --streamout-template <path>  Previous working streamout Tcl template.
  --old-base <path>            Old dryGDS base path to replace in the template.
  --old-proof-base <path>      Old proof dryGDS base path to replace.
  --dcell-gds <path>           D_CELLS GDS merged into layout.
  --dcell-cdl <path>           D_CELLS CDL used by PVS LVS.
  --ro-gds <path>              RO_tune6 GDS merged into layout.
  --stream-map <path>          Official streamOut map. Defaults to XH018_1131.
  --strict-attribution         Require an explicitly supplied RO GDS and write
                               fail-closed pin/hash attribution evidence.
  -h, --help                   Show this help.

Default behavior replays a known-good streamout Tcl template after patching
absolute paths to the new checkpoint and result directory. Set
MPTDC_PVS_ALLOW_GENERATED_STREAMOUT=1 only if the template is unavailable and
the Innovus streamOut syntax in the generated fallback is acceptable locally.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --checkpoint)
      SOURCE_CHECKPOINT="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --checkpoint value}")"
      shift 2
      ;;
    --run-id)
      RUN_ID="${2:?missing --run-id value}"
      shift 2
      ;;
    --result-dir)
      RESULT_DIR="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --result-dir value}")"
      shift 2
      ;;
    --expected-head)
      EXPECTED_HEAD_VALUE="${2:?missing --expected-head value}"
      shift 2
      ;;
    --innovus-work)
      INNOVUS_WORK="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --innovus-work value}")"
      shift 2
      ;;
    --top-cell)
      TOP_CELL="${2:?missing --top-cell value}"
      shift 2
      ;;
    --streamout-template)
      STREAMOUT_TEMPLATE="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --streamout-template value}")"
      shift 2
      ;;
    --old-base)
      OLD_BASE="${2:?missing --old-base value}"
      shift 2
      ;;
    --old-proof-base)
      OLD_PROOF_BASE="${2:?missing --old-proof-base value}"
      shift 2
      ;;
    --dcell-gds)
      DCELL_GDS="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --dcell-gds value}")"
      shift 2
      ;;
    --dcell-cdl)
      DCELL_CDL="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --dcell-cdl value}")"
      shift 2
      ;;
    --ro-gds)
      RO_GDS="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --ro-gds value}")"
      RO_GDS_EXPLICIT=1
      shift 2
      ;;
    --stream-map)
      STREAM_MAP="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --stream-map value}")"
      shift 2
      ;;
    --strict-attribution)
      STRICT_ATTRIBUTION=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[[ -n "$SOURCE_CHECKPOINT" ]] || { usage >&2; mptdc_pvs_die "--checkpoint is required"; }
RUN_ID="${RUN_ID:-20260707_mptdc_pvs_inputs_from_checkpoint_$(date +%Y%m%d_%H%M%S)}"
RESULT_DIR="${RESULT_DIR:-$INNOVUS_WORK/$RUN_ID}"

cd "$REPO_ROOT"
mptdc_pvs_check_git_head "$REPO_ROOT" "$EXPECTED_HEAD_VALUE"
mptdc_pvs_require_clean_tracked_tree "$REPO_ROOT"
mptdc_pvs_require_dir "$SOURCE_CHECKPOINT"
mptdc_pvs_require_file "$DCELL_GDS"
mptdc_pvs_require_file "$DCELL_CDL"
mptdc_pvs_require_file "$RO_GDS"
mptdc_pvs_require_file "$STREAM_MAP"

if [[ "$STRICT_ATTRIBUTION" == "1" && "$RO_GDS_EXPLICIT" != "1" ]]; then
  mptdc_pvs_die "--strict-attribution requires an explicit --ro-gds exported from the current RO_tune6 OA layout"
fi

if [[ -e "$RESULT_DIR" ]]; then
  mptdc_pvs_die "result directory already exists: $RESULT_DIR"
fi

if [[ ! -f "$STREAMOUT_TEMPLATE" && "$ALLOW_GENERATED_STREAMOUT" != "1" ]]; then
  mptdc_pvs_die "streamout template not found: $STREAMOUT_TEMPLATE (or set MPTDC_PVS_ALLOW_GENERATED_STREAMOUT=1)"
fi

mkdir -p "$RESULT_DIR"/{work,outputs,reports,logs,manifests,pvs_drc,pvs_lvs}
WORK_DIR="$RESULT_DIR/work"
OUTPUT_DIR="$RESULT_DIR/outputs"
REPORT_DIR="$RESULT_DIR/reports"
MANIFEST_DIR="$RESULT_DIR/manifests"
LOG_DIR="$RESULT_DIR/logs"
RUN_LOG="$LOG_DIR/prepare_pvs_inputs.log"
MERGE_LIB_DIR="$RESULT_DIR/merge_libs"
mkdir -p "$MERGE_LIB_DIR"
ORIGINAL_RO_GDS="$RO_GDS"
LOCAL_RO_GDS="$MERGE_LIB_DIR/$(basename "$RO_GDS")"
cp -p "$RO_GDS" "$LOCAL_RO_GDS"
RO_GDS="$LOCAL_RO_GDS"

TOP_ONLY_GDS="$OUTPUT_DIR/${TOP_CELL}_top_only.gds"
MERGED_GDS="$OUTPUT_DIR/${TOP_CELL}_merged_stdcell_ro6.gds"
PLAIN_V="$OUTPUT_DIR/${TOP_CELL}_pnr_lvs_plain_retry.v"
PG_V="$OUTPUT_DIR/${TOP_CELL}_pnr_lvs_with_pg.v"
PHYS_PG_V="$OUTPUT_DIR/${TOP_CELL}_pnr_lvs_phys_with_pg.v"
FILTERED_V="$OUTPUT_DIR/${TOP_CELL}_pnr_lvs_with_pg_NO_DCELL_MODULES_RO6_PINFIX_NOATTR_CLEAN.v"
HCELL="$OUTPUT_DIR/pvs_hcell_ro6.txt"
FILTER_REPORT="$REPORT_DIR/lvs_source_filter.rpt"
FINAL_DEF="$OUTPUT_DIR/${TOP_CELL}.def"

{
  echo "# MPTDC PVS Input Preparation"
  echo "date: $(date -Iseconds)"
  echo "repo: $REPO_ROOT"
  echo "head: $(git rev-parse HEAD)"
  echo "run_id: $RUN_ID"
  echo "result_dir: $RESULT_DIR"
  echo "source_checkpoint: $SOURCE_CHECKPOINT"
  echo "top_cell: $TOP_CELL"
  echo "streamout_template: $STREAMOUT_TEMPLATE"
  echo "old_base: $OLD_BASE"
  echo "old_proof_base: $OLD_PROOF_BASE"
  echo "dcell_gds: $DCELL_GDS"
  echo "dcell_cdl: $DCELL_CDL"
  echo "original_ro_gds: $ORIGINAL_RO_GDS"
  echo "local_ro_gds: $RO_GDS"
  echo "stream_map: $STREAM_MAP"
  echo "strict_attribution: $STRICT_ATTRIBUTION"
  echo "top_only_gds: $TOP_ONLY_GDS"
  echo "merged_gds: $MERGED_GDS"
  echo "pg_verilog: $PG_V"
  echo "filtered_verilog: $FILTERED_V"
  echo "hcell: $HCELL"
  echo
  echo "git status --short --untracked-files=no:"
  git status --short --untracked-files=no
} | tee "$MANIFEST_DIR/pvs_input_manifest.txt" | tee "$RUN_LOG"

PATCHED_STREAMOUT="$WORK_DIR/streamout_mptdc_merged_ro6.replayed.tcl"
STREAM_MAP_BINDING_REPORT="$REPORT_DIR/streamout_map_binding.rpt"
STREAM_MAP_BINDING_MODE="GENERATED_STREAMOUT"
if [[ -f "$STREAMOUT_TEMPLATE" ]]; then
  cp -p "$STREAMOUT_TEMPLATE" "$PATCHED_STREAMOUT"
  mptdc_pvs_patch_file_paths "$PATCHED_STREAMOUT" \
    "$OLD_PROOF_CKPT=$SOURCE_CHECKPOINT" \
    "$DEFAULT_OLD_BASE/merge_libs/RO_tune6_from_OA.gds=$RO_GDS" \
    "$DEFAULT_STREAM_MAP=$STREAM_MAP" \
    "$OLD_PROOF_BASE=$RESULT_DIR" \
    "$OLD_BASE=$RESULT_DIR" \
    "$DEFAULT_DCELL_GDS=$DCELL_GDS" \
    "$DEFAULT_DCELL_CDL=$DCELL_CDL"
  mptdc_pvs_fail_if_contains_old_path "streamout old proof checkpoint" "$OLD_PROOF_CKPT" "$PATCHED_STREAMOUT"
  mptdc_pvs_fail_if_contains_old_path "streamout old proof base" "$OLD_PROOF_BASE" "$PATCHED_STREAMOUT"
  mptdc_pvs_fail_if_contains_old_path "streamout old base" "$OLD_BASE" "$PATCHED_STREAMOUT"
  if ! STREAM_MAP_BINDING_MODE="$(mptdc_pvs_streamout_map_binding_mode "$PATCHED_STREAMOUT" "$STREAM_MAP")"; then
    mptdc_pvs_die "streamout template does not bind -mapFile to the selected map or ::env(STREAM_MAP): $PATCHED_STREAMOUT"
  fi
fi

{
  echo "# MPTDC streamout map binding"
  echo "STREAMOUT_TEMPLATE=$STREAMOUT_TEMPLATE"
  echo "PATCHED_STREAMOUT=$PATCHED_STREAMOUT"
  echo "SELECTED_STREAM_MAP=$STREAM_MAP"
  echo "STREAM_MAP_BINDING_MODE=$STREAM_MAP_BINDING_MODE"
  echo "STREAM_MAP_BINDING_STATUS=PASS"
} | tee "$STREAM_MAP_BINDING_REPORT" | tee -a "$RUN_LOG"

GENERATED_TCL="$WORK_DIR/prepare_pvs_inputs.tcl"
{
  printf 'set checkpoint {%s}\n' "$SOURCE_CHECKPOINT"
  printf 'set top_cell {%s}\n' "$TOP_CELL"
  printf 'set output_dir {%s}\n' "$OUTPUT_DIR"
  printf 'set top_only_gds {%s}\n' "$TOP_ONLY_GDS"
  printf 'set merged_gds {%s}\n' "$MERGED_GDS"
  printf 'set plain_v {%s}\n' "$PLAIN_V"
  printf 'set pg_v {%s}\n' "$PG_V"
  printf 'set phys_pg_v {%s}\n' "$PHYS_PG_V"
  printf 'set dcell_gds {%s}\n' "$DCELL_GDS"
  printf 'set ro_gds {%s}\n' "$RO_GDS"
  printf 'set patched_streamout {%s}\n' "$PATCHED_STREAMOUT"
  printf 'set stream_map {%s}\n' "$STREAM_MAP"
  cat <<'TCL'
proc mptdc_pvs_try {label cmd} {
  set rc [catch {uplevel #0 $cmd} err]
  puts "MPTDC_PVS_PREP_${label}_RC=$rc ERR=$err"
  if {$rc} {
    puts stderr "MPTDC_PVS_PREP_FATAL_LABEL=$label"
    puts stderr "MPTDC_PVS_PREP_FATAL_ERROR=$err"
    exit 1
  }
}

file mkdir $output_dir
mptdc_pvs_try restoreDesign [list restoreDesign $checkpoint $top_cell]
mptdc_pvs_try defOut [list defOut [file join $output_dir "${top_cell}.def"]]
mptdc_pvs_try saveNetlist_plain [list saveNetlist $plain_v]
mptdc_pvs_try saveNetlist_pg [list saveNetlist -includePowerGround $pg_v]
catch {saveNetlist -phys -includePowerGround $phys_pg_v} phys_err
puts "MPTDC_PVS_PREP_saveNetlist_phys_pg_ERR=$phys_err"

if {[file exists $patched_streamout]} {
  puts "MPTDC_PVS_PREP_STREAMOUT_TEMPLATE=$patched_streamout"
  set result_dir [file dirname $output_dir]
  set ::env(OUT_DIR) $result_dir
  set ::env(OUTPUT_DIR) $output_dir
  set ::env(RESULT_DIR) $result_dir
  set ::env(WORK_DIR) [file dirname $patched_streamout]
  set ::env(CHK_DAT) $checkpoint
  set ::env(CKPT) $checkpoint
  set ::env(CHECKPOINT) $checkpoint
  set ::env(SOURCE_CHECKPOINT) $checkpoint
  set ::env(TOP_CELL) $top_cell
  set ::env(TOP_ONLY_GDS) $top_only_gds
  set ::env(MERGED_GDS) $merged_gds
  set ::env(PLAIN_V) $plain_v
  set ::env(PG_V) $pg_v
  set ::env(PHYS_PG_V) $phys_pg_v
  set ::env(DCELL_GDS) $dcell_gds
  set ::env(STD_GDS) $dcell_gds
  set ::env(RO_GDS) $ro_gds
  set ::env(STREAM_MAP) $stream_map
  set ::mptdc_pvs_template_restore_skip_count 0
  rename restoreDesign mptdc_pvs_saved_restoreDesign
  proc restoreDesign {args} {
    incr ::mptdc_pvs_template_restore_skip_count
    puts "MPTDC_PVS_PREP_TEMPLATE_RESTORE_SKIPPED_ARGS=$args"
    return 3
  }
  set source_rc [catch {source $patched_streamout} source_err]
  rename restoreDesign {}
  rename mptdc_pvs_saved_restoreDesign restoreDesign
  puts "MPTDC_PVS_PREP_source_streamout_RC=$source_rc ERR=$source_err"
  puts "MPTDC_PVS_PREP_TEMPLATE_RESTORE_SKIP_COUNT=$::mptdc_pvs_template_restore_skip_count"
  if {$source_rc} {
    puts stderr "MPTDC_PVS_PREP_FATAL_LABEL=source_streamout"
    puts stderr "MPTDC_PVS_PREP_FATAL_ERROR=$source_err"
    exit 1
  }
  if {$::mptdc_pvs_template_restore_skip_count > 1} {
    puts stderr "MPTDC_PVS_PREP_FATAL_LABEL=template_restore_guard"
    puts stderr "MPTDC_PVS_PREP_FATAL_ERROR=legacy template attempted more than one restore"
    exit 1
  }
  puts "MPTDC_PVS_PREP_TEMPLATE_RESTORE_GUARD_STATUS=PASS"
} elseif {[info exists ::env(MPTDC_PVS_ALLOW_GENERATED_STREAMOUT)] && $::env(MPTDC_PVS_ALLOW_GENERATED_STREAMOUT)} {
  set args [list $top_only_gds -libName DesignLib -units 1000 -mode ALL]
  if {$stream_map ne ""} { lappend args -mapFile $stream_map }
  mptdc_pvs_try streamOut_top_only [concat [list streamOut] $args]
  set merge_args [list $merged_gds -libName DesignLib -units 1000 -mode ALL -merge [list $dcell_gds $ro_gds]]
  if {$stream_map ne ""} { lappend merge_args -mapFile $stream_map }
  mptdc_pvs_try streamOut_merged [concat [list streamOut] $merge_args]
} else {
  puts stderr "MPTDC_PVS_PREP_FATAL_LABEL=streamout_selection"
  puts stderr "MPTDC_PVS_PREP_FATAL_ERROR=No streamout template and generated streamout disabled"
  exit 1
}
puts "MPTDC_PVS_PREP_BATCH_STATUS=PASS"
exit 0
TCL
} > "$GENERATED_TCL"

if ! command -v innovus >/dev/null 2>&1; then
  mptdc_pvs_die "innovus not found in PATH; run this on the server after sourcing Cadence"
fi

set +e
(
  cd "$REPO_ROOT"
  innovus -nowin -init "$GENERATED_TCL" -log "$LOG_DIR/innovus_prepare_pvs_inputs.log" </dev/null
) 2>&1 | tee -a "$RUN_LOG"
INNOVUS_RC=${PIPESTATUS[0]}
set -e
echo "INNOVUS_RC=$INNOVUS_RC" | tee -a "$RUN_LOG"
[[ "$INNOVUS_RC" -eq 0 ]] || exit "$INNOVUS_RC"

if [[ ! -s "$TOP_ONLY_GDS" ]]; then
  echo "WARN: optional top-only GDS was not produced or is empty: $TOP_ONLY_GDS" | tee -a "$RUN_LOG"
fi
mptdc_pvs_require_file "$MERGED_GDS"
mptdc_pvs_require_file "$PG_V"
mptdc_pvs_require_file "$PHYS_PG_V"
mptdc_pvs_require_file "$FINAL_DEF"
"$SCRIPT_DIR/01_generate_lvs_source_pg_filtered.py" \
  --input "$PHYS_PG_V" \
  --output "$FILTERED_V" \
  --hcell "$HCELL" \
  --report "$FILTER_REPORT" \
  --cdl "$DCELL_CDL" \
  --top "$TOP_CELL" \
  --expected-ro-instance-count 2 \
  --expected-ro-instance u_core_u_osc_fast_u_ro_tune4 \
  --expected-ro-instance u_core_u_osc_slow_u_ro_tune4

TAP_PIN_REPORT="$REPORT_DIR/tap_pin_contract.rpt"
{
  echo "# MPTDC final DEF tap-pin contract"
  echo "DEF=$FINAL_DEF"
  tap_pin_status=PASS
  tap_pin_total="$(awk '
    /^PINS[[:space:]]/ {in_pins=1; next}
    /^END PINS/ {in_pins=0}
    in_pins && /^-[[:space:]]/ && $2 ~ /^ro_(slow|fast)_tap[0-9]+_o$/ {count++}
    END {print count + 0}
  ' "$FINAL_DEF")"
  echo "RO_TAP_OBSERVABILITY_PIN_COUNT=$tap_pin_total"
  if [[ "$tap_pin_total" != "2" ]]; then
    tap_pin_status=FAIL
  fi
  for pin in ro_slow_tap0_o ro_fast_tap0_o; do
    record="$(awk -v wanted="$pin" '
      /^PINS[[:space:]]/ {in_pins=1; next}
      /^END PINS/ {in_pins=0}
      in_pins && /^-[[:space:]]/ {
        if (active) {print record}
        active=($2 == wanted)
        record=$0
        next
      }
      in_pins && active {record=record " " $0}
      END {if (active) print record}
    ' "$FINAL_DEF")"
    count="$(printf '%s\n' "$record" | sed '/^[[:space:]]*$/d' | wc -l)"
    direction_status=FAIL
    layer_status=FAIL
    [[ "$record" == *"+ DIRECTION OUTPUT"* ]] && direction_status=PASS
    [[ "$record" == *"+ LAYER MET3"* ]] && layer_status=PASS
    echo "${pin}_COUNT=$count"
    echo "${pin}_DIRECTION_STATUS=$direction_status"
    echo "${pin}_LAYER_STATUS=$layer_status"
    echo "${pin}_DEF_RECORD=$record"
    if [[ "$count" != "1" || "$direction_status" != "PASS" || "$layer_status" != "PASS" ]]; then
      tap_pin_status=FAIL
    fi
  done
  echo "TAP_PIN_CONTRACT_STATUS=$tap_pin_status"
} | tee "$TAP_PIN_REPORT"

grep -qx 'TAP_PIN_CONTRACT_STATUS=PASS' "$TAP_PIN_REPORT" || \
  mptdc_pvs_die "final DEF tap-pin contract failed: $TAP_PIN_REPORT"

HASH_MANIFEST="$MANIFEST_DIR/pvs_input_hashes.rpt"
{
  echo "# MPTDC immutable PVS input hashes"
  echo "GIT_HEAD=$(git rev-parse HEAD)"
  echo "TOP_CELL=$TOP_CELL"
  echo "SOURCE_CHECKPOINT=$SOURCE_CHECKPOINT"
  echo "STRICT_ATTRIBUTION=$STRICT_ATTRIBUTION"
} > "$HASH_MANIFEST"
mptdc_pvs_append_hash "$HASH_MANIFEST" MERGED_GDS "$MERGED_GDS"
if [[ -s "$TOP_ONLY_GDS" ]]; then
  mptdc_pvs_append_hash "$HASH_MANIFEST" TOP_ONLY_GDS "$TOP_ONLY_GDS"
fi
mptdc_pvs_append_hash "$HASH_MANIFEST" LVS_SOURCE_FILTERED "$FILTERED_V"
mptdc_pvs_append_hash "$HASH_MANIFEST" LVS_SOURCE_PHYSICAL_PG "$PHYS_PG_V"
mptdc_pvs_append_hash "$HASH_MANIFEST" LVS_HCELL "$HCELL"
mptdc_pvs_append_hash "$HASH_MANIFEST" DCELL_GDS "$DCELL_GDS"
mptdc_pvs_append_hash "$HASH_MANIFEST" DCELL_CDL "$DCELL_CDL"
mptdc_pvs_append_hash "$HASH_MANIFEST" ORIGINAL_RO_GDS "$ORIGINAL_RO_GDS"
mptdc_pvs_append_hash "$HASH_MANIFEST" RO_GDS "$RO_GDS"
mptdc_pvs_append_hash "$HASH_MANIFEST" STREAM_MAP "$STREAM_MAP"
if [[ -s "$PATCHED_STREAMOUT" ]]; then
  mptdc_pvs_append_hash "$HASH_MANIFEST" PATCHED_STREAMOUT "$PATCHED_STREAMOUT"
else
  echo "PATCHED_STREAMOUT_PATH=NOT_USED_GENERATED_STREAMOUT" >> "$HASH_MANIFEST"
fi
mptdc_pvs_append_hash "$HASH_MANIFEST" STREAM_MAP_BINDING_REPORT "$STREAM_MAP_BINDING_REPORT"
mptdc_pvs_append_hash "$HASH_MANIFEST" FINAL_DEF "$FINAL_DEF"
mptdc_pvs_append_hash "$HASH_MANIFEST" TAP_PIN_REPORT "$TAP_PIN_REPORT"

{
  echo "# MPTDC PVS Prepared Inputs"
  echo "PVS_PREP_INPUT_STATUS=PASS"
  echo "RESULT_DIR=$RESULT_DIR"
  echo "TOP_ONLY_GDS=$TOP_ONLY_GDS"
  echo "MERGED_GDS=$MERGED_GDS"
  echo "LVS_SOURCE_PG=$PG_V"
  echo "LVS_SOURCE_PHYSICAL_PG=$PHYS_PG_V"
  echo "LVS_SOURCE_FILTERED=$FILTERED_V"
  echo "PVS_HCELL=$HCELL"
  echo "DCELL_CDL=$DCELL_CDL"
  echo "DCELL_GDS=$DCELL_GDS"
  echo "ORIGINAL_RO_GDS=$ORIGINAL_RO_GDS"
  echo "RO_GDS=$RO_GDS"
  echo "FILTER_REPORT=$FILTER_REPORT"
  echo "STREAM_MAP_BINDING_REPORT=$STREAM_MAP_BINDING_REPORT"
  echo "STREAM_MAP_BINDING_MODE=$STREAM_MAP_BINDING_MODE"
  echo "TAP_PIN_REPORT=$TAP_PIN_REPORT"
  echo "INPUT_HASH_MANIFEST=$HASH_MANIFEST"
  echo "STRICT_ATTRIBUTION=$STRICT_ATTRIBUTION"
} | tee "$REPORT_DIR/pvs_prepared_inputs.rpt"
