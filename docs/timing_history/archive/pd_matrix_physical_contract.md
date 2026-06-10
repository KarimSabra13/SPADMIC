# PD Matrix Physical Contract

Status: PROVISIONAL - thresholds are placeholders until analog budgets arrive.

## Structural Requirements

- Exactly 64 PD instances exist.
- All 64 use the same logical master/signature.
- All 64 are preserved through synthesis/PnR.
- All 64 are placed in an 8 x 8 regular grid.
- Orientation is controlled, either identical or deliberately mirrored.
- Slow tap routes use the same layer strategy.
- Fast tap routes use the same layer strategy.
- Cells for the same slow tap see matched slow RC.
- Cells for the same fast tap see matched fast RC.
- All taps have bounded total capacitance.
- All taps have bounded capacitance mismatch.
- All taps have bounded route-delay mismatch.
- No normal digital standard cells are placed inside phase-routing channels.
- The right-side backend island is separated from phase nets.

## Provisional Numeric Targets

Tap total load:

- Must be <= analog max load.
- If analog max load is unknown, report only; do not sign off.

Tap load mismatch:

- target <= 2%
- warning <= 5%
- fail > 10% unless analog approves

Tap RC delay mismatch:

- target <= 0.5 ps
- warning <= 1.0 ps
- fail > 2.5 ps unless calibration/analog approves

Tap slew mismatch:

- target <= 5%
- warning <= 10%
- fail > 20%

Via-count mismatch:

- target equal
- warning if +/-1
- fail if systematic imbalance

Route-layer mismatch:

- target same layer stack for sibling taps
- fail if one tap uses materially different routing topology

PD placement:

- target exact grid
- fail if placement breaks row/column regularity

PD orientation:

- target identical or deliberate mirror pattern
- fail if uncontrolled/random orientation

## Topology Review

Evaluate both topologies after real analog pin order is known:

Topology A:

- columns = slow tap index `ns`
- rows = fast tap index `nf`
- slow taps as vertical north-to-south trunks
- fast taps as row distribution from south macro

Topology B:

- columns = fast tap index `nf`
- rows = slow tap index `ns`
- fast taps as vertical south-to-north trunks
- slow taps as row distribution from north macro

Default preference: make fast sampling clocks the most regular and lowest skew,
unless the slow tap mismatch becomes materially worse.

## Required Reports

- `pd_instance_placement.csv`
- `pd_instance_symmetry_summary.md`
- `phase_net_rc.csv`
- `phase_net_balance_summary.md`
- `tap_loads.csv`
- `tap_load_balance_summary.md`
- `nfast_count_bus_rc.csv`
- `nfast_count_bus_summary.md`

Any unknown or missing data keeps the status at `PROVISIONAL_REVIEW_REQUIRED`.
