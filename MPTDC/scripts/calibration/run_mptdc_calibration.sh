#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MPTDC_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

# shellcheck source=../mptdc_flow_common.sh
source "$MPTDC_DIR/scripts/mptdc_flow_common.sh"

mptdc_common_init_work_roots "$REPO_ROOT"
RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_mptdc_calibration}"
if [[ $# -gt 0 ]]; then
  shift
fi
RUN_DIR="$MPTDC_CALIBRATION_WORK/$RUN_ID"
TRAIN_DIR="${MPTDC_CALIBRATION_TRAIN_DIR:-$MPTDC_CHARACTERIZATION_WORK/latest/characterization}"
VAL_DIR="${MPTDC_CALIBRATION_VAL_DIR:-}"
FRESH_DIR="${MPTDC_CALIBRATION_FRESH_DIR:-}"

mptdc_common_require_clean_tracked "$REPO_ROOT"
mptdc_common_require_file "calibration script" "$MPTDC_DIR/scripts/calibration/calibrate_6d_lut.py"
if [[ ! -d "$TRAIN_DIR" ]]; then
  echo "ERROR: missing calibration training directory: $TRAIN_DIR" >&2
  echo "Set MPTDC_CALIBRATION_TRAIN_DIR to a characterization seed CSV directory." >&2
  exit 2
fi

cmd=(
  python3 "$MPTDC_DIR/scripts/calibration/calibrate_6d_lut.py"
  --train-dir "$TRAIN_DIR"
  --out-dir "$RUN_DIR"
  --freq-mode "${MPTDC_FREQ_MODE:-r750_delta5}"
  --nfast-encoding "${MPTDC_NFAST_ENCODING:-raw_lfsr_tag}"
)
if [[ -n "$VAL_DIR" ]]; then
  cmd+=(--val-dir "$VAL_DIR")
fi
if [[ -n "$FRESH_DIR" ]]; then
  cmd+=(--fresh-dir "$FRESH_DIR")
fi

mkdir -p "$MPTDC_CALIBRATION_WORK"
mptdc_common_print_run_header \
  "MPTDC Calibration" \
  "$REPO_ROOT" \
  "$RUN_ID" \
  "$RUN_DIR" \
  "calibrate_6d_lut"

exec "${cmd[@]}" "$@"
