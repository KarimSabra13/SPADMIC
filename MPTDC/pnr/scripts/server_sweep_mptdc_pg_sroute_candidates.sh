#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

DEFAULT_INNOVUS_WORK="/sim/ksabra/SPADMIC_work/innovus"

SOURCE_CHECKPOINT=""
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"
BASE_RUN_ID=""
INNOVUS_WORK_VALUE="${MPTDC_INNOVUS_WORK:-$DEFAULT_INNOVUS_WORK}"

usage() {
  cat <<'USAGE'
Usage:
  server_sweep_mptdc_pg_sroute_candidates.sh --checkpoint <enc.dat> [options]

Options:
  --checkpoint <path>    Clean source Innovus checkpoint data directory.
                         Use the pre-sroute 03_cts.enc.dat checkpoint, not a
                         failed postplace_sroute checkpoint.
  --base-run-id <id>     Prefix for per-candidate repair run IDs.
  --expected-head <sha>  Require repository HEAD to match this commit.
  --innovus-work <path>  Innovus run root. Default: /sim/ksabra/SPADMIC_work/innovus
  -h, --help             Show this help.

Runs each PG sroute candidate in a fresh Innovus restore from the same source
checkpoint. This avoids cumulative sroute damage and writes one CSV summary.
The strict_pg_clean column is PASS only when raw VDD/VSS special connectivity
is clean and DRC shorts are zero. RO-filtered results are diagnostic only.
USAGE
}

abs_path() {
  local path="$1"
  case "$path" in
    /*) printf '%s\n' "$path" ;;
    *) printf '%s/%s\n' "$REPO_ROOT" "$path" ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --checkpoint)
      SOURCE_CHECKPOINT="$(abs_path "${2:?missing --checkpoint value}")"
      shift 2
      ;;
    --base-run-id)
      BASE_RUN_ID="${2:?missing --base-run-id value}"
      shift 2
      ;;
    --expected-head)
      EXPECTED_HEAD_VALUE="${2:?missing --expected-head value}"
      shift 2
      ;;
    --innovus-work)
      INNOVUS_WORK_VALUE="$(abs_path "${2:?missing --innovus-work value}")"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$SOURCE_CHECKPOINT" ]]; then
  echo "ERROR: --checkpoint is required" >&2
  usage >&2
  exit 2
fi

if [[ -z "$BASE_RUN_ID" ]]; then
  BASE_RUN_ID="mptdc_pg_sroute_isolated_$(date +%Y%m%d_%H%M%S)"
fi

cd "$REPO_ROOT"

ACTUAL_HEAD="$(git rev-parse HEAD)"
echo "REPO_ROOT=$REPO_ROOT"
echo "BRANCH=$(git rev-parse --abbrev-ref HEAD)"
echo "ACTUAL_HEAD=$ACTUAL_HEAD"
if [[ -n "$EXPECTED_HEAD_VALUE" ]]; then
  echo "EXPECTED_HEAD=$EXPECTED_HEAD_VALUE"
  test "$ACTUAL_HEAD" = "$EXPECTED_HEAD_VALUE"
fi

test -d "$SOURCE_CHECKPOINT"
case "$(basename "$SOURCE_CHECKPOINT")" in
  03b_postplace_pre_route_sroute_failed.enc.dat|03b_postplace_pre_route_sroute_failed.enc)
    echo "ERROR: refusing contaminated failed-sroute checkpoint: $SOURCE_CHECKPOINT" >&2
    echo "Use the clean pre-sroute checkpoint, normally:" >&2
    echo "  <run>/checkpoints/03_cts.enc.dat" >&2
    exit 3
    ;;
esac
mkdir -p "$INNOVUS_WORK_VALUE"

SUMMARY_CSV="$INNOVUS_WORK_VALUE/${BASE_RUN_ID}_summary.csv"
SUMMARY_MD="$INNOVUS_WORK_VALUE/${BASE_RUN_ID}_summary.md"

printf 'candidate,run_id,rc,strict_pg_clean,strict_pg_reasons,drc,shorts,regular_bad,special_bad,special_raw_bad,special_filter_status,special_filtered_ro,special_non_ro,unrouted,route_gate_pass,checkpoint,status_report\n' > "$SUMMARY_CSV"

cat > "$SUMMARY_MD" <<EOF
# MPTDC PG Isolated SRoute Candidate Sweep

- date: $(date --iso-8601=seconds)
- repo: $REPO_ROOT
- branch: $(git rev-parse --abbrev-ref HEAD)
- head: $ACTUAL_HEAD
- source_checkpoint: $SOURCE_CHECKPOINT
- innovus_work: $INNOVUS_WORK_VALUE

Each candidate restores the same clean checkpoint. Results are not cumulative.
Acceptance is intentionally strict: strict_pg_clean=PASS requires
special_raw_bad=0, special_bad=0, and shorts=0. A filtered RO-only result
is not accepted as clean unless the raw special report is also clean.

EOF

read -r -d '' CANDIDATES <<'EOF' || true
corepin_ring|NONE|sroute -connect {corePin} -nets {VDD VSS} -corePinTarget {ring stripe} -allowLayerChange 1
corepin_first_after_row_end|NONE|sroute -connect {corePin} -nets {VDD VSS} -corePinTarget firstAfterRowEnd -allowLayerChange 1
core_block_ring|NONE|sroute -connect {corePin blockPin} -nets {VDD VSS} -blockPin all -blockPinTarget {ring stripe} -corePinTarget {ring stripe} -allowLayerChange 1
core_block_pad_ring|NONE|sroute -connect {corePin blockPin padPin} -nets {VDD VSS} -blockPin all -blockPinTarget {ring stripe} -corePinTarget {ring stripe} -padPinTarget {ring stripe} -allowLayerChange 1
core_block_via_closest|setSrouteMode -viaThruToClosestRing true|sroute -connect {corePin blockPin} -nets {VDD VSS} -blockPin all -blockPinTarget {ring stripe} -corePinTarget {ring stripe} -allowLayerChange 1
core_block_connect_broken|setSrouteMode -connectBrokenCorePin true|sroute -connect {corePin blockPin} -nets {VDD VSS} -blockPin all -blockPinTarget {ring stripe} -corePinTarget {ring stripe} -allowLayerChange 1
core_block_pin_width|setSrouteMode -blockPinRouteWithPinWidth true|sroute -connect {corePin blockPin} -nets {VDD VSS} -blockPin all -blockPinTarget {ring stripe} -corePinTarget {ring stripe} -allowLayerChange 1
core_block_pin_corners|setSrouteMode -blockPinConnectRingPinCorners true|sroute -connect {corePin blockPin} -nets {VDD VSS} -blockPin all -blockPinTarget {ring stripe} -corePinTarget {ring stripe} -allowLayerChange 1
core_block_target_80|setSrouteMode -targetSearchDistance 80|sroute -connect {corePin blockPin} -nets {VDD VSS} -blockPin all -blockPinTarget {ring stripe} -corePinTarget {ring stripe} -allowLayerChange 1
core_block_target_250|setSrouteMode -targetSearchDistance 250|sroute -connect {corePin blockPin} -nets {VDD VSS} -blockPin all -blockPinTarget {ring stripe} -corePinTarget {ring stripe} -allowLayerChange 1
EOF

while IFS='|' read -r candidate mode_cmd sroute_cmd; do
  [[ -z "$candidate" ]] && continue
  run_id="${BASE_RUN_ID}_${candidate}"
  payload="/tmp/${run_id}.payload.tcl"
  commands="/tmp/${run_id}.commands.tcl"
  result_dir="$INNOVUS_WORK_VALUE/$run_id"

  cat > "$payload" <<EOF
set ::env(MPTDC_PG_STRATEGY) manual_ro_pg_core_sroute
set ::env(MPTDC_ENABLE_RO_PG_PROBE) 1
set ::env(MPTDC_ENABLE_RO_PG_HOOKUP) 0
set ::env(MPTDC_REQUIRE_RO_PG_HOOKUP) 0
set ::env(MPTDC_ENABLE_RO_PG_MACRO_PATCH) 1
set ::env(MPTDC_ALLOW_RO_DERIVED_PG_DANGLING) 0

set rpt [file join [mptdc_signoff_report_dir] pg_candidate_${candidate}_status.rpt]
set fh [open \$rpt w]
puts \$fh "# MPTDC PG isolated candidate"
puts \$fh "CANDIDATE=$candidate"
puts \$fh "MODE_COMMAND=$mode_cmd"
puts \$fh "SROUTE_COMMAND=$sroute_cmd"
mptdc_signoff_dump_pg_topology [file join [mptdc_signoff_report_dir] pg_candidate_${candidate}_before_topology.rpt] PG_CANDIDATE_BEFORE
catch {setSrouteMode -corePinStopRoute RowEnd} mode_err
puts \$fh "CORE_PIN_STOP_ROUTE_STATUS=[expr {[info exists mode_err] && \$mode_err ne "" ? "REVIEW_REQUIRED" : "PASS"}]"
if {"$mode_cmd" ne "NONE"} {
    if {[catch {$mode_cmd} err]} {
        puts \$fh "MODE_STATUS=REVIEW_REQUIRED"
        puts \$fh "MODE_ERROR=\$err"
    } else {
        puts \$fh "MODE_STATUS=PASS"
    }
} else {
    puts \$fh "MODE_STATUS=SKIPPED"
}
if {[catch {$sroute_cmd} err]} {
    puts \$fh "SROUTE_STATUS=FAIL"
    puts \$fh "SROUTE_ERROR=\$err"
} else {
    puts \$fh "SROUTE_STATUS=PASS"
}
close \$fh

mptdc_signoff_dump_pg_topology [file join [mptdc_signoff_report_dir] pg_candidate_${candidate}_after_topology.rpt] PG_CANDIDATE_AFTER
set snap [mptdc_ckpt_verify_snapshot pg_candidate_${candidate}_after]
foreach key {total_violations shorts regular_bad special_bad special_raw_bad special_filter_status special_filtered_ro_terminals special_non_ro_failures unrouted route_gate_pass} {
    puts "PG_CANDIDATE_${candidate}_[string toupper \$key]=[dict get \$snap \$key]"
}
EOF

  printf 'mptdc_ckpt_source_tcl %s\n' "$payload" > "$commands"

  repair_args=(
    --run-id "$run_id"
    --checkpoint "$SOURCE_CHECKPOINT"
    --commands-file "$commands"
  )
  if [[ -n "$EXPECTED_HEAD_VALUE" ]]; then
    repair_args+=(--expected-head "$EXPECTED_HEAD_VALUE")
  fi

  set +e
  MPTDC_CHECKPOINT_REPAIR_KEEP_GOING=1 \
    MPTDC_INNOVUS_WORK="$INNOVUS_WORK_VALUE" \
    "$SCRIPT_DIR/server_repair_mptdc_route_checkpoint.sh" \
      "${repair_args[@]}" \
      </dev/null
  rc=$?
  set -e

  status_report="$result_dir/reports/checkpoint_repair_status.rpt"
  command_report="$(ls "$result_dir"/reports/01_command_mptdc_ckpt_source_tcl_*.rpt 2>/dev/null | head -1 || true)"

  field() {
    local key="$1"
    local file="$2"
    if [[ -f "$file" ]]; then
      grep -E "(^|[[:space:]>])${key}=" "$file" \
        | tail -1 \
        | sed -E "s/.*${key}=//" \
        || true
    fi
  }

  drc="$(field FINAL_DRC "$status_report")"
  shorts="$(field FINAL_SHORTS "$status_report")"
  regular_bad="$(field FINAL_REGULAR_CONNECTIVITY_BAD "$status_report")"
  special_bad="$(field FINAL_SPECIAL_CONNECTIVITY_BAD "$status_report")"
  route_gate="$(field FINAL_ROUTE_GATE_PASS "$status_report")"
  checkpoint="$(field FINAL_CHECKPOINT_DAT "$status_report")"
  status="$(field CHECKPOINT_REPAIR_STATUS "$status_report")"
  special_raw="$(field FINAL_SPECIAL_CONNECTIVITY_RAW_BAD "$status_report")"
  special_filter_status="$(field FINAL_SPECIAL_CONNECTIVITY_FILTER_STATUS "$status_report")"
  special_filtered_ro="$(field FINAL_SPECIAL_CONNECTIVITY_FILTERED_RO_TERMINALS "$status_report")"
  special_non_ro="$(field FINAL_SPECIAL_CONNECTIVITY_NON_RO_FAILURES "$status_report")"
  unrouted="$(field FINAL_UNROUTED_NETS "$status_report")"
  if [[ -z "$special_raw" ]]; then
    special_raw="$(field "PG_CANDIDATE_${candidate}_SPECIAL_RAW_BAD" "$command_report")"
  fi
  if [[ -z "$special_filter_status" ]]; then
    special_filter_status="$(field "PG_CANDIDATE_${candidate}_SPECIAL_FILTER_STATUS" "$command_report")"
  fi
  if [[ -z "$special_filtered_ro" ]]; then
    special_filtered_ro="$(field "PG_CANDIDATE_${candidate}_SPECIAL_FILTERED_RO_TERMINALS" "$command_report")"
  fi
  if [[ -z "$special_non_ro" ]]; then
    special_non_ro="$(field "PG_CANDIDATE_${candidate}_SPECIAL_NON_RO_FAILURES" "$command_report")"
  fi
  if [[ -z "$unrouted" ]]; then
    unrouted="$(field "PG_CANDIDATE_${candidate}_UNROUTED" "$command_report")"
  fi

  strict_reasons=()
  [[ "$rc" == "0" ]] || strict_reasons+=("wrapper_rc_${rc:-missing}")
  [[ "$shorts" == "0" ]] || strict_reasons+=("shorts_${shorts:-missing}")
  [[ "$special_raw" == "0" ]] || strict_reasons+=("special_raw_${special_raw:-missing}")
  [[ "$special_bad" == "0" ]] || strict_reasons+=("special_bad_${special_bad:-missing}")
  if [[ -n "$drc" && "$drc" != "0" ]]; then
    strict_reasons+=("drc_${drc}")
  fi
  strict_pg_clean=FAIL
  strict_reason_text=PASS
  if [[ ${#strict_reasons[@]} -eq 0 ]]; then
    strict_pg_clean=PASS
  else
    strict_reason_text="$(IFS=+; echo "${strict_reasons[*]}")"
  fi

  printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$candidate" "$run_id" "$rc" "$strict_pg_clean" "$strict_reason_text" \
    "$drc" "$shorts" "$regular_bad" "$special_bad" \
    "$special_raw" "$special_filter_status" "$special_filtered_ro" "$special_non_ro" \
    "$unrouted" "$route_gate" "$checkpoint" "$status_report" \
    >> "$SUMMARY_CSV"

  {
    echo "## $candidate"
    echo ""
    echo "- run_id: \`$run_id\`"
    echo "- rc: \`$rc\`"
    echo "- strict_pg_clean: \`$strict_pg_clean\`"
    echo "- strict_pg_reasons: \`$strict_reason_text\`"
    echo "- final_drc/shorts: \`${drc:-NA}/${shorts:-NA}\`"
    echo "- regular_bad: \`${regular_bad:-NA}\`"
    echo "- special_bad/raw/filter/ro/non_ro: \`${special_bad:-NA}/${special_raw:-NA}/${special_filter_status:-NA}/${special_filtered_ro:-NA}/${special_non_ro:-NA}\`"
    echo "- unrouted: \`${unrouted:-NA}\`"
    echo "- route_gate_pass: \`${route_gate:-NA}\`"
    echo "- status_report: \`$status_report\`"
    echo ""
  } >> "$SUMMARY_MD"
done <<< "$CANDIDATES"

echo "SUMMARY_CSV=$SUMMARY_CSV"
echo "SUMMARY_MD=$SUMMARY_MD"
