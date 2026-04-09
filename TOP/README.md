# TOP — SPADMIC Top-Level Integration

First-silicon SPADMIC chip-level integration around three preserved `mptdc_top_asic` axes.

## Active architecture at a glance

- one physical `chip_tx_valid/chip_tx_data/chip_tx_ready` interface
- one requested-to-active control contract (`spadmic_global_csr` + `spadmic_top_sequencer`)
- one shared TDC serializer fed by per-axis acquisition-record exports
- one async-qualified position path with explicit counters and sticky faults
- one shared CSR fabric fronted by the I2C slave and CSR bridge

## Document map

| Document | Purpose |
|----------|---------|
| [`docs/SPADMIC_TOPLEVEL_PLAN.md`](docs/SPADMIC_TOPLEVEL_PLAN.md) | Compact integration note and file inventory |
| [`docs/01_ACTIVE_ARCHITECTURE.md`](docs/01_ACTIVE_ARCHITECTURE.md) | Detailed dataflow, clocks/resets, module responsibilities, and active-path behavior |
| [`docs/02_CSR_MAP.md`](docs/02_CSR_MAP.md) | Global and position CSR register map, field semantics, and software control rules |

## Active datapath summary

### Control plane

1. `spadmic_i2c_slave` samples the I2C pins into `clk_sys`.
2. `spadmic_i2c_csr_bridge` converts pointer-based I2C accesses into one local CSR request/response channel.
3. `spadmic_csr_decoder` routes the request to global, X, Y, Z, or position CSR regions and times out stalled reads.
4. `spadmic_global_csr` stores the requested control image, while `spadmic_top_sequencer` commits the active image only after drain/idle.

### TDC plane

1. Each axis wrapper qualifies one `clk_ref_40m` STOP pulse from the asynchronous SPAD event.
2. Each `mptdc_top_asic` instance runs the preserved measurement kernel and exports acquisition records instead of using its local narrow output.
3. `spadmic_tdc_shared_readout` arbitrates only on META records, keeps the selected source until EOC, and feeds one shared `mptdc_narrow16_tx_v2`.

### Position plane

1. `spadmic_position_block` synchronizes the asynchronous line buses.
2. A detect/settle/evaluate/wait-clear FSM snapshots stable activity only.
3. Three `spadmic_axis_cluster_scan` instances derive up to two clusters per axis.
4. The block emits a fixed 12-word packet and raises explicit counters/sticky bits for drops and glitch rejects.

### Final egress

- `spadmic_shared_tx_mux` selects either the packetized TDC stream or the packetized position stream.
- The sequencer guarantees `tx_sel` changes only while both candidate sources are idle.

## Active module inventory

| Module | File | Purpose |
|--------|------|---------|
| `spadmic_top_v1` | `rtl/spadmic_top_v1.sv` | Chip-level integration shell |
| `spadmic_pkg` | `rtl/spadmic_pkg.sv` | Shared constants, CSR addresses, packet helpers, cluster types |
| `spadmic_csr_decoder` | `rtl/spadmic_csr_decoder.sv` | Shared CSR region decoder with read timeout |
| `spadmic_global_csr` | `rtl/spadmic_global_csr.sv` | Requested control image plus global status/fault reporting |
| `spadmic_top_sequencer` | `rtl/spadmic_top_sequencer.sv` | Active-image commit sequencer |
| `spadmic_tdc_axis_wrapper` | `rtl/spadmic_tdc_axis_wrapper.sv` | Per-axis wrapper around stop qualification and `mptdc_top_asic` |
| `spadmic_ref_stop_qualifier` | `rtl/spadmic_ref_stop_qualifier.sv` | One-shot qualified STOP pulse generator |
| `spadmic_tdc_shared_readout` | `rtl/spadmic_tdc_shared_readout.sv` | Shared TDC record arbiter + shared serializer |
| `spadmic_position_block` | `rtl/spadmic_position_block.sv` | Position detector, packetizer, and local CSR block |
| `spadmic_axis_cluster_scan` | `rtl/spadmic_axis_cluster_scan.sv` | Per-axis two-cluster scanner with overflow flag |
| `spadmic_shared_tx_mux` | `rtl/spadmic_shared_tx_mux.sv` | Final mux onto the physical chip TX bus |

### Retained legacy collateral

| Module | File | Purpose today |
|--------|------|---------------|
| `spadmic_tdc_arbiter3` | `rtl/spadmic_tdc_arbiter3.sv` | Legacy packet arbiter retained for collateral around the old per-axis narrow packet path |
| `spadmic_tdc_packet_fifo` | `rtl/spadmic_tdc_packet_fifo.sv` | Legacy packet FIFO retained for collateral around the old per-axis narrow packet path |

## Clock and reset summary

| Domain | Frequency | Usage |
|--------|-----------|-------|
| `clk_sys` | 160 MHz | I2C, CSR, sequencer, shared TDC readout, shared TX mux, position block |
| `clk_ref_40m` | 40 MHz | STOP qualification only |
| MPTDC internal generated clocks | varies | Preserved inside each `mptdc_top_asic` instance |

## Validation entrypoints

```bash
# Full top lint
cd /home/karim/SPADMIC
MPTDC_FILES=$(sed -e 's,//.*$,,' -e '/^[[:space:]]*$/d' MPTDC/rtl/filelist.f | sed 's,^,MPTDC/,')
TOP_FILES=$(sed -e 's,//.*$,,' -e '/^[[:space:]]*$/d' TOP/filelist.f | sed 's,^,TOP/,')
verilator --lint-only --timing +define+MPTDC_USE_OSC_MODEL \
  $MPTDC_FILES $TOP_FILES \
  --top-module spadmic_top_v1

# Shared-readout unit test
verilator --binary --timing -Wall \
  -Wno-UNUSEDSIGNAL -Wno-UNDRIVEN -Wno-DECLFILENAME -Wno-WIDTHEXPAND \
  -Wno-WIDTHTRUNC -Wno-UNUSEDPARAM -Wno-PINMISSING -Wno-UNUSEDGENVAR \
  -Wno-CASEINCOMPLETE -Wno-LATCH -Wno-REALCVT -Wno-INITIALDLY -Wno-COMBDLY \
  -Wno-PINCONNECTEMPTY -Wno-SYNCASYNCNET -Wno-UNOPTFLAT \
  MPTDC/rtl/pkg/mptdc_pkg.sv \
  TOP/rtl/spadmic_pkg.sv \
  MPTDC/rtl/readout/mptdc_narrow16_tx_v2.sv \
  TOP/rtl/spadmic_tdc_shared_readout.sv \
  TOP/tb/tb_spadmic_tdc_shared_readout_unit.sv \
  --top-module tb_spadmic_tdc_shared_readout_unit
```
