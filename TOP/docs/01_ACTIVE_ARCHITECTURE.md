# SPADMIC TOP — Active Architecture Guide

Author: Karim Sabra

## Scope

This document describes the active chip-level RTL in `TOP/rtl/` and its interaction with the preserved `MPTDC` and `I2C` blocks.

It is the detailed companion to:

- [`../README.md`](../README.md)
- [`SPADMIC_TOPLEVEL_PLAN.md`](SPADMIC_TOPLEVEL_PLAN.md)
- [`02_CSR_MAP.md`](02_CSR_MAP.md)

## 1. Active top-level contract

The current top-level design is organized around one shared physical output bus and one explicit requested-to-active control handoff.

### Core architectural rules

1. The chip exposes one physical source-synchronous `chip_tx_*` interface.
2. The chip supports three export personalities on that interface:
   - TDC-only
   - position-only
   - correlated both-active
3. Software writes only the **requested** control image.
4. `spadmic_top_sequencer` commits the **active** image after the old datapath drains.
5. The three TDC measurement kernels stay local inside three `mptdc_axis_core` product axes.
6. TDC sharing happens only after each axis has already produced direct packet words.
7. The shared egress assigns one unified rolling 14-bit event ID and patches it into the EOC word of every emitted packet.

## 2. End-to-end dataflow

### 2.1 Control path

```text
I2C pins
  -> spadmic_i2c_slave
  -> spadmic_i2c_csr_bridge
  -> spadmic_csr_decoder
  -> global CSR / X TDC CSR / Y TDC CSR / Z TDC CSR / position CSR
```

### 2.2 TDC path

```text
per-axis async SPAD event
  -> spadmic_ref_stop_qualifier
  -> mptdc_axis_core
  -> mptdc_core local acquisition FIFO
  -> mptdc_packet16_tx direct packet stream
  -> spadmic_correlated_tx
  -> spadmic_ddr_tx
  -> chip_tx_clk_o / chip_tx_valid_o / chip_tx_data_o[7:0] DDR
```

### 2.3 Position path

```text
async x/y/z line buses
  -> synchronizer chain
  -> detect/settle/evaluate/wait-clear FSM
  -> per-axis cluster scan
  -> queued cluster or raw bitmap position packets
  -> spadmic_correlated_tx
  -> spadmic_ddr_tx
  -> chip_tx_clk_o / chip_tx_valid_o / chip_tx_data_o[7:0] DDR
```

## 3. Clocks and resets

| Domain | Source | Used by |
|--------|--------|---------|
| `clk_sys` | external 160 MHz | I2C, CSR, sequencer, ARB adapters, position block, correlated TX, physical TX packer |
| `clk_ref_40m` | external 40 MHz | STOP qualification only |
| MPTDC generated clocks | internal oscillators | preserved inside each `mptdc_axis_core` instance |
| async line/event domain | external asynchronous sources | SPAD event entry and position-line entry |

### Reset strategy

- `async_rst_n` enters the chip top asynchronously.
- `mptdc_reset_sync` generates `rst_sys_n` for the top-level `clk_sys` glue.
- Each `mptdc_axis_core` instance receives the original asynchronous top reset and handles its own local synchronization internally.

## 4. Requested versus active control

### 4.1 Requested image (`spadmic_global_csr`)

`spadmic_global_csr` is the software-visible control bank. It stores:

- `global_enable`
- `axis_enable[2:0]`
- `position_enable`
- `shared_tx_sel`
- `tdc_input_sel`
- `tdc_out_mode`

It also reports:

- whether the datapath is idle
- whether the sequencer would currently accept a configuration update
- whether a previously accepted image is still pending commit
- sticky and counted rejects for non-idle control writes
- position-side drop and glitch status
- correlated-event tagger overflow status

### 4.2 Active image (`spadmic_top_sequencer`)

`spadmic_top_sequencer` owns the live control image used by the datapath.

When `cfg_update_i` asserts:

1. the sequencer leaves `SEQ_IDLE`
2. `active_global_enable_o` is forced low
3. the current datapath is allowed to drain
4. when `path_idle` is true, the requested image is copied into the active image
5. the sequencer returns to `SEQ_IDLE`

### 4.3 `path_idle` definition

The top-level transition logic considers the chip idle only when all of the following are false:

- `tdc_tx_busy`
- any `tdc_pkt_pending`
- `position_busy`
- `position_pending`

That is the contract that protects mode/source switches from mid-packet corruption.

### 4.4 Export-mode meaning

The active RTL keeps the existing CSR width but interprets the committed control image as:

- `shared_tx_sel = TDC`, `position_enable = 0` -> **TDC-only**
- `shared_tx_sel = POSITION`, `position_enable = 1` -> **position-only**
- `shared_tx_sel = TDC`, `position_enable = 1` -> **correlated both-active**

## 5. TDC integration details

### 5.1 Per-axis wrapper

`spadmic_tdc_axis_wrapper` does four things:

1. gates the asynchronous SPAD event with the active global/axis enables
2. converts the event into one qualified `clk_ref_40m` STOP pulse
3. forwards product controls and global `max_hits` into `mptdc_axis_core`
4. exports direct 16-bit packet words plus SOP/EOP and packet-active sidebands

Inside each preserved MPTDC kernel, the current measurement-control/context
pivot is local to `mptdc_core`: oscillator/PD/counter fabric remains
measurement-local, while `mptdc_meas_ctrl`, `mptdc_hit_capture_bridge`, and
`mptdc_context_bank` run in `clk_sys`. TOP only sees the product packet stream
and should not assume a fast-domain context-bank interface.

### 5.2 Unified ARB TDC packet streams

`mptdc_packet16_tx` now lives inside each product axis:

- each axis still owns its own local acquisition FIFO inside `mptdc_core`
- each product packetizer consumes one META record and then the announced HIT records
- the central ARB consumes direct `{valid,ready,data,sop,eop}` packet streams
- the selected `tdc_id` is patched into TDC header bits `[1:0]`
- the ARB path emits the fixed v2.7 TDC packet; legacy output-mode requests are masked to RAW_FEATURES compatibility

That keeps zero-hit packets self-identifying without paying an extra source-tag word.

### 5.3 Why arbitration starts after packetization

Packet-stream arbitration gives two guarantees:

1. no interleaving between packets from different axes
2. one central four-source ARB can handle X, Y, Z, and position uniformly

## 6. Position path details

### 6.1 Input qualification

`x_lines_i`, `y_lines_i`, and `z_lines_i` are treated as asynchronous black-box outputs from the SPAD matrix.

The position block therefore:

- uses a three-stage synchronizer chain
- waits for nonzero activity
- requires the synchronized lines to settle
- snapshots only stable data
- rejects glitches or empty snapshots explicitly
- can emit one active-high `spad_matrix_rst_o` pulse in the `clk_sys` domain

### 6.2 Cluster extraction

Each axis uses `spadmic_axis_cluster_scan` to find:

- `cluster0`
- `cluster1`
- `overflow`
- `cluster_count`

The active block then filters out clusters whose span is below the configured minimum.
The reduced SPAD geometry is 64x64x64, so each axis coordinate is a 6-bit
`0..63` value. Gap threshold and minimum span remain 7-bit count fields because
they may need to represent the full 64-line width.

### 6.3 Position packet formats

Default cluster mode emits the fixed 8-word position packet:

1. header
2. X cluster 0
3. X cluster 1
4. Y cluster 0
5. Y cluster 1
6. Z cluster 0
7. Z cluster 1
8. EOC/tag

If `POS_CTRL.compact_cluster` is enabled, cluster mode emits a variable-length
compact packet:

1. compact header
2. only the valid cluster slots, in fixed slot order `X0, X1, Y0, Y1, Z0, Z1`
3. EOC/tag

The compact header keeps the normal position marker `[15:14] = 2'b01`, sets
bit `[9] = 1`, and carries the valid slot mask in `[8:3]`:

```text
[15:14] = 2'b01
[13]    = overflow_any
[12:10] = non_empty_mask {Z,Y,X}
[9]     = compact_cluster
[8:3]   = slot_valid_mask {Z1,Z0,Y1,Y0,X1,X0}
[2:0]   = multi_cluster_mask {Z,Y,X}
```

Each cluster word is a 16-bit logical word:

```text
[15:13] = 3'b000 reserved
[12:7]  = lo[5:0]
[6:1]   = hi[5:0]
[0]     = valid
```

Raw bitmap mode emits a fixed 14-word low-rate characterization packet:

1. raw header
2. X line bitmap words 0..3 (`x_lines[15:0]` through `x_lines[63:48]`)
3. Y line bitmap words 0..3
4. Z line bitmap words 0..3
5. EOC

Because raw payload words are unescaped 16-bit line levels and may look like a
normal EOC marker, `spadmic_correlated_tx` recognizes the raw position header and
holds arbitration for the fixed 14-word raw packet length.

### 6.4 SPAD matrix reset modes

The top-level output `spad_matrix_rst_o` is an active-high one-cycle pulse in
the `clk_sys` domain. Software controls it through the position CSR block:

| Mode | Meaning |
|------|---------|
| `manual only` | no automatic reset; `POS_CTRL.manual_reset_req` emits one pulse |
| `reset after capture` | optional `POS_CTRL.reset_after_capture` pulse after the stable line snapshot is already registered |
| `event-deferred auto-reset` | period expiry waits until the position detector, packetizer, FIFO read port, and synchronized line buses are idle |
| `periodic auto-reset` | period expiry emits a pulse immediately on schedule, intended for raw characterization |

### 6.5 Position overlap behavior

Accepted position snapshots are queued in an internal FIFO before packetization. That means:

- a second qualifying snapshot no longer has to be dropped just because the previous packet is still draining
- `drop_count` now tracks queue overflow, not simple "packet active" overlap
- `position_pending` can stay high while the queue drains even if the detector FSM is already idle

## 7. Shared chip TX path

`spadmic_correlated_tx` replaced the old one-of-two final mux in the active datapath.

It does three things:

1. arbitrates between already packetized TDC and position packets at **packet** granularity
2. preserves packet atomicity while alternating sources in both-active mode
3. replaces each packet's local EOC counter with a shared 14-bit event ID so off-chip software can regroup X/Y/Z/position packets by event

The current event-ID rule is intentionally simple: for each enabled source, the nth emitted packet is tagged as that source's nth physical event. Under the active contract — one ordered packet per enabled source per physical event and no silent loss — that gives deterministic off-chip correlation without touching the TDC kernels.

## 8. Physical TX mapping

`spadmic_ddr_tx` maps the internal logical stream onto the chip pins as:

- `chip_tx_clk_o` = forwarded `clk_sys`
- `chip_tx_valid_o` = SDR word-valid qualifier
- `chip_tx_data_o[7:0]` = DDR byte lane

Each internal 16-bit logical word is emitted as:

1. low byte on the rising edge of `chip_tx_clk_o`
2. high byte on the falling edge of `chip_tx_clk_o`

There is no off-chip `ready`/backpressure pin in the active physical contract. All elasticity stays inside the on-chip correlated/export buffering.

## 8. Module responsibilities

| Module | Responsibility |
|--------|----------------|
| `spadmic_top_v1` | Wire up the full chip-level data/control graph |
| `spadmic_pkg` | Shared addresses, packet helpers, source IDs, position helpers |
| `spadmic_csr_decoder` | Region decode and read timeout |
| `spadmic_global_csr` | Requested image, status, faults |
| `spadmic_top_sequencer` | Active-image commit |
| `spadmic_ref_stop_qualifier` | One qualified STOP pulse per async event |
| `spadmic_tdc_axis_wrapper` | Per-axis glue around the product TDC axis |
| `spadmic_tdc_axis_csr` | TOP-owned product TDC control/status |
| `spadmic_position_block` | Position detection, queued packetization, accounting |
| `spadmic_axis_cluster_scan` | Five-cycle pipelined cluster scan |
| `spadmic_packet_arbiter4` | Masked packet-atomic four-source arbiter |
| `spadmic_correlated_tx` | Direct TDC/position packet arbitration, unified event tagging, and post-arbiter FIFO |
| `spadmic_ddr_tx` | Forwarded-clock physical TX packer |
