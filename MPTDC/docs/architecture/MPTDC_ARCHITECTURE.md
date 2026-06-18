# MPTDC Architecture

This document describes the active SPADMIC product-axis RTL. It is an
architecture contract, not a final physical-signoff statement.

## Product boundary

The maintained top is `rtl/top/mptdc_axis_core.sv`. It selects SPAD or
calibration START/STOP inputs, generates a synchronized local reset, instantiates
`mptdc_core`, and exports the fixed 16-bit packet stream plus ready/busy/FIFO
status. `mptdc_top_asic` belongs to an older standalone boundary and is not the
active product synthesis top.

`rtl/top/mptdc_core.sv` integrates:

- slow and fast oscillator phase families;
- buffered phase distribution;
- the `8 x 8` Vernier detector matrix;
- local fast tag and slow epoch capture;
- async frontend/context ownership;
- held-context CDC into `clk_sys`;
- measurement control, drain, watchdog, FIFO, and packet readout.

## Clock and reset domains

`clk_sys` owns ordinary control, status, draining, FIFO operation, and packet
transmission. Slow and fast oscillator phases own measurement-local activity.
The design does not assume synchronous phase relationships between these
families.

The product reset asserts asynchronously and deasserts through explicit local
synchronizers. Reset synchronizer attributes and staggered depths are preserved
to prevent optimization from rebuilding one high-fanout reset tree. Changes to
reset structure require CDC, recovery/removal, and physical review.

## Oscillators and phase distribution

Physical synthesis binds two `RO_tune4` macro abstracts, one slow and one fast.
Their `S[0:7]` pins are raw analog phase sources and remain auditable load points.
Each tap uses the validated digital topology:

```text
RO_tune4/S[n] -> BUHDX4 -> BUHDX12 -> digital phase fabric
```

The final `BUHDX12` outputs are modeled as buffered phase clocks for the current
typical flow. RO and phase clocks are not ordinary `clk_sys` CTS targets.

## Vernier detector matrix

The detector is an `8 x 8` matrix: each row corresponds to one slow phase and
each column to one fast phase. The slow-to-fast q1 sampling relation is the
intentional Vernier measurement. The synthesis exception is therefore narrow,
fail-closed, and count-checked at eight sources and 64 q1 endpoints.

The exception does not cut q1-to-q2, hit latching, local nfast capture, fast-tag,
reset, control, FIFO, or packet paths. Those remain real timing paths.

## Tags, epoch, and context capture

The current architecture uses a local fast raw tag and a slow Johnson epoch.
These preserve measurement context without a global high-speed binary counter.
The sampled PD image and associated metadata are held in a context bank before
`clk_sys` consumes them. Control crossings use explicit synchronization; the
multi-bit context image relies on a documented static-held-bus protocol after
its ownership/ready handshake.

## Drain and packet contract

The drain controller serializes complete context records into a synchronous
FIFO. `mptdc_packet16_tx` emits the fixed narrow packet with valid/ready and
SOP/EOP. Packet field meanings, order, calibration interpretation, and
backpressure behavior are external contracts; cleanup work must not change them
implicitly.

## Active physical assumptions

- Product top: `mptdc_axis_core`.
- Frequency mode: `R750_delta5`.
- Standard-cell family for the closed Genus run: JIHD.
- Typical-only Genus timing view.
- Real `RO_tune4` macro binding.
- Buffered `BUHDX4 -> BUHDX12` phase distribution.
- Exact count-checked PD Vernier exception.
- Scoped local ON22 X0-to-X1 repair on real endpoint cones.

Final MMMC timing, extracted parasitics, analog phase/jitter confirmation, LVS,
DRC, PEX, and post-layout characterization remain outside this architecture
claim.
