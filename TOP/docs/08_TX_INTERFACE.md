# SPADMIC TOP — TX Interface Contract

## Scope

This document defines the **chip-facing** TX interface implemented by
`rtl/spadmic_ddr_tx.sv`.

It is the physical boundary between the on-chip logical packet stream and the
off-chip receiver.

## 1. Pin-level contract

| Pin | Direction | Meaning |
|-----|-----------|---------|
| `chip_tx_clk_o` | output | forwarded source-synchronous clock, same frequency as `clk_sys` |
| `chip_tx_valid_o` | output | SDR qualifier: one asserted cycle means one logical 16-bit word is present across the two DDR edges of that cycle |
| `chip_tx_data_o[7:0]` | output | DDR byte lane carrying the two bytes of the logical word |
| `spad_matrix_rst_o` | output | active-high one-`clk_sys` pulse to the SPAD matrix reset input |

There is **no** `chip_tx_ready_i` pin in the active contract.

## 2. Logical-to-physical mapping

The active transport still thinks in **16-bit logical words** internally.

For each valid logical word:

1. rising edge of `chip_tx_clk_o` carries `word[7:0]`
2. falling edge of `chip_tx_clk_o` carries `word[15:8]`

The receiver reconstructs:

```text
word = {byte_on_falling_edge, byte_on_rising_edge}
```

## 3. Valid behavior

`chip_tx_valid_o` is asserted for the full logical-word cycle.

That means:

- if `chip_tx_valid_o = 1`, the receiver must sample both edges
- if `chip_tx_valid_o = 0`, the receiver should ignore the DDR lane for that cycle

The design currently drives zeros on idle bytes, but the receiver should treat
those bytes as **don't care** when `chip_tx_valid_o = 0`.

## 4. What travels over the interface

The physical interface carries the same logical packet words described in:

- [`03_CORRELATED_EVENT_EXPORT.md`](03_CORRELATED_EVENT_EXPORT.md)
- MPTDC packet helpers in `MPTDC/rtl/pkg/mptdc_pkg.sv`

In other words, the physical interface changes **timing and byte mapping**, not
the logical packet grammar.

### Packet landmarks

At the logical-word level, the receiver still expects:

1. header
2. payload words
3. EOC

Cluster-position packets include a position sub-header after the header and use
6-bit `lo`/`hi` cluster coordinates for the 64x64x64 SPAD matrix. Raw bitmap
position packets are fixed-length 14-word packets with 12 unescaped bitmap
payload words; a receiver must parse them by raw header and length because raw
payload words can look like EOC markers.

For correlated export, the EOC word contains the shared event ID:

```text
[15:14] = 2'b11
[13:0]  = shared_event_id
```

## 5. Clocking assumptions

`chip_tx_clk_o` is the forwarded transmit clock. The off-chip receiver is assumed
to treat it as the sampling reference for both DDR edges.

The active implementation uses `clk_sys` directly as that forwarded clock. There
is no independent source-strobe generation stage inside the current RTL.

## 6. Flow-control assumptions

The physical TX boundary is **unidirectional** and **non-backpressured**:

- the receiver cannot stall the transmitter
- all elasticity must be absorbed on-chip
- the relevant on-chip elasticity point is the post-arbiter FIFO inside `spadmic_correlated_tx`

That architectural split is intentional:

1. packet correlation and buffering stay on-chip
2. the pin-level interface stays simple
3. off-chip logic only needs to sample and parse

## 7. Receiver checklist

An off-chip receiver should implement the following sequence:

1. use `chip_tx_clk_o` as the DDR sampling clock
2. gate collection with `chip_tx_valid_o`
3. collect low byte on rising edge
4. collect high byte on falling edge
5. rebuild 16-bit logical words
6. parse the logical packet grammar
7. group packets by `shared_event_id` and source tag in both-active mode

## 8. Relationship to the VIP

The current TOP VIP follows exactly that model:

1. `spadmic_vip_tb.sv` connects the real DUT pins
2. `spadmic_narrow_tx_if.sv` reconstructs 16-bit words from the DDR bus
3. `spadmic_tx_monitor.sv` assembles packets from the reconstructed words

That means the maintained VIP is a good executable reference for a software or
FPGA receiver implementation.

## 9. Why the contract was chosen

The active implementation deliberately keeps the internal packet format and only
changes the **physical egress**. That was chosen to:

- minimize churn inside the packet generators
- preserve existing packet-oriented tooling and helper functions
- keep the chip pin count low
- provide a realistic source-synchronous interface for silicon

Future work can still change the logical framing if a later bandwidth study shows
that the 16-bit logical layer itself should be compressed further.

## 10. Cross-reference

- [`01_ACTIVE_ARCHITECTURE.md`](01_ACTIVE_ARCHITECTURE.md)
- [`03_CORRELATED_EVENT_EXPORT.md`](03_CORRELATED_EVENT_EXPORT.md)
- [`07_BLOCK_GUIDE.md`](07_BLOCK_GUIDE.md)
- [`09_VIP_GUIDE.md`](09_VIP_GUIDE.md)
