# SPADMIC TOP DDR16 Interface Contract

Author: Karim Sabra

## Scope

This document defines the active chip-facing TX interface implemented by
`TOP/rtl/spadmic_ddr16_tx_pairer.sv` and exposed by
`TOP/rtl/spadmic_top_matrix_v1.sv`.

## Pin-level contract

| Pin | Direction | Meaning |
| --- | --- | --- |
| `ddr_clk_o` | output | forwarded system clock |
| `ddr_pair_valid_o` | output | both 16-bit word buses carry one ordered pair |
| `ddr_data_l_o[15:0]` | output | earlier logical word in the pair |
| `ddr_data_h_o[15:0]` | output | later logical word, or zero padding after flush |

There is no off-chip ready input. All flow control and elasticity are on chip.

## Logical-to-physical mapping

The internal packet grammar uses 16-bit logical words. The pairer accepts that
stream in order:

1. the first accepted word is retained as the low member
2. the second accepted word completes the pair
3. `ddr_pair_valid_o` pulses with both outputs valid
4. an ordered flush with one retained word emits a padded pair

For a padded final pair:

```text
ddr_data_l_o = final logical word
ddr_data_h_o = 16'h0000
```

The bundle transmitter generates flush only after every required packet for the
physical event has completed.

## Idle behavior

When `ddr_pair_valid_o` is low and no pair is being emitted, both data outputs
return to zero. A receiver must still qualify data exclusively with
`ddr_pair_valid_o`.

`ddr_clk_o` follows `clk_sys`; it is not gated by valid or idle state.

## Logical stream

The interface carries the packet words defined by
[`03_CORRELATED_EVENT_EXPORT.md`](03_CORRELATED_EVENT_EXPORT.md):

- TDC R, Y, and B packets
- cluster position packets of 8 words
- raw position packets of 14 words
- a shared 14-bit event ID in each packet EOP

Source ordering within one event bundle is R, Y, B, then position, restricted to
the frozen required mask for that operating mode.

## Receiver checklist

For each asserted `ddr_pair_valid_o`:

1. append `ddr_data_l_o` to the logical word stream
2. append `ddr_data_h_o`
3. parse packet header and known packet length
4. discard the high zero word only when protocol length proves the pair is the
   padded end of a bundle
5. group packets by shared event ID and source identity

Do not infer padding from a zero value alone because zero is legal packet data.

## Timing boundary

RTL establishes functional ordering only. Package/board delay, macro mapping,
output timing constraints, and receiver setup/hold budgets must be supplied and
closed in the implementation flow. Local Verilator or server Xcelium success is
not physical TX signoff.

## VIP relationship

`TOP/tb/vip/interfaces/spadmic_narrow_tx_if.sv` observes the low/high word buses
and forwards ordered 16-bit words to `spadmic_tx_monitor`. The monitor and
scoreboard are the executable receiver reference for packet boundaries, source
identity, and event correlation.

## Cross-reference

- [`01_ACTIVE_ARCHITECTURE.md`](01_ACTIVE_ARCHITECTURE.md)
- [`03_CORRELATED_EVENT_EXPORT.md`](03_CORRELATED_EVENT_EXPORT.md)
- [`07_BLOCK_GUIDE.md`](07_BLOCK_GUIDE.md)
- [`09_VIP_GUIDE.md`](09_VIP_GUIDE.md)
