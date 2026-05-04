#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Purpose : Orchestrate a full data-collection campaign across all TDC
#           configurations. Builds the collection testbench once for Verilator,
#           or launches one xrun/xcelium job per seed with a unique worklib.
# Usage   : bash scripts/sim/run_campaign.sh [options]
#           --sim NAME       Simulator: verilator|xrun|xcelium (default verilator)
#           --jobs N         Parallel seeds (default 12)
#           --seeds N        Seeds per config (default 30)
#           --n-conv N       Conversions per seed (default 50000)
#           --delay-min N    Min delay in ps (default 20)
#           --delay-max N    Max delay in ps (default 30000)
#           --seed-start N   First PRNG seed number (default 0)
#           --configs GLOB   Config name filter glob (default '*')
#           --out-mode NAME  Serializer mode: full|raw_features (default full)
#           --jitter-sigma N Override oscillator jitter sigma in ps
#           --jitter-bound N Override oscillator jitter bound in ps
#           --out-dir DIR    Output directory (default results/campaign)
#           --rebuild        Force rebuild / clean simulator workdir
#           --dry-run        Print what would run without executing
#           --smoke          Quick smoke: 1 config, 1 seed, 100 conv
# Notes   : Active v2.4 RTL has no FIRST_HIT mode bit. Compatibility-named
#           firsthit_* configs are driven as fast-close runs via max_hits=1.
# Author  : Karim Sabra
# -----------------------------------------------------------------------------

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$REPO_ROOT/build"
OBJ_DIR="$BUILD_DIR/obj_dir_campaign"
BINARY="$OBJ_DIR/tb_campaign_collect"
XRUN_BUILD_ROOT="$BUILD_DIR/campaign_xrun"

# ── defaults ────────────────────────────────────────────────────────────────
SIM="verilator"
JOBS=12
SEEDS_PER_CONFIG=30
N_CONV=50000
DELAY_MIN=20
DELAY_MAX=30000
SEED_START=0
CONFIG_FILTER="*"
OUT_MODE="full"
OUT_MODE_ENUM=2
JITTER_SIGMA_OVERRIDE=""
JITTER_BOUND_OVERRIDE=""
OUT_DIR="$REPO_ROOT/results/campaign"
REBUILD=0
DRY_RUN=0
SMOKE=0

print_cmd() {
  local prefix="$1"
  shift
  printf '%s' "$prefix"
  for arg in "$@"; do
    printf ' %q' "$arg"
  done
  printf '\n'
}

print_cd_cmd() {
  local dir="$1"
  shift
  printf '[DRY-RUN] (cd %q &&' "$dir"
  for arg in "$@"; do
    printf ' %q' "$arg"
  done
  printf ' )\n'
}

sanitize_path_token() {
  local token="$1"
  token="${token//\//_}"
  token="${token// /_}"
  token="${token//[^A-Za-z0-9_.-]/_}"
  printf '%s' "$token"
}

has_gnu_parallel() {
  command -v parallel >/dev/null 2>&1 || return 1
  parallel --version 2>/dev/null | grep -q '^GNU parallel'
}

config_output_name() {
  local base_cfg="$1"
  local jsig="$2"
  local jb="$3"
  local name="$base_cfg"

  if [[ "$OUT_MODE" != "full" ]]; then
    name+="_${OUT_MODE}"
  fi
  if [[ -n "$JITTER_SIGMA_OVERRIDE" || -n "$JITTER_BOUND_OVERRIDE" ]]; then
    name+="_js${jsig}_jb${jb}"
  fi
  printf '%s' "$name"
}

# ── parse arguments ────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sim)        SIM="$2";              shift 2 ;;
    --jobs)       JOBS="$2";             shift 2 ;;
    --seeds)      SEEDS_PER_CONFIG="$2"; shift 2 ;;
    --n-conv)     N_CONV="$2";           shift 2 ;;
    --delay-min)  DELAY_MIN="$2";        shift 2 ;;
    --delay-max)  DELAY_MAX="$2";        shift 2 ;;
    --seed-start) SEED_START="$2";       shift 2 ;;
    --configs)    CONFIG_FILTER="$2";    shift 2 ;;
    --out-mode)   OUT_MODE="$2";         shift 2 ;;
    --jitter-sigma) JITTER_SIGMA_OVERRIDE="$2"; shift 2 ;;
    --jitter-bound) JITTER_BOUND_OVERRIDE="$2"; shift 2 ;;
    --out-dir)    OUT_DIR="$2";          shift 2 ;;
    --rebuild)    REBUILD=1;              shift ;;
    --dry-run)    DRY_RUN=1;              shift ;;
    --smoke)      SMOKE=1;                shift ;;
    -h|--help)
      sed -n '2,/^# ---/{ /^# ---/d; s/^# //; p }' "$0"
      exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

case "$SIM" in
  verilator) ;;
  xrun|xcelium) SIM="xrun" ;;
  *)
    echo "[ERROR] Unknown simulator '$SIM' (use verilator, xrun, or xcelium)"
    exit 1
    ;;
esac

case "$OUT_MODE" in
  full|2) OUT_MODE="full"; OUT_MODE_ENUM=2 ;;
  raw_features|raw|0) OUT_MODE="raw_features"; OUT_MODE_ENUM=0 ;;
  *)
    echo "[ERROR] Unknown out mode '$OUT_MODE' (use full or raw_features)"
    exit 1
    ;;
esac

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

# ── smoke mode overrides ───────────────────────────────────────────────────
if (( SMOKE )); then
  SEEDS_PER_CONFIG=1
  N_CONV=100
  CONFIG_FILTER="multihit_15_cal_nominal"
  echo "[CAMPAIGN] Smoke mode: 1 config, 1 seed, 100 conversions"
fi

# ── simulator preparation ───────────────────────────────────────────────────
build_tb() {
  local -a cmd=(
    verilator --binary --timing -j 4
    +define+MPTDC_USE_OSC_MODEL
    -f "$REPO_ROOT/rtl/filelist.f"
    "$REPO_ROOT/tb/common/mptdc_tb_pkg.sv"
    "$REPO_ROOT/tb/common/mptdc_raw_monitor.sv"
    "$REPO_ROOT/tb/int/tb_campaign_collect.sv"
    --top-module tb_campaign_collect
    -o tb_campaign_collect
    -Mdir "$OBJ_DIR"
    -Wno-fatal
  )

  if (( DRY_RUN )); then
    print_cmd "[DRY-RUN]" "${cmd[@]}"
    return 0
  fi

  echo "[CAMPAIGN] Building collection testbench with Verilator..."
  mkdir -p "$BUILD_DIR"
  "${cmd[@]}" 2>&1 | tail -5
  echo "[CAMPAIGN] Build complete: $BINARY"
}

prepare_sim() {
  case "$SIM" in
    verilator)
      if (( DRY_RUN )); then
        if [[ ! -x "$BINARY" ]] || (( REBUILD )); then
          build_tb
        fi
        return 0
      fi
      if ! command -v verilator >/dev/null 2>&1; then
        echo "[ERROR] Verilator not found in PATH"
        exit 1
      fi
      if [[ ! -x "$BINARY" ]] || (( REBUILD )); then
        build_tb
      fi
      if [[ ! -x "$BINARY" ]]; then
        echo "[ERROR] Binary not found at $BINARY"
        exit 1
      fi
      ;;

    xrun)
      if (( ! DRY_RUN )) && ! command -v xrun >/dev/null 2>&1; then
        echo "[ERROR] xrun not found in PATH"
        exit 1
      fi
      if (( ! DRY_RUN && REBUILD )) && [[ -d "$XRUN_BUILD_ROOT" ]]; then
        rm -rf "$XRUN_BUILD_ROOT"
      fi
      mkdir -p "$XRUN_BUILD_ROOT"
      ;;
  esac
}

prepare_sim

# ── config enumeration ──────────────────────────────────────────────────────
#  mode: multihit (0), firsthit-compat fast-close (1)
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
echo "[CAMPAIGN] Simulator: ${SIM}"
echo "[CAMPAIGN] Out mode: ${OUT_MODE}"
if [[ -n "$JITTER_SIGMA_OVERRIDE" ]]; then
  echo "[CAMPAIGN] Jitter override: sigma=${JITTER_SIGMA_OVERRIDE} ps, bound=${JITTER_BOUND_OVERRIDE} ps"
fi
echo "[CAMPAIGN] Parallelism: ${JOBS} jobs"
echo "[CAMPAIGN] Output: ${OUT_DIR}"
echo ""

# Export associative arrays via temp file (bash limitation)
CFG_EXPORT_FILE=$(mktemp)
for cfg in "${FILTERED[@]}"; do
  echo "${cfg} ${CFG_MODE[$cfg]} ${CFG_MAXHITS[$cfg]} ${CFG_INPUT[$cfg]} ${CFG_JSIG[$cfg]} ${CFG_JBOUND[$cfg]}"
done > "$CFG_EXPORT_FILE"
export CFG_EXPORT_FILE

worker() {
  local cfg="$1" seed_num="$2"
  local line
  line=$(grep "^${cfg} " "$CFG_EXPORT_FILE")
  local mode mh inp jsig jb
  read -r _ mode mh inp jsig jb <<< "$line"
  local effective_mh="$mh"
  if [[ "$mode" -eq 1 ]]; then
    effective_mh=1
  fi

  if [[ -n "$JITTER_SIGMA_OVERRIDE" ]]; then
    jsig="$JITTER_SIGMA_OVERRIDE"
    jb="$JITTER_BOUND_OVERRIDE"
  fi

  local cfg_tag
  cfg_tag="$(config_output_name "$cfg" "$jsig" "$jb")"
  local cfg_dir="${OUT_DIR}/${cfg_tag}"
  local csv_file="${cfg_dir}/seed_${seed_num}.csv"
  local log_file="${cfg_dir}/seed_${seed_num}.log"

  mkdir -p "$cfg_dir"

  local rc=0
  local -a cmd

  case "$SIM" in
    verilator)
      cmd=(
        "$BINARY"
        "+CAMPAIGN_MODE=${mode}"
        "+CAMPAIGN_MAX_HITS=${effective_mh}"
        "+CAMPAIGN_INPUT_SEL=${inp}"
        "+CAMPAIGN_N_CONV=${N_CONV}"
        "+CAMPAIGN_DELAY_MIN_PS=${DELAY_MIN}"
        "+CAMPAIGN_DELAY_MAX_PS=${DELAY_MAX}"
        "+CAMPAIGN_SEED=${seed_num}"
        "+CAMPAIGN_OUTPUT_FILE=${csv_file}"
        "+CAMPAIGN_OUT_MODE=${OUT_MODE_ENUM}"
        "+OSC_JITTER_SIGMA_PS=${jsig}"
        "+OSC_JITTER_BOUND_PS=${jb}"
      )
      if (( DRY_RUN )); then
        print_cmd "[DRY-RUN]" "${cmd[@]}"
        return 0
      fi
      "${cmd[@]}" > "$log_file" 2>&1
      rc=$?
      ;;

    xrun)
      local work_dir="${XRUN_BUILD_ROOT}/$(sanitize_path_token "$cfg_tag")/seed_${seed_num}"
      mkdir -p "$work_dir"
      cmd=(
        xrun
        -64 -sv -access +rwc
        -timescale 1ps/1ps
        -nowarn DLCVAR
        -top tb_campaign_collect
        +define+MPTDC_USE_OSC_MODEL
        -f "$REPO_ROOT/rtl/filelist.f"
        "$REPO_ROOT/tb/common/mptdc_tb_pkg.sv"
        "$REPO_ROOT/tb/common/mptdc_raw_monitor.sv"
        "$REPO_ROOT/tb/int/tb_campaign_collect.sv"
        -xmlibdirname "$work_dir/xcelium.d"
        "+CAMPAIGN_MODE=${mode}"
        "+CAMPAIGN_MAX_HITS=${effective_mh}"
        "+CAMPAIGN_INPUT_SEL=${inp}"
        "+CAMPAIGN_N_CONV=${N_CONV}"
        "+CAMPAIGN_DELAY_MIN_PS=${DELAY_MIN}"
        "+CAMPAIGN_DELAY_MAX_PS=${DELAY_MAX}"
        "+CAMPAIGN_SEED=${seed_num}"
        "+CAMPAIGN_OUTPUT_FILE=${csv_file}"
        "+CAMPAIGN_OUT_MODE=${OUT_MODE_ENUM}"
        "+OSC_JITTER_SIGMA_PS=${jsig}"
        "+OSC_JITTER_BOUND_PS=${jb}"
      )
      if (( DRY_RUN )); then
        print_cd_cmd "$REPO_ROOT" "${cmd[@]}"
        return 0
      fi
      (cd "$REPO_ROOT" && "${cmd[@]}") > "$log_file" 2>&1
      rc=$?
      ;;
  esac

  if (( rc != 0 )); then
    echo "[FAIL] ${cfg}/seed_${seed_num} (rc=${rc})"
    return "$rc"
  fi

  local lines
  lines=$(wc -l < "$csv_file" 2>/dev/null || echo 0)
  if (( lines < 2 )); then
    echo "[WARN] ${cfg}/seed_${seed_num}: CSV has ${lines} lines"
  else
    echo "[DONE] ${cfg}/seed_${seed_num} — ${lines} rows"
  fi
  return 0
}

export -f worker print_cmd print_cd_cmd sanitize_path_token config_output_name
export REPO_ROOT BINARY XRUN_BUILD_ROOT OUT_DIR N_CONV DELAY_MIN DELAY_MAX DRY_RUN SIM OUT_MODE OUT_MODE_ENUM JITTER_SIGMA_OVERRIDE JITTER_BOUND_OVERRIDE

# ── launch all seeds ────────────────────────────────────────────────────────
TOTAL_SEEDS=$(( ${#FILTERED[@]} * SEEDS_PER_CONFIG ))

echo "[CAMPAIGN] Starting ${TOTAL_SEEDS} seed runs..."
echo "==========================================================="

# Build job list (skip already-completed seeds for resume support)
JOB_LIST_FILE=$(mktemp)
SKIPPED=0
for cfg in "${FILTERED[@]}"; do
  for (( s = SEED_START; s < SEED_START + SEEDS_PER_CONFIG; s++ )); do
    line=$(grep "^${cfg} " "$CFG_EXPORT_FILE")
    read -r _ _ _ _ jsig jb <<< "$line"
    if [[ -n "$JITTER_SIGMA_OVERRIDE" ]]; then
      jsig="$JITTER_SIGMA_OVERRIDE"
      jb="$JITTER_BOUND_OVERRIDE"
    fi
    cfg_tag="$(config_output_name "$cfg" "$jsig" "$jb")"
    csv_check="${OUT_DIR}/${cfg_tag}/seed_${s}.csv"
    if [[ -f "$csv_check" ]] && (( $(wc -l < "$csv_check") > 10 )); then
      SKIPPED=$(( SKIPPED + 1 ))
    else
      echo "${cfg} ${s}"
    fi
  done
done > "$JOB_LIST_FILE"

ACTUAL_JOBS=$(wc -l < "$JOB_LIST_FILE")
echo "[CAMPAIGN] Skipped ${SKIPPED} already-complete seeds, ${ACTUAL_JOBS} remaining"

if (( ACTUAL_JOBS == 0 )); then
  echo "[CAMPAIGN] Nothing to run after resume check"
  RC=0
else
  # Use GNU parallel if available, otherwise xargs. Some Cadence installs ship a
  # different `parallel` helper that is not GNU parallel and must not be used here.
  if has_gnu_parallel; then
    echo "[CAMPAIGN] Using GNU parallel with ${JOBS} jobs"
    parallel --jobs "$JOBS" --colsep ' ' worker {1} {2} < "$JOB_LIST_FILE"
    RC=$?
  else
    echo "[CAMPAIGN] Using xargs with ${JOBS} jobs"
    xargs -r -P "$JOBS" -L 1 bash -c 'worker "$@"' _ < "$JOB_LIST_FILE"
    RC=$?
  fi
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

  FAIL_COUNT=$(find "$OUT_DIR" -name '*.log' -exec grep -l 'ERROR\|FATAL\|FAIL' {} + 2>/dev/null | wc -l || true)
  if (( FAIL_COUNT > 0 )); then
    echo "[WARN] ${FAIL_COUNT} seed(s) had errors — check logs"
  fi
fi

exit $RC
