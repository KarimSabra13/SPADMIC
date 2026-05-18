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
#           --out-mode NAME       full|raw_features (default full)
#           --out-dir DIR         Root output dir (default results/characterization/baseline_nominal_full)
#           --analyze             Run sweep analysis + fine-grid report, including
#                                 raw tuple histograms/code-density CSVs and plots
#           --calibrate           Run maintained 6D LUT calibration after collection,
#                                 including pre/post reconstruction error exports
#           --train-seeds N       Training seeds for calibration (default 24)
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
#           --dry-run             Print commands without executing
#           --smoke               Shape-validation mode (small representative run)
# -----------------------------------------------------------------------------

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

SIM="verilator"
JOBS=12
SEEDS=30
N_CONV=100000
CONFIG="multihit_15_cal_nominal"
OUT_MODE="full"
OUT_DIR="$REPO_ROOT/results/characterization/baseline_nominal_full"
ANALYZE=0
CALIBRATE=0
TRAIN_SEEDS=24
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

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sim) SIM="$2"; shift 2 ;;
    --jobs) JOBS="$2"; shift 2 ;;
    --seeds) SEEDS="$2"; shift 2 ;;
    --n-conv) N_CONV="$2"; shift 2 ;;
    --config) CONFIG="$2"; shift 2 ;;
    --out-mode) OUT_MODE="$2"; shift 2 ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --analyze) ANALYZE=1; shift ;;
    --calibrate) CALIBRATE=1; shift ;;
    --train-seeds) TRAIN_SEEDS="$2"; shift 2 ;;
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
  if (( CALIBRATE )) && (( ! FRESH_DIR_EXPLICIT )); then
    FRESH_DIR=""
  fi
  echo "[BASELINE] Smoke mode: 1 seed, 200 conversions, representative fixed-delay points"
fi

CAMPAIGN_DIR="$OUT_DIR/campaign"
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
  --out-dir "$CAMPAIGN_DIR"
)
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
)
if (( DRY_RUN )); then
  ANALYZE_CMD+=(--max-files 1)
fi

FINE_GRID_CMD=(
  python3 "$REPO_ROOT/scripts/calibration/analyze_fine_grid.py"
  --output "$SWEEP_ANALYSIS_DIR/fine_grid_analysis.pdf"
)

CALIBRATE_CMD=(
  python3 "$REPO_ROOT/scripts/calibration/calibrate_6d_lut.py"
  --train-dir "$CAMPAIGN_DIR/$CONFIG"
  --out-dir "$CALIBRATION_DIR"
  --train-seeds "$TRAIN_SEEDS"
)
if [[ -n "$VAL_DIR" ]]; then
  CALIBRATE_CMD+=(--val-dir "$VAL_DIR")
elif (( SMOKE )); then
  CALIBRATE_CMD+=(--val-dir "$CAMPAIGN_DIR/$CONFIG")
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
  --delay-list "$FIXED_DELAY_LIST"
  --out-dir "$FIXED_DELAY_DIR"
  --analyze
)
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
  export MANIFEST_OUT_DIR="$OUT_DIR"
  export MANIFEST_CAMPAIGN_DIR="$CAMPAIGN_DIR"
  export MANIFEST_SWEEP_ANALYSIS_DIR="$SWEEP_ANALYSIS_DIR"
  export MANIFEST_CALIBRATION_DIR="$CALIBRATION_DIR"
  export MANIFEST_FIXED_DELAY_DIR="$FIXED_DELAY_DIR"
  export MANIFEST_ANALYZE="$ANALYZE"
  export MANIFEST_CALIBRATE="$CALIBRATE"
  export MANIFEST_WITH_FIXED_DELAY="$WITH_FIXED_DELAY"
  export MANIFEST_SMOKE="$SMOKE"
  export MANIFEST_TRAIN_SEEDS="$TRAIN_SEEDS"
  export MANIFEST_VAL_DIR="$VAL_DIR"
  export MANIFEST_FRESH_DIR="$FRESH_DIR"
  export MANIFEST_FIXED_DELAY_LIST="$FIXED_DELAY_LIST"
  export MANIFEST_FIXED_DELAY_SEEDS="$FIXED_DELAY_SEEDS"
  export MANIFEST_FIXED_DELAY_N_CONV="$FIXED_DELAY_N_CONV"
  export MANIFEST_FIXED_DELAY_JOBS="$FIXED_DELAY_JOBS"
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
from pathlib import Path

def env_bool(name: str) -> bool:
    return os.environ.get(name, "0") == "1"

data = {
    "name": "mptdc-characterization-baseline",
    "status": os.environ["MANIFEST_STATUS"],
    "baseline": {
        "sim": os.environ["MANIFEST_SIM"],
        "jobs": int(os.environ["MANIFEST_JOBS"]),
        "seeds": int(os.environ["MANIFEST_SEEDS"]),
        "n_conv_per_seed": int(os.environ["MANIFEST_N_CONV"]),
        "config": os.environ["MANIFEST_CONFIG"],
        "delay_range_ps": [20, 30000],
        "out_mode": os.environ["MANIFEST_OUT_MODE"],
        "smoke": env_bool("MANIFEST_SMOKE"),
    },
    "stages": {
        "analyze": env_bool("MANIFEST_ANALYZE"),
        "calibrate": env_bool("MANIFEST_CALIBRATE"),
        "with_fixed_delay": env_bool("MANIFEST_WITH_FIXED_DELAY"),
    },
    "calibration": {
        "train_seeds": int(os.environ["MANIFEST_TRAIN_SEEDS"]),
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
        "campaign": os.environ["MANIFEST_CAMPAIGN_DIR"],
        "sweep_analysis": os.environ["MANIFEST_SWEEP_ANALYSIS_DIR"],
        "calibration": os.environ["MANIFEST_CALIBRATION_DIR"],
        "fixed_delay": os.environ["MANIFEST_FIXED_DELAY_DIR"],
    },
    "commands": {
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
echo "[BASELINE] Manifest: $MANIFEST_PATH"

write_manifest "planned" 0 0 0

print_cmd "[RUN]" "${CAMPAIGN_CMD[@]}"
if (( ! DRY_RUN )); then
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
