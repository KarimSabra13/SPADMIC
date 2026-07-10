#!/usr/bin/env bash
# Launch the read-only OA audit in batch Virtuoso.
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBRARY="${1:-}"
CELL="${2:-}"
REPORT="${3:-}"
VIEW="${4:-layout}"

if [[ -z "$LIBRARY" || -z "$CELL" || -z "$REPORT" ]]; then
  echo "Usage: $0 <oa-library> <cell> <report-path> [view]" >&2
  exit 2
fi
if ! command -v virtuoso >/dev/null 2>&1; then
  echo "ERROR: virtuoso missing; source /eda/cadence/eda_2023-2024" >&2
  exit 3
fi
mkdir -p "$(dirname "$REPORT")"
export SPADMIC_OA_AUDIT_LIBRARY="$LIBRARY"
export SPADMIC_OA_AUDIT_CELL="$CELL"
export SPADMIC_OA_AUDIT_VIEW="$VIEW"
export SPADMIC_OA_AUDIT_REPORT="$REPORT"
virtuoso -nograph -restore "$SCRIPT_DIR/audit_oa_layout_contract.il" \
  -log "${REPORT%.rpt}.virtuoso.log"
RC=$?
echo "OA_AUDIT_RC=$RC"
cat "$REPORT" 2>/dev/null || echo "MISSING OA REPORT"
exit "$RC"
