# Server Run Request: Final Typical Genus Control Root

Purpose: isolate the high-fanout control-net DRV repair without broad
control-cell bias, fast-tag flop bias, preserve relaxation, design-wide DRV
pressure, or RTL changes.

This is a typical-only Genus closure experiment. It is not MMMC and not final
silicon signoff.

## Command

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC

git checkout SPADMIC_FINAL
git pull --ff-only
git rev-parse HEAD

unset MPTDC_GENUS_REPAIR_STRONG_FAST_TAG_FLOPS
unset MPTDC_GENUS_REPAIR_STRONG_CONTROL_DRV
unset MPTDC_GENUS_REPAIR_CONTROL_CELL_BIAS_STAGE
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

RUN_ID=final_typical_genus_control_root_$(date +%Y%m%d_%H%M%S)

MPTDC_WORK_ROOT=work \
MPTDC_RO_SOURCE_LEF_PATH="$SRC_LEF" \
O1_RO_LEF_PATH="$DST_LEF" \
O1_RO_LIBERTY_PATH="$PWD/MPTDC/syn/macros/RO_tune4_real_abstract_shell.lib" \
bash MPTDC/syn/scripts/server_run_genus_mptdc_final_typical_control_root.sh "$RUN_ID" \
  2>&1 | tee "work/logs/${RUN_ID}.console.log"

RUN_DIR="work/genus/$RUN_ID"

sed -n '1,340p' "$RUN_DIR/SUMMARY.md"
cat "$RUN_DIR/final_typical_genus_repair_1.rpt"
cat "$RUN_DIR/report_helpers_status.rpt"
cat "$RUN_DIR/summary_parser_check.rpt"
cat "$RUN_DIR/fast_tag_cell_mapping_guardrail.rpt"
head -120 "$RUN_DIR/reports/fast_tag_cell_mapping.csv"
cat "$RUN_DIR/reports/control_drv_root_causes.csv" 2>/dev/null || true
cat "$RUN_DIR/reports/drv_transition_root_causes.csv" 2>/dev/null || true
```

## Expected Knobs

- `STRONG_CONTROL_DRV=0`
- `CONTROL_CELL_BIAS_STAGE=none`
- `EXACT_CONTROL_ROOT_REPAIR=1`
- `EXACT_CONTROL_ROOT_MIN_FANOUT=64`
- `STRONG_FAST_TAG_FLOPS=0`
- `MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE=0`
- `MPTDC_GENUS_REPAIR_APPLY_DESIGN_DRV=0`

## Expected Result

Useful pass for this experiment:

- timing near the guarded baseline:
  - setup WNS around `-3.5 ps`
  - setup TNS around `-77 ps`
  - setup violations around `42`
- DRV `0 / 0 / 0`, or a single exact root reported for follow-up;
- report helpers `PASS`;
- SDC failures `0`;
- `FAST_TAG_MAPPING_PARSE_STATUS=PASS`.

If timing remains around `-20 ps`, this mode is still perturbing fast-domain
mapping and must be debugged before setup repair. If timing returns to the
guarded baseline but DRV returns, refine exact-root selection from
`control_drv_root_causes.csv`.
