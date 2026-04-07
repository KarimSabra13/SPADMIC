# TOP — SPADMIC Top-Level Integration

First chip-level integration scaffold for the SPADMIC SPAD readout IC.

## Architecture

See [`docs/SPADMIC_TOPLEVEL_PLAN.md`](docs/SPADMIC_TOPLEVEL_PLAN.md) for the full design note.

### Key blocks

| Module | File | Purpose |
|--------|------|---------|
| `spadmic_top_v1` | `rtl/spadmic_top_v1.sv` | Chip-level integration shell |
| `spadmic_tdc_axis_wrapper` | `rtl/spadmic_tdc_axis_wrapper.sv` | Per-axis wrapper (stop qualifier + MPTDC) |
| `spadmic_ref_stop_qualifier` | `rtl/spadmic_ref_stop_qualifier.sv` | One-shot reference-edge stop generator |
| `spadmic_tdc_arbiter3` | `rtl/spadmic_tdc_arbiter3.sv` | 3-to-1 round-robin packet-atomic arbiter |
| `spadmic_tdc_packet_fifo` | `rtl/spadmic_tdc_packet_fifo.sv` | Per-source FIFO with `tdc_id` header patching |
| `spadmic_csr_decoder` | `rtl/spadmic_csr_decoder.sv` | CSR address-region decoder |
| `spadmic_global_csr` | `rtl/spadmic_global_csr.sv` | Global ID/version/enable/status registers |
| `spadmic_position_block` | `rtl/spadmic_position_block.sv` | 3-axis position capture, scan, and TX |
| `spadmic_axis_cluster_scan` | `rtl/spadmic_axis_cluster_scan.sv` | 127-bit bitmap cluster scanner |
| `spadmic_pkg` | `rtl/spadmic_pkg.sv` | Constants, types, and helper functions |

### Testbenches

#### Unit tests (34 checks)

| Testbench | Checks | Status |
|-----------|--------|--------|
| `tb_spadmic_ref_stop_qualifier_unit` | 7 | ✅ PASS |
| `tb_spadmic_tdc_arbiter3_unit` | 15 | ✅ PASS |
| `tb_spadmic_axis_cluster_scan_unit` | 12 | ✅ PASS |

#### Stress tests (159 checks)

| Testbench | Checks | Status |
|-----------|--------|--------|
| `tb_spadmic_stress_stop_qualifier` | 16 | ✅ PASS |
| `tb_spadmic_stress_cluster_scan` | 94 | ✅ PASS |
| `tb_spadmic_stress_csr` | 23 | ✅ PASS |
| `tb_spadmic_stress_arbiter` | 15 | ✅ PASS |
| `tb_spadmic_stress_position` | 11 | ✅ PASS |

**Total: 193 self-checking assertions across 8 testbenches.**

## Clock domains

| Domain | Frequency | Usage |
|--------|-----------|-------|
| `clk_sys` | 160 MHz | CSR, FIFOs, arbiter, position |
| `clk_ref_40m` | 40 MHz | Reference-edge stop qualification |

## Building

From the `MPTDC/` directory:

```bash
# Lint
verilator --lint-only --timing +define+MPTDC_USE_OSC_MODEL \
  -f rtl/filelist.f -f ../TOP/filelist.f -f ../I2C/filelist.f \
  --top-module spadmic_top_v1

# Run unit tests (example: stop qualifier)
verilator --binary --timing -Wall \
  -Wno-UNUSEDSIGNAL -Wno-UNDRIVEN -Wno-DECLFILENAME -Wno-WIDTHEXPAND \
  -Wno-WIDTHTRUNC -Wno-UNUSEDPARAM -Wno-PINMISSING -Wno-UNUSEDGENVAR \
  -Wno-CASEINCOMPLETE -Wno-LATCH -Wno-REALCVT -Wno-INITIALDLY -Wno-COMBDLY \
  -Wno-PINCONNECTEMPTY -Wno-SYNCASYNCNET -Wno-UNOPTFLAT \
  rtl/pkg/mptdc_pkg.sv \
  ../TOP/rtl/spadmic_pkg.sv \
  ../TOP/rtl/spadmic_ref_stop_qualifier.sv \
  ../TOP/tb/tb_spadmic_ref_stop_qualifier_unit.sv \
  --top-module tb_spadmic_ref_stop_qualifier_unit
```
