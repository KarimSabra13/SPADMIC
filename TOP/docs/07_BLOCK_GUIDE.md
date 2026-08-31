# Active Block Guide

## Integration

| Module | Role |
| --- | --- |
| `spadmic_top_matrix_v1` | active external boundary and complete integration |
| `spadmic_matrix_top_csr` | CSR subsystem assembly and block signal fanout |
| `spadmic_event_coordinator` | shared event ID, completion mask, lifecycle, reset request |
| `spadmic_matrix_snapshot_frontend` | coherent R/Y/B matrix snapshot capture |
| `spadmic_event_bundle_tx` | ordered packet bundle and public source/event patching |
| `spadmic_output_fifo` | fixed geometry output buffering |
| `spadmic_ddr16_tx_pairer` | two logical 16-bit words to low/high DDR pair outputs |

## CSR subsystem

| Module | Ownership |
| --- | --- |
| `spadmic_csr_map_pkg` | canonical addresses, reset metadata, access causes |
| `spadmic_csr_router` | alignment, mapping, access type, page dispatch |
| `spadmic_csr_system_bank` | identity, ABI, global state, shared TDC config, access diagnostics |
| `spadmic_csr_tdc_bank` | one R/Y/B status/fault/count page |
| `spadmic_csr_position_bank` | position config/status/drop diagnostics |
| `spadmic_csr_event_bank` | event/snapshot/reset config, status, faults, counters |
| `spadmic_csr_matrix_bank` | matrix operation, payload, readback, faults, counters |
| `spadmic_csr_tx_bank` | bundle/FIFO/DDR status and TX diagnostics |
| `spadmic_csr_pll_bank` | PLL/clock controls and lock-loss diagnostics |
| `spadmic_csr_analog_bank` | SLVS and receiver controls |

Each bank returns a bounded response and owns its state. The router never
silently aliases an invalid address to another register.

## TDC boundary

The three public axes are R, Y, and B. TOP shares max-hits and RO tuning across
normal axes. Normal TDC/BOTH operation always uses all three axes; calibration
may select a nonzero subset through `CALIB_AXIS_MASK`.

`MPTDC/rtl/top/mptdc_axis_core.sv` is protected. Do not add product CSR policy or
chip-level status behavior inside it.

## Position

The position path consumes three 64-line projections and emits either cluster
or raw packets. `POSITION_CFG` owns mode, gap, and minimum span. Snapshot settle,
watchdog, and coordinated matrix reset belong to the event bank.

## Matrix configuration

The matrix bank stages column and 64-bit write data, then accepts a legal
operation/start command while disabled and idle. Column values outside the
44-column contract and unsupported operations are rejected without side
effects. Readback and controller error are reported separately.

## PLL and analog

These controls are immediate after an accepted disabled/idle write. Active-low
analog reset images are encoded explicitly: `_B` controls reset high while
active-high enables reset low. Reserved bits read zero.

## Transport

`spadmic_i2c_slave` and `spadmic_i2c_csr_bridge` are transport components. They
do not own register policy. `i2c_rst_i` is transport-only and preserves all bank
state.

## Verification ownership

- direct bank behavior: `tb_spadmic_matrix_top_csr_unit`
- transport behavior: I2C control-plane and matrix-top benches
- active integration: matrix-top directed benches
- end-to-end behavior: `TOP/tb/vip/`
- generated software contract: `TOP/ci/check_csr_map_generated.sh`
