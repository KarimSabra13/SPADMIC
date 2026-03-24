# MPTDC v2.0 — CSR Register Map

## Overview

Minimal CSR interface with 6-bit address bus and 32-bit data.

```
Interface:
  csr_addr_i   [5:0]   Register address
  csr_wdata_i  [31:0]  Write data
  csr_wr_en_i          Write enable (1 cycle pulse)
  csr_rdata_o  [31:0]  Read data (always available, no latency)
```

## Register Summary

| Addr | Name | R/W | Description |
|------|------|-----|-------------|
| 0x00 | CTRL | W | Control (arm, clear, reset) |
| 0x04 | MODE | R/W | Operating mode configuration |
| 0x08 | MAX_HITS | R/W | Maximum hits per conversion |
| 0x0C | WDT_CTX | R/W | Per-context watchdog timeout |
| 0x10 | WDT_GLOBAL | R/W | Global watchdog timeout |
| 0x20 | STATUS | R | TDC status |
| 0x24 | HIT_COUNT | R | Last conversion hit count + flags |
| 0x28 | FIFO_STATUS | R | FIFO level and flags |
| 0x2C | WDT_STATUS | R | Watchdog trip counters |
| 0x30 | CONV_COUNT | R | Total conversion counter |
| 0x34 | OVF_COUNT | R | Overflow counter |

## Control Registers

### CTRL (0x00) — Write Only

| Bit | Field | Default | Description |
|-----|-------|---------|-------------|
| 0 | conv_arm | 0 | Arm for next conversion (self-clearing) |
| 1 | fifo_clr | 0 | Clear async FIFO (self-clearing) |
| 2 | soft_rst | 0 | Soft reset all logic (self-clearing) |
| 31:3 | — | 0 | Reserved |

### MODE (0x04) — Read/Write

| Bit | Field | Default | Description |
|-----|-------|---------|-------------|
| 0 | mode_cfg | 0 | 0=MULTI_HIT, 1=FIRST_HIT |
| 1 | input_sel | 0 | 0=SPAD inputs, 1=CAL inputs |
| 3:2 | out_mode | 0 | 0=RAW_FEATURES, 1=RAW_TIMESTAMP, 2=FULL |
| 31:4 | — | 0 | Reserved |

### MAX_HITS (0x08) — Read/Write

| Bit | Field | Default | Description |
|-----|-------|---------|-------------|
| 3:0 | max_hits | 15 | Max hits per conversion (1-15, 0=use 15) |
| 31:4 | — | 0 | Reserved |

### WDT_CTX (0x0C) — Read/Write

| Bit | Field | Default | Description |
|-----|-------|---------|-------------|
| 15:0 | ctx_timeout | 0 | Per-context timeout in sys clk cycles (0=disabled) |
| 31:16 | — | 0 | Reserved |

At 160 MHz: timeout_ns = ctx_timeout × 6.25

### WDT_GLOBAL (0x10) — Read/Write

| Bit | Field | Default | Description |
|-----|-------|---------|-------------|
| 15:0 | global_timeout | 0 | Global timeout in sys clk cycles (0=disabled) |
| 31:16 | — | 0 | Reserved |

## Status Registers

### STATUS (0x20) — Read Only

| Bit | Field | Description |
|-----|-------|-------------|
| 0 | ready | TDC ready for arm |
| 1 | busy | Conversion in progress |
| 7:2 | ctx_state_packed | Context states (2 bits each: 00=FREE, 01=CAPTURING, 10=DRAINING) |
| 31:8 | — | Reserved |

### HIT_COUNT (0x24) — Read Only

| Bit | Field | Description |
|-----|-------|-------------|
| 3:0 | last_hit_count | Hit count from last conversion |
| 7:4 | last_flags | Flags from last conversion |
| 31:8 | — | Reserved |

### FIFO_STATUS (0x28) — Read Only

| Bit | Field | Description |
|-----|-------|-------------|
| 6:0 | fifo_level | Current FIFO fill level |
| 7 | fifo_full | FIFO is full |
| 8 | fifo_empty | FIFO is empty |
| 31:9 | — | Reserved |

### WDT_STATUS (0x2C) — Read Only

| Bit | Field | Description |
|-----|-------|-------------|
| 7:0 | ctx_trip_cnt | Per-context watchdog trip counter (saturating) |
| 15:8 | global_trip_cnt | Global watchdog trip counter (saturating) |
| 31:16 | — | Reserved |

### CONV_COUNT (0x30) — Read Only

| Bit | Field | Description |
|-----|-------|-------------|
| 31:0 | conv_count | Total conversions completed |

### OVF_COUNT (0x34) — Read Only

| Bit | Field | Description |
|-----|-------|-------------|
| 15:0 | ovf_count | Overflow events (START when no context free) |
| 31:16 | — | Reserved |

## Typical Usage Sequence

```
1. Write MODE:     input_sel=SPAD, mode=MULTI_HIT, out_mode=RAW_FEATURES
2. Write MAX_HITS: 15
3. Write WDT_CTX:  10000 (62.5 µs timeout)
4. Write CTRL:     conv_arm=1
5. Wait for START/STOP events
6. Read narrow_data bus for output packet
7. Repeat from step 4
```
