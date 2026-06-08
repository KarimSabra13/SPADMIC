# O12 Clock Model After Phase Buffers

Status: `O12_PHASE_ISOLATION_BUFFER_EXPERIMENT`

This is a typical feasibility clock-model note, not an MMMC or final signoff
constraint.

## Two Clock Boundaries

O12 creates two different review points:

| Boundary | Meaning |
|---|---|
| raw `RO_tune4/S[n]` | analog load and source waveform review |
| phase buffer output | downstream digital STA source for PD/tag/metadata logic |

For analog load checks, the raw RO pins matter.

For digital STA, the buffered phase nets are more appropriate because they are
the clocks that actually drive the downstream flops after O12 insertion.

## RTL Structure

`mptdc_core` now separates:

```systemverilog
slow_phase_raw[7:0], fast_phase_raw[7:0]
slow_phase[7:0],     fast_phase[7:0]
```

RO wrappers drive the raw nets.  `mptdc_phase_buffer_bank` drives the existing
`slow_phase` and `fast_phase` nets.  Downstream RTL is unchanged.

## Synthesis Clock Model

The O12 Genus overlay is:

```text
MPTDC/syn/inputs/mptdc_osc_typical_r750_delta5_o12_phase_buffers.sdc
```

It keeps the existing raw RO clocks and creates generated clocks at each
`BUHDX4/Q` output:

```text
clk_osc_slow_buf_tap0 .. clk_osc_slow_buf_tap7
clk_osc_fast_buf_tap0 .. clk_osc_fast_buf_tap7
```

The generated clocks are divide-by-1 clocks sourced from the corresponding raw
RO pin.  The overlay does not add broad false paths.

## Innovus Clock Model

The matching Innovus-safe overlay is:

```text
MPTDC/pnr/constraints/mptdc_osc_typical_r750_delta5_o12_phase_buffers_innovus.sdc
```

It recreates raw clocks if needed, then creates generated clocks through the
phase-buffer outputs.  This keeps the raw RO source pins visible for load
reporting while timing the digital fabric from the buffered phase nets.

## Timing Expectations

The O12 buffer bank adds insertion delay to all phase paths.  That delay is
acceptable only if it is:

- identical by topology;
- placed and routed symmetrically enough for calibration;
- stable over the operating condition being studied;
- monotonic with the intended tap order;
- visible in STA and reports.

Do not hide phase-buffer delay.  Do not broad false-path the phase fabric.  Do
not let CTS treat the RO phase buffers like `clk_sys`.

## Adoption Gate

O12 can move forward only if the server reports show:

- raw RO `S` pin max-cap fixed;
- buffer output loads are digitally drivable;
- tap-to-tap buffer/route mismatch is small and reviewable;
- no packet-format, raw-tag, R750_delta5, or PD functional regression;
- no evidence that the buffer insertion destroys Vernier monotonicity.
