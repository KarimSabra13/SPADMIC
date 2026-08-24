#!/usr/bin/env bash
# Collect reviewable MPTDC server-run evidence into a tracked docs folder.
# The collector intentionally avoids checkpoints, databases, GDS, and large
# binary artifacts unless explicitly requested by environment.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  MPTDC/ci/collect_mptdc_server_snapshot.sh <genus|innovus|drygds|pvs> <RUN_ID>

Optional environment:
  SPADMIC_WORK_ROOT              Default: /sim/ksabra/SPADMIC_work
  MPTDC_SNAPSHOT_ROOT            Default: MPTDC/docs/server_snapshots
  MPTDC_SNAPSHOT_SOURCE_DIR      Override source directory, required for many drygds/pvs runs.
  MPTDC_SNAPSHOT_INCLUDE_NETLIST Set to 1 to include mptdc_axis_core.postsyn.v.
  MPTDC_SNAPSHOT_INCLUDE_DEF     Set to 1 to include DEF files from Innovus snapshots.
  MPTDC_SNAPSHOT_MAX_TEXT_BYTES  Largest copied text file. Default: 2097152.

Run this from the repository checkout on the server after the corresponding run
finishes. Stage only the snapshot directory printed by this script.
USAGE
}

if [[ $# -ne 2 ]]; then
  usage >&2
  exit 2
fi

KIND="$1"
RUN_ID="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MPTDC_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_ROOT/.." && pwd)"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
SNAPSHOT_ROOT="${MPTDC_SNAPSHOT_ROOT:-$MPTDC_ROOT/docs/server_snapshots}"
MAX_TEXT_BYTES="${MPTDC_SNAPSHOT_MAX_TEXT_BYTES:-2097152}"

if [[ ! "$MAX_TEXT_BYTES" =~ ^[1-9][0-9]*$ ]]; then
  echo "ERROR: MPTDC_SNAPSHOT_MAX_TEXT_BYTES must be a positive integer" >&2
  exit 2
fi

case "$KIND" in
  genus)   SRC_DIR="${MPTDC_SNAPSHOT_SOURCE_DIR:-$WORK_ROOT/genus/$RUN_ID}" ;;
  innovus) SRC_DIR="${MPTDC_SNAPSHOT_SOURCE_DIR:-$WORK_ROOT/innovus/$RUN_ID}" ;;
  drygds|pvs)
    if [[ -n "${MPTDC_SNAPSHOT_SOURCE_DIR:-}" ]]; then
      SRC_DIR="$MPTDC_SNAPSHOT_SOURCE_DIR"
    else
      SRC_DIR="$WORK_ROOT/innovus/$RUN_ID"
    fi
    ;;
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
  local lines="${3:-260}"
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
  local lines="${4:-320}"
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

copy_text_tree() {
  local root="$1"
  local dst_prefix="$2"
  [[ -d "$root" ]] || return 0
  while IFS= read -r file; do
    local rel="${file#"$root"/}"
    local size
    size="$(wc -c < "$file")"
    if (( size <= MAX_TEXT_BYTES )); then
      copy_file "$file" "$dst_prefix/$rel"
    else
      printf '%s\t%s\n' "$size" "$file" >> "$DST_DIR/skipped_large_text.tmp"
    fi
  done < <(
    find "$root" -type f \
      \( -name '*.rpt' -o -name '*.csv' -o -name '*.tsv' -o -name '*.txt' \
         -o -name '*.md' -o -name '*.sum' -o -name '*.shorts' -o -name '*.out' \
         -o -name '*.err' -o -name '*.rep' -o -name '*.RPT' -o -name '*.CSV' \
         -o -name '*.TSV' -o -name '*.TXT' -o -name '*.MD' -o -name '*.SUM' \
         -o -name '*.SHORTS' -o -name '*.OUT' -o -name '*.ERR' \
         -o -name '*.REP' \) 2>/dev/null | sort
  )
}

copy_console_tails() {
  local root="$1"
  local dst_prefix="$2"
  [[ -d "$root" ]] || return 0
  while IFS= read -r file; do
    local rel="${file#"$root"/}"
    copy_matching_tail "$file" "$dst_prefix/${rel}.messages.tail" \
      '(^\*\*(WARN|ERROR|INFO)|\b(ERROR|WARN|FATAL|PASS|FAIL|STATUS|READY|VIOL|short|SHORT|match|MATCH|mismatch|MISMATCH)\b)' 500
  done < <(
    find "$root" -type f \
      \( -name '*.stdout' -o -name '*.out' -o -name '*.OUT' \
         -o -name '*.err' -o -name '*.ERR' -o -name '*.log' \
         -o -name '*.LOG' \) 2>/dev/null | sort
  )
}

copy_pvs_controls() {
  local root="$1"
  local dst_prefix="$2"
  [[ -d "$root" ]] || return 0
  while IFS= read -r file; do
    local rel="${file#"$root"/}"
    local size
    size="$(wc -c < "$file")"
    if (( size <= MAX_TEXT_BYTES )); then
      copy_file "$file" "$dst_prefix/$rel"
    else
      printf '%s\t%s\n' "$size" "$file" >> "$DST_DIR/skipped_large_text.tmp"
    fi
  done < <(
    find "$root" -type f \
      \( -name 'run.pvs' -o -name 'pvsdrcctl' -o -name 'pvslvsctl' \
         -o -name '.config.rul' -o -name '.technology.rul' \
         -o -name 'cell_tree.txt' \) 2>/dev/null | sort
  )
}

copy_log_tails() {
  local root="$1"
  local dst_prefix="$2"
  [[ -d "$root" ]] || return 0
  while IFS= read -r file; do
    local rel="${file#"$root"/}"
    copy_matching_tail "$file" "$dst_prefix/${rel}.messages.tail" '(^\*\*(WARN|ERROR|INFO)|\b(ERROR|WARN|FATAL|PASS|FAIL|STATUS|READY|VIOL|short|SHORT)\b)' 360
  done < <(find "$root" -type f -name '*.log' 2>/dev/null | sort)
}

copy_file "$SRC_DIR/SUMMARY.md" "SUMMARY.md"
copy_file "$SRC_DIR/run_manifest.txt" "run_manifest.txt"
copy_file "$SRC_DIR/git_status_short.txt" "git_status_short.txt"

case "$KIND" in
  genus)
    copy_file "$SRC_DIR/mptdc_axis_core.postsyn.sdc" "outputs/mptdc_axis_core.postsyn.sdc"
    copy_file "$SRC_DIR/final_sdc_overlay_used.sdc" "outputs/final_sdc_overlay_used.sdc"
    copy_file "$SRC_DIR/final_filelist_used.f" "outputs/final_filelist_used.f"
    copy_file "$SRC_DIR/sdc_command_failures.md" "sdc_command_failures.md"
    copy_file "$SRC_DIR/report_clocks.rpt" "reports/report_clocks.rpt"
    copy_file "$SRC_DIR/report_exceptions.rpt" "reports/report_exceptions.rpt"
    copy_file "$SRC_DIR/check_timing_intent_post_synth.rpt" "reports/check_timing_intent_post_synth.rpt"
    copy_file "$SRC_DIR/report_design_rules.rpt" "reports/report_design_rules.rpt"
    copy_text_tree "$SRC_DIR/reports" "reports"
    copy_log_tails "$SRC_DIR/logs" "logs"
    copy_matching_tail "$SRC_DIR/genus_${RUN_ID}.log" "logs/genus_${RUN_ID}.messages.tail" '(^\*\*(WARN|ERROR|INFO)|\b(ERROR|WARN|FATAL|PASS|FAIL|GENUS_TYPICAL|INNOVUS_READY)\b)' 500
    if [[ "${MPTDC_SNAPSHOT_INCLUDE_NETLIST:-0}" == "1" ]]; then
      copy_file "$SRC_DIR/mptdc_axis_core.postsyn.v" "outputs/mptdc_axis_core.postsyn.v"
    fi
    ;;
  innovus)
    copy_text_tree "$SRC_DIR/reports" "reports"
    copy_text_tree "$SRC_DIR/manifests" "manifests"
    copy_text_tree "$SRC_DIR/outputs" "outputs"
    copy_log_tails "$SRC_DIR/logs" "logs"
    if [[ "${MPTDC_SNAPSHOT_INCLUDE_DEF:-0}" == "1" ]]; then
      copy_text_tree "$SRC_DIR/def" "def"
      while IFS= read -r file; do
        rel="${file#"$SRC_DIR/def"/}"
        copy_file "$file" "def/$rel"
      done < <(find "$SRC_DIR/def" -type f -name '*.def' 2>/dev/null | sort)
    fi
    ;;
  drygds|pvs)
    copy_text_tree "$SRC_DIR/reports" "reports"
    copy_text_tree "$SRC_DIR/logs" "logs"
    copy_text_tree "$SRC_DIR/manifests" "manifests"
    copy_text_tree "$SRC_DIR/pvs_lvs" "pvs_lvs"
    copy_text_tree "$SRC_DIR/pvs_drc" "pvs_drc"
    copy_text_tree "$SRC_DIR/outputs" "outputs"
    copy_log_tails "$SRC_DIR/logs" "logs"
    copy_pvs_controls "$SRC_DIR/pvs_drc" "pvs_drc"
    copy_pvs_controls "$SRC_DIR/pvs_lvs" "pvs_lvs"
    copy_console_tails "$SRC_DIR/pvs_drc" "pvs_drc"
    copy_console_tails "$SRC_DIR/pvs_lvs" "pvs_lvs"
    ;;
esac

{
  echo "# MPTDC Server Snapshot"
  echo
  echo "- Kind: \`$KIND\`"
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Source directory: \`$SRC_DIR\`"
  echo "- Snapshot directory: \`$DST_DIR\`"
  echo "- Collection branch: \`$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || echo unknown)\`"
  echo "- Collection commit: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)\`"
  echo "- Created UTC: \`$(date -u +%Y-%m-%dT%H:%M:%SZ)\`"
  echo
  echo "## Included Files"
  find "$DST_DIR" -type f ! -name 'skipped_large_text.tmp' \
    | sed "s#^$DST_DIR/##" | sort | sed 's/^/- `/' | sed 's/$/`/'
  echo
  echo "## Excluded By Policy"
  echo
  echo "- Innovus checkpoints and databases;"
  echo "- raw GDS/OAS files;"
  echo "- full raw logs unless converted to message tails;"
  echo "- text files larger than $MAX_TEXT_BYTES bytes;"
  echo "- large binary artifacts;"
  echo "- server work directories outside this snapshot."
  if [[ -f "$DST_DIR/skipped_large_text.tmp" ]]; then
    echo
    echo "## Skipped Large Text Files"
    echo
    echo '```text'
    cat "$DST_DIR/skipped_large_text.tmp"
    echo '```'
  fi
} > "$DST_DIR/README.md"

rm -f "$DST_DIR/skipped_large_text.tmp"

echo "Snapshot created: $DST_DIR"
echo
echo "Review, then stage only this directory:"
echo "  git add $DST_DIR"
