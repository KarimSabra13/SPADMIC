#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PVS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PREP_SCRIPT="$PVS_DIR/00_prepare_pvs_inputs_from_checkpoint.sh"
# shellcheck source=MPTDC/scripts/pvs/lib_pvs_common.sh
source "$PVS_DIR/lib_pvs_common.sh"
TMP_ROOT="$(mktemp -d /tmp/mptdc_pvs_gate_test.XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

grep -Fq 'RO_TAP_OBSERVABILITY_PIN_COUNT=' "$PREP_SCRIPT"
grep -Fq 'mptdc_pvs_append_hash "$HASH_MANIFEST" STREAM_MAP "$STREAM_MAP"' "$PREP_SCRIPT"
grep -Fq 'mptdc_pvs_append_hash "$HASH_MANIFEST" PATCHED_STREAMOUT "$PATCHED_STREAMOUT"' "$PREP_SCRIPT"

STREAM_MAP_SET_LINE="$(grep -n 'set ::env(STREAM_MAP) $stream_map' "$PREP_SCRIPT" | head -1 | cut -d: -f1)"
STREAMOUT_SOURCE_LINE="$(grep -n 'mptdc_pvs_try source_streamout' "$PREP_SCRIPT" | head -1 | cut -d: -f1)"
[[ -n "$STREAM_MAP_SET_LINE" && -n "$STREAMOUT_SOURCE_LINE" ]]
[[ "$STREAM_MAP_SET_LINE" -lt "$STREAMOUT_SOURCE_LINE" ]]

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
schematic_path "$SOURCE" verilog;
schematic_path "$CDL" spice;
EOF
printf 'fixture config\n' > "$LVS_RUN/.config.rul"
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
grep -qx 'PVS_LVS_STATUS=NOT_PROVEN' "$TMP_ROOT/lvs_fail.rpt"

echo "MPTDC_PVS_RESULT_GATE_TEST=PASS"
