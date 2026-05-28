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
