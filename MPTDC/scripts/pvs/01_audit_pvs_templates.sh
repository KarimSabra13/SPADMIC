#!/usr/bin/env bash
# Audit GUI-generated PVS DRC/LVS templates before replay.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=MPTDC/scripts/pvs/lib_pvs_common.sh
source "$SCRIPT_DIR/lib_pvs_common.sh"

REPO_ROOT="$(mptdc_pvs_repo_root)"
DEFAULT_OLD_BASE="/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_falsepath_nfast_risk_235618/drygds_oa_20260702_001608"
OLD_BASE="${MPTDC_PVS_OLD_BASE:-$DEFAULT_OLD_BASE}"
DRC_TEMPLATE="${MPTDC_PVS_DRC_TEMPLATE:-$OLD_BASE/pvs_drc/mptdc_axis_core_merged}"
LVS_TEMPLATE="${MPTDC_PVS_LVS_TEMPLATE:-$OLD_BASE/pvs_lvs/mptdc_axis_core_merged_pg_nonphys_dcells_cdl_ro6_pinfix_noattr_findshorts}"
RESULT_DIR=""
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"

usage() {
  cat <<'USAGE'
Usage:
  01_audit_pvs_templates.sh [options]

Options:
  --drc-template <dir>   GUI-generated PVS DRC run directory.
  --lvs-template <dir>   GUI-generated PVS LVS run directory.
  --result-dir <dir>     Optional directory for reports/manifests.
  --old-base <dir>       Old dryGDS base path used in templates.
  --expected-head <sha>  Require repository HEAD to match this commit.
  -h, --help             Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --drc-template)
      DRC_TEMPLATE="${2:?missing --drc-template value}"
      shift 2
      ;;
    --lvs-template)
      LVS_TEMPLATE="${2:?missing --lvs-template value}"
      shift 2
      ;;
    --result-dir)
      RESULT_DIR="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --result-dir value}")"
      shift 2
      ;;
    --old-base)
      OLD_BASE="${2:?missing --old-base value}"
      shift 2
      ;;
    --expected-head)
      EXPECTED_HEAD_VALUE="${2:?missing --expected-head value}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

cd "$REPO_ROOT"
mptdc_pvs_check_git_head "$REPO_ROOT" "$EXPECTED_HEAD_VALUE"
mptdc_pvs_prepend_known_cadence_bins

REPORT_DIR="${RESULT_DIR:-$PWD}/reports"
MANIFEST_DIR="${RESULT_DIR:-$PWD}/manifests"
mkdir -p "$REPORT_DIR" "$MANIFEST_DIR"
REPORT="$REPORT_DIR/pvs_template_audit.rpt"

{
  echo "# MPTDC PVS Template Audit"
  echo "date: $(date -Iseconds)"
  echo "OLD_BASE=$OLD_BASE"
  echo "DRC_TEMPLATE=$DRC_TEMPLATE"
  echo "LVS_TEMPLATE=$LVS_TEMPLATE"
  echo
  echo "## Tool Paths"
  type -a pvs || true
  type -a pegasus || true
  mptdc_pvs_report_tool_path pvs || true
  mptdc_pvs_report_tool_path pegasus || true
  echo
  echo "## Required Template Files"
  for f in \
    "$DRC_TEMPLATE/run.pvs" \
    "$DRC_TEMPLATE/pvsdrcctl" \
    "$DRC_TEMPLATE/.config.rul" \
    "$DRC_TEMPLATE/.technology.rul" \
    "$LVS_TEMPLATE/run.pvs" \
    "$LVS_TEMPLATE/.config.rul" \
    "$LVS_TEMPLATE/.technology.rul" \
    "$LVS_TEMPLATE/pvslvsctl"
  do
    if [[ -f "$f" ]]; then
      if [[ -s "$f" ]]; then
        echo "PASS $f"
      else
        echo "PASS_EMPTY $f"
      fi
    else
      echo "FAIL $f"
    fi
  done
  echo
  echo "## DRC Template Path Scan"
  grep -RniE 'GDS|gds|DRC|drc|rulesFile|xh018|mptdc_axis_core|metalswitch' \
    "$DRC_TEMPLATE/run.pvs" "$DRC_TEMPLATE/pvsdrcctl" "$DRC_TEMPLATE/.config.rul" "$DRC_TEMPLATE/.technology.rul" \
    2>/dev/null | sed -n '1,260p' || true
  echo
  echo "## LVS Template Path Scan"
  grep -RniE 'GDS|gds|SOURCE|source|verilog|cdl|CDL|mptdc_axis_core|RO_tune6|hcell|HCell|VDD|VSS|LVS_FIND_SHORTS|POWER|GROUND' \
    "$LVS_TEMPLATE/run.pvs" "$LVS_TEMPLATE/.config.rul" "$LVS_TEMPLATE/.technology.rul" "$LVS_TEMPLATE/pvslvsctl" \
    2>/dev/null | sed -n '1,360p' || true
} | tee "$REPORT"

for f in \
  "$DRC_TEMPLATE/run.pvs" \
  "$DRC_TEMPLATE/pvsdrcctl" \
  "$DRC_TEMPLATE/.config.rul" \
  "$DRC_TEMPLATE/.technology.rul" \
  "$LVS_TEMPLATE/run.pvs" \
  "$LVS_TEMPLATE/.config.rul" \
  "$LVS_TEMPLATE/.technology.rul" \
  "$LVS_TEMPLATE/pvslvsctl"
do
  mptdc_pvs_require_existing_file "$f"
done

if grep -q -- '-cell_tree' "$DRC_TEMPLATE/run.pvs"; then
  mptdc_pvs_require_existing_file "$DRC_TEMPLATE/cell_tree.txt"
fi

echo "PVS_TEMPLATE_AUDIT_STATUS=PASS" | tee "$MANIFEST_DIR/pvs_template_audit.status"
