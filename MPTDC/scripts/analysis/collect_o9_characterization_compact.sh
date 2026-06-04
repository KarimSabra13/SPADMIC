#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MPTDC_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

SRC_ROOT="${O9_CHAR_EXTERNAL_ROOT:-/sim/ksabra/Sim/20260604_o9_r750_delta5_overnight/results}"
DST_ROOT="${O9_CHAR_COMPACT_OUT:-$REPO_ROOT/results/o9_char/20260604_o9_r750_delta5_overnight_compact}"

mkdir -p "$DST_ROOT"

{
  echo "# O9 R750 Delta5 Compact Characterization Collection"
  echo "created: $(date -Iseconds)"
  echo "repo: $REPO_ROOT"
  echo "branch: $(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
  echo "head: $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
  echo "source_root: $SRC_ROOT"
  echo "destination_root: $DST_ROOT"
  echo
} > "$DST_ROOT/COLLECTION_MANIFEST.md"

if [[ ! -d "$SRC_ROOT" ]]; then
  {
    echo "ERROR: external characterization root is not accessible."
    echo "Set O9_CHAR_EXTERNAL_ROOT to the server-side results path if needed."
  } | tee -a "$DST_ROOT/COLLECTION_MANIFEST.md" >&2
  exit 2
fi

copy_one() {
  local rel="$1"
  local src="$SRC_ROOT/$rel"
  local dst="$DST_ROOT/$rel"
  mkdir -p "$(dirname "$dst")"
  if [[ -f "$src" ]]; then
    cp "$src" "$dst"
    echo "copied: $rel" >> "$DST_ROOT/COLLECTION_MANIFEST.md"
  else
    echo "missing: $rel" >> "$DST_ROOT/COLLECTION_MANIFEST.md"
  fi
}

copy_first_match() {
  local label="$1"
  shift
  local rel
  for rel in "$@"; do
    if [[ -f "$SRC_ROOT/$rel" ]]; then
      copy_one "$rel"
      echo "selected_$label: $rel" >> "$DST_ROOT/COLLECTION_MANIFEST.md"
      return 0
    fi
  done
  echo "missing_group: $label" >> "$DST_ROOT/COLLECTION_MANIFEST.md"
  return 0
}

copy_one "overnight_manifest.json"
copy_one "characterization/characterization_manifest.json"

copy_first_match packet_parse \
  "characterization/analysis/sweep/packet_parse_summary.json" \
  "characterization/analysis/sweep/packet_parse_report.json" \
  "characterization/analysis/sweep/summary_report.json"

copy_first_match packet_parse_text \
  "characterization/analysis/sweep/packet_parse_summary.txt" \
  "characterization/analysis/sweep/packet_parse_report.txt" \
  "characterization/analysis/sweep/summary_report.txt"

copy_one "characterization/analysis/sweep/summary_report.json"
copy_one "characterization/analysis/sweep/summary_report.txt"
copy_one "characterization/analysis/sweep/analysis_memory_report.txt"
copy_one "characterization/analysis/sweep/chunked_metrics_summary.csv"

copy_one "characterization/analysis/calibration/calibration_report.json"
copy_one "characterization/analysis/calibration/calibration_report.txt"
copy_one "characterization/analysis/calibration/val_reconstruction_errors_pre_post.csv"

copy_one "characterization/fixed_delay/analysis/fixed_delay_report.json"
copy_one "characterization/fixed_delay/analysis/fixed_delay_report.txt"
copy_one "characterization/fixed_delay/analysis/fixed_delay_summary.csv"
copy_one "characterization/fixed_delay/analysis/fixed_delay_averaging.csv"

copy_first_match raw_tag_decode \
  "characterization/analysis/sweep/raw_tag_decode_report.json" \
  "characterization/analysis/sweep/raw_tag_decode_summary.json" \
  "characterization/analysis/calibration/raw_tag_decode_report.json"

copy_first_match dnl_inl \
  "characterization/analysis/calibration/dnl_inl_summary.json" \
  "characterization/analysis/calibration/code_density_summary.json" \
  "characterization/analysis/sweep/dnl_inl_summary.json"

copy_first_match boundary_bias \
  "characterization/analysis/calibration/boundary_class_report.json" \
  "characterization/analysis/sweep/boundary_class_report.json" \
  "characterization/analysis/sweep/boundary_bias_summary.json"

find "$DST_ROOT" -type f | sort > "$DST_ROOT/COMPACT_FILE_INDEX.txt"

echo "Compact O9 characterization summaries collected in $DST_ROOT"
