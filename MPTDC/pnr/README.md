# MPTDC Innovus Estimate Flow

This directory contains the first-pass physical-estimation flow for the MPTDC macro. It is intended for area/timing/power exploration after a Genus run, not final signoff PnR.

## Baseline policy

- Technology: XFAB XH018, 1P4M / 4-metal HD baseline.
- Optimization goal: area-first.
- Default core utilization: `0.78`, with placement max density `0.82`.
- Default signal routing layers: `MET1` through `MET3`.
- Default NanoRoute routing layer indexes: `1` through `3` (`MET1-MET3` in the lab LEF).
- Default reserved power layer: `METTP`, so top/thick metal remains available for VDD/VSS straps and top-level power distribution as much as practical.
- Expected route directions: `MET1` horizontal, `MET2` vertical, `MET3` horizontal, `METTP` vertical. The technology LEF remains the source of truth; the run manifest records these expectations for review.

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
export MPTDC_PNR_SIGNAL_TOP_LAYER=MET3
export MPTDC_PNR_SIGNAL_TOP_LAYER_IDX=3
export MPTDC_PNR_POWER_LAYER=METTP
export MPTDC_PNR_DO_PRECTS_OPT=1
export MPTDC_PNR_DO_DETAIL_ROUTE=1
```

Explicit standard-cell PG pin connection is enabled by default. The XH018 HD
standard-cell LEF exposes lower-case `vdd/gnd` PG pins while the macro rails
remain upper-case `VDD/VSS`, so the flow connects upper-case nets to lower-case
cell pins. Disable only for debug:

```bash
export MPTDC_PNR_CONNECT_PG_PINS=0
```

Review these outputs first:

- `pnr/reports/run_manifest.rpt`
- `pnr/reports/run_status.rpt`
- `pnr/reports/report_area_place.rpt`
- `pnr/reports/report_gate_count_place.rpt`
- `pnr/reports/report_power_place.rpt`
- `pnr/reports/prects/`
- `pnr/reports/pd_matrix_symmetry.rpt`

Use the helper to preserve the estimate for review:

```bash
cd MPTDC/pnr/scripts
bash collect_snapshot.sh innovus_$(date +%Y%m%d_%H%M)_estimate
```

`saveDesign` writes a small restore script (`mptdc_top_asic.place.enc`) plus a
database directory (`mptdc_top_asic.place.enc.dat`).  To reopen a live run from
`pnr/scripts`, use one of:

```tcl
source ../outputs/mptdc_top_asic.place.enc
# or:
restoreDesign ../outputs/mptdc_top_asic.place.enc.dat mptdc_top_asic
```

The snapshot helper skips the `.enc.dat` database directory by default to avoid
accidentally committing a large binary Innovus DB.  If you explicitly need a
restorable snapshot, run:

```bash
MPTDC_SNAPSHOT_COPY_INNOVUS_DB=1 bash collect_snapshot.sh innovus_$(date +%Y%m%d_%H%M)_estimate_with_db
```

The flow also prepares a first-pass phase-detector matrix placement hook. By default it searches for the synthesized `gen_pd_row[*]/gen_pd_col[*]/u_pd` instances, creates the `mptdc_pd_matrix` group/region when Innovus supports those commands, and writes a review report. This is preparation only: final symmetry and matched-RC closure still need the real oscillator/PD macro LEFs and extraction/routing rules.

Each run now clears stale PnR reports before initialization and writes `run_status.rpt`. Treat a snapshot as invalid if `run_status.rpt` is missing or does not say `Status: COMPLETE`.

If congestion is high with `MET1-MET3` signal routing, relax utilization before allowing signal routing on `METTP`; preserving the top metal for power is the default priority for this baseline.
