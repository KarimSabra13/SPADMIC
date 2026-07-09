#!/usr/bin/env bash
# Dump DRC marker coordinates from an existing SPADMIC OOC Innovus run.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  TOP/pnr/scripts/run_innovus_ooc_dump_markers.sh <BLOCK_ROOT> [TOP_MODULE]

Example:
  TOP/pnr/scripts/run_innovus_ooc_dump_markers.sh \
    /sim/ksabra/SPADMIC_work/innovus/<RUN_ID>/blocks/tx_egress_core \
    spadmic_tx_egress_core

Writes:
  <BLOCK_ROOT>/reports/drc_marker_dump_summary.rpt
  <BLOCK_ROOT>/reports/verify_drc_marker_dump.rpt
  <BLOCK_ROOT>/reports/verify_drc_post_route_markers.tsv
  <BLOCK_ROOT>/reports/verify_drc_post_route_markers_schema.rpt
USAGE
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BLOCK_ROOT="$1"
TOP_MODULE="${2:-spadmic_tx_egress_core}"

if [[ ! -d "$BLOCK_ROOT" ]]; then
  echo "ERROR: block root not found: $BLOCK_ROOT" >&2
  exit 2
fi

if ! command -v innovus >/dev/null 2>&1; then
  echo "ERROR: innovus command not found; source the Cadence environment first" >&2
  exit 3
fi

mkdir -p "$BLOCK_ROOT/logs" "$BLOCK_ROOT/reports"

export SPADMIC_INNOVUS_BLOCK_ROOT="$BLOCK_ROOT"
export SPADMIC_INNOVUS_TOP_MODULE="$TOP_MODULE"
export SPADMIC_INNOVUS_CHECKPOINT="${SPADMIC_INNOVUS_CHECKPOINT:-$BLOCK_ROOT/checkpoints/05_postroute_export.enc.dat}"

innovus -nowin -init "$SCRIPT_DIR/dump_innovus_ooc_drc_markers.tcl" \
  -log "$BLOCK_ROOT/logs/dump_drc_markers.log" \
  > "$BLOCK_ROOT/logs/dump_drc_markers.stdout.log" 2>&1

cat "$BLOCK_ROOT/reports/drc_marker_dump_summary.rpt"
