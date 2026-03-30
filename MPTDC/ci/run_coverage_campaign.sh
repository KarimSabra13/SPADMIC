#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Purpose : Run full coverage closure campaign with merged results
#           1) coverage_exhaustive  — directed walk of all config combos
#           2) stress_random × N    — parallel random seeds for delay coverage
# Usage   : bash ci/run_coverage_campaign.sh [options]
# Options : --sim xrun|xcelium  --seeds N  --conv-per-seed N  --jobs J
#           --cov-root DIR  --clean  --dry-run
# Author  : Karim Sabra
# -----------------------------------------------------------------------------

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIM="xrun"
NUM_SEEDS=20
CONV_PER_SEED=5000
MAX_JOBS=4
COV_ROOT="$REPO_ROOT/build/coverage_campaign"
CLEAN=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sim)           SIM="$2"; shift 2 ;;
    --seeds)         NUM_SEEDS="$2"; shift 2 ;;
    --conv-per-seed) CONV_PER_SEED="$2"; shift 2 ;;
    --jobs|-j)       MAX_JOBS="$2"; shift 2 ;;
    --cov-root)      COV_ROOT="$2"; shift 2 ;;
    --clean)         CLEAN=1; shift ;;
    --dry-run)       DRY_RUN=1; shift ;;
    -h|--help)
      cat <<EOF
Usage: $0 [options]

Options:
  --sim xrun|xcelium   Simulator (default: xrun)
  --seeds N            Number of random seeds (default: 20)
  --conv-per-seed N    Conversions per stress_random run (default: 5000)
  --jobs N             Max parallel jobs (default: 4)
  --cov-root DIR       Coverage output directory
  --clean              Remove old coverage data first
  --dry-run            Print commands without running

Total conversions = seeds × conv-per-seed + ~200 (exhaustive)
Example: --seeds 100 --conv-per-seed 5000 = 500,200 total conversions

For 30M conversions: --seeds 6000 --conv-per-seed 5000 --jobs 8
  (will take several hours with 8 parallel Xcelium processes)
EOF
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

COV_WORK="$COV_ROOT/cov_work"
LOG_DIR="$COV_ROOT/logs"

if [[ $CLEAN -eq 1 ]]; then
  echo "Cleaning $COV_ROOT ..."
  rm -rf "$COV_ROOT"
fi

mkdir -p "$LOG_DIR"

TOTAL_CONV=$(( NUM_SEEDS * CONV_PER_SEED + 200 ))
echo "============================================"
echo "  MPTDC Coverage Campaign"
echo "============================================"
echo "  Simulator:       $SIM"
echo "  Exhaustive:      ~200 directed conversions"
echo "  Stress seeds:    $NUM_SEEDS"
echo "  Conv/seed:       $CONV_PER_SEED"
echo "  Total conv:      ~$TOTAL_CONV"
echo "  Max parallel:    $MAX_JOBS"
echo "  Coverage root:   $COV_ROOT"
echo "  Coverage work:   $COV_WORK"
echo ""

run_test() {
  local test_name="$1"
  local seed="$2"
  local cov_label="$3"
  local extra_args="$4"
  local log_file="$LOG_DIR/${cov_label}.log"

  local cmd="bash $REPO_ROOT/scripts/sim/run_vip_test.sh $test_name \
    --sim $SIM \
    --seed $seed \
    --func-cov --code-cov \
    --cov-workdir $COV_WORK \
    --cov-test-name $cov_label \
    $extra_args"

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[DRY-RUN] $cmd"
    return 0
  fi

  echo "  [$cov_label] starting ..."
  if eval "$cmd" > "$log_file" 2>&1; then
    echo "  [$cov_label] PASS"
    return 0
  else
    echo "  [$cov_label] FAIL — see $log_file"
    return 1
  fi
}

# ===== Phase 1: Directed exhaustive coverage =====
echo "=== Phase 1: coverage_exhaustive ==="
PASS=0; FAIL=0
DIRECTED_EXPECTED=0

run_test "coverage_exhaustive" "42" "exhaustive" "" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
DIRECTED_EXPECTED=$((DIRECTED_EXPECTED + 1))

# Also run the directed closure tests for completeness
for t in smoke_single_conv full_mode_timestamp firsthit_contract \
         backpressure_integrity start_watchdog cal_inject \
         overflow_status long_random multi_conv_rearm_stress \
         global_watchdog_recovery csr_readback_control hard_reset_readback \
         jitter_robustness; do
  EXTRA_ARGS=""
  if [[ "$t" == "jitter_robustness" ]]; then
    EXTRA_ARGS="--osc-jitter-sigma 8 --osc-jitter-bound 24"
  fi
  run_test "$t" "42" "directed_${t}" "$EXTRA_ARGS" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
  DIRECTED_EXPECTED=$((DIRECTED_EXPECTED + 1))
done

echo ""
echo "Phase 1 done: $PASS passed, $FAIL failed"
echo ""

# ===== Phase 2: Parallel stress_random with multiple seeds =====
echo "=== Phase 2: stress_random × $NUM_SEEDS seeds ==="
STRESS_PASS=0; STRESS_FAIL=0
RUNNING=0

for ((i=1; i<=NUM_SEEDS; i++)); do
  SEED=$((1000 + i * 7919))
  COV_LABEL="stress_s${i}"

  run_test "stress_random" "$SEED" "$COV_LABEL" "--num-conv $CONV_PER_SEED" &

  RUNNING=$((RUNNING+1))

  # Throttle: wait when we hit max jobs
  if [[ $RUNNING -ge $MAX_JOBS ]]; then
    wait -n 2>/dev/null || true
    RUNNING=$((RUNNING-1))
  fi
done

# Wait for all remaining jobs
wait

if [[ $DRY_RUN -eq 1 ]]; then
  echo ""
  echo "Coverage campaign dry-run prepared $DIRECTED_EXPECTED directed tests and $NUM_SEEDS stress jobs"
  echo "Coverage workdir (planned): $COV_WORK"
  exit 0
fi

# Count results from logs
for ((i=1; i<=NUM_SEEDS; i++)); do
  LOG="$LOG_DIR/stress_s${i}.log"
  if [[ -f "$LOG" ]] && grep -q "TEST COMPLETE\|PASSED" "$LOG" 2>/dev/null; then
    STRESS_PASS=$((STRESS_PASS+1))
  else
    STRESS_FAIL=$((STRESS_FAIL+1))
  fi
done

echo ""
echo "Phase 2 done: $STRESS_PASS passed, $STRESS_FAIL failed out of $NUM_SEEDS"
echo ""

# ===== Summary =====
TOTAL_PASS=$((PASS + STRESS_PASS))
TOTAL_FAIL=$((FAIL + STRESS_FAIL))
TOTAL_TESTS=$((DIRECTED_EXPECTED + NUM_SEEDS))

echo "============================================"
echo "  CAMPAIGN RESULTS"
echo "============================================"
echo "  Directed:   $PASS / $DIRECTED_EXPECTED"
echo "  Stress:     $STRESS_PASS / $NUM_SEEDS"
echo "  Total:      $TOTAL_PASS / $TOTAL_TESTS"
echo "  Total conv: ~$TOTAL_CONV"
echo ""
echo "  Coverage DB: $COV_WORK"
echo "  Logs:        $LOG_DIR"
echo ""

if [[ $TOTAL_FAIL -gt 0 ]]; then
  echo "  !!! $TOTAL_FAIL tests FAILED — check logs !!!"
  echo ""
  for f in "$LOG_DIR"/*.log; do
    if ! grep -q "TEST COMPLETE\|PASSED" "$f" 2>/dev/null; then
      echo "    FAIL: $(basename "$f" .log)"
    fi
  done
  echo ""
fi

echo "Next steps:"
echo "  1. Merge coverage buckets and generate IMC reports:"
echo "     bash scripts/sim/report_coverage.sh --cov-root $COV_ROOT"
echo ""
echo "  2. Open the merged run in IMC:"
echo "     imc -load $COV_WORK/scope/merged_cov &"
echo ""
echo "  3. Open the generated HTML report:"
echo "     xdg-open $COV_ROOT/cov_report_aggregate/index.html"
echo ""
