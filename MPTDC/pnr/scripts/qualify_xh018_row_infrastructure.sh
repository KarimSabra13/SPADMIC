#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID="${1:-xh018_row_qual_$(date +%Y%m%d_%H%M%S)}"
MPTDC_WORK_ROOT="${MPTDC_WORK_ROOT:-$REPO_ROOT/work}"
RESULT_DIR="${MPTDC_ROW_QUAL_RESULT_DIR:-$MPTDC_WORK_ROOT/row_qualification/$RUN_ID}"
REPORT_DIR="$RESULT_DIR/reports"
MANIFEST_DIR="$RESULT_DIR/manifests"
WORK_DIR="$RESULT_DIR/work"
mkdir -p "$REPORT_DIR" "$MANIFEST_DIR" "$WORK_DIR"

STATUS_RPT="$REPORT_DIR/row_qualification_status.rpt"
SPEC_RPT="$REPORT_DIR/row_qualification_test_spec.rpt"
CELL_RPT="$REPORT_DIR/row_qualification_cells.rpt"
TOOL_RPT="$MANIFEST_DIR/physical_verification_tools.rpt"

{
  echo "# XH018/JIHD no-dedicated-core-tap/endcap row qualification"
  echo "date=$(date -Iseconds)"
  echo "repo=$REPO_ROOT"
  echo "branch=$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
  echo "head=$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
  echo "run_id=$RUN_ID"
  echo "result_dir=$RESULT_DIR"
  echo "policy=NO_DEDICATED_CORE_TAP_ENDCAP_PENDING_DRC_LVS"
} > "$MANIFEST_DIR/run_manifest.rpt"

if command -v tclsh >/dev/null 2>&1; then
  (
    cd "$REPO_ROOT"
    export CELL_RPT
    tclsh <<'EOF'
source MPTDC/pnr/config/xh018_cells.tcl
set out [open $::env(CELL_RPT) w]
foreach key {
    stdcell_site
    stdcell_pg_power
    stdcell_pg_ground
    tap_policy
    tap
    endcap_left_policy
    endcap_left
    endcap_right_policy
    endcap_right
    filler
    spacer
    decap
    antenna
    tie_high
    tie_low
    cts_buffers
    cts_inverters
    phase_iso_buffer
    phase_final_buffer
    rejected_core_row_cells
    core_tap_count
    core_endcap_count
    io_endcap_count
} {
    puts $out "$key=[mptdc_xh018_cell $key]"
}
close $out
EOF
  )
else
  echo "ERROR: tclsh missing; cannot read xh018_cells.tcl" > "$CELL_RPT"
fi

cat > "$SPEC_RPT" <<'EOF'
ROW_TEST_PURPOSE=prove JIHD standard-cell row construction without dedicated CORE tap/endcap masters
ROW_TEST_SITE=core_jihd
ROW_TEST_REQUIRED_CONTENT=
  legal standard-cell rows
  alternating row orientations
  representative JIHD logic cells
  representative JIHD sequential cells
  BUJIHDX4 BUJIHDX12
  FEED1JIHD FEED25JIHD
  FCPE2JIHD FCPE32JIHD
  DECAP3JIHD DECAP25JIHD
  LOGIC0DJIHD LOGIC1DJIHD
ROW_TEST_FORBIDDEN_CONTENT=
  dedicated tap cells
  dedicated endcap cells
  IO CORNER cells
  IO ENDCAP cells
ROW_TEST_PG_MAPPING=
  VDD -> vddi
  VSS -> gndi
  RO VDD -> VDD
  RO vdd! -> VDD
  RO VSS -> VSS
ROW_TEST_ACCEPTANCE_REPORTS=
  ROW_TEST_DRC_STATUS
  ROW_TEST_LVS_STATUS
  ROW_TEST_FLOATING_WELL_STATUS
  ROW_TEST_NWELL_CONTACT_STATUS
  ROW_TEST_DNWELL_CONTACT_STATUS
  ROW_TEST_PWELL_CONTACT_STATUS
  ROW_TEST_ROW_EDGE_STATUS
  ROW_TEST_ABUTMENT_STATUS
  ROW_TEST_NO_IO_ENDCAP_USED
  ROW_TEST_NO_DEDICATED_TAP_USED
  ROW_TEST_NO_DEDICATED_ENDCAP_USED
EOF

{
  for tool in pvs assura calibre innovus virtuoso si; do
    printf '%s=' "$tool"
    if command -v "$tool" >/dev/null 2>&1; then
      command -v "$tool"
    else
      echo MISSING
    fi
  done
} > "$TOOL_RPT"

DRC_STATUS=DEFERRED
LVS_STATUS=DEFERRED
DRC_EVIDENCE=missing_foundry_qualified_drc_run
LVS_EVIDENCE=missing_foundry_qualified_lvs_run

if [[ -n "${MPTDC_ROW_QUAL_DRC_CMD:-}" ]]; then
  set +e
  (cd "$RESULT_DIR" && bash -lc "$MPTDC_ROW_QUAL_DRC_CMD") > "$REPORT_DIR/row_test_drc.log" 2>&1
  drc_rc=$?
  set -e
  if [[ "$drc_rc" == "0" ]]; then
    DRC_STATUS=EXTERNAL
    DRC_EVIDENCE="$REPORT_DIR/row_test_drc.log"
  else
    DRC_STATUS=FAIL
    DRC_EVIDENCE="$REPORT_DIR/row_test_drc.log"
  fi
fi

if [[ -n "${MPTDC_ROW_QUAL_LVS_CMD:-}" ]]; then
  set +e
  (cd "$RESULT_DIR" && bash -lc "$MPTDC_ROW_QUAL_LVS_CMD") > "$REPORT_DIR/row_test_lvs.log" 2>&1
  lvs_rc=$?
  set -e
  if [[ "$lvs_rc" == "0" ]]; then
    LVS_STATUS=EXTERNAL
    LVS_EVIDENCE="$REPORT_DIR/row_test_lvs.log"
  else
    LVS_STATUS=FAIL
    LVS_EVIDENCE="$REPORT_DIR/row_test_lvs.log"
  fi
fi

cat > "$STATUS_RPT" <<EOF
ROW_INFRA_POLICY=NO_DEDICATED_CORE_TAP_ENDCAP_PENDING_DRC_LVS
ROW_TEST_DRC_STATUS=$DRC_STATUS
ROW_TEST_LVS_STATUS=$LVS_STATUS
ROW_TEST_FLOATING_WELL_STATUS=DEFERRED
ROW_TEST_NWELL_CONTACT_STATUS=DEFERRED
ROW_TEST_DNWELL_CONTACT_STATUS=DEFERRED
ROW_TEST_PWELL_CONTACT_STATUS=DEFERRED
ROW_TEST_ROW_EDGE_STATUS=DEFERRED
ROW_TEST_ABUTMENT_STATUS=DEFERRED
ROW_TEST_NO_IO_ENDCAP_USED=SPECIFIED
ROW_TEST_NO_DEDICATED_TAP_USED=SPECIFIED
ROW_TEST_NO_DEDICATED_ENDCAP_USED=SPECIFIED
ROW_TEST_DRC_EVIDENCE=$DRC_EVIDENCE
ROW_TEST_LVS_EVIDENCE=$LVS_EVIDENCE
ROW_INFRA_DRC_LVS_STATUS=DEFERRED
FINAL_SIGNOFF_ALLOWED=NO
EOF

cat "$STATUS_RPT"
