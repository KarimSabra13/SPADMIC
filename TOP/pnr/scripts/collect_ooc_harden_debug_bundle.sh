#!/usr/bin/env bash
# Collect text reports from one OOC hardening run into a tracked debug bundle.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  TOP/pnr/scripts/collect_ooc_harden_debug_bundle.sh <BLOCK_ROOT> [DEST_DIR]

Default DEST_DIR:
  TOP/docs/pnr_debug/<block>/<run_id>

By default this copies reports, generated collateral, manifests, summaries,
and log excerpts only. It writes a manifest of output files but does not copy
large DEF/GDS/netlist artifacts. Set SPADMIC_COLLECT_OOC_INCLUDE_OUTPUTS=1 to
also copy outputs/.
USAGE
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TOP_ROOT="$(cd "$PNR_ROOT/.." && pwd)"
REPO_ROOT="$(cd "$TOP_ROOT/.." && pwd)"

BLOCK_ROOT="$(cd "$1" && pwd)"
BLOCK="$(basename "$BLOCK_ROOT")"
RUN_ROOT="$(cd "$BLOCK_ROOT/../.." && pwd)"
RUN_ID="$(basename "$RUN_ROOT")"
DEST="${2:-$REPO_ROOT/TOP/docs/pnr_debug/$BLOCK/$RUN_ID}"
INCLUDE_OUTPUTS="${SPADMIC_COLLECT_OOC_INCLUDE_OUTPUTS:-0}"

mkdir -p "$DEST"

copy_dir_if_exists() {
  local src="$1"
  local dst="$2"
  if [[ -d "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    rm -rf "$dst"
    cp -a "$src" "$dst"
  fi
}

copy_file_if_exists() {
  local src="$1"
  local dst="$2"
  if [[ -f "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
  fi
}

copy_log_excerpt() {
  local src="$1"
  local dst="$2"
  if [[ -f "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    {
      echo "# Log excerpt from $src"
      echo "# First 400 lines"
      sed -n '1,400p' "$src"
      echo
      echo "# Last 4000 lines"
      tail -n 4000 "$src"
    } > "$dst"
  fi
}

copy_file_if_exists "$RUN_ROOT/SUMMARY.md" "$DEST/SUMMARY.md"
copy_file_if_exists "$RUN_ROOT/run_manifest.txt" "$DEST/run_manifest.txt"
copy_file_if_exists "$RUN_ROOT/reports/ooc_harden_manifest.csv" "$DEST/reports/ooc_harden_manifest.csv"
copy_file_if_exists "$BLOCK_ROOT/SUMMARY.md" "$DEST/block_SUMMARY.md"
copy_dir_if_exists "$BLOCK_ROOT/reports" "$DEST/reports"
copy_dir_if_exists "$BLOCK_ROOT/generated" "$DEST/generated"

mkdir -p "$DEST/logs"
copy_log_excerpt "$BLOCK_ROOT/logs/innovus.log" "$DEST/logs/innovus.log.excerpt"
copy_log_excerpt "$BLOCK_ROOT/logs/innovus.stdout.log" "$DEST/logs/innovus.stdout.log.excerpt"
copy_log_excerpt "$BLOCK_ROOT/logs/dump_drc_markers.log" "$DEST/logs/dump_drc_markers.log.excerpt"
copy_log_excerpt "$BLOCK_ROOT/logs/dump_drc_markers.stdout.log" "$DEST/logs/dump_drc_markers.stdout.log.excerpt"

mkdir -p "$DEST/manifests"
{
  echo "path,size_bytes"
  if [[ -d "$BLOCK_ROOT/outputs" ]]; then
    find "$BLOCK_ROOT/outputs" -maxdepth 1 -type f -printf '%p,%s\n' | sort
  fi
} > "$DEST/manifests/outputs_file_manifest.csv"

{
  echo "path,size_bytes"
  find "$DEST" -type f -printf '%P,%s\n' | sort
} > "$DEST/manifests/debug_bundle_file_manifest.csv"

if [[ "$INCLUDE_OUTPUTS" == "1" ]]; then
  copy_dir_if_exists "$BLOCK_ROOT/outputs" "$DEST/outputs"
fi

cat > "$DEST/README.md" <<EOF
# OOC Hardening Debug Bundle: $RUN_ID

- Block: \`$BLOCK\`
- Source block root: \`$BLOCK_ROOT\`
- Source run root: \`$RUN_ROOT\`
- Collected by: \`TOP/pnr/scripts/collect_ooc_harden_debug_bundle.sh\`
- Large outputs copied: \`$INCLUDE_OUTPUTS\`

This bundle is for local debug/review only. It is not signoff evidence.

## Key Files

- \`reports/ooc_harden_status.rpt\`
- \`reports/verify_drc_post_route.rpt\`
- \`reports/verify_drc_post_route_markers.tsv\` if marker dump was run
- \`reports/FILLER_MODE.rpt\`
- \`reports/POSTROUTE_DRC_CLEANUP.rpt\`
- \`reports/verify_connectivity_regular.rpt\`
- \`reports/SROUTE_PG.rpt\`
- \`generated/ooc_block_context.md\`
- \`generated/ooc_block_pin_plan.csv\`
- \`manifests/outputs_file_manifest.csv\`
EOF

echo "DEBUG_BUNDLE=$DEST"
find "$DEST" -maxdepth 3 -type f -print | sort
