# SPADMIC top-level v1 integration note

## Scope

This document defines the first integration scaffold for the full SPADMIC top around the validated `MPTDC` block. The goal is to preserve the existing TDC implementation as much as possible and add only wrapper/glue logic for multi-axis integration, control, and packet routing.

## Repository layout

New directories at the repository root keep the MPTDC core untouched:

```text
SPADMIC/
├── MPTDC/          # Existing validated TDC core (unchanged)
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
clk_ref_40m ------->| X axis wrapper        |->| packet FIFO      |
x event async ----->| (ref-stop qualifier + |  +------------------+
                    |  mptdc_top_asic)      |          |
                    +-----------------------+          |
                                                       v
                    +-----------------------+  +------------------+
clk_ref_40m ------->| Y axis wrapper        |->| packet FIFO      |
y event async ----->| (ref-stop qualifier + |  +------------------+
                    |  mptdc_top_asic)      |          |
                    +-----------------------+          |
                                                       v
                    +-----------------------+  +------------------+
clk_ref_40m ------->| Z axis wrapper        |->| packet FIFO      |
z event async ----->| (ref-stop qualifier + |  +------------------+
                    |  mptdc_top_asic)      |          |
                    +-----------------------+          |
                                                       v
                                              +------------------+
                                              | 3:1 packet       |
                                              | arbiter (atomic) |
                                              +------------------+
                                                       |
                                                       v
                                                shared TDC TX

x/y/z lines[126:0] ----------------------+
                                          v
                               +-----------------------+
                               | position snapshot +   |
                               | cluster scan + TX     |
                               +-----------------------+
                                          |
                                          v
                                    position TX
```

## Clock and reset domains

| Domain | Frequency | Usage |
|--------|-----------|-------|
| `clk_sys` | 160 MHz | I2C decode/bridge, CSR, packet FIFOs, arbiter, position |
| `clk_ref_40m` | 40 MHz | Reverse stop qualification only |
| MPTDC internal | varies | Preserved inside each `mptdc_top_asic` instance |
| Async events | — | Per-axis SPAD OR-tree into axis wrapper |

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

## Shared TDC arbitration contract

- Each axis TDC keeps its own local MPTDC packetizer
- Per-axis packet FIFO captures `header → sub-header → payload → EOC`
- Arbitration sees only complete packets (`pkt_available`)
- Round-robin selection happens only at packet boundaries
- Once granted, source keeps TX until EOC is accepted
- **No packet interleaving**

### `tdc_id` tagging

- Existing v2.3 sub-header bits `[5:4]` carry `tdc_id`:
  - `2'b00` = TDC_X
  - `2'b01` = TDC_Y
  - `2'b10` = TDC_Z
- Standalone `mptdc_top_asic` instances emit zero in those bits

## Position block contract

- Inputs: `x_lines[126:0]`, `y_lines[126:0]`, `z_lines[126:0]`
- Sampled in `clk_sys`; source must hold bitmap stable for snapshot
- Up to 2 clusters per axis, configurable gap threshold
- Overflow flag if more clusters detected
- Dedicated TX path, fully separate from TDC arbiter

## File inventory

### TOP/rtl/

| File | Purpose |
|------|---------|
| `spadmic_pkg.sv` | Constants, types, helper functions |
| `spadmic_top_v1.sv` | Chip-level integration shell |
| `spadmic_tdc_axis_wrapper.sv` | Per-axis TDC wrapper (stop qualifier + mptdc_top_asic) |
| `spadmic_ref_stop_qualifier.sv` | One-shot ref-edge stop generator |
| `spadmic_tdc_arbiter3.sv` | 3-to-1 round-robin packet arbiter |
| `spadmic_tdc_packet_fifo.sv` | Per-source packet buffer with tdc_id patching |
| `spadmic_csr_decoder.sv` | Address-region decoder for CSR bus |
| `spadmic_global_csr.sv` | Global identification, enable, status registers |
| `spadmic_position_block.sv` | Position capture, scan, packetize pipeline |
| `spadmic_axis_cluster_scan.sv` | 127-bit line bitmap cluster scanner |

### I2C/rtl/

| File | Purpose |
|------|---------|
| `spadmic_i2c_slave.sv` | I2C slave with 16-bit addr, 32-bit data |
| `spadmic_i2c_csr_bridge.sv` | I2C-to-CSR transaction bridge |

### TOP/tb/

| File | Purpose |
|------|---------|
| `tb_spadmic_ref_stop_qualifier_unit.sv` | Stop qualifier unit test |
| `tb_spadmic_tdc_arbiter3_unit.sv` | Arbiter + FIFO integration test |
| `tb_spadmic_axis_cluster_scan_unit.sv` | Cluster scan unit test |

## Known assumptions / TBDs

1. I2C v1: 7-bit slave address, 16-bit register address, 32-bit data, no burst
2. Position capture trigger: rising-edge occupancy detection in `clk_sys`
3. Shared-TX `tdc_id` uses existing reserved sub-header bits
4. Integration scaffold, not silicon-signoff evidence for new blocks
5. The MPTDC protocol doc update (`02_OUTPUT_PROTOCOL.md`) documents the sub-header tdc_id field
