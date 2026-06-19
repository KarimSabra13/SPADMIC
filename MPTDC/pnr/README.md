# MPTDC PnR

Author: Karim Sabra

This directory contains Innovus collateral for the active `mptdc_axis_core`
product boundary. The historical `final_typical` wrappers are typical-only
implementation helpers. The digital signoff flow is separate and must produce
MMMC, extraction, DRC/LVS, CTS, power, routing, and phase-symmetry evidence
before any signoff claim.

## Active Entry Points

Run from the repository root:

```bash
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_feasibility.sh
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_typical.sh
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_final_typical.sh
bash MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh <run_id> --mode discover_only
MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1 \
  bash MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh <run_id> --mode validate_only --genus-run-id <fresh_genus_run_id> --handoff-dir <handoff_dir>
MPTDC_DIGITAL_SIGNOFF_APPROVED=1 MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1 \
  bash MPTDC/pnr/scripts/server_run_innovus_mptdc_digital_signoff.sh <run_id> --mode full_signoff --genus-run-id <fresh_genus_run_id> --handoff-dir <handoff_dir>
bash MPTDC/pnr/scripts/qualify_xh018_row_infrastructure.sh <run_id>
```

Use the feasibility wrapper first after a clean canonical Genus rerun. The
`final_typical` wrapper is still typical-only and requires explicit approval
before launching a real implementation mode. The digital signoff wrapper is the
owner-facing digital PNR entrypoint. Its source gate allows the reviewed
no-dedicated-CORE-tap/endcap policy only when
`MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1` is set; this permits implementation
with `ROW_INFRA_STATUS=PROVISIONAL`, not final PASS. Final PASS remains blocked
until row-infrastructure or final-block DRC/LVS proves the policy.

## Active Physical Intent

- Product top: `mptdc_axis_core`.
- Input netlist/SDC source: canonical Genus axis-core typical-closed flow.
- Standard-cell family: JIHD for the current closed Genus result.
- Macro model: real `RO_tune4` abstract shell, not the old oscillator stub.
- Phase distribution target: `BUJIHDX4 -> BUJIHDX12` per slow/fast tap. The
  2026-06-18 JIHD discovery proved both masters in JIHD LEF/Liberty; any BUHD
  handoff is legacy input only.
- Floorplan target: horizontally elongated `4:3` block boundary, accepted range
  `1.20 <= width/height <= 1.47`.
- Measurement stack: slow RO north, slow phase buffers, central `8 x 8` PD
  matrix, fast phase buffers, fast RO south, backend logic east.
- Clock policy: `clk_sys` is the ordinary CTS target; RO and buffered phase
  clocks are measurement clocks and must not be flattened into normal CTS.
- Required audits: RO interface, phase-buffer clock model, pin geometry, power
  geometry, CTS state, timing, congestion, antenna, and physical verification
  are separate gates.
- `config/xh018_cells.tcl` is a reviewed per-class policy source. JIHD FEED
  fillers, FCPE/FEED spacers, decaps, antenna cells, ties, CTS cells,
  `BUJIHDX4/BUJIHDX12`, `core_jihd`, and `vddi/gndi` PG pins are known. CORE
  tap/endcap masters were not found, so tap/endcap lists remain empty under
  `NO_DEDICATED_MASTER_PENDING_DRC_LVS`. IO `CORNER*`/ENDCAP pad-ring cells are
  explicitly rejected for core rows. Implementation is allowed only with
  `MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1`; final signoff is not allowed until
  DRC/LVS evidence qualifies the policy.

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
