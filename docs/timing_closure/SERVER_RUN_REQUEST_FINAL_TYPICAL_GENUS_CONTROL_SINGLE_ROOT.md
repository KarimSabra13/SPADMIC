# Server Run Request: Final Typical Genus Single Control Root

Purpose: test the narrowest DRV repair that should preserve the guarded timing
baseline. This mode excludes reset/epoch roots and targets only the known local
PD-control root driver class from the guarded/control-root evidence.

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
unset MPTDC_CONTROL_REPAIR_EXACT_DRIVER_REGEX
unset MPTDC_CONTROL_REPAIR_EXACT_NET_REGEX

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

RUN_ID=final_typical_genus_control_single_root_$(date +%Y%m%d_%H%M%S)

MPTDC_WORK_ROOT=work \
MPTDC_RO_SOURCE_LEF_PATH="$SRC_LEF" \
O1_RO_LEF_PATH="$DST_LEF" \
O1_RO_LIBERTY_PATH="$PWD/MPTDC/syn/macros/RO_tune4_real_abstract_shell.lib" \
bash MPTDC/syn/scripts/server_run_genus_mptdc_final_typical_control_single_root.sh "$RUN_ID" \
  2>&1 | tee "work/logs/${RUN_ID}.console.log"

RUN_DIR="work/genus/$RUN_ID"

sed -n '1,360p' "$RUN_DIR/SUMMARY.md"
cat "$RUN_DIR/final_typical_genus_repair_1.rpt"
cat "$RUN_DIR/report_helpers_status.rpt"
cat "$RUN_DIR/summary_parser_check.rpt"
cat "$RUN_DIR/fast_tag_cell_mapping_guardrail.rpt"
head -120 "$RUN_DIR/reports/fast_tag_cell_mapping.csv"
cat "$RUN_DIR/reports/control_drv_root_causes.csv" 2>/dev/null || true
cat "$RUN_DIR/reports/drv_transition_root_causes.csv" 2>/dev/null || true
```

## Required Knobs

- `STRONG_CONTROL_DRV=0`
- `CONTROL_CELL_BIAS_STAGE=none`
- `EXACT_CONTROL_ROOT_REPAIR=1`
- `EXACT_CONTROL_ROOT_MIN_FANOUT=64`
- `EXACT_CONTROL_ROOT_REQUIRE_PD_SINKS=1`
- `EXACT_CONTROL_ROOT_ALLOW_RESET_ROOTS=0`
- `EXACT_CONTROL_ROOT_DRIVER_REGEX=(^|/)g33116/Q$`
- `EXACT_CONTROL_ROOT_MAX_ROOTS=1`
- `STRONG_FAST_TAG_FLOPS=0`
- `MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE=0`
- `MPTDC_GENUS_REPAIR_APPLY_DESIGN_DRV=0`

## Expected Result

Useful pass for this experiment:

- selected exact root count is one;
- selected root is the `g33116/Q` local PD-control root class;
- timing returns near the guarded baseline:
  - setup WNS around `-3.5 ps`
  - setup TNS around `-77 ps`
  - setup violations around `42`
- DRV remains `0 / 0 / 0`;
- report helpers `PASS`;
- SDC failures `0`;
- fast-tag mapping parse `PASS`.

If DRV returns, the single-root repair is too narrow; inspect
`control_drv_root_causes.csv` and add only the actual reported offender. If
timing remains near `-14 ps`, the exact control constraint itself is affecting
fast-path mapping and the DRV fix should move to a post-report ECO-style buffer
or explicit net repair rather than synthesis pressure.
