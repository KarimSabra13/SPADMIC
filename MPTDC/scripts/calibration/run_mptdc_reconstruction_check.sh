#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MPTDC_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

# shellcheck source=../mptdc_flow_common.sh
source "$MPTDC_DIR/scripts/mptdc_flow_common.sh"

mptdc_common_init_work_roots "$REPO_ROOT"
RUN_ID="${1:-$(date +%Y%m%d_%H%M%S)_mptdc_reconstruction_check}"
if [[ $# -gt 0 ]]; then
  shift
fi
RUN_DIR="$MPTDC_CALIBRATION_WORK/$RUN_ID"
CAL_REPORT="${MPTDC_CALIBRATION_REPORT:-$MPTDC_CALIBRATION_WORK/latest/calibration_report.json}"

mptdc_common_require_clean_tracked "$REPO_ROOT"
mptdc_common_require_file "calibration report" "$CAL_REPORT"

mkdir -p "$RUN_DIR"
mptdc_common_print_run_header \
  "MPTDC Reconstruction Check" \
  "$REPO_ROOT" \
  "$RUN_ID" \
  "$RUN_DIR" \
  "calibration_report_reconstruction_check"

python3 - "$CAL_REPORT" "$RUN_DIR/reconstruction_check_summary.txt" <<'PY'
import json
import sys
from pathlib import Path

report_path = Path(sys.argv[1])
out_path = Path(sys.argv[2])
data = json.loads(report_path.read_text(encoding="utf-8"))
held = data.get("held_out_validation", {})
fresh = data.get("fresh_validation", {})
lines = [
    "MPTDC reconstruction check",
    f"report={report_path}",
    f"held_out={held}",
    f"fresh={fresh}",
    "FINAL_SIGNOFF=NO",
]
out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(out_path)
PY
