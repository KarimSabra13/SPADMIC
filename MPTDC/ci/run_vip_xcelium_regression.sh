#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Purpose : VIP Xcelium CDV regression manager.
# Usage   : bash ci/run_vip_xcelium_regression.sh [options] [test ...]
#           --jobs N --seed-start N --seeds N --out-dir DIR --dry-run
# Notes   : Primary runs are wave-light. Failing seeds are rerun with deep waves
#           into an isolated failures/ directory for morning debug.
# -----------------------------------------------------------------------------

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER="$ROOT/scripts/sim/run_vip_test.sh"

SIM="xrun"
JOBS=32
SEED_START=1000
SEEDS=32
NUM_CONV=0
OUT_DIR="$ROOT/build/vip_xcelium"
DRY_RUN=0
CLEAN=0
RERUN_FAILURES=1

DEFAULT_TESTS=(
  smoke_single_conv
  full_mode_timestamp
  firsthit_contract
  backpressure_integrity
  start_watchdog
  cal_inject
  overflow_status
  long_random
  multi_conv_rearm_stress
  global_watchdog_recovery
  csr_readback_control
  hard_reset_readback
  coverage_exhaustive
  stress_random
  vip_ref_stop_cdv
  vip_maxhits_matrix
)

SELECTED_TESTS=()

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
    --num-conv) NUM_CONV="$2"; shift 2 ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --clean) CLEAN=1; shift ;;
    --no-rerun) RERUN_FAILURES=0; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) SELECTED_TESTS+=("$1"); shift ;;
  esac
done

case "$SIM" in
  xrun|xcelium) ;;
  *) echo "Error: VIP CDV requires --sim xrun|xcelium" >&2; exit 1 ;;
esac

case "$OUT_DIR" in
  /*) ;;
  *) OUT_DIR="$ROOT/$OUT_DIR" ;;
esac

TESTS=("${DEFAULT_TESTS[@]}")
if (( ${#SELECTED_TESTS[@]} > 0 )); then
  TESTS=("${SELECTED_TESTS[@]}")
fi

if (( ! DRY_RUN )) && ! command -v xrun >/dev/null 2>&1; then
  echo "Error: xrun not found; use --dry-run locally or run on a Cadence machine." >&2
  exit 1
fi

if (( CLEAN )) && (( ! DRY_RUN )); then
  rm -rf "$OUT_DIR"
fi

mkdir -p "$OUT_DIR"/{logs,artifacts,failures,cov_work}

MANIFEST="$OUT_DIR/vip_manifest.jsonl"
SUMMARY="$OUT_DIR/vip_summary.json"
JOB_LIST="$OUT_DIR/jobs.txt"
FAIL_LIST="$OUT_DIR/failures.txt"
: > "$MANIFEST"
: > "$JOB_LIST"
: > "$FAIL_LIST"

for seed_idx in $(seq 0 "$((SEEDS - 1))"); do
  seed="$((SEED_START + seed_idx))"
  for test_name in "${TESTS[@]}"; do
    echo "$test_name $seed" >> "$JOB_LIST"
  done
done

run_one() {
  local test_name="$1"
  local seed="$2"
  local root="$3"
  local sim="$4"
  local num_conv="$5"
  local dry_run="$6"
  local runner="$7"

  local run_id="${test_name}__seed_${seed}"
  local log_dir="$root/logs"
  local artifact_dir="$root/artifacts/$run_id"
  local log="$log_dir/$run_id.log"
  local cmd=(
    bash "$runner" "$test_name"
    --sim "$sim"
    --seed "$seed"
    --stop-model qualified-ref
    --func-cov
    --code-cov
    --cov-workdir "$root/cov_work"
    --cov-test-name "$run_id"
    --artifact-dir "$artifact_dir"
    --vip-asserts
  )

  if [[ "$num_conv" != "0" ]]; then
    cmd+=(--num-conv "$num_conv")
  fi

  mkdir -p "$artifact_dir" "$log_dir"
  printf '%q ' "${cmd[@]}" > "$artifact_dir/command.sh"
  printf '\n' >> "$artifact_dir/command.sh"

  if [[ "$dry_run" == "1" ]]; then
    echo "[DRY-RUN] ${cmd[*]}"
    return 0
  fi

  if "${cmd[@]}" >"$log" 2>&1; then
    echo "{\"test\":\"$test_name\",\"seed\":$seed,\"status\":\"pass\",\"artifact_dir\":\"$artifact_dir\",\"log\":\"$log\"}" >> "$root/vip_manifest.jsonl"
    return 0
  fi

  tail -200 "$log" > "$artifact_dir/transcript_tail.log" || true
  echo "$test_name $seed" >> "$root/failures.txt"
  echo "{\"test\":\"$test_name\",\"seed\":$seed,\"status\":\"fail\",\"artifact_dir\":\"$artifact_dir\",\"log\":\"$log\"}" >> "$root/vip_manifest.jsonl"
  return 1
}

export -f run_one
export ROOT RUNNER OUT_DIR SIM NUM_CONV DRY_RUN

echo "[VIP-CDV] Tests: ${TESTS[*]}"
echo "[VIP-CDV] Seeds: $SEEDS from $SEED_START"
echo "[VIP-CDV] Jobs:  $JOBS"
echo "[VIP-CDV] Out:   $OUT_DIR"

set +e
if command -v parallel >/dev/null 2>&1 && parallel --version 2>/dev/null | grep -q '^GNU parallel'; then
  parallel --jobs "$JOBS" --colsep ' ' run_one {1} {2} "$OUT_DIR" "$SIM" "$NUM_CONV" "$DRY_RUN" "$RUNNER" < "$JOB_LIST"
  RC=$?
else
  xargs -r -P "$JOBS" -L 1 bash -c 'run_one "$1" "$2" "$OUT_DIR" "$SIM" "$NUM_CONV" "$DRY_RUN" "$RUNNER"' _ < "$JOB_LIST"
  RC=$?
fi
set -e

if (( RERUN_FAILURES )) && (( DRY_RUN == 0 )) && [[ -s "$FAIL_LIST" ]]; then
  while read -r test_name seed; do
    run_id="${test_name}__seed_${seed}"
    fail_dir="$OUT_DIR/failures/$run_id"
    mkdir -p "$fail_dir"
    bash "$RUNNER" "$test_name" \
      --sim "$SIM" \
      --seed "$seed" \
      --stop-model qualified-ref \
      --waves \
      --func-cov \
      --code-cov \
      --cov-workdir "$OUT_DIR/cov_work" \
      --cov-test-name "${run_id}__debug" \
      --artifact-dir "$fail_dir" \
      --vip-asserts \
      > "$fail_dir/rerun.log" 2>&1 </dev/null || true
    tail -200 "$fail_dir/rerun.log" > "$fail_dir/transcript_tail.log" || true
  done < "$FAIL_LIST"
fi

if (( DRY_RUN == 0 )); then
  python3 - "$MANIFEST" "$SUMMARY" <<'PY'
import json
import sys
from pathlib import Path

manifest = Path(sys.argv[1])
summary = Path(sys.argv[2])
rows = []
if manifest.exists():
    rows = [json.loads(line) for line in manifest.read_text().splitlines() if line.strip()]
data = {
    "total": len(rows),
    "pass": sum(1 for row in rows if row.get("status") == "pass"),
    "fail": sum(1 for row in rows if row.get("status") == "fail"),
    "failures": [row for row in rows if row.get("status") == "fail"],
}
summary.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
print(json.dumps(data, indent=2))
PY
fi

exit "$RC"
