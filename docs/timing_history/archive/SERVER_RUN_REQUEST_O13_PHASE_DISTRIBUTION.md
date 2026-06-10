# Server Run Request: O13 Phase Distribution

REPORT_STATUS=READY_FOR_SERVER

This is a feasibility/debug request, not signoff.  Do not run characterization yet.

## Goal

Measure whether a two-stage phase-distribution topology fixes the weak O12 digital phase drive while preserving the successful O12 raw RO isolation:

```text
RO_tune4/S[n]
  -> BUHDX4
  -> BUHDX12
  -> phase fabric
```

Packet format, `raw_lfsr_tag`, `nfast/nslow` widths, oscillator frequency, and PD behavior must remain unchanged.

## Step A: Genus O13

Run on the lab server:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
git checkout SPADMIC_localtag
git pull --ff-only
git status --short
git rev-parse HEAD

MPTDC_O13_VALIDATE_ONLY=1 \
bash MPTDC/syn/scripts/server_run_genus_o13_phase_distribution.sh \
  202606xx_o13_phase_distribution_genus

bash MPTDC/syn/scripts/server_run_genus_o13_phase_distribution.sh \
  202606xx_o13_phase_distribution_genus
```

Review:

```bash
cat results/genus_osc_pd/202606xx_o13_phase_distribution_genus/SUMMARY.md
cat results/genus_osc_pd/202606xx_o13_phase_distribution_genus/o13_phase_distribution_check.rpt
```

Required Genus checks:

- `RO_tune4` count is `2`.
- `mptdc_osc_stub` residue count is `0`.
- At least `16` `BUHDX4` instances.
- At least `16` `BUHDX12` instances.
- Packet format and `raw_lfsr_tag` remain unchanged.

## Step B: Innovus O13

Use the O13 Genus netlist/SDC in the existing P&R flow with this overlay:

```text
MPTDC/pnr/constraints/mptdc_osc_typical_r750_delta5_o13_phase_distribution_innovus.sdc
```

If using the existing O10.2 P&R wrapper as the route-feasibility engine, set the O13 inputs explicitly:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC

MPTDC_O10_NETLIST=results/genus_osc_pd/202606xx_o13_phase_distribution_genus/mptdc_top_asic.postsyn.v \
MPTDC_O10_POSTSYN_SDC=results/genus_osc_pd/202606xx_o13_phase_distribution_genus/mptdc_top_asic.postsyn.sdc \
MPTDC_O10_SDC_OVERLAY=MPTDC/pnr/constraints/mptdc_osc_typical_r750_delta5_o13_phase_distribution_innovus.sdc \
MPTDC_O10_2_MODE=route_feasibility \
bash MPTDC/pnr/scripts/server_run_innovus_o10_2_pnr_repair.sh \
  202606xx_o13_phase_distribution_pnr
```

Then run the O13 report-only checker on that routed checkpoint:

```bash
MPTDC_O13_SOURCE_RUN_ID=202606xx_o13_phase_distribution_pnr \
bash MPTDC/pnr/scripts/server_run_innovus_o13_phase_distribution.sh \
  202606xx_o13_phase_distribution_reports
```

## Optional Placement Hook

Before a fresh O13 placement/legalization run, source:

```text
MPTDC/pnr/scripts/innovus_o13_phase_buffer_place.tcl
```

Required origin variables:

```text
MPTDC_O13_SLOW_ISO_X/Y
MPTDC_O13_SLOW_DRV_X/Y
MPTDC_O13_FAST_ISO_X/Y
MPTDC_O13_FAST_DRV_X/Y
```

Start without the hook if exact coordinates are not known.  Use the first O13 report to choose row origins.

## Required O13 Reports

The O13 report command must produce:

- `reports/SUMMARY.md`
- `reports/ro_phase_raw_pin_loads.csv`
- `reports/phase_buffer_output_loads.csv`
- `reports/phase_buffer_balance_summary.md`
- `reports/phase_buffer_topology.csv`
- `reports/phase_buffer_topology_summary.md`
- `reports/phase_buffer_placement.csv`
- `reports/phase_buffer_placement_summary.md`
- `reports/phase_buffer_delay_estimate.csv`
- `reports/phase_buffer_route_summary.csv`
- `reports/ro_phase_sink_classification.csv`
- `reports/drv_max_cap.rpt`
- `reports/drv_max_transition.rpt`
- `reports/timing_post_route_ro_osc_domain.rpt`
- `reports/timing_post_route_summary_by_class.md`

## Decision Rules

- If raw RO load stays <= `58.72 fF` and final-driver transition improves below `0.5-0.75 ns`, keep O13 and proceed to placement matching.
- If final-driver transition remains > `0.75 ns`, consider a deeper balanced tree or per-branch distribution.  Do not silently size only one tap.
- If slow0 remains a large outlier, evaluate a documented slow0 PD/aux split next.
- If O13 creates unacceptable mismatch, timing, or power, then revisit RTL load reduction.

Do not run full characterization until O13 physical load, transition, timing, and placement health are reviewed.
