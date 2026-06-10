# Server Run Request - Final Typical Genus JIHD Tap0 Micro

Run this on the lab server from:

`/home/validmgr/ksabra/2026_SPAD/SPADMIC`

Branch:

`SPADMIC_FINAL`

## Purpose

Close the remaining typical-only Genus setup residue from:

`final_typical_genus_control_exact_only_jihd_20260610_165235`

That run is clean for O13/RO/PD exception checks and DRV, with only a small
real setup residue:

- WNS/TNS: `-1.4 ps` / `-15.6 ps`
- setup violations: `12`
- family: `FAST_TAG_TO_PD_TS`
- group: `clk_osc_fast_buf_tap0`
- source bits: `tag_o_reg[5]`, `tag_o_reg[6]`
- endpoint column: `gen_pd_col[0]`
- endpoint bits: `nfast_hit_latched_reg[5]`, `nfast_hit_latched_reg[6]`

This is typical-only closure for the tapeout package. It is not MMMC signoff.

## Enabled Repair

The wrapper owns the JIHD standard-cell environment and enables only exact
tap0 data-path pressure:

- `MPTDC_STDCELL_FAMILY=JIHD`
- `MPTDC_GENUS_REPAIR_FAST_TAG_PD=1`
- `MPTDC_GENUS_REPAIR_DRV_TRANSITION=0`
- `MPTDC_FAST_TAG_REPAIR_EXACT_DATA_PATHS=1`
- `MPTDC_FAST_TAG_REPAIR_EXACT_TAPS=0`
- `MPTDC_FAST_TAG_REPAIR_EXACT_BITS="5 6"`
- `MPTDC_FAST_TAG_REPAIR_EXACT_MAX_FANOUT=4`
- `MPTDC_FAST_TAG_REPAIR_EXACT_MAX_TRANSITION_NS=0.35`

Disabled:

- broad fast-tag Q constraints
- broad control-net repair
- exact control-root repair
- strong fast-tag flop bias
- strong control driver bias
- preserve relaxation
- design-wide DRV pressure
- timing exceptions or false paths for `FAST_TAG_TO_PD_TS`

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
unset MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS
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

RUN_ID=final_typical_genus_jihd_tap0_micro_$(date +%Y%m%d_%H%M%S)

MPTDC_WORK_ROOT=work \
MPTDC_RO_SOURCE_LEF_PATH="$SRC_LEF" \
O1_RO_LEF_PATH="$DST_LEF" \
O1_RO_LIBERTY_PATH="$PWD/MPTDC/syn/macros/RO_tune4_real_abstract_shell.lib" \
bash MPTDC/syn/scripts/server_run_genus_mptdc_final_typical_jihd_tap0_micro.sh "$RUN_ID" \
  2>&1 | tee "work/logs/${RUN_ID}.console.log"

RUN_DIR="work/genus/$RUN_ID"

sed -n '1,440p' "$RUN_DIR/SUMMARY.md"
cat "$RUN_DIR/run_manifest.txt"
cat "$RUN_DIR/reports/synthesis/post_synthesis/run_manifest.rpt" 2>/dev/null || true
cat "$RUN_DIR/final_typical_genus_repair_1.rpt"
cat "$RUN_DIR/report_helpers_status.rpt"
cat "$RUN_DIR/summary_parser_check.rpt"
cat "$RUN_DIR/fast_tag_cell_mapping_guardrail.rpt"
sed -n '1,180p' "$RUN_DIR/final_genus_fast_tag_to_pd_ts_analysis.md"
awk -F, 'NR==1 || ($6=="nfast_hit_endpoint" && $7=="YES")' \
  "$RUN_DIR/reports/fast_tag_cell_mapping.csv" | sort -u
cat "$RUN_DIR/reports/control_drv_root_causes.csv" 2>/dev/null || true
cat "$RUN_DIR/reports/drv_transition_root_causes.csv" 2>/dev/null || true
```

## Expected Repair Report Markers

The repair report should show:

```text
DRV_TRANSITION_REPAIR=0
EXACT_CONTROL_ROOT_REPAIR=0
FAST_TAG_APPLY_Q_CONSTRAINTS=0
CONTROL_APPLY_BROAD_NETS=0
FAST_TAG_EXACT_DATA_PATHS=1
FAST_TAG_EXACT_TAPS=0
FAST_TAG_EXACT_BITS=5,6
FAST_TAG_EXACT_SOURCE_Q_PINS=2
FAST_TAG_EXACT_SOURCE_C_PINS=2
FAST_TAG_EXACT_ENDPOINT_D_PINS=16
FAST_TAG_EXACT_Q_SET_MAX_FANOUT=OK
FAST_TAG_EXACT_Q_SET_MAX_TRANSITION=OK
FAST_TAG_EXACT_D_SET_MAX_TRANSITION=OK
```

## Pass Criteria

- Genus exit code `0`
- report helpers `PASS`
- SDC failures `0`
- RO audit and macro binding clean
- PD Vernier exception applied with `64` paths and `8` sources
- `UNKNOWN_REVIEW_REQUIRED=0`
- `FAST_TAG_MAPPING_STATUS=PASS`
- setup WNS `>= 0 ps`
- setup TNS `0 ps`
- setup violating paths `0`
- max transition/cap/fanout `0 / 0 / 0`

If these pass, proceed to `MPTDC_FINAL_TYPICAL_INNOVUS_FEASIBILITY`.
