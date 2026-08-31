# Active Matrix-Top Architecture

## Scope

`TOP/rtl/spadmic_top_matrix_v1.sv` is the active RTL integration target. The
legacy chip top and monolithic CSR implementation are retired. The matrix top
keeps the existing external chip ports while replacing the internal control
plane with CSR ABI 1.0.

## Major paths

```text
I2C -> CSR router -> block-owned banks -> controls/status

SPAD event -> coordinator -> R/Y/B TDC + position snapshot
           -> correlated packet bundle -> output FIFO -> DDR16 low/high words

CSR matrix page -> matrix config controller -> 44-column matrix interface
```

The active top integrates:

- R, Y, and B `mptdc_axis_core` instances through TOP-owned wrappers
- position cluster/raw processing
- one shared event coordinator and event ID
- matrix configuration and readback
- fixed TX buffering and physical DDR egress
- PLL and analog control banks
- I2C transport and software-visible diagnostics

`MPTDC/rtl/top/mptdc_axis_core.sv` remains protected. Shared product tuning,
mode policy, status aggregation, and CSR ownership stay in TOP.

## Operating modes

`GLOBAL_CTRL` commits the complete active image atomically while idle.

| Mode field | Meaning | Axis policy |
| ---: | --- | --- |
| `0` | disabled | enable bit must be 0 |
| `1` | TDC only | R/Y/B mask must be `111` |
| `2` | position only | normal mask remains `111` |
| `3` | TDC plus position | R/Y/B mask must be `111` |
| `4` | calibration | uses nonzero `CALIB_AXIS_MASK` |

Normal acquisition does not expose a manual conversion-start command. A
qualified SPAD event enters the coordinator, which starts the enabled consumers,
waits for the required completion mask, exports correlated packets, and manages
the optional matrix-reset pulse.

## Configuration safety

Except for `GLOBAL_CTRL`, configuration writes require:

```text
GLOBAL_STATUS.enable == 0
GLOBAL_STATUS.safe_idle == 1
```

`GLOBAL_CTRL` itself requires idle and validates the complete proposed state.
Enabling TDC, position, or BOTH operation requires nonzero `RESET_CFG` width.
Calibration requires a nonzero calibration mask. Rejected writes leave the
previous active image unchanged and record an access error.

PLL, analog, position, matrix, and TDC tuning writes follow the same
disabled-and-idle policy. Configuration changes take effect immediately after
an accepted write; there is no hidden shadow commit.

## Position and reset

`POSITION_CFG` selects cluster/raw mode and the shared gap/minimum-span filters.
The reset image is cluster mode, gap 2, minimum span 1. The event page owns
snapshot settle/watchdog timing and the automatic matrix-reset pulse width.

`GLOBAL_CTRL.auto_reset_enable` authorizes the coordinator-generated pulse.
`RESET_CFG.width` must be nonzero before enabling normal operation. Transport
reset `i2c_rst_i` is unrelated and never clears this state.

## TX path

The event bundle transmitter preserves packet boundaries and emits sources in
R, Y, B, then position order. It applies the public R/Y/B source identity and
one shared event ID to every packet belonging to the physical event. A fixed
FIFO then feeds `spadmic_ddr16_tx_pairer`, which emits two consecutive logical
16-bit words on `ddr_data_l_o` and `ddr_data_h_o` per valid pair. An odd final
word is deterministically zero-padded after the ordered flush marker.

Output FIFO reserve/depth are software-readable but not configurable. Faults
and counters separately report missing active sources and overflow conditions.

## Reset domains

- chip reset initializes RTL configuration, faults, counters, and datapaths
- I2C transport reset initializes only the I2C protocol engine
- TDC shared commands pulse soft reset/FIFO clear only while disabled and idle
- coordinated matrix reset is an event-path output, not a chip reset

## Evidence boundaries

RTL simulation proves the functional contract only. Genus, Innovus, STA, CDC,
DRC, LVS, and export readiness remain separate stages and are not authorized by
an RTL regression pass.
