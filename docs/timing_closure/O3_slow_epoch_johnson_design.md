# O3 Slow Epoch Johnson Design

## Why Change

O2 Genus shows the slow coarse source is still a binary counter plus Gray encode
in the `slow_phase[0]` oscillator domain. That creates real setup paths around
1 ns that are not realistic in XH018 standard cells.

The previous slow path also synchronized and decoded Gray state into the fast
domain, creating `clk_osc_fast` violations that are unnecessary for packet
generation.

## O3 Design

Module:

- `MPTDC/rtl/pd/mptdc_slow_epoch_johnson.sv`

State:

- 64-bit Johnson/twisted-ring state.
- 128 valid states.
- reset/clear state is all zeros.
- each enabled slow edge advances with:

```systemverilog
johnson_o <= {johnson_o[62:0], ~johnson_o[63]};
```

Properties:

- no binary carry chain.
- one bit changes per transition.
- STOP-edge asynchronous capture is less vulnerable to incoherent multi-bit
  samples than a binary or arbitrary LFSR state.

STOP capture module:

- `MPTDC/rtl/async/mptdc_stop_epoch_capture_async.sv`

The raw Johnson state is captured on the real STOP edge and held until
`meas_pd_clear`.

Decode:

- `mptdc_pkg::slow_johnson_to_count()`.
- called by `mptdc_hit_capture_bridge` when `sample_en_i` samples the held
  measurement image.
- packet/context `nslow` remains a 7-bit decoded count.

## Semantics

Before O3:

- `nslow` came from a binary counter encoded as Gray, STOP-captured, transferred
  to fast domain, decoded in fast domain, then sampled by `clk_sys`.

After O3:

- raw Johnson slow epoch is STOP-captured and held.
- `clk_sys` bridge decodes to the existing 7-bit `nslow`.

Packet width/layout is unchanged. `nslow` remains decoded in RTL for
compatibility.

## Residual Risk

The Johnson decode is now clk_sys logic. If Genus shows this path is too long,
pipeline the decode in clk_sys rather than moving decode back into an oscillator
domain.

Final signoff still requires analog confirmation of oscillator behavior and
physical matching reports.
