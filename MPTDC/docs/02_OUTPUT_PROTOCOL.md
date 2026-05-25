# MPTDC v2.6 — 16-bit Output Protocol

> - **Author:** Karim Sabra
> - **Purpose:** Define the live 16-bit packet format emitted by the MPTDC serializer.
> - **Scope:** Covers header, hit, and EOC words plus parsing rules for `RAW_FEATURES`, `RAW_TIMESTAMP`, and `FULL` modes.

## 1. Overview

The active design emits conversion results on a 16-bit ready/valid stream. Each conversion is packetized as:

1. one header word
2. zero or more hit words
3. one EOC word

The old dedicated TDC sub-header has been removed. `nfast_stop`, `nfast_snap`, `pd_idx`, and `event_seq` are no longer part of the live packet contract.

The serializer may insert internal `clk_sys` bubbles between ready/valid words,
including a registered timestamp-calculation bubble before hit payload emission.
Receivers must rely on `valid`/`ready` and packet structure, not fixed cycle
spacing between words.

## 2. Word-class identification

```text
[15:13] = 3'b100 -> header
[15:14] = 2'b11  -> EOC
[15]    = 1'b0   -> hit payload word
```

In `RAW_TIMESTAMP` and `FULL` modes, timestamp payload words may have any pattern on the lower 16 bits, so the receiver must parse by packet structure rather than by payload value.

## 3. Header word

```text
[15:14] type              = 2'b10
[13:12] ctx_id            = context id (standalone MPTDC path)
[11]    phase0_snap       = STOP-side snapshot of slow phase 0
[10:7]  hit_count         = number of hits carried in this packet
[6:3]   flags             = close reason flags
[2:1]   out_mode          = serializer mode
[0]     slow_boundary_inc = STOP-side boundary carry
```

### 3.1 Flag semantics

```text
bit 3  reserved              = currently always 0 in standalone MPTDC
bit 2  closed_by_fast_maxhit = conversion closed by the fast close path used when max_hits = 1
bit 1  closed_by_maxhits     = conversion closed because hit count reached max_hits
bit 0  closed_by_watchdog    = conversion closed by the no-STOP safety timeout / watchdog-class path
```

Important: true context-allocation overflow is not encoded in the packet header. It is counted separately in CSR `OVF_COUNT`.
The active pivot no longer uses a near-1 GHz fast-domain context FSM; treat this
flag as a watchdog-class close indication rather than proof that a programmable
fast-domain watchdog counter elapsed.

## 4. RAW_FEATURES mode (`out_mode = 0`)

This is the preferred mode for offline calibration and silicon characterization because it exports the raw measured fields instead of only a derived timestamp.

Packet size:

```text
1 header + 2 * hit_count + 1 EOC
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
[6:3]   reserved
[2:0]   stop_phase_disc
```

Field meaning:

- `ns` = slow phase index associated with this PD cell
- `nf` = fast phase index associated with this PD cell
- `stop_phase_disc` = STOP-edge `slow_phase[5:3]` discriminator captured with
  the conversion metadata. This field reduces and diagnoses early-delay raw
  aliases while preserving the 16-bit word structure and hit word count; it is
  not a substitute for a correct STOP-side `nslow` coarse count.

The reserved `W1[6:3]` field is the preferred zero-word-count expansion point
if the Oracle calibration analysis proves that another per-hit edge
discriminator is required. Do not consume header bits for per-hit information
unless these four reserved bits are insufficient.

The removed fields are recovered as follows when needed offline:

- `pd_idx = ns * NE + nf`
- `hit_idx` remains implicit from packet order
- `event_seq` is intentionally not exported; scan order is no longer a live packet field

## 5. RAW_TIMESTAMP mode (`out_mode = 1`)

This mode emits the coarse counters plus one derived raw timestamp word per hit.

Packet size:

```text
1 header + 2 * hit_count + 1 EOC
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

## 6. FULL mode (`out_mode = 2`)

This mode emits the raw feature words, including `stop_phase_disc`, plus the
derived timestamp.

Packet size:

```text
1 header + 3 * hit_count + 1 EOC
```

### 6.1 Hit words W0-W1

Same as RAW_FEATURES W0-W1.

### 6.2 Hit word W2

```text
[15:0] t_raw_ps[15:0]
```

This is the same derived timestamp used in RAW_TIMESTAMP mode.

## 7. EOC word

```text
[15:14] = 2'b11
[13:0]  = conv_id
```

`conv_id` is maintained by `mptdc_narrow16_tx_v2.sv` as a local 14-bit wrapping packet counter.

## 8. Internal origin of packet fields

The serializer still consumes two internal acquisition-record types:

- META record: conversion-level information (`nslow`, capture-time `nfast`, `hit_count`, flags, boundary info, `stop_phase_disc`, `ctx_id`)
- HIT record: per-hit information (`ns`, `nf`, `nfast_hit`, internal `event_seq`)

Important distinction:

- `nfast_snap`, `nfast_stop`, and `event_seq` still exist in some internal records and historical tooling
- they are **not** emitted on the live narrow packet anymore

## 9. Host-side parsing rules

1. Wait for a header word.
2. Decode `hit_count` and `out_mode` from the header.
3. Derive the total packet length:
   - RAW_FEATURES: `2 * hit_count + 2`
   - RAW_TIMESTAMP: `2 * hit_count + 2`
   - FULL: `3 * hit_count + 2`
4. Consume the expected number of hit words.
5. Expect one EOC word at the end.

Do not rely on payload bit patterns to infer semantic word boundaries in timestamp modes.

## 10. Recommended operating usage

- Use `RAW_FEATURES` for silicon characterization and offline calibration.
- Use `RAW_TIMESTAMP` when the host only needs a compact pre-centered raw time and does not need direct `ns/nf` export.
- Use `FULL` when you want both the raw feature words and the on-chip raw timestamp reconstruction for debug correlation.

## 11. Example packet (RAW_FEATURES, 2 hits)

```text
word 0  header
word 1  hit0 W0  (nslow, nfast_hit)
word 2  hit0 W1  (ns, nf)
word 3  hit1 W0
word 4  hit1 W1
word 5  EOC
```
