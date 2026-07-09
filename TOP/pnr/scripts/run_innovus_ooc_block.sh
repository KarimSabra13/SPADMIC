#!/usr/bin/env bash
# =============================================================================
# SPADMIC matrix-top -- single-block Innovus OOC collateral gate
# =============================================================================
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  TOP/pnr/scripts/run_innovus_ooc_block.sh <block> <GENUS_RUN_ID> [RUN_ID]

Example:
  TOP/pnr/scripts/run_innovus_ooc_block.sh matrix_reset_ctrl genus_ooc_matrix_reset_ctrl_20260708_1200

This prepares/checks one block for the next Innovus import template. It does
not run placement, route, CTS, DRC/LVS, PEX, MMMC, or signoff.
USAGE
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BLOCK_IN="$1"
GENUS_RUN_ID="$2"
RUN_ID="${3:-innovus_ooc_${BLOCK_IN}_$(date +%Y%m%d_%H%M)}"

case "$BLOCK_IN" in
  matrix_reset_ctrl|or64_tree|position_snapshot|matrix_cfg_ctrl|event_coordinator|event_bundle_tx|tx_egress_core|output_fifo|ddr16_pairer|ddrs2_adapter|matrix_top_csr|i2c_csr_bridge|i2c_slave)
    BLOCK="$BLOCK_IN"
    ;;
  spadmic_matrix_reset_ctrl)
    BLOCK="matrix_reset_ctrl"
    ;;
  spadmic_matrix_or_tree)
    BLOCK="or64_tree"
    ;;
  spadmic_position_snapshot_packetizer)
    BLOCK="position_snapshot"
    ;;
  spadmic_matrix_cfg_ctrl)
    BLOCK="matrix_cfg_ctrl"
    ;;
  spadmic_event_coordinator)
    BLOCK="event_coordinator"
    ;;
  spadmic_event_bundle_tx)
    BLOCK="event_bundle_tx"
    ;;
  tx_egress_cluster|spadmic_tx_egress_cluster|spadmic_tx_egress_core)
    BLOCK="tx_egress_core"
    ;;
  spadmic_output_fifo)
    BLOCK="output_fifo"
    ;;
  spadmic_ddr16_tx_pairer)
    BLOCK="ddr16_pairer"
    ;;
  spadmic_ddrs2_adapter)
    BLOCK="ddrs2_adapter"
    ;;
  spadmic_matrix_top_csr)
    BLOCK="matrix_top_csr"
    ;;
  spadmic_i2c_csr_bridge)
    BLOCK="i2c_csr_bridge"
    ;;
  spadmic_i2c_slave)
    BLOCK="i2c_slave"
    ;;
  *)
    echo "ERROR: unknown OOC block: $BLOCK_IN" >&2
    usage >&2
    exit 2
    ;;
esac

export SPADMIC_INNOVUS_OOC_BLOCKS="$BLOCK"
set +e
"$SCRIPT_DIR/server_run_innovus_matrix_ooc.sh" "$RUN_ID" "$GENUS_RUN_ID"
rc=$?
set -e

# The legacy matrix OOC collateral gate returns 4 for
# READY_FOR_NEXT_IMPORT_TEMPLATE. For this single-block wrapper, treat that as a
# successful gate so server command blocks can use normal shell error handling.
if [[ "$rc" -eq 4 ]]; then
  exit 0
fi
exit "$rc"
