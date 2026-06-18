# MPTDC PnR

Author: Karim Sabra

This directory contains Innovus collateral for the active `mptdc_axis_core`
product boundary. The current handoff target is Innovus feasibility from the
typical-closed Genus profile. It is not final tapeout signoff.

## Active Entry Points

Run from the repository root:

```bash
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_feasibility.sh
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_typical.sh
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_final_typical.sh
```

Use the feasibility wrapper first after a clean canonical Genus rerun. The
`final_typical` wrapper is still typical-only and requires explicit approval
before launching a real implementation mode.

## Active Physical Intent

- Product top: `mptdc_axis_core`.
- Input netlist/SDC source: canonical Genus axis-core typical-closed flow.
- Standard-cell family: JIHD for the current closed Genus result.
- Macro model: real `RO_tune4` abstract shell, not the old oscillator stub.
- Phase distribution: `BUHDX4 -> BUHDX12` per slow/fast tap.
- Clock policy: `clk_sys` is the ordinary CTS target; RO and buffered phase
  clocks are measurement clocks and must not be flattened into normal CTS.
- Required audits: RO interface, phase-buffer clock model, pin geometry, power
  geometry, CTS state, timing, congestion, antenna, and physical verification
  are separate gates.

## Directory Ownership

| Path | Purpose |
| --- | --- |
| `constraints/` | Stable PnR SDC aliases and physical constraint overlays. |
| `inputs/` | Innovus MMMC and input collateral consumed by scripts. |
| `scripts/` | Server wrappers, Tcl hooks, audit helpers, and report collection. |

Generated Innovus logs, reports, databases, snapshots, and tarballs belong
under `work/innovus/<run_id>/` or external server work directories. Do not add
raw PnR output back into this source directory.

## Source of Truth

Detailed policy is in
`MPTDC/docs/pnr/MPTDC_PNR_FLOW.md`. Timing readiness is in
`MPTDC/docs/timing_closure/MPTDC_TIMING_CLOSURE_STATUS.md`. Signoff boundaries
are in `MPTDC/docs/signoff_notes/MPTDC_SIGNOFF_LIMITATIONS.md`.

Before changing PnR scripts, state whether the change affects placement,
power, phase-buffer handling, clock modeling, routing, report parsing, or
launch policy. A physical-flow cleanup is not complete until the feasibility
wrapper validates from a clean tracked tree.
