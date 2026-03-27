#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Purpose : Orchestrate a full data-collection campaign across all TDC
#           configurations.  Builds the collection testbench once, then
#           enumerates every (mode × max_hits × source × jitter) config,
#           spawning --jobs parallel seeds per config.
# Usage   : bash scripts/sim/run_campaign.sh [options]
#           --jobs N         Parallel seeds (default 12)
#           --seeds N        Seeds per config (default 30)
#           --n-conv N       Conversions per seed (default 50000)
#           --delay-min N    Min delay in ps (default 20)
#           --delay-max N    Max delay in ps (default 30000)
#           --seed-start N   First PRNG seed number (default 0)
#           --configs GLOB   Config name filter glob (default '*')
#           --out-dir DIR    Output directory (default results/campaign)
#           --rebuild        Force rebuild even if binary exists
#           --dry-run        Print what would run without executing
#           --smoke          Quick smoke: 1 config, 1 seed, 100 conv
# Author  : Karim Sabra
# -----------------------------------------------------------------------------

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$REPO_ROOT/build"
OBJ_DIR="$BUILD_DIR/obj_dir_campaign"
BINARY="$OBJ_DIR/tb_campaign_collect"

# ── defaults ────────────────────────────────────────────────────────────────
JOBS=12
SEEDS_PER_CONFIG=30
N_CONV=50000
DELAY_MIN=20
DELAY_MAX=30000
SEED_START=0
CONFIG_FILTER="*"
OUT_DIR="$REPO_ROOT/results/campaign"
REBUILD=0
DRY_RUN=0
SMOKE=0

# ── parse arguments ────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --jobs)       JOBS="$2";            shift 2;;
    --seeds)      SEEDS_PER_CONFIG="$2"; shift 2;;
    --n-conv)     N_CONV="$2";          shift 2;;
    --delay-min)  DELAY_MIN="$2";       shift 2;;
    --delay-max)  DELAY_MAX="$2";       shift 2;;
    --seed-start) SEED_START="$2";      shift 2;;
    --configs)    CONFIG_FILTER="$2";   shift 2;;
    --out-dir)    OUT_DIR="$2";         shift 2;;
    --rebuild)    REBUILD=1;            shift;;
    --dry-run)    DRY_RUN=1;           shift;;
    --smoke)      SMOKE=1;             shift;;
    -h|--help)
      sed -n '2,/^# ---/{ /^# ---/d; s/^# //; p }' "$0"
      exit 0;;
    *) echo "Unknown option: $1"; exit 1;;
  esac
done

# ── smoke mode overrides ───────────────────────────────────────────────────
if (( SMOKE )); then
  SEEDS_PER_CONFIG=1
  N_CONV=100
  CONFIG_FILTER="multihit_15_cal_nominal"
  echo "[CAMPAIGN] Smoke mode: 1 config, 1 seed, 100 conversions"
fi

# ── build ───────────────────────────────────────────────────────────────────
build_tb() {
  echo "[CAMPAIGN] Building collection testbench..."
  mkdir -p "$BUILD_DIR"
  verilator --binary --timing -j 4 \
    +define+MPTDC_USE_OSC_MODEL \
    -f "$REPO_ROOT/rtl/filelist.f" \
    "$REPO_ROOT/tb/common/mptdc_tb_pkg.sv" \
    "$REPO_ROOT/tb/common/mptdc_raw_monitor.sv" \
    "$REPO_ROOT/tb/int/tb_campaign_collect.sv" \
    --top-module tb_campaign_collect \
    -Mdir "$OBJ_DIR" \
    -Wno-fatal 2>&1 | tail -5
  echo "[CAMPAIGN] Build complete: $BINARY"
}

if [[ ! -x "$BINARY" ]] || (( REBUILD )); then
  build_tb
fi

if [[ ! -x "$BINARY" ]]; then
  echo "[ERROR] Binary not found at $BINARY"
  exit 1
fi

# ── config enumeration ──────────────────────────────────────────────────────
#  mode: multihit (0), firsthit (1)
#  max_hits: 15, 10, 5
#  source: cal (1), spad (0)
#  jitter: nominal (sigma=0), jitter (sigma=8, bound=24)
declare -a CONFIGS=()
declare -A CFG_MODE CFG_MAXHITS CFG_INPUT CFG_JSIG CFG_JBOUND

add_config() {
  local name="$1" mode="$2" mh="$3" inp="$4" jsig="$5" jb="$6"
  CONFIGS+=("$name")
  CFG_MODE[$name]=$mode
  CFG_MAXHITS[$name]=$mh
  CFG_INPUT[$name]=$inp
  CFG_JSIG[$name]=$jsig
  CFG_JBOUND[$name]=$jb
}

for mode_name in multihit firsthit; do
  if [[ "$mode_name" == "multihit" ]]; then mode_val=0; else mode_val=1; fi
  for mh in 15 10 5; do
    for src_name in cal spad; do
      if [[ "$src_name" == "cal" ]]; then inp=1; else inp=0; fi
      for jit in nominal jitter; do
        if [[ "$jit" == "nominal" ]]; then jsig=0; jb=0; else jsig=8; jb=24; fi
        cfg_name="${mode_name}_${mh}_${src_name}_${jit}"
        add_config "$cfg_name" "$mode_val" "$mh" "$inp" "$jsig" "$jb"
      done
    done
  done
done

# ── filter configs ──────────────────────────────────────────────────────────
FILTERED=()
for c in "${CONFIGS[@]}"; do
  # shellcheck disable=SC2053
  if [[ "$c" == $CONFIG_FILTER ]]; then
    FILTERED+=("$c")
  fi
done

if [[ ${#FILTERED[@]} -eq 0 ]]; then
  echo "[ERROR] No configs match filter '$CONFIG_FILTER'"
  echo "        Available: ${CONFIGS[*]}"
  exit 1
fi

echo "[CAMPAIGN] Matched ${#FILTERED[@]} config(s), ${SEEDS_PER_CONFIG} seeds each, ${N_CONV} conv/seed"
echo "[CAMPAIGN] Parallelism: ${JOBS} jobs"
echo "[CAMPAIGN] Output: ${OUT_DIR}"
echo ""

# ── run one seed ────────────────────────────────────────────────────────────
run_seed() {
  local cfg="$1" seed_num="$2"
  local cfg_dir="${OUT_DIR}/${cfg}"
  local csv_file="${cfg_dir}/seed_${seed_num}.csv"
  local log_file="${cfg_dir}/seed_${seed_num}.log"

  mkdir -p "$cfg_dir"

  local mode="${CFG_MODE[$cfg]}"
  local mh="${CFG_MAXHITS[$cfg]}"
  local inp="${CFG_INPUT[$cfg]}"
  local jsig="${CFG_JSIG[$cfg]}"
  local jb="${CFG_JBOUND[$cfg]}"

  local cmd="$BINARY"
  cmd+=" +CAMPAIGN_MODE=${mode}"
  cmd+=" +CAMPAIGN_MAX_HITS=${mh}"
  cmd+=" +CAMPAIGN_INPUT_SEL=${inp}"
  cmd+=" +CAMPAIGN_N_CONV=${N_CONV}"
  cmd+=" +CAMPAIGN_DELAY_MIN_PS=${DELAY_MIN}"
  cmd+=" +CAMPAIGN_DELAY_MAX_PS=${DELAY_MAX}"
  cmd+=" +CAMPAIGN_SEED=${seed_num}"
  cmd+=" +CAMPAIGN_OUTPUT_FILE=${csv_file}"
  cmd+=" +OSC_JITTER_SIGMA_PS=${jsig}"
  cmd+=" +OSC_JITTER_BOUND_PS=${jb}"

  if (( DRY_RUN )); then
    echo "[DRY-RUN] $cmd"
    return 0
  fi

  $cmd > "$log_file" 2>&1
  local rc=$?

  if (( rc != 0 )); then
    echo "[FAIL] ${cfg}/seed_${seed_num} (rc=${rc})"
    return $rc
  fi

  # Quick validation: CSV should have >1 line (header + data)
  local lines
  lines=$(wc -l < "$csv_file" 2>/dev/null || echo 0)
  if (( lines < 2 )); then
    echo "[WARN] ${cfg}/seed_${seed_num}: CSV has ${lines} lines"
  fi

  return 0
}

export -f run_seed
export BINARY OUT_DIR N_CONV DELAY_MIN DELAY_MAX DRY_RUN

# Export associative arrays via temp file (bash limitation)
CFG_EXPORT_FILE=$(mktemp)
for cfg in "${FILTERED[@]}"; do
  echo "${cfg} ${CFG_MODE[$cfg]} ${CFG_MAXHITS[$cfg]} ${CFG_INPUT[$cfg]} ${CFG_JSIG[$cfg]} ${CFG_JBOUND[$cfg]}"
done > "$CFG_EXPORT_FILE"

# ── launch all seeds ────────────────────────────────────────────────────────
TOTAL_SEEDS=$(( ${#FILTERED[@]} * SEEDS_PER_CONFIG ))
COMPLETED=0
FAILED=0

echo "[CAMPAIGN] Starting ${TOTAL_SEEDS} seed runs..."
echo "==========================================================="

# Build job list (skip already-completed seeds for resume support)
JOB_LIST_FILE=$(mktemp)
SKIPPED=0
for cfg in "${FILTERED[@]}"; do
  for (( s = SEED_START; s < SEED_START + SEEDS_PER_CONFIG; s++ )); do
    csv_check="${OUT_DIR}/${cfg}/seed_${s}.csv"
    if [[ -f "$csv_check" ]] && (( $(wc -l < "$csv_check") > 10 )); then
      SKIPPED=$(( SKIPPED + 1 ))
    else
      echo "${cfg} ${s}"
    fi
  done
done > "$JOB_LIST_FILE"

ACTUAL_JOBS=$(wc -l < "$JOB_LIST_FILE")
echo "[CAMPAIGN] Skipped ${SKIPPED} already-complete seeds, ${ACTUAL_JOBS} remaining"

# Worker function that re-reads config from export file
worker() {
  local cfg="$1" seed_num="$2"
  local cfg_dir="${OUT_DIR}/${cfg}"
  local csv_file="${cfg_dir}/seed_${seed_num}.csv"
  local log_file="${cfg_dir}/seed_${seed_num}.log"

  mkdir -p "$cfg_dir"

  # Read config parameters
  local line
  line=$(grep "^${cfg} " "$CFG_EXPORT_FILE")
  local mode mh inp jsig jb
  read -r _ mode mh inp jsig jb <<< "$line"

  local cmd="$BINARY"
  cmd+=" +CAMPAIGN_MODE=${mode}"
  cmd+=" +CAMPAIGN_MAX_HITS=${mh}"
  cmd+=" +CAMPAIGN_INPUT_SEL=${inp}"
  cmd+=" +CAMPAIGN_N_CONV=${N_CONV}"
  cmd+=" +CAMPAIGN_DELAY_MIN_PS=${DELAY_MIN}"
  cmd+=" +CAMPAIGN_DELAY_MAX_PS=${DELAY_MAX}"
  cmd+=" +CAMPAIGN_SEED=${seed_num}"
  cmd+=" +CAMPAIGN_OUTPUT_FILE=${csv_file}"
  cmd+=" +OSC_JITTER_SIGMA_PS=${jsig}"
  cmd+=" +OSC_JITTER_BOUND_PS=${jb}"

  if (( DRY_RUN )); then
    echo "[DRY-RUN] $cmd"
    return 0
  fi

  $cmd > "$log_file" 2>&1
  local rc=$?

  if (( rc != 0 )); then
    echo "[FAIL] ${cfg}/seed_${seed_num} (rc=${rc})"
    return $rc
  fi

  local lines
  lines=$(wc -l < "$csv_file" 2>/dev/null || echo 0)
  echo "[DONE] ${cfg}/seed_${seed_num} — ${lines} rows"
  return 0
}

export -f worker
export CFG_EXPORT_FILE

# Use GNU parallel if available, otherwise xargs
if command -v parallel &>/dev/null; then
  echo "[CAMPAIGN] Using GNU parallel with ${JOBS} jobs"
  parallel --jobs "$JOBS" --colsep ' ' worker {1} {2} < "$JOB_LIST_FILE"
  RC=$?
else
  echo "[CAMPAIGN] Using xargs with ${JOBS} jobs"
  cat "$JOB_LIST_FILE" | xargs -P "$JOBS" -L 1 bash -c 'worker "$@"' _
  RC=$?
fi

# ── cleanup temp files ──────────────────────────────────────────────────────
rm -f "$CFG_EXPORT_FILE" "$JOB_LIST_FILE"

# ── summary ─────────────────────────────────────────────────────────────────
echo ""
echo "==========================================================="
echo "[CAMPAIGN] Run complete (exit code: ${RC})"

if (( ! DRY_RUN )); then
  TOTAL_CSV=$(find "$OUT_DIR" -name '*.csv' 2>/dev/null | wc -l)
  TOTAL_ROWS=0
  if (( TOTAL_CSV > 0 )); then
    TOTAL_ROWS=$(find "$OUT_DIR" -name '*.csv' -exec tail -n +2 {} + 2>/dev/null | wc -l)
  fi
  echo "[CAMPAIGN] CSV files: ${TOTAL_CSV}"
  echo "[CAMPAIGN] Total data rows: ${TOTAL_ROWS}"
  echo "[CAMPAIGN] Output directory: ${OUT_DIR}"

  # Check for failures (|| true prevents set -e from tripping on no-match)
  FAIL_COUNT=$(find "$OUT_DIR" -name '*.log' -exec grep -l 'ERROR\|FATAL\|FAIL' {} + 2>/dev/null | wc -l || true)
  if (( FAIL_COUNT > 0 )); then
    echo "[WARN] ${FAIL_COUNT} seed(s) had errors — check logs"
  fi
fi

exit $RC
