# MPTDC v2.7 — Fixed 16-bit Output Protocol

> - **Author:** Karim Sabra
> - **Purpose:** Define the live 16-bit packet format emitted by the MPTDC serializer.
> - **Scope:** Covers the single header/hit/EOC packet format used by both the standalone MPTDC serializer and the shared SPADMIC TDC packet adapter.

## 1. Overview

The active design emits conversion results on a 16-bit ready/valid stream. Each conversion is packetized as:

1. one header word
2. zero or more hit words
3. one EOC word

The old dedicated TDC sub-header has been removed. `nfast_stop`, `nfast_snap`, `pd_idx`, and `event_seq` are no longer part of the live packet contract.

The serializer may insert internal `clk_sys` bubbles between ready/valid words. Receivers must rely on `valid`/`ready` and packet structure, not fixed cycle spacing between words.

## 2. Word-class identification

```text
[15:13] = 3'b100 -> header
[15:14] = 2'b11  -> EOC
[15]    = 1'b0   -> hit payload word
```

All hit payload words have `word[15]=0`; receivers should still parse by packet structure rather than by payload value.

## 3. Header word

```text
[15:14] type              = 2'b10
[13:12] ctx_id            = context id (standalone MPTDC path)
[11]    phase0_snap       = STOP-side snapshot of slow phase 0
[10:7]  hit_count         = number of hits carried in this packet
[6:3]   flags             = close reason flags
[2]     slow_boundary_inc = STOP boundary coarse-count correction
[1:0]   reserved          = 2'b00
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

## 4. Fixed calibrated-feature hit format

This is the only maintained output format. It exports the packet-visible fields required by the final LUT calibration while keeping the packet at two words per hit.

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

## 5. Removed legacy modes and retained boundary bit

`RAW_TIMESTAMP` and `FULL` are no longer emitted by the maintained RTL. Legacy CSR or wrapper fields that still carry an `out_mode` type are hardwired/ignored and read back as `OUT_MODE_RAW_FEATURES`.

`slow_boundary_inc` remains exported as a single conversion-level header bit. A v2.7 ablation showed that removing it leaves the matched-row RMSE nearly unchanged, but about `0.123 %` of validation rows become ambiguous. If the host reconstructs the raw timestamp with this bit forced to zero, those rare rows form an error tail close to one slow coarse step. Keeping the bit in `header[2]` preserves the two-word-per-hit throughput while restoring all-row calibration quality.

## 6. EOC word

```text
[15:14] = 2'b11
[13:0]  = conv_id
```

`conv_id` is maintained by `mptdc_narrow16_tx_v2.sv` as a local 14-bit wrapping packet counter.

## 7. Internal origin of packet fields

The serializer still consumes two internal acquisition-record types:

- META record: conversion-level information (`nslow`, capture-time `nfast`, `hit_count`, flags, internal boundary info, `stop_phase_disc`, `ctx_id`)
- HIT record: per-hit information (`ns`, `nf`, `nfast_hit`, internal `event_seq`)

Important distinction:

- `nfast_snap`, `nfast_stop`, and `event_seq` still exist in some internal records and historical tooling
- they are **not** emitted on the live narrow packet anymore

## 8. Host-side parsing rules

1. Wait for a header word.
2. Decode `hit_count` from the header.
3. Derive the total packet length as `2 * hit_count + 2`.
4. Consume the expected number of hit words.
5. Expect one EOC word at the end.

Decode `header[2]` as `slow_boundary_inc`. Treat `header[1:0]` as reserved/read-zero.

## 9. Recommended operating usage

- Use the fixed calibrated-feature packet for silicon characterization and offline calibration.
- Reconstruct raw timestamps offline from packet-visible fields when needed; no live timestamp word is emitted.
- Report both calibration error metrics and effective inference/LUT coverage.

## 10. Example packet (2 hits)

```text
word 0  header
word 1  hit0 W0  (nslow, nfast_hit)
word 2  hit0 W1  (ns, nf)
word 3  hit1 W0
word 4  hit1 W1
word 5  EOC
```
