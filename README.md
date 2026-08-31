# SPADMIC

SPADMIC is the RTL, verification, software-collateral, and implementation
repository for the SPAD detector readout ASIC. The active chip integration RTL
is `TOP/rtl/spadmic_top_matrix_v1.sv`.

## Active control plane

The active software-visible control path is:

```text
I2C pins
  -> I2C/rtl/spadmic_i2c_slave.sv
  -> I2C/rtl/spadmic_i2c_csr_bridge.sv
  -> TOP/rtl/spadmic_csr_router.sv
  -> TOP/rtl/spadmic_csr_banks.sv
  -> block controls and status
```

The contract is CSR ABI 1.0:

- fixed 7-bit I2C address `0x42` at 100 kHz
- 16-bit, word-aligned register addresses, MSB first
- 32-bit register data, MSB first
- one register transaction at a time, with no burst or auto-increment
- R, Y, and B public TDC axes
- invalid and incomplete accesses are fail-closed and recorded
- `i2c_rst_i` resets transport state only

The authoritative address source is
`TOP/rtl/spadmic_csr_map_pkg.sv`. Generated C, Python, CSV, and Markdown
collateral is under `TOP/sw/` and `TOP/docs/csr/`.

## Repository areas

| Area | Purpose |
| --- | --- |
| `TOP/` | active integration, CSR banks, event coordination, TX, VIP, and CI |
| `I2C/` | I2C transport and CSR bridge |
| `MPTDC/` | protected TDC implementation boundary and collateral |
| `position/` | position processing RTL and verification |
| `matrice/` | matrix configuration RTL and verification |
| `IP/` | reused design IP |

`MPTDC/rtl/top/mptdc_axis_core.sv` remains a protected boundary. Product-level
configuration and status belong in TOP-owned wrappers and CSR banks.

## Local verification

```bash
bash TOP/ci/check_csr_map_generated.sh
bash TOP/ci/run_smoke.sh
bash TOP/ci/run_directed_regression.sh
bash TOP/ci/run_vip_smoke.sh
bash TOP/ci/run_tapeout_readiness.sh
```

The scripts select Xcelium when available and otherwise use the supported local
Verilator paths. Functional coverage requires Xcelium:

```bash
bash TOP/ci/run_vip_coverage.sh
```

Passing RTL regressions does not imply synthesis, physical, DRC, LVS, timing,
or tapeout closure. Those remain separate evidence gates.
