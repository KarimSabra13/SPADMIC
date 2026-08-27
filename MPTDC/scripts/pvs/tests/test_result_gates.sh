#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PVS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PREP_SCRIPT="$PVS_DIR/00_prepare_pvs_inputs_from_checkpoint.sh"
DRC_REPLAY_SCRIPT="$PVS_DIR/02_replay_pvs_drc_from_template.sh"
# shellcheck source=MPTDC/scripts/pvs/lib_pvs_common.sh
source "$PVS_DIR/lib_pvs_common.sh"
TMP_ROOT="$(mktemp -d /tmp/mptdc_pvs_gate_test.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

BASE_CONTROL="$TMP_ROOT/pvsdrcctl.base"
printf '#UNDEFINE DENSITY\n#UNDEFINE POPPING\n#UNDEFINE PIMIDE\n' > "$BASE_CONTROL"
mptdc_pvs_rewrite_drc_density_control "$BASE_CONTROL" base \
  > "$TMP_ROOT/base_control_rewrite.rpt"
grep -qx 'PVS_DRC_CONTROL_REWRITE_STATUS=PASS' "$TMP_ROOT/base_control_rewrite.rpt"
grep -qx 'PVS_DRC_DENSITY_CONTROL=#UNDEFINE DENSITY' "$TMP_ROOT/base_control_rewrite.rpt"
grep -qx 'PVS_DRC_JOINED_DIRECTIVE_COUNT=0' "$TMP_ROOT/base_control_rewrite.rpt"
test "$(sed -n '1p' "$BASE_CONTROL")" = '#UNDEFINE DENSITY'
test "$(sed -n '2p' "$BASE_CONTROL")" = '#UNDEFINE POPPING'
test "$(wc -l < "$BASE_CONTROL")" -eq 3

DENSITY_CONTROL="$TMP_ROOT/pvsdrcctl.density"
printf '#UNDEFINE DENSITY\r\n#UNDEFINE POPPING\r\n' > "$DENSITY_CONTROL"
mptdc_pvs_rewrite_drc_density_control "$DENSITY_CONTROL" density \
  > "$TMP_ROOT/density_control_rewrite.rpt"
grep -qx 'PVS_DRC_CONTROL_REWRITE_STATUS=PASS' "$TMP_ROOT/density_control_rewrite.rpt"
grep -qx 'PVS_DRC_DENSITY_CONTROL=#DEFINE DENSITY' "$TMP_ROOT/density_control_rewrite.rpt"
perl -0 -e '
  local $/;
  my $text = <>;
  exit($text eq "#DEFINE DENSITY\r\n#UNDEFINE POPPING\r\n" ? 0 : 1);
' "$DENSITY_CONTROL"

MALFORMED_CONTROL="$TMP_ROOT/pvsdrcctl.malformed"
printf '#UNDEFINE DENSITY#UNDEFINE POPPING\n' > "$MALFORMED_CONTROL"
if (mptdc_pvs_rewrite_drc_density_control "$MALFORMED_CONTROL" base) \
    > "$TMP_ROOT/malformed_control_rewrite.log" 2>&1; then
  echo "ERROR: joined DRC configurator directives unexpectedly passed" >&2
  exit 1
fi
grep -Fq 'joined configurator directives found' "$TMP_ROOT/malformed_control_rewrite.log"

grep -Fq 'RO_TAP_OBSERVABILITY_PIN_COUNT=' "$PREP_SCRIPT"
grep -Fq 'mptdc_pvs_rewrite_drc_density_control "$NEW_DRC_RUN/pvsdrcctl" "$VARIANT"' \
  "$DRC_REPLAY_SCRIPT"
grep -Fq 'pvs_drc_${VARIANT}_control_rewrite.rpt' "$DRC_REPLAY_SCRIPT"
grep -Fq 'mptdc_pvs_append_hash "$HASH_MANIFEST" STREAM_MAP "$STREAM_MAP"' "$PREP_SCRIPT"
grep -Fq 'mptdc_pvs_append_hash "$HASH_MANIFEST" PATCHED_STREAMOUT "$PATCHED_STREAMOUT"' "$PREP_SCRIPT"
grep -Fq -- '--filler-report "$FILLER_REPORT"' "$PREP_SCRIPT"
grep -Fq -- '--row-infra-report "$ROW_INFRA_REPORT"' "$PREP_SCRIPT"
grep -Fq 'mptdc_pvs_append_hash "$HASH_MANIFEST" FILLER_REPORT "$FILLER_REPORT"' "$PREP_SCRIPT"
grep -Fq 'mptdc_pvs_append_hash "$HASH_MANIFEST" ROW_INFRA_REPORT "$ROW_INFRA_REPORT"' "$PREP_SCRIPT"

STREAM_MAP_SET_LINE="$(grep -n 'set ::env(STREAM_MAP) $stream_map' "$PREP_SCRIPT" | head -1 | cut -d: -f1)"
STD_GDS_SET_LINE="$(grep -n 'set ::env(STD_GDS) $dcell_gds' "$PREP_SCRIPT" | head -1 | cut -d: -f1)"
STREAMOUT_SOURCE_LINE="$(grep -n 'set source_rc \[catch {source $patched_streamout}' "$PREP_SCRIPT" | head -1 | cut -d: -f1)"
[[ -n "$STREAM_MAP_SET_LINE" && -n "$STD_GDS_SET_LINE" && -n "$STREAMOUT_SOURCE_LINE" ]]
[[ "$STREAM_MAP_SET_LINE" -lt "$STREAMOUT_SOURCE_LINE" ]]
[[ "$STD_GDS_SET_LINE" -lt "$STREAMOUT_SOURCE_LINE" ]]
grep -Fq 'rename restoreDesign mptdc_pvs_saved_restoreDesign' "$PREP_SCRIPT"
grep -Fq 'rename mptdc_pvs_saved_restoreDesign restoreDesign' "$PREP_SCRIPT"
grep -Fq 'MPTDC_PVS_PREP_TEMPLATE_RESTORE_SKIP_COUNT=' "$PREP_SCRIPT"
grep -Fq 'MPTDC_PVS_PREP_TEMPLATE_RESTORE_GUARD_STATUS=PASS' "$PREP_SCRIPT"
if grep -Fq 'restore_db_stop_at_design_in_memory' "$PREP_SCRIPT"; then
  echo "ERROR: preparation script disables Innovus restore protection" >&2
  exit 1
fi
grep -Fq 'MPTDC_PVS_PREP_FATAL_LABEL=$label' "$PREP_SCRIPT"
grep -Fq 'MPTDC_PVS_PREP_BATCH_STATUS=PASS' "$PREP_SCRIPT"
grep -Fq 'innovus -nowin -init "$GENERATED_TCL" -log "$LOG_DIR/innovus_prepare_pvs_inputs.log" </dev/null' "$PREP_SCRIPT"

SELECTED_MAP="/pdk/selected/pnr_streamout.map"
ENV_MAP_TEMPLATE="$TMP_ROOT/streamout_env_map.tcl"
LITERAL_MAP_TEMPLATE="$TMP_ROOT/streamout_literal_map.tcl"
STALE_MAP_TEMPLATE="$TMP_ROOT/streamout_stale_map.tcl"
MISSING_MAP_TEMPLATE="$TMP_ROOT/streamout_missing_map.tcl"

cat > "$ENV_MAP_TEMPLATE" <<'EOF'
streamOut $::env(MERGED_GDS) -mapFile $::env(STREAM_MAP) -mode ALL
EOF
cat > "$LITERAL_MAP_TEMPLATE" <<EOF
streamOut \$::env(MERGED_GDS) -mapFile {$SELECTED_MAP} -mode ALL
EOF
cat > "$STALE_MAP_TEMPLATE" <<'EOF'
streamOut $::env(MERGED_GDS) -mapFile /pdk/stale/streamout.map -mode ALL
EOF
cat > "$MISSING_MAP_TEMPLATE" <<'EOF'
streamOut $::env(MERGED_GDS) -mode ALL
EOF

[[ "$(mptdc_pvs_streamout_map_binding_mode "$ENV_MAP_TEMPLATE" "$SELECTED_MAP")" == "ENV_SELECTED_MAP" ]]
[[ "$(mptdc_pvs_streamout_map_binding_mode "$LITERAL_MAP_TEMPLATE" "$SELECTED_MAP")" == "LITERAL_SELECTED_MAP" ]]
if mptdc_pvs_streamout_map_binding_mode "$STALE_MAP_TEMPLATE" "$SELECTED_MAP"; then
  echo "ERROR: stale literal streamout map unexpectedly passed" >&2
  exit 1
fi
if mptdc_pvs_streamout_map_binding_mode "$MISSING_MAP_TEMPLATE" "$SELECTED_MAP"; then
  echo "ERROR: missing streamout map unexpectedly passed" >&2
  exit 1
fi

GDS="$TMP_ROOT/mptdc_axis_core.gds"
SOURCE="$TMP_ROOT/mptdc_axis_core.v"
CDL="$TMP_ROOT/xh018_D_CELLS_JIHD.cdl"
HCELL="$TMP_ROOT/pvs_hcell_ro6.txt"
HASH_MANIFEST="$TMP_ROOT/pvs_input_hashes.rpt"

printf 'fixture gds\n' > "$GDS"
printf 'module mptdc_axis_core; endmodule\n' > "$SOURCE"
printf '.SUBCKT INV A Y VDD VSS\n.ENDS\n' > "$CDL"
printf 'RO_tune6 RO_tune6\n' > "$HCELL"

{
  printf 'STRICT_ATTRIBUTION=1\n'
  printf 'MERGED_GDS_PATH=%s\n' "$GDS"
  printf 'MERGED_GDS_SHA256=%s\n' "$(sha256sum "$GDS" | awk '{print $1}')"
  printf 'LVS_SOURCE_FILTERED_PATH=%s\n' "$SOURCE"
  printf 'LVS_SOURCE_FILTERED_SHA256=%s\n' "$(sha256sum "$SOURCE" | awk '{print $1}')"
  printf 'DCELL_CDL_PATH=%s\n' "$CDL"
  printf 'DCELL_CDL_SHA256=%s\n' "$(sha256sum "$CDL" | awk '{print $1}')"
  printf 'LVS_HCELL_PATH=%s\n' "$HCELL"
  printf 'LVS_HCELL_SHA256=%s\n' "$(sha256sum "$HCELL" | awk '{print $1}')"
} > "$HASH_MANIFEST"

make_drc_fixture() {
  local run_dir="$1"
  local density_control="$2"
  local primary="$3"
  mkdir -p "$run_dir"
  cat > "$run_dir/run.pvs" <<EOF
#!/bin/sh
cd $run_dir
pvs -drc -top_cell mptdc_axis_core -control $run_dir/pvsdrcctl
EOF
  cat > "$run_dir/pvsdrcctl" <<EOF
layout_path "$GDS";
$density_control
EOF
  cat > "$run_dir/mptdc_axis_core_drc.sum" <<EOF
RULECHECK RULE_A ........ Total Result $primary ( $primary )
Total DRC RuleChecks : 1
Total DRC Results : $primary ( $primary )
EOF
}

BASE_DRC="$TMP_ROOT/drc_base"
make_drc_fixture "$BASE_DRC" "#UNDEFINE DENSITY" 0
python3 "$PVS_DIR/05_gate_pvs_drc.py" \
  --run-dir "$BASE_DRC" \
  --tool-rc 0 \
  --variant base \
  --expected-top mptdc_axis_core \
  --hash-manifest "$HASH_MANIFEST" \
  --out "$TMP_ROOT/drc_base_pass.rpt"
grep -qx 'PVS_DRC_STATUS=PASS' "$TMP_ROOT/drc_base_pass.rpt"
grep -qx $'rule\tprimary\texpanded' "$TMP_ROOT/drc_base_pass_nonzero_rules.tsv"
test "$(wc -l < "$TMP_ROOT/drc_base_pass_nonzero_rules.tsv")" -eq 1

DIRTY_DRC="$TMP_ROOT/drc_dirty"
make_drc_fixture "$DIRTY_DRC" "#UNDEFINE DENSITY" 1
if python3 "$PVS_DIR/05_gate_pvs_drc.py" \
  --run-dir "$DIRTY_DRC" \
  --tool-rc 0 \
  --variant base \
  --expected-top mptdc_axis_core \
  --hash-manifest "$HASH_MANIFEST" \
  --out "$TMP_ROOT/drc_dirty_fail.rpt"; then
  echo "ERROR: nonzero DRC unexpectedly passed" >&2
  exit 1
fi
grep -qx 'PVS_DRC_STATUS=FAIL' "$TMP_ROOT/drc_dirty_fail.rpt"
grep -qx $'RULE_A\t1\t1' "$TMP_ROOT/drc_dirty_fail_nonzero_rules.tsv"
grep -Fqx "NONZERO_RULE_REPORT=$TMP_ROOT/drc_dirty_fail_nonzero_rules.tsv" \
  "$TMP_ROOT/drc_dirty_fail.rpt"

ARCHIVED_DRC_SUM="$PVS_DIR/../../docs/signoff_notes/pvs_drc_realro6_20260707_01_evidence/mptdc_axis_core_drc.sum"
if [[ -s "$ARCHIVED_DRC_SUM" ]]; then
  ARCHIVED_DRC="$TMP_ROOT/drc_archived_nonzero"
  make_drc_fixture "$ARCHIVED_DRC" "#UNDEFINE DENSITY" 0
  cp -p "$ARCHIVED_DRC_SUM" "$ARCHIVED_DRC/mptdc_axis_core_drc.sum"
  if python3 "$PVS_DIR/05_gate_pvs_drc.py" \
    --run-dir "$ARCHIVED_DRC" \
    --tool-rc 0 \
    --variant base \
    --expected-top mptdc_axis_core \
    --hash-manifest "$HASH_MANIFEST" \
    --out "$TMP_ROOT/drc_archived_fail.rpt"; then
    echo "ERROR: archived 4783-result DRC unexpectedly passed" >&2
    exit 1
  fi
  grep -qx 'DRC_TOTAL_PRIMARY=4783' "$TMP_ROOT/drc_archived_fail.rpt"
fi

DENSITY_DRC="$TMP_ROOT/drc_density"
make_drc_fixture "$DENSITY_DRC" "#DEFINE DENSITY" 0
python3 "$PVS_DIR/05_gate_pvs_drc.py" \
  --run-dir "$DENSITY_DRC" \
  --tool-rc 0 \
  --variant density \
  --expected-top mptdc_axis_core \
  --hash-manifest "$HASH_MANIFEST" \
  --out "$TMP_ROOT/drc_density_pass.rpt"
grep -qx 'PVS_DRC_STATUS=PASS' "$TMP_ROOT/drc_density_pass.rpt"

LVS_RUN="$TMP_ROOT/lvs"
mkdir -p "$LVS_RUN"
cat > "$LVS_RUN/run.pvs" <<EOF
#!/bin/sh
cd $LVS_RUN
pvs -lvs -top_cell mptdc_axis_core -source_top_cell mptdc_axis_core -control $LVS_RUN/pvslvsctl -hcell $HCELL
EOF
cat > "$LVS_RUN/pvslvsctl" <<EOF
layout_path "$GDS";
schematic_path "$SOURCE" verilog -keep_backslash;
schematic_path "$CDL" cdl;
EOF
: > "$LVS_RUN/.config.rul"
printf 'fixture technology\n' > "$LVS_RUN/.technology.rul"
printf 'The net-lists match.\n' > "$LVS_RUN/final_lvs.sum"

python3 "$PVS_DIR/06_gate_pvs_lvs.py" \
  --run-dir "$LVS_RUN" \
  --tool-rc 0 \
  --gds "$GDS" \
  --source "$SOURCE" \
  --cdl "$CDL" \
  --hcell "$HCELL" \
  --hash-manifest "$HASH_MANIFEST" \
  --layout-top mptdc_axis_core \
  --source-top mptdc_axis_core \
  --out "$TMP_ROOT/lvs_pass.rpt" \
  --inventory "$TMP_ROOT/lvs_pass_inventory.tsv"
grep -qx 'PVS_LVS_STATUS=MATCH' "$TMP_ROOT/lvs_pass.rpt"

sed -i 's/verilog -keep_backslash;/verilog -keep_backslash -unsupported;/' \
  "$LVS_RUN/pvslvsctl"
if python3 "$PVS_DIR/06_gate_pvs_lvs.py" \
  --run-dir "$LVS_RUN" \
  --tool-rc 0 \
  --gds "$GDS" \
  --source "$SOURCE" \
  --cdl "$CDL" \
  --hcell "$HCELL" \
  --hash-manifest "$HASH_MANIFEST" \
  --layout-top mptdc_axis_core \
  --source-top mptdc_axis_core \
  --out "$TMP_ROOT/lvs_option_fail.rpt" \
  --inventory "$TMP_ROOT/lvs_option_fail_inventory.tsv"; then
  echo "ERROR: unsupported LVS source option unexpectedly passed" >&2
  exit 1
fi
grep -Fqx \
  "ERROR=pvslvsctl Verilog schematic_path has unsupported options: ('-keep_backslash', '-unsupported')" \
  "$TMP_ROOT/lvs_option_fail.rpt"
sed -i 's/verilog -keep_backslash -unsupported;/verilog -keep_backslash;/' \
  "$LVS_RUN/pvslvsctl"

printf 'The net-lists do not match.\n' > "$LVS_RUN/final_lvs.sum"
if python3 "$PVS_DIR/06_gate_pvs_lvs.py" \
  --run-dir "$LVS_RUN" \
  --tool-rc 0 \
  --gds "$GDS" \
  --source "$SOURCE" \
  --cdl "$CDL" \
  --hcell "$HCELL" \
  --hash-manifest "$HASH_MANIFEST" \
  --layout-top mptdc_axis_core \
  --source-top mptdc_axis_core \
  --out "$TMP_ROOT/lvs_fail.rpt" \
  --inventory "$TMP_ROOT/lvs_fail_inventory.tsv"; then
  echo "ERROR: LVS mismatch unexpectedly passed" >&2
  exit 1
fi
grep -qx 'PVS_LVS_STATUS=MISMATCH' "$TMP_ROOT/lvs_fail.rpt"
grep -qx 'PVS_RC=0' "$TMP_ROOT/lvs_fail.rpt"
grep -Fq 'ERROR=explicit LVS mismatch evidence found in ' "$TMP_ROOT/lvs_fail.rpt"

echo "MPTDC_PVS_RESULT_GATE_TEST=PASS"
