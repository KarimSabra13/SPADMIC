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

RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_lint_current_head}"
RESULT_DIR="$MPTDC_VERILATOR_WORK/$RUN_ID/lint"
FAST_TAG_ENCODING="${MPTDC_FAST_TAG_ENCODING:-raw_lfsr_tag}"
FREQ_MODE="${MPTDC_FREQ_MODE:-nominal}"

case "$FAST_TAG_ENCODING" in
  raw_lfsr_tag) FAST_TAG_DEFINE_ARGS=() ;;
  raw_galois_tag) FAST_TAG_DEFINE_ARGS=(+define+MPTDC_FAST_TAG_GALOIS) ;;
  *)
    echo "[LINT] Invalid MPTDC_FAST_TAG_ENCODING=$FAST_TAG_ENCODING" >&2
    exit 1
    ;;
esac

case "$FREQ_MODE" in
  nominal) FREQ_MODE_DEFINE_ARGS=() ;;
  r750_delta5) FREQ_MODE_DEFINE_ARGS=(+define+MPTDC_FREQ_R750_DELTA5) ;;
  *)
    echo "[LINT] Invalid MPTDC_FREQ_MODE=$FREQ_MODE" >&2
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

CMD=(
  verilator
  --lint-only
  --timing
  -Wall
  -Wno-WIDTHEXPAND
  -Wno-WIDTHTRUNC
  -Wno-UNUSEDSIGNAL
  -Wno-UNDRIVEN
  -Wno-UNUSEDPARAM
  -Wno-PINMISSING
  -Wno-UNUSEDGENVAR
  -Wno-CASEINCOMPLETE
  -Wno-LATCH
  -Wno-REALCVT
  -Wno-INITIALDLY
  -Wno-COMBDLY
  -Wno-PINCONNECTEMPTY
  -Wno-SYNCASYNCNET
  -Wno-UNOPTFLAT
  -Wno-DECLFILENAME
  -Wno-VARHIDDEN
  "${FAST_TAG_DEFINE_ARGS[@]}"
  "${FREQ_MODE_DEFINE_ARGS[@]}"
  -f "$MPTDC_DIR/sim/verilator/filelist_verilator.f"
  --top-module mptdc_axis_core
)

{
  echo "Run ID: $RUN_ID"
  echo "Fast tag encoding: $FAST_TAG_ENCODING"
  echo "Frequency mode: $FREQ_MODE"
  echo "Working directory: $REPO_ROOT"
  echo "Command:"
  printf '  %q' "${CMD[@]}"
  echo
} > "$RESULT_DIR/command_transcript.log"

echo "[LINT] Writing results to $RESULT_DIR"
(
  cd "$REPO_ROOT"
  "${CMD[@]}"
) > "$RESULT_DIR/lint.log" 2>&1
RC=$?

{
  echo "# Local Verilator Lint Summary"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Git HEAD: \`$(cat "$RESULT_DIR/git_head.txt")\`"
  echo "- Verilator: \`$(cat "$RESULT_DIR/verilator_version.txt")\`"
  echo "- Fast tag encoding: \`$FAST_TAG_ENCODING\`"
  echo "- Frequency mode: \`$FREQ_MODE\`"
  echo "- Command log: \`command_transcript.log\`"
  echo "- Lint log: \`lint.log\`"
  if [[ $RC -eq 0 ]]; then
    echo "- Result: PASS"
  else
    echo "- Result: FAIL (rc=$RC)"
  fi
  echo
  echo "This is local Verilator evidence only. Cadence timing and Xcelium results are server required."
} > "$RESULT_DIR/SUMMARY.md"

exit "$RC"
