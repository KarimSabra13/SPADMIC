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
