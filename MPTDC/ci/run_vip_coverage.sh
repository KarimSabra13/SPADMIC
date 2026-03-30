#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Purpose : Run the stable VIP coverage regression on a Cadence-capable
#           simulator and shared coverage work area.
# Usage   : bash ci/run_vip_coverage.sh [test_name ...]
#           [--sim xrun|xcelium] [--cov-root DIR] [--seed-base N]
#           [--waves] [--clean] [--dry-run] [--list-tests]
# Context : Intended for Cadence-equipped environments; --dry-run stages
#           the commands locally without invoking xrun.
# Author  : Karim Sabra
# -----------------------------------------------------------------------------

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNNER="$ROOT/scripts/sim/run_vip_test.sh"
SIM="xrun"
WAVES=0
DRY_RUN=0
LIST_ONLY=0
CLEAN=0
SEED_BASE=""
COV_ROOT=""
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
  jitter_robustness
  csr_readback_control
  hard_reset_readback
  coverage_exhaustive
)
SELECTED_TESTS=()

normalize_repo_path() {
  local raw_path="$1"
  if [[ "$raw_path" == /* ]]; then
    printf '%s\n' "$raw_path"
  else
    printf '%s\n' "$ROOT/$raw_path"
  fi
}

ensure_repo_path() {
  local checked_path="$1"
  case "$checked_path" in
    "$ROOT"/*) ;;
    *)
      echo "Error: coverage artifacts must stay inside the repository: $checked_path" >&2
      exit 1
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sim)
      SIM="$2"; shift 2 ;;
    --waves)
      WAVES=1; shift ;;
    --seed-base)
      SEED_BASE="$2"; shift 2 ;;
    --cov-root)
      COV_ROOT="$2"; shift 2 ;;
    --clean)
      CLEAN=1; shift ;;
    --dry-run)
      DRY_RUN=1; shift ;;
    --list-tests)
      LIST_ONLY=1; shift ;;
    -h|--help)
      cat <<EOF
Usage: $0 [test_name ...] [--sim xrun|xcelium] [--cov-root DIR] [--seed-base N]
          [--waves] [--clean] [--dry-run] [--list-tests]

Runs the stable VIP coverage suite on a Cadence-equipped machine.
- Uses scripts/sim/run_vip_test.sh with --func-cov --code-cov
- Shares one coverage work directory so per-test covtest buckets stay together
- For local Verilator smoke, use: bash ci/run_vip_smoke.sh

Examples:
  bash ci/run_vip_coverage.sh --sim xrun --clean
  bash ci/run_vip_coverage.sh long_random --sim xcelium --seed-base 100
  bash ci/run_vip_coverage.sh --dry-run
EOF
      exit 0 ;;
    *)
      SELECTED_TESTS+=("$1")
      shift ;;
  esac
done

case "$SIM" in
  xrun|xcelium) ;;
  *)
    echo "Error: VIP coverage regression requires --sim xrun or --sim xcelium" >&2
    exit 1
    ;;
esac

if [[ -z "$COV_ROOT" ]]; then
  COV_ROOT="$ROOT/build/vip_coverage_${SIM}"
else
  COV_ROOT="$(normalize_repo_path "$COV_ROOT")"
  ensure_repo_path "$COV_ROOT"
fi

COV_WORKDIR="$COV_ROOT/cov_work"
LOG_DIR="$COV_ROOT/logs"

if [[ ${#SELECTED_TESTS[@]} -eq 0 ]]; then
  TESTS=("${DEFAULT_TESTS[@]}")
else
  TESTS=("${SELECTED_TESTS[@]}")
fi

if [[ $LIST_ONLY -eq 1 ]]; then
  printf '%s\n' "${TESTS[@]}"
  exit 0
fi

if [[ $DRY_RUN -eq 0 ]] && ! command -v xrun >/dev/null 2>&1; then
  echo "Error: xrun not found in PATH. Run this helper on a Cadence-equipped machine, or use --dry-run locally." >&2
  exit 1
fi

echo "============================================"
echo "  MPTDC VIP Coverage Regression"
echo "============================================"
echo "  Simulator: $SIM"
echo "  Coverage root: $COV_ROOT"
echo "  Coverage workdir: $COV_WORKDIR"
echo "  Log dir: $LOG_DIR"
echo "  Tests: ${#TESTS[@]}"
if [[ $DRY_RUN -eq 1 ]]; then
  echo "  Mode: dry-run"
fi
echo "  Local limitation: Verilator smoke is separate via ci/run_vip_smoke.sh"
echo ""

if [[ $DRY_RUN -eq 0 ]]; then
  if [[ $CLEAN -eq 1 ]]; then
    rm -rf "$COV_ROOT"
  fi
  mkdir -p "$COV_ROOT"
  mkdir -p "$LOG_DIR"
elif [[ $CLEAN -eq 1 ]]; then
  echo "DRY-RUN: would remove and recreate $COV_ROOT"
  echo ""
fi

PASS=0
FAIL=0
FAILED_LIST=()

for idx in "${!TESTS[@]}"; do
  test_name="${TESTS[$idx]}"
  log_path="$LOG_DIR/${test_name}.log"
  echo "=== Running VIP coverage: $test_name ==="

  cmd=(
    bash "$RUNNER" "$test_name"
    --sim "$SIM"
    --func-cov
    --code-cov
    --cov-workdir "$COV_WORKDIR"
    --cov-test-name "$test_name"
  )

  case "$test_name" in
    jitter_robustness)
      cmd+=(--osc-jitter-sigma 8 --osc-jitter-bound 24)
      ;;
  esac

  if [[ $WAVES -eq 1 ]]; then
    cmd+=(--waves)
  fi
  if [[ -n "$SEED_BASE" ]]; then
    cmd+=(--seed "$((SEED_BASE + idx))")
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    cmd+=(--dry-run)
    "${cmd[@]}"
    PASS=$((PASS + 1))
    echo "--- $test_name: PREPARED ---"
    echo ""
    continue
  fi

  if "${cmd[@]}" >"$log_path" 2>&1; then
    tail -20 "$log_path"
    PASS=$((PASS + 1))
    echo "--- $test_name: PASSED ---"
  else
    tail -40 "$log_path"
    FAIL=$((FAIL + 1))
    FAILED_LIST+=("$test_name")
    echo "!!! $test_name: FAILED !!!"
  fi
  echo ""
done

if [[ $DRY_RUN -eq 1 ]]; then
  echo "VIP coverage dry-run prepared ${#TESTS[@]} test commands"
  echo "Coverage workdir (planned): $COV_WORKDIR"
  exit 0
fi

echo "VIP coverage results: $PASS passed, $FAIL failed"
echo "Coverage workdir: $COV_WORKDIR"
echo "Logs: $LOG_DIR"
echo "Next step on a Cadence machine: inspect the merged database in IMC / Xcelium coverage reporting."
if [[ ${#FAILED_LIST[@]} -gt 0 ]]; then
  echo "Failed tests: ${FAILED_LIST[*]}"
fi
[[ $FAIL -eq 0 ]]
