# MPTDC Innovus Implementation Plan

Status: `PLANNED_AFTER_GENUS_REVIEW`

Do not run Innovus implementation until the stable Genus typical result is
either clean or explicitly accepted as physical-placement-sensitive.

## Current Wrapper Limitation

`MPTDC/pnr/scripts/server_run_innovus_mptdc_feasibility.sh` is a feasibility
wrapper. It currently delegates to a report/checkpoint-oriented compatibility
flow and is not the final implementation flow.

## Required Future Mode

Future user-facing mode:

```text
MPTDC_INNOVUS_IMPLEMENTATION_TYPICAL
```

Required inputs:

- Genus netlist from `work/genus/<GENUS_RUN_ID>/outputs/`
- Genus exported SDC or an Innovus-safe equivalent SDC
- RO_tune4 LEF abstract
- XH018 standard-cell LEF/Liberty setup
- XLIBD report config for interpretation only
- reviewed floorplan, power, and IO plans

## Implementation Stages

1. Read final Genus netlist and constraints.
2. Initialize floorplan.
3. Place slow and fast `RO_tune4` macros.
4. Place the 8x8 PD matrix regularly.
5. Place BUHDX4 and BUHDX12 phase-buffer chains near the RO/PD fabric.
6. Define power nets and build the power plan.
7. Place IO pins.
8. Place standard cells.
9. Run CTS on `clk_sys` only.
10. Do not run CTS on raw RO clocks or buffered phase clocks.
11. Route.
12. Report timing, DRV, congestion, route DRC, raw RO load, phase-buffer output load, phase route mismatch, and PD grid symmetry.

## Required Reports

- timing summary by path family
- design-rule violations
- congestion and route DRC
- raw RO pin capacitance
- phase-buffer output capacitance
- phase route mismatch
- PD grid symmetry
- clock-tree report for `clk_sys`
- proof that RO and phase clocks were not CTS-managed

## Gate

The implementation flow starts only after reviewed Genus evidence exists in:

```text
work/genus/<GENUS_RUN_ID>/final_typical_genus_readiness.md
```
