#!/usr/bin/env bash
# Collect small, reviewable server-run evidence into a tracked docs folder.
# This intentionally excludes raw simulator/tool work directories and large logs.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  TOP/ci/collect_matrix_top_server_snapshot.sh <xcelium|genus|innovus> <RUN_ID>

Optional environment:
  SPADMIC_WORK_ROOT       Default: /sim/ksabra/SPADMIC_work
  SPADMIC_SNAPSHOT_ROOT   Default: TOP/docs/server_snapshots

The script copies summaries, manifests, failure tails, and selected lightweight
reports only. It must be run from a repository checkout on the server after the
corresponding run completes.
USAGE
}

if [[ $# -ne 2 ]]; then
  usage >&2
  exit 2
fi

KIND="$1"
RUN_ID="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$TOP_ROOT/.." && pwd)"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
SNAPSHOT_ROOT="${SPADMIC_SNAPSHOT_ROOT:-$TOP_ROOT/docs/server_snapshots}"

case "$KIND" in
  xcelium) SRC_DIR="$WORK_ROOT/xcelium/$RUN_ID" ;;
  genus)   SRC_DIR="$WORK_ROOT/genus/$RUN_ID" ;;
  innovus) SRC_DIR="$WORK_ROOT/innovus/$RUN_ID" ;;
  *)
    echo "ERROR: unsupported snapshot kind: $KIND" >&2
    usage >&2
    exit 2
    ;;
esac

if [[ ! -d "$SRC_DIR" ]]; then
  echo "ERROR: run directory not found: $SRC_DIR" >&2
  exit 3
fi

DST_DIR="$SNAPSHOT_ROOT/$KIND/$RUN_ID"
if [[ -e "$DST_DIR" ]]; then
  echo "ERROR: snapshot directory already exists: $DST_DIR" >&2
  exit 4
fi

mkdir -p "$DST_DIR"

copy_file() {
  local src="$1"
  local dst_rel="$2"
  if [[ -f "$src" ]]; then
    mkdir -p "$DST_DIR/$(dirname "$dst_rel")"
    cp "$src" "$DST_DIR/$dst_rel"
  fi
}

copy_excerpt() {
  local src="$1"
  local dst_rel="$2"
  local lines="${3:-240}"
  if [[ -f "$src" ]]; then
    mkdir -p "$DST_DIR/$(dirname "$dst_rel")"
    {
      echo "# Excerpt from $src"
      echo "# First $lines lines"
      sed -n "1,${lines}p" "$src"
    } > "$DST_DIR/$dst_rel"
  fi
}

copy_matching_tail() {
  local src="$1"
  local dst_rel="$2"
  local pattern="$3"
  local lines="${4:-240}"
  if [[ -f "$src" ]]; then
    mkdir -p "$DST_DIR/$(dirname "$dst_rel")"
    {
      echo "# Matching tail from $src"
      echo "# Pattern: $pattern"
      echo "# Last $lines matching lines"
      grep -E "$pattern" "$src" | tail -n "$lines" || true
    } > "$DST_DIR/$dst_rel"
  fi
}

copy_sdc_clock_groups() {
  local src="$1"
  local dst_rel="$2"
  if [[ -f "$src" ]]; then
    mkdir -p "$DST_DIR/$(dirname "$dst_rel")"
    {
      echo "# Clock-group and clock excerpts from $src"
      grep -E 'create_clock|set_clock_groups|clk_sys|clk_cfg_40m|clk_ref_40m' "$src" || true
    } > "$DST_DIR/$dst_rel"
  fi
}

copy_file "$SRC_DIR/SUMMARY.md" "SUMMARY.md"
copy_file "$SRC_DIR/run_manifest.txt" "run_manifest.txt"
copy_file "$SRC_DIR/git_status_short.txt" "git_status_short.txt"
copy_file "$SRC_DIR/test_summary.txt" "test_summary.txt"
copy_file "$SRC_DIR/xrun_version.txt" "xrun_version.txt"

case "$KIND" in
  xcelium)
    while IFS= read -r file; do
      rel="${file#"$SRC_DIR"/}"
      copy_file "$file" "$rel"
    done < <(find "$SRC_DIR/logs" -maxdepth 1 -type f -name '*.tail' 2>/dev/null | sort)
    ;;
  genus)
    copy_file "$SRC_DIR/filelists/top_genus_excluded.f" "filelists/top_genus_excluded.f"
    while IFS= read -r file; do
      rel="${file#"$SRC_DIR"/}"
      case "$rel" in
        */logs/genus.stdout.log)
          copy_matching_tail "$file" "${rel%.log}.messages.tail" '^(Error|Warning|Info)[[:space:]]*:|^\*\*(WARN|ERROR|INFO)' 260
          ;;
        */logs/failure.tail|*/reports/messages/warning_classification.rpt)
          copy_file "$file" "$rel"
          ;;
        */reports/elaboration/check_design_post_elab.rpt|*/reports/messages/report_messages.rpt|*/reports/timing/check_timing_intent.rpt|*/reports/timing/report_clocks.rpt|*/reports/timing/report_timing_*.rpt|*/reports/qor/report_area.rpt|*/reports/qor/report_area_hierarchy.rpt|*/reports/qor/report_qor.rpt|*/reports/qor/report_design_rules.rpt)
          copy_excerpt "$file" "$rel" 220
          ;;
        */outputs/*.postsyn.sdc)
          copy_sdc_clock_groups "$file" "$rel.clock_groups.txt"
          ;;
      esac
    done < <(find "$SRC_DIR" -type f 2>/dev/null | sort)
    ;;
  innovus)
    copy_file "$SRC_DIR/logs/innovus_floorplan_seed.tail" "logs/innovus_floorplan_seed.tail"
    copy_file "$SRC_DIR/logs/innovus_staged_floorplan.tail" "logs/innovus_staged_floorplan.tail"
    copy_file "$SRC_DIR/generated/floorplan_summary.md" "generated/floorplan_summary.md"
    copy_file "$SRC_DIR/generated/top_floorplan_summary.md" "generated/top_floorplan_summary.md"
    copy_file "$SRC_DIR/generated/feasibility_status.txt" "generated/feasibility_status.txt"
    copy_file "$SRC_DIR/generated/matrix_pin_family_summary.csv" "generated/matrix_pin_family_summary.csv"
    copy_file "$SRC_DIR/generated/matrix_pin_side_summary.csv" "generated/matrix_pin_side_summary.csv"
    copy_file "$SRC_DIR/generated/matrix_unknown_pins.csv" "generated/matrix_unknown_pins.csv"
    copy_file "$SRC_DIR/generated/matrix_top_region_summary.csv" "generated/matrix_top_region_summary.csv"
    copy_file "$SRC_DIR/generated/mptdc_placeholder_summary.csv" "generated/mptdc_placeholder_summary.csv"
    copy_file "$SRC_DIR/generated/mptdc_scenario_summary.csv" "generated/mptdc_scenario_summary.csv"
    copy_file "$SRC_DIR/generated/pad_policy_summary.csv" "generated/pad_policy_summary.csv"
    copy_file "$SRC_DIR/generated/top_floorplan_regions.tcl" "generated/top_floorplan_regions.tcl"
    copy_file "$SRC_DIR/reports/ooc_collateral_manifest.csv" "reports/ooc_collateral_manifest.csv"
    while IFS= read -r file; do
      rel="${file#"$SRC_DIR"/}"
      copy_file "$file" "$rel"
    done < <(find "$SRC_DIR/blocks" -maxdepth 2 -type f -name 'SUMMARY.md' 2>/dev/null | sort)
    while IFS= read -r file; do
      rel="${file#"$SRC_DIR"/}"
      copy_excerpt "$file" "$rel" 260
    done < <(find "$SRC_DIR/reports" -type f -name '*.rpt' 2>/dev/null | sort)
    ;;
esac

SOURCE_RUN_BRANCH=""
SOURCE_RUN_HEAD=""
if [[ -f "$SRC_DIR/run_manifest.txt" ]]; then
  SOURCE_RUN_BRANCH="$(awk -F= '$1 == "BRANCH" {print $2; exit}' "$SRC_DIR/run_manifest.txt")"
  SOURCE_RUN_HEAD="$(awk -F= '$1 == "HEAD" {print $2; exit}' "$SRC_DIR/run_manifest.txt")"
fi

{
  echo "# Matrix TOP Server Snapshot"
  echo
  echo "- Kind: \`$KIND\`"
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Source directory: \`$SRC_DIR\`"
  echo "- Snapshot directory: \`$DST_DIR\`"
  if [[ -n "$SOURCE_RUN_BRANCH" ]]; then
    echo "- Source run branch: \`$SOURCE_RUN_BRANCH\`"
  fi
  if [[ -n "$SOURCE_RUN_HEAD" ]]; then
    echo "- Source run commit: \`$SOURCE_RUN_HEAD\`"
  fi
  echo "- Snapshot collection branch: \`$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo unknown)\`"
  echo "- Snapshot collection commit: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)\`"
  echo "- Created UTC: \`$(date -u +%Y-%m-%dT%H:%M:%SZ)\`"
  echo
  echo "## Included Files"
  find "$DST_DIR" -type f | sed "s#^$DST_DIR/##" | sort | sed 's/^/- `/' | sed 's/$/`/'
  echo
  echo "## Excluded By Policy"
  echo
  echo "- raw \`*.log\` files except curated tails;"
  echo "- Xcelium \`xcelium.d\` libraries;"
  echo "- Genus/Innovus databases, checkpoints, netlists, SDF/SPEF, waves, and tarballs;"
  echo "- generated server work directories under \`/sim\`."
} > "$DST_DIR/README.md"

echo "Snapshot created: $DST_DIR"
echo
echo "Review, then stage only this directory if it is small enough:"
echo "  git add $DST_DIR"
