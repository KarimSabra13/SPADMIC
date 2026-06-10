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

## Residual-Pressure Update

The first repair run `final_typical_genus_repair_1_20260610_134332` proved the
parser and O13 checks but still had:

- setup WNS/TNS: `-3.5 ps` / `-77.1 ps`
- setup violating paths: `42`
- worst family: `FAST_TAG_TO_PD_TS`
- max transition violations: `1015`, rooted at one `INHDX8`-driven PD control
  net with `511 ps` transition against the `500 ps` limit
- report helper failures: `1`, caused by a generic PD hotspot helper using
  broad `u_pd` cell patterns instead of endpoint-register patterns

The first stronger pressure run, `final_typical_genus_repair_pressure_20260610_141642`,
regressed badly:

- setup WNS/TNS became `-91.7 ps` / `-37024.9 ps`;
- setup violating paths became `512`;
- worst family moved to `PD_HIT_LATCH_LOCAL_FAST`;
- max-transition violations became `3505`.

Root cause: the pressure mode was too broad. It injected
`MPTDC_RELAX_FAST_TAG_PRESERVE`, released 512 PD/nfast capture cells, applied a
design-level `0.45 ns` max-transition target, and avoided strong inverter
candidates together with weak ones. That changed the local PD fast-domain
implementation instead of only nudging the original fast-tag source path.

The corrected wrapper is conservative again:

- no automatic `MPTDC_RELAX_FAST_TAG_PRESERVE` filelist define;
- no broad PD capture fabric preserve release;
- no design-wide DRV pressure by default;
- fast-tag Q pressure defaults to fanout `16` and transition `0.50 ns`;
- control-net pressure defaults to fanout `16` and transition `0.50 ns`;
- strong flop/inverter avoidance is opt-in, not default.

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
