# MPTDC Innovus Estimate Flow

This directory contains the first-pass physical-estimation flow for the MPTDC macro. It is intended for area/timing/power exploration after a Genus run, not final signoff PnR.

## Baseline policy

- Technology: XFAB XH018, 1P4M / 4-metal HD baseline.
- Optimization goal: area-first.
- Default core utilization: `0.78`, with placement max density `0.82`.
- Default signal routing layers: `M1` through `M3`.
- Default NanoRoute routing layer indexes: `1` through `3` (`M1-M3` in the lab LEF).
- Default reserved power layer: `M4`, so top metal remains available for VDD/VSS straps and top-level power distribution as much as practical.
- Expected route directions: `M1` horizontal, `M2` vertical, `M3` horizontal, `M4` vertical. The technology LEF remains the source of truth; the run manifest records these expectations for review.

## Quick run

Run synthesis first:

```bash
cd MPTDC/syn/scripts
mkdir -p ../logs
genus -files genus.tcl -log ../logs/genus.log
```

Then run the Innovus estimate:

```bash
cd ../../pnr/scripts
mkdir -p ../logs
innovus -nowin -init innovus_estimate.tcl -log ../logs/innovus_estimate.log
```

The PnR flow uses `pnr/inputs/mptdc_innovus.mmmc`, an Innovus-compatible MMMC
file that consumes the Genus post-synthesis netlist and SDC. The Genus
`syn/inputs/mptdc.mmmc` remains the synthesis MMMC source of truth. Innovus uses
the XH018 cap-table files when present; if they are missing, the run must be
treated as a lower-accuracy RC estimate.

Useful overrides:

```bash
export MPTDC_PNR_CORE_UTIL=0.75
export MPTDC_PNR_MAX_DENSITY=0.80
export MPTDC_PNR_SIGNAL_TOP_LAYER=M3
export MPTDC_PNR_SIGNAL_TOP_LAYER_IDX=3
export MPTDC_PNR_POWER_LAYER=M4
export MPTDC_PNR_DO_DETAIL_ROUTE=1
```

Explicit standard-cell PG pin connection is disabled by default because the
current lab LEF/Liberty naming must be confirmed before applying
`globalNetConnect`. Enable it only after confirming the actual PG pin names:

```bash
export MPTDC_PNR_CONNECT_PG_PINS=1
```

Review these outputs first:

- `pnr/reports/run_manifest.rpt`
- `pnr/reports/report_area_place.rpt`
- `pnr/reports/report_gate_count_place.rpt`
- `pnr/reports/report_power_place.rpt`
- `pnr/reports/prects/`

Use the helper to preserve the estimate for review:

```bash
cd MPTDC/pnr/scripts
bash collect_snapshot.sh innovus_$(date +%Y%m%d_%H%M)_estimate
```

If congestion is high with `M1-M3` signal routing, relax utilization before allowing signal routing on `M4`; preserving the top metal for power is the default priority for this baseline.
