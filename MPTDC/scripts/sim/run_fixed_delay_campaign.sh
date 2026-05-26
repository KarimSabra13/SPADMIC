#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Purpose : Collect repeated fixed-delay characterization points using the
#           maintained tb_campaign_collect flow. Each delay is run as an
#           independent campaign with delay_min == delay_max.
# Usage   : bash scripts/sim/run_fixed_delay_campaign.sh [options]
#           --sim NAME         Simulator: verilator|xrun|xcelium (default verilator)
#           --jobs N           Parallel seeds per delay (default 8)
#           --seeds N          Seeds per delay point (default 6)
#           --n-conv N         Conversions per seed (default 2000)
#           --seed-start N     First PRNG seed number (default 0)
#           --configs GLOB     Config filter passed to run_campaign.sh
#           --out-mode NAME    Serializer mode: raw_features (default raw_features;
#                              legacy full/2 aliases are mapped downstream)
#           --delay-list LIST  Comma/space-separated delays in ps
#           --out-dir DIR      Output directory (default results/fixed_delay_campaign)
#           --jitter-sigma N   Override oscillator jitter sigma in ps
#           --jitter-bound N   Override oscillator jitter bound in ps
#           --analyze          Run analyze_fixed_delay_campaign.py after collection
#           --rebuild          Forward --rebuild to the first campaign launch
#           --dry-run          Print commands without executing
#           --smoke            Small representative fixed-delay sweep
# -----------------------------------------------------------------------------

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

SIM="verilator"
JOBS=8
SEEDS=6
N_CONV=2000
SEED_START=0
CONFIG_FILTER="multihit_15_cal_nominal"
OUT_MODE="raw_features"
OUT_DIR="$REPO_ROOT/results/fixed_delay_campaign"
DELAY_LIST="20,50,100,200,500,1000,2000,5000,10000,30000"
JITTER_SIGMA_OVERRIDE=""
JITTER_BOUND_OVERRIDE=""
ANALYZE=0
REBUILD=0
DRY_RUN=0
SMOKE=0
ANALYSIS_FILTER=""

print_cmd() {
  local prefix="$1"
  shift
  printf '%s' "$prefix"
  for arg in "$@"; do
    printf ' %q' "$arg"
  done
  printf '\n'
}

usage() {
  sed -n '2,/^# -----------------------------------------------------------------------------$/{ /^# -----------------------------------------------------------------------------$/d; s/^# //; p }' "$0"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sim) SIM="$2"; shift 2 ;;
    --jobs) JOBS="$2"; shift 2 ;;
    --seeds) SEEDS="$2"; shift 2 ;;
    --n-conv) N_CONV="$2"; shift 2 ;;
    --seed-start) SEED_START="$2"; shift 2 ;;
    --configs) CONFIG_FILTER="$2"; shift 2 ;;
    --out-mode) OUT_MODE="$2"; shift 2 ;;
    --delay-list) DELAY_LIST="$2"; shift 2 ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --jitter-sigma) JITTER_SIGMA_OVERRIDE="$2"; shift 2 ;;
    --jitter-bound) JITTER_BOUND_OVERRIDE="$2"; shift 2 ;;
    --analyze) ANALYZE=1; shift ;;
    --rebuild) REBUILD=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --smoke) SMOKE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[ERROR] Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -n "$JITTER_SIGMA_OVERRIDE" && -z "$JITTER_BOUND_OVERRIDE" ]]; then
  echo "[ERROR] --jitter-sigma requires --jitter-bound"
  exit 1
fi
if [[ -z "$JITTER_SIGMA_OVERRIDE" && -n "$JITTER_BOUND_OVERRIDE" ]]; then
  echo "[ERROR] --jitter-bound requires --jitter-sigma"
  exit 1
fi

case "$OUT_DIR" in
  /*) ;;
  *) OUT_DIR="$(pwd)/$OUT_DIR" ;;
esac

if (( SMOKE )); then
  SEEDS=1
  N_CONV=200
  CONFIG_FILTER="multihit_15_cal_nominal"
  DELAY_LIST="50,1000,10000"
  echo "[FIXED-DELAY] Smoke mode: 3 delays, 1 seed, 200 conversions"
fi

normalize_delays() {
  local raw="$1"
  raw="${raw//,/ }"
  read -r -a DELAYS <<< "$raw"
  if (( ${#DELAYS[@]} == 0 )); then
    echo "[ERROR] Empty --delay-list"
    exit 1
  fi
  for delay in "${DELAYS[@]}"; do
    if [[ ! "$delay" =~ ^[0-9]+$ ]]; then
      echo "[ERROR] Invalid delay '$delay' in --delay-list"
      exit 1
    fi
  done
}

normalize_delays "$DELAY_LIST"

if [[ -z "$ANALYSIS_FILTER" ]]; then
  case "$CONFIG_FILTER" in
    *'*'*|*'?'*|*'['*|*']'*)
      ANALYSIS_FILTER="$CONFIG_FILTER"
      ;;
    *)
      ANALYSIS_FILTER="${CONFIG_FILTER}*"
      ;;
  esac
fi

mkdir -p "$OUT_DIR"
echo "[FIXED-DELAY] Output root: $OUT_DIR"
echo "[FIXED-DELAY] Delays (ps): ${DELAYS[*]}"

first_run=1
for delay_ps in "${DELAYS[@]}"; do
  delay_tag="$(printf "%05dps" "$delay_ps")"
  delay_out="$OUT_DIR/delay_${delay_tag}"

  cmd=(
    bash "$REPO_ROOT/scripts/sim/run_campaign.sh"
    --sim "$SIM"
    --jobs "$JOBS"
    --seeds "$SEEDS"
    --n-conv "$N_CONV"
    --delay-min "$delay_ps"
    --delay-max "$delay_ps"
    --seed-start "$SEED_START"
    --configs "$CONFIG_FILTER"
    --out-mode "$OUT_MODE"
    --out-dir "$delay_out"
  )

  if [[ -n "$JITTER_SIGMA_OVERRIDE" ]]; then
    cmd+=(--jitter-sigma "$JITTER_SIGMA_OVERRIDE" --jitter-bound "$JITTER_BOUND_OVERRIDE")
  fi
  if (( REBUILD && first_run )); then
    cmd+=(--rebuild)
  fi

  echo
  echo "[FIXED-DELAY] Running delay ${delay_ps} ps -> $delay_out"
  if (( DRY_RUN )); then
    print_cmd "[DRY-RUN]" "${cmd[@]}"
  else
    "${cmd[@]}"
  fi
  first_run=0
done

if (( ANALYZE )); then
  echo
  analysis_cmd=(
    python3 "$REPO_ROOT/scripts/analysis/analyze_fixed_delay_campaign.py"
    --campaign-dir "$OUT_DIR"
    --output-dir "$OUT_DIR/analysis"
    --config-filter "$ANALYSIS_FILTER"
  )
  if (( DRY_RUN )); then
    print_cmd "[DRY-RUN]" "${analysis_cmd[@]}"
  else
    echo "[FIXED-DELAY] Launching fixed-delay analysis..."
    "${analysis_cmd[@]}"
  fi
else
  echo
  echo "[FIXED-DELAY] Collection complete."
  echo "[FIXED-DELAY] Analyze with:"
  print_cmd "  " \
    python3 "$REPO_ROOT/scripts/analysis/analyze_fixed_delay_campaign.py" \
    --campaign-dir "$OUT_DIR" \
    --output-dir "$OUT_DIR/analysis" \
    --config-filter "$ANALYSIS_FILTER"
fi
