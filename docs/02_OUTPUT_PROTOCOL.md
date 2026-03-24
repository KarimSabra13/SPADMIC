# MPTDC v2.0 — 16-bit Output Protocol

## Overview

The TDC streams conversion results over a 16-bit ready/valid bus. Each conversion produces a **packet** consisting of:

1. **Header** (1 word)
2. **Hit words** (2-4 words per hit, depending on output mode)
3. **End-of-Conversion marker** (1 word)

## Word Type Detection

```
Bits [15:14] determine word type:
  2'b10  →  Header
  2'b11  →  End-of-Conversion (EOC)
  2'b0x  →  Hit data (bit[15] always 0)
```

## Header Word

```
Bit   Field           Width  Description
───── ─────────────── ────── ─────────────────────────────
15:14 type            2      Always 2'b10 (header marker)
13:12 ctx_id          2      Context ID (0-2)
   11 phase0_snap     1      Boundary phase snapshot
 10:7 hit_count       4      Number of hits in this conversion (0-15)
  6:3 flags           4      Conversion flags (see below)
  2:1 out_mode        2      Output mode used
    0 reserved        1      Always 0
```

### Flags Field

```
Bit  Flag                 Meaning
──── ──────────────────── ─────────────────────────────
  3  overflow             All contexts were busy at START
  2  closed_by_firsthit   First-hit mode forced closure
  1  closed_by_maxhits    Max hit count reached
  0  closed_by_watchdog   Watchdog timer forced closure
```

## Hit Words — RAW_FEATURES Mode (out_mode=0)

3 words per hit. This is the primary mode for offline calibration.

### Word 0 (Counter Snapshots)
```
Bit   Field       Width  Description
───── ─────────── ────── ───────────────────────
   15 zero        1      Always 0
 14:8 nslow       7      Slow counter (revolutions)
  7:1 nfast       7      Fast counter (revolutions)
    0 zero        1      Always 0
```

### Word 1 (Phase + Cell Index)
```
Bit   Field       Width  Description
───── ─────────── ────── ───────────────────────
   15 zero        1      Always 0
14:11 ns          4      Slow phase index (0-8)
 10:7 nf          4      Fast phase index (0-8)
  6:0 pd_idx      7      PD cell flat index (0-80)
```

### Word 2 (Sequence)
```
Bit   Field       Width  Description
───── ─────────── ────── ───────────────────────
   15 zero        1      Always 0
14:11 event_seq   4      Hit sequence number (0-14)
 10:0 reserved    11     Always 0
```

## Hit Words — RAW_TIMESTAMP Mode (out_mode=1)

2 words per hit.

### Word 0
Same as RAW_FEATURES Word 0.

### Word 1
```
Bit   Field       Width  Description
───── ─────────── ────── ───────────────────────
 15:0 t_raw_ps    16     Raw time in picoseconds (signed, truncated)
```

**Note**: t_raw_ps can have bit[15]=1 (negative or large values). In this mode, the consumer must use packet structure (word count from header) to parse, not bit[15] detection.

## Hit Words — FULL Mode (out_mode=2)

4 words per hit (all features + timestamp).

### Words 0-2
Same as RAW_FEATURES Words 0-2.

### Word 3
```
Bit   Field       Width  Description
───── ─────────── ────── ───────────────────────
 15:0 t_raw_ps    16     Raw time in picoseconds (signed, truncated)
```

## End-of-Conversion (EOC) Word

```
Bit   Field       Width  Description
───── ─────────── ────── ───────────────────────
15:14 type        2      Always 2'b11 (EOC marker)
 13:0 conv_id     14     Conversion counter (wraps at 16383)
```

## Packet Size Summary

| Mode | Words per hit | Packet size (N hits) |
|------|--------------|---------------------|
| RAW_FEATURES (0) | 3 | 1 + 3N + 1 = 3N+2 |
| RAW_TIMESTAMP (1) | 2 | 1 + 2N + 1 = 2N+2 |
| FULL (2) | 4 | 1 + 4N + 1 = 4N+2 |

For max 15 hits: 47 words (features), 32 words (timestamp), 62 words (full).

## Handshake Protocol

Standard ready/valid:
- `narrow_valid_o`: Asserted when data is available
- `narrow_ready_i`: Consumer ready to accept
- Transfer occurs on rising clock edge when both are high
- Backpressure: deassert `narrow_ready_i` to stall output (FIFO buffers internally)

## Example Packet (RAW_FEATURES, 2 hits)

```
Word 0: 0x8xxx  Header (ctx_id, phase0, hit_count=2, flags, mode)
Word 1: 0x0xxx  Hit 0, W0 (nslow, nfast)
Word 2: 0x0xxx  Hit 0, W1 (ns, nf, pd_idx)
Word 3: 0x0xxx  Hit 0, W2 (event_seq=0)
Word 4: 0x0xxx  Hit 1, W0 (nslow, nfast)
Word 5: 0x0xxx  Hit 1, W1 (ns, nf, pd_idx)
Word 6: 0x0xxx  Hit 1, W2 (event_seq=1)
Word 7: 0xCxxx  EOC (conv_id)
```
