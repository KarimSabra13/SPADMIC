# MPTDC Repository Inventory

Phase 0 scope: inventory only. No RTL moves, filelist rewrites, script rewrites,
or deletions are part of this phase.

## Raw Inventory Evidence

Generated listings are under `docs/cleanup/generated/`:

- `tracked_files_before_cleanup.txt`
- `all_files_before_cleanup.txt`
- `git_status_before_cleanup.txt`
- `largest_files_before_cleanup.txt`

Snapshot facts:

- Branch at capture: `SPADMIC_FINAL`
- Source branch used for branch creation: `SPADMIC_localtag`
- Captured HEAD: `002ea6cdb1effdd58c25ea7cc74a6b06613ea7e7`
- Tracked files before Phase 0 docs: 27381
- All non-top-level-git files before Phase 0 docs: 102166
- Non-tracked/ignored workspace files in the raw all-file scan: about 74785
- Git status before Phase 0 docs: clean branch-only status

The largest tracked files are generated run artifacts, led by Innovus O10.2 logs
and reports under `results/innovus/20260604_o10_2_pnr_repair/` and mirrored
files under `MPTDC/lab_snapshots/innovus_o10_2_pnr_repair_20260604_o10_2_pnr_repair/`.
The largest all-files entries also include ignored local data, including the
ignored nested `OpenROAD/` checkout and large `results/characterization/...`
CSV files.

## Major Area Classification

| Area | Purpose | Source/generated | Active/legacy status | Main dependencies | Reference risk |
| --- | --- | --- | --- | --- | --- |
| `MPTDC/rtl/` | MPTDC design RTL, packages, CDC, top, PD, oscillator, readout, control | Source | Active/protected | `MPTDC/rtl/filelist.f`, Verilator, Xcelium, Genus | Very high |
| `MPTDC/rtl/cdc/` | CDC synchronizers and FIFO modules | Source | Active/protected | RTL filelist, simulator filelists, CDC docs | Very high |
| `MPTDC/tb/` | Unit, integration, VIP, and shared testbench code | Source | Active/protected | Verilator and Xcelium wrappers, VIP filelist | High |
| `MPTDC/sim/verilator/` | Verilator filelist and simulation support | Source/config | Active/protected | `filelist_verilator.f`, local smoke and VIP scripts | High |
| `MPTDC/sim/xcelium/` | Xcelium server wrappers | Source/script | Active/protected | Server-side Xcelium availability, RTL/testbench filelists | High |
| `MPTDC/syn/scripts/` | Genus entrypoints and helper Tcl | Source/script | Active/protected | O12/O13 wrappers, `procedures.tcl`, server checkout | Very high |
| `MPTDC/syn/inputs/` | Genus SDC/MMMC/defines inputs | Constraint/config | Active/protected | O13/O12 wrappers, Genus timing model, RO abstract | Very high |
| `MPTDC/syn/macros/` | Oscillator/RO abstract Liberty and LEF inputs | Constraint/macro input | Active/protected | O7-O13 Genus, Innovus, analog load analysis | Very high |
| `MPTDC/pnr/scripts/` | Innovus Tcl and server wrappers | Source/script | Active/protected | O10-O13 PnR flow, checkpoint restore/report scripts | Very high |
| `MPTDC/pnr/inputs/` | Innovus config/MMMC inputs | Constraint/config | Active/protected | Innovus init wrappers | High |
| `MPTDC/pnr/constraints/` | Innovus SDC overlays | Constraint/config | Active/protected | O10-O13 PnR wrappers | Very high |
| `MPTDC/analog_handoff/` | RO/oscillator contracts, pin lists, mode descriptions | Source evidence/config | Active/protected | RO abstract generation, O10-O13 timing assumptions | High |
| `MPTDC/tech/xlibd/` | XLIBD cell value notes and extracted references | Curated evidence | Active/protected | O13 IO/load/reset/scan docs, timing interpretation | High |
| `MPTDC/scripts/` | Characterization, analysis, and calibration scripts | Source/script | Active/protected unless proven obsolete | Report generation, calibration evidence, result post-processing | High |
| `MPTDC/ci/` | CI/helper checks | Source/config | Active/protected | Local validation expectations | Medium |
| `MPTDC/docs/` | MPTDC-local documentation | Source/docs | Active/protected | User-facing architecture and flow context | Medium |
| `docs/timing_closure/` | Timing/run planning and review notes | Source/docs/evidence | Active evidence, partly historical | Current O10-O13 decisions reference these docs | High |
| `docs/tech/` | Technology and XLIBD notes | Source/docs/evidence | Active/protected | XLIBD references and O13 timing docs | High |
| `MPTDC/lab_snapshots/` | Captured Genus/Innovus run snapshots | Generated evidence | Mixed: curated evidence plus old run bulk | Docs and debugging references; sometimes mirrors top-level `results/` | High |
| `MPTDC/results/` | Characterization and campaign outputs | Generated evidence | Mixed: some curated, much bulky historical output | Report scripts, thesis/report figures, calibration claims | High |
| `MPTDC/artifacts/` | Overnight VIP artifacts | Generated output | Candidate for archive/delete after review | VIP evidence and seed-level transcript tails | Medium |
| `MPTDC/report_artifacts/` | Final protocol report artifacts | Generated/curated evidence | Candidate for evidence archive, not blind delete | Thesis/report outputs | Medium |
| top-level `results/` | Local and server run outputs | Generated evidence | Mixed: current O10/O13 evidence plus old bulk | Timing closure docs and recent triage | Very high |
| `TOP/`, `I2C/`, `position/`, `arb/` | Other SPADMIC blocks | Source/mixed | Out of MPTDC cleanup scope by default | Top-level integration and unrelated block flows | High if touched |
| `Rapport_5PSM_KS/` | Thesis/report source and generated figures/PDFs | Source plus generated | Out of MPTDC cleanup scope unless separately approved | Report build and evidence references | Medium |
| `OpenROAD/` | Ignored local nested checkout | Ignored local dependency/cache | Out of git cleanup scope | Local tool exploration only unless documented otherwise | Low for tracked cleanup |
| `.venv/`, `MPTDC/build/` | Local environments and simulator builds | Ignored generated output | Not tracked; local cleanup only | Developer environment | Low for tracked cleanup |
| root `local_file_inventory.txt` | Prior inventory dump | Generated evidence | Candidate for consolidation | May duplicate new Phase 0 generated inventory | Low |
| root `tatus --short package-lock.json` | Accidental root artifact by name | Generated/mistyped artifact | Candidate after verification | None known | Low |

## Active Dependency Notes

- `MPTDC/rtl/filelist.f`, `MPTDC/sim/verilator/filelist_verilator.f`, and
  `MPTDC/tb/vip/filelist.f` are protected. Later cleanup must prove that every
  compile path still sees the same RTL/testbench closure before touching them.
- Current Genus activity depends on O12/O13 wrappers and SDC overlays,
  especially `server_run_genus_o13_abs5_pd_q1_exception_exact.sh`,
  `server_run_genus_o13_phase_distribution.sh`,
  `mptdc_osc_typical_r750_delta5_o13_abs5.sdc`, and
  `mptdc_osc_typical_r750_delta5_o13_phase_distribution.sdc`.
- Current Innovus activity depends on O10-O13 wrappers and overlays, especially
  O10.2 repair, O11 RO-load analysis, O12 phase-buffer analysis, and O13 phase
  distribution scripts.
- Existing RTL layout already mostly matches the desired split and includes an
  active `cdc/` subtree. Do not move RTL just to make the layout look cleaner.
- `.gitignore` and `MPTDC/.gitignore` already ignore many generated outputs,
  but many generated artifacts are already tracked. That mismatch is a cleanup
  target for later review, not a Phase 0 deletion.

## Phase 0 Finding

The repository is not source-heavy; it is evidence-heavy. The dominant tracked
areas are `MPTDC/`, top-level `results/`, and historical documentation. Cleanup
must therefore start from reference safety: preserve the current O13/O12 flow,
preserve the evidence used by timing-closure docs, then archive or remove only
candidate generated outputs after explicit review.
