#!/usr/bin/env bash
# Restore an OOC block and add only local PG stitching. Signal route is preserved.
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SOURCE_BLOCK_ROOT="${1:-}"
BLOCK="${2:-}"
RUN_ID="${3:-innovus_ooc_pg_only_${BLOCK:-block}_$(date +%Y%m%d_%H%M%S)}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"

if [[ -z "$SOURCE_BLOCK_ROOT" || -z "$BLOCK" ]]; then
  echo "Usage: $0 <source-block-root> <block-name> [run-id]" >&2
  exit 2
fi
if [[ "$BLOCK" != "tx_ddr_strip" ]]; then
  echo "ERROR: only tx_ddr_strip is approved for restore-only Innovus PG; packet PG remains manual OA work" >&2
  exit 6
fi

CHECKPOINT="$SOURCE_BLOCK_ROOT/checkpoints/05_postroute_export.enc.dat"
[[ -d "$CHECKPOINT" ]] || CHECKPOINT="$SOURCE_BLOCK_ROOT/checkpoints/05_postroute_export.enc"
if [[ ! -e "$CHECKPOINT" ]]; then
  echo "ERROR: source checkpoint missing under $SOURCE_BLOCK_ROOT/checkpoints" >&2
  exit 6
fi

RUN_ROOT="$WORK_ROOT/innovus/$RUN_ID"
if [[ -e "$RUN_ROOT" ]]; then
  echo "ERROR: immutable run exists: $RUN_ROOT" >&2
  exit 2
fi
mkdir -p "$RUN_ROOT"/{checkpoints,logs,outputs,reports}
STREAM_MAP="${SPADMIC_STREAMOUT_MAP_FILE:-/eda/pdk/xfab/xh018/cadence/v10_1/PDK/IC61/v10_1_1/TECH_XH018_HD_1131/pnr_streamout.map}"
STDCELL_GDS="${SPADMIC_STDCELL_GDS:-/data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/gds/xh018_D_CELLS_JIHD.gds}"
[[ -s "$STREAM_MAP" ]] || { echo "ERROR: streamout map missing: $STREAM_MAP" >&2; exit 6; }
[[ -s "$STDCELL_GDS" ]] || { echo "ERROR: JIHD GDS missing: $STDCELL_GDS" >&2; exit 6; }
if ! command -v innovus >/dev/null 2>&1; then
  echo "ERROR: innovus missing; source /eda/cadence/eda_2023-2024" >&2
  exit 3
fi

export SPADMIC_REPO_ROOT="$REPO_ROOT"
export SPADMIC_PG_PATCH_SOURCE_CHECKPOINT="$CHECKPOINT"
export SPADMIC_PG_PATCH_RUN_ROOT="$RUN_ROOT"
export SPADMIC_PG_PATCH_BLOCK="$BLOCK"
export SPADMIC_PG_PATCH_TOP="spadmic_tx_ddr_strip"
export SPADMIC_PG_PATCH_VDD_X_UM="${SPADMIC_PG_PATCH_VDD_X_UM:-880.880}"
export SPADMIC_PG_PATCH_VSS_X_UM="${SPADMIC_PG_PATCH_VSS_X_UM:-2642.080}"
export SPADMIC_PG_PATCH_STRAP_WIDTH_UM="${SPADMIC_PG_PATCH_STRAP_WIDTH_UM:-3.360}"
export SPADMIC_STREAMOUT_MAP_FILE="$STREAM_MAP"
export SPADMIC_PG_PATCH_STDCELL_GDS="$STDCELL_GDS"

{
  echo "RUN_ID=$RUN_ID"
  echo "SOURCE_BLOCK_ROOT=$SOURCE_BLOCK_ROOT"
  echo "SOURCE_CHECKPOINT=$CHECKPOINT"
  echo "BLOCK=$BLOCK"
  echo "HEAD=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null)"
  echo "VDD_X_UM=$SPADMIC_PG_PATCH_VDD_X_UM"
  echo "VSS_X_UM=$SPADMIC_PG_PATCH_VSS_X_UM"
  echo "STRAP_WIDTH_UM=$SPADMIC_PG_PATCH_STRAP_WIDTH_UM"
  echo "SIGNAL_ROUTE_POLICY=PRESERVE_NO_ROUTE_DESIGN"
  echo "STDCELL_GDS=$STDCELL_GDS"
} >"$RUN_ROOT/run_manifest.rpt"

innovus -nowin -init "$SCRIPT_DIR/run_innovus_ooc_pg_only_patch.tcl" \
  -log "$RUN_ROOT/logs/innovus.log" >"$RUN_ROOT/logs/innovus.stdout.log" 2>&1
RC=$?
echo "PG_PATCH_RC=$RC"
cat "$RUN_ROOT/reports/pg_only_patch_status.rpt" 2>/dev/null || echo "MISSING STATUS"
exit "$RC"
