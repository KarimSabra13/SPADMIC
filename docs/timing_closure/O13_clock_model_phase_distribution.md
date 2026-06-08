# O13 Clock Model For Phase Distribution

REPORT_STATUS=REVIEW_REQUIRED

O13 creates three meaningful timing/load points per tap:

```text
RO_tune4/S[n]
  -> BUHDX4 u_iso/Q
  -> BUHDX12 u_drv/Q
  -> digital phase fabric
```

## Timing Points

| Point | Role | Timing meaning |
|---|---|---|
| `RO_tune4/S[n]` | analog source | source clock and raw RO load check |
| `u_iso/Q` | isolation internal node | first-stage delay/load evidence |
| `u_drv/Q` | final phase driver output | digital phase clock source for PD/tag/epoch fabric |

The analog and digital phase points are no longer the same physical node.  Reports must keep them separate.

## Preferred STA Model

- Create raw oscillator clocks at `RO_tune4/S[n]`.
- Create generated clocks at the final `BUHDX12 u_drv/Q` outputs.
- Use divide-by-1 generated clocks so period and tap relation are preserved.
- Keep buffer insertion delay visible and reportable.
- Do not broad false-path the phase-buffer chain.
- Do not send RO or phase-buffer clocks through normal CTS.
- Keep `clk_sys` CTS separate.

The generated digital phase clocks keep the existing naming pattern:

```text
clk_osc_slow_buf_tap0..7
clk_osc_fast_buf_tap0..7
```

The O13 synthesis overlay is:

```text
MPTDC/syn/inputs/mptdc_osc_typical_r750_delta5_o13_phase_distribution.sdc
```

The O13 Innovus overlay is:

```text
MPTDC/pnr/constraints/mptdc_osc_typical_r750_delta5_o13_phase_distribution_innovus.sdc
```

## Required Review Questions

- Did all 16 raw RO pins match?
- Did all 16 `BUHDX4 u_iso/A` pins match?
- Did all 16 `BUHDX4 u_iso/Q` pins match?
- Did all 16 `BUHDX12 u_drv/A` pins match?
- Did all 16 `BUHDX12 u_drv/Q` pins match?
- Were 16 final-driver generated clocks created?
- Are phase-buffer clocks excluded from CTS?
- Is buffer-chain delay visible in timing reports?

If the tool cannot support the preferred generated-clock model cleanly, document the actual behavior and mark timing decision quality as incomplete.  Do not hide the O13 buffer delay with broad false paths.
