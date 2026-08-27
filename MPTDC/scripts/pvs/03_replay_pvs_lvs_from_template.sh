#!/usr/bin/env bash
# Replay a GUI-generated PVS LVS run on a new merged GDS and filtered source.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=MPTDC/scripts/pvs/lib_pvs_common.sh
source "$SCRIPT_DIR/lib_pvs_common.sh"

REPO_ROOT="$(mptdc_pvs_repo_root)"
DEFAULT_OLD_BASE="/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_falsepath_nfast_risk_235618/drygds_oa_20260702_001608"
OLD_BASE="${MPTDC_PVS_OLD_BASE:-$DEFAULT_OLD_BASE}"
OLD_LVS_RUN="${MPTDC_PVS_LVS_TEMPLATE:-$OLD_BASE/pvs_lvs/mptdc_axis_core_merged_pg_nonphys_dcells_cdl_ro6_pinfix_noattr_findshorts}"
OLD_GDS="${MPTDC_PVS_OLD_GDS:-$OLD_BASE/outputs/mptdc_axis_core_merged_stdcell_ro6.gds}"
OLD_SRC="${MPTDC_PVS_OLD_LVS_SOURCE:-$OLD_BASE/outputs/mptdc_axis_core_pnr_lvs_with_pg_NO_DCELL_MODULES_RO6_PINFIX_NOATTR.v}"
OLD_HCELL="${MPTDC_PVS_OLD_HCELL:-$OLD_BASE/outputs/pvs_hcell_ro6.txt}"
DEFAULT_DCELL_CDL="/data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/cdl/xh018_D_CELLS_JIHD.cdl"

NEW_BASE=""
NEW_LVS_RUN=""
NEW_GDS=""
NEW_SRC=""
NEW_HCELL=""
DCELL_CDL="${MPTDC_PVS_DCELL_CDL:-$DEFAULT_DCELL_CDL}"
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"
DRY_RUN=0
DIAGNOSTIC_ALLOW_BASE_DRC_DEBT=0
DIAGNOSTIC_RO6_BOUNDARY_BLACKBOX=0
BLACKBOX_CELL=""

usage() {
  cat <<'USAGE'
Usage:
  03_replay_pvs_lvs_from_template.sh --prepared-dir <dir> [options]

Options:
  --prepared-dir <dir>      Directory from 00_prepare_pvs_inputs_from_checkpoint.sh.
  --template-run <dir>      Old GUI-generated LVS run directory.
  --new-gds <path>          Override merged GDS path.
  --new-source <path>       Override filtered LVS Verilog source.
  --new-hcell <path>        Override HCell file.
  --dcell-cdl <path>        D_CELLS CDL path.
  --old-base <dir>          Old dryGDS base path to replace.
  --old-gds <path>          Old GDS path to replace.
  --old-source <path>       Old source path to replace.
  --old-hcell <path>        Old HCell path to replace.
  --new-run-dir <dir>       Explicit new PVS LVS run directory.
  --expected-head <sha>     Require repository HEAD to match this commit.
  --diagnostic-allow-base-drc-debt
                            Internal guarded mode: require the diagnostic scope
                            manifest and attributable base DRC, then skip the
                            normal density-DRC prerequisite. Never signoff mode.
  --diagnostic-ro6-boundary-blackbox
                            LVS-only diagnostic mode. Add an explicit
                            lvs_black_box RO_tune6 boundary rule, require its
                            dedicated scope manifest, and skip DRC prerequisites.
                            This proves top-level boundary connectivity only and
                            is never standalone RO or block signoff evidence.
  --dry-run                 Patch and audit templates without launching run.pvs.
  -h, --help                Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prepared-dir)
      NEW_BASE="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --prepared-dir value}")"
      shift 2
      ;;
    --template-run)
      OLD_LVS_RUN="${2:?missing --template-run value}"
      shift 2
      ;;
    --new-gds)
      NEW_GDS="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --new-gds value}")"
      shift 2
      ;;
    --new-source)
      NEW_SRC="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --new-source value}")"
      shift 2
      ;;
    --new-hcell)
      NEW_HCELL="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --new-hcell value}")"
      shift 2
      ;;
    --dcell-cdl)
      DCELL_CDL="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --dcell-cdl value}")"
      shift 2
      ;;
    --old-base)
      OLD_BASE="${2:?missing --old-base value}"
      shift 2
      ;;
    --old-gds)
      OLD_GDS="${2:?missing --old-gds value}"
      shift 2
      ;;
    --old-source)
      OLD_SRC="${2:?missing --old-source value}"
      shift 2
      ;;
    --old-hcell)
      OLD_HCELL="${2:?missing --old-hcell value}"
      shift 2
      ;;
    --new-run-dir)
      NEW_LVS_RUN="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --new-run-dir value}")"
      shift 2
      ;;
    --expected-head)
      EXPECTED_HEAD_VALUE="${2:?missing --expected-head value}"
      shift 2
      ;;
    --diagnostic-allow-base-drc-debt)
      DIAGNOSTIC_ALLOW_BASE_DRC_DEBT=1
      shift
      ;;
    --diagnostic-ro6-boundary-blackbox)
      DIAGNOSTIC_RO6_BOUNDARY_BLACKBOX=1
      BLACKBOX_CELL=RO_tune6
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
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

report_value() {
  local report="$1"
  local key="$2"
  sed -n "s/^${key}=//p" "$report" 2>/dev/null | tail -1
}

require_diagnostic_scope() {
  local scope="$NEW_BASE/manifests/pvs_diagnostic_scope.rpt"
  mptdc_pvs_require_file "$scope"
  grep -qx 'PVS_RUN_CLASS=DIAGNOSTIC_NOT_SIGNOFF' "$scope" || \
    mptdc_pvs_die "diagnostic LVS scope has invalid PVS_RUN_CLASS: $scope"
  grep -qx 'DIAGNOSTIC_SCOPE=BASE_DRC_PLUS_LVS' "$scope" || \
    mptdc_pvs_die "diagnostic LVS scope is not BASE_DRC_PLUS_LVS: $scope"
  grep -qx 'DENSITY_DRC_STATUS=NOT_RUN_BY_SCOPE' "$scope" || \
    mptdc_pvs_die "diagnostic LVS scope did not explicitly exclude density DRC: $scope"
  grep -qx 'SIGNOFF_ELIGIBLE=NO' "$scope" || \
    mptdc_pvs_die "diagnostic LVS scope is not marked ineligible for signoff: $scope"
  grep -qx 'DEFERRED_INNOVUS_DRC_COUNT=1' "$scope" || \
    mptdc_pvs_die "diagnostic LVS scope does not carry exactly one deferred Innovus DRC: $scope"
  grep -qx 'DEFERRED_INNOVUS_DRC_RULE=MET1_MINIMUM_AREA' "$scope" || \
    mptdc_pvs_die "diagnostic LVS scope has an unexpected deferred rule: $scope"
}

require_attributable_base_drc() {
  local status_report="$NEW_BASE/reports/pvs_drc_base_status.rpt"
  local rule_report="$NEW_BASE/reports/pvs_drc_base_nonzero_rules.tsv"
  local status gate variant pvs_rc primary expanded nonzero reported_rules reported_hash
  local actual_hash actual_rows

  mptdc_pvs_require_file "$status_report"
  mptdc_pvs_require_file "$rule_report"
  status="$(report_value "$status_report" STATUS)"
  gate="$(report_value "$status_report" PVS_DRC_STATUS)"
  variant="$(report_value "$status_report" PVS_DRC_VARIANT)"
  pvs_rc="$(report_value "$status_report" PVS_RC)"
  primary="$(report_value "$status_report" DRC_TOTAL_PRIMARY)"
  expanded="$(report_value "$status_report" DRC_TOTAL_EXPANDED)"
  nonzero="$(report_value "$status_report" NONZERO_RULE_COUNT)"
  reported_rules="$(report_value "$status_report" NONZERO_RULE_REPORT)"
  reported_hash="$(report_value "$status_report" NONZERO_RULE_REPORT_SHA256)"

  [[ "$variant" == BASE && "$pvs_rc" == 0 ]] || \
    mptdc_pvs_die "diagnostic LVS requires attributable BASE DRC with PVS_RC=0: $status_report"
  [[ "$status" == "$gate" && ( "$status" == PASS || "$status" == FAIL ) ]] || \
    mptdc_pvs_die "diagnostic LVS base DRC status is inconsistent: $status_report"
  [[ "$primary" =~ ^[0-9]+$ && "$expanded" =~ ^[0-9]+$ && "$nonzero" =~ ^[0-9]+$ ]] || \
    mptdc_pvs_die "diagnostic LVS base DRC totals are not numeric: $status_report"
  [[ "$reported_rules" == "$rule_report" ]] || \
    mptdc_pvs_die "diagnostic LVS rule inventory path is not canonical: $reported_rules"
  actual_hash="$(mptdc_pvs_sha256 "$rule_report")"
  [[ "$reported_hash" == "$actual_hash" ]] || \
    mptdc_pvs_die "diagnostic LVS rule inventory hash mismatch: $rule_report"
  actual_rows="$(awk -F '\t' 'NR > 1 && NF >= 3 {count++} END {print count + 0}' "$rule_report")"
  [[ "$actual_rows" == "$nonzero" ]] || \
    mptdc_pvs_die "diagnostic LVS rule inventory count mismatch: report=$nonzero rows=$actual_rows"

  if [[ "$status" == PASS ]]; then
    [[ "$primary" == 0 && "$expanded" == 0 && "$nonzero" == 0 ]] || \
      mptdc_pvs_die "diagnostic LVS base DRC PASS has nonzero totals: $status_report"
  else
    [[ "$primary" != 0 || "$expanded" != 0 ]] || \
      mptdc_pvs_die "diagnostic LVS base DRC FAIL has zero totals: $status_report"
    [[ "$nonzero" != 0 ]] || \
      mptdc_pvs_die "diagnostic LVS base DRC FAIL has no nonzero rule inventory: $status_report"
  fi
}

require_ro6_boundary_blackbox_scope() {
  local scope="$NEW_BASE/manifests/pvs_ro6_boundary_blackbox_scope.rpt"
  local hcell_entry_count wrapper_count

  mptdc_pvs_require_file "$scope"
  grep -qx 'PVS_RUN_CLASS=DIAGNOSTIC_RO6_BOUNDARY_BLACKBOX' "$scope" || \
    mptdc_pvs_die "RO6 boundary scope has invalid PVS_RUN_CLASS: $scope"
  grep -qx 'DIAGNOSTIC_SCOPE=LVS_ONLY_RO6_BOUNDARY' "$scope" || \
    mptdc_pvs_die "RO6 boundary scope is not LVS_ONLY_RO6_BOUNDARY: $scope"
  grep -qx 'BLACKBOX_CELL=RO_tune6' "$scope" || \
    mptdc_pvs_die "RO6 boundary scope has an unexpected blackbox cell: $scope"
  grep -qx 'RO6_BUS_PIN_NORMALIZATION=EXACT_SAME_INDEX_SCALAR_ANGLE_PORTS' "$scope" || \
    mptdc_pvs_die "RO6 boundary scope has an unexpected bus-pin policy: $scope"
  grep -qx 'VERILOG_GLOBAL_SIGNAL_PORT_POLICY=DO_NOT_PROMOTE' "$scope" || \
    mptdc_pvs_die "RO6 boundary scope has an unexpected global-signal policy: $scope"
  grep -qx 'RO6_STANDALONE_LVS_REQUIRED=YES' "$scope" || \
    mptdc_pvs_die "RO6 boundary scope does not require standalone macro LVS: $scope"
  grep -qx 'SIGNOFF_ELIGIBLE=NO' "$scope" || \
    mptdc_pvs_die "RO6 boundary scope is not marked ineligible for signoff: $scope"

  hcell_entry_count="$(awk 'NF && $1 !~ /^#/ {count++; if ($1 == "RO_tune6" && $2 == "RO_tune6" && NF == 2) exact++} END {print count ":" exact + 0}' "$NEW_HCELL")"
  [[ "$hcell_entry_count" == "1:1" ]] || \
    mptdc_pvs_die "RO6 boundary mode requires exactly one 'RO_tune6 RO_tune6' HCell mapping"

  wrapper_count="$(grep -Ec '^[[:space:]]*module[[:space:]]+RO_tune6[[:space:]]*[(]' "$NEW_SRC" 2>/dev/null || true)"
  [[ "$wrapper_count" == 1 ]] || \
    mptdc_pvs_die "RO6 boundary mode requires exactly one RO_tune6 source wrapper"
  for declaration in \
    'inout[[:space:]]+VDD[[:space:]]*;' \
    'inout[[:space:]]+VSS[[:space:]]*;' \
    'inout[[:space:]]+rstb[[:space:]]*;'; do
    grep -Eq "$declaration" "$NEW_SRC" || \
      mptdc_pvs_die "RO6 source wrapper is missing expected declaration: $declaration"
  done
  local bus bit declaration_count connection_count
  for bus in code S; do
    for bit in {0..7}; do
      declaration_count="$({ grep -Eo "inout[[:space:]]+\\\\${bus}<${bit}>[[:space:]]*;" "$NEW_SRC" 2>/dev/null || true; } | wc -l | tr -d ' ')"
      [[ "$declaration_count" == 1 ]] || \
        mptdc_pvs_die "RO6 source wrapper requires one scalar ${bus}<${bit}> declaration"
      connection_count="$({ grep -Eo "\\.\\\\${bus}<${bit}>[[:space:]]*\\(" "$NEW_SRC" 2>/dev/null || true; } | wc -l | tr -d ' ')"
      [[ "$connection_count" == 2 ]] || \
        mptdc_pvs_die "RO6 source requires two same-index ${bus}<${bit}> instance connections"
    done
  done
  ! grep -Eq 'inout[[:space:]]+\[7:0\][[:space:]]+(code|S)' "$NEW_SRC" || \
    mptdc_pvs_die "RO6 boundary source still contains a vector wrapper declaration"
}

write_ro6_boundary_blackbox_gate() {
  local report="$NEW_BASE/reports/pvs_lvs_ro6_boundary_blackbox_status.rpt"
  local cls_file_count=0 cls_file="" blackboxed_count=MISSING rule_count=0
  local bus_rule_count=0 bus_rule_effective_value=ABSENT bus_rule_status=FAIL
  local global_rule_count=0 global_rule_status=FAIL
  local ro6_initial_pins=MISSING ro6_compare_pins=MISSING ro6_cell_status=MISSING
  local ro6_cell_match_status=FAIL angle_bus_missing_count=MISSING
  local square_bus_missing_count=MISSING tie1_missing_count=MISSING
  local tie1_net_mismatch_count=MISSING tie1_instance_cascade_count=MISSING
  local layout_open_net_count=MISSING shorts_opens_count=MISSING
  local mismatched_net_count=MISSING mismatched_instance_count=MISSING
  local vdd_open_section_count=MISSING vss_open_section_count=MISSING
  local rule_status=FAIL application_status=FAIL gate_rc=1

  if [[ -d "$NEW_LVS_RUN" ]]; then
    cls_file_count="$(find "$NEW_LVS_RUN" -type f -name '*.cls' 2>/dev/null | wc -l | tr -d ' ')"
  fi
  if [[ "$cls_file_count" == 1 ]]; then
    cls_file="$(find "$NEW_LVS_RUN" -type f -name '*.cls' -print -quit)"
    blackboxed_count="$(awk -F '|' '/Cells that have been blackboxed/ {value=$2; gsub(/[[:space:]]/, "", value); print value; exit}' "$cls_file")"
    [[ -n "$blackboxed_count" ]] || blackboxed_count=MISSING
    rule_count="$(grep -Eic '^[[:space:]]*lvs_black_box[[:space:]].*RO_tune6' "$cls_file" 2>/dev/null || true)"
    bus_rule_count="$(awk 'tolower($1) == "lvs_verilog_bus_map_by_position" {count++} END {print count+0}' "$cls_file")"
    if [[ "$bus_rule_count" -gt 0 ]]; then
      bus_rule_effective_value="$(awk 'tolower($1) == "lvs_verilog_bus_map_by_position" {print toupper($2); exit}' "$cls_file")"
      [[ -n "$bus_rule_effective_value" ]] || bus_rule_effective_value=MISSING
    fi
    global_rule_count="$(grep -Eic '^[[:space:]]*lvs_global_sigs_are_ports[[:space:]]+no([[:space:]]|$)' "$cls_file" 2>/dev/null || true)"
    ro6_initial_pins="$(awk -F '|' '$1 ~ /^RO_tune6[[:space:]]*$/ {value=$2; gsub(/[[:space:]]/, "", value); print value; exit}' "$cls_file")"
    ro6_compare_pins="$(awk -F '|' '$1 ~ /^RO_tune6[[:space:]]*$/ {value=$3; gsub(/[[:space:]]/, "", value); print value; exit}' "$cls_file")"
    ro6_cell_status="$(awk -F '|' '$1 ~ /^RO_tune6[[:space:]]*$/ {value=$4; gsub(/[[:space:]]/, "", value); print tolower(value); exit}' "$cls_file")"
    [[ -n "$ro6_initial_pins" ]] || ro6_initial_pins=MISSING
    [[ -n "$ro6_compare_pins" ]] || ro6_compare_pins=MISSING
    [[ -n "$ro6_cell_status" ]] || ro6_cell_status=MISSING
    angle_bus_missing_count="$(grep -Ec 'Layout Pin: (S|code)<[0-7]>[[:space:]]*\| Schematic Pin: \*\* missing pin \*\*' "$cls_file" 2>/dev/null || true)"
    square_bus_missing_count="$(grep -Ec 'Layout Pin: \*\* missing pin \*\*[[:space:]]*\| Schematic Pin: (S|code)\[[0-7]\]' "$cls_file" 2>/dev/null || true)"
    tie1_missing_count="$(grep -Ec '^tie1[[:space:]]*\|[[:space:]]*\*\* missing pin \*\*' "$cls_file" 2>/dev/null || true)"
    tie1_net_mismatch_count="$(grep -Ec 'Schematic Net:[[:space:]]+tie1([[:space:]]|$)' "$cls_file" 2>/dev/null || true)"
    tie1_instance_cascade_count="$(grep -Ec '\|[[:space:]]+G:[[:space:]]+tie1([[:space:]]|$)' "$cls_file" 2>/dev/null || true)"
    layout_open_net_count="$(grep -Ec '\|[[:space:]]+OPEN[[:space:]]*$' "$cls_file" 2>/dev/null || true)"
    shorts_opens_count="$(grep -Ec '\(sao[[:space:]]+[0-9]+\)' "$cls_file" 2>/dev/null || true)"
    mismatched_net_count="$(grep -Ec '\(mn[[:space:]]+[0-9]+\)' "$cls_file" 2>/dev/null || true)"
    mismatched_instance_count="$(grep -Ec '\(mi[[:space:]]+[0-9]+\)' "$cls_file" 2>/dev/null || true)"
    vdd_open_section_count="$(grep -Ec 'Layout Pin: VDD[[:space:]]*\| Schematic Pin: VDD' "$cls_file" 2>/dev/null || true)"
    vss_open_section_count="$(grep -Ec 'Layout Pin: VSS[[:space:]]*\| Schematic Pin: VSS' "$cls_file" 2>/dev/null || true)"
  fi

  if [[ "$rule_count" -ge 1 ]]; then
    rule_status=PASS
  fi
  if [[ "$blackboxed_count" =~ ^[0-9]+$ && "$blackboxed_count" -ge 1 ]]; then
    application_status=PASS
  fi
  if [[ "$bus_rule_count" == 0 || \
        ("$bus_rule_count" == 1 && "$bus_rule_effective_value" == NO) ]]; then
    bus_rule_status=NOT_USED_EXACT_SCALAR_SOURCE
  fi
  if [[ "$global_rule_count" -ge 1 ]]; then
    global_rule_status=PASS
  fi
  if [[ "$ro6_initial_pins" == 19:19 && "$ro6_compare_pins" == 19:19 && \
        "$ro6_cell_status" == match ]]; then
    ro6_cell_match_status=PASS
  fi
  if [[ "$rule_status" == PASS && "$application_status" == PASS && \
        "$bus_rule_status" == NOT_USED_EXACT_SCALAR_SOURCE && "$global_rule_status" == PASS && \
        "$ro6_cell_match_status" == PASS ]]; then
    gate_rc=0
  fi

  {
    echo "PVS_LVS_BOUNDARY_MODE=DIAGNOSTIC_RO6_BOUNDARY_BLACKBOX"
    echo "LVS_BLACKBOX_CELL=RO_tune6"
    echo "LVS_BLACKBOX_CLS_FILE_COUNT=$cls_file_count"
    echo "LVS_BLACKBOX_CLS_FILE=${cls_file:-MISSING}"
    echo "LVS_BLACKBOX_RULE_COUNT=$rule_count"
    echo "LVS_BLACKBOX_RULE_STATUS=$rule_status"
    echo "LVS_BUS_PIN_MAP_RULE_COUNT=$bus_rule_count"
    echo "LVS_BUS_PIN_MAP_EFFECTIVE_VALUE=$bus_rule_effective_value"
    echo "LVS_BUS_PIN_MAP_RULE_STATUS=$bus_rule_status"
    echo "LVS_GLOBAL_SIGNAL_PORT_RULE_COUNT=$global_rule_count"
    echo "LVS_GLOBAL_SIGNAL_PORT_RULE_STATUS=$global_rule_status"
    echo "LVS_BLACKBOXED_CELL_COUNT=$blackboxed_count"
    echo "LVS_BLACKBOX_APPLICATION_STATUS=$application_status"
    echo "RO6_BLACKBOX_INITIAL_PINS=$ro6_initial_pins"
    echo "RO6_BLACKBOX_COMPARE_PINS=$ro6_compare_pins"
    echo "RO6_BLACKBOX_CELL_STATUS=$ro6_cell_status"
    echo "RO6_BLACKBOX_CELL_MATCH_STATUS=$ro6_cell_match_status"
    echo "RO6_ANGLE_BUS_MISSING_PIN_COUNT=$angle_bus_missing_count"
    echo "RO6_SQUARE_BUS_MISSING_PIN_COUNT=$square_bus_missing_count"
    echo "TIE1_UNMATCHED_PIN_COUNT=$tie1_missing_count"
    echo "TIE1_MISMATCHED_NET_COUNT=$tie1_net_mismatch_count"
    echo "TIE1_MISMATCHED_INSTANCE_CASCADE_COUNT=$tie1_instance_cascade_count"
    echo "LAYOUT_OPEN_NET_COUNT=$layout_open_net_count"
    echo "SHORTS_OPENS_RECORD_COUNT=$shorts_opens_count"
    echo "MISMATCHED_NET_RECORD_COUNT=$mismatched_net_count"
    echo "MISMATCHED_INSTANCE_RECORD_COUNT=$mismatched_instance_count"
    echo "VDD_OPEN_SECTION_COUNT=$vdd_open_section_count"
    echo "VSS_OPEN_SECTION_COUNT=$vss_open_section_count"
    echo "RO6_STANDALONE_LVS_REQUIRED=YES"
    echo "SIGNOFF_ELIGIBLE=NO"
  } | tee "$report"
  return "$gate_rc"
}

[[ -n "$NEW_BASE" ]] || { usage >&2; mptdc_pvs_die "--prepared-dir is required"; }
if [[ "$DIAGNOSTIC_ALLOW_BASE_DRC_DEBT" == 1 && "$DIAGNOSTIC_RO6_BOUNDARY_BLACKBOX" == 1 ]]; then
  mptdc_pvs_die "diagnostic base-DRC debt and RO6 boundary-blackbox modes are mutually exclusive"
fi
NEW_GDS="${NEW_GDS:-$NEW_BASE/outputs/mptdc_axis_core_merged_stdcell_ro6.gds}"
NEW_SRC="${NEW_SRC:-$NEW_BASE/outputs/mptdc_axis_core_pnr_lvs_with_pg_NO_DCELL_MODULES_RO6_PINFIX_NOATTR_CLEAN.v}"
NEW_HCELL="${NEW_HCELL:-$NEW_BASE/outputs/pvs_hcell_ro6.txt}"
NEW_LVS_RUN="${NEW_LVS_RUN:-$NEW_BASE/pvs_lvs/mptdc_axis_core_merged_pg_nonphys_dcells_cdl_ro6_pinfix_noattr_clean_findshorts_script}"

cd "$REPO_ROOT"
mptdc_pvs_check_git_head "$REPO_ROOT" "$EXPECTED_HEAD_VALUE"
mptdc_pvs_require_clean_tracked_tree "$REPO_ROOT"
mptdc_pvs_require_dir "$NEW_BASE"
mptdc_pvs_require_file "$NEW_GDS"
mptdc_pvs_require_file "$NEW_SRC"
mptdc_pvs_require_file "$NEW_HCELL"
mptdc_pvs_require_file "$DCELL_CDL"
for f in "$OLD_LVS_RUN/run.pvs" "$OLD_LVS_RUN/.config.rul" "$OLD_LVS_RUN/.technology.rul" "$OLD_LVS_RUN/pvslvsctl"; do
  mptdc_pvs_require_existing_file "$f"
done
if grep -q -- '-cell_tree' "$OLD_LVS_RUN/run.pvs"; then
  mptdc_pvs_require_existing_file "$OLD_LVS_RUN/cell_tree.txt"
fi

if [[ "$DIAGNOSTIC_ALLOW_BASE_DRC_DEBT" == 1 ]]; then
  require_diagnostic_scope
  require_attributable_base_drc
  [[ ! -e "$NEW_BASE/reports/pvs_drc_density_status.rpt" ]] || \
    mptdc_pvs_die "diagnostic base-DRC plus LVS scope unexpectedly contains density DRC evidence"
fi
if [[ "$DIAGNOSTIC_RO6_BOUNDARY_BLACKBOX" == 1 ]]; then
  require_ro6_boundary_blackbox_scope
fi

if [[ -e "$NEW_LVS_RUN" ]]; then
  mptdc_pvs_die "new LVS run directory already exists: $NEW_LVS_RUN"
fi

mkdir -p "$NEW_LVS_RUN" "$NEW_BASE/reports" "$NEW_BASE/manifests"
cp -p "$OLD_LVS_RUN/run.pvs" "$NEW_LVS_RUN/run.pvs"
cp -p "$OLD_LVS_RUN/pvslvsctl" "$NEW_LVS_RUN/pvslvsctl"
cp -p "$OLD_LVS_RUN/.config.rul" "$NEW_LVS_RUN/.config.rul"
cp -p "$OLD_LVS_RUN/.technology.rul" "$NEW_LVS_RUN/.technology.rul"
[[ -f "$OLD_LVS_RUN/cell_tree.txt" ]] && cp -p "$OLD_LVS_RUN/cell_tree.txt" "$NEW_LVS_RUN/cell_tree.txt"
[[ -f "$OLD_LVS_RUN/.preset.autosave" ]] && cp -p "$OLD_LVS_RUN/.preset.autosave" "$NEW_LVS_RUN/.preset.autosave"

PATCH_FILES=("$NEW_LVS_RUN/run.pvs" "$NEW_LVS_RUN/pvslvsctl" "$NEW_LVS_RUN/.config.rul" "$NEW_LVS_RUN/.technology.rul")
[[ -f "$NEW_LVS_RUN/cell_tree.txt" ]] && PATCH_FILES+=("$NEW_LVS_RUN/cell_tree.txt")
[[ -f "$NEW_LVS_RUN/.preset.autosave" ]] && PATCH_FILES+=("$NEW_LVS_RUN/.preset.autosave")

for f in "${PATCH_FILES[@]}"; do
  mptdc_pvs_patch_file_paths "$f" \
    "$OLD_GDS=$NEW_GDS" \
    "$OLD_SRC=$NEW_SRC" \
    "$OLD_HCELL=$NEW_HCELL" \
    "$OLD_LVS_RUN=$NEW_LVS_RUN" \
    "$OLD_BASE=$NEW_BASE" \
    "$DEFAULT_DCELL_CDL=$DCELL_CDL"
done

if [[ "$DIAGNOSTIC_RO6_BOUNDARY_BLACKBOX" == 1 ]]; then
  for rule in lvs_black_box lvs_verilog_bus_map_by_position lvs_global_sigs_are_ports; do
    if grep -Eq "^[[:space:]]*${rule}([[:space:]]|$)" "$NEW_LVS_RUN/pvslvsctl"; then
      mptdc_pvs_die "template already contains $rule; refusing ambiguous boundary control"
    fi
  done
  {
    echo
    echo "// MPTDC diagnostic digital-top boundary comparison; not standalone RO LVS."
    echo "lvs_black_box $BLACKBOX_CELL;"
    echo "lvs_global_sigs_are_ports no;"
  } >> "$NEW_LVS_RUN/pvslvsctl"
fi

mptdc_pvs_fail_if_contains_old_path "LVS template run" "$OLD_LVS_RUN" "${PATCH_FILES[@]}"
mptdc_pvs_fail_if_contains_old_path "LVS old base" "$OLD_BASE" "${PATCH_FILES[@]}"
mptdc_pvs_fail_if_contains_old_path "LVS old GDS" "$OLD_GDS" "${PATCH_FILES[@]}"
mptdc_pvs_fail_if_contains_old_path "LVS old source" "$OLD_SRC" "${PATCH_FILES[@]}"
mptdc_pvs_fail_if_contains_old_path "LVS old HCell" "$OLD_HCELL" "${PATCH_FILES[@]}"
chmod +x "$NEW_LVS_RUN/run.pvs"

{
  echo "# MPTDC PVS LVS Replay Manifest"
  echo "date: $(date -Iseconds)"
  echo "old_lvs_run: $OLD_LVS_RUN"
  echo "new_lvs_run: $NEW_LVS_RUN"
  echo "old_base: $OLD_BASE"
  echo "new_base: $NEW_BASE"
  echo "new_gds: $NEW_GDS"
  echo "new_source: $NEW_SRC"
  echo "new_hcell: $NEW_HCELL"
  echo "dcell_cdl: $DCELL_CDL"
  echo "diagnostic_allow_base_drc_debt: $DIAGNOSTIC_ALLOW_BASE_DRC_DEBT"
  echo "diagnostic_ro6_boundary_blackbox: $DIAGNOSTIC_RO6_BOUNDARY_BLACKBOX"
  echo "blackbox_cell: ${BLACKBOX_CELL:-NONE}"
  echo "ro6_bus_pin_normalization: $([[ "$DIAGNOSTIC_RO6_BOUNDARY_BLACKBOX" == 1 ]] && echo EXACT_SAME_INDEX_SCALAR_ANGLE_PORTS || echo NONE)"
  echo "verilog_global_signal_port_policy: $([[ "$DIAGNOSTIC_RO6_BOUNDARY_BLACKBOX" == 1 ]] && echo DO_NOT_PROMOTE || echo DEFAULT)"
  echo "dry_run: $DRY_RUN"
} | tee "$NEW_BASE/manifests/pvs_lvs_replay_manifest.txt"

{
  echo "===== Patched run.pvs ====="
  sed -n '1,180p' "$NEW_LVS_RUN/run.pvs"
  echo
  echo "===== Patched LVS config scan ====="
  grep -RniE 'mptdc_axis_core_merged_stdcell_ro6|NO_DCELL|RO6|RO_tune6|xh018_D_CELLS|LVS_FIND_SHORTS|VDD|VSS|hcell|HCell|black_box|BLACK_BOX|bus_map|global_sigs|SOURCE|source|verilog|cdl|CDL' \
    "$NEW_LVS_RUN/run.pvs" "$NEW_LVS_RUN/pvslvsctl" "$NEW_LVS_RUN/.config.rul" "$NEW_LVS_RUN/.technology.rul" | sed -n '1,420p' || true
} | tee "$NEW_BASE/reports/pvs_lvs_replay_preflight.rpt"

if [[ "$DRY_RUN" == "1" ]]; then
  echo "PVS_LVS_REPLAY_STATUS=DRY_RUN_READY" | tee "$NEW_BASE/reports/pvs_lvs_status.rpt"
  exit 0
fi

if [[ "$DIAGNOSTIC_ALLOW_BASE_DRC_DEBT" != 1 && "$DIAGNOSTIC_RO6_BOUNDARY_BLACKBOX" != 1 ]]; then
  for variant in base density; do
    drc_status="$NEW_BASE/reports/pvs_drc_${variant}_status.rpt"
    mptdc_pvs_require_file "$drc_status"
    grep -qx 'PVS_DRC_STATUS=PASS' "$drc_status" || \
      mptdc_pvs_die "LVS blocked because $variant DRC is not PASS: $drc_status"
  done
fi

mptdc_pvs_prepend_known_cadence_bins
mptdc_pvs_forbid_bare_linux_lvm_pvs
set +e
(
  cd "$NEW_LVS_RUN"
  bash ./run.pvs
) 2>&1 | tee "$NEW_LVS_RUN/pvs_lvs_replay.stdout"
PVS_RC=${PIPESTATUS[0]}
set -e
echo "PVS_LVS_RC=$PVS_RC" | tee "$NEW_BASE/reports/pvs_lvs_tool_status.rpt"

grep -RIna --binary-files=without-match \
  --exclude='*.rdb' \
  --exclude='*.ecdb' \
  --exclude='netlistLAYOUT' \
  --exclude='netlistSOURCE' \
  --exclude-dir='REPORTDB' \
  -E 'LVS_FIND_SHORTS|Run Result|Run Summary|short|SHORT|Different labels|VDD_LEFT|VDD_RIGHT|VSS_LEFT|VSS_RIGHT|inputting verilog|inputting.*cdl|RO_tune6|mismatch|match|abort|fatal|error|truncated' \
  "$NEW_LVS_RUN" | head -2000 | tee "$NEW_BASE/reports/pvs_lvs_result_scan.txt" || true

find "$NEW_LVS_RUN" -path '*/SHORTSDB/rule.id' -type f -exec cat {} \; \
  | tee "$NEW_BASE/reports/pvs_lvs_SHORTSDB_rule_id.txt" || true

HASH_MANIFEST="$NEW_BASE/manifests/pvs_input_hashes.rpt"
GATE_REPORT="$NEW_BASE/reports/pvs_lvs_status.rpt"
INVENTORY="$NEW_BASE/reports/pvs_lvs_evidence_inventory.tsv"
set +e
python3 "$SCRIPT_DIR/06_gate_pvs_lvs.py" \
  --run-dir "$NEW_LVS_RUN" \
  --tool-rc "$PVS_RC" \
  --gds "$NEW_GDS" \
  --source "$NEW_SRC" \
  --cdl "$DCELL_CDL" \
  --hcell "$NEW_HCELL" \
  --hash-manifest "$HASH_MANIFEST" \
  --layout-top mptdc_axis_core \
  --source-top mptdc_axis_core \
  --out "$GATE_REPORT" \
  --inventory "$INVENTORY"
GATE_RC=$?
set -e

BLACKBOX_GATE_RC=0
if [[ "$DIAGNOSTIC_RO6_BOUNDARY_BLACKBOX" == 1 ]]; then
  set +e
  write_ro6_boundary_blackbox_gate
  BLACKBOX_GATE_RC=$?
  set -e
fi

if [[ "$PVS_RC" -ne 0 ]]; then
  exit "$PVS_RC"
fi
if [[ "$GATE_RC" -ne 0 ]]; then
  exit "$GATE_RC"
fi
exit "$BLACKBOX_GATE_RC"
