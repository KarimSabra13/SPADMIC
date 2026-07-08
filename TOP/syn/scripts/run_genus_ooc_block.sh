#!/usr/bin/env bash
# =============================================================================
# SPADMIC matrix-top -- single-block server Genus OOC runner
# =============================================================================
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  TOP/syn/scripts/run_genus_ooc_block.sh <block-or-top-module> [RUN_ID]

Examples:
  TOP/syn/scripts/run_genus_ooc_block.sh spadmic_matrix_reset_ctrl
  TOP/syn/scripts/run_genus_ooc_block.sh matrix_reset_ctrl matrix_reset_ctrl_ooc_$(date +%Y%m%d_%H%M)

This is a typical-only OOC feasibility run. It does not run full top, MMMC,
Innovus, DRC/LVS, PEX, or signoff.
USAGE
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BLOCK_IN="$1"
RUN_ID="${2:-genus_ooc_${BLOCK_IN}_$(date +%Y%m%d_%H%M)}"

case "$BLOCK_IN" in
  matrix_reset_ctrl|spadmic_matrix_reset_ctrl)
    BLOCK_SPEC="matrix_reset_ctrl:spadmic_matrix_reset_ctrl"
    ;;
  or64_tree|spadmic_matrix_or_tree)
    BLOCK_SPEC="or64_tree:spadmic_matrix_or_tree"
    ;;
  position_snapshot|spadmic_position_snapshot_packetizer)
    BLOCK_SPEC="position_snapshot:spadmic_position_snapshot_packetizer"
    ;;
  matrix_cfg_ctrl|spadmic_matrix_cfg_ctrl)
    BLOCK_SPEC="matrix_cfg_ctrl:spadmic_matrix_cfg_ctrl"
    ;;
  event_coordinator|spadmic_event_coordinator)
    BLOCK_SPEC="event_coordinator:spadmic_event_coordinator"
    ;;
  event_bundle_tx|spadmic_event_bundle_tx)
    BLOCK_SPEC="event_bundle_tx:spadmic_event_bundle_tx"
    ;;
  output_fifo|spadmic_output_fifo)
    BLOCK_SPEC="output_fifo:spadmic_output_fifo"
    ;;
  ddr16_pairer|spadmic_ddr16_tx_pairer)
    BLOCK_SPEC="ddr16_pairer:spadmic_ddr16_tx_pairer"
    ;;
  ddrs2_adapter|spadmic_ddrs2_adapter)
    BLOCK_SPEC="ddrs2_adapter:spadmic_ddrs2_adapter"
    ;;
  matrix_top_csr|spadmic_matrix_top_csr)
    BLOCK_SPEC="matrix_top_csr:spadmic_matrix_top_csr"
    ;;
  i2c_csr_bridge|spadmic_i2c_csr_bridge)
    BLOCK_SPEC="i2c_csr_bridge:spadmic_i2c_csr_bridge"
    ;;
  i2c_slave|spadmic_i2c_slave)
    BLOCK_SPEC="i2c_slave:spadmic_i2c_slave"
    ;;
  *)
    echo "ERROR: unknown OOC block: $BLOCK_IN" >&2
    usage >&2
    exit 2
    ;;
esac

export SPADMIC_GENUS_OOC_BLOCKS="$BLOCK_SPEC"
exec "$SCRIPT_DIR/run_genus_all_matrix_ooc.sh" "$RUN_ID"
