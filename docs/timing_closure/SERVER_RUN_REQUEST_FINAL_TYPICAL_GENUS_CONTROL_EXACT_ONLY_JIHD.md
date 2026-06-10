# Server Run Request - Final Typical Genus Control Exact Only JIHD

Run this on the lab server from:

`/home/validmgr/ksabra/2026_SPAD/SPADMIC`

Branch:

`SPADMIC_FINAL`

Expected HEAD after pull should include this change:

`MPTDC/syn/scripts/server_run_genus_mptdc_final_typical_control_exact_only_jihd.sh`

## Purpose

Run a fresh typical-only Genus experiment with the `D_CELLS_JIHD` 1.8 V
standard-cell sublibrary.

This keeps the latest exact-only DRV isolation knobs and changes only the
digital standard-cell library selection:

- `D_CELLS_HD` -> `D_CELLS_JIHD`
- typical Liberty -> `D_CELLS_JIHD_LPMOS_typ_1_80V_25C.lib`
- standard-cell LEF -> `xh018_D_CELLS_JIHD.lef`

This is not MMMC signoff and not final silicon signoff.

## Expected Knobs

- `MPTDC_STDCELL_FAMILY=JIHD`
- `SC_ROOT=/eda/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0`
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

unset MPTDC_STDCELL_FAMILY
unset SC_ROOT
unset MPTDC_STDCELL_LEF
unset MPTDC_STDCELL_TC_LIB

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

RUN_ID=final_typical_genus_control_exact_only_jihd_$(date +%Y%m%d_%H%M%S)

MPTDC_WORK_ROOT=work \
MPTDC_RO_SOURCE_LEF_PATH="$SRC_LEF" \
O1_RO_LEF_PATH="$DST_LEF" \
O1_RO_LIBERTY_PATH="$PWD/MPTDC/syn/macros/RO_tune4_real_abstract_shell.lib" \
bash MPTDC/syn/scripts/server_run_genus_mptdc_final_typical_control_exact_only_jihd.sh "$RUN_ID" \
  2>&1 | tee "work/logs/${RUN_ID}.console.log"

RUN_DIR="work/genus/$RUN_ID"

sed -n '1,400p' "$RUN_DIR/SUMMARY.md"
cat "$RUN_DIR/run_manifest.txt"
cat "$RUN_DIR/reports/synthesis/post_synthesis/run_manifest.rpt" 2>/dev/null || true
cat "$RUN_DIR/final_typical_genus_repair_1.rpt"
cat "$RUN_DIR/report_helpers_status.rpt"
cat "$RUN_DIR/summary_parser_check.rpt"
cat "$RUN_DIR/fast_tag_cell_mapping_guardrail.rpt"
head -120 "$RUN_DIR/reports/fast_tag_cell_mapping.csv"
cat "$RUN_DIR/reports/control_drv_root_causes.csv" 2>/dev/null || true
cat "$RUN_DIR/reports/drv_transition_root_causes.csv" 2>/dev/null || true
```

## Required Evidence

The JIHD wrapper owns the standard-cell environment. The run manifest must
show:

```text
STDCELL_FAMILY=JIHD
STDCELL_LEF=<real xh018_D_CELLS_JIHD.lef path discovered by the wrapper>
STDCELL_TC_LIB=/eda/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/liberty_LPMOS/v6_0_0/PVT_1_80V_range/D_CELLS_JIHD_LPMOS_typ_1_80V_25C.lib
```

The repair report should still show:

```text
EXACT_CONTROL_ROOT_NETS=1
FAST_TAG_Q_SET_MAX_FANOUT=SKIPPED_FAST_TAG_Q_CONSTRAINTS_DISABLED
FAST_TAG_Q_SET_MAX_TRANSITION=SKIPPED_FAST_TAG_Q_CONSTRAINTS_DISABLED
CONTROL_REPAIR_NETS=SKIPPED_BROAD_CONTROL_NETS_DISABLED
```

## Decision

If JIHD keeps O13/RO/PD checks clean and improves setup timing, continue from
the JIHD result.

If JIHD keeps DRV clean but setup remains negative, re-plan the narrow
`FAST_TAG_TO_PD_TS` repair using JIHD mapping evidence.

If JIHD breaks DRV, repair only the reported JIHD root from
`control_drv_root_causes.csv`; do not re-enable broad control-cell bias.
