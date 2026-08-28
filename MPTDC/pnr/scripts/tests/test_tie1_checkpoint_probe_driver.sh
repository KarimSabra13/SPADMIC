#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_ROOT="$(mktemp -d /tmp/mptdc_tie1_checkpoint_probe.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

REPO="$TMP_ROOT/repo"
WORK="$TMP_ROOT/work"
SOURCE_PVS_ID=physical_source_fillernorm
SOURCE_PNR_ID=failed_v6r
BOUNDARY_ID=boundary_step5r
BAD_BOUNDARY_ID=boundary_bad_cascade
DRIVER="$REPO/MPTDC/pnr/scripts/server_run_mptdc_tie1_checkpoint_probe.sh"
PROBE_TCL="$REPO/MPTDC/pnr/scripts/innovus_mptdc_tie1_checkpoint_probe.tcl"
INNOVUS_STUB="$TMP_ROOT/innovus_stub.sh"
PUBLISHER_STUB="$TMP_ROOT/publisher_stub.sh"
TCL_HARNESS="$TMP_ROOT/tie1_probe_tcl_harness.tcl"

mkdir -p "$REPO/MPTDC/pnr/scripts" \
  "$WORK/$SOURCE_PNR_ID/checkpoints/repaired_route.enc.dat" \
  "$WORK/$SOURCE_PVS_ID/reports" \
  "$WORK/$SOURCE_PVS_ID/outputs"
cp -p "$PNR_DIR/server_run_mptdc_tie1_checkpoint_probe.sh" "$DRIVER"
cp -p "$PNR_DIR/innovus_mptdc_tie1_checkpoint_probe.tcl" "$PROBE_TCL"
printf 'immutable checkpoint fixture\n' \
  > "$WORK/$SOURCE_PNR_ID/checkpoints/repaired_route.enc.dat/design.bin"

cat > "$WORK/$SOURCE_PVS_ID/outputs/mptdc_axis_core_pnr_lvs_phys_with_pg.v" <<'EOF'
module mptdc_axis_core;
  wire tie1;
  NA2JIHDX1 u0 (.A(tie1));
endmodule
EOF
PHYSICAL_SHA="$(sha256sum "$WORK/$SOURCE_PVS_ID/outputs/mptdc_axis_core_pnr_lvs_phys_with_pg.v" | awk '{print $1}')"

cat > "$WORK/$SOURCE_PVS_ID/reports/lvs_source_filter.rpt" <<EOF
LVS_SOURCE_CONTRACT_STATUS=PASS
SOURCE_KIND=INNOVUS_SAVE_NETLIST_PHYS_INCLUDE_POWER_GROUND
INPUT=$WORK/$SOURCE_PVS_ID/outputs/mptdc_axis_core_pnr_lvs_phys_with_pg.v
INPUT_SHA256=$PHYSICAL_SHA
PHYSICAL_ONLY_FILLER_REMOVAL_STATUS=PASS
RO_TUNE6_INSTANCE_NAME_STATUS=PASS
PHYSICAL_TIE_MASTER_COUNT=0
PHYSICAL_TIE_INSTANCE_COUNT=0
PHYSICAL_TIE_PRESERVATION_STATUS=PASS
UNRESOLVED_ACTIVE_MASTER_COUNT=0
EOF

make_boundary_fixture() {
  local boundary_id="$1"
  local cascade_count="$2"
  local live="$WORK/$boundary_id"
  local tracked="$REPO/MPTDC/docs/server_snapshots/pvs/$boundary_id"

  mkdir -p "$live/reports" "$live/manifests" "$live/outputs" \
    "$tracked/reports" "$tracked/manifests"
  cp -p "$WORK/$SOURCE_PVS_ID/outputs/mptdc_axis_core_pnr_lvs_phys_with_pg.v" \
    "$live/outputs/mptdc_axis_core_pnr_lvs_phys_with_pg.v"

  cat > "$live/reports/operator_gate_pvs_ro6_boundary_lvs.rpt" <<EOF
STEP=PVS_RO6_BOUNDARY_LVS
SOURCE_PVS_RUN_ID=$SOURCE_PVS_ID
STANDALONE_PVS_RUN_ID=ro6_standalone_match
PVS_RUN_CLASS=DIAGNOSTIC_RO6_BOUNDARY_BLACKBOX
LVS_RC=8
STATUS=FAIL
PVS_LVS_STATUS=MISMATCH
PVS_RC=0
LVS_BLACKBOX_RULE_STATUS=PASS
LVS_BLACKBOX_APPLICATION_STATUS=PASS
LVS_BLACKBOXED_CELL_COUNT=1
LVS_BUS_PIN_MAP_EFFECTIVE_VALUE=NO
LVS_BUS_PIN_MAP_RULE_STATUS=NOT_USED_EXACT_SCALAR_SOURCE
LVS_GLOBAL_SIGNAL_PORT_RULE_STATUS=PASS
RO6_BLACKBOX_CELL_MATCH_STATUS=PASS
RO6_ANGLE_BUS_MISSING_PIN_COUNT=0
RO6_SQUARE_BUS_MISSING_PIN_COUNT=0
TIE1_UNMATCHED_PIN_COUNT=0
TIE1_MISMATCHED_NET_COUNT=1
TIE1_MISMATCHED_INSTANCE_CASCADE_COUNT=$cascade_count
LAYOUT_OPEN_NET_COUNT=2
SHORTS_OPENS_RECORD_COUNT=1
MISMATCHED_NET_RECORD_COUNT=91
MISMATCHED_INSTANCE_RECORD_COUNT=334
VDD_OPEN_SECTION_COUNT=0
VSS_OPEN_SECTION_COUNT=1
BOUNDARY_REMAINDER_CLASS=TOP_CONNECTIVITY_MISMATCH
RO6_STANDALONE_LVS_REQUIRED=YES
DRC_STATUS=NOT_RUN_BY_SCOPE
SIGNOFF_ELIGIBLE=NO
DECISION=FAIL_STOP
NEXT_STAGE=STOP_AND_REVIEW_PUBLISHED_EVIDENCE
EOF

  cat > "$live/manifests/pvs_input_hashes.rpt" <<EOF
TOP_CELL=mptdc_axis_core
SOURCE_CHECKPOINT=$WORK/$SOURCE_PNR_ID/checkpoints/repaired_route.enc.dat
LVS_SOURCE_PHYSICAL_PG_PATH=$live/outputs/mptdc_axis_core_pnr_lvs_phys_with_pg.v
LVS_SOURCE_PHYSICAL_PG_SHA256=$PHYSICAL_SHA
EOF

  cp -p "$live/reports/operator_gate_pvs_ro6_boundary_lvs.rpt" \
    "$tracked/reports/operator_gate_pvs_ro6_boundary_lvs.rpt"
  cp -p "$live/manifests/pvs_input_hashes.rpt" \
    "$tracked/manifests/pvs_input_hashes.rpt"
}

make_boundary_fixture "$BOUNDARY_ID" 334
make_boundary_fixture "$BAD_BOUNDARY_ID" 333
mkdir -p "$REPO/MPTDC/docs/server_snapshots/pvs/${SOURCE_PVS_ID}_04_lvs/reports"
cp -p "$WORK/$SOURCE_PVS_ID/reports/lvs_source_filter.rpt" \
  "$REPO/MPTDC/docs/server_snapshots/pvs/${SOURCE_PVS_ID}_04_lvs/reports/lvs_source_filter.rpt"

cat > "$INNOVUS_STUB" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
outdir="${MPTDC_TIE1_PROBE_OUTDIR:?}"
checkpoint="${MPTDC_TIE1_PROBE_CKPT:?}"
mkdir -p "$outdir/reports"
if [[ "${MPTDC_TEST_MUTATE_SAFE_COPY:-0}" == 1 ]]; then
  printf 'unexpected mutation\n' >> "$checkpoint/design.bin"
fi
cat > "$outdir/reports/tie1_checkpoint_probe_status.rpt" <<'RPT'
STEP=TIE1_CHECKPOINT_PROBE
RESTORE_STATUS=PASS
TIE1_NET_COUNT=1
TIE1_INST_TERM_COUNT=334
TIE1_REGULAR_WIRE_COUNT=0
TIE1_SPECIAL_WIRE_COUNT=0
TIE1_VIA_COUNT=0
TIE_AVAILABLE_MASTER_COUNT=4
PHYSICAL_TIE_MASTER_COUNT=0
PHYSICAL_TIE_INSTANCE_COUNT=0
FLAGGED_TIE_HIGH_TERM_COUNT=334
FLAGGED_TIE_LOW_TERM_COUNT=0
CORE_QUERY_ERROR_COUNT=0
QUERY_ERROR_COUNT=0
FLAGGED_DETAIL_QUERY_ERROR_COUNT=0
CORE_QUERY_STATUS=PASS
DESIGN_OBJECT_COUNT_STATUS=PASS
DESIGN_MUTATION_COUNT=0
PROBE_STATUS=PASS
RPT
cat > "$outdir/reports/tie1_candidate_master_inventory.tsv" <<'RPT'
master	polarity	library_master_count	physical_instance_count
LOGIC1DJIHD	HIGH	1	0
RPT
cat > "$outdir/reports/tie1_inst_term_inventory.tsv" <<'RPT'
index	inst_term	instance	master	pin	net	is_tie_high	is_tie_low
0	u0/A	u0	NA2JIHDX1	A	tie1	1	0
RPT
exit 0
EOF

cat > "$PUBLISHER_STUB" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${MPTDC_TEST_PUBLISH_ARGS:?}"
exit 0
EOF
chmod +x "$INNOVUS_STUB" "$PUBLISHER_STUB"

cat > "$TCL_HARNESS" <<'EOF'
proc restoreDesign {checkpoint top_cell} {
  if {![file exists $checkpoint] || $top_cell ne "mptdc_axis_core"} {
    error "bad restore fixture"
  }
}
proc dbGet {args} {
  set query [join $args " "]
  switch -glob -- $query {
    "top.insts" { return {0xi0 0xi1} }
    "top.nets" { return {0xn0 0xn1} }
    "top.nets.name" { return {tie1 clk} }
    "top.nets.name tie1 -p" { return 0xnet }
    "0xnet.instTerms" { return {0xt0 0xt1} }
    "0xnet.wires" -
    "0xnet.sWires" -
    "0xnet.vias" { return 0x0 }
    "0xnet.instTerms.name" { return {u0/A u1/A} }
    "0xnet.instTerms.inst.name" { return {u0 u1} }
    "0xnet.instTerms.inst.cell.name" { return {NA2JIHDX1 NO2JIHDX1} }
    "0xnet.instTerms.cellTerm.name" { return {A A} }
    "0xnet.instTerms.net.name" { return {tie1 tie1} }
    "0xnet.instTerms.isTieHi" { return {1 1} }
    "0xnet.instTerms.isTieLo" { return {0 0} }
    "top.insts.instTerms.isTieHi 1 -p" { return {0xt0 0xt1} }
    "top.insts.instTerms.isTieLo 1 -p" { return 0x0 }
    "0xt0.name" { return u0/A }
    "0xt0.inst.name" { return u0 }
    "0xt0.inst.cell.name" { return NA2JIHDX1 }
    "0xt0.cellTerm.name" { return A }
    "0xt0.net.name" { return tie1 }
    "0xt1.name" { return u1/A }
    "0xt1.inst.name" { return u1 }
    "0xt1.inst.cell.name" { return NO2JIHDX1 }
    "0xt1.cellTerm.name" { return A }
    "0xt1.net.name" { return tie1 }
    "head.libCells.name * -p" { return 0xlib }
    "top.insts.cell.name * -p2" { return 0x0 }
    "top.nets.?" { return {name wires sWires instTerms} }
    "top.insts.instTerms.?" { return {name net inst cellTerm isTieHi isTieLo} }
    default { error "unexpected dbGet query: $query" }
  }
}
set ::env(MPTDC_TIE1_PROBE_CKPT) $::env(MPTDC_TEST_TCL_CKPT)
set ::env(MPTDC_TIE1_PROBE_OUTDIR) $::env(MPTDC_TEST_TCL_OUT)
set ::env(MPTDC_TIE1_PROBE_TOP) mptdc_axis_core
source $::env(MPTDC_TEST_PROBE_TCL)
EOF

mkdir -p "$TMP_ROOT/tcl_checkpoint"
printf 'tcl checkpoint fixture\n' > "$TMP_ROOT/tcl_checkpoint/design.bin"
MPTDC_TEST_TCL_CKPT="$TMP_ROOT/tcl_checkpoint" \
MPTDC_TEST_TCL_OUT="$TMP_ROOT/tcl_probe_out" \
MPTDC_TEST_PROBE_TCL="$PNR_DIR/innovus_mptdc_tie1_checkpoint_probe.tcl" \
tclsh "$TCL_HARNESS" > "$TMP_ROOT/tcl_probe.stdout"
grep -qx 'MPTDC_TIE1_CHECKPOINT_PROBE_STATUS=PASS' "$TMP_ROOT/tcl_probe.stdout"
grep -qx 'TIE1_NET_COUNT=1' "$TMP_ROOT/tcl_probe_out/reports/tie1_checkpoint_probe_status.rpt"
grep -qx 'TIE1_INST_TERM_COUNT=2' "$TMP_ROOT/tcl_probe_out/reports/tie1_checkpoint_probe_status.rpt"
grep -qx 'PHYSICAL_TIE_INSTANCE_COUNT=0' "$TMP_ROOT/tcl_probe_out/reports/tie1_checkpoint_probe_status.rpt"
grep -qx 'FLAGGED_DETAIL_QUERY_ERROR_COUNT=0' "$TMP_ROOT/tcl_probe_out/reports/tie1_checkpoint_probe_status.rpt"
grep -qx 'DESIGN_MUTATION_COUNT=0' "$TMP_ROOT/tcl_probe_out/reports/tie1_checkpoint_probe_status.rpt"
grep -qx 'PROBE_STATUS=PASS' "$TMP_ROOT/tcl_probe_out/reports/tie1_checkpoint_probe_status.rpt"

git init -q -b SPADMIC_test "$REPO"
git -C "$REPO" config user.name 'MPTDC tie1 probe test'
git -C "$REPO" config user.email 'mptdc-tie1-probe@example.invalid'
git -C "$REPO" add MPTDC
git -C "$REPO" commit -q -m fixtures
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"

SOURCE_HASH_BEFORE="$(sha256sum "$WORK/$SOURCE_PNR_ID/checkpoints/repaired_route.enc.dat/design.bin" | awk '{print $1}')"
RUN_ID=tie1_probe_pass
MPTDC_TIE1_PROBE_REPO_ROOT="$REPO" \
MPTDC_TIE1_PROBE_INNOVUS_BIN="$INNOVUS_STUB" \
MPTDC_TIE1_PROBE_PUBLISHER="$PUBLISHER_STUB" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/pass.publish.args" \
bash "$DRIVER" \
  --boundary-pvs-run-id "$BOUNDARY_ID" \
  --run-id "$RUN_ID" \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/pass.stdout"

grep -qx 'TIE1_CHECKPOINT_PROBE_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'TIE1_NET_COUNT=1' "$TMP_ROOT/pass.stdout"
grep -qx 'TIE1_INST_TERM_COUNT=334' "$TMP_ROOT/pass.stdout"
grep -qx 'PHYSICAL_TIE_INSTANCE_COUNT=0' "$TMP_ROOT/pass.stdout"
grep -qx 'READ_ONLY_STATUS=PASS' "$TMP_ROOT/pass.stdout"
grep -qx 'DECISION=PASS_REVIEW_TIE1_EVIDENCE' "$TMP_ROOT/pass.stdout"
grep -qx 'NEXT_STAGE=REVIEW_TIE1_EVIDENCE_BEFORE_HASH_GUARDED_TRIAL' "$TMP_ROOT/pass.stdout"
grep -q "innovus $RUN_ID $WORK/$RUN_ID TIE1_CHECKPOINT_PROBE" "$TMP_ROOT/pass.publish.args"
grep -qx 'SAFE_COPY_MATCH_STATUS=PASS' "$WORK/$RUN_ID/reports/operator_gate_tie1_checkpoint_probe.rpt"
grep -qx 'DESIGN_MUTATION_COUNT=0' "$WORK/$RUN_ID/reports/operator_gate_tie1_checkpoint_probe.rpt"
test "$(wc -l < "$WORK/$RUN_ID/reports/tie1_inst_term_inventory.tsv")" -eq 2
SOURCE_HASH_AFTER="$(sha256sum "$WORK/$SOURCE_PNR_ID/checkpoints/repaired_route.enc.dat/design.bin" | awk '{print $1}')"
test "$SOURCE_HASH_BEFORE" = "$SOURCE_HASH_AFTER"

set +e
MPTDC_TIE1_PROBE_REPO_ROOT="$REPO" \
MPTDC_TIE1_PROBE_INNOVUS_BIN="$INNOVUS_STUB" \
MPTDC_TIE1_PROBE_PUBLISHER="$PUBLISHER_STUB" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/bad.publish.args" \
bash "$DRIVER" \
  --boundary-pvs-run-id "$BAD_BOUNDARY_ID" \
  --run-id tie1_probe_bad_boundary \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/bad.stdout" 2>&1
BAD_RC=$?
set -e
test "$BAD_RC" -eq 4
grep -q "TIE1_MISMATCHED_INSTANCE_CASCADE_COUNT expected '334', got '333'" "$TMP_ROOT/bad.stdout"
test ! -e "$WORK/tie1_probe_bad_boundary"

set +e
MPTDC_TEST_MUTATE_SAFE_COPY=1 \
MPTDC_TIE1_PROBE_REPO_ROOT="$REPO" \
MPTDC_TIE1_PROBE_INNOVUS_BIN="$INNOVUS_STUB" \
MPTDC_TIE1_PROBE_PUBLISHER="$PUBLISHER_STUB" \
MPTDC_INNOVUS_WORK="$WORK" \
MPTDC_TEST_PUBLISH_ARGS="$TMP_ROOT/mutation.publish.args" \
bash "$DRIVER" \
  --boundary-pvs-run-id "$BOUNDARY_ID" \
  --run-id tie1_probe_mutated_copy \
  --expected-head "$HEAD_SHA" > "$TMP_ROOT/mutation.stdout" 2>&1
MUTATION_RC=$?
set -e
test "$MUTATION_RC" -eq 1
grep -qx 'READ_ONLY_STATUS=FAIL' "$TMP_ROOT/mutation.stdout"
grep -qx 'DECISION=FAIL_STOP' "$TMP_ROOT/mutation.stdout"
grep -qx 'SAFE_CHECKPOINT_HASH_STATUS=FAIL' \
  "$WORK/tie1_probe_mutated_copy/reports/operator_gate_tie1_checkpoint_probe.rpt"
SOURCE_HASH_FINAL="$(sha256sum "$WORK/$SOURCE_PNR_ID/checkpoints/repaired_route.enc.dat/design.bin" | awk '{print $1}')"
test "$SOURCE_HASH_BEFORE" = "$SOURCE_HASH_FINAL"

echo "MPTDC_TIE1_CHECKPOINT_PROBE_DRIVER_TEST=PASS"
