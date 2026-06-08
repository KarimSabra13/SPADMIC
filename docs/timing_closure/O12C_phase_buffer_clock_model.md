# O12C Phase Buffer Clock Model

REPORT_STATUS=REVIEW_REQUIRED

After O12, the analog RO pin and the digital phase clock point are different physical points.

Model:

```text
RO_tune4/S[n]       analog source point and analog load check
BUHDX4/Q phase net  digital phase clock source for PD/tag/epoch fabric
```

Preferred STA behavior:

- Create source clocks at `RO_tune4/S[n]`.
- Create generated clocks at each phase buffer output.
- Generated clocks inherit period and phase from the source tap.
- Buffer insertion delay remains visible and reportable.
- Do not broad false-path the phase buffers.
- Do not hide phase-buffer delay.
- Do not send RO or buffered phase clocks through normal CTS.
- `clk_sys` remains the normal CTS clock.

The existing O12 Innovus overlay already implements this generated-clock model.  O12C adds:

```text
MPTDC/pnr/constraints/mptdc_osc_typical_r750_delta5_phasebuf_innovus.sdc
```

That file sources the O12 phase-buffer overlay and labels the run as O12C topology/placement closure.

Timing reports must state whether capture clocks are modeled from RO pins or from buffer outputs.  If the tool cannot propagate generated clocks cleanly, document the actual model and keep the risk visible.
