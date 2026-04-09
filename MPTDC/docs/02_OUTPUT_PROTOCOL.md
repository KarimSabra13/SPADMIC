# MPTDC v2.2 — 16-bit Output Protocol

> - **Author:** Karim Sabra
> - **Purpose:** Define the live 16-bit packet format emitted by the MPTDC serializer.
> - **Scope:** Covers header, hit, and EOC words plus parsing rules for `RAW_FEATURES`, `RAW_TIMESTAMP`, and `FULL` modes.

## 1. Overview

The active design emits conversion results on a 16-bit ready/valid stream. Each conversion is packetized as:

1. one header word
2. one sub-header word
3. zero or more hit words (format depends on `out_mode`)
4. one EOC word

The serializer is implemented by `rtl/readout/mptdc_narrow16_tx_v2.sv` and consumes acquisition records produced by `mptdc_drain_ctrl` through `mptdc_sync_fifo`.

## 2. Word-class identification

```text
[15:14] = 2'b10 -> header
[15:14] = 2'b11 -> EOC
[15]    = 1'b0 -> hit payload word
```

In `RAW_TIMESTAMP` and `FULL` modes, timestamp payload words may have any pattern on the lower 16 bits, so the receiver must parse by packet structure rather than by trying to infer semantic word types from the payload value.

## 3. Header word

```text
[15:14] type              = 2'b10
[13:12] ctx_id            = context id (padded to 2 bits, live design uses 2 contexts)
[11]    phase0_snap       = STOP-side snapshot of slow phase 0
[10:7]  hit_count         = number of hits carried in this packet
[6:3]   flags             = close reason flags
[2:1]   out_mode          = serializer mode
[0]     slow_boundary_inc = STOP-side boundary carry
```

### 3.1 Flag semantics

```text
bit 3  reserved             = currently always 0
bit 2  closed_by_fast_maxhit = conversion closed by the fast close path used when max_hits = 1
bit 1  closed_by_maxhits    = conversion closed because hit count reached max_hits
bit 0  closed_by_watchdog   = conversion closed because the fast-domain context watchdog fired
```

Important: true context-allocation overflow is not encoded in the packet header. It is counted separately in CSR `OVF_COUNT`.
There is no separate `FIRST_HIT` mode in the active v2.4 RTL; the bit above reports the compatibility-equivalent fast-close path.

## 4. Sub-header word

```text
[15:13] = 3'b101
[12:6]  = nfast_stop
[5:4]   = shared-top tdc_id tag (only when routed through SPADMIC shared TDC TX)
[3:0]   = reserved
```

Notes:

- standalone `mptdc_top_asic` keeps `[5:4] = 0`
- the SPADMIC top-level shared 3-to-1 arbiter patches `[5:4]` to identify `TDC_X`, `TDC_Y`, or `TDC_Z`

## 5. RAW_FEATURES mode (`out_mode = 0`)

This is the preferred mode for offline calibration and silicon characterization because it exports the raw measured fields instead of only a derived timestamp.

Packet size:

```text
1 header + 1 sub-header + 3 * hit_count + 1 EOC
```

### 4.1 Hit word W0

```text
[15]   0
[14:8] nslow
[7:1]  nfast_hit
[0]    0
```

Field meaning:

- `nslow` = STOP-side slow coarse snapshot exported from the context META record
- `nfast_hit` = per-hit fast coarse count latched by the PD cell that produced this hit

### 4.2 Hit word W1

```text
[15]    0
[14:11] ns
[10:7]  nf
[6:0]   pd_idx
```

Field meaning:

- `ns` = slow phase index associated with this PD cell
- `nf` = fast phase index associated with this PD cell
- `pd_idx` = flattened PD-cell index `ns * NE + nf`

### 4.3 Hit word W2

```text
[15]    0
[14:11] event_seq
[10:4]  nfast_snap
[3:0]   0
```

Field meaning:

- `event_seq` = order in which the drain FSM discovered the hit while scanning the frozen PD bitmap
- `nfast_snap` = CAPTURE-time fast coarse snapshot repeated with each hit for host convenience

This field is part of the live RTL contract. If any older document says W2 is just reserved padding, trust the RTL and this document instead.

## 6. RAW_TIMESTAMP mode (`out_mode = 1`)

This mode emits the coarse counters plus one derived raw timestamp word per hit.

Packet size:

```text
1 header + 1 sub-header + 2 * hit_count + 1 EOC
```

### 5.1 Hit word W0

Same layout as RAW_FEATURES W0.

### 5.2 Hit word W1

```text
[15:0] t_raw_ps[15:0]
```

`rtl/readout/mptdc_narrow16_tx_v2.sv` computes `t_raw_ps` using `mptdc_pkg::vernier_tconv_ps()`. The formula preserves the original Vernier dependence on:

- `Nslow`
- `Nfast`
- `ns`
- `nf`
- `K_VERNIER`
- `DELTA_LSB`

and also applies the current fixed geometry-origin corrections and `slow_boundary_inc`.

## 7. FULL mode (`out_mode = 2`)

This mode emits all raw feature words plus the derived timestamp.

Packet size:

```text
1 header + 1 sub-header + 4 * hit_count + 1 EOC
```

### 6.1 Hit words W0-W2

Same as RAW_FEATURES W0-W2.

### 6.2 Hit word W3

```text
[15:0] t_raw_ps[15:0]
```

This is the same derived timestamp used in RAW_TIMESTAMP mode.

## 8. EOC word

```text
[15:14] = 2'b11
[13:0]  = conv_id
```

`conv_id` is maintained by `mptdc_narrow16_tx_v2.sv` as a local 14-bit wrapping packet counter.

## 9. Internal origin of packet fields

The serializer consumes two internal acquisition-record types:

- META record: conversion-level information (`nslow`, `nfast_snap`, `hit_count`, flags, boundary info, `ctx_id`)
- HIT record: per-hit information (`ns`, `nf`, `nfast_hit`, `event_seq`)

The serializer latches META first, then fetches HIT records until `hit_count` hits have been emitted, then emits EOC.

## 10. Host-side parsing rules

1. Wait for a header word.
2. Decode `hit_count` and `out_mode` from the header.
3. Consume one sub-header word after the header.
4. Derive the total packet length:
   - RAW_FEATURES: `3 * hit_count + 3`
   - RAW_TIMESTAMP: `2 * hit_count + 3`
   - FULL: `4 * hit_count + 3`
5. Consume the expected number of hit words.
6. Expect one EOC word at the end.

Do not rely on payload bit patterns to infer semantic word boundaries in timestamp modes.

## 11. Recommended operating usage

- Use `RAW_FEATURES` for silicon characterization and offline calibration.
- Use `RAW_TIMESTAMP` when the host only needs a compact pre-centered raw time and does not need `ns`, `nf`, `pd_idx`, or `nfast_snap`.
- Use `FULL` when you want both the original raw features and the on-chip raw timestamp reconstruction for debug correlation.

## 12. Example packet (RAW_FEATURES, 2 hits)

```text
word 0  header
word 1  sub-header
word 2  hit0 W0  (nslow, nfast_hit)
word 3  hit0 W1  (ns, nf, pd_idx)
word 4  hit0 W2  (event_seq, nfast_snap)
word 5  hit1 W0
word 6  hit1 W1
word 7  hit1 W2
word 8  EOC
```
