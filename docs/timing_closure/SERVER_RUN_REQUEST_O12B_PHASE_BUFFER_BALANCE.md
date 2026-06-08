# Server Run Request: O12B Phase Buffer Balance

This is not signoff.  This is a report-only O12B feasibility/debug run that
restores an existing O12 route checkpoint and quantifies phase-buffer balance.

## Checkout

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only
git status --short
git rev-parse HEAD
git log --oneline -10
```

## Validate Wrapper

```bash
EXPECTED_HEAD=$(git rev-parse HEAD)

MPTDC_O12B_VALIDATE_ONLY=1 \
EXPECTED_HEAD=$EXPECTED_HEAD \
bash MPTDC/pnr/scripts/server_run_innovus_o12b_phase_buffer_balance.sh \
  20260608_o12b_phase_buffer_balance_validate
```

## Report-Only Balance Run

Use the latest usable O12 PNR checkpoint unless a newer clean O12 route run is
available:

```bash
EXPECTED_HEAD=$(git rev-parse HEAD)
O12_PNR_RUN=20260608_o12_phase_buffer_pnr_abs1

EXPECTED_HEAD=$EXPECTED_HEAD \
MPTDC_O12B_SOURCE_RUN_ID=$O12_PNR_RUN \
bash MPTDC/pnr/scripts/server_run_innovus_o12b_phase_buffer_balance.sh \
  20260608_o12b_phase_buffer_balance_abs2
```

## Review Commands

```bash
RUN=20260608_o12b_phase_buffer_balance_abs2
R=results/innovus/$RUN/reports

sed -n '1,180p' results/innovus/$RUN/SUMMARY.md
sed -n '1,220p' $R/phase_buffer_balance_summary.md
sed -n '1,160p' $R/phase_buffer_placement_summary.md
column -s, -t < $R/ro_phase_raw_pin_loads.csv | sed -n '1,24p'
column -s, -t < $R/phase_buffer_output_loads.csv | sed -n '1,24p'
column -s, -t < $R/phase_buffer_topology.csv | sed -n '1,24p'
column -s, -t < $R/phase_buffer_placement.csv | sed -n '1,24p'
column -s, -t < $R/phase_buffer_route_summary.csv | sed -n '1,24p'
sed -n '1,220p' $R/phase_buffer_db_attribute_probe.rpt
ls -1 $R/net_debug_*_buf.rpt | sed -n '1,20p'
```

## Pass Indicators

Expected O12B indicators:

- `RAW_RO_LOAD_FIXED=YES`
- `BUFFER_OUTPUT_LOAD_QUANTIFIED=YES`
- `TOPOLOGY_MATCHED=YES`
- `PLACEMENT_QUANTIFIED=YES`
- `TIMING_DECISION_QUALITY=YES`
- 16 `TOPOLOGY_MATCH` rows
- 16 raw RO fanout-1 rows
- no raw RO `CRITICAL` rows

If `BUFFER_OUTPUT_LOAD_QUANTIFIED=NO`, keep O12 as promising but do not make a
BUHDX4/BUHDX6/BUHDX8 decision until numeric buffer-output cap/transition data is
available.

If Innovus returns `139`, check:

```bash
cat results/innovus/$RUN/manifests/current_stage.txt
cat results/innovus/$RUN/manifests/innovus_exit_classification.txt
sed -n '1,220p' results/innovus/$RUN/REQUIRED_OUTPUTS_CHECK_FAILED.txt
```
