# Oscillator/PD Iteration Log

## O0_osc_pd_signoff_infra

Iteration ID: O0_osc_pd_signoff_infra

Git HEAD: pending local commit

Branch: SPADMIC_TOP

Patch summary:

- Added provisional oscillator macro-view generator and generated LEF/Liberty shells.
- Added analog handoff templates.
- Added oscillator/PD SDC overlay, env-gated in Genus/Innovus MMMC.
- Added Innovus O0 hooks for regions, PD grid intent, phase route intent, and reports.
- Added local parsers/analyzers for PD placement, phase routes, tap loads, and path classification.
- Added separate Genus/Innovus server-run wrappers for O0.

Files changed:

- docs/timing_closure/O0_osc_pd_signoff_plan.md
- docs/timing_closure/oscillator_analog_handoff_request.md
- docs/timing_closure/pd_matrix_physical_contract.md
- docs/timing_closure/osc_pd_exception_waivers.md
- docs/timing_closure/SERVER_RUN_REQUEST_OSC_PD.md
- MPTDC/analog_handoff/*
- tools/osc/*
- tools/timing/analyze_pd_instance_symmetry.py
- tools/timing/analyze_pd_phase_routes.py
- tools/timing/analyze_osc_tap_loads.py
- tools/timing/classify_mptdc_timing_paths.py
- MPTDC/syn/inputs/mptdc_osc_pd_physical.sdc
- MPTDC/syn/scripts/server_run_genus_osc_pd_signoff.sh
- MPTDC/pnr/scripts/*osc_pd*
- MPTDC/pnr/scripts/report_pd_*
- MPTDC/pnr/scripts/report_osc_tap_loads.tcl

Tool stage:

- local Python/script checks only

Was this actually run by agent locally?

- yes, for generator and Python syntax checks
- no Cadence tools run locally

Was this run by human on lab server?

- no

Evidence location:

- pending local command transcript

Genus:

- run available? no
- WNS/TNS/path count: unknown
- worst path group: unknown
- design-rule violations: unknown

Innovus:

- run available? no
- phase-route/load reports: not available yet
- PD placement reports: not available yet

Functional result:

- unknown; no RTL changed

Timing result:

- unknown until server run

Linearity/precision risk:

- none for docs/scripts
- provisional physical-model risk remains high until analog handoff and extracted RC

Decision:

- request O0 server run after local checks and commit

Next action:

- Run `server_run_genus_osc_pd_signoff.sh` and `server_run_innovus_osc_pd_signoff.sh` on lab server after this branch is pushed.

## O1_real_abstract_and_R800_derate_prep

Iteration ID: O1_real_abstract_and_R800_derate_prep

Git HEAD: pending local commit

Branch: SPADMIC_TOP

Patch summary:

- Reviewed committed O0 Genus/Innovus server results.
- Added O1A real `SPADMIC/RO_tune4/abstract` locator/export collateral.
- Added O1A Genus/Innovus wrappers that require real LEF and refuse silent provisional-LEF fallback.
- Updated O1A export flow to use user-provided source LEF `/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune4.lef` and create a documented `RO_tune4` macro-name alias if the internal source macro is still `RO4_TUNE`.
- Added macro-binding audit documenting current `mptdc_osc_stub` netlist mismatch.
- Added O1B R800 STA/PnR what-if timing defines and wrappers.
- Added conservative R800 Xcelium wrapper that blocks until analog-confirmed behavioral/tune data exists.

Files changed:

- docs/timing_closure/O1_o0_result_review.md
- docs/timing_closure/O1_real_abstract_plan.md
- docs/timing_closure/O1_macro_binding_audit.md
- docs/timing_closure/O1B_R800_derate_plan.md
- docs/timing_closure/SERVER_RUN_REQUEST_O1_REAL_ABSTRACT.md
- docs/timing_closure/SERVER_RUN_REQUEST_O1B_R800.md
- MPTDC/analog_handoff/real_ro_tune4_abstract.env
- MPTDC/analog_handoff/cds_analog_override.lib
- MPTDC/analog_handoff/oscillator_tune_modes.yaml
- MPTDC/syn/inputs/mptdc_freq_modes.defines
- MPTDC/syn/inputs/mptdc_osc_pd_r800.sdc
- MPTDC/sim/verilator/README_R800.md
- MPTDC/pnr/scripts/server_locate_ro_tune4_abstract.sh
- MPTDC/pnr/scripts/server_export_ro_tune4_lef.sh
- MPTDC/syn/scripts/server_run_genus_o1_real_abstract.sh
- MPTDC/pnr/scripts/server_run_innovus_o1_real_abstract.sh
- MPTDC/syn/scripts/server_run_genus_o1b_r800.sh
- MPTDC/pnr/scripts/server_run_innovus_o1b_r800.sh
- MPTDC/sim/xcelium/server_run_xcelium_r800_mptdc.sh

Tool stage:

- local script/Python/Tcl syntax checks only

Was this actually run by agent locally?

- yes, local syntax checks only
- no Cadence tools run locally

Was this run by human on lab server?

- no

Evidence location:

- `results/local_osc_pd/20260528_o1_prep_checks/SUMMARY.md`

O0 result review:

- Genus run available? yes
- Genus worst group: `clk_osc_fast_tap1`, WNS `-3163.0 ps`, TNS `-193058.8 ps`, 72 paths
- Genus clk_sys: WNS `-720.4 ps`, TNS `-37235.0 ps`, 77 paths
- Genus top class: `OSC_FAST_REAL`, mainly fast counter to `nfast_hit`
- Innovus run available? yes, but physical signoff incomplete
- Innovus postRoute setup/hold: missing
- PD grid report: logical PASS for 64 cells, but actual placement/master fields incomplete
- Phase tap RC/load reports: empty or missing

Functional result:

- unknown; no RTL semantic change

Timing result:

- unknown until O1A lab run

Linearity/precision risk:

- none for docs/scripts/SDC overlays
- O1B R800 remains not calibration-safe until analog tune table preserves 5 ps tap delta

Decision:

- request O1A locator/export first
- run O1A Genus/Innovus only if real LEF exists and macro binding can be proven
- keep H4b paused

Next action:

- Human runs `SERVER_RUN_REQUEST_O1_REAL_ABSTRACT.md` commands on lab server and commits pushed results.

## O1C_macro_binding_fix_prep

Iteration ID: O1C_macro_binding_fix_prep

Git HEAD: pending local commit

Branch: SPADMIC_TOP

Patch summary:

- Fixed LEF macro parsing so `PROPERTYDEFINITIONS` cannot be mistaken for a
  physical macro block.
- Added a Liberty shell for real `RO_tune4` logical binding.
- Added guarded synthesis-only `MPTDC_USE_RO_TUNE4_MACRO` mode in
  `mptdc_osc_wrapper`.
- Mapped `RO_tune4.rstb` directly to oscillator enable/run input, not global
  reset.
- Added O1C SDC overlay and Genus server wrapper.
- Documented the O1A binding failure and the fast-counter to `nfast_hit` timing
  concern for post-binding analysis.

Files changed:

- `tools/timing/parse_lef_macros.py`
- `tools/timing/test_parse_ro_tune4_lef.py`
- `MPTDC/pnr/scripts/server_export_ro_tune4_lef.sh`
- `MPTDC/rtl/osc/mptdc_osc_wrapper.sv`
- `MPTDC/rtl/top/mptdc_core.sv`
- `MPTDC/syn/filelist_o1c_macro_binding.f`
- `MPTDC/syn/macros/RO_tune4_real_abstract_shell.lib`
- `MPTDC/syn/inputs/mptdc.defines`
- `MPTDC/syn/inputs/mptdc_osc_pd_o1c.sdc`
- `MPTDC/syn/libraries/libraries.xh018.tcl`
- `MPTDC/syn/scripts/server_run_genus_o1c_macro_binding.sh`
- `docs/timing_closure/O1C_lef_parser_fix.md`
- `docs/timing_closure/O1C_macro_binding_audit.md`
- `docs/timing_closure/O1C_sdc_binding_notes.md`
- `docs/timing_closure/O1C_fast_count_capture_analysis.md`
- `docs/timing_closure/SERVER_RUN_REQUEST_O1C_MACRO_BINDING.md`
- `docs/timing_closure/osc_pd_iteration_log.md`

Tool stage:

- local Python syntax/checks
- local Verilator lint/smoke attempted because RTL wrapper changed
- Genus server request prepared

Was this actually run by agent locally?

- yes, local-only checks
- no Cadence tools run locally

Was this run by human on lab server?

- no

Evidence location:

- local command output in this Codex session
- server evidence pending in `results/genus_osc_pd/20260528_o1c_macro_binding_genus/`

O1A Genus review:

- run available? yes
- WNS: `-3163.0 ps` on `clk_osc_fast_tap1`
- total TNS: `-1583170.0 ps`
- violating paths: `697`
- binding status: `NOT_BOUND_STILL_MPTDC_OSC_STUB`
- dominant class: `OSC_FAST_REAL`
- main conceptual path: fast counter to PD `nfast_hit_latched`

O1C expected Genus result:

- exactly two `RO_tune4` instances
- no post-synthesis `mptdc_osc_stub` residue
- generated clocks attached to `u_ro_tune4/S[0:7]`
- real fast-domain paths remain visible

Functional result:

- normal simulation mode should remain unchanged
- macro mode is synthesis-only and must be validated by Genus netlist inspection

Timing result:

- unknown until O1C Genus is run on the lab server

Linearity/precision risk:

- low for O1C binding if `S[0:7]` ordering and `rstb` run-control behavior are
  correct
- final signoff still blocked by analog tune code, load, slew, jitter, startup,
  and tap-delay data

Decision:

- request O1C Genus only
- Innovus remains blocked until binding succeeds
- R800 remains blocked until O1C binding and analog tune data

Next action:

- Human runs `docs/timing_closure/SERVER_RUN_REQUEST_O1C_MACRO_BINDING.md` on
  the lab server after this patch is pushed.

### O1C Tcl quote fix

The first O1C server attempt stopped while sourcing `mptdc.defines`:

```text
invalid command name "0:7"
```

Root cause:

- A Genus/Tcl `puts` message used double quotes around the literal text
  `S[0:7]`.
- Tcl treated `[0:7]` as command substitution.

Fix:

- Changed the O1C status `puts` in `MPTDC/syn/inputs/mptdc.defines` to use
  braces, preserving literal `S[0:7]`.

Server action:

- Pull the quote-fix commit and rerun the same O1C Genus command.

### O1C2 fast-count audit prep

Iteration ID: O1C2_fast_count_audit_prep

Git HEAD:

- local base before this prep: `abe049df9d31cb5899cd3810eb9adf89a1cc0baa`

Patch summary:

- Fixed O1C SDC bracketed phase-net pattern construction.
- Removed report-only `group_path` commands from the O1C overlay.
- Added focused Genus report generation for `fast counter -> nfast_hit`.
- Added local parser `tools/timing/analyze_fast_count_capture.py`.
- Added O1C result review documentation.

Files changed:

- `MPTDC/syn/inputs/mptdc_osc_pd_o1c.sdc`
- `MPTDC/syn/scripts/procedures.tcl`
- `MPTDC/syn/scripts/server_run_genus_o1c_macro_binding.sh`
- `tools/timing/parse_genus_summary.py`
- `tools/timing/analyze_fast_count_capture.py`
- `docs/timing_closure/O1C_result_review.md`
- `docs/timing_closure/O1C_fast_count_capture_analysis.md`
- `docs/timing_closure/O1C_sdc_binding_notes.md`
- `docs/timing_closure/osc_pd_iteration_log.md`

Tool stage:

- local parser checks
- next required server stage: Genus only

Was this actually run by agent locally?

- yes, Python syntax checks and local parsing of committed O1C reports
- no Cadence tools run locally

Was this run by human on lab server?

- no

Evidence location:

- local parser output from committed O1C report:
  `results/genus_osc_pd/20260528_o1c_macro_binding_genus/fast_count_capture_summary.md`
- updated server run will produce fresh O1C2 evidence under:
  `results/genus_osc_pd/20260601_o1c2_fast_count_audit_genus/`

Local checks:

- `python3 -m py_compile tools/timing/parse_genus_summary.py tools/timing/classify_mptdc_timing_paths.py tools/timing/analyze_fast_count_capture.py`: pass
- `python3 tools/timing/analyze_fast_count_capture.py results/genus_osc_pd/20260528_o1c_macro_binding_genus`: pass

Functional result:

- no RTL semantics changed

Timing result:

- unknown until O1C2 Genus run

Linearity/precision risk:

- none for this prep patch
- it adds reports only and does not touch PD/oscillator behavior

Decision:

- request one O1C2 Genus run before Innovus/R800/H4b

Next action:

- Commit/push this prep patch, then run:
  `bash MPTDC/syn/scripts/server_run_genus_o1c_macro_binding.sh 20260601_o1c2_fast_count_audit_genus`

### O1C3 latest Genus review and PD-gate fix

Iteration ID: O1C3_latest_genus_review_pd_gate_fix

Git HEAD:

- pulled HEAD before O1C3 edits: `226549ca4064d8dcb1f5e06fc3223c2454e1d0b7`

Patch summary:

- Reviewed latest committed O1C2 Genus evidence.
- Confirmed `RO_tune4` binding remains candidate-valid.
- Confirmed oscillator-domain standard-cell timing is the dominant conceptual blocker.
- Confirmed PD input gate can fabricate a hit if it forces the sampled slow input low before the bridge samples.
- Kept `pd_gate_o` high through `ST_M_SNAPSHOT` so the bridge and row-count sample occur before the digital gate drops.
- Added a Verilator PD-cell unit test that reproduces forced-low false-hit behavior.
- Cleaned O1C reporting helpers so focused fast-count reports are copied and Cadence collection iteration is not collapsed into one string.
- Made O1C phase net electrical limits report-only in Genus because Genus 22.13 rejects the net-level SDC commands used in O1C2.

Files changed:

- `MPTDC/rtl/ctrl/mptdc_meas_ctrl.sv`
- `MPTDC/tb/unit/tb_meas_ctrl_unit.sv`
- `MPTDC/tb/unit/tb_pd_gate_false_hit_unit.sv`
- `MPTDC/syn/inputs/mptdc_osc_pd_o1c.sdc`
- `MPTDC/syn/scripts/procedures.tcl`
- `MPTDC/syn/scripts/server_run_genus_o1c_macro_binding.sh`
- `docs/timing_closure/O1C3_latest_genus_review.md`
- `docs/timing_closure/O1C3_fast_count_root_cause.md`
- `docs/timing_closure/O1C3_pd_gate_false_hit_analysis.md`
- `docs/timing_closure/O1C3_architecture_options.md`
- `docs/timing_closure/osc_pd_iteration_log.md`

Tool stage:

- local Verilator and parser checks
- no Genus/Innovus/Xcelium run by agent

Was this actually run by agent locally?

- yes, Verilator unit/lint and Python/Tcl/bash checks

Was this run by human on lab server?

- O1C2 evidence was run by human before this review
- O1C3 edited RTL/scripts have not been run on the lab server

Evidence location:

- latest server evidence: `results/genus_osc_pd/20260601_o1c2_fast_count_audit_genus/`
- local lint result: `results/local_verilator/20260601_o1c3_local_lint/`
- review docs:
  - `docs/timing_closure/O1C3_latest_genus_review.md`
  - `docs/timing_closure/O1C3_fast_count_root_cause.md`
  - `docs/timing_closure/O1C3_pd_gate_false_hit_analysis.md`
  - `docs/timing_closure/O1C3_architecture_options.md`

Local checks:

- `tb_meas_ctrl_unit` with Verilator: PASS, 132 checks
- `tb_pd_gate_false_hit_unit` with Verilator: PASS
- `run_lint.sh 20260601_o1c3_local_lint`: PASS
- `python3 -m py_compile tools/timing/parse_genus_summary.py tools/timing/classify_mptdc_timing_paths.py tools/timing/analyze_fast_count_capture.py`: PASS
- `bash -n MPTDC/syn/scripts/server_run_genus_o1c_macro_binding.sh`: PASS
- O1C SDC dummy Tcl source with stubbed Cadence commands: parses through expected report messages

Functional result:

- PD-gate false-hit hazard fixed locally.
- Measurement field meanings unchanged.

Timing result:

- O1C2 Genus evidence still shows `OSC_FAST_REAL` as dominant:
  - fast-count focused worst slack: `-3051 ps`
  - internal fast-counter worst slack: about `-2706 ps`
  - clk_sys worst slack: about `-825 ps`

Linearity/precision risk:

- O1C3 PD-gate fix risk: low positive, because it prevents a digital forced-low edge before snapshot.
- Fast-domain architecture remains unresolved and is medium/high risk until a stable-tag or macro strategy is selected.

Decision:

- Do not run Innovus.
- Do not run R800.
- Do not resume H4b yet.
- Next major decision is hardened measurement-fabric macro/waiver versus stable `nfast_hit` tag redesign.

Next action:

- Commit/push O1C3 low-risk fixes and documentation.
- Do not spend a Genus run on O1C3 alone unless a clean-report sanity check is explicitly desired; it will still be dominated by the oscillator-domain timing feasibility issue.

### O2 raw local fast tag RTL experiment

Iteration ID: O2_RAW_TAG_SW_DECODE_PREP

Git HEAD:

- branch point before O2 edits: `226549ca4064d8dcb1f5e06fc3223c2454e1d0b7`

Patch summary:

- Created branch `SPADMIC_localtag`.
- Added one local 7-bit LFSR fast epoch tag generator per fast column.
- Removed the global live binary fast counter from the PD capture path.
- Changed PD cells to capture local encoded tags and added `detect_en_i` so
  the sampled slow phase is no longer forced low by core-level gating.
- Removed RTL tag decode from `mptdc_drain_ctrl`.
- Exported the raw local LFSR tag in the existing packet/acquisition `nfast`
  field.
- Kept packet/acquisition record bit layout unchanged; changed O2 `nfast`
  semantics and moved decode to software/calibration.
- Retained the O1C3 measurement controller change that keeps `pd_gate` open
  through `ST_M_SNAPSHOT`.
- Added focused Verilator unit tests and included them in local smoke.
- Prepared a Genus O2 server wrapper and run request.

Files changed:

- `MPTDC/rtl/pkg/mptdc_pkg.sv`
- `MPTDC/rtl/pd/mptdc_fast_epoch_tag.sv`
- `MPTDC/rtl/pd/mptdc_pd_cell.sv`
- `MPTDC/rtl/top/mptdc_core.sv`
- `MPTDC/rtl/ctrl/mptdc_drain_ctrl.sv`
- `MPTDC/rtl/filelist.f`
- `MPTDC/sim/verilator/filelist_verilator.f`
- `MPTDC/sim/verilator/run_smoke.sh`
- `MPTDC/syn/filelist_synth.f`
- `MPTDC/syn/filelist_o1c_macro_binding.f`
- `MPTDC/syn/filelist_o2_raw_tag.f`
- `MPTDC/syn/scripts/server_run_genus_o2_raw_tag.sh`
- `MPTDC/tb/unit/tb_fast_epoch_tag_unit.sv`
- `MPTDC/tb/unit/tb_pd_cell_tag_capture_unit.sv`
- `MPTDC/tb/unit/tb_pd_gate_false_hit_unit.sv`
- `MPTDC/tb/unit/tb_drain_raw_tag_unit.sv`
- `MPTDC/tb/unit/tb_drain_ctrl_unit.sv`
- `docs/timing_closure/O2_local_fast_tag_architecture.md`
- `docs/timing_closure/O2_raw_tag_software_decode.md`
- `docs/timing_closure/O2_raw_tag_sta_cdc_asic_review.md`
- `docs/timing_closure/SERVER_RUN_REQUEST_O2_RAW_TAG_OVERNIGHT_CHARAC.md`
- `docs/timing_closure/SERVER_RUN_REQUEST_O2_RAW_TAG_GENUS.md`
- `docs/timing_closure/osc_pd_iteration_log.md`

Tool stage:

- local Verilator
- no Genus/Innovus/Xcelium run by agent

Was this actually run by agent locally?

- yes

Was this run by human on lab server?

- no

Evidence location:

- local smoke: `results/local_verilator/20260601_o2_raw_tag_smoke/`
- local lint: `results/local_verilator/20260601_o2_raw_tag_lint/`
- local software smoke: `results/local_software/20260601_o2_raw_tag_charac_smoke/`
- architecture note: `docs/timing_closure/O2_local_fast_tag_architecture.md`
- software decode note: `docs/timing_closure/O2_raw_tag_software_decode.md`

Local checks:

- Python compile: PASS for raw-tag decoder, tests, characterization smoke,
  shared characterization helpers, campaign analysis, calibration, and VIP
  schema helpers.
- `python3 tools/mptdc_decode/test_fast_tag_decode.py`: PASS.
- `python3 MPTDC/scripts/analysis/o2_raw_tag_charac_smoke.py --run-id 20260601_o2_raw_tag_charac_smoke`: PASS.
- `run_lint.sh 20260601_o2_raw_tag_lint`: PASS.
- `run_smoke.sh 20260601_o2_raw_tag_smoke`: PASS, 14/14 steps.
- O2 synthesis filelist Verilator syntax check with `MPTDC_USE_RO_TUNE4_MACRO`: PASS.
- Characterization baseline dry-run with `--nfast-encoding raw_lfsr_tag`: PASS.
- VIP overnight char-stage dry-run with `--char-nfast-encoding raw_lfsr_tag`: PASS.
- After the first server O2 overnight attempt, VIP passed 512/512 but all
  campaign characterization seeds failed at `rc=1`.  Root cause identified
  locally: `tb_campaign_collect.sv` still had debug-only hierarchical probes
  into removed `u_core.u_fast_cnt.*`.
- Fixed campaign collector debug probes to populate historical fast-gray debug
  columns with the phase-0 raw tag (`u_core.nfast_src_count`) in O2.
- Verilator campaign smoke from the repository top-level command path: PASS,
  1 seed, 100 conversions, 1500 data rows.

Functional result:

- Verilator smoke PASS.
- Packet/acquisition record structure unchanged.
- `nfast_hit` is internally encoded in the held context and emitted as raw tag
  in O2 mode; software must decode using `nf` plus the LFSR table.

Timing result:

- unknown until O2 Genus.
- Expected removed path: `u_fast_cnt/bin_q_reg[] -> u_pd/nfast_hit_latched_reg[*]`.
- Expected new fast paths: local tag LFSR feedback and same-column tag-to-PD
  captures with fanout 8 per column.
- No RTL tag decode should appear in `clk_sys`.

Linearity/precision risk:

- medium/high until software characterization and Xcelium/calibration confirm
  the raw-tag decode and per-`nf` offset model.
- no PD dimension, tap ordering, START/STOP, or packet layout change.

Decision:

- Run local Python/Verilator raw-tag validation.
- Run or at least prepare O2 raw-tag overnight characterization before Genus.
- Request one O2 Genus run only after raw-tag software/VIP confidence.
- Do not run Innovus until O2 Genus proves the global fast-count path is gone
  and remaining fast paths are local/physically meaningful.
- Keep R800, H4b, and cell sizing blocked.

Next action:

- Commit/push O2 raw-tag branch after local checks pass.
- Server characterization request:
  `docs/timing_closure/SERVER_RUN_REQUEST_O2_RAW_TAG_OVERNIGHT_CHARAC.md`
- Genus request, still blocked until raw-tag validation:
  `docs/timing_closure/SERVER_RUN_REQUEST_O2_RAW_TAG_GENUS.md`

## Iteration: O2_ANALYSIS_MEMORY_STREAMING

Git HEAD at local patch time:

- `3529510a57dd0278bf4155c859f198ec2fcf2ac7`

Branch:

- `SPADMIC_localtag`

Patch summary:

- Added streaming/chunked campaign analysis for O2 raw-tag characterization.
- Separated simulation parallelism from analysis controls.
- Added a `--skip-campaign` path so completed Xcelium campaign CSVs can be
  reused without relaunching simulation.
- Added bounded calibration training controls for large campaigns.

Files changed:

- `MPTDC/scripts/analysis/analyze_campaign.py`
- `MPTDC/scripts/sim/run_characterization_baseline.sh`
- `MPTDC/scripts/sim/run_vip_overnight.sh`
- `MPTDC/scripts/calibration/calibrate_6d_lut.py`
- `docs/timing_closure/O2_analysis_memory_diagnosis.md`
- `docs/timing_closure/SERVER_RUN_REQUEST_O2_RAW_TAG_ANALYSIS_RERUN.md`
- `docs/timing_closure/osc_pd_iteration_log.md`

Tool stage:

- local Python/shell checks only

Was this actually run by agent locally?

- yes

Was this run by human on lab server?

- no

Evidence location:

- local streaming smoke output: `/tmp/o2_streaming_analysis_smoke/`
- diagnosis: `docs/timing_closure/O2_analysis_memory_diagnosis.md`
- rerun request: `docs/timing_closure/SERVER_RUN_REQUEST_O2_RAW_TAG_ANALYSIS_RERUN.md`

Local checks:

- `python3 -m py_compile MPTDC/scripts/analysis/analyze_campaign.py MPTDC/scripts/calibration/calibrate_6d_lut.py`: PASS.
- `bash -n MPTDC/scripts/sim/run_characterization_baseline.sh MPTDC/scripts/sim/run_vip_overnight.sh`: PASS.
- Streaming analysis smoke on local Verilator campaign, 1 file / 1500 rows:
  PASS.
- Smoke RSS log: start 0.14 GiB, after first chunk 0.15 GiB, end 0.17 GiB.
- Characterization baseline dry-run with `--skip-campaign`,
  `--analysis-low-memory`, `--analysis-jobs 2`, and bounded calibration:
  PASS.
- Follow-up calibration vectorization smoke:
  `python3 MPTDC/scripts/calibration/calibrate_6d_lut.py --train-dir /tmp/o2_campaign_smoke_root/multihit_15_cal_nominal --out-dir /tmp/o2_calibration_vector_smoke --train-seeds 1 --nfast-encoding raw_lfsr_tag --train-max-rows-per-seed 1000 --val-max-files 1`
  PASS in 4.5 seconds.

Functional result:

- No RTL changed in this iteration.
- Existing campaign CSVs can be reused.
- O2 raw-tag software decode remains enabled in analysis, but is now applied
  per chunk.

Timing result:

- no Genus/Innovus impact; this is a data-pipeline fix.

Linearity/precision risk:

- low for the software change, but streaming P90/P99 tails are histogram
  approximations and raw scatter/t-test plots are skipped to keep memory bounded.
- calibration confidence still depends on rerunning the completed campaign
  analysis and reviewing outputs.

Decision:

- Stop old high-memory `analyze_campaign.py` processes if still running.
- Reuse existing Xcelium campaign CSVs.
- Rerun only streaming analysis/calibration using
  `SERVER_RUN_REQUEST_O2_RAW_TAG_ANALYSIS_RERUN.md`.
- Genus remains blocked until this characterization rerun completes cleanly.

Next action:

- Push this software-pipeline patch.
- Human runs the analysis-only rerun command from
  `docs/timing_closure/SERVER_RUN_REQUEST_O2_RAW_TAG_ANALYSIS_RERUN.md`.

---

Iteration ID: O2_raw_tag_genus_review_and_report_hygiene

Git HEAD:

- `1e3fb188303e2755de403ac5c3571b27bc2feca8`

Branch:

- `SPADMIC_localtag`

Patch summary:

- Reviewed the committed O2 raw-tag Genus result.
- Documented that the actual O2 netlist removed `u_fast_cnt`, but stale focused
  fast-count reports survived from a repeated run ID and contaminated the
  classifier summary.
- Patched the O2 Genus wrapper to clean its result directory before each run
  and to stop counting all `bin_q_reg` names as fast-counter residue.
- Confirmed the next timing target is the slow coarse counter/watchdog fabric,
  but a naive async-captured slow LFSR is not safe.

Files changed:

- `MPTDC/syn/scripts/server_run_genus_o2_raw_tag.sh`
- `docs/timing_closure/O2_raw_tag_genus_review.md`
- `docs/timing_closure/osc_pd_iteration_log.md`

Tool stage:

- local report review only

Was this actually run by agent locally?

- yes

Was this run by human on lab server?

- no

Evidence location:

- `results/genus_osc_pd/20260601_o2_raw_tag_genus/`
- `docs/timing_closure/O2_raw_tag_genus_review.md`

Local checks:

- Current netlist check: `mptdc_top_asic.postsyn.v` contains two `RO_tune4`
  instances and no `u_fast_cnt`.
- Current actual `timing_violations.rpt` top paths are slow counter/watchdog,
  slow-count decode, and PD-cell `q1/q2 -> nfast_hit_latched`.
- Stale focused reports still reference `u_fast_cnt`, so they must not be used
  as current O2 timing evidence.

Functional result:

- No RTL changed in this iteration.

Timing result:

- O2 removed the old global fast-counter-to-PD path from the actual netlist.
- O2 does not close oscillator-domain timing; standard-cell logic remains in
  slow/fast oscillator domains.

Linearity/precision risk:

- none for this report/script hygiene patch.
- proposed O3 slow raw-tag work is medium/high until STOP-freeze semantics,
  software decode, Xcelium, and characterization are complete.

Decision:

- Continue with O3 planning/patching before another expensive Genus run.
- Do not run Innovus yet.
- Do not run R800 yet.
- Do not resume H4b yet.

Next action:

- Implement `O3_RAW_SLOW_TAG_SW_DECODE` only after adding local tests and
  software decode metadata for raw `nslow`.

---

Iteration ID: O3_raw_epoch_and_pd_capture_cleanup

Git HEAD:

- Baseline before patch: `1e3fb188303e2755de403ac5c3571b27bc2feca8`

Branch:

- `SPADMIC_localtag`

Patch summary:

- Replaced the slow binary/Gray coarse source with a 64-stage Johnson epoch
  generator and STOP-edge raw epoch capture.
- Moved slow epoch decode to `clk_sys` inside `mptdc_hit_capture_bridge`, keeping
  packet/context `nslow` as a decoded 7-bit field.
- Migrated START-only timeout counting from `slow_phase[0]` to `clk_sys`.
- Simplified PD tag capture so each PD cell shadows the local raw fast tag until
  hit freeze instead of feeding q1/q2 edge-detect logic into every tag bit.
- Added O3 Genus filelist, SDC/report overlay, and server wrapper.

Files changed:

- `MPTDC/rtl/pkg/mptdc_pkg.sv`
- `MPTDC/rtl/pd/mptdc_slow_epoch_johnson.sv`
- `MPTDC/rtl/pd/mptdc_pd_cell.sv`
- `MPTDC/rtl/async/mptdc_stop_epoch_capture_async.sv`
- `MPTDC/rtl/async/mptdc_hit_capture_bridge.sv`
- `MPTDC/rtl/top/mptdc_core.sv`
- `MPTDC/rtl/filelist.f`
- `MPTDC/sim/verilator/filelist_verilator.f`
- `MPTDC/sim/verilator/run_smoke.sh`
- `MPTDC/scripts/sim/run_tb.sh`
- `MPTDC/syn/filelist_synth.f`
- `MPTDC/syn/filelist_o2_raw_tag.f`
- `MPTDC/syn/filelist_o3_raw_epoch_cleanup.f`
- `MPTDC/syn/inputs/mptdc_osc_pd_o3.sdc`
- `MPTDC/syn/scripts/procedures.tcl`
- `MPTDC/syn/scripts/server_run_genus_o3_raw_epoch_cleanup.sh`
- `MPTDC/tb/unit/tb_slow_epoch_johnson_unit.sv`
- `MPTDC/tb/unit/tb_stop_epoch_capture_async_unit.sv`
- `MPTDC/tb/unit/tb_johnson_decode_unit.sv`
- `MPTDC/tb/unit/tb_hit_capture_bridge_unit.sv`
- `docs/timing_closure/O3_*.md`

Tool stage:

- local Verilator complete; Genus server required

Was this actually run by agent locally?

- yes, for lint and focused unit tests

Was this run by human on lab server?

- no

Evidence location:

- local Verilator result directories under `results/local_verilator/`
- O3 docs under `docs/timing_closure/`

Local Verilator:

- preliminary lint: PASS (`20260601_o3_lint_prelim`)
- `tb_slow_epoch_johnson_unit`: PASS
- `tb_stop_epoch_capture_async_unit`: PASS
- `tb_johnson_decode_unit`: PASS
- `tb_pd_cell_tag_capture_unit`: PASS
- `tb_hit_capture_bridge_unit`: PASS
- full smoke: PASS (`results/local_verilator/20260601_o3_smoke/`)
- `tb_start_wdt`: PASS
- `tb_watchdog_recovery`: PASS
- VIP `start_watchdog`: PASS

Functional result:

- Packet layout is unchanged.
- `nslow` remains decoded in RTL.
- HIT `nfast` remains raw fast LFSR tag in O2/O3 raw-tag mode.

Timing result:

- unknown until Genus O3 run.

Linearity/precision risk:

- medium. The slow epoch source changed, but `nslow` remains decoded into the
  existing field. STOP raw capture uses one-bit-change Johnson state to reduce
  async incoherency risk relative to binary/LFSR.

Decision:

- O3 Genus is the next useful server run after committing/pushing the O3 patch.

Next action:

- Ask human to run `server_run_genus_o3_raw_epoch_cleanup.sh` on the lab server
  after the O3 patch is committed and pushed.

## 2026-06-02 - O4_MUXLESS_TAGS_AND_R600_PD_LOCKED prepared

Branch: `SPADMIC_localtag`

Base HEAD before O4 edits: `fb8210c55c01f95ec5fc795d4da39d8b543e9a5a`

Purpose:

- Keep the local raw fast-tag architecture and slow Johnson epoch.
- Keep PD behavior locked per designer instruction.
- Remove oscillator-domain enable/hold muxes from fast and slow tag generators.
- Convert the clk_sys START watchdog to a countdown.
- Prepare nominal and R600 Genus fast-feasibility runs with optional closure rerun only for a promising mode.

Files changed:

- `MPTDC/rtl/pd/mptdc_fast_epoch_tag.sv`
- `MPTDC/rtl/pd/mptdc_slow_epoch_johnson.sv`
- `MPTDC/rtl/top/mptdc_core.sv`
- `MPTDC/tb/unit/tb_fast_epoch_tag_unit.sv`
- `MPTDC/tb/unit/tb_slow_epoch_johnson_unit.sv`
- `MPTDC/syn/inputs/mptdc.defines`
- `MPTDC/syn/scripts/settings.tcl`
- `MPTDC/syn/filelist_o4_muxless_tags_r600.f`
- `MPTDC/syn/inputs/mptdc_osc_pd_o4.sdc`
- `MPTDC/syn/scripts/server_run_genus_o4_muxless_tags_r600.sh`
- `docs/timing_closure/O4_*.md`

Functional result:

- Packet layout unchanged.
- HIT `nfast` remains raw LFSR tag in raw-tag mode.
- `nslow` remains decoded from STOP-captured Johnson state in clk_sys.
- PD detection/freeze behavior is not redesigned.

Server result:

- pending O4 Genus run.

Local Verilator:

- `tb_fast_epoch_tag_unit`: PASS
- `tb_slow_epoch_johnson_unit`: PASS
- `tb_pd_cell_tag_capture_unit`: PASS
- `tb_pd_gate_false_hit_unit`: PASS
- `tb_drain_raw_tag_unit`: PASS
- `tb_start_wdt`: PASS
- `tb_drain_ctrl_unit`: PASS
- full local smoke `20260602_o4_muxless_tags_smoke`: PASS, 17 steps passed, 0 failed

Next action:

- Commit/push O4 patch, then run `server_run_genus_o4_muxless_tags_r600.sh` on the lab server.
