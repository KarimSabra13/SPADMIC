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
STREAM_MAP="${MPTDC_PVS_STREAM_MAP:-}"

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
  --stream-map <path>          Optional streamOut map for generated fallback.
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
      shift 2
      ;;
    --stream-map)
      STREAM_MAP="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --stream-map value}")"
      shift 2
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
if [[ -f "$STREAMOUT_TEMPLATE" ]]; then
  cp -p "$STREAMOUT_TEMPLATE" "$PATCHED_STREAMOUT"
  mptdc_pvs_patch_file_paths "$PATCHED_STREAMOUT" \
    "$OLD_PROOF_CKPT=$SOURCE_CHECKPOINT" \
    "$DEFAULT_OLD_BASE/merge_libs/RO_tune6_from_OA.gds=$RO_GDS" \
    "$OLD_PROOF_BASE=$RESULT_DIR" \
    "$OLD_BASE=$RESULT_DIR" \
    "$DEFAULT_DCELL_GDS=$DCELL_GDS" \
    "$DEFAULT_DCELL_CDL=$DCELL_CDL"
  mptdc_pvs_fail_if_contains_old_path "streamout old proof checkpoint" "$OLD_PROOF_CKPT" "$PATCHED_STREAMOUT"
  mptdc_pvs_fail_if_contains_old_path "streamout old proof base" "$OLD_PROOF_BASE" "$PATCHED_STREAMOUT"
  mptdc_pvs_fail_if_contains_old_path "streamout old base" "$OLD_BASE" "$PATCHED_STREAMOUT"
fi

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
  if {$rc} { error $err }
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
  set ::env(OUT_DIR) $output_dir
  set ::env(OUTPUT_DIR) $output_dir
  set ::env(RESULT_DIR) [file dirname $output_dir]
  set ::env(WORK_DIR) [file dirname $patched_streamout]
  set ::env(TOP_CELL) $top_cell
  set ::env(TOP_ONLY_GDS) $top_only_gds
  set ::env(MERGED_GDS) $merged_gds
  set ::env(PLAIN_V) $plain_v
  set ::env(PG_V) $pg_v
  set ::env(PHYS_PG_V) $phys_pg_v
  set ::env(DCELL_GDS) $dcell_gds
  set ::env(RO_GDS) $ro_gds
  mptdc_pvs_try source_streamout [list source $patched_streamout]
} elseif {[info exists ::env(MPTDC_PVS_ALLOW_GENERATED_STREAMOUT)] && $::env(MPTDC_PVS_ALLOW_GENERATED_STREAMOUT)} {
  set args [list $top_only_gds -libName DesignLib -units 1000 -mode ALL]
  if {$stream_map ne ""} { lappend args -mapFile $stream_map }
  mptdc_pvs_try streamOut_top_only [concat [list streamOut] $args]
  set merge_args [list $merged_gds -libName DesignLib -units 1000 -mode ALL -merge [list $dcell_gds $ro_gds]]
  if {$stream_map ne ""} { lappend merge_args -mapFile $stream_map }
  mptdc_pvs_try streamOut_merged [concat [list streamOut] $merge_args]
} else {
  error "No streamout template and generated streamout disabled"
}
TCL
} > "$GENERATED_TCL"

if ! command -v innovus >/dev/null 2>&1; then
  mptdc_pvs_die "innovus not found in PATH; run this on the server after sourcing Cadence"
fi

(
  cd "$REPO_ROOT"
  innovus -nowin -init "$GENERATED_TCL" -log "$LOG_DIR/innovus_prepare_pvs_inputs.log"
) 2>&1 | tee -a "$RUN_LOG"
INNOVUS_RC=${PIPESTATUS[0]}
echo "INNOVUS_RC=$INNOVUS_RC" | tee -a "$RUN_LOG"
[[ "$INNOVUS_RC" -eq 0 ]] || exit "$INNOVUS_RC"

if [[ ! -s "$TOP_ONLY_GDS" ]]; then
  echo "WARN: optional top-only GDS was not produced or is empty: $TOP_ONLY_GDS" | tee -a "$RUN_LOG"
fi
mptdc_pvs_require_file "$MERGED_GDS"
mptdc_pvs_require_file "$PG_V"
"$SCRIPT_DIR/01_generate_lvs_source_pg_filtered.py" \
  --input "$PG_V" \
  --output "$FILTERED_V" \
  --hcell "$HCELL" \
  --report "$FILTER_REPORT"

{
  echo "# MPTDC PVS Prepared Inputs"
  echo "PVS_PREP_INPUT_STATUS=PASS"
  echo "RESULT_DIR=$RESULT_DIR"
  echo "TOP_ONLY_GDS=$TOP_ONLY_GDS"
  echo "MERGED_GDS=$MERGED_GDS"
  echo "LVS_SOURCE_PG=$PG_V"
  echo "LVS_SOURCE_FILTERED=$FILTERED_V"
  echo "PVS_HCELL=$HCELL"
  echo "DCELL_CDL=$DCELL_CDL"
  echo "DCELL_GDS=$DCELL_GDS"
  echo "ORIGINAL_RO_GDS=$ORIGINAL_RO_GDS"
  echo "RO_GDS=$RO_GDS"
  echo "FILTER_REPORT=$FILTER_REPORT"
} | tee "$REPORT_DIR/pvs_prepared_inputs.rpt"
