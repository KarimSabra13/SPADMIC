#!/usr/bin/env bash
# Read-only PG connectivity probe for a completed tx_ddr_strip PG attempt.
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_RUN_ROOT="${1:-}"
RUN_ID="${2:-tx_ddr_strip_pg_probe_$(date +%Y%m%d_%H%M%S)}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"

if [[ -z "$SOURCE_RUN_ROOT" ]]; then
  echo "Usage: $0 <pg-run-root> [probe-id]" >&2
  exit 2
fi

CHECKPOINT="$SOURCE_RUN_ROOT/checkpoints/02_pg_verified_export.enc.dat"
[[ -d "$CHECKPOINT" ]] || CHECKPOINT="$SOURCE_RUN_ROOT/checkpoints/02_pg_verified_export.enc"
if [[ ! -e "$CHECKPOINT" ]]; then
  echo "ERROR: PG checkpoint missing under $SOURCE_RUN_ROOT/checkpoints" >&2
  exit 6
fi
if ! command -v innovus >/dev/null 2>&1; then
  echo "ERROR: innovus missing; source /eda/cadence/eda_2023-2024" >&2
  exit 3
fi

PROBE_ROOT="$WORK_ROOT/diagnostics/$RUN_ID"
if [[ -e "$PROBE_ROOT" ]]; then
  echo "ERROR: immutable probe directory exists: $PROBE_ROOT" >&2
  exit 2
fi
mkdir -p "$PROBE_ROOT"/{logs,reports}

export SPADMIC_PG_PROBE_CHECKPOINT="$CHECKPOINT"
export SPADMIC_PG_PROBE_ROOT="$PROBE_ROOT"
export SPADMIC_PG_PROBE_TOP=spadmic_tx_ddr_strip

{
  echo "RUN_ID=$RUN_ID"
  echo "SOURCE_RUN_ROOT=$SOURCE_RUN_ROOT"
  echo "SOURCE_CHECKPOINT=$CHECKPOINT"
  echo "PROBE_ROOT=$PROBE_ROOT"
  echo "HEAD=$(git -C "$SCRIPT_DIR/../../.." rev-parse HEAD 2>/dev/null)"
  echo "POLICY=READ_ONLY_RESTORE_AND_REPORT"
} >"$PROBE_ROOT/context.rpt"

innovus -nowin -init "$SCRIPT_DIR/probe_innovus_ooc_pg_connectivity.tcl" \
  -log "$PROBE_ROOT/logs/innovus.log" \
  >"$PROBE_ROOT/logs/innovus.stdout.log" 2>&1
RC=$?

echo "PG_PROBE_RC=$RC"
echo "PG_PROBE_ROOT=$PROBE_ROOT"
cat "$PROBE_ROOT/reports/pg_probe_status.rpt" 2>/dev/null || echo "MISSING STATUS"
exit "$RC"
