# MPTDC Synthesis Inputs

Author: Karim Sabra

Use `mptdc_axis_core_typical_closed.sdc` as the canonical Genus constraint
entrypoint. The wrapper selects it automatically; handoff runs should not build
an alternate SDC stack through shell arguments.

## Active files

| File | Purpose |
| --- | --- |
| `mptdc_axis_core_typical_closed.sdc` | Purpose-named entrypoint for the closed typical baseline. |
| `mptdc_pd_vernier_exceptions.sdc` | Stable alias for the exact PD Vernier exception. |
| `mptdc_osc_typical_r750_delta5_o13_abs5.sdc` | Historical implementation overlay with exact object-count checks. |
| `mptdc_osc_typical_r750_delta5_o13_abs3.sdc` | Historical clock and CDC overlay used by ABS5. |
| `mptdc_freq_modes.defines` | Frequency-mode constants consumed by the backend. |

The historical O13 and ABS filenames remain for report correlation and internal
Tcl compatibility. They are not independent handoff flows.

## Current intent

- Top: `mptdc_axis_core`.
- View: typical-only `R750_delta5`.
- Phase distribution: `BUJIHDX4 -> BUJIHDX12`.
- Exact exception scope: eight slow-phase sources and 64 q1 endpoints.
- q1-to-q2, local capture, fast-tag, reset, control, FIFO, and packet paths stay
  timed.
- Boundary: not MMMC and not final tapeout signoff.

Changes to periods, uncertainty, object counts, exception matching, path budgets,
or design-rule limits require a named profile experiment and a before/after
report. Historical SDC filenames remain only where the canonical entrypoint
delegates to them or where backend compatibility still requires them; they are
not source-of-truth handoff commands.
