# SPADMIC TOP Correlated Event Export Contract

Author: Karim Sabra

## Scope

This document defines the active export behavior implemented by:

- `TOP/rtl/spadmic_top_matrix_v1.sv`
- `TOP/rtl/spadmic_event_coordinator.sv`
- `TOP/rtl/spadmic_event_bundle_tx.sv`
- `TOP/rtl/spadmic_output_fifo.sv`
- `TOP/rtl/spadmic_ddr16_tx_pairer.sv`
- `MPTDC/rtl/top/mptdc_axis_core.sv`, through TOP-owned wrappers

It is the off-chip contract for R/Y/B TDC packets and the optional position
packet produced by one physical event. The protected MPTDC boundary is not
modified by this contract.

## Event personalities

`GLOBAL_CTRL.mode` selects the required packet set. Normal modes require an
R/Y/B axis mask of `3'b111`.

| Mode | Required packet sources |
| --- | --- |
| disabled | none |
| TDC only | R, Y, B |
| position only | position |
| TDC plus position | R, Y, B, position |
| calibration | selected nonzero calibration-axis mask |

Normal matrix operation has no software conversion-start command. A qualified
matrix event starts the coordinator, which freezes the required packet and
reset-acknowledgement masks for the complete event lifetime.

## Shared event ID

The coordinator allocates one 14-bit event ID per accepted physical event. All
required packets in that event bundle receive the same EOP word:

```text
[15:14] = 2'b11
[13:0]  = shared_event_id
```

The event ID increments once when a new event is accepted, not once per packet.
The receiver can therefore group R/Y/B and position packets by this ID.

## Source order and identification

`spadmic_event_bundle_tx` transmits required sources in deterministic order:

```text
R -> Y -> B -> position
```

It holds each source until its EOP is accepted. Packets cannot interleave.
TDC header bits `[1:0]` are patched at the TOP boundary:

| Header ID | Public source |
| --- | --- |
| `2'b00` | R |
| `2'b01` | Y |
| `2'b10` | B |
| `2'b11` | reserved |

Position source identity is implicit in the position header format.

## Position packet formats

The position source captures a private R/Y/B snapshot before acknowledging that
matrix reset may proceed.

| Mode | Logical word count | Payload |
| --- | ---: | --- |
| cluster | 8 | header, two cluster slots per R/Y/B axis, EOP |
| raw | 14 | header, twelve 16-bit bitmap words, EOP |

Cluster mode reset defaults are gap threshold 2 and minimum cluster span 1.
The packetizer reports pending/busy/drop state to the event and CSR banks.

## Output FIFO

The correlated bundle enters a fixed 256-entry FIFO. Its reserve threshold is
compile-time fixed and software-readable; software cannot relax it. The FIFO
absorbs complete legal event bundles and preserves the ordered flush marker.

The bundle does not complete until every required source packet has drained and
the flush marker has been accepted. Missing-source and FIFO-overflow conditions
have separate sticky faults and saturating counters.

## DDR16 physical mapping

The active matrix-top boundary is:

```text
ddr_data_l_o[15:0]
ddr_data_h_o[15:0]
ddr_pair_valid_o
ddr_clk_o
```

Each asserted `ddr_pair_valid_o` transfers two consecutive logical 16-bit
words: the earlier word on `ddr_data_l_o`, and the later word on
`ddr_data_h_o`. If an event bundle ends with an odd logical-word count, the
ordered flush emits the final word on `ddr_data_l_o` and zero-pads
`ddr_data_h_o`.

There is no off-chip ready input. `ddr_clk_o` follows the system-clock boundary.

## Receiver procedure

For each cycle with `ddr_pair_valid_o == 1`:

1. append `ddr_data_l_o` to the logical stream
2. append `ddr_data_h_o` unless the final pair is known to be padded
3. identify TDC source from header bits `[1:0]`
4. identify position packets from their cluster/raw header
5. terminate each packet at the EOP marker
6. group packets sharing the same 14-bit event ID

Raw packets are length-delimited because bitmap payload words may also have
`[15:14] == 2'b11`. Parse a raw packet as exactly 14 logical words rather than
terminating on the first EOP-looking payload word.

## Error and reset behavior

- An event is rejected before acceptance if required resources are unavailable.
- Required source masks remain frozen while an event is open.
- Chip reset clears coordinator, packet, FIFO, and DDR state.
- `i2c_rst_i` resets only the I2C transport and does not disturb an event.
- RTL regression evidence does not authorize physical implementation or
  signoff.
