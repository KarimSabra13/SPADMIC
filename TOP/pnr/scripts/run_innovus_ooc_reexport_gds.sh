#!/usr/bin/env bash
# Re-export GDS from an existing SPADMIC OOC Innovus checkpoint with an explicit
# streamout map. This restores the saved design and runs streamOut only.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  TOP/pnr/scripts/run_innovus_ooc_reexport_gds.sh <BLOCK_ROOT> <TOP_MODULE> [OUT_GDS]

Example:
  TOP/pnr/scripts/run_innovus_ooc_reexport_gds.sh \
    /sim/ksabra/SPADMIC_work/innovus/<RUN_ID>/blocks/tx_packet_core \
    spadmic_tx_packet_core

Environment:
  SPADMIC_INNOVUS_CHECKPOINT    Optional checkpoint override.
  SPADMIC_STREAMOUT_MAP_FILE    Optional streamOut map override.

Default streamOut map:
  /eda/pdk/xfab/xh018/cadence/v10_1/PDK/IC61/v10_1_1/TECH_XH018_HD_1131/pnr_streamout.map

Writes:
  <BLOCK_ROOT>/outputs/<block>.gds
  <BLOCK_ROOT>/reports/REEXPORT_GDS_WITH_MAP.rpt
  <BLOCK_ROOT>/logs/reexport_gds_with_map.log
  <BLOCK_ROOT>/logs/reexport_gds_with_map.stdout.log

This does not rerun import, floorplan, place, CTS, route, or DRC repair.
USAGE
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BLOCK_ROOT="$1"
TOP_MODULE="$2"
BLOCK="$(basename "$BLOCK_ROOT")"
OUT_GDS="${3:-$BLOCK_ROOT/outputs/$BLOCK.gds}"

DEFAULT_STREAMOUT_MAP="/eda/pdk/xfab/xh018/cadence/v10_1/PDK/IC61/v10_1_1/TECH_XH018_HD_1131/pnr_streamout.map"
STREAMOUT_MAP="${SPADMIC_STREAMOUT_MAP_FILE:-$DEFAULT_STREAMOUT_MAP}"
CHECKPOINT="${SPADMIC_INNOVUS_CHECKPOINT:-$BLOCK_ROOT/checkpoints/05_postroute_export.enc.dat}"
REPORT="$BLOCK_ROOT/reports/REEXPORT_GDS_WITH_MAP.rpt"

if [[ ! -d "$BLOCK_ROOT" ]]; then
  echo "ERROR: block root not found: $BLOCK_ROOT" >&2
  exit 2
fi
if [[ ! -e "$CHECKPOINT" ]]; then
  echo "ERROR: checkpoint not found: $CHECKPOINT" >&2
  exit 2
fi
if [[ ! -f "$STREAMOUT_MAP" ]]; then
  echo "ERROR: streamOut map not found: $STREAMOUT_MAP" >&2
  exit 2
fi
if ! command -v innovus >/dev/null 2>&1; then
  echo "ERROR: innovus command not found; source the Cadence environment first" >&2
  exit 3
fi

mkdir -p "$BLOCK_ROOT/logs" "$BLOCK_ROOT/outputs" "$BLOCK_ROOT/reports"

if [[ -s "$OUT_GDS" ]]; then
  BACKUP="$OUT_GDS.pre_mapfix_$(date +%Y%m%d_%H%M%S)"
  cp -p "$OUT_GDS" "$BACKUP"
else
  BACKUP=""
fi

export SPADMIC_REEXPORT_BLOCK_ROOT="$BLOCK_ROOT"
export SPADMIC_REEXPORT_TOP_MODULE="$TOP_MODULE"
export SPADMIC_REEXPORT_CHECKPOINT="$CHECKPOINT"
export SPADMIC_REEXPORT_GDS="$OUT_GDS"
export SPADMIC_REEXPORT_STREAMOUT_MAP="$STREAMOUT_MAP"
export SPADMIC_REEXPORT_REPORT="$REPORT"
export SPADMIC_REEXPORT_BACKUP="$BACKUP"

set +e
innovus -nowin -init "$SCRIPT_DIR/reexport_innovus_ooc_gds.tcl" \
  -log "$BLOCK_ROOT/logs/reexport_gds_with_map.log" \
  > "$BLOCK_ROOT/logs/reexport_gds_with_map.stdout.log" 2>&1
innovus_rc=$?
set -e

HANDOFF_ROOT=""
STATUS_RPT="$BLOCK_ROOT/reports/ooc_harden_status.rpt"
if [[ -f "$STATUS_RPT" ]]; then
  HANDOFF_ROOT="$(awk -F= '$1=="HANDOFF_ROOT"{print $2}' "$STATUS_RPT" | tail -1)"
fi

if [[ "$innovus_rc" -eq 0 && -s "$OUT_GDS" && -n "$HANDOFF_ROOT" && -d "$HANDOFF_ROOT/innovus" ]]; then
  cp -p "$OUT_GDS" "$HANDOFF_ROOT/innovus/$(basename "$OUT_GDS")"
  {
    echo "HANDOFF_GDS_COPY=PASS"
    echo "HANDOFF_GDS=$HANDOFF_ROOT/innovus/$(basename "$OUT_GDS")"
  } >> "$REPORT"
elif [[ "$innovus_rc" -eq 0 ]]; then
  {
    echo "HANDOFF_GDS_COPY=SKIPPED"
    echo "HANDOFF_ROOT=$HANDOFF_ROOT"
  } >> "$REPORT"
fi

cat "$REPORT" 2>/dev/null || true
exit "$innovus_rc"
