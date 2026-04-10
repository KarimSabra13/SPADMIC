#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP — Multi-Seed Coverage Campaign
# Runs stress_random with N seeds in parallel, then merges coverage.
# Usage: bash ci/run_coverage_campaign.sh [--seeds N] [--max-jobs N]
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

NUM_SEEDS=20
MAX_JOBS=16

while [[ $# -gt 0 ]]; do
  case "$1" in
    --seeds)    NUM_SEEDS="$2"; shift 2 ;;
    --max-jobs) MAX_JOBS="$2"; shift 2 ;;
    *)          echo "Unknown: $1"; exit 1 ;;
  esac
done

COV_WORKDIR="$REPO_ROOT/build/campaign_coverage"
mkdir -p "$COV_WORKDIR"

echo "═══════════════════════════════════════════════════════"
echo "  SPADMIC TOP — Coverage Campaign"
echo "  Seeds: $NUM_SEEDS  Max parallel: $MAX_JOBS"
echo "═══════════════════════════════════════════════════════"

PASS=0
FAIL=0
PIDS=()

for i in $(seq 0 $((NUM_SEEDS - 1))); do
  SEED=$((1000 + i * 7919))
  COV_NAME="stress_s${i}"

  echo "  Launching seed $SEED (job $i/$NUM_SEEDS)..."

  bash "$REPO_ROOT/scripts/sim/run_vip_test.sh" stress_random \
    --seed "$SEED" \
    --func-cov --code-cov \
    --cov-workdir "$COV_WORKDIR" \
    --cov-test-name "$COV_NAME" \
    --num-phases 200 &

  PIDS+=($!)

  # Throttle to MAX_JOBS parallel
  while [[ $(jobs -r | wc -l) -ge $MAX_JOBS ]]; do
    wait -n 2>/dev/null || true
  done
done

# Wait for all to complete
echo ""
echo "Waiting for all $NUM_SEEDS jobs to complete..."
for pid in "${PIDS[@]}"; do
  if wait "$pid"; then
    ((PASS++))
  else
    ((FAIL++))
  fi
done

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  CAMPAIGN: $PASS pass, $FAIL fail / $NUM_SEEDS seeds"
echo "═══════════════════════════════════════════════════════"

# Merge coverage
echo ""
echo "─── Merging campaign coverage ────────────────────────"
bash "$REPO_ROOT/scripts/sim/report_coverage.sh" "$COV_WORKDIR" "$REPO_ROOT/build/campaign_report"

[[ $FAIL -eq 0 ]] && exit 0 || exit 1
