# SPADMIC top-level v1 integration note

## Scope

This document is the compact integration note for the active SPADMIC top around the validated `MPTDC` block.
For the detailed active architecture and software-visible register map, use:

- [`01_ACTIVE_ARCHITECTURE.md`](01_ACTIVE_ARCHITECTURE.md)
- [`02_CSR_MAP.md`](02_CSR_MAP.md)

## Repository layout

New directories at the repository root keep the MPTDC core untouched:

```text
SPADMIC/
├── MPTDC/          # Product TDC axis core and preserved measurement engine
├── TOP/            # SPADMIC top-level integration
│   ├── rtl/        # All integration RTL (pkg, wrappers, arbiter, position)
│   ├── tb/         # Unit/smoke testbenches for integration blocks
│   ├── docs/       # This document and architecture notes
│   └── filelist.f  # Compile list (references MPTDC/ and I2C/)
├── I2C/            # I2C control plane (separate from MPTDC)
│   ├── rtl/        # I2C slave and CSR bridge modules
│   └── filelist.f  # I2C-only compile list
└── ...
```

## Text block diagram

```text
                    +-----------------------+
clk_sys ----------->|  I2C slave + bridge   |----+
async_rst_n ------->|  + top-level CSR dec  |    |
                    +-----------------------+    |
                                                 v
                    +-----------------------+  +------------------+
 clk_ref_40m ------->| X axis wrapper        |->| packet stream    |
 x event async ----->| (ref-stop qualifier + |  | (inside MPTDC)   |
                    |  mptdc_axis_core)     |  +------------------+
                    +-----------------------+          |
                                                       v
                    +-----------------------+  +------------------+
 clk_ref_40m ------->| Y axis wrapper        |->| packet stream    |
 y event async ----->| (ref-stop qualifier + |  | (inside MPTDC)   |
                    |  mptdc_axis_core)     |  +------------------+
                    +-----------------------+          |
                                                       v
                    +-----------------------+  +------------------+
 clk_ref_40m ------->| Z axis wrapper        |->| packet stream    |
 z event async ----->| (ref-stop qualifier + |  | (inside MPTDC)   |
                    |  mptdc_axis_core)     |  +------------------+
                    +-----------------------+          |
                                                       v
 x/y/z lines[63:0] -----------------------+   +------------------+
                                           v   | unified ARB +    |
                                +-----------------------+ event tag |
                                | async qualify +       | + FIFO    |
                                | cluster scan + TX     +----------+
                                +-----------------------+     |
                                                              v
                                                        shared chip TX
```

## Clock and reset domains

| Domain | Frequency | Usage |
|--------|-----------|-------|
| `clk_sys` | 160 MHz | I2C decode/bridge, CSR, local acquisition FIFOs, ARB adapters/tagger/FIFO, position |
| `clk_ref_40m` | 40 MHz | Reverse stop qualification only |
| MPTDC internal | varies | Preserved inside each `mptdc_axis_core` instance |
| Async events | — | Per-axis SPAD OR-tree into axis wrapper |
| Async line buses | — | `x/y/z_lines_i` enter the position block through synchronizer stages |

**Reset policy:**
- Top-level digital glue uses a synchronized `clk_sys` reset
- Each axis wrapper passes `async_rst_n` into the preserved MPTDC wrapper

## Reverse START/STOP contract

Per axis:

- **START** = asynchronous SPAD OR-tree event
- **STOP** = exactly one qualified high phase of `clk_ref_40m`
- **Qualification** = first `clk_ref_40m` rising edge after a latched start request
- **Disarm** = automatic after one qualified ref edge

Implementation:
- Stop qualifier uses low-phase-latched qualification around `clk_ref_40m` (no combinational clock gating)
- Existing MPTDC frontend still prevents stop-without-start internally

## Unified ARB/TDC readout contract

- Each axis TDC keeps its own local acquisition FIFO inside `mptdc_core`
- `mptdc_packet16_tx` serializes each axis into a uniform packet stream before central arbitration
- `spadmic_tdc_axis_wrapper` exports direct packet words plus SOP/EOP and packet-active sidebands
- `spadmic_correlated_tx` arbitrates `{TDC_X,TDC_Y,TDC_Z,POSITION}` with packet-level locking
- The active packet source ID is carried on internal sidebands until EOC so header/tagging stays coherent
- **No packet interleaving**

### `tdc_id` tagging

- Active shared-TDC tagging uses header bits `[1:0]`:
  - `2'b00` = TDC_X
  - `2'b01` = TDC_Y
  - `2'b10` = TDC_Z
  - `2'b11` = reserved
- `mptdc_axis_core` emits generic `[1:0] = 2'b00`; TOP patches only TDC header words.

## Shared chip TX contract

- First silicon now exposes one physical source-synchronous TX boundary:
  - forwarded `chip_tx_clk_o`
  - SDR `chip_tx_valid_o`
  - 8-bit DDR `chip_tx_data_o`
- The internal logical stream still carries correlated TDC/position packets, but the chip pins no longer expose an off-chip `ready`
- `spadmic_global_csr` accepts source-selection and mode updates only while the active path is idle/drained
- `spadmic_correlated_tx` arbitrates four uniform packet sources and never interleaves words
- Position packets carry an explicit source tag so one host parser can accept both TDC and position traffic

## Top-level sequencing contract

- `spadmic_global_csr` stores the **requested** control image visible to software
- `spadmic_top_sequencer` owns the **active** control image that drives the top
- An accepted control update first forces `global_enable` low, drains the old path, then commits the new active source/mode/control state
- Drain/idle means: no TDC packet in flight or pending, and no outstanding position packet or detector activity
- Busy or non-idle writes are rejected, counted, and reported back through the global fault/status registers
- Status now distinguishes datapath idleness from control-accept readiness and requested-versus-active mismatch

## Position block contract

- Inputs: `x_lines[63:0]`, `y_lines[63:0]`, `z_lines[63:0]` are treated as asynchronous black-box SPAD-matrix outputs
- Three synchronizer stages feed a detect/settle/evaluate/wait-clear FSM before snapshotting
- Up to 2 clusters per axis, configurable gap threshold, minimum cluster span, and settle-cycle filtering
- Accepted position snapshots are queued; overlaps increment drop counters only if that queue becomes full
- Weak or glitchy events increment explicit reject counters and sticky status
- Position packets now use an 8-word cluster format with header, 6 cluster words, and EOC/tag
- Cluster words use 6-bit `lo`/`hi` fields for the reduced 64x64x64 SPAD geometry; raw bitmap mode remains 14 words because each 64-bit axis consumes four 16-bit words

## File inventory

### TOP/rtl/

| File | Purpose |
|------|---------|
| `spadmic_pkg.sv` | Constants, types, helper functions |
| `spadmic_top_v1.sv` | Chip-level integration shell |
| `spadmic_tdc_axis_wrapper.sv` | Per-axis TDC wrapper (stop qualifier + mptdc_axis_core) |
| `spadmic_tdc_axis_csr.sv` | TOP-owned product TDC control/status CSR |
| `spadmic_ref_stop_qualifier.sv` | One-shot ref-edge stop generator |
| `spadmic_csr_decoder.sv` | Address-region decoder for CSR bus |
| `spadmic_global_csr.sv` | Global identification, enable, status registers |
| `spadmic_top_sequencer.sv` | Requested-to-active control sequencer for safe top-level transitions |
| `spadmic_ddr_tx.sv` | Active physical 8-bit DDR TX packer with forwarded clock |

### arb/rtl/

| File | Purpose |
|------|---------|
| `spadmic_position_packet_adapter.sv` | SOP/EOP/source sideband adapter for position packets |
| `spadmic_packet_arbiter4.sv` | Masked packet-atomic four-source arbiter with source skids |
| `spadmic_correlated_tx.sv` | Active correlated packet arbiter, unified event tagger, and output FIFO |

### I2C/rtl/

| File | Purpose |
|------|---------|
| `spadmic_i2c_slave.sv` | I2C slave with 16-bit addr, 32-bit data |
| `spadmic_i2c_csr_bridge.sv` | I2C-to-CSR transaction bridge |

### TOP/tb/

| File | Purpose |
|------|---------|
| `tb_spadmic_ref_stop_qualifier_unit.sv` | Stop qualifier unit test |
| `tb_spadmic_axis_cluster_scan_unit.sv` | Cluster scan unit test |
| `tb_spadmic_ddr_tx_unit.sv` | Physical DDR TX packer unit test |
| `tb_spadmic_top_sequencer_unit.sv` | Top control sequencer unit test |

### arb/tb/

| File | Purpose |
|------|---------|
| `tb_spadmic_arb_modes.sv` | ARB source-mask and legacy-mode masking coverage |
| `tb_spadmic_arb_stress.sv` | Max legal 110-word concurrent burst and backpressure stress |

## Known assumptions / TBDs

1. I2C v1: 7-bit slave address, 16-bit register address, 32-bit data, no burst
2. Position capture is qualified through synchronizer + settle filtering, not a raw one-cycle snapshot
3. Shared-TX source tagging reuses header bit `[12]` and reserved flag bit `[6]` for first silicon
4. First silicon keeps the internal correlated logical stream but repacks it onto a forwarded-clock 8-bit DDR output with no off-chip backpressure
5. Integration scaffold, not silicon-signoff evidence for new blocks
6. The MPTDC protocol doc update (`02_OUTPUT_PROTOCOL.md`) documents the compact no-sub-header TDC packet
