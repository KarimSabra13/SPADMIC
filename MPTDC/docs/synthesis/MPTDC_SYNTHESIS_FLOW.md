# MPTDC Synthesis Flow

Author: Karim Sabra

The active synthesis flow is the Cadence Genus typical-closed handoff flow for
`mptdc_axis_core`. It produces the mapped netlist/SDC package consumed by
Innovus. It is not MMMC or final tapeout signoff.

The June 18, 2026 clean handoff is valid only for the exact RTL commit that
generated it. Any RTL interface, phase-buffer, SDC, library, or profile change
invalidates that handoff and requires a fresh canonical Genus run before PnR.

## Canonical command

Run from the repository root:

```bash
bash MPTDC/syn/scripts/run_genus_axis_core_typical_closed.sh [run_id]
```

The optional argument names the run directory. Without it, the run ID is
`MPTDC_TC_Closure_Genus`. No timing-policy arguments or environment overrides
are accepted. Work-root and machine infrastructure such as `MPTDC_WORK_ROOT`,
`PDK_ROOT`, and `SC_ROOT` remain environment-configurable; closure decisions do
not.

Legacy public filenames (`server_run_genus_mptdc_typical.sh`,
`server_run_genus_mptdc_timing_closure.sh`,
`server_run_genus_mptdc_final_typical.sh`, and the old axis timing-close name)
are compatibility shims to the same canonical entrypoint.

## Flow layering

1. `run_genus_axis_core_typical_closed.sh` validates the repository, input files,
   run ID, clean-tree policy, and current checkout guard.
2. `scripts/profiles/genus_axis_core_typical_closed.sh` owns the validated
   closure policy and rejects inherited experiment variables.
3. `filelist_axis_core_typical_closed.f` names the product RTL and synthesis
   defines without presenting O13 as the flow name.
4. `inputs/mptdc_axis_core_typical_closed.sdc` is the canonical SDC entrypoint.
5. `server_run_genus_o13_phase_distribution.sh` remains the internal backend for
   historical report compatibility and result parsing.
6. `procedures.tcl` performs the mapped repair, reporting, and fail-closed count
   checks.

This separation allows the backend to retain historical labels while the handoff
interface exposes one stable purpose-based flow.

The canonical wrapper pins the backend `EXPECTED_HEAD` guard to the current
checkout. This prevents an inherited stale experiment SHA from aborting a valid
handoff rerun while still catching accidental checkout drift inside the backend.

## Validated timing policy

The profile reproduces the June 18, 2026 clean run:

- typical-only `R750_delta5` timing model;
- JIHD standard cells and timing-focused optimization;
- exact 64-path PD Vernier q1 exception with eight sources;
- exact fast-tag path constraints using the full `1.333 ns` C-to-D budget;
- exact fast-tag source-cell remapping disabled;
- broad PD hit-to-nfast delay/transition pressure disabled;
- local ON22 discovery from timing reports;
- 448 expected local endpoints;
- driver/cell count policy `AUTO` because 355 unique real ON22 drivers is valid;
- requested targets `ON22JIHDX1 ON22JIHDX2` with X2 prohibited;
- 355 resolved `ON22JIHDX0` instances resized to X1 in the reference run.

The detailed rationale and impact of each setting is documented in
[`GENUS_AXIS_CORE_TYPICAL_CLOSED_PROFILE.md`](GENUS_AXIS_CORE_TYPICAL_CLOSED_PROFILE.md).

## Inputs

Protected synthesis inputs include:

- `filelist_axis_core_typical_closed.f`;
- `inputs/mptdc_axis_core_typical_closed.sdc` and its stable delegates;
- `inputs/README.md` for constraint ownership and edit rules;
- `macros/RO_tune6_real_layout_shell.lib`;
- `analog_handoff/real_ro_tune6_layout.env`;
- `analog_handoff/audit_ro_tune6_layout.py`;
- `scripts/profiles/genus_axis_core_typical_closed.sh`;
- the Genus backend and `procedures.tcl`.

The active RO rerun expects the exported physical LEF at
`/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef`. The RTL instance
name remains `u_ro_tune4` for constraint stability, but the instantiated macro
master is `RO_tune6`. See
`MPTDC/analog_handoff/RO_TUNE6_LAYOUT_EXPORT.md` for the OA source, required
LEF contents, exact output name, and audit commands.

Historical O13/ABS/REPAIR files remain protected because the stable aliases and
report parsers delegate to them. They are not recommended commands.

## Output and decision policy

The wrapper writes to `work/genus/<run_id>/`, records git HEAD/branch, and prints
`FINAL_SIGNOFF=NO`. A typical closure decision requires:

- Genus exit code zero;
- exact PD exception and local-repair discovery checks;
- no active SDC failures or invalid objects;
- setup WNS at least zero, zero setup violating paths, and zero TNS within report
  numerical tolerance;
- zero max-transition, max-capacitance, and max-fanout violations;
- no unclassified new real path family.

The reference result is WNS `+0.3 ps`, TNS `-0.0 ps`, zero setup violations, and
zero DRVs. The later server rerun
`20260618_axis_core_typical_closed_handoff_rerun2` reproduced closure at commit
`d290cd7dc15222a343e4c8c0e60005494ac62ec4` and passed the pre-PnR handoff gate,
with the explicit warning that the WNS margin is only `+0.3 ps`.

That result authorizes only the next implementation step for that exact
netlist. The current RO-code RTL interface change creates a new netlist
contract, so the old handoff must be treated as reference evidence, not as the
active PnR input. After any profile, RTL, library, SDC, or parser change, run
the profile checker and a fresh server Genus comparison before updating the
baseline.
