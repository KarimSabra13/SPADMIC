# CSR ABI 1.0 Guide

## Canonical source

The authoritative address, access, reset, and field source is:

```text
TOP/rtl/spadmic_csr_map_pkg.sv
```

`TOP/scripts/generate_csr_map.py` produces the complete register and field
collateral in:

- `TOP/docs/csr/CSR_MAP.md`
- `TOP/docs/csr/spadmic_csr_map.csv`
- `TOP/docs/csr/spadmic_csr_fields.csv`
- `TOP/sw/include/spadmic_csr.h`
- `TOP/sw/python/spadmic_csr_map.py`

The generated C header includes register addresses plus field shift, width,
mask, and reset macros. The Python module exposes `REGISTERS`,
`REGISTER_FIELDS`, and checked field `prep()`/`get()` helpers. Do not duplicate
or manually edit these generated tables. CI runs
`TOP/ci/check_csr_map_generated.sh` to reject drift.

## Page allocation

| Page | Base | Owner |
| ---: | ---: | --- |
| `0x0` | `0x0000` | system, shared TDC configuration, access diagnostics |
| `0x1` | `0x1000` | TDC R status/fault/count |
| `0x2` | `0x2000` | TDC Y status/fault/count |
| `0x3` | `0x3000` | TDC B status/fault/count |
| `0x4` | `0x4000` | position |
| `0x5` | `0x5000` | event, snapshot, reset |
| `0x6` | `0x6000` | matrix configuration/readback |
| `0x7` | `0x7000` | TX and output FIFO |
| `0x8` | `0x8000` | PLL and clock controls |
| `0x9` | `0x9000` | analog controls |

All addresses are 16-bit byte addresses and must be 4-byte aligned. Data is
32-bit. Reserved bits read zero and are ignored on write.

## Programming constraints

The generated [complete map](csr/CSR_MAP.md) defines all 68 registers and all
162 software-visible fields. The constraints below state cross-field rules that
cannot be represented by masks alone.

### `GLOBAL_CTRL` and `GLOBAL_STATUS`

| Bits | Field |
| ---: | --- |
| `[0]` | global enable |
| `[3:1]` | operating mode: disabled/TDC/position/BOTH/calibration |
| `[6:4]` | normal active axis mask; normal TDC/BOTH must be `111` |
| `[7]` | auto-reset enable in CTRL; safe-idle indication in STATUS |

Reset value is `0x000000F0`: disabled, normal R/Y/B mask selected, automatic
reset enabled. A valid normal-mode enable also requires a programmed nonzero
reset width.

### Shared and position configuration

| Register | Fields |
| --- | --- |
| `TDC_SHARED_CFG` | max hits `[3:0]`, slow RO code `[15:8]`, fast RO code `[23:16]` |
| `TDC_SHARED_CMD` | soft reset `[0]`, FIFO clear `[1]` pulses |
| `CALIB_AXIS_MASK` | nonzero calibration R/Y/B mask `[2:0]` |
| `POSITION_CFG` | raw mode `[0]`, gap `[7:1]`, minimum span `[14:8]` |
| `SNAPSHOT_CFG` | settle cycles `[15:0]`, nonzero watchdog `[31:16]` |
| `RESET_CFG` | matrix-reset pulse width `[15:0]` |

`POSITION_CFG` resets to `0x00000104`: cluster mode, gap 2, minimum span 1.
`SNAPSHOT_CFG` resets to `0x00400002`.

## Access diagnostics

Invalid reads return zero. Invalid writes have no block side effect. Both are
recorded in the system page.

| Cause | Value | Sticky bit |
| --- | ---: | ---: |
| misaligned | `0x01` | `ACCESS_FAULT[0]` |
| unmapped | `0x02` | `ACCESS_FAULT[1]` |
| write to read-only | `0x03` | `ACCESS_FAULT[2]` |
| invalid value | `0x04` | `ACCESS_FAULT[3]` |
| unsafe write | `0x05` | `ACCESS_FAULT[4]` |
| incomplete I2C write | `0x06` | `ACCESS_FAULT[5]` |
| I2C reset abort | `0x07` | `ACCESS_FAULT[6]` |

`ACCESS_LAST_INFO` stores address `[15:0]`, cause `[23:16]`, and write/read
direction `[24]`. `ACCESS_LAST_WDATA` stores the rejected write payload.
`ACCESS_ERROR_COUNT` saturates at `0xFFFFFFFF`.

`GLOBAL_FAULT[6:0]` summarizes PLL, TX, matrix, event, position, any TDC, and
system access faults respectively from bit 6 down to bit 0.

## Clearing policy

Sticky block faults and `ACCESS_FAULT` are W1C. `MAINT_CMD[0]` clears saturating
error counters only while disabled and idle; it does not clear configuration or
sticky faults. Chip reset is the only global initialization event.
