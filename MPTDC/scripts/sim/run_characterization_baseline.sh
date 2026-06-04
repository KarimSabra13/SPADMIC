#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Purpose : Launch the maintained MPTDC RTL characterization baseline with a
#           stable directory layout, manifest, and optional downstream stages.
# Usage   : bash scripts/sim/run_characterization_baseline.sh [options]
#           --sim NAME            Simulator: verilator|xrun|xcelium (default verilator)
#           --jobs N              Parallel campaign jobs (default 12)
#           --seeds N             Seeds in the broad sweep campaign (default 30)
#           --n-conv N            Conversions per seed/job (default 100000)
#           --config NAME         Campaign config (default multihit_15_cal_nominal)
#           --out-mode NAME       raw_features (default raw_features;
#                                 legacy full/2 aliases are mapped to raw_features)
#           --nfast-encoding NAME legacy_binary_nfast|raw_lfsr_tag|raw_galois_tag
#           --freq-mode NAME      nominal|r750_delta5 RTL timing constants
#           --out-dir DIR         Root output dir (default results/characterization/baseline_nominal_raw_features)
#           --scratch-root DIR    Simulator build/work root for xrun/Verilator
#                                 (default $MPTDC_SIM_SCRATCH_ROOT when set)
#           --analyze             Run sweep analysis + fine-grid report, including
#                                 raw tuple histograms/code-density CSVs and plots
#           --analysis-jobs N     Python analysis worker budget (default 4;
#                                 streaming uses bounded sequential aggregation)
#           --analysis-chunksize N Rows per CSV chunk in low-memory analysis
#           --analysis-low-memory Use streaming analysis backend
#           --analysis-backend B  legacy|streaming (default legacy)
#           --log-memory          Log Python analysis RSS checkpoints
#           --calibrate           Run maintained 6D LUT calibration after collection,
#                                 including pre/post reconstruction error exports
#           --train-seeds N       Training seeds for calibration (default 24)
#           --train-max-rows-per-seed N
#                                 Bound calibration training rows per seed
#           --calibration-val-max-files N
#                                 Bound held-out validation files in calibration
#           --val-dir DIR         Explicit held-out validation directory for calibration
#           --fresh-dir DIR       Fresh validation dir for calibration
#           --with-fixed-delay    Run maintained fixed-delay characterization
#           --fixed-delay-list L  Fixed-delay list in ps
#           --fixed-delay-seeds N Seeds per fixed-delay point (default 6)
#           --fixed-delay-n-conv N Conversions per fixed-delay seed (default 2000)
#           --fixed-delay-jobs N  Parallel jobs for fixed-delay collection (default 8)
#           --jitter-sigma N      Override oscillator jitter sigma in ps
#           --jitter-bound N      Override oscillator jitter bound in ps
#           --rebuild             Forward --rebuild to the first campaign launch
#           --skip-campaign       Reuse existing campaign CSVs under --out-dir
#           --dry-run             Print commands without executing
#           --smoke               Shape-validation mode (small representative run)
# -----------------------------------------------------------------------------

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ORIGINAL_ARGS=("$@")

SIM="verilator"
JOBS=12
SEEDS=30
N_CONV=100000
CONFIG="multihit_15_cal_nominal"
OUT_MODE="raw_features"
NFAST_ENCODING="legacy_binary_nfast"
FAST_TAG_ENCODING="raw_lfsr_tag"
RTL_TAG_DEFINE_OR_PARAMETER="default:TAG_ENCODING_SEL=TAG_ENC_LFSR_FIBONACCI"
FREQ_MODE="${MPTDC_FREQ_MODE:-nominal}"
FREQ_RTL_DEFINE_OR_PARAMETER="default:OSC_TS_SLOW_PS=55,OSC_TS_FAST_PS=50"
OSC_TS_SLOW_PS=55
OSC_TS_FAST_PS=50
DELTA_STEP=5
DELTA_LSB=10
K_VERNIER=11
SCRATCH_ROOT="${MPTDC_SIM_SCRATCH_ROOT:-}"
OUT_DIR="$REPO_ROOT/results/characterization/baseline_nominal_raw_features"
ANALYZE=0
ANALYSIS_JOBS=4
ANALYSIS_CHUNKSIZE=200000
ANALYSIS_BACKEND="legacy"
ANALYSIS_LOW_MEMORY=0
ANALYSIS_LOG_MEMORY=0
CALIBRATE=0
TRAIN_SEEDS=24
TRAIN_MAX_ROWS_PER_SEED=""
CALIBRATION_VAL_MAX_FILES=""
VAL_DIR=""
FRESH_DIR="$REPO_ROOT/results/campaign_validation/multihit_15_cal_nominal"
FRESH_DIR_EXPLICIT=0
WITH_FIXED_DELAY=0
FIXED_DELAY_LIST="20,50,100,200,500,1000,2000,5000,10000,30000"
FIXED_DELAY_SEEDS=6
FIXED_DELAY_N_CONV=2000
FIXED_DELAY_JOBS=8
JITTER_SIGMA=""
JITTER_BOUND=""
REBUILD=0
SKIP_CAMPAIGN=0
DRY_RUN=0
SMOKE=0

usage() {
  sed -n '2,/^# -----------------------------------------------------------------------------$/{ /^# -----------------------------------------------------------------------------$/d; s/^# //; p }' "$0"
}

print_cmd() {
  local prefix="$1"
  shift
  printf '%s' "$prefix"
  for arg in "$@"; do
    printf ' %q' "$arg"
  done
  printf '\n'
}

render_cmd() {
  local parts=()
  for arg in "$@"; do
    parts+=("$(printf '%q' "$arg")")
  done
  local joined=""
  for arg in "${parts[@]}"; do
    if [[ -n "$joined" ]]; then
      joined+=" "
    fi
    joined+="$arg"
  done
  printf '%s' "$joined"
}

config_output_name() {
  local base_cfg="$1"
  local jsig="$2"
  local jb="$3"
  local name="$base_cfg"

  if [[ "$OUT_MODE" != "raw_features" ]]; then
    name+="_${OUT_MODE}"
  fi
  if [[ -n "$JITTER_SIGMA" || -n "$JITTER_BOUND" ]]; then
    name+="_js${jsig}_jb${jb}"
  fi
  printf '%s' "$name"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sim) SIM="$2"; shift 2 ;;
    --jobs) JOBS="$2"; shift 2 ;;
    --seeds) SEEDS="$2"; shift 2 ;;
    --n-conv) N_CONV="$2"; shift 2 ;;
    --config) CONFIG="$2"; shift 2 ;;
    --out-mode) OUT_MODE="$2"; shift 2 ;;
    --nfast-encoding) NFAST_ENCODING="$2"; shift 2 ;;
    --freq-mode) FREQ_MODE="$2"; shift 2 ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --scratch-root) SCRATCH_ROOT="$2"; shift 2 ;;
    --analyze) ANALYZE=1; shift ;;
    --analysis-jobs) ANALYSIS_JOBS="$2"; shift 2 ;;
    --analysis-chunksize|--chunksize) ANALYSIS_CHUNKSIZE="$2"; shift 2 ;;
    --analysis-low-memory) ANALYSIS_LOW_MEMORY=1; ANALYSIS_BACKEND="streaming"; shift ;;
    --analysis-backend) ANALYSIS_BACKEND="$2"; shift 2 ;;
    --log-memory) ANALYSIS_LOG_MEMORY=1; shift ;;
    --calibrate) CALIBRATE=1; shift ;;
    --train-seeds) TRAIN_SEEDS="$2"; shift 2 ;;
    --train-max-rows-per-seed) TRAIN_MAX_ROWS_PER_SEED="$2"; shift 2 ;;
    --calibration-val-max-files) CALIBRATION_VAL_MAX_FILES="$2"; shift 2 ;;
    --val-dir) VAL_DIR="$2"; shift 2 ;;
    --fresh-dir) FRESH_DIR="$2"; FRESH_DIR_EXPLICIT=1; shift 2 ;;
    --with-fixed-delay) WITH_FIXED_DELAY=1; shift ;;
    --fixed-delay-list) FIXED_DELAY_LIST="$2"; shift 2 ;;
    --fixed-delay-seeds) FIXED_DELAY_SEEDS="$2"; shift 2 ;;
    --fixed-delay-n-conv) FIXED_DELAY_N_CONV="$2"; shift 2 ;;
    --fixed-delay-jobs) FIXED_DELAY_JOBS="$2"; shift 2 ;;
    --jitter-sigma) JITTER_SIGMA="$2"; shift 2 ;;
    --jitter-bound) JITTER_BOUND="$2"; shift 2 ;;
    --rebuild) REBUILD=1; shift ;;
    --skip-campaign) SKIP_CAMPAIGN=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --smoke) SMOKE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[ERROR] Unknown option: $1"; exit 1 ;;
  esac
done

case "$OUT_DIR" in
  /*) ;;
  *) OUT_DIR="$(pwd)/$OUT_DIR" ;;
esac
if [[ -n "$SCRATCH_ROOT" ]]; then
  case "$SCRATCH_ROOT" in
    /*) ;;
    *) SCRATCH_ROOT="$REPO_ROOT/$SCRATCH_ROOT" ;;
  esac
fi
case "$FRESH_DIR" in
  "") ;;
  /*) ;;
  *) FRESH_DIR="$(pwd)/$FRESH_DIR" ;;
esac
case "$VAL_DIR" in
  "") ;;
  /*) ;;
  *) VAL_DIR="$(pwd)/$VAL_DIR" ;;
esac

if [[ -n "$JITTER_SIGMA" && -z "$JITTER_BOUND" ]]; then
  echo "[ERROR] --jitter-sigma requires --jitter-bound"
  exit 1
fi
if [[ -z "$JITTER_SIGMA" && -n "$JITTER_BOUND" ]]; then
  echo "[ERROR] --jitter-bound requires --jitter-sigma"
  exit 1
fi

case "$OUT_MODE" in
  full|2)
    echo "[WARN] Legacy --out-mode '$OUT_MODE' ignored; using fixed raw_features packet"
    OUT_MODE="raw_features"
    ;;
  raw_features|raw|0) OUT_MODE="raw_features" ;;
  *)
    echo "[ERROR] Unknown out mode '$OUT_MODE' (use raw_features)"
    exit 1
    ;;
esac
case "$NFAST_ENCODING" in
  legacy_binary_nfast|raw_lfsr_tag|raw_galois_tag) ;;
  *)
    echo "[ERROR] Unknown nfast encoding '$NFAST_ENCODING'"
    exit 1
    ;;
esac
case "$NFAST_ENCODING" in
  raw_galois_tag)
    FAST_TAG_ENCODING="raw_galois_tag"
    RTL_TAG_DEFINE_OR_PARAMETER="+define+MPTDC_FAST_TAG_GALOIS"
    ;;
  legacy_binary_nfast|raw_lfsr_tag)
    FAST_TAG_ENCODING="raw_lfsr_tag"
    RTL_TAG_DEFINE_OR_PARAMETER="default:TAG_ENCODING_SEL=TAG_ENC_LFSR_FIBONACCI"
    ;;
esac
case "$FREQ_MODE" in
  nominal)
    FREQ_RTL_DEFINE_OR_PARAMETER="default:OSC_TS_SLOW_PS=55,OSC_TS_FAST_PS=50"
    OSC_TS_SLOW_PS=55
    OSC_TS_FAST_PS=50
    ;;
  r750_delta5)
    FREQ_RTL_DEFINE_OR_PARAMETER="+define+MPTDC_FREQ_R750_DELTA5"
    OSC_TS_SLOW_PS=79
    OSC_TS_FAST_PS=74
    ;;
  *)
    echo "[ERROR] Unknown freq mode '$FREQ_MODE' (use nominal or r750_delta5)"
    exit 1
    ;;
esac
DELTA_STEP=$((OSC_TS_SLOW_PS - OSC_TS_FAST_PS))
if (( DELTA_STEP <= 0 )); then
  echo "[ERROR] Invalid frequency mode $FREQ_MODE: OSC_TS_SLOW_PS must exceed OSC_TS_FAST_PS"
  exit 1
fi
DELTA_LSB=$((2 * DELTA_STEP))
K_VERNIER=$((OSC_TS_SLOW_PS / DELTA_STEP))
case "$ANALYSIS_BACKEND" in
  legacy|streaming) ;;
  *)
    echo "[ERROR] Unknown analysis backend '$ANALYSIS_BACKEND' (use legacy or streaming)"
    exit 1
    ;;
esac
if (( ANALYSIS_JOBS < 1 )); then
  echo "[ERROR] --analysis-jobs must be >= 1"
  exit 1
fi
if (( ANALYSIS_CHUNKSIZE < 1 )); then
  echo "[ERROR] --analysis-chunksize must be >= 1"
  exit 1
fi

# The ECO discriminator is part of the calibration key. Older default fresh
# validation directories may predate the stop_phase_disc column, so only use a
# fresh validation set when the caller explicitly supplies one.
if (( CALIBRATE )) && (( ! FRESH_DIR_EXPLICIT )); then
  FRESH_DIR=""
fi

if (( SMOKE )); then
  SEEDS=1
  N_CONV=200
  FIXED_DELAY_SEEDS=1
  FIXED_DELAY_N_CONV=200
  FIXED_DELAY_JOBS=1
  FIXED_DELAY_LIST="50,1000,10000"
  if (( CALIBRATE )) && [[ -z "$VAL_DIR" ]]; then
    TRAIN_SEEDS=1
  fi
  ANALYSIS_JOBS=1
  ANALYSIS_CHUNKSIZE=50000
  if (( CALIBRATE )) && (( ! FRESH_DIR_EXPLICIT )); then
    FRESH_DIR=""
  fi
  echo "[BASELINE] Smoke mode: 1 seed, 200 conversions, representative fixed-delay points"
fi

CAMPAIGN_DIR="$OUT_DIR/campaign"
CAMPAIGN_CONFIG_DIR="$(config_output_name "$CONFIG" "$JITTER_SIGMA" "$JITTER_BOUND")"
SWEEP_ANALYSIS_DIR="$OUT_DIR/analysis/sweep"
CALIBRATION_DIR="$OUT_DIR/analysis/calibration"
FIXED_DELAY_DIR="$OUT_DIR/fixed_delay"
MANIFEST_PATH="$OUT_DIR/characterization_manifest.json"

mkdir -p "$OUT_DIR"
cd "$REPO_ROOT"

CAMPAIGN_CMD=(
  bash "$REPO_ROOT/scripts/sim/run_campaign.sh"
  --sim "$SIM"
  --jobs "$JOBS"
  --seeds "$SEEDS"
  --n-conv "$N_CONV"
  --delay-min 20
  --delay-max 30000
  --configs "$CONFIG"
  --out-mode "$OUT_MODE"
  --fast-tag-encoding "$FAST_TAG_ENCODING"
  --freq-mode "$FREQ_MODE"
  --out-dir "$CAMPAIGN_DIR"
)
if [[ -n "$SCRATCH_ROOT" ]]; then
  CAMPAIGN_CMD+=(--scratch-root "$SCRATCH_ROOT")
fi
if [[ -n "$JITTER_SIGMA" ]]; then
  CAMPAIGN_CMD+=(--jitter-sigma "$JITTER_SIGMA" --jitter-bound "$JITTER_BOUND")
fi
if (( REBUILD )); then
  CAMPAIGN_CMD+=(--rebuild)
fi
if (( DRY_RUN )); then
  CAMPAIGN_CMD+=(--dry-run)
fi

ANALYZE_CMD=(
  python3 "$REPO_ROOT/scripts/analysis/analyze_campaign.py"
  --campaign-dir "$CAMPAIGN_DIR"
  --output-dir "$SWEEP_ANALYSIS_DIR"
  --config-filter "$CONFIG*"
  --nfast-encoding "$NFAST_ENCODING"
  --freq-mode "$FREQ_MODE"
  --analysis-jobs "$ANALYSIS_JOBS"
  --analysis-chunksize "$ANALYSIS_CHUNKSIZE"
  --analysis-backend "$ANALYSIS_BACKEND"
)
if (( ANALYSIS_LOW_MEMORY )); then
  ANALYZE_CMD+=(--analysis-low-memory)
fi
if (( ANALYSIS_LOG_MEMORY )); then
  ANALYZE_CMD+=(--log-memory)
fi
if (( DRY_RUN )); then
  ANALYZE_CMD+=(--max-files 1)
fi

FINE_GRID_CMD=(
  python3 "$REPO_ROOT/scripts/calibration/analyze_fine_grid.py"
  --output "$SWEEP_ANALYSIS_DIR/fine_grid_analysis.pdf"
  --freq-mode "$FREQ_MODE"
)

CALIBRATE_CMD=(
  python3 "$REPO_ROOT/scripts/calibration/calibrate_6d_lut.py"
  --train-dir "$CAMPAIGN_DIR/$CAMPAIGN_CONFIG_DIR"
  --out-dir "$CALIBRATION_DIR"
  --train-seeds "$TRAIN_SEEDS"
  --nfast-encoding "$NFAST_ENCODING"
  --freq-mode "$FREQ_MODE"
)
if [[ -n "$TRAIN_MAX_ROWS_PER_SEED" ]]; then
  CALIBRATE_CMD+=(--train-max-rows-per-seed "$TRAIN_MAX_ROWS_PER_SEED")
fi
if [[ -n "$CALIBRATION_VAL_MAX_FILES" ]]; then
  CALIBRATE_CMD+=(--val-max-files "$CALIBRATION_VAL_MAX_FILES")
elif (( ANALYSIS_LOW_MEMORY )); then
  CALIBRATE_CMD+=(--val-max-files 2)
fi
if [[ -n "$VAL_DIR" ]]; then
  CALIBRATE_CMD+=(--val-dir "$VAL_DIR")
elif (( SMOKE )); then
  CALIBRATE_CMD+=(--val-dir "$CAMPAIGN_DIR/$CAMPAIGN_CONFIG_DIR")
fi
if [[ -n "$FRESH_DIR" ]]; then
  CALIBRATE_CMD+=(--fresh-dir "$FRESH_DIR")
fi

FIXED_DELAY_CMD=(
  bash "$REPO_ROOT/scripts/sim/run_fixed_delay_campaign.sh"
  --sim "$SIM"
  --jobs "$FIXED_DELAY_JOBS"
  --seeds "$FIXED_DELAY_SEEDS"
  --n-conv "$FIXED_DELAY_N_CONV"
  --configs "$CONFIG"
  --out-mode "$OUT_MODE"
  --fast-tag-encoding "$FAST_TAG_ENCODING"
  --freq-mode "$FREQ_MODE"
  --delay-list "$FIXED_DELAY_LIST"
  --out-dir "$FIXED_DELAY_DIR"
  --analyze
)
if [[ -n "$SCRATCH_ROOT" ]]; then
  FIXED_DELAY_CMD+=(--scratch-root "$SCRATCH_ROOT")
fi
if [[ -n "$JITTER_SIGMA" ]]; then
  FIXED_DELAY_CMD+=(--jitter-sigma "$JITTER_SIGMA" --jitter-bound "$JITTER_BOUND")
fi
if (( REBUILD )); then
  FIXED_DELAY_CMD+=(--rebuild)
fi
if (( DRY_RUN )); then
  FIXED_DELAY_CMD+=(--dry-run)
fi

write_manifest() {
  local status="$1"
  local campaign_csv_count="$2"
  local campaign_row_count="$3"
  local fixed_delay_csv_count="$4"
  export MANIFEST_PATH
  export MANIFEST_STATUS="$status"
  export MANIFEST_SIM="$SIM"
  export MANIFEST_JOBS="$JOBS"
  export MANIFEST_SEEDS="$SEEDS"
  export MANIFEST_N_CONV="$N_CONV"
  export MANIFEST_CONFIG="$CONFIG"
  export MANIFEST_OUT_MODE="$OUT_MODE"
  export MANIFEST_NFAST_ENCODING="$NFAST_ENCODING"
  export MANIFEST_FAST_TAG_ENCODING="$FAST_TAG_ENCODING"
  export MANIFEST_RTL_TAG_DEFINE_OR_PARAMETER="$RTL_TAG_DEFINE_OR_PARAMETER"
  export MANIFEST_FREQ_MODE="$FREQ_MODE"
  export MANIFEST_FREQ_RTL_DEFINE_OR_PARAMETER="$FREQ_RTL_DEFINE_OR_PARAMETER"
  export MANIFEST_OSC_TS_SLOW_PS="$OSC_TS_SLOW_PS"
  export MANIFEST_OSC_TS_FAST_PS="$OSC_TS_FAST_PS"
  export MANIFEST_DELTA_STEP="$DELTA_STEP"
  export MANIFEST_DELTA_LSB="$DELTA_LSB"
  export MANIFEST_K_VERNIER="$K_VERNIER"
  export MANIFEST_COMMAND_LINE="$(render_cmd "$0" "${ORIGINAL_ARGS[@]}")"
  export MANIFEST_RTL_HEAD="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
  export MANIFEST_BRANCH="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  export MANIFEST_MPTDC_ROOT="$REPO_ROOT"
  export MANIFEST_PACKET_FORMAT_VERSION="fixed_raw_features_v2_7"
  export MANIFEST_CALIBRATION_MODEL_VERSION="6d_lut_v2_7"
  export MANIFEST_OUT_DIR="$OUT_DIR"
  export MANIFEST_CAMPAIGN_DIR="$CAMPAIGN_DIR"
  export MANIFEST_CAMPAIGN_CONFIG_DIR="$CAMPAIGN_DIR/$CAMPAIGN_CONFIG_DIR"
  export MANIFEST_SWEEP_ANALYSIS_DIR="$SWEEP_ANALYSIS_DIR"
  export MANIFEST_CALIBRATION_DIR="$CALIBRATION_DIR"
  export MANIFEST_FIXED_DELAY_DIR="$FIXED_DELAY_DIR"
  export MANIFEST_ANALYZE="$ANALYZE"
  export MANIFEST_ANALYSIS_JOBS="$ANALYSIS_JOBS"
  export MANIFEST_ANALYSIS_CHUNKSIZE="$ANALYSIS_CHUNKSIZE"
  export MANIFEST_ANALYSIS_BACKEND="$ANALYSIS_BACKEND"
  export MANIFEST_ANALYSIS_LOW_MEMORY="$ANALYSIS_LOW_MEMORY"
  export MANIFEST_ANALYSIS_LOG_MEMORY="$ANALYSIS_LOG_MEMORY"
  export MANIFEST_CALIBRATE="$CALIBRATE"
  export MANIFEST_WITH_FIXED_DELAY="$WITH_FIXED_DELAY"
  export MANIFEST_SMOKE="$SMOKE"
  export MANIFEST_SKIP_CAMPAIGN="$SKIP_CAMPAIGN"
  export MANIFEST_TRAIN_SEEDS="$TRAIN_SEEDS"
  export MANIFEST_TRAIN_MAX_ROWS_PER_SEED="$TRAIN_MAX_ROWS_PER_SEED"
  export MANIFEST_CALIBRATION_VAL_MAX_FILES="$CALIBRATION_VAL_MAX_FILES"
  export MANIFEST_VAL_DIR="$VAL_DIR"
  export MANIFEST_FRESH_DIR="$FRESH_DIR"
  export MANIFEST_FIXED_DELAY_LIST="$FIXED_DELAY_LIST"
  export MANIFEST_FIXED_DELAY_SEEDS="$FIXED_DELAY_SEEDS"
  export MANIFEST_FIXED_DELAY_N_CONV="$FIXED_DELAY_N_CONV"
  export MANIFEST_FIXED_DELAY_JOBS="$FIXED_DELAY_JOBS"
  export MANIFEST_SCRATCH_ROOT="$SCRATCH_ROOT"
  export MANIFEST_JITTER_SIGMA="$JITTER_SIGMA"
  export MANIFEST_JITTER_BOUND="$JITTER_BOUND"
  export MANIFEST_CAMPAIGN_CMD="$(render_cmd "${CAMPAIGN_CMD[@]}")"
  export MANIFEST_ANALYZE_CMD="$(render_cmd "${ANALYZE_CMD[@]}")"
  export MANIFEST_FINE_GRID_CMD="$(render_cmd "${FINE_GRID_CMD[@]}")"
  export MANIFEST_CALIBRATE_CMD="$(render_cmd "${CALIBRATE_CMD[@]}")"
  export MANIFEST_FIXED_DELAY_CMD="$(render_cmd "${FIXED_DELAY_CMD[@]}")"
  export MANIFEST_CAMPAIGN_CSV_COUNT="$campaign_csv_count"
  export MANIFEST_CAMPAIGN_ROW_COUNT="$campaign_row_count"
  export MANIFEST_FIXED_DELAY_CSV_COUNT="$fixed_delay_csv_count"
  export MANIFEST_RAW_TUPLE_HISTOGRAM_GLOB="$SWEEP_ANALYSIS_DIR/raw_tuple_histogram_*.csv"
  export MANIFEST_RAW_TUPLE_HISTOGRAM_PLOT_GLOB="$SWEEP_ANALYSIS_DIR/raw_tuple_histogram_*.png"
  export MANIFEST_RECON_ERROR_TABLE="$CALIBRATION_DIR/val_reconstruction_errors_pre_post.csv"
  export MANIFEST_RECON_ERROR_PLOTS_DIR="$CALIBRATION_DIR/plots"
  python3 - <<'PY'
import json
import os
import sys
from pathlib import Path

tools_root = Path(os.environ["MANIFEST_MPTDC_ROOT"]).parent / "tools"
if str(tools_root) not in sys.path:
    sys.path.insert(0, str(tools_root))

from mptdc_decode.fast_tag_decode import FastTagMetadata

def env_bool(name: str) -> bool:
    return os.environ.get(name, "0") == "1"

tag_metadata = FastTagMetadata(nfast_encoding=os.environ["MANIFEST_NFAST_ENCODING"]).as_dict()
seed_list = list(range(int(os.environ["MANIFEST_SEEDS"])))

data = {
    "name": "mptdc-characterization-baseline",
    "status": os.environ["MANIFEST_STATUS"],
    "rtl": {
        "branch": os.environ["MANIFEST_BRANCH"],
        "head": os.environ["MANIFEST_RTL_HEAD"],
        "fast_tag_encoding": os.environ["MANIFEST_FAST_TAG_ENCODING"],
        "rtl_tag_define_or_parameter": os.environ["MANIFEST_RTL_TAG_DEFINE_OR_PARAMETER"],
        "freq_mode": os.environ["MANIFEST_FREQ_MODE"],
        "freq_rtl_define_or_parameter": os.environ["MANIFEST_FREQ_RTL_DEFINE_OR_PARAMETER"],
    },
    "frequency_mode": {
        "freq_mode": os.environ["MANIFEST_FREQ_MODE"],
        "OSC_TS_SLOW_PS": int(os.environ["MANIFEST_OSC_TS_SLOW_PS"]),
        "OSC_TS_FAST_PS": int(os.environ["MANIFEST_OSC_TS_FAST_PS"]),
        "DELTA_STEP": int(os.environ["MANIFEST_DELTA_STEP"]),
        "DELTA_LSB": int(os.environ["MANIFEST_DELTA_LSB"]),
        "K_VERNIER": int(os.environ["MANIFEST_K_VERNIER"]),
    },
    "packet": {
        "format_version": os.environ["MANIFEST_PACKET_FORMAT_VERSION"],
        "word_width": 16,
        "layout": "header + 2*hit_count hit words + eoc",
        "production_packet_unchanged": True,
        "nslow_width": 7,
        "nfast_width": 7,
        "ns_width": 4,
        "nf_width": 4,
    },
    "tag_encoding": tag_metadata,
    "calibration_model_version": os.environ["MANIFEST_CALIBRATION_MODEL_VERSION"],
    "baseline": {
        "sim": os.environ["MANIFEST_SIM"],
        "jobs": int(os.environ["MANIFEST_JOBS"]),
        "seeds": int(os.environ["MANIFEST_SEEDS"]),
        "seed_list": seed_list,
        "n_conv_per_seed": int(os.environ["MANIFEST_N_CONV"]),
        "config": os.environ["MANIFEST_CONFIG"],
        "delay_range_ps": [20, 30000],
        "out_mode": os.environ["MANIFEST_OUT_MODE"],
        "nfast_encoding": os.environ["MANIFEST_NFAST_ENCODING"],
        "fast_tag_encoding": os.environ["MANIFEST_FAST_TAG_ENCODING"],
        "rtl_tag_define_or_parameter": os.environ["MANIFEST_RTL_TAG_DEFINE_OR_PARAMETER"],
        "freq_mode": os.environ["MANIFEST_FREQ_MODE"],
        "smoke": env_bool("MANIFEST_SMOKE"),
        "skip_campaign": env_bool("MANIFEST_SKIP_CAMPAIGN"),
    },
    "stages": {
        "analyze": env_bool("MANIFEST_ANALYZE"),
        "calibrate": env_bool("MANIFEST_CALIBRATE"),
        "with_fixed_delay": env_bool("MANIFEST_WITH_FIXED_DELAY"),
    },
    "analysis": {
        "jobs": int(os.environ["MANIFEST_ANALYSIS_JOBS"]),
        "chunksize": int(os.environ["MANIFEST_ANALYSIS_CHUNKSIZE"]),
        "backend": os.environ["MANIFEST_ANALYSIS_BACKEND"],
        "low_memory": env_bool("MANIFEST_ANALYSIS_LOW_MEMORY"),
        "log_memory": env_bool("MANIFEST_ANALYSIS_LOG_MEMORY"),
    },
    "calibration": {
        "train_seeds": int(os.environ["MANIFEST_TRAIN_SEEDS"]),
        "train_max_rows_per_seed": os.environ.get("MANIFEST_TRAIN_MAX_ROWS_PER_SEED", ""),
        "val_max_files": os.environ.get("MANIFEST_CALIBRATION_VAL_MAX_FILES", ""),
        "val_dir": os.environ.get("MANIFEST_VAL_DIR", ""),
        "fresh_dir": os.environ.get("MANIFEST_FRESH_DIR", ""),
    },
    "fixed_delay": {
        "delay_list_ps": [int(x) for x in os.environ["MANIFEST_FIXED_DELAY_LIST"].replace(",", " ").split()],
        "seeds": int(os.environ["MANIFEST_FIXED_DELAY_SEEDS"]),
        "n_conv_per_seed": int(os.environ["MANIFEST_FIXED_DELAY_N_CONV"]),
        "jobs": int(os.environ["MANIFEST_FIXED_DELAY_JOBS"]),
    },
    "jitter_override_ps": {
        "sigma": os.environ.get("MANIFEST_JITTER_SIGMA", ""),
        "bound": os.environ.get("MANIFEST_JITTER_BOUND", ""),
    },
    "paths": {
        "root": os.environ["MANIFEST_OUT_DIR"],
        "scratch_root": os.environ["MANIFEST_SCRATCH_ROOT"],
        "campaign": os.environ["MANIFEST_CAMPAIGN_DIR"],
        "campaign_config": os.environ["MANIFEST_CAMPAIGN_CONFIG_DIR"],
        "sweep_analysis": os.environ["MANIFEST_SWEEP_ANALYSIS_DIR"],
        "calibration": os.environ["MANIFEST_CALIBRATION_DIR"],
        "fixed_delay": os.environ["MANIFEST_FIXED_DELAY_DIR"],
    },
    "commands": {
        "top_level": os.environ["MANIFEST_COMMAND_LINE"],
        "campaign": os.environ["MANIFEST_CAMPAIGN_CMD"],
        "analyze": os.environ["MANIFEST_ANALYZE_CMD"],
        "fine_grid": os.environ["MANIFEST_FINE_GRID_CMD"],
        "calibrate": os.environ["MANIFEST_CALIBRATE_CMD"],
        "fixed_delay": os.environ["MANIFEST_FIXED_DELAY_CMD"],
    },
    "precision_evidence": {
        "raw_tuple_histogram_csv_glob": os.environ["MANIFEST_RAW_TUPLE_HISTOGRAM_GLOB"],
        "raw_tuple_histogram_plot_glob": os.environ["MANIFEST_RAW_TUPLE_HISTOGRAM_PLOT_GLOB"],
        "post_reconstruction_error_table": os.environ["MANIFEST_RECON_ERROR_TABLE"],
        "post_reconstruction_error_plots_dir": os.environ["MANIFEST_RECON_ERROR_PLOTS_DIR"],
        "requires": {
            "raw_tuple_histograms": "--analyze",
            "post_reconstruction_error_exports": "--calibrate",
        },
    },
    "summary": {
        "campaign_csv_count": int(os.environ["MANIFEST_CAMPAIGN_CSV_COUNT"]),
        "campaign_row_count": int(os.environ["MANIFEST_CAMPAIGN_ROW_COUNT"]),
        "fixed_delay_csv_count": int(os.environ["MANIFEST_FIXED_DELAY_CSV_COUNT"]),
    },
}

path = Path(os.environ["MANIFEST_PATH"])
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
}

echo "[BASELINE] Output root: $OUT_DIR"
echo "[BASELINE] Config: $CONFIG"
echo "[BASELINE] Sweep campaign: $SEEDS seed(s) × $N_CONV conv/seed, $JOBS job(s) in parallel"
echo "[BASELINE] Fast tag RTL: nfast_encoding=$NFAST_ENCODING fast_tag_encoding=$FAST_TAG_ENCODING"
echo "[BASELINE] Frequency mode: $FREQ_MODE OSC_TS_SLOW_PS=$OSC_TS_SLOW_PS OSC_TS_FAST_PS=$OSC_TS_FAST_PS DELTA_STEP=$DELTA_STEP DELTA_LSB=$DELTA_LSB K_VERNIER=$K_VERNIER"
if [[ -n "$SCRATCH_ROOT" ]]; then
  echo "[BASELINE] Scratch/build root: $SCRATCH_ROOT"
fi
echo "[BASELINE] Analysis: backend=$ANALYSIS_BACKEND jobs=$ANALYSIS_JOBS chunksize=$ANALYSIS_CHUNKSIZE low_memory=$ANALYSIS_LOW_MEMORY"
echo "[BASELINE] Manifest: $MANIFEST_PATH"

write_manifest "planned" 0 0 0

print_cmd "[RUN]" "${CAMPAIGN_CMD[@]}"
if (( SKIP_CAMPAIGN )); then
  echo "[BASELINE] Skipping campaign collection; reusing $CAMPAIGN_DIR"
elif (( ! DRY_RUN )); then
  "${CAMPAIGN_CMD[@]}"
fi

if (( ANALYZE )); then
  print_cmd "[RUN]" "${ANALYZE_CMD[@]}"
  if (( ! DRY_RUN )); then
    "${ANALYZE_CMD[@]}"
  fi

  print_cmd "[RUN]" "${FINE_GRID_CMD[@]}"
  if (( ! DRY_RUN )); then
    "${FINE_GRID_CMD[@]}"
  fi
fi

if (( CALIBRATE )); then
  print_cmd "[RUN]" "${CALIBRATE_CMD[@]}"
  if (( ! DRY_RUN )); then
    "${CALIBRATE_CMD[@]}"
  fi
fi

if (( WITH_FIXED_DELAY )); then
  print_cmd "[RUN]" "${FIXED_DELAY_CMD[@]}"
  if (( ! DRY_RUN )); then
    "${FIXED_DELAY_CMD[@]}"
  fi
fi

CAMPAIGN_CSV_COUNT=0
CAMPAIGN_ROW_COUNT=0
FIXED_DELAY_CSV_COUNT=0
if (( ! DRY_RUN )); then
  CAMPAIGN_CSV_COUNT=$(find "$CAMPAIGN_DIR" -name 'seed_*.csv' 2>/dev/null | wc -l)
  if (( CAMPAIGN_CSV_COUNT > 0 )); then
    CAMPAIGN_ROW_COUNT=$(find "$CAMPAIGN_DIR" -name 'seed_*.csv' -exec tail -n +2 {} + 2>/dev/null | wc -l)
  fi
  if [[ -d "$FIXED_DELAY_DIR" ]]; then
    FIXED_DELAY_CSV_COUNT=$(find "$FIXED_DELAY_DIR" -name 'seed_*.csv' 2>/dev/null | wc -l)
  fi
fi
write_manifest "completed" "$CAMPAIGN_CSV_COUNT" "$CAMPAIGN_ROW_COUNT" "$FIXED_DELAY_CSV_COUNT"

echo "[BASELINE] Done."
echo "[BASELINE] Manifest written to $MANIFEST_PATH"
