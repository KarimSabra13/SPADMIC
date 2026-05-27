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
