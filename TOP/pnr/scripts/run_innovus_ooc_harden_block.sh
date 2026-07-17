#!/usr/bin/env bash
# =============================================================================
# SPADMIC matrix-top -- single-block Innovus OOC hardening flow
# =============================================================================
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  TOP/pnr/scripts/run_innovus_ooc_harden_block.sh <block> <GENUS_RUN_ID> [RUN_ID]

Supported blocks:
  tx_packet_core / spadmic_tx_packet_core
  tx_ddr_strip / spadmic_tx_ddr_strip
  position_core / spadmic_position_core
  event_coordinator / spadmic_event_coordinator
  event_bundle_tx / spadmic_event_bundle_tx
  output_fifo / spadmic_output_fifo_topcfg
  ddr16_pairer / spadmic_ddr16_tx_pairer
  ddrs2_adapter / spadmic_ddrs2_adapter
  tx_egress_core / spadmic_tx_egress_core
  tx_egress_assembly / spadmic_tx_egress_core

This is the first real TOP OOC hardening wrapper. It imports one Genus OOC
netlist/SDC into Innovus, builds a local abstract floorplan, places pins,
creates local VDD/VSS METTP access pins, runs place/CTS/route/filler/timing/
DRV/Innovus DRC/connectivity checks, and exports DEF/LEF/GDS collateral.
Most legacy leaves defer local special PG routing. TX_PACKET_CORE,
TX_DDR_STRIP, POSITION_CORE, and EVENT_COORDINATOR enable the explicit-exact
PG strategy in their generated config:
the METTP stripe center is identical to the VDD/VSS pin center and sroute is
limited to corePin stitching. The wrapper fails closed on special connectivity.
For the wide TX egress core min-area/antenna rescue, set
SPADMIC_OOC_ROUTE_PROFILE=met2_first_antenna. If the wide bbox still reports
non-PG DRC, rerun with SPADMIC_OOC_CORE_HEIGHT_UM=160, then 170 maximum.

It is still typical-only Innovus OOC implementation. It does not run PVS,
PEX, multi-corner signoff, or foundry signoff LVS.
USAGE
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TOP_ROOT="$(cd "$PNR_ROOT/.." && pwd)"
REPO_ROOT="$(cd "$TOP_ROOT/.." && pwd)"
BLOCK_IN="$1"
GENUS_RUN_ID="$2"

case "$BLOCK_IN" in
  tx_packet_core|spadmic_tx_packet_core)
    BLOCK="tx_packet_core"
    TOP_MODULE="spadmic_tx_packet_core"
    ;;
  tx_ddr_strip|spadmic_tx_ddr_strip)
    BLOCK="tx_ddr_strip"
    TOP_MODULE="spadmic_tx_ddr_strip"
    ;;
  position_core|spadmic_position_core)
    BLOCK="position_core"
    TOP_MODULE="spadmic_position_core"
    ;;
  event_coordinator|spadmic_event_coordinator)
    BLOCK="event_coordinator"
    TOP_MODULE="spadmic_event_coordinator"
    ;;
  event_bundle_tx|spadmic_event_bundle_tx)
    BLOCK="event_bundle_tx"
    TOP_MODULE="spadmic_event_bundle_tx"
    ;;
  output_fifo|spadmic_output_fifo|spadmic_output_fifo_topcfg)
    BLOCK="output_fifo"
    TOP_MODULE="spadmic_output_fifo_topcfg"
    ;;
  ddr16_pairer|spadmic_ddr16_tx_pairer)
    BLOCK="ddr16_pairer"
    TOP_MODULE="spadmic_ddr16_tx_pairer"
    ;;
  ddrs2_adapter|spadmic_ddrs2_adapter)
    BLOCK="ddrs2_adapter"
    TOP_MODULE="spadmic_ddrs2_adapter"
    ;;
  tx_egress_cluster|tx_egress_core|spadmic_tx_egress_cluster|spadmic_tx_egress_core)
    BLOCK="tx_egress_core"
    TOP_MODULE="spadmic_tx_egress_core"
    ;;
  tx_egress_assembly)
    BLOCK="tx_egress_assembly"
    TOP_MODULE="spadmic_tx_egress_core"
    ;;
  *)
    echo "ERROR: unsupported OOC hardening block: $BLOCK_IN" >&2
    usage >&2
    exit 2
    ;;
esac

RUN_ID="${3:-innovus_ooc_harden_${BLOCK}_$(date +%Y%m%d_%H%M)}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
GENUS_ROOT="$WORK_ROOT/genus/$GENUS_RUN_ID"
RUN_ROOT="$WORK_ROOT/innovus/$RUN_ID"
BLOCK_ROOT="$RUN_ROOT/blocks/$BLOCK"
HANDOFF_ROOT="$WORK_ROOT/handoff/abstracts/$BLOCK/$RUN_ID"
LAYOUT_AUDIT_DIR="${SPADMIC_LAYOUT_AUDIT_DIR:-$REPO_ROOT/TOP/docs/layout_audits/SPADMIC2_20260709_072331}"

export MPTDC_XH018_STACK="${MPTDC_XH018_STACK:-xx31}"
export MPTDC_STDCELL_FAMILY="${MPTDC_STDCELL_FAMILY:-JIHD}"
export MPTDC_PNR_ROUTE_LAYER_NAMES="${MPTDC_PNR_ROUTE_LAYER_NAMES:-MET1 MET2 MET3 METTP}"
export MPTDC_PNR_SIGNAL_TOP_LAYER="${MPTDC_PNR_SIGNAL_TOP_LAYER:-MET3}"
export MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER="${MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER:-METTP}"
export MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY="${MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY:-1}"

DEFAULT_SPADMIC_STREAMOUT_MAP="/eda/pdk/xfab/xh018/cadence/v10_1/PDK/IC61/v10_1_1/TECH_XH018_HD_1131/pnr_streamout.map"
if [[ -z "${SPADMIC_STREAMOUT_MAP_FILE:-}" && -f "$DEFAULT_SPADMIC_STREAMOUT_MAP" ]]; then
  export SPADMIC_STREAMOUT_MAP_FILE="$DEFAULT_SPADMIC_STREAMOUT_MAP"
fi
DEFAULT_SPADMIC_STDCELL_GDS="/data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/gds/xh018_D_CELLS_JIHD.gds"
if [[ -z "${SPADMIC_STDCELL_GDS:-}" && -f "$DEFAULT_SPADMIC_STDCELL_GDS" ]]; then
  export SPADMIC_STDCELL_GDS="$DEFAULT_SPADMIC_STDCELL_GDS"
fi

GENUS_BLOCK_ROOT="$GENUS_ROOT/$BLOCK"
NETLIST="$GENUS_BLOCK_ROOT/outputs/$BLOCK.postsyn.v"
SDC="$GENUS_BLOCK_ROOT/outputs/$BLOCK.postsyn.sdc"
GENUS_SUMMARY="$GENUS_BLOCK_ROOT/SUMMARY.md"

if [[ -e "$RUN_ROOT" ]]; then
  echo "ERROR: run directory already exists: $RUN_ROOT" >&2
  exit 2
fi

mkdir -p "$BLOCK_ROOT"/{checkpoints,generated,logs,outputs,reports,handoff} \
  "$RUN_ROOT/reports" "$HANDOFF_ROOT"/{innovus,netlist,reports}

fail_summary() {
  local rc="$1"
  local reason="$2"
  {
    echo "# SPADMIC Matrix TOP Innovus OOC Hardening"
    echo
    echo "- Run ID: \`$RUN_ID\`"
    echo "- Run directory: \`$RUN_ROOT\`"
    echo "- Block: \`$BLOCK\`"
    echo "- Top module: \`$TOP_MODULE\`"
    echo "- Genus run ID: \`$GENUS_RUN_ID\`"
    echo "- Result: FAIL"
    echo "- First error: \`$reason\`"
    echo
    echo "This wrapper did not claim signoff."
  } > "$RUN_ROOT/SUMMARY.md"
  cp "$RUN_ROOT/SUMMARY.md" "$BLOCK_ROOT/SUMMARY.md"
  cat "$RUN_ROOT/SUMMARY.md"
  exit "$rc"
}

[[ -d "$GENUS_ROOT" ]] || fail_summary 6 "Genus run directory not found: $GENUS_ROOT"
[[ -f "$NETLIST" ]] || fail_summary 6 "Genus netlist not found: $NETLIST"
[[ -f "$SDC" ]] || fail_summary 6 "Genus SDC not found: $SDC"
[[ -f "$GENUS_SUMMARY" ]] || fail_summary 6 "Genus block summary not found: $GENUS_SUMMARY"
[[ -d "$LAYOUT_AUDIT_DIR" ]] || fail_summary 6 "Layout audit directory not found: $LAYOUT_AUDIT_DIR"

{
  echo "RUN_ID=$RUN_ID"
  echo "DATE_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "REPO_ROOT=$REPO_ROOT"
  echo "TOP_ROOT=$TOP_ROOT"
  echo "PNR_ROOT=$PNR_ROOT"
  echo "RUN_ROOT=$RUN_ROOT"
  echo "BLOCK_ROOT=$BLOCK_ROOT"
  echo "HANDOFF_ROOT=$HANDOFF_ROOT"
  echo "BLOCK=$BLOCK"
  echo "TOP_MODULE=$TOP_MODULE"
  echo "GENUS_RUN_ID=$GENUS_RUN_ID"
  echo "GENUS_ROOT=$GENUS_ROOT"
  echo "GENUS_BLOCK_ROOT=$GENUS_BLOCK_ROOT"
  echo "NETLIST=$NETLIST"
  echo "SDC=$SDC"
  echo "GENUS_SUMMARY=$GENUS_SUMMARY"
  echo "LAYOUT_AUDIT_DIR=$LAYOUT_AUDIT_DIR"
  echo "MPTDC_XH018_STACK=$MPTDC_XH018_STACK"
  echo "MPTDC_STDCELL_FAMILY=$MPTDC_STDCELL_FAMILY"
  echo "MPTDC_PNR_ROUTE_LAYER_NAMES=$MPTDC_PNR_ROUTE_LAYER_NAMES"
  echo "MPTDC_PNR_SIGNAL_TOP_LAYER=$MPTDC_PNR_SIGNAL_TOP_LAYER"
  echo "MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER=$MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER"
  echo "MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=$MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY"
  echo "SPADMIC_OOC_ROUTE_PROFILE=${SPADMIC_OOC_ROUTE_PROFILE:-default}"
  echo "SPADMIC_OOC_SIGNAL_BOTTOM_LAYER=${SPADMIC_OOC_SIGNAL_BOTTOM_LAYER:-}"
  echo "SPADMIC_OOC_SIGNAL_BOTTOM_LAYER_IDX=${SPADMIC_OOC_SIGNAL_BOTTOM_LAYER_IDX:-}"
  echo "SPADMIC_OOC_SIGNAL_TOP_LAYER=${SPADMIC_OOC_SIGNAL_TOP_LAYER:-}"
  echo "SPADMIC_OOC_SIGNAL_TOP_LAYER_IDX=${SPADMIC_OOC_SIGNAL_TOP_LAYER_IDX:-}"
  echo "SPADMIC_OOC_CORE_HEIGHT_UM=${SPADMIC_OOC_CORE_HEIGHT_UM:-}"
  echo "SPADMIC_OOC_PLACE_MAX_DENSITY=${SPADMIC_OOC_PLACE_MAX_DENSITY:-}"
  echo "SPADMIC_OOC_ENABLE_ROUTE_EFFORT=${SPADMIC_OOC_ENABLE_ROUTE_EFFORT:-}"
  echo "SPADMIC_OOC_ENABLE_ANTENNA_REPAIR=${SPADMIC_OOC_ENABLE_ANTENNA_REPAIR:-}"
  echo "SPADMIC_OOC_REQUIRE_ANTENNA_CLEAN=${SPADMIC_OOC_REQUIRE_ANTENNA_CLEAN:-}"
  echo "SPADMIC_OOC_ENABLE_PG_SROUTE=${SPADMIC_OOC_ENABLE_PG_SROUTE:-}"
  echo "SPADMIC_OOC_ENABLE_PRE_CTS_PG_DIRECT_VIAS=${SPADMIC_OOC_ENABLE_PRE_CTS_PG_DIRECT_VIAS:-}"
  echo "SPADMIC_OOC_PG_DIRECT_VIA_AREAS=${SPADMIC_OOC_PG_DIRECT_VIA_AREAS:-}"
  echo "SPADMIC_OOC_PRE_CTS_EXPECTED_DANGLING_COUNT=${SPADMIC_OOC_PRE_CTS_EXPECTED_DANGLING_COUNT:-}"
  echo "SPADMIC_OOC_ENABLE_POST_FILLER_PG_RESTITCH=${SPADMIC_OOC_ENABLE_POST_FILLER_PG_RESTITCH:-}"
  echo "SPADMIC_STREAMOUT_MAP_FILE=${SPADMIC_STREAMOUT_MAP_FILE:-}"
  echo "SPADMIC_STDCELL_GDS=${SPADMIC_STDCELL_GDS:-}"
  echo "BRANCH=$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo unknown)"
  echo "HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
  echo "STATUS_SHORT_BEGIN"
  git -C "$REPO_ROOT" status --short 2>/dev/null || true
  echo "STATUS_SHORT_END"
} > "$RUN_ROOT/run_manifest.txt"

python3 "$SCRIPT_DIR/gen_ooc_block_harden_plan.py" "$BLOCK" \
  --layout-audit-dir "$LAYOUT_AUDIT_DIR" \
  --out-dir "$BLOCK_ROOT/generated"

CONFIG_TCL="$BLOCK_ROOT/generated/ooc_block_harden_config.tcl"
[[ -f "$CONFIG_TCL" ]] || fail_summary 6 "Generated hardening config missing: $CONFIG_TCL"

if ! command -v innovus >/dev/null 2>&1; then
  fail_summary 3 "innovus command not found; source the Cadence environment first"
fi

export SPADMIC_REPO_ROOT="$REPO_ROOT"
export SPADMIC_TOP_ROOT="$TOP_ROOT"
export SPADMIC_PNR_ROOT="$PNR_ROOT"
export SPADMIC_INNOVUS_RUN_ROOT="$RUN_ROOT"
export SPADMIC_INNOVUS_BLOCK_ROOT="$BLOCK_ROOT"
export SPADMIC_INNOVUS_HANDOFF_ROOT="$HANDOFF_ROOT"
export SPADMIC_INNOVUS_BLOCK="$BLOCK"
export SPADMIC_INNOVUS_TOP_MODULE="$TOP_MODULE"
export SPADMIC_INNOVUS_NETLIST="$NETLIST"
export SPADMIC_INNOVUS_SDC="$SDC"
export SPADMIC_INNOVUS_CONFIG_TCL="$CONFIG_TCL"
export SPADMIC_INNOVUS_GENUS_SUMMARY="$GENUS_SUMMARY"

set +e
innovus -nowin -init "$SCRIPT_DIR/run_innovus_ooc_harden_block.tcl" \
  -log "$BLOCK_ROOT/logs/innovus.log" \
  </dev/null \
  > "$BLOCK_ROOT/logs/innovus.stdout.log" 2>&1
innovus_rc=$?
set -e

status_rpt="$BLOCK_ROOT/reports/ooc_harden_status.rpt"
gds_audit_rpt="$BLOCK_ROOT/reports/gds_export_audit.rpt"
gds_audit_rc=6
if [[ -s "$BLOCK_ROOT/outputs/$BLOCK.gds" ]] \
    && [[ -s "$BLOCK_ROOT/logs/innovus.log" ]] \
    && [[ -s "${SPADMIC_STREAMOUT_MAP_FILE:-}" ]] \
    && [[ -s "${SPADMIC_STDCELL_GDS:-}" ]]; then
  set +e
  python3 "$SCRIPT_DIR/audit_innovus_gds_export.py" \
    --gds "$BLOCK_ROOT/outputs/$BLOCK.gds" \
    --log "$BLOCK_ROOT/logs/innovus.log" \
    --stream-map "$SPADMIC_STREAMOUT_MAP_FILE" \
    --required-merge "$SPADMIC_STDCELL_GDS" \
    --status "$gds_audit_rpt"
  gds_audit_rc=$?
  set -e
else
  {
    echo "LABEL=SPADMIC_INNOVUS_GDS_EXPORT_AUDIT"
    echo "STATUS=FAIL"
    echo "ERROR=missing_gds_log_stream_map_or_required_merge"
  } > "$gds_audit_rpt"
fi
cp -f "$gds_audit_rpt" "$HANDOFF_ROOT/reports/gds_export_audit.rpt"

tx_ooc_gate_rc="NOT_APPLICABLE"
tx_ooc_gate_rpt="$BLOCK_ROOT/reports/canonical_tx_ooc_gate.rpt"
if [[ "$BLOCK" == "tx_packet_core" || "$BLOCK" == "tx_ddr_strip" ]]; then
  TX_GATE_ARGS=(--block-root "$BLOCK_ROOT" --block "$BLOCK" --status "$tx_ooc_gate_rpt")
  case "${SPADMIC_TX_ALLOW_ANTENNA_DEFERRED:-1}" in
    1|yes|YES|true|TRUE|on|ON) TX_GATE_ARGS+=(--allow-antenna-deferred) ;;
  esac
  set +e
  python3 "$SCRIPT_DIR/validate_tx_canonical_ooc.py" "${TX_GATE_ARGS[@]}"
  tx_ooc_gate_rc=$?
  set -e
  if [[ -s "$tx_ooc_gate_rpt" ]]; then
    cp -f "$tx_ooc_gate_rpt" "$HANDOFF_ROOT/reports/canonical_tx_ooc_gate.rpt"
  fi
fi

result="FAIL"
if [[ "$innovus_rc" -eq 0 ]] \
    && [[ "$gds_audit_rc" -eq 0 ]] \
    && [[ "$tx_ooc_gate_rc" == "NOT_APPLICABLE" || "$tx_ooc_gate_rc" -eq 0 ]] \
    && [[ -f "$status_rpt" ]] \
    && grep -q '^RESULT=ABSTRACT_READY_FOR_TOP_REVIEW$' "$status_rpt"; then
  result="ABSTRACT_READY_FOR_TOP_REVIEW"
fi

status_value() {
  local key="$1"
  if [[ -s "$status_rpt" ]]; then
    awk -F= -v key="$key" '$1 == key {print substr($0, index($0, "=") + 1); exit}' "$status_rpt"
  fi
}

summary_route_profile="$(status_value ROUTE_PROFILE)"
summary_signal_route_layers="$(status_value SIGNAL_ROUTE_LAYERS)"
summary_pg_local_route_mode="$(status_value PG_LOCAL_ROUTE_MODE)"
summary_pg_route_strategy="$(status_value PG_ROUTE_STRATEGY)"

if [[ -z "$summary_route_profile" ]]; then
  summary_route_profile="${SPADMIC_OOC_ROUTE_PROFILE:-default}"
fi
if [[ -z "$summary_signal_route_layers" ]]; then
  case "$summary_route_profile" in
    met2_first|met2_first_antenna)
      summary_signal_route_layers="MET2-MET3"
      ;;
    *)
      summary_signal_route_layers="${SPADMIC_OOC_SIGNAL_BOTTOM_LAYER:-MET1}-${SPADMIC_OOC_SIGNAL_TOP_LAYER:-MET3}"
      ;;
  esac
fi
if [[ -z "$summary_pg_local_route_mode" ]]; then
  case "${SPADMIC_OOC_ENABLE_PG_SROUTE:-0}" in
    1|yes|YES|true|TRUE|on|ON)
      summary_pg_local_route_mode="ENABLED_FROM_ENVIRONMENT"
      ;;
    *)
      summary_pg_local_route_mode="DEFERRED_TO_TOP_LEVEL"
      ;;
  esac
fi
if [[ -z "$summary_pg_route_strategy" ]]; then
  summary_pg_route_strategy="UNREPORTED"
fi

{
  echo "block,top_module,genus_run_id,innovus_run_id,netlist,sdc,result,status_report,handoff_root"
  printf '%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$BLOCK" "$TOP_MODULE" "$GENUS_RUN_ID" "$RUN_ID" "$NETLIST" "$SDC" \
    "$result" "$status_rpt" "$HANDOFF_ROOT"
} > "$RUN_ROOT/reports/ooc_harden_manifest.csv"

{
  echo "# SPADMIC Matrix TOP Innovus OOC Hardening"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Run directory: \`$RUN_ROOT\`"
  echo "- Block: \`$BLOCK\`"
  echo "- Top module: \`$TOP_MODULE\`"
  echo "- Genus run ID: \`$GENUS_RUN_ID\`"
  echo "- Genus root: \`$GENUS_ROOT\`"
  echo "- Branch: \`$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo unknown)\`"
  echo "- Commit: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)\`"
  echo "- XH018 stack: \`$MPTDC_XH018_STACK\`"
  echo "- Standard-cell family: \`$MPTDC_STDCELL_FAMILY\`"
  echo "- OOC route profile: \`$summary_route_profile\`"
  echo "- Ordinary signal route layers: \`$summary_signal_route_layers\`"
  echo "- Power access layer: \`METTP\`"
  echo "- Local PG route mode: \`$summary_pg_local_route_mode\`"
  echo "- PG route strategy: \`$summary_pg_route_strategy\`"
  echo "- Physical configuration source: \`$status_rpt\`"
  echo "- Layout audit: \`$LAYOUT_AUDIT_DIR\`"
  echo "- Handoff root: \`$HANDOFF_ROOT\`"
  echo "- Innovus return code: \`$innovus_rc\`"
  echo "- Mapped/merged GDS audit return code: \`$gds_audit_rc\`"
  echo "- Canonical TX OOC gate return code: \`$tx_ooc_gate_rc\`"
  echo
  echo "## Result"
  echo
  echo "- Result: \`$result\`"
  echo "- Status report: \`$status_rpt\`"
  echo "- GDS export audit: \`$gds_audit_rpt\`"
  echo "- Canonical TX OOC gate: \`$tx_ooc_gate_rpt\`"
  echo "- Manifest: \`reports/ooc_harden_manifest.csv\`"
  echo
  echo "This is typical-only Innovus OOC implementation. PVS, PEX, MMMC, and foundry LVS are deferred; do not label this SIGNOFF_READY."
} > "$RUN_ROOT/SUMMARY.md"

cp "$RUN_ROOT/SUMMARY.md" "$BLOCK_ROOT/SUMMARY.md"
cat "$RUN_ROOT/SUMMARY.md"

if [[ "$result" == "ABSTRACT_READY_FOR_TOP_REVIEW" ]]; then
  exit 0
fi
if [[ "$innovus_rc" -eq 0 ]]; then
  exit 8
fi
exit "$innovus_rc"
