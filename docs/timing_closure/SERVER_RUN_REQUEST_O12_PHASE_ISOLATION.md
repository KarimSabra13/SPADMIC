# Server Run Request: O12 Phase Isolation Buffer Experiment

This is not signoff.  This is a TC-only physical feasibility experiment to
reduce direct `RO_tune4/S[0:7]` load.

## Checkout

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only
```

## Step 1: Validate Wrappers

```bash
MPTDC_O12_VALIDATE_ONLY=1 \
bash MPTDC/syn/scripts/server_run_genus_o12_phase_isolation.sh \
  20260608_o12_phase_iso_validate

MPTDC_O12_VALIDATE_ONLY=1 \
bash MPTDC/pnr/scripts/server_run_innovus_o12_phase_buffer_analysis.sh \
  20260608_o12_phase_buf_validate
```

## Step 2: Genus O12 Typical

```bash
EXPECTED_HEAD=$(git rev-parse HEAD) \
bash MPTDC/syn/scripts/server_run_genus_o12_phase_isolation.sh \
  20260608_o12_phase_isolation_genus
```

Review:

```bash
sed -n '1,180p' results/genus_osc_pd/20260608_o12_phase_isolation_genus/SUMMARY.md
sed -n '1,160p' results/genus_osc_pd/20260608_o12_phase_isolation_genus/o12_phase_isolation_check.rpt
```

Required Genus indicators:

- `O12_STATUS=O12_NETLIST_CANDIDATE`
- `RO_tune4 instance count: 2`
- `mptdc_osc_stub residue count: 0`
- `BUHDX4 phase-buffer instance count: 16` or more if the tool clones only
  after preserving the expected base cells.
- packet format unchanged
- `raw_lfsr_tag` unchanged

## Step 3: Innovus O12 PNR Feasibility

Use the existing O10.2 route wrapper with O12 netlist and O12 Innovus SDC
overlay:

```bash
O12_GENUS_RUN=20260608_o12_phase_isolation_genus
O12_PNR_RUN=20260608_o12_phase_buffer_pnr

EXPECTED_HEAD=$(git rev-parse HEAD) \
MPTDC_O10_NETLIST=results/genus_osc_pd/${O12_GENUS_RUN}/mptdc_top_asic.postsyn.v \
MPTDC_O10_POSTSYN_SDC=results/genus_osc_pd/${O12_GENUS_RUN}/mptdc_top_asic.postsyn.sdc \
MPTDC_O10_SDC_OVERLAY=MPTDC/pnr/constraints/mptdc_osc_typical_r750_delta5_o12_phase_buffers_innovus.sdc \
MPTDC_O10_2_MODE=route_feasibility \
bash MPTDC/pnr/scripts/server_run_innovus_o10_2_pnr_repair.sh \
  ${O12_PNR_RUN}
```

Review:

```bash
sed -n '1,180p' results/innovus/${O12_PNR_RUN}/SUMMARY.md
sed -n '1,160p' results/innovus/${O12_PNR_RUN}/reports/drv_max_cap.rpt
```

## Step 4: O12 Raw/Buffer Load Report

```bash
O12_PNR_RUN=20260608_o12_phase_buffer_pnr

EXPECTED_HEAD=$(git rev-parse HEAD) \
MPTDC_O12_SOURCE_RUN_ID=${O12_PNR_RUN} \
bash MPTDC/pnr/scripts/server_run_innovus_o12_phase_buffer_analysis.sh \
  20260608_o12_phase_buffer_analysis
```

Review:

```bash
RUN=20260608_o12_phase_buffer_analysis
R=results/innovus/$RUN/reports

sed -n '1,160p' results/innovus/$RUN/SUMMARY.md
sed -n '1,180p' $R/phase_buffer_balance_summary.md
sed -n '1,40p' $R/ro_phase_raw_pin_loads.csv
sed -n '1,40p' $R/phase_buffer_output_loads.csv
```

## Expected O12 Outcome

Pass target:

- raw `RO_tune4/S[n]` load <= 58.72 fF preferred;
- raw `RO_tune4/S[n]` load <= 75.59 fF acceptable;
- no raw RO `CRITICAL` rows.

Because the RO shell still has a 50 fF `S` max-cap limit, a matched raw RO row
with no entry in `drv_max_cap.rpt` is bounded below both analog budgets.  Exact
numeric cap is still preferred if Innovus exposes an all-net cap report.

Do not call this signoff.  If O12 fails due to mismatch, power, or buffer output
load, evaluate RTL load reduction instead of relaxing the RO shell.
