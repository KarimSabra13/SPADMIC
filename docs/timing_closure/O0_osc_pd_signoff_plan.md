# O0 Oscillator/PD Signoff Plan

Status: PROVISIONAL - NOT ANALOG VERIFIED

## Purpose

O0 is a separate oscillator/phase-detector signoff track.  It pauses the H4b
backend-only lab run and focuses on making the oscillator/PD fabric physically
reviewable in Genus/Innovus while complete analog `.lib` and `.lef` views are
still missing.

This work does not modify PD-cell measurement semantics, oscillator enable
semantics, START/STOP behavior, STOP metadata capture, or raw calibration
fields.

## Current Design Facts

- Slow oscillator hierarchy: `u_core/u_osc_slow/u_stub`
- Fast oscillator hierarchy: `u_core/u_osc_fast/u_stub`
- PD matrix hierarchy: `u_core/gen_pd_row[ns]/gen_pd_col[nf]/u_pd`
- PD count target: 64 cells, `ns=0..7`, `nf=0..7`
- Current RTL uses synthesizable `mptdc_osc_stub`, not separate slow/fast hard macro instances.
- Existing SDC creates slow and fast tap clocks on the stub phase pins.
- Existing backend timing work remains H1b/H4b and is not modified by O0.

## Physical Target

The intended sandwich layout is:

```text
north: slow oscillator macro, slow_phase[0:7] pins on bottom
center: 8 x 8 PD matrix, matched slow/fast routing
south: fast oscillator macro, fast_phase[0:7] pins on top
right: clk_sys backend island
```

The backend island contains the hit capture bridge, measurement controller,
context bank, drain controller, FIFO, and shared/local readout.  Normal digital
buses should not route through the sensitive phase-routing region unless there
is no practical alternative.

## Topology Evaluation

Topology A is the provisional default:

- columns = slow tap index `ns`
- rows = fast tap index `nf`
- `slow_phase[ns]` routes as a north-to-south column trunk
- `fast_phase[nf]` routes as a south-to-row distribution trunk

Topology B remains open until real macro pin coordinates arrive:

- columns = fast tap index `nf`
- rows = slow tap index `ns`
- `fast_phase[nf]` routes as a south-to-north column trunk
- `slow_phase[ns]` routes as a north-to-row distribution trunk

Decision rule: prefer the topology that gives the fast sampling clocks the most
regular and lowest-skew routing, unless slow tap mismatch becomes materially
worse.  If pin order is reversed, try legal macro mirroring/orientation before
creating long crossing routes through the PD matrix.

## Provisional Macro Views

Generated files:

- `MPTDC/syn/macros/mptdc_osc_slow_provisional.lef`
- `MPTDC/syn/macros/mptdc_osc_fast_provisional.lef`
- `MPTDC/syn/macros/mptdc_osc_slow_provisional.lib`
- `MPTDC/syn/macros/mptdc_osc_fast_provisional.lib`

Generator:

- `tools/osc/gen_osc_macro_views.py`
- `tools/osc/oscillator_macro_template.yaml`

The provisional Liberty is for tool integration only.  The output phase timing
is modeled by SDC tap clocks.  No internal oscillator startup, jitter, phase
order, tune-code behavior, or PVT signoff is represented by the Liberty.

Important unresolved binding issue: the current RTL does not instantiate the
two provisional macro cell names directly.  The O0 scripts load the views and
reserve macro regions, but final hard macro placement requires either real
analog wrapper modules or an approved netlist/macro binding strategy.

## Constraint Strategy

Overlay:

- `MPTDC/syn/inputs/mptdc_osc_pd_physical.sdc`

The overlay is opt-in through `MPTDC_OSC_PD_SDC_OVERLAY`.  It does not add
clk_sys false paths.  It records oscillator nominal periods, applies
provisional phase-net transition/cap targets when nets match, and creates
report groups for PD capture, fast counter, slow counter, and held-bus bridge
review.

Real timed paths:

- `clk_sys` backend paths
- fast counter internal paths
- fast counter to `nfast_hit` capture paths unless proven otherwise
- PD internal same-fast-clock paths
- slow counter/watchdog paths when ordinary sequential timing applies

Intentional waived paths:

- slow phase sampled by fast phase inside PD cells
- START/STOP event capture
- STOP metadata event capture

CDC/async paths:

- held PD/counter/STOP metadata bus into `mptdc_hit_capture_bridge`
- async PD/counter clears
- reset assertion and synchronous release

Unresolved paths:

- Any `UNKNOWN_REVIEW_REQUIRED` result from `tools/timing/classify_mptdc_timing_paths.py`
- Any real fast-domain path hidden by broad async grouping or missing generated clocks
- Any phase-net load/RC imbalance without analog-approved budget

## Physical Scripts

PnR scripts:

- `MPTDC/pnr/scripts/osc_pd_regions.tcl`
- `MPTDC/pnr/scripts/pd_matrix_floorplan.tcl`
- `MPTDC/pnr/scripts/osc_pd_route_guides.tcl`
- `MPTDC/pnr/scripts/report_pd_instance_symmetry.tcl`
- `MPTDC/pnr/scripts/report_pd_phase_routes.tcl`
- `MPTDC/pnr/scripts/report_osc_tap_loads.tcl`
- `MPTDC/pnr/scripts/server_run_innovus_osc_pd_signoff.sh`

The Innovus estimate flow now has O0 hooks gated by `MPTDC_OSC_PD_ENABLE=1`.
Normal Innovus runs are unchanged unless that variable is set.

## Report Outputs

Genus O0:

- `results/genus_osc_pd/<RUN_ID>/SUMMARY.md`
- timing summary/violations
- PD capture and oscillator counter hotspot reports
- clocks, clock groups, exceptions, constraints
- path classification CSV/summary

Innovus O0:

- `results/osc_pd/<RUN_ID>/floorplan_summary.rpt`
- `macro_placement.rpt`
- `pd_instance_placement.csv`
- `pd_instance_symmetry_summary.md`
- `phase_net_rc.csv`
- `phase_net_balance_summary.md`
- `tap_loads.csv`
- `tap_load_balance_summary.md`
- `nfast_count_bus_rc.csv`
- timing/DRV/congestion/clock reports
- path classification CSV/summary

## What Counts As Closed

O0 cannot be signed off with one WNS number.

Real digital timing must close or be redesigned:

- PD same-fast-clock logic
- fast counter internal paths
- fast counter to `nfast_hit`
- slow-domain ordinary sequential paths
- clk_sys backend paths

Intentional measurement crossings need waiver evidence:

- PD slow-to-fast Vernier sampling
- STOP event capture
- START/STOP latch behavior

Physical matching must be reported:

- slow/fast tap total load
- tap load mismatch
- route delay mismatch
- PD grid and orientation
- phase0 extra load
- `nfast_src_count` bus RC/skew
- digital noise proximity to phase nets

Without real analog macro views, final status remains:

```text
PROVISIONAL PHYSICAL CLOSURE ONLY
NOT SILICON SIGNOFF
```

## Plan B Frequency Derating

Do not derate because intentional PD sampling reports as a digital violation.
Only consider Plan B if a real fast-domain path cannot close, the analog
oscillator cannot drive extracted load, tap load/slew exceeds analog max, or PVT
analog simulations show insufficient margin.

Any derate must preserve the Vernier delta first.  The exact slow/fast tune-code
pairs must come from analog simulation, not digital guessing.
