# Server Run Request - Final Typical Genus Control Exact Only

Run this on the lab server from:

`/home/validmgr/ksabra/2026_SPAD/SPADMIC`

Branch:

`SPADMIC_FINAL`

Expected HEAD after pull should include:

`0e32ed1b5d9240084f385122aff74cecc2e0fb62`

## Purpose

Run `MPTDC_FINAL_TYPICAL_GENUS_REPAIR_CONTROL_EXACT_ONLY`.

This is the true isolation run after
`final_typical_genus_control_single_root_20260610_161411`. The single-root
selector worked, but that run still applied broad control-net constraints to
`130` nets and applied fast-tag Q fanout/transition constraints. This wrapper
disables both of those pressures.

## Expected Knobs

- `MPTDC_GENUS_REPAIR_EXACT_CONTROL_ROOTS=1`
- `MPTDC_CONTROL_REPAIR_EXACT_REQUIRE_PD_SINKS=1`
- `MPTDC_CONTROL_REPAIR_EXACT_ALLOW_RESET_ROOTS=0`
- `MPTDC_CONTROL_REPAIR_EXACT_DRIVER_REGEX=(^|/)g33116/Q$`
- `MPTDC_CONTROL_REPAIR_EXACT_MAX_ROOTS=1`
- `MPTDC_GENUS_REPAIR_APPLY_BROAD_CONTROL_NETS=0`
- `MPTDC_FAST_TAG_REPAIR_APPLY_Q_CONSTRAINTS=0`
- `MPTDC_GENUS_REPAIR_STRONG_CONTROL_DRV=0`
- `MPTDC_GENUS_REPAIR_STRONG_FAST_TAG_FLOPS=0`
- `MPTDC_GENUS_REPAIR_APPLY_DESIGN_DRV=0`
- `MPTDC_GENUS_RELAX_FAST_TAG_PRESERVE=0`

## Commands

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC

git checkout SPADMIC_FINAL
git pull --ff-only
git rev-parse HEAD

unset MPTDC_GENUS_REPAIR_STRONG_FAST_TAG_FLOPS
unset MPTDC_GENUS_REPAIR_STRONG_CONTROL_DRV
unset MPTDC_GENUS_REPAIR_CONTROL_CELL_BIAS_STAGE
unset MPTDC_GENUS_REPAIR_CONTROL_AVOID_INHDX8
unset MPTDC_GENUS_REPAIR_APPLY_BROAD_CONTROL_NETS
unset MPTDC_FAST_TAG_REPAIR_APPLY_Q_CONSTRAINTS
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

RUN_ID=final_typical_genus_control_exact_only_$(date +%Y%m%d_%H%M%S)

MPTDC_WORK_ROOT=work \
MPTDC_RO_SOURCE_LEF_PATH="$SRC_LEF" \
O1_RO_LEF_PATH="$DST_LEF" \
O1_RO_LIBERTY_PATH="$PWD/MPTDC/syn/macros/RO_tune4_real_abstract_shell.lib" \
bash MPTDC/syn/scripts/server_run_genus_mptdc_final_typical_control_exact_only.sh "$RUN_ID" \
  2>&1 | tee "work/logs/${RUN_ID}.console.log"

RUN_DIR="work/genus/$RUN_ID"

sed -n '1,380p' "$RUN_DIR/SUMMARY.md"
cat "$RUN_DIR/final_typical_genus_repair_1.rpt"
cat "$RUN_DIR/report_helpers_status.rpt"
cat "$RUN_DIR/summary_parser_check.rpt"
cat "$RUN_DIR/fast_tag_cell_mapping_guardrail.rpt"
head -120 "$RUN_DIR/reports/fast_tag_cell_mapping.csv"
cat "$RUN_DIR/reports/control_drv_root_causes.csv" 2>/dev/null || true
cat "$RUN_DIR/reports/drv_transition_root_causes.csv" 2>/dev/null || true
```

## Expected Result

The key repair report signatures should be:

```text
EXACT_CONTROL_ROOT_NETS=1
EXACT_CONTROL_ROOT_NET=n_6899 fanout=64 driver=g33116/Q pd_sinks=64 reset_sinks=0
FAST_TAG_Q_SET_MAX_FANOUT=SKIPPED_FAST_TAG_Q_CONSTRAINTS_DISABLED
FAST_TAG_Q_SET_MAX_TRANSITION=SKIPPED_FAST_TAG_Q_CONSTRAINTS_DISABLED
CONTROL_REPAIR_NETS=SKIPPED_BROAD_CONTROL_NETS_DISABLED
CONTROL_SET_MAX_FANOUT=SKIPPED_BROAD_CONTROL_NETS_DISABLED
CONTROL_SET_MAX_TRANSITION=SKIPPED_BROAD_CONTROL_NETS_DISABLED
```

Target outcome:

- setup WNS returns near the guarded baseline, around `-3.5 ps`
- setup TNS returns near `-77 ps`
- setup path count remains around `42`
- DRV remains `0 / 0 / 0`
- report helpers remain `PASS`
- SDC failures remain `0`

If timing returns near baseline but DRV returns, add only the new reported DRV
root from `reports/control_drv_root_causes.csv`. If timing remains near
`-14.5 ps`, the exact control constraint itself is perturbing fast mapping and
the next DRV repair should be an ECO-style buffer/source-strength experiment
rather than more synthesis pressure.
