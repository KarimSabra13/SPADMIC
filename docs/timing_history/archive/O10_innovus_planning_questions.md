# O10 Innovus Planning Questions

Status: answers captured for first run; remaining open items are documented as assumptions.

## A. Run Objective

- First run objective: typical feasibility plus manager-visible screenshots.
- Timing closure target: attempt normal Innovus optimization through placement, `clk_sys` CTS, and route, but do not claim signoff.
- Dirty/quick vs baseline: clean reproducible baseline.
- Stop point: continue through route unless a catastrophic tool/setup failure occurs.
- CTS: run CTS for `clk_sys` only.

## B. Timing View

- Use O9 R750_delta5 typical view.
- MMMC: disabled for first O10 feasibility intent.
- Standard-cell Liberty: typical 1.8 V / 25 C.
- RO_tune4 LEF: real abstract LEF from the O1 export.
- RO_tune4 Liberty: shell only.
- SDC: O9 R750_delta5 final SDC plus post-synth SDC.
- Pre-place negative timing policy: accept the O9 seven residual setup paths into P&R as `NEAR_CLEAN_PRE_PNR_RESIDUAL`; track them, do not block the first run.

## C. Input Collateral

- Netlist: `results/genus_osc_pd/20260604_o9_final_typical_r750_delta5/mptdc_top_asic.postsyn.v`.
- Post-synth SDC: `results/genus_osc_pd/20260604_o9_final_typical_r750_delta5/mptdc_top_asic.postsyn.sdc`.
- O9 overlay SDC: `MPTDC/syn/inputs/mptdc_osc_typical_r750_delta5.sdc`.
- Tech LEF: XH018 `xh018_xx41_HD_MET4_METMID.lef`.
- Standard-cell LEF: XFAB D_CELLS_HD LEF.
- RO_tune4 LEF: `results/osc_pd/20260528_o1_export_ro_tune4_lef/real_abstract_lef/RO_tune4_real_abstract.lef`.
- Captable/QRC: use the typical captable/QRC files when available; otherwise mark RC as lower-accuracy feasibility.
- Existing Innovus scripts: reuse existing `MPTDC/pnr` helpers for PD matrix, phase-net, and tap-load reports.
- Floorplan DEF: none selected; create fresh O10 sandwich floorplan.

## D. Die/Core/Floorplan

- Default target: tool-derived macro block floorplan with about 60% core utilization.
- Layout concept: slow RO north, PD matrix center, fast RO south, backend digital island right.
- Whitespace: reserve margin around PD matrix and RO macros.
- Power rings: minimal first-run power connectivity/reporting; do not claim power-grid signoff.
- Macro halos: enabled around RO_tune4 macros; default halo documented in O10 assumptions.

## E. RO_tune4 Placement

- Both slow and fast macros use `RO_tune4`.
- LEF evidence: `SIZE 176.675 BY 67.17`, `SYMMETRY X Y R90`, `S[0:7]` pins on MET2.
- Default orientation: slow macro north with S pins facing the PD matrix; fast macro south mirrored/rotated so S pins face the PD matrix.
- Legal orientations: only use orientations consistent with LEF symmetry.
- Macro status: fixed after floorplan placement for first feasibility.
- Keepout: add halo/blockage around RO_tune4 and phase-route channel.

## F. PD Matrix Placement

- Place/guidance: strongly guide 64 PD cells into an 8x8 grid.
- Mapping: rows correspond to `gen_pd_row[ns]`, columns to `gen_pd_col[nf]`.
- Orientation: start with identical `R0` for reviewability; revise only after route evidence.
- Fast tags: guide fast tag column logic near the corresponding PD column when tool commands support it.
- PD matrix region: block unrelated digital cells from the central matrix/phase channel as much as practical.

## G. Phase-Net Routing

- Treat `RO_tune4/S[0:7]` nets as special source-clock phase nets.
- Do not run CTS on RO phase nets.
- Route as signals and report load/RC/transition/mismatch.
- Preferred first-run policy: no dummy loads, no arbitrary buffers, no signoff matched-length claim.
- Report phase0 extra load explicitly.

## H. Clocks

- `clk_sys`: normal CTS.
- `RO_tune4/S[0:7]`: no normal CTS; source clocks from macro pins, routed/reported as phase nets.
- RO uncertainty: keep O9 values, setup 10 ps and hold 5 ps.
- `clk_sys` uncertainty: keep the post-synthesis SDC value unless Innovus reports a setup incompatibility.

## I. Power

- Standard-cell power nets: `VDD` and `VSS`.
- RO_tune4 pins: connect `VDD` and `vdd!` to `VDD`; connect `VSS` to `VSS`.
- Separate analog supply: not enabled in first run.
- Well taps/endcaps/fillers: report capability; do not claim final physical signoff if incomplete.

## J. IO/Pins

- First run is block-level, no pad cells.
- Top-level pins may be auto-placed unless a previous constraint file is provided later.
- Prefer START/STOP near the RO/PD island and readout/control near backend right if pin placement commands are added.

## K. Reports/Screenshots

- Image format: PNG.
- Required views: floorplan, macro/PD matrix, placed design, `clk_sys` CTS, routed design, congestion, phase nets, final manager view.
- Include labels in manager summary, not necessarily embedded in the Innovus screenshot if the tool cannot annotate robustly.
- Batch screenshot export is attempted; restore/manual GUI instructions are generated if export fails.

## L. Runtime/License Control

- Run through route by default.
- Stop only on fatal setup/tool failure.
- Skip SI/signoff extraction unless available as a lightweight report.
- Preserve partial logs, checkpoints, DEFs, and screenshots/fallback notes.

## M. Deliverables for Manager

- `results/innovus/<RUN_ID>/manager/MANAGER_SUMMARY.md`.
- Screenshot paths and caveats included.
- Must state: typical feasibility only, not final signoff, not MMMC, not tapeout ready.
