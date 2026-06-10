# Server Run Request: Final Typical Genus Repair 1

Run this on the lab server from the `SPADMIC_FINAL` branch. This is typical-only
Genus closure repair, not MMMC and not final silicon signoff.

## Command Block

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC

git checkout SPADMIC_FINAL
git pull --ff-only

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

RUN_ID=final_typical_genus_repair_1_$(date +%Y%m%d_%H%M%S)

MPTDC_WORK_ROOT=work \
MPTDC_RO_SOURCE_LEF_PATH="$SRC_LEF" \
O1_RO_LEF_PATH="$DST_LEF" \
O1_RO_LIBERTY_PATH="$PWD/MPTDC/syn/macros/RO_tune4_real_abstract_shell.lib" \
bash MPTDC/syn/scripts/server_run_genus_mptdc_final_typical_repair.sh "$RUN_ID" \
  2>&1 | tee "work/logs/${RUN_ID}.console.log"

RUN_DIR="work/genus/$RUN_ID"

sed -n '1,280p' "$RUN_DIR/SUMMARY.md"
cat "$RUN_DIR/o13_phase_distribution_check.rpt"
cat "$RUN_DIR/summary_parser_check.rpt"
cat "$RUN_DIR/reports/ro_tune4_lef_audit.rpt"
cat "$RUN_DIR/reports/drv_transition_root_causes.csv" 2>/dev/null || true
cat "$RUN_DIR/report_helpers_status.rpt" 2>/dev/null || true
cat "$RUN_DIR/helper_tcl_selftest.rpt" 2>/dev/null || true
```

## Expected Good Result

Functional and structural:

- Genus exit code: `0`
- netlist, SDC, SDF, DB exported
- `RO_tune4` count: `2`
- `mptdc_osc_stub` count: `0`
- packet unchanged: `YES`
- `raw_lfsr_tag` unchanged: `YES`
- RO audit: `PASS`
- raw RO clocks: `16`
- buffered phase clocks: `16`
- PD Vernier exception: `PASS`
- `UNKNOWN_REVIEW_REQUIRED`: `0`

Timing:

- setup WNS: `>= 0 ps`
- setup TNS: `0 ps`
- setup violating paths: `0`
- no real local fast-domain violations

DRV:

- max transition violations: `0`
- max capacitance violations: `0`
- max fanout violations: `0`

Reports:

- report helper failures: `0`
- SDC command failures: `0`
- `SUMMARY.md` agrees with raw timing reports

Only then should the wrapper say:

`READY_FOR_O13_INNOVUS_FEASIBILITY=YES`

If timing is around `-3 ps` to `-10 ps` with clean reports and clean DRV, mark
it `NEAR_CLEAN`, not pass. If any DRV remains, keep `REVIEW_REQUIRED`.
