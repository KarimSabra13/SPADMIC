#!/usr/bin/env bash
# Capture command documentation from the installed Innovus version.
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
RUN_ID="${1:-innovus_pg_command_help_$(date +%Y%m%d_%H%M%S)}"
HELP_ROOT="$WORK_ROOT/diagnostics/$RUN_ID"

if [[ -e "$HELP_ROOT" ]]; then
  echo "ERROR: immutable help directory exists: $HELP_ROOT" >&2
  exit 2
fi
if ! command -v innovus >/dev/null 2>&1; then
  echo "ERROR: innovus missing; source /eda/cadence/eda_2023-2024" >&2
  exit 3
fi
mkdir -p "$HELP_ROOT"/{logs,reports}
export SPADMIC_INNOVUS_HELP_ROOT="$HELP_ROOT"

{
  echo "RUN_ID=$RUN_ID"
  echo "HELP_ROOT=$HELP_ROOT"
  echo "HEAD=$(git -C "$SCRIPT_DIR/../../.." rev-parse HEAD 2>/dev/null)"
  echo "POLICY=NO_DESIGN_LOADED_NO_DESIGN_MODIFICATION"
} >"$HELP_ROOT/context.rpt"

innovus -nowin -init "$SCRIPT_DIR/capture_innovus_pg_command_help.tcl" \
  -log "$HELP_ROOT/logs/innovus.log" \
  >"$HELP_ROOT/logs/innovus.stdout.log" 2>&1
RC=$?

echo "COMMAND_HELP_RC=$RC"
echo "COMMAND_HELP_ROOT=$HELP_ROOT"
cat "$HELP_ROOT/reports/command_help_status.rpt" 2>/dev/null || echo "MISSING STATUS"
exit "$RC"
