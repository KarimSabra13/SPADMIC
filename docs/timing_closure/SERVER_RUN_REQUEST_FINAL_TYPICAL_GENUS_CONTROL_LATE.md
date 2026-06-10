# Server Run Request: Final Typical Genus Late Control Repair

Run this on the lab server from `SPADMIC_FINAL`. This is typical-only Genus
repair, not MMMC and not final silicon signoff.

This run is the follow-up to
`final_typical_genus_control_only_20260610_152702`. The control-only run fixed
DRV but moved timing to `-23.0 ps / -1870.3 ps / 218 paths`, so this experiment
keeps the control fix later and narrower.

## Command Block

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC

git checkout SPADMIC_FINAL
git pull --ff-only
git rev-parse HEAD

unset MPTDC_GENUS_REPAIR_STRONG_FAST_TAG_FLOPS
unset MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE
unset MPTDC_GENUS_REPAIR_APPLY_DESIGN_DRV
unset MPTDC_FAST_TAG_REPAIR_MAX_DELAY_NS

source MPTDC/analog_handoff/real_ro_tune4_abstract.env

SRC_LEF="$O1_RO_SOURCE_LEF_PATH"
DST_DIR="$PWD/work/macros/ro_tune4"
DST_LEF="$DST_DIR/RO_tune4_real_abstract.lef"

test -f "$SRC_LEF" || { echo "MISSING source LEF: $SRC_LEF"; exit 2; }

mkdir -p "$DST_DIR" work/logs
cp "$SRC_LEF" "$DST_LEF"

python3 MPTDC/analog_handoff/audit_ro_tune4_abstract.py \
  --source-lef "$SRC_LEF" \
  --copied-lef "$DST_LEF" \
  --report work/evidence/ro_tune4_lef_audit.rpt

RUN_ID=final_typical_genus_control_late_$(date +%Y%m%d_%H%M%S)

MPTDC_WORK_ROOT=work \
MPTDC_RO_SOURCE_LEF_PATH="$SRC_LEF" \
O1_RO_LEF_PATH="$DST_LEF" \
O1_RO_LIBERTY_PATH="$PWD/MPTDC/syn/macros/RO_tune4_real_abstract_shell.lib" \
bash MPTDC/syn/scripts/server_run_genus_mptdc_final_typical_control_late.sh "$RUN_ID" \
  2>&1 | tee "work/logs/${RUN_ID}.console.log"

RUN_DIR="work/genus/$RUN_ID"

sed -n '1,320p' "$RUN_DIR/SUMMARY.md"
cat "$RUN_DIR/final_typical_genus_repair_1.rpt"
cat "$RUN_DIR/report_helpers_status.rpt"
cat "$RUN_DIR/summary_parser_check.rpt"
cat "$RUN_DIR/fast_tag_cell_mapping_guardrail.rpt"
head -100 "$RUN_DIR/reports/fast_tag_cell_mapping.csv"
cat "$RUN_DIR/reports/control_drv_root_causes.csv" 2>/dev/null || true
cat "$RUN_DIR/reports/drv_transition_root_causes.csv" 2>/dev/null || true
```

## Required Knobs

Expected in `final_typical_genus_repair_1.rpt`:

- `STRONG_CONTROL_DRV=1`
- `CONTROL_CELL_BIAS_STAGE=post_map_only`
- `CONTROL_CELL_BIAS_APPLIED=0` during `pre_generic`
- `CONTROL_CELL_BIAS_APPLIED=1` during `post_map_pre_opt`
- `CONTROL_AVOID_INHDX8=0`
- `STRONG_FAST_TAG_FLOPS=0`
- `NFAST_CAPTURE_PATH_DONT_TOUCH_RELEASE=SKIPPED_PRESERVE_PD_FABRIC`
- `DESIGN_SET_MAX_FANOUT_FOR_DRV_REPAIR=SKIPPED_TARGETED_NETS_ONLY`
- `DESIGN_SET_MAX_TRANSITION_FOR_DRV_REPAIR=SKIPPED_TARGETED_NETS_ONLY`

Expected in `SUMMARY.md`:

- `FAST_TAG_FLOP_BIAS_MODE: DISABLED`
- `FAST_TAG_MAPPING_PARSE_STATUS: PASS`
- no `DFRRQHDX0` top fast-tag source mapping
- no `UNKNOWN` top fast-tag source mapping

## Expected Result

Best useful result:

- setup WNS near guarded baseline, around `-3.5 ps`
- setup TNS near guarded baseline, around `-77 ps`
- setup violations near guarded baseline, around `42`
- DRV max transition `0`
- max cap `0`
- max fanout `0`
- report helpers `PASS`
- SDC command failures `0`
- PD Vernier exception `PASS`

If timing remains around `-20 ps` or worse, even late control-cell bias is too
broad and the next repair should target only the actual DRV root reported in
`control_drv_root_causes.csv`.

If DRV returns but timing is near the guarded baseline, the next repair is an
exact source-strength or buffer-tree change for the reported high-fanout
control net only.
