# SPADMIC TOP — Correlated Event Export Contract

## Scope

This document defines the active top-level export behavior implemented by:

- `rtl/spadmic_tdc_shared_readout.sv`
- `../SPADMIC/position/rtl/spadmic_position_block.sv`
- `rtl/spadmic_correlated_tx.sv`

It is the contract for off-chip regrouping of X/Y/Z TDC packets and position packets that describe the same physical event.

## 1. Export personalities

The active RTL keeps the existing control-image width and derives the export personality from `shared_tx_sel` plus `position_enable`:

| `shared_tx_sel` | `position_enable` | Meaning |
|-----------------|-------------------|---------|
| `TDC` | `0` | TDC-only |
| `POSITION` | `1` | position-only |
| `TDC` | `1` | correlated both-active |

## 2. Packet sources

The chip-level egress consumes two already packetized producers:

1. one shared TDC packet stream from `spadmic_tdc_shared_readout`
2. one queued position packet stream from `spadmic_position_block`

`spadmic_correlated_tx` arbitrates between them at **packet** granularity, never at word granularity. A packet is never interleaved once its header has started.

## 3. Shared event ID rule

Every emitted packet ends with:

```text
[15:14] = 2'b11
[13:0]  = shared_event_id
```

The top-level tagger replaces the producer-local EOC count with a shared event ID.

### 3.1 Current correlation rule

The active contract uses **per-source ordinal correlation**:

- for each enabled source, the first emitted packet is event `0`
- the second emitted packet from that same source is event `1`
- and so on

Under the active system contract:

1. each enabled source emits at most one packet per physical event
2. packet order is preserved within each source
3. the design should avoid silent drops in the normal path

That means the nth packet from X, Y, Z, and position all describe the nth physical event and therefore receive the same event ID.

## 4. Source identification

TDC and position packets now identify source differently:

| Packet type | Source encoding |
|-------------|-----------------|
| TDC | header bit `[12]` = `tdc_id[0]`, header bit `[6]` = `tdc_id[1]` |
| Position cluster | cluster header marker `[15:14] = 2'b01`; source is implicitly position |
| Position raw bitmap | raw header pattern from `spadmic_pos_raw_header_word()`; source is implicitly position |

Off-chip software should therefore group packets by:

1. `shared_event_id` from the EOC word
2. TDC source from the header or implicit position source from the position header

## 5. Position overlap behavior

The position path no longer drops a qualifying snapshot just because a previous packet is still draining.

Instead:

- accepted snapshots are queued in `spadmic_position_block`
- `POS_DROP_COUNT` increments only if that queue becomes full
- `position_pending` remains asserted while queued packets still need to drain

## 6. Post-arbiter FIFO

`spadmic_correlated_tx` includes a post-arbiter word FIFO with depth:

```text
SPADMIC_OUTPUT_FIFO_DEPTH = 2048 words
```

This FIFO sits **after** packet arbitration and **after** event-ID tagging. Its role is to:

1. absorb shared-output backpressure
2. keep arbitration packet-atomic
3. isolate the packet producers from the fixed-rate physical TX boundary

## 7. Physical TX mapping

The active chip-facing interface is now:

```text
chip_tx_clk_o     forwarded 160 MHz source-synchronous clock
chip_tx_valid_o   SDR word-valid qualifier
chip_tx_data_o    8-bit DDR byte lane
```

The active mapping preserves the internal 16-bit logical packet format:

- rising edge: `word[7:0]`
- falling edge: `word[15:8]`

There is no off-chip `ready` signal in the active physical contract.

## 8. Receiver-side parsing

Host software should parse packets as:

1. use `chip_tx_valid_o` to identify cycles carrying one logical 16-bit word
2. sample `chip_tx_data_o` on both edges of `chip_tx_clk_o`
3. reconstruct the 16-bit logical word from `{falling_edge_byte, rising_edge_byte}`
4. parse the logical packet stream as:
   - TDC: header, payload, EOC
   - position cluster: header, six 6-bit-coordinate cluster words, EOC
   - position raw bitmap: raw header, 12 unescaped bitmap payload words, EOC

For both-active mode, the receiver should build one correlated event record by collecting all packets with the same `shared_event_id`.

Raw bitmap position packets are fixed length because payload words carry true
16-bit line levels and can therefore have `[15:14] = 2'b11`. The on-chip
correlator and the off-chip receiver must parse raw bitmap packets by the raw
header plus 14 total words, not by the first EOC-looking payload word.

The 64x64x64 SPAD geometry does not change packet word counts: cluster packets
remain 12 logical words and raw bitmap packets remain 14 logical words. The
protocol-level geometry change is the cluster bound width inside each cluster
word:

```text
[15:13] = 3'b000 reserved
[12:7]  = lo[5:0]
[6:1]   = hi[5:0]
[0]     = valid
```
