# SPADMIC TOP

`TOP/rtl/spadmic_top_matrix_v1.sv` is the active chip integration target. It
combines the R/Y/B TDC axes, position path, matrix configuration, coordinated
event/reset control, physical TX egress, PLL/analog controls, and the ABI 1.0
CSR plane.

## Control architecture

```text
spadmic_i2c_slave
  -> spadmic_i2c_csr_bridge
  -> spadmic_matrix_top_csr
       -> spadmic_csr_router
       -> spadmic_csr_system_bank
       -> spadmic_csr_tdc_bank x3
       -> spadmic_csr_position_bank
       -> spadmic_csr_event_bank
       -> spadmic_csr_matrix_bank
       -> spadmic_csr_tx_bank
       -> spadmic_csr_pll_bank
       -> spadmic_csr_analog_bank
```

The router validates alignment, mapping, and register access type. Each bank
owns its configuration, status, sticky faults, and saturating counters. Access
errors return a deterministic response and are also recorded in the system
page.

Configuration writes are accepted only while acquisition is disabled and the
design is idle. `GLOBAL_CTRL` is the atomic exception: it may commit a valid
disabled or enabled operating state while idle. Normal TDC and BOTH modes
require axis mask `3'b111`; calibration uses a separately programmed nonzero
axis mask.

## Data architecture

The event coordinator assigns one event ID across the active R/Y/B and position
sources. Required packet streams are bundled at packet boundaries, buffered,
and emitted as low/high 16-bit DDR word pairs. Matrix reset can be generated
only from the coordinated event path; there is no normal-mode software
conversion-start command.

Position operation supports cluster and raw modes. The ABI reset image is:

- cluster mode
- gap threshold 2
- minimum cluster span 1
- fixed output FIFO geometry
- global disabled, R/Y/B mask selected, automatic reset enabled

An enabled normal acquisition mode also requires nonzero `RESET_CFG` width.

## Key RTL

| File | Ownership |
| --- | --- |
| `rtl/spadmic_top_matrix_v1.sv` | active chip integration |
| `rtl/spadmic_csr_map_pkg.sv` | authoritative addresses and access metadata |
| `rtl/spadmic_csr_router.sv` | request validation and page routing |
| `rtl/spadmic_csr_banks.sv` | block-owned ABI 1.0 banks |
| `rtl/spadmic_matrix_top_csr.sv` | CSR subsystem assembly |
| `rtl/spadmic_event_coordinator.sv` | event lifecycle and reset coordination |
| `rtl/spadmic_event_bundle_tx.sv` | event-correlated packet bundle and public identity patching |
| `rtl/spadmic_output_fifo.sv` | fixed output buffering |
| `rtl/spadmic_ddr16_tx_pairer.sv` | physical 16-bit low/high DDR pair egress |

The legacy chip top, monolithic global/decoder CSR RTL, and direct legacy CSR
stress bench were retired after matrix-top migration. Historical documents and
snapshots remain for traceability.

## Generated software map

Do not edit generated outputs directly. Change the adjacent `CSR_MAP` record and
constant in `rtl/spadmic_csr_map_pkg.sv`, then run:

```bash
python3 scripts/generate_csr_map.py
bash ci/check_csr_map_generated.sh
```

Outputs:

- `sw/include/spadmic_csr.h`
- `sw/python/spadmic_csr_map.py`
- `docs/csr/spadmic_csr_map.csv`
- `docs/csr/spadmic_csr_fields.csv`
- `docs/csr/CSR_MAP.md`

## Verification

```bash
bash ci/run_smoke.sh
bash ci/run_directed_regression.sh
bash ci/run_vip_smoke.sh
bash ci/run_tapeout_readiness.sh
```

Use `bash ci/run_vip_coverage.sh` on an Xcelium host for functional coverage.
See `docs/05_XCELIUM_RUNBOOK.md` and `docs/42_CSR_I2C_BRINGUP_FR.md`.
