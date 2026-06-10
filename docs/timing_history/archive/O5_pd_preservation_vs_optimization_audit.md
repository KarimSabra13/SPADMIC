# O5 PD Preservation Versus Optimization Audit

Branch: `SPADMIC_localtag`

## Problem

The PD matrix has real physical symmetry requirements, but O4 over-protected the PD internals for a timing experiment:

- `mptdc_pd_cell.sv` module attribute had `keep_hierarchy`, `dont_touch`, and `preserve`.
- `mptdc_core.sv` PD instance attribute had `keep_hierarchy`, `dont_touch`, and `preserve`.
- `mptdc_preserve_physical_hierarchy` applied `dont_touch` to `*gen_pd_row*gen_pd_col*u_pd*`, `*u_pd*`, and `*mptdc_pd_cell*`.

This can block:

- remapping resettable timestamp flops to faster no-reset flops
- automatic clock-gating inference
- local data-path optimization inside the PD cell
- useful cloning/sizing of freeze-control gates

## Required Physical Intent

The PD island still needs:

- 8x8 regular hierarchy visible in reports
- one equivalent PD structure per matrix cell
- row/column naming preserved for placement
- symmetric slow/fast phase loading
- no random per-instance flattening that hides mismatches

The hierarchy should be preserved for review and floorplanning. The internals should not be `dont_touch` during O5.

## O5 Policy

O5 keeps:

- `(* keep_hierarchy = "yes" *)` on the PD cell
- `(* keep_hierarchy = "yes" *)` on each PD instance
- `ungroup_ok=false` best-effort when `MPTDC_RELAX_PD_PRESERVE=1`

O5 relaxes:

- RTL `dont_touch` on `mptdc_pd_cell`
- RTL `dont_touch` on PD instances
- Genus procedure `dont_touch` on PD cells/modules when `MPTDC_RELAX_PD_PRESERVE=1`

Reset synchronizers and CDC synchronizer flops remain protected.

## Genus Mode Use

The O5 server script uses:

- `MPTDC_RELAX_PD_PRESERVE=1` for `O5_NORESET_TS`
- `MPTDC_RELAX_PD_PRESERVE=1` for `O5_CLOCK_GATED_TS`

This makes the O5 result a real optimization experiment, not a rerun of a frozen PD cell.

## Stop Conditions

Stop and review if:

- PD hierarchy disappears from reports.
- Netlist has asymmetric PD instance treatment.
- Clock gating is inserted into only some PD cells.
- Old fast counter or slow counter residue reappears.
- `UNKNOWN_REVIEW_REQUIRED` paths appear.
- Broad new timing exceptions hide PD timestamp logic.

## Expected Good Result

A good O5 fast-feasibility result should show:

- old global fast counter path still absent
- timestamp flops no longer resettable, or resettable timestamp flop count greatly reduced
- in clock-gated mode, ICG cells appear in the netlist
- `PD_HIT_TO_TS_FREEZE` path count and WNS improve substantially
- no broad false paths
- no packet layout change
