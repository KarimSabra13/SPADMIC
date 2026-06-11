# MPTDC Innovus Estimate Flow

This directory contains the first-pass physical-estimation flow for the MPTDC macro. It is intended for area/timing/power exploration after a Genus run, not final signoff PnR.

## Baseline policy

- Technology: XFAB XH018, 1P4M / 4-metal HD baseline.
- Optimization goal: area-first.
- Default core utilization: `0.78`, with placement max density `0.82`.
- Default signal routing layers: `MET1` through `MET3`.
- Default NanoRoute routing layer indexes: `1` through `3` (`MET1-MET3` in the lab LEF).
- Default reserved power layer: `METTP`, so top/thick metal remains available for VDD/VSS straps and top-level power distribution as much as practical.
- Local exception: over the `mptdc_pd_matrix` region, `METTP` is reserved as an allowed routing/shielding resource for the 8 slow and 8 fast oscillator phase nets. The global route top remains `MET3` until detail-route/PDN evidence justifies enabling the exception in routing.
- Expected route directions: `MET1` horizontal, `MET2` vertical, `MET3` horizontal, `METTP` vertical. The technology LEF remains the source of truth; the run manifest records these expectations for review.
- Provisional oscillator abstracts: `syn/macros/mptdc_osc_blackbox.lef` and `.lib` define empty 300 um x 100 um slow/fast oscillator black boxes with `VDDA`/`VSSA`, top `ctrl_i[7:0]`, bottom `phase_o[7:0]`, and left-side `start_i`/`stop_i` enable pins. Replace them with foundry/custom macro views before final timing signoff.
- PD matrix decap policy: the estimate flow attempts to pack `DECAP25HD`/`DECAP15HD` into the PD matrix region after pre-CTS placement/optimization. Review `pnr/reports/pd_matrix_decap.rpt`; if the local Innovus build rejects the candidate `addFiller` syntax, insert equivalent PD-bound decap manually before final route.

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
export MPTDC_PNR_PHASE_METTP_EXCEPTION=1
export MPTDC_PNR_PD_REGION_WIDTH_UM=300
export MPTDC_PNR_OSC_WIDTH_UM=300
export MPTDC_PNR_OSC_HEIGHT_UM=100
export MPTDC_PNR_VECTORLESS_ACTIVITY=1
export MPTDC_PNR_DO_PRECTS_OPT=1
export MPTDC_PNR_DO_DETAIL_ROUTE=1
```

Explicit standard-cell PG pin connection is enabled by default. The XH018 HD
standard-cell LEF exposes lower-case `vdd/gnd` PG pins while the macro rails
remain upper-case `VDD/VSS`, so the flow connects upper-case nets to lower-case
cell pins. The provisional oscillator black boxes use separate `VDDA/VSSA`
analog rails and are connected explicitly by PG pin name. Disable only for debug:

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
- `pnr/reports/pd_matrix_decap.rpt`

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

The snapshot helper skips the `.enc` restore script and `.enc.dat` database
directory by default so the repository receives reports/log manifests rather
than heavy CAD databases. If you explicitly need a restorable snapshot, run:

```bash
MPTDC_SNAPSHOT_COPY_INNOVUS_DB=1 bash collect_snapshot.sh innovus_$(date +%Y%m%d_%H%M)_estimate_with_db
```

The flow also prepares a first-pass phase-detector matrix placement hook. By default it searches for the synthesized `gen_pd_row[*]/gen_pd_col[*]/u_pd` instances, creates the `mptdc_pd_matrix` group/region when Innovus supports those commands, and writes a review report. This is preparation only: final symmetry and matched-RC closure still need the real oscillator/PD macro LEFs and extraction/routing rules.

Each run now clears stale PnR reports before initialization and writes `run_status.rpt`. Treat a snapshot as invalid if `run_status.rpt` is missing or does not say `Status: COMPLETE`.

If congestion is high with `MET1-MET3` global signal routing, relax utilization first. The only planned `METTP` signal exception is the localized PD phase mesh; preserve top metal for PDN elsewhere.

## Final-Typical Stable Entry Point

Use the final-typical wrapper only after the Genus gate passes:

```bash
GENUS_RUN_ID=final_typical_genus_jihd_tap0_micro_v3_drvclean_20260610_175527
bash MPTDC/pnr/scripts/check_mptdc_pre_pnr_gate.sh --genus-run-id "$GENUS_RUN_ID"

MPTDC_GENUS_RUN_ID="$GENUS_RUN_ID" \
MPTDC_PNR_IO_LOAD_CLASS=medium \
MPTDC_PNR_CORE_UTIL=0.55 \
MPTDC_PNR_PLACE_PD_GRID=1 \
MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN=1 \
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_final_typical.sh mptdc_final_typical_validate --validate-only
```

The wrapper defaults to `validate_only`; it runs the pre-PNR gate and Tcl
source checks without launching Innovus. Any mode that can launch Innovus
requires `MPTDC_FINAL_TYPICAL_APPROVED=1` after review.

Stable Tcl hooks:

- `scripts/innovus_mptdc_floorplan.tcl`
- `scripts/innovus_mptdc_backend_regions.tcl`
- `scripts/innovus_mptdc_phase_buffer_place.tcl`
- `scripts/innovus_mptdc_pd_matrix_place.tcl`
- `scripts/innovus_mptdc_power.tcl`
- `scripts/innovus_mptdc_cts.tcl`
- `scripts/innovus_mptdc_reports.tcl`

Planning docs live under `docs/pnr/`.
