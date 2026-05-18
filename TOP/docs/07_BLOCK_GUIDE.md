# SPADMIC TOP — Block Guide

## Scope

This is the block-by-block reference for `TOP/rtl/`.

Use it when you want the shortest path from a module name to:

- whether the block is active or legacy
- which clock/reset domain it lives in
- what contract it owns
- where it sits in the end-to-end control or data path

For packet semantics, use [`03_CORRELATED_EVENT_EXPORT.md`](03_CORRELATED_EVENT_EXPORT.md).
For the chip pins, use [`08_TX_INTERFACE.md`](08_TX_INTERFACE.md).

## 1. Active top-level block map

```text
spadmic_top_v1
  |- spadmic_i2c_slave
  |- spadmic_i2c_csr_bridge
  |- spadmic_csr_decoder
  |- spadmic_global_csr
  |- spadmic_top_sequencer
  |- spadmic_tdc_axis_wrapper x 3
  |    |- spadmic_ref_stop_qualifier
  |    `- mptdc_top_asic
  |- spadmic_tdc_shared_readout
  |- spadmic_position_block
  |    `- spadmic_axis_cluster_scan x 3
  |- spadmic_correlated_tx
  `- spadmic_ddr_tx
```

## 2. Integration shell and shared package

| Block | File | Domain | Status | What it owns |
|-------|------|--------|--------|--------------|
| `spadmic_top_v1` | `rtl/spadmic_top_v1.sv` | mostly `clk_sys` + async inputs | active | chip-level wiring, active control-image fanout, debug/status export |
| `spadmic_pkg` | `rtl/spadmic_pkg.sv` | none | active | shared constants, source IDs, CSR map, packet helpers, position helper types |

### `spadmic_top_v1`

This is the single place where the three major subsystems meet:

1. control plane from I2C
2. three preserved TDC axes
3. position detector and correlated export path

The module deliberately keeps most policy in sub-blocks. Its main job is to wire:

- requested control into the sequencer
- sequencer outputs into the datapath
- per-axis TDC exports into the shared TDC readout
- TDC and position packets into the correlated TX block
- logical packet words into the DDR TX block

### `spadmic_pkg`

This package is the TOP-side contract anchor. It is where future edits should
start if they change:

- source IDs
- CSR region definitions
- position packet widths
- correlated-export constants
- TX physical width

## 3. Control-path blocks

| Block | File | Domain | Status | Key responsibility |
|-------|------|--------|--------|--------------------|
| `spadmic_csr_decoder` | `rtl/spadmic_csr_decoder.sv` | `clk_sys` | active | region decode, read timeout, CSR request/response fanout |
| `spadmic_global_csr` | `rtl/spadmic_global_csr.sv` | `clk_sys` | active | requested image, software-visible status, sticky faults, counters |
| `spadmic_top_sequencer` | `rtl/spadmic_top_sequencer.sv` | `clk_sys` | active | requested-to-active handoff after datapath drain |

### `spadmic_csr_decoder`

This is the control-plane crossbar for the top:

- accepts one local CSR request from the I2C bridge or direct VIP path
- routes it by address region
- returns an error on invalid regions
- times out stalled reads instead of hanging the software-facing path forever

It is intentionally simple and synchronous because it sits on the management
path, not on the critical measurement path.

### `spadmic_global_csr`

This block is the software contract for chip-level control. It holds the
**requested** image, not the immediately live one.

It also reports the health of the integrated design:

- whether updates are currently allowed
- whether a request is pending commit
- control-write rejects
- position drop/glitch status
- correlated-export overflow status

If software wants to know what the chip is really doing right now, it must look
at the active-status reporting, not only at the requested control bits it wrote.

### `spadmic_top_sequencer`

This block protects the design from live mode-switch corruption.

It is the owner of the **active** image used by the datapath. On update:

1. the old path is forced toward drain
2. `path_idle` is waited out
3. the requested image is copied into the active registers
4. the datapath restarts under the new image

That separation is one of the most important chip-integration safety decisions in
the repository.

## 4. TDC-path blocks

| Block | File | Domain | Status | Key responsibility |
|-------|------|--------|--------|--------------------|
| `spadmic_tdc_axis_wrapper` | `rtl/spadmic_tdc_axis_wrapper.sv` | async input + `clk_ref_40m` + `clk_sys` glue | active | per-axis top-level wrapper around STOP qualification and `mptdc_top_asic` |
| `spadmic_ref_stop_qualifier` | `rtl/spadmic_ref_stop_qualifier.sv` | async event to `clk_ref_40m` | active | creates one qualified STOP pulse per accepted event |
| `spadmic_tdc_shared_readout` | `rtl/spadmic_tdc_shared_readout.sv` | `clk_sys` | active | shared acquisition-record arbiter and shared serializer |

### `spadmic_tdc_axis_wrapper`

Each axis wrapper keeps the analog-facing event side narrow and predictable:

- applies active enable gating
- converts the async event into a safe STOP pulse on `clk_ref_40m`
- forwards the selected input/output mode into the preserved TDC kernel
- exports acquisition records to the shared top-level readout path

The wrapper exists so the top can optimize area around the TDC kernels without
rewriting the kernels themselves.

The latest MPTDC kernel keeps only the oscillator/PD/counter fabric in generated
measurement clocks. Its normal measurement controller, hit-capture bridge,
context bank, drain, and FIFO ownership are `clk_sys` logic, so TOP-level
timing/CDC review should not describe the MPTDC context bank as a fast-domain
producer.

### `spadmic_ref_stop_qualifier`

This block converts an asynchronous event request into one reference-clock-aligned
STOP pulse. It is the small but important boundary between the uncontrolled SPAD
event arrival and the preserved `mptdc_top_asic` input contract.

### `spadmic_tdc_shared_readout`

This is the main digital-area optimization point on the TOP side.

Instead of keeping one packet serializer per axis, the design:

1. leaves one acquisition FIFO inside each axis-local TDC core
2. arbitrates on META records
3. holds the selected axis until its packet completes
4. feeds one shared `mptdc_narrow16_tx_v2`

That preserves per-axis measurement autonomy while collapsing redundant top-level
packetization hardware.

## 5. Position-path blocks

| Block | File | Domain | Status | Key responsibility |
|-------|------|--------|--------|--------------------|
| `spadmic_position_block` | `rtl/spadmic_position_block.sv` | async inputs into `clk_sys` | active | synchronize, settle, clusterize, queue, packetize, and count faults |
| `spadmic_axis_cluster_scan` | `rtl/spadmic_axis_cluster_scan.sv` | combinational in `clk_sys` datapath | active | derive up to two clusters and overflow metadata from one axis snapshot |

### `spadmic_position_block`

This block is the top-level position estimator and packetizer for the
64x64x64 SPAD matrix: one 64-line X/Y/Z projection bus per axis.

Its job is not only to emit packets. It also makes noisy asynchronous line
activity software-visible in a controlled way:

- stable snapshots become queued packets
- empty or glitch-like snapshots become counted rejects
- FIFO exhaustion becomes explicit drop accounting

The important active behavior change is that accepted snapshots are queued before
packetization. The block no longer drops a valid second event simply because the
first packet is still draining.

### `spadmic_axis_cluster_scan`

This is the local geometry helper used by the position block. It looks at one
64-line axis snapshot and returns:

- first cluster
- second cluster
- cluster count
- overflow indicator

It is intentionally isolated as a small leaf so the position estimator can stay
readable and directly unit-testable.

Cluster bounds are 6-bit coordinates (`0..63`) in both the internal
`spadmic_cluster_t` type and the cluster-position TX word. Gap threshold and
minimum-span controls remain 7-bit counts so software can express spans up to
the full 64-line axis.

## 6. Shared export and physical TX blocks

| Block | File | Domain | Status | Key responsibility |
|-------|------|--------|--------|--------------------|
| `spadmic_correlated_tx` | `rtl/spadmic_correlated_tx.sv` | `clk_sys` | active | packet arbitration, shared event-ID patching, post-arbiter FIFO |
| `spadmic_ddr_tx` | `rtl/spadmic_ddr_tx.sv` | `clk_sys` + both edges of forwarded clock | active | map logical 16-bit words onto source-synchronous 8-bit DDR pins |

### `spadmic_correlated_tx`

This block is the architectural replacement for the old final mux. It assumes
its two inputs are already packetized and then adds system-level meaning:

1. packet-granular arbitration
2. both-active source alternation
3. shared 14-bit event-ID insertion into EOC
4. post-arbiter buffering before the physical TX boundary

It is the place where the design stops thinking in terms of "which producer owns
the bus?" and starts thinking in terms of "how do multiple packet sources
describe one physical event family?".

### `spadmic_ddr_tx`

This block is intentionally simple:

- `chip_tx_clk_o` is just forwarded `clk_sys`
- `chip_tx_valid_o` is an SDR word-valid qualifier
- the low byte launches on the rising edge
- the high byte launches on the falling edge

There is no silicon-facing backpressure. Any elasticity must already exist
upstream, which is why `spadmic_correlated_tx` owns the post-arbiter FIFO.

## 7. Retained legacy collateral

| Block | File | Status today | Why it still exists |
|-------|------|--------------|---------------------|
| `spadmic_tdc_arbiter3` | `rtl/spadmic_tdc_arbiter3.sv` | legacy | older per-axis packet arbitration collateral |
| `spadmic_tdc_packet_fifo` | `rtl/spadmic_tdc_packet_fifo.sv` | legacy | older packet-FIFO collateral |
| `spadmic_shared_tx_mux` | `rtl/spadmic_shared_tx_mux.sv` | legacy | older top-level final-mux collateral and unit-test coverage |

These files are **not** part of the active chip datapath. They remain in-tree for:

- backward-compatible collateral
- unit benches that still describe historical behavior
- comparison/reference during the redesign

## 8. Reading order for new contributors

If you need to understand the active TOP quickly, read in this order:

1. `spadmic_top_v1.sv`
2. `spadmic_global_csr.sv`
3. `spadmic_top_sequencer.sv`
4. `spadmic_tdc_shared_readout.sv`
5. `spadmic_position_block.sv`
6. `spadmic_correlated_tx.sv`
7. `spadmic_ddr_tx.sv`

Then use:

- [`01_ACTIVE_ARCHITECTURE.md`](01_ACTIVE_ARCHITECTURE.md)
- [`03_CORRELATED_EVENT_EXPORT.md`](03_CORRELATED_EVENT_EXPORT.md)
- [`08_TX_INTERFACE.md`](08_TX_INTERFACE.md)
- [`09_VIP_GUIDE.md`](09_VIP_GUIDE.md)
