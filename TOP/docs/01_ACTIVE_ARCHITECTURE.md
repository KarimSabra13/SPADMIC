# SPADMIC TOP — Active Architecture Guide

## Scope

This document describes the active chip-level RTL in `TOP/rtl/` and its interaction with the preserved `MPTDC` and `I2C` blocks.

It is the detailed companion to:

- [`../README.md`](../README.md)
- [`SPADMIC_TOPLEVEL_PLAN.md`](SPADMIC_TOPLEVEL_PLAN.md)
- [`02_CSR_MAP.md`](02_CSR_MAP.md)

## 1. Active top-level contract

The current top-level design is organized around one shared physical output bus and one explicit requested-to-active control handoff.

### Core architectural rules

1. The chip exposes one physical `chip_tx_*` interface.
2. TDC traffic and position traffic are mutually exclusive at that interface.
3. Software writes only the **requested** control image.
4. `spadmic_top_sequencer` commits the **active** image after the old datapath drains.
5. The three TDC measurement kernels stay local inside three preserved `mptdc_top_asic` instances.
6. TDC sharing happens only after each axis has already produced acquisition records.

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
  -> mptdc_top_asic
  -> mptdc_core local acquisition FIFO
  -> exported acquisition records
  -> spadmic_tdc_shared_readout
  -> shared mptdc_narrow16_tx_v2
  -> spadmic_shared_tx_mux
  -> chip_tx_*
```

### 2.3 Position path

```text
async x/y/z line buses
  -> synchronizer chain
  -> detect/settle/evaluate/wait-clear FSM
  -> per-axis cluster scan
  -> fixed 12-word position packet
  -> spadmic_shared_tx_mux
  -> chip_tx_*
```

## 3. Clocks and resets

| Domain | Source | Used by |
|--------|--------|---------|
| `clk_sys` | external 160 MHz | I2C, CSR, sequencer, shared readout, position block, shared TX mux |
| `clk_ref_40m` | external 40 MHz | STOP qualification only |
| MPTDC generated clocks | internal oscillators | preserved inside each `mptdc_top_asic` instance |
| async line/event domain | external asynchronous sources | SPAD event entry and position-line entry |

### Reset strategy

- `async_rst_n` enters the chip top asynchronously.
- `mptdc_reset_sync` generates `rst_sys_n` for the top-level `clk_sys` glue.
- Each `mptdc_top_asic` instance receives the original asynchronous top reset and handles its own local synchronization internally.

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

## 5. TDC integration details

### 5.1 Per-axis wrapper

`spadmic_tdc_axis_wrapper` does four things:

1. gates the asynchronous SPAD event with the active global/axis enables
2. converts the event into one qualified `clk_ref_40m` STOP pulse
3. forwards the global TDC input/output-mode overrides into the preserved `mptdc_top_asic`
4. exports acquisition records instead of using the legacy per-axis narrow output

### 5.2 Shared TDC readout

`spadmic_tdc_shared_readout` is the digital-area optimization point in the active top:

- each axis still owns its own local acquisition FIFO inside `mptdc_core`
- the top arbitrates only on META records
- once a META record is accepted, the same axis remains selected until all announced HIT records drain and the serializer emits EOC
- the selected `tdc_id` is held until packet end and is patched into sub-header bits `[5:4]`

### 5.3 Why arbitration starts on META records

META-first arbitration gives two guarantees:

1. no interleaving between packets from different axes
2. no second top-level packet FIFO is needed after serialization

## 6. Position path details

### 6.1 Input qualification

`x_lines_i`, `y_lines_i`, and `z_lines_i` are treated as asynchronous black-box outputs from the SPAD matrix.

The position block therefore:

- uses a three-stage synchronizer chain
- waits for nonzero activity
- requires the synchronized lines to settle
- snapshots only stable data
- rejects glitches or empty snapshots explicitly

### 6.2 Cluster extraction

Each axis uses `spadmic_axis_cluster_scan` to find:

- `cluster0`
- `cluster1`
- `overflow`
- `cluster_count`

The active block then filters out clusters whose span is below the configured minimum.

### 6.3 Position packet format

The active position packet is fixed at 12 words:

1. header
2. source-tagged sub-header
3. X summary
4. X cluster 0
5. X cluster 1
6. Y summary
7. Y cluster 0
8. Y cluster 1
9. Z summary
10. Z cluster 0
11. Z cluster 1
12. EOC

## 7. Shared chip TX path

`spadmic_shared_tx_mux` is intentionally simple. It does not arbitrate packets dynamically; it only selects between two already packetized sources.

That simplicity is safe because:

- `shared_tx_sel` changes only through the sequencer
- the sequencer changes it only when both sources are idle
- each source already preserves its own packet boundaries

## 8. Module responsibilities

| Module | Responsibility |
|--------|----------------|
| `spadmic_top_v1` | Wire up the full chip-level data/control graph |
| `spadmic_pkg` | Shared addresses, packet helpers, source IDs, position helpers |
| `spadmic_csr_decoder` | Region decode and read timeout |
| `spadmic_global_csr` | Requested image, status, faults |
| `spadmic_top_sequencer` | Active-image commit |
| `spadmic_ref_stop_qualifier` | One qualified STOP pulse per async event |
| `spadmic_tdc_axis_wrapper` | Per-axis glue around the preserved TDC |
| `spadmic_tdc_shared_readout` | Shared TDC serializer front end |
| `spadmic_position_block` | Position detection, packetization, accounting |
| `spadmic_axis_cluster_scan` | Pure combinational cluster scan |
| `spadmic_shared_tx_mux` | Final physical-bus mux |

## 9. Retained legacy collateral

`spadmic_tdc_arbiter3` and `spadmic_tdc_packet_fifo` remain in the tree for collateral around the older per-axis packet path, but they are not part of the active chip-level datapath.
