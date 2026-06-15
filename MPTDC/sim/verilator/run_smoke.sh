#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MPTDC_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"
MPTDC_WORK_ROOT="${MPTDC_WORK_ROOT:-work}"
case "$MPTDC_WORK_ROOT" in
  /*) ;;
  *) MPTDC_WORK_ROOT="$REPO_ROOT/$MPTDC_WORK_ROOT" ;;
esac
MPTDC_VERILATOR_WORK="${MPTDC_VERILATOR_WORK:-$MPTDC_WORK_ROOT/verilator}"
MPTDC_SIM_SCRATCH_ROOT="${MPTDC_SIM_SCRATCH_ROOT:-$MPTDC_WORK_ROOT/scratch/verilator}"
export MPTDC_WORK_ROOT MPTDC_VERILATOR_WORK MPTDC_SIM_SCRATCH_ROOT

RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_smoke_current_head}"
RESULT_DIR="$MPTDC_VERILATOR_WORK/$RUN_ID"
FAST_TAG_ENCODING="${MPTDC_FAST_TAG_ENCODING:-raw_lfsr_tag}"
FREQ_MODE="${MPTDC_FREQ_MODE:-nominal}"

case "$FAST_TAG_ENCODING" in
  raw_lfsr_tag|raw_galois_tag) ;;
  *)
    echo "[SMOKE] Invalid MPTDC_FAST_TAG_ENCODING=$FAST_TAG_ENCODING" >&2
    exit 1
    ;;
esac

case "$FREQ_MODE" in
  nominal|r750_delta5) ;;
  *)
    echo "[SMOKE] Invalid MPTDC_FREQ_MODE=$FREQ_MODE" >&2
    exit 1
    ;;
esac

mkdir -p "$RESULT_DIR"
mkdir -p "$RESULT_DIR/ccache/tmp"

export CCACHE_DIR="$RESULT_DIR/ccache"
export CCACHE_TEMPDIR="$RESULT_DIR/ccache/tmp"

git -C "$REPO_ROOT" rev-parse HEAD > "$RESULT_DIR/git_head.txt"
git -C "$REPO_ROOT" status --short > "$RESULT_DIR/git_status.txt"
verilator --version > "$RESULT_DIR/verilator_version.txt"
: > "$RESULT_DIR/command_transcript.log"
: > "$RESULT_DIR/test_summary.txt"

record_cmd() {
  printf '[%s]' "$(date -Iseconds)" >> "$RESULT_DIR/command_transcript.log"
  printf ' %q' "$@" >> "$RESULT_DIR/command_transcript.log"
  printf '\n' >> "$RESULT_DIR/command_transcript.log"
}

run_logged() {
  local name="$1"
  shift
  local log="$RESULT_DIR/${name}.log"

  echo "[RUN] $name"
  record_cmd "$@"
  set +e
  "$@" > "$log" 2>&1
  local rc=$?
  set -e

  if [[ $rc -eq 0 ]]; then
    echo "PASS $name" | tee -a "$RESULT_DIR/test_summary.txt"
  else
    echo "FAIL $name rc=$rc" | tee -a "$RESULT_DIR/test_summary.txt"
  fi
  return "$rc"
}

pass=0
fail=0

run_step() {
  local name="$1"
  shift
  if run_logged "$name" "$@"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
  fi
}

echo "[SMOKE] Writing results to $RESULT_DIR"
echo "[SMOKE] Fast tag encoding: $FAST_TAG_ENCODING"
echo "[SMOKE] Frequency mode: $FREQ_MODE"
export MPTDC_FAST_TAG_ENCODING="$FAST_TAG_ENCODING"
export MPTDC_FREQ_MODE="$FREQ_MODE"

run_step lint bash "$MPTDC_DIR/sim/verilator/run_lint.sh" "$RUN_ID"

TB_RUNNER="$MPTDC_DIR/scripts/sim/run_tb.sh"

UNIT_TESTS=(
)

INT_TESTS=(
  tb_axis_core_product_smoke
)

VIP_TESTS=(
)

for tb in "${UNIT_TESTS[@]}"; do
  run_step "$tb" bash "$TB_RUNNER" "$tb" --sim verilator --fast-tag-encoding "$FAST_TAG_ENCODING" --freq-mode "$FREQ_MODE"
done

for tb in "${INT_TESTS[@]}"; do
  run_step "$tb" bash "$TB_RUNNER" "$tb" --sim verilator --fast-tag-encoding "$FAST_TAG_ENCODING" --freq-mode "$FREQ_MODE"
done

for test_name in "${VIP_TESTS[@]}"; do
  run_step "vip_${test_name}" bash "$VIP_RUNNER" "$test_name" --sim verilator --fast-tag-encoding "$FAST_TAG_ENCODING" --freq-mode "$FREQ_MODE"
done

{
  echo "# Local Verilator Smoke Summary"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Git HEAD: \`$(cat "$RESULT_DIR/git_head.txt")\`"
  echo "- Verilator: \`$(cat "$RESULT_DIR/verilator_version.txt")\`"
  echo "- Fast tag encoding: \`$FAST_TAG_ENCODING\`"
  echo "- Frequency mode: \`$FREQ_MODE\`"
  echo "- Passed steps: $pass"
  echo "- Failed steps: $fail"
  echo "- Command transcript: \`command_transcript.log\`"
  echo "- Test summary: \`test_summary.txt\`"
  echo
  echo "## Step Results"
  echo
  sed 's/^/- /' "$RESULT_DIR/test_summary.txt"
  echo
  echo "This is local Verilator evidence only. Genus, Innovus, and Xcelium remain server required."
} > "$RESULT_DIR/SUMMARY.md"

if [[ $fail -ne 0 ]]; then
  exit 1
fi

exit 0
