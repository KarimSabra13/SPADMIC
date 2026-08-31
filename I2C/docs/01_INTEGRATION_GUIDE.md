# I2C Integration Guide

## Scope

The active endpoint is `spadmic_top_matrix_v1`. Its external I2C pins remain
`i2c_scl_i`, bidirectional `i2c_sda_io`, and transport reset `i2c_rst_i`.

```text
pins -> spadmic_i2c_slave -> spadmic_i2c_csr_bridge
     -> spadmic_matrix_top_csr -> router -> block-owned banks
```

## Transaction encoding

### Write one register

```text
START
0x42 + W
ADDR[15:8]
ADDR[7:0]
DATA[31:24]
DATA[23:16]
DATA[15:8]
DATA[7:0]
STOP
```

### Pointer plus repeated-START read

```text
START
0x42 + W
ADDR[15:8]
ADDR[7:0]
REPEATED START
0x42 + R
DATA[31:24]
DATA[23:16]
DATA[15:8]
DATA[7:0]
STOP
```

The master ACKs intermediate read bytes and NACKs the final byte. A current-
pointer read omits the pointer phase. The pointer does not auto-increment.

## Integration requirements

1. Keep the address fixed at `0x42`; no runtime strap exists.
2. Use 100 kHz standard mode; the slave does not stretch SCL.
3. Issue only 4-byte-aligned 16-bit pointers.
4. Treat any partial data write as discarded, never as byte-enable behavior.
5. Poll software-visible status; no interrupt output exists.
6. Do not use `i2c_rst_i` to reset acquisition or clear diagnostics.

The bridge has a single outstanding request. A local CSR response reports read
data and an error indication; the I2C read payload is deterministic even for an
invalid address. The system access page records the exact software-visible
failure.

## Initial software checks

Read the following before configuration:

| Address | Expected |
| ---: | ---: |
| `0x0000` | `CHIP_ID = 0x53504D54` |
| `0x0004` | `ABI_VERSION = 0x00010000` |
| `0x0008` | `GLOBAL_CTRL = 0x000000F0` after chip reset |

Then keep global acquisition disabled, wait for `GLOBAL_STATUS[7] == 1`, write
configuration, and atomically enable the selected mode through `GLOBAL_CTRL`.

See `TOP/docs/42_CSR_I2C_BRINGUP_FR.md` for the operator sequence.
