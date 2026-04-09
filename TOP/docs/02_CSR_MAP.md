# SPADMIC TOP — Global and Position CSR Map

## Scope

This document covers the software-visible CSR fields owned by the active TOP-level glue:

- `spadmic_global_csr`
- `spadmic_position_block`
- the shared region decode used by `spadmic_csr_decoder`

Per-axis TDC register details remain documented in [`../../MPTDC/docs/03_CSR_MAP.md`](../../MPTDC/docs/03_CSR_MAP.md).

## 1. Region decode

The shared 12-bit CSR address uses bits `[11:8]` for region selection.

| Region | Bits `[11:8]` | Owner |
|--------|---------------|-------|
| `0x0` | `GLOBAL` | `spadmic_global_csr` |
| `0x1` | `TDC_X` | X-axis `mptdc_top_asic` |
| `0x2` | `TDC_Y` | Y-axis `mptdc_top_asic` |
| `0x3` | `TDC_Z` | Z-axis `mptdc_top_asic` |
| `0x4` | `POSITION` | `spadmic_position_block` |

## 2. Global CSR block

### 2.1 Register summary

| Addr | Name | R/W | Purpose |
|------|------|-----|---------|
| `0x000` | `GLOBAL_ID` | R | constant `0x5350_4144` (`"SPAD"`) |
| `0x004` | `GLOBAL_VERSION` | R | current top-level version encoding (`0x0003_0000` in the active RTL) |
| `0x008` | `GLOBAL_CTRL` | R/W | requested control image |
| `0x00C` | `GLOBAL_STATUS` | R | active state, datapath status, and control-accept state |
| `0x010` | `GLOBAL_FAULT` | R/W1C | sticky faults |
| `0x014` | `GLOBAL_FAULT_COUNT` | R | reject counters |

### 2.2 `GLOBAL_CTRL` (`0x008`)

This register holds the **requested** control image, not the live committed image.

| Bits | Name | Meaning |
|------|------|---------|
| `[0]` | `req_global_enable` | requested top-level enable |
| `[3:1]` | `req_axis_enable` | requested enables for X/Y/Z TDC axes |
| `[4]` | `req_position_enable` | requested enable for the position block |
| `[5]` | `req_shared_tx_sel` | `0 = TDC`, `1 = POSITION` |
| `[6]` | `req_tdc_input_sel` | `0 = SPAD`, `1 = CAL` |
| `[8:7]` | `req_tdc_out_mode` | `0 = RAW_FEATURES`, `1 = RAW_TIMESTAMP`, `2 = FULL` |

### 2.3 `GLOBAL_STATUS` (`0x00C`)

| Bits | Name | Meaning |
|------|------|---------|
| `[0]` | `tdc_tx_busy` | shared TDC serializer is inside an active packet |
| `[3:1]` | `tdc_pkt_pending` | each bit indicates an axis currently presenting a META record at the shared-readout boundary |
| `[4]` | `position_busy` | position detector or packetizer busy |
| `[5]` | `position_pending` | position path still has a packet outstanding |
| `[6]` | `path_idle` | no shared TDC packet, no pending TDC META, no position activity |
| `[7]` | `active_shared_tx_sel` | live committed bus source |
| `[8]` | `active_tdc_input_sel` | live committed TDC input source |
| `[10:9]` | `active_tdc_out_mode` | live committed TDC output mode |
| `[13:11]` | `tdc_pkt_full` | each bit mirrors one axis-local acquisition FIFO full flag |
| `[14]` | `transition_busy` | sequencer is draining or committing a control transition |
| `[15]` | `ctrl_apply_pending` | requested image differs from active image |
| `[16]` | `active_global_enable` | live committed global enable |
| `[19:17]` | `active_axis_enable` | live committed per-axis enables |
| `[20]` | `active_position_enable` | live committed position enable |
| `[21]` | `cfg_accept` | a new requested image would be accepted now |

### 2.4 `GLOBAL_FAULT` (`0x010`)

| Bits | Name | Meaning | Clear behavior |
|------|------|---------|----------------|
| `[0]` | `mode_reject_sticky` | software attempted a control change while `cfg_accept = 0` | write `1` to clear |
| `[1]` | `position_drop_sticky` | a new position event arrived while another one was still outstanding | clear in `POSITION_FAULT_STATUS` |
| `[2]` | `position_glitch_sticky` | unstable or empty position activity was rejected | clear in `POSITION_FAULT_STATUS` |

### 2.5 `GLOBAL_FAULT_COUNT` (`0x014`)

| Bits | Name | Meaning |
|------|------|---------|
| `[15:0]` | `mode_reject_count` | number of rejected control writes |

## 3. Global software rules

1. Write `GLOBAL_CTRL` only when `GLOBAL_STATUS.cfg_accept = 1`.
2. After an accepted write, poll until:
   - `transition_busy = 0`
   - `ctrl_apply_pending = 0`
3. Read the active fields from `GLOBAL_STATUS`, not from `GLOBAL_CTRL`, when software needs the live state.

## 4. Position CSR block

### 4.1 Register summary

| Addr | Name | R/W | Purpose |
|------|------|-----|---------|
| `0x400` | `POS_CTRL` | R/W | local position enable |
| `0x404` | `POS_GAP_CFG` | R/W | zero-gap threshold used to split clusters |
| `0x408` | `POS_FILTER_CFG` | R/W | minimum cluster span and settle-cycle count |
| `0x420` | `POS_STATUS` | R | live detector and packet status |
| `0x424` | `POS_EVENT_COUNT` | R | accepted position-event count |
| `0x428` | `POS_FAULT_STATUS` | R/W1C | sticky faults and detector-state snapshot |
| `0x42C` | `POS_DROP_COUNT` | R | count of overlapping accepted-event drops |
| `0x430` | `POS_REJECT_COUNT` | R | count of glitch/empty rejections |

### 4.2 `POS_CTRL` (`0x400`)

| Bits | Name | Meaning |
|------|------|---------|
| `[0]` | `local_enable` | local enable inside the position block |

The effective enable is `global_enable_i & local_enable`.

### 4.3 `POS_GAP_CFG` (`0x404`)

| Bits | Name | Meaning |
|------|------|---------|
| `[6:0]` | `gap_threshold` | minimum zero-run length that starts a new cluster |

### 4.4 `POS_FILTER_CFG` (`0x408`)

| Bits | Name | Meaning |
|------|------|---------|
| `[6:0]` | `min_cluster_span` | clusters smaller than this are suppressed |
| `[11:8]` | `settle_cycles` | number of stable `clk_sys` cycles required before snapshot |

### 4.5 `POS_STATUS` (`0x420`)

| Bits | Name | Meaning |
|------|------|---------|
| `[0]` | `packet_active` | position packet currently being emitted |
| `[1]` | `overflow_any` | at least one axis had more than two qualifying clusters in the snapshot |
| `[4:2]` | `non_empty_mask` | axis snapshot contains at least one kept cluster (`X/Y/Z`) |
| `[7:5]` | `multi_cluster_mask` | axis snapshot contains two kept clusters (`X/Y/Z`) |
| `[8]` | `busy` | detector or packetizer busy |
| `[9]` | `packet_pending` | packet still outstanding |
| `[11:10]` | `det_state` | detector FSM state (`IDLE/SETTLE/EVAL/WAIT_CLEAR`) |

### 4.6 `POS_EVENT_COUNT` (`0x424`)

| Bits | Name | Meaning |
|------|------|---------|
| `[13:0]` | `event_count` | accepted position-event count |

### 4.7 `POS_FAULT_STATUS` (`0x428`)

| Bits | Name | Meaning | Clear behavior |
|------|------|---------|----------------|
| `[0]` | `drop_sticky` | an overlapping event was dropped | write `1` to clear |
| `[1]` | `glitch_reject_sticky` | unstable or empty activity was rejected | write `1` to clear |
| `[3:2]` | `det_state` | current detector FSM state snapshot | read only |

### 4.8 `POS_DROP_COUNT` (`0x42C`)

| Bits | Name | Meaning |
|------|------|---------|
| `[15:0]` | `drop_count` | count of dropped overlapping events |

### 4.9 `POS_REJECT_COUNT` (`0x430`)

| Bits | Name | Meaning |
|------|------|---------|
| `[15:0]` | `reject_count` | count of glitch or empty-event rejections |

## 5. Position operating rules

1. Keep the global and local enables aligned to the intended operating mode.
2. Use `drop_count` and `glitch_reject_sticky` as health indicators, not just the packet stream.
3. Treat `overflow_any` as "more than two clusters existed," not as a transport error.
