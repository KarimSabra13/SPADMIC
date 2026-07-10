#!/usr/bin/env bash
# Read-only backup before copying the corrected _HV OA layout onto canonical cell.
set -u -o pipefail

OA_LIBRARY_ROOT="${1:-}"
HV_GDS="${2:-}"
BACKUP_ID="${3:-tx_packet_oa_backup_$(date +%Y%m%d_%H%M%S)}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
BACKUP_ROOT="$WORK_ROOT/handoff/innovus/_source_archive/tx_packet_core/$BACKUP_ID"

if [[ -z "$OA_LIBRARY_ROOT" || -z "$HV_GDS" ]]; then
  echo "Usage: $0 <OA-library-directory> <fixed-HV-GDS> [backup-id]" >&2
  exit 2
fi
if [[ ! -d "$OA_LIBRARY_ROOT/spadmic_tx_packet_core" || ! -d "$OA_LIBRARY_ROOT/spadmic_tx_packet_core_HV" ]]; then
  echo "ERROR: canonical and _HV OA cell directories must both exist under $OA_LIBRARY_ROOT" >&2
  exit 6
fi
if [[ ! -s "$HV_GDS" || -e "$BACKUP_ROOT" ]]; then
  echo "ERROR: fixed GDS missing or immutable backup already exists: $BACKUP_ROOT" >&2
  exit 6
fi
mkdir -p "$BACKUP_ROOT/oa" "$BACKUP_ROOT/gds" "$BACKUP_ROOT/manifests"
cp -a "$OA_LIBRARY_ROOT/spadmic_tx_packet_core" "$BACKUP_ROOT/oa/"
cp -a "$OA_LIBRARY_ROOT/spadmic_tx_packet_core_HV" "$BACKUP_ROOT/oa/"
cp -p "$HV_GDS" "$BACKUP_ROOT/gds/"
{
  echo "LABEL=TX_PACKET_OA_PRE_PROMOTION_BACKUP"
  echo "STATUS=PASS"
  echo "OA_LIBRARY_ROOT=$OA_LIBRARY_ROOT"
  echo "CANONICAL_CELL=spadmic_tx_packet_core"
  echo "FIXED_SOURCE_CELL=spadmic_tx_packet_core_HV"
  echo "FIXED_SOURCE_GDS=$HV_GDS"
  echo "ACTION_AFTER_BACKUP=MANUAL_GUI_COPY_LAYOUT_HV_TO_CANONICAL_THEN_XSTREAM_OUT_CANONICAL_TOP"
  echo "OA_MODIFICATION_PERFORMED=NO"
} >"$BACKUP_ROOT/manifests/backup_status.rpt"
find "$BACKUP_ROOT" -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum >"$BACKUP_ROOT/manifests/SHA256SUMS"
echo "BACKUP_ROOT=$BACKUP_ROOT"
cat "$BACKUP_ROOT/manifests/backup_status.rpt"
