#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Purpose : Verilator-only standalone MPTDC characterization orchestration.
# Usage   : bash scripts/sim/run_characterization_overnight.sh [options]
#           --sim NAME      Simulator: verilator|xrun|xcelium (default verilator)
#           --jobs N        Parallel jobs (default 12)
#           --seed-start N  First seed (default 0)
#           --seeds N       Seeds per characterization stage
#           --out-dir DIR   Output root (default results/characterization/overnight_verilator)
#           --stages LIST   Comma-separated stages, or all
#           --smoke         Small shape-validation run
#           --overnight     Aggressive preset (default unless --smoke)
#           --analyze       Run Python analysis after collection
#           --rebuild       Rebuild Verilator binaries
#           --dry-run       Print commands without executing
# -----------------------------------------------------------------------------

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

SIM="verilator"
JOBS=12
SEED_START=0
SEEDS=24
OUT_DIR="$REPO_ROOT/results/characterization/overnight_verilator"
STAGES="all"
SMOKE=0
ANALYZE=0
REBUILD=0
DRY_RUN=0

# Aggressive defaults; --smoke overrides them below.
CODE_N_CONV=200000
DEAD_GAP_MIN_PS=0
DEAD_GAP_MAX_PS=80000
DEAD_GAP_STEP_PS=500
DEAD_TRIALS_PER_GAP=100
BOUNDARIES=32
BOUNDARY_REPEATS=20
CONTEXT_ATTEMPTS=800
THROUGHPUT_EVENTS=20000

usage() {
  sed -n '2,/^# -----------------------------------------------------------------------------$/{
    /^# -----------------------------------------------------------------------------$/d
    s/^# //p
  }' "$0"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sim) SIM="$2"; shift 2 ;;
    --jobs) JOBS="$2"; shift 2 ;;
    --seed-start) SEED_START="$2"; shift 2 ;;
    --seeds) SEEDS="$2"; shift 2 ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --stages) STAGES="$2"; shift 2 ;;
    --smoke) SMOKE=1; shift ;;
    --overnight) SMOKE=0; shift ;;
    --analyze) ANALYZE=1; shift ;;
    --rebuild) REBUILD=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[ERROR] Unknown option: $1" >&2; exit 1 ;;
  esac
done

case "$OUT_DIR" in
  /*) ;;
  *) OUT_DIR="$(pwd)/$OUT_DIR" ;;
esac

case "$SIM" in
  verilator) ;;
  xrun|xcelium) SIM="xrun" ;;
  *) echo "[ERROR] Unknown simulator '$SIM' (use verilator, xrun, or xcelium)" >&2; exit 1 ;;
esac
BUILD_ROOT="$REPO_ROOT/build/char_${SIM}"

if (( SMOKE )); then
  SEEDS=1
  CODE_N_CONV=200
  DEAD_GAP_MIN_PS=0
  DEAD_GAP_MAX_PS=20000
  DEAD_GAP_STEP_PS=5000
  DEAD_TRIALS_PER_GAP=2
  BOUNDARIES=2
  BOUNDARY_REPEATS=1
  CONTEXT_ATTEMPTS=20
  THROUGHPUT_EVENTS=50
  echo "[CHAR] Smoke mode enabled"
else
  echo "[CHAR] Aggressive overnight mode enabled"
fi

if ! command -v "$SIM" >/dev/null 2>&1 && (( ! DRY_RUN )); then
  echo "[ERROR] $SIM not found in PATH" >&2
  exit 1
fi

has_gnu_parallel() {
  command -v parallel >/dev/null 2>&1 || return 1
  parallel --version 2>/dev/null | grep -q '^GNU parallel'
}

stage_enabled() {
  local stage="$1"
  [[ "$STAGES" == "all" ]] && return 0
  local normalized=",${STAGES// /},"
  [[ "$normalized" == *",$stage,"* ]]
}

tb_for_stage() {
  case "$1" in
    code_density) echo "tb_char_code_density" ;;
    deadtime) echo "tb_char_deadtime_persistent" ;;
    boundary) echo "tb_char_boundary_stress" ;;
    context_overflow) echo "tb_char_context_overflow" ;;
    throughput) echo "tb_char_throughput_backpressure" ;;
    *) return 1 ;;
  esac
}

print_cmd() {
  local prefix="$1"; shift
  printf '%s' "$prefix"
  for arg in "$@"; do
    printf ' %q' "$arg"
  done
  printf '\n'
}

build_tb() {
  local tb="$1"
  if [[ "$SIM" == "xrun" ]]; then
    echo "[CHAR] xrun will compile $tb per seed with isolated worklibs"
    return 0
  fi
  local mdir="$BUILD_ROOT/$tb"
  local bin="$mdir/$tb"
  local needs_build="$REBUILD"
  if [[ ! -x "$bin" ]]; then
    needs_build=1
  elif find "$REPO_ROOT/rtl" "$REPO_ROOT/tb/common" "$REPO_ROOT/tb/int/${tb}.sv" \
      -type f -newer "$bin" -print -quit | grep -q .; then
    needs_build=1
  fi
  if [[ "$needs_build" -eq 0 ]]; then
    echo "[CHAR] Reusing up-to-date $tb"
    return 0
  fi
  mkdir -p "$mdir"
  local cmd=(
    verilator --binary --timing -j 4
    +define+MPTDC_USE_OSC_MODEL
    -f "$REPO_ROOT/rtl/filelist.f"
    "$REPO_ROOT/tb/common/mptdc_tb_pkg.sv"
    "$REPO_ROOT/tb/common/mptdc_char_tb_pkg.sv"
    "$REPO_ROOT/tb/common/mptdc_raw_monitor.sv"
    "$REPO_ROOT/tb/int/${tb}.sv"
    --top-module "$tb"
    -o "$tb"
    -Mdir "$mdir"
    -Wno-fatal
  )
  if (( DRY_RUN )); then
    print_cmd "[DRY-RUN]" "${cmd[@]}"
  else
    echo "[CHAR] Building $tb"
    (cd "$REPO_ROOT" && "${cmd[@]}") 2>&1 | tail -10
  fi
}

stage_plusargs() {
  local stage="$1"
  case "$stage" in
    code_density)
      printf '%s\n' \
        "+CHAR_N_CONV=${CODE_N_CONV}" \
        "+CHAR_MAX_HITS=15" \
        "+CHAR_INPUT_SEL=1" \
        "+CHAR_OUT_MODE=2"
      ;;
    deadtime)
      printf '%s\n' \
        "+CHAR_GAP_MIN_PS=${DEAD_GAP_MIN_PS}" \
        "+CHAR_GAP_MAX_PS=${DEAD_GAP_MAX_PS}" \
        "+CHAR_GAP_STEP_PS=${DEAD_GAP_STEP_PS}" \
        "+CHAR_TRIALS_PER_GAP=${DEAD_TRIALS_PER_GAP}" \
        "+CHAR_MAX_HITS=1" \
        "+CHAR_INPUT_SEL=1" \
        "+CHAR_OUT_MODE=0"
      ;;
    boundary)
      printf '%s\n' \
        "+CHAR_BOUNDARIES=${BOUNDARIES}" \
        "+CHAR_REPEATS=${BOUNDARY_REPEATS}" \
        "+CHAR_MAX_HITS=15" \
        "+CHAR_INPUT_SEL=1" \
        "+CHAR_OUT_MODE=2"
      ;;
    context_overflow)
      printf '%s\n' \
        "+CHAR_ATTEMPTS=${CONTEXT_ATTEMPTS}" \
        "+CHAR_MAX_HITS=15" \
        "+CHAR_INPUT_SEL=1" \
        "+CHAR_OUT_MODE=0"
      ;;
    throughput)
      printf '%s\n' \
        "+CHAR_N_EVENTS=${THROUGHPUT_EVENTS}" \
        "+CHAR_READY_DUTY_PCT=50" \
        "+CHAR_MAX_HITS=15" \
        "+CHAR_INPUT_SEL=1" \
        "+CHAR_OUT_MODE=0"
      ;;
  esac
}

run_worker() {
  local stage="$1" seed="$2"
  local tb
  tb="$(tb_for_stage "$stage")"
  local bin="$BUILD_ROOT/$tb/$tb"
  local stage_dir="$OUT_DIR/stages/$stage"
  local csv="$stage_dir/seed_${seed}.csv"
  local log="$stage_dir/seed_${seed}.log"

  mkdir -p "$stage_dir"
  if [[ -f "$csv" ]] && [[ -f "$log" ]] && grep -q '\[CHAR\].*complete' "$log" \
      && (( $(wc -l < "$csv") > 1 )); then
    echo "[SKIP] $stage seed=$seed already complete"
    return 0
  fi
  rm -f "$csv" "$log"

  mapfile -t plusargs < <(stage_plusargs "$stage")
  local cmd=()
  if [[ "$SIM" == "verilator" ]]; then
    cmd=(
      "$bin"
      "+CHAR_SEED=${seed}"
      "+CHAR_OUTPUT_FILE=${csv}"
      "+CHAR_CONFIG=${stage}"
      "${plusargs[@]}"
    )
  else
    local work_dir="$BUILD_ROOT/$stage/seed_${seed}"
    mkdir -p "$work_dir"
    cmd=(
      xrun
      -64 -sv -access +rwc
      -timescale 1ps/1ps
      -nowarn DLCVAR
      -top "$tb"
      +define+MPTDC_USE_OSC_MODEL
      -f "$REPO_ROOT/rtl/filelist.f"
      "$REPO_ROOT/tb/common/mptdc_tb_pkg.sv"
      "$REPO_ROOT/tb/common/mptdc_char_tb_pkg.sv"
      "$REPO_ROOT/tb/common/mptdc_raw_monitor.sv"
      "$REPO_ROOT/tb/int/${tb}.sv"
      -xmlibdirname "$work_dir/xcelium.d"
      "+CHAR_SEED=${seed}"
      "+CHAR_OUTPUT_FILE=${csv}"
      "+CHAR_CONFIG=${stage}"
      "${plusargs[@]}"
    )
  fi
  if (( DRY_RUN )); then
    print_cmd "[DRY-RUN]" "${cmd[@]}"
    return 0
  fi
  (cd "$REPO_ROOT" && "${cmd[@]}") > "$log" 2>&1
  local rc=$?
  if (( rc != 0 )); then
    echo "[FAIL] $stage seed=$seed rc=$rc"
    return "$rc"
  fi
  echo "[DONE] $stage seed=$seed rows=$(wc -l < "$csv")"
}

export -f tb_for_stage print_cmd stage_plusargs run_worker
export REPO_ROOT BUILD_ROOT OUT_DIR DRY_RUN SIM
export CODE_N_CONV DEAD_GAP_MIN_PS DEAD_GAP_MAX_PS DEAD_GAP_STEP_PS DEAD_TRIALS_PER_GAP
export BOUNDARIES BOUNDARY_REPEATS CONTEXT_ATTEMPTS THROUGHPUT_EVENTS

ALL_STAGES=(code_density deadtime boundary context_overflow throughput)
SELECTED_STAGES=()
for stage in "${ALL_STAGES[@]}"; do
  if stage_enabled "$stage"; then
    SELECTED_STAGES+=("$stage")
  fi
done

if (( ${#SELECTED_STAGES[@]} == 0 )); then
  echo "[ERROR] No stages selected" >&2
  exit 1
fi

mkdir -p "$OUT_DIR/stages" "$OUT_DIR/logs"

echo "[CHAR] Output: $OUT_DIR"
echo "[CHAR] Simulator: $SIM"
echo "[CHAR] Stages: ${SELECTED_STAGES[*]}"
echo "[CHAR] Seeds per stage: $SEEDS (start=$SEED_START)"
echo "[CHAR] Parallel jobs: $JOBS"

for stage in "${SELECTED_STAGES[@]}"; do
  build_tb "$(tb_for_stage "$stage")"
done

JOB_LIST="$(mktemp)"
for stage in "${SELECTED_STAGES[@]}"; do
  for (( seed=SEED_START; seed<SEED_START+SEEDS; seed++ )); do
    echo "$stage $seed"
  done
done > "$JOB_LIST"

if has_gnu_parallel; then
  parallel --jobs "$JOBS" --colsep ' ' run_worker {1} {2} < "$JOB_LIST"
else
  xargs -r -P "$JOBS" -L 1 bash -c 'run_worker "$@"' _ < "$JOB_LIST"
fi
rm -f "$JOB_LIST"

MANIFEST="$OUT_DIR/characterization_manifest.json"
if (( ! DRY_RUN )); then
  export CHAR_MANIFEST="$MANIFEST"
  export CHAR_OUT_DIR="$OUT_DIR"
  export CHAR_JOBS="$JOBS"
  export CHAR_SEEDS="$SEEDS"
  export CHAR_SEED_START="$SEED_START"
  export CHAR_STAGES="${SELECTED_STAGES[*]}"
  export CHAR_SMOKE="$SMOKE"
  export CHAR_SIM="$SIM"
  export CHAR_GIT_SHA
  CHAR_GIT_SHA="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
  python3 - <<'PY'
import json
import os
from pathlib import Path

root = Path(os.environ["CHAR_OUT_DIR"])
csvs = sorted(root.glob("stages/*/seed_*.csv"))
rows = 0
for path in csvs:
    try:
        with path.open("r", encoding="utf-8") as handle:
            rows += max(sum(1 for _ in handle) - 1, 0)
    except OSError:
        pass

data = {
    "name": "mptdc-standalone-characterization",
    "simulator": os.environ["CHAR_SIM"],
    "jobs": int(os.environ["CHAR_JOBS"]),
    "seed_start": int(os.environ["CHAR_SEED_START"]),
    "seeds_per_stage": int(os.environ["CHAR_SEEDS"]),
    "stages": os.environ["CHAR_STAGES"].split(),
    "smoke": os.environ["CHAR_SMOKE"] == "1",
    "git_sha": os.environ["CHAR_GIT_SHA"],
    "paths": {"root": str(root), "stages": str(root / "stages")},
    "summary": {"csv_files": len(csvs), "data_rows": rows},
}
Path(os.environ["CHAR_MANIFEST"]).write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
  echo "[CHAR] Manifest: $MANIFEST"
fi

if (( ANALYZE )); then
  cmd=(python3 "$REPO_ROOT/scripts/analysis/analyze_characterization_overnight.py"
       --root "$OUT_DIR"
       --output-dir "$OUT_DIR/analysis")
  if (( DRY_RUN )); then
    print_cmd "[DRY-RUN]" "${cmd[@]}"
  else
    "${cmd[@]}"
  fi
fi

echo "[CHAR] Done"
