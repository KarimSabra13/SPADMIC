# O11 RO Phase Load Analysis

## Objective

O11 is a report-only load analysis run.  It restores the routed O10.2 Innovus checkpoint and measures each RO_tune4 `S[n]` load from the source pin outward.  It does not reroute, change RTL, change constraints, or relax Liberty.

## Source Run

Default source run:

```bash
results/innovus/20260604_o10_2_pnr_repair
```

Default checkpoint:

```bash
results/innovus/20260604_o10_2_pnr_repair/checkpoints/04_route.enc.dat
```

## Reports

O11 writes these files under `results/innovus/<run_id>/reports`:

- `phase_net_loads.csv`: one row per slow/fast RO source pin with fanout, cap, sink counts, and budget label.
- `phase_net_load_budget_summary.md`: budget thresholds, row counts, max measured load, and label histogram.
- `fast_tag_loads.csv`: fast RO tap loads with explicit fast-tag clock sink counts.
- `ro_phase_sink_classification.csv`: one row per sink pin reached from each RO source pin.
- `drv_max_cap.rpt`: restored checkpoint max-cap report for cross-checking source-pin loads.

## Sink Interpretation

Static RTL and netlist review predict these dominant classes:

- Fast RO taps drive PD `fast_phase` clock-like pins and one local fast-tag generator clock per column.
- Slow RO taps drive PD `slow_phase` data pins.
- Slow `S[0]` has extra epoch and boundary metadata load.

The O11 sink classification CSV verifies whether the routed checkpoint matches that expectation.

## Local Validation

```bash
bash -n MPTDC/pnr/scripts/server_run_innovus_o11_ro_load_analysis.sh
MPTDC_O11_VALIDATE_ONLY=1 bash MPTDC/pnr/scripts/server_run_innovus_o11_ro_load_analysis.sh 20260608_o11_ro_load_validate
```

`validate_only` checks wrapper inputs, Tcl sourceability, budget labels, and exact source-pin candidate generation.  It does not launch Innovus.

## Server Run

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only
EXPECTED_HEAD=$(git rev-parse HEAD) \
MPTDC_O11_SOURCE_RUN_ID=20260604_o10_2_pnr_repair \
bash MPTDC/pnr/scripts/server_run_innovus_o11_ro_load_analysis.sh 20260608_o11_ro_load_analysis
```

The wrapper fails the report-only run if required CSVs are missing, contain `ERROR`, or contain placeholder markers such as `NO_SOURCE_PIN_MATCH` or `NO_NET_FROM_PIN`.

## Decision Gate

Do not start Phase B cleanup until O11 has answered two questions:

1. Which sink classes explain the apparent `500-700 fF` RO output loads?
2. Are the loads dominated by unavoidable clock-like PD/tag sinks, avoidable metadata load, routing geometry, or a reporting-unit/object mismatch?
